#!/bin/bash

# Claude Code iOS - Simulator Automation Script
# iPhone 16 Pro (iOS 26.0) Build, Log, and Launch Automation

set -e  # Exit on error

# ============================================================================
# CONFIGURATION
# ============================================================================

# Persistent Simulator UUID for iPhone 16 Pro (iOS 26.0)
readonly SIMULATOR_UUID="058A3C12-3207-436C-96D4-A92F1D5697DF"
readonly APP_BUNDLE_ID="com.claudecode.ui"
readonly SCHEME_NAME="ClaudeCodeUI"
readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOGS_DIR="${PROJECT_ROOT}/logs"
readonly BUILD_DIR="${PROJECT_ROOT}/build"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# ============================================================================
# FUNCTIONS
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
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

# Start log capture in background
start_log_capture() {
    local log_file="${LOGS_DIR}/simulator_$(date +%Y%m%d_%H%M%S).log"
    
    log_info "Starting log capture..."
    log_info "Log file: $log_file"
    
    # Kill any existing log processes for this simulator
    pkill -f "simctl spawn $SIMULATOR_UUID log" 2>/dev/null || true
    
    # Start new log capture
    xcrun simctl spawn "$SIMULATOR_UUID" log stream \
        --level=debug \
        --style=syslog \
        --predicate 'processImagePath CONTAINS "ClaudeCode"' \
        > "$log_file" 2>&1 &
    
    LOG_PID=$!
    echo "$LOG_PID" > "${LOGS_DIR}/.log_pid"
    
    log_success "Log capture started (PID: $LOG_PID)"
    
    # Create symlink to latest log
    ln -sf "$log_file" "${LOGS_DIR}/latest.log"
}

# Build the app
build_app() {
    log_info "Building app..."
    log_info "Scheme: $SCHEME_NAME"
    log_info "Destination: iPhone 16 Pro (iOS 26.0)"
    
    # Check if xcodeproj exists
    if [ ! -d "${PROJECT_ROOT}/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj" ]; then
        log_warning "Xcode project not found. Generating with XcodeGen..."
        if command -v xcodegen &> /dev/null; then
            (cd "$PROJECT_ROOT" && PKG_CONFIG_PATH="$PKG_CONFIG_PATH" xcodegen)
            log_success "Xcode project generated"
        else
            log_error "XcodeGen not installed. Run: brew install xcodegen"
            exit 1
        fi
    fi
    
    # Build with xcodebuild (with PKG_CONFIG_PATH for libssh2)
    if command -v xcbeautify &> /dev/null; then
        PKG_CONFIG_PATH="$PKG_CONFIG_PATH" xcodebuild \
            -project "${PROJECT_ROOT}/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj" \
            -scheme "$SCHEME_NAME" \
            -destination "platform=iOS Simulator,id=$SIMULATOR_UUID" \
            -derivedDataPath "$BUILD_DIR" \
            clean build \
            | xcbeautify || {
                log_error "Build failed"
                exit 1
            }
    else
        PKG_CONFIG_PATH="$PKG_CONFIG_PATH" xcodebuild \
            -project "${PROJECT_ROOT}/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj" \
            -scheme "$SCHEME_NAME" \
            -destination "platform=iOS Simulator,id=$SIMULATOR_UUID" \
            -derivedDataPath "$BUILD_DIR" \
            clean build || {
                log_error "Build failed"
                exit 1
            }
    fi
    
    log_success "Build completed successfully"
}

# Install and launch app
install_and_launch() {
    log_info "Installing app on simulator..."
    
    # Find the app bundle
    local app_path=$(find "$BUILD_DIR" -name "*.app" -type d | head -n 1)
    
    if [ -z "$app_path" ]; then
        log_error "App bundle not found in build directory"
        exit 1
    fi
    
    log_info "App bundle: $app_path"
    
    # Uninstall existing app (if any)
    xcrun simctl uninstall "$SIMULATOR_UUID" "$APP_BUNDLE_ID" 2>/dev/null || true
    
    # Install new app
    xcrun simctl install "$SIMULATOR_UUID" "$app_path"
    log_success "App installed"
    
    # Launch app
    log_info "Launching app..."
    xcrun simctl launch "$SIMULATOR_UUID" "$APP_BUNDLE_ID"
    log_success "App launched"
    
    # Open simulator window
    open -a Simulator
}

# Stop log capture
stop_log_capture() {
    if [ -f "${LOGS_DIR}/.log_pid" ]; then
        local pid=$(cat "${LOGS_DIR}/.log_pid")
        if kill -0 "$pid" 2>/dev/null; then
            log_info "Stopping log capture (PID: $pid)..."
            kill "$pid"
            rm "${LOGS_DIR}/.log_pid"
            log_success "Log capture stopped"
        fi
    fi
}

# Clean up on exit
cleanup() {
    log_info "Cleaning up..."
    stop_log_capture
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    echo "=========================================="
    echo "Claude Code iOS - Simulator Automation"
    echo "iPhone 16 Pro (iOS 26.0)"
    echo "UUID: $SIMULATOR_UUID"
    echo "=========================================="
    echo
    
    # Set up trap for cleanup
    trap cleanup EXIT
    
    # Parse command line arguments
    case "${1:-all}" in
        logs)
            setup_directories
            check_simulator
            start_log_capture
            log_info "Log capture running. Press Ctrl+C to stop."
            wait $LOG_PID
            ;;
        build)
            setup_directories
            check_simulator
            start_log_capture
            build_app
            ;;
        launch)
            check_simulator
            install_and_launch
            ;;
        all|"")
            setup_directories
            check_simulator
            start_log_capture
            build_app
            install_and_launch
            log_success "Complete workflow executed successfully!"
            log_info "Logs available at: ${LOGS_DIR}/latest.log"
            ;;
        clean)
            log_info "Cleaning build artifacts..."
            rm -rf "$BUILD_DIR"
            log_success "Build directory cleaned"
            ;;
        status)
            check_simulator
            ;;
        test)
            setup_directories
            check_simulator
            start_log_capture
            log_info "Running tests..."
            
            # Set PKG_CONFIG_PATH for libssh2
            export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:/opt/homebrew/opt/libssh2/lib/pkgconfig:/opt/homebrew/opt/openssl@3/lib/pkgconfig"
            
            # Generate project if needed
            if [ ! -d "${PROJECT_ROOT}/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj" ]; then
                log_warning "Xcode project not found. Generating with XcodeGen..."
                (cd "$PROJECT_ROOT" && PKG_CONFIG_PATH="$PKG_CONFIG_PATH" xcodegen)
                log_success "Xcode project generated"
            fi
            
            # Run unit tests
            log_info "Running unit tests..."
            PKG_CONFIG_PATH="$PKG_CONFIG_PATH" xcodebuild test \
                -project "${PROJECT_ROOT}/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj" \
                -scheme "$SCHEME_NAME" \
                -destination "platform=iOS Simulator,id=$SIMULATOR_UUID" \
                -derivedDataPath "$BUILD_DIR" \
                -enableCodeCoverage YES \
                2>&1 | tee "${LOGS_DIR}/test_$(date +%Y%m%d_%H%M%S).log" | xcbeautify || {
                    log_error "Tests failed"
                    exit 1
                }
            
            log_success "All tests passed!"
            
            # Generate coverage report if xcov is installed
            if command -v xcov &> /dev/null; then
                log_info "Generating coverage report..."
                xcov --project "${PROJECT_ROOT}/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj" \
                     --scheme "$SCHEME_NAME" \
                     --output_directory "${PROJECT_ROOT}/coverage" \
                     --derived_data_path "$BUILD_DIR"
                log_success "Coverage report generated in coverage/"
            fi
            ;;
        uitest)
            setup_directories
            check_simulator
            start_log_capture
            log_info "Running UI tests..."
            
            # Set PKG_CONFIG_PATH for libssh2
            export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:/opt/homebrew/opt/libssh2/lib/pkgconfig:/opt/homebrew/opt/openssl@3/lib/pkgconfig"
            
            # Generate project if needed
            if [ ! -d "${PROJECT_ROOT}/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj" ]; then
                log_warning "Xcode project not found. Generating with XcodeGen..."
                (cd "$PROJECT_ROOT" && PKG_CONFIG_PATH="$PKG_CONFIG_PATH" xcodegen)
                log_success "Xcode project generated"
            fi
            
            # Build and install app first
            build_app
            install_and_launch
            
            # Run UI tests
            log_info "Running UI tests..."
            PKG_CONFIG_PATH="$PKG_CONFIG_PATH" xcodebuild test \
                -project "${PROJECT_ROOT}/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj" \
                -scheme "$SCHEME_NAME" \
                -destination "platform=iOS Simulator,id=$SIMULATOR_UUID" \
                -derivedDataPath "$BUILD_DIR" \
                -only-testing:ClaudeCodeUITests \
                2>&1 | tee "${LOGS_DIR}/uitest_$(date +%Y%m%d_%H%M%S).log" | xcbeautify || {
                    log_error "UI tests failed"
                    exit 1
                }
            
            log_success "UI tests completed!"
            ;;
        help|--help|-h)
            echo "Usage: $0 [command]"
            echo
            echo "Commands:"
            echo "  all     - Run complete workflow (default)"
            echo "  logs    - Start log capture only"
            echo "  build   - Build app with logging"
            echo "  launch  - Install and launch app"
            echo "  test    - Run all unit tests with coverage"
            echo "  uitest  - Run UI tests"
            echo "  clean   - Clean build artifacts"
            echo "  status  - Check simulator status"
            echo "  help    - Show this help message"
            echo
            echo "Environment:"
            echo "  Simulator UUID: $SIMULATOR_UUID"
            echo "  Bundle ID: $APP_BUNDLE_ID"
            echo "  Logs: ${LOGS_DIR}/"
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
