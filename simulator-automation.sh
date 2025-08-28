#!/bin/bash

# Claude Code iOS - Simulator Automation Script (Background-First Edition)
# iPhone 16 Pro Max (iOS 18.6) Build, Log, and Launch Automation
#
# This script integrates with background-logging-system.sh to prevent app restarts
# and log size issues by separating logging from build/launch operations.
#
# For MCP-based automation with UI testing, use XcodeBuildMCP tools from Claude.

set -e  # Exit on error

# ============================================================================
# CONFIGURATION
# ============================================================================

# Persistent Simulator UUID for iPhone 16 Pro Max (iOS 18.6)
readonly SIMULATOR_UUID="A707456B-44DB-472F-9722-C88153CDFFA1"
readonly APP_BUNDLE_ID="com.claudecode.ui"
readonly SCHEME_NAME="ClaudeCodeUI"
readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOGS_DIR="${PROJECT_ROOT}/logs"
readonly BUILD_DIR="${PROJECT_ROOT}/build"
readonly XCODE_PROJECT="${PROJECT_ROOT}/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj"

# Integration with background logging system
readonly BACKGROUND_LOGGER="${PROJECT_ROOT}/background-logging-system.sh"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m' # No Color

# ============================================================================
# FUNCTIONS
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%H:%M:%S') - $1"
}

log_mcp() {
    echo -e "${MAGENTA}[MCP]${NC} $(date '+%H:%M:%S') - $1"
}

log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $(date '+%H:%M:%S') - $1"
    fi
}

# Create necessary directories
setup_directories() {
    log_info "Setting up directories..."
    mkdir -p "$LOGS_DIR"
    mkdir -p "$BUILD_DIR"
    log_success "Directories created"
}

# Check if simulator exists and is available
check_simulator() {
    log_info "Checking simulator availability..."
    
    if xcrun simctl list devices | grep -q "$SIMULATOR_UUID"; then
        log_success "Simulator found: $SIMULATOR_UUID"
        
        # Get simulator status
        local status=$(xcrun simctl list devices | grep "$SIMULATOR_UUID" | sed 's/.*(\(.*\))/\1/')
        log_info "Simulator status: $status"
        
        # Boot simulator if needed
        if [[ "$status" == "Shutdown" ]]; then
            log_info "Booting simulator..."
            xcrun simctl boot "$SIMULATOR_UUID"
            sleep 5  # Give it time to boot
            log_success "Simulator booted"
        fi
    else
        log_error "Simulator not found: $SIMULATOR_UUID"
        log_info "Available simulators:"
        xcrun simctl list devices | grep "iPhone 16 Pro"
        exit 1
    fi
}

# Use background logging system instead of direct log capture
start_background_logs() {
    log_info "Starting background-first logging system..."
    
    if [[ ! -x "$BACKGROUND_LOGGER" ]]; then
        log_error "Background logging script not found or not executable: $BACKGROUND_LOGGER"
        log_info "Making it executable..."
        chmod +x "$BACKGROUND_LOGGER"
    fi
    
    # Start the background logging system
    "$BACKGROUND_LOGGER" start-logs
    
    if [[ $? -eq 0 ]]; then
        log_success "Background logging system active"
        log_info "Runtime logs: ${LOGS_DIR}/runtime/latest.log"
        return 0
    else
        log_error "Failed to start background logging"
        return 1
    fi
}

# Check background logging status
check_logging_status() {
    if [[ -x "$BACKGROUND_LOGGER" ]]; then
        local status=$("$BACKGROUND_LOGGER" status 2>/dev/null | grep "Logging Status:" | cut -d: -f2 | xargs)
        echo "$status"
    else
        echo "UNAVAILABLE"
    fi
}

# Build app using background-first approach
build_app() {
    log_info "Building app (non-intrusive mode)..."
    
    # Ensure logging is active first
    local log_status=$(check_logging_status)
    if [[ "$log_status" != "ACTIVE" ]]; then
        log_warning "Background logging not active, starting it first..."
        if ! start_background_logs; then
            log_error "Cannot build without active logging"
            return 1
        fi
    fi
    
    # Check if xcodeproj exists
    if [ ! -d "$XCODE_PROJECT" ]; then
        log_warning "Xcode project not found. Generating with XcodeGen..."
        if command -v xcodegen &> /dev/null; then
            (cd "${PROJECT_ROOT}/ClaudeCodeUI-iOS" && xcodegen)
            log_success "Xcode project generated"
        else
            log_error "XcodeGen not installed. Run: brew install xcodegen"
            return 1
        fi
    fi
    
    # Use background logger's non-intrusive build
    "$BACKGROUND_LOGGER" build
    
    if [[ $? -eq 0 ]]; then
        log_success "Build completed successfully"
        log_info "Build logs: ${LOGS_DIR}/build/latest.log"
        return 0
    else
        log_error "Build failed - check ${LOGS_DIR}/build/latest.log"
        return 1
    fi
}

# Install app without launching (prevents restart)
install_app() {
    log_info "Installing app (without launch)..."
    
    "$BACKGROUND_LOGGER" install
    
    if [[ $? -eq 0 ]]; then
        log_success "App installed successfully"
        return 0
    else
        log_error "Failed to install app"
        return 1
    fi
}

# Launch app attached to existing logs
launch_app() {
    log_info "Launching app (attached to existing logs)..."
    
    "$BACKGROUND_LOGGER" launch
    
    if [[ $? -eq 0 ]]; then
        log_success "App launched successfully"
        # Also open simulator window
        open -a Simulator
        return 0
    else
        log_error "Failed to launch app"
        return 1
    fi
}

# Combined install and launch for convenience
install_and_launch() {
    if install_app && launch_app; then
        log_success "App installed and launched successfully"
        return 0
    else
        log_error "Failed to install and launch app"
        return 1
    fi
}

# Stop background logging processes
stop_background_logs() {
    log_info "Stopping background logging..."
    "$BACKGROUND_LOGGER" stop
    log_success "Background logging stopped"
}

# Clean up on exit
cleanup() {
    log_info "Cleaning up..."
    # Background logger handles its own cleanup
    log_debug "Cleanup complete"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    echo "==========================================="
    echo "Claude Code iOS - Simulator Automation"
    echo "Background-First Logging Edition"
    echo "iPhone 16 Pro Max (iOS 18.6)"
    echo "UUID: $SIMULATOR_UUID"
    echo "==========================================="
    echo
    
    # Set up trap for cleanup
    trap cleanup EXIT
    
    # Parse command line arguments
    case "${1:-all}" in
        logs)
            # Start background logging only
            setup_directories
            check_simulator
            start_background_logs
            log_info "Background logging active. Check ${LOGS_DIR}/runtime/latest.log"
            ;;
        build)
            # Build with background logging
            setup_directories
            check_simulator
            build_app
            ;;
        install)
            # Install without launch
            check_simulator
            install_app
            ;;
        launch)
            # Launch with existing logs
            check_simulator
            launch_app
            ;;
        all|workflow|"")
            # Complete workflow: logs → build → install → launch
            log_info "Starting complete background-first workflow..."
            setup_directories
            check_simulator
            
            # Step 1: Start background logging
            if ! start_background_logs; then
                log_error "Failed to start logging"
                exit 1
            fi
            
            # Step 2: Build (non-intrusive)
            if ! build_app; then
                log_error "Build failed"
                exit 1
            fi
            
            # Step 3: Install and launch
            if ! install_and_launch; then
                log_error "Failed to install/launch"
                exit 1
            fi
            
            log_success "Complete workflow executed successfully!"
            log_info "Runtime logs: ${LOGS_DIR}/runtime/latest.log"
            log_info "Build logs: ${LOGS_DIR}/build/latest.log"
            ;;
        stop)
            # Stop background logging
            stop_background_logs
            ;;
        clean)
            log_info "Cleaning all artifacts..."
            "$BACKGROUND_LOGGER" clean
            rm -rf "$BUILD_DIR"
            log_success "All artifacts cleaned"
            ;;
        status)
            check_simulator
            log_info "Logging status: $(check_logging_status)"
            "$BACKGROUND_LOGGER" health
            ;;
        mcp-build)
            # Special command for MCP-based builds from Claude
            log_mcp "MCP build mode - for use with XcodeBuildMCP tools"
            setup_directories
            check_simulator
            
            # Always start background logging first
            if ! start_background_logs; then
                log_error "Failed to start background logging"
                exit 1
            fi
            
            log_success "Background logging active - ready for MCP build commands"
            log_info "Use XcodeBuildMCP tools in Claude to build and run the app"
            log_info "Logs will be captured at: ${LOGS_DIR}/runtime/latest.log"
            ;;
        help|--help|-h)
            echo "Usage: $0 [command]"
            echo
            echo "Commands:"
            echo "  workflow    - Run complete workflow: logs → build → install → launch (default)"
            echo "  logs        - Start background logging only"
            echo "  build       - Build app (with auto-start of background logs)"
            echo "  install     - Install app without launching"
            echo "  launch      - Launch app (attached to existing logs)"
            echo "  stop        - Stop background logging"
            echo "  clean       - Clean all build and log artifacts"
            echo "  status      - Check simulator and logging status"
            echo "  mcp-build   - Prepare for MCP-based builds from Claude"
            echo "  help        - Show this help message"
            echo
            echo "Environment:"
            echo "  Simulator UUID: $SIMULATOR_UUID"
            echo "  Bundle ID: $APP_BUNDLE_ID"
            echo "  Runtime Logs: ${LOGS_DIR}/runtime/"
            echo "  Build Logs: ${LOGS_DIR}/build/"
            echo "  Background Logger: $BACKGROUND_LOGGER"
            echo
            echo "Background-First Workflow:"
            echo "  1. Start background logging BEFORE any build/launch"
            echo "  2. Build app without attaching new log streams"
            echo "  3. Install app without launching"
            echo "  4. Launch app attached to existing logs"
            echo
            echo "This prevents app restarts and log size issues!"
            ;;
        *)
            log_error "Unknown command: $1"
            echo "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
