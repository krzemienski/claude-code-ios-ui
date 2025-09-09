#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
# Tuist Build & Run Script for ClaudeCodeUI iOS
# ═══════════════════════════════════════════════════════════════════════════
# This script provides comprehensive Tuist commands for building, testing,
# and running the iOS application. All operations use Tuist exclusively.
#
# Based on Tuist 4.x documentation and project requirements
# Created: 2025-08-31
# ═══════════════════════════════════════════════════════════════════════════

set -e  # Exit on error

# Configuration
PROJECT_ROOT="/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS"
SCHEME="ClaudeCodeUI"
DEFAULT_PLATFORM="iOS"
DEFAULT_CONFIGURATION="Debug"
DEFAULT_DEVICE="iPhone 16 Pro"  # For simulator
MIN_IOS_VERSION="17.0"

# Log configuration
LOG_DIR="$PROJECT_ROOT/logs"
BUILD_LOG="$LOG_DIR/tuist-build-$(date '+%Y%m%d_%H%M%S').log"
ERROR_LOG="$LOG_DIR/tuist-build-errors-$(date '+%Y%m%d_%H%M%S').log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ═══════════════════════════════════════════════════════════════════════════
# Helper Functions
# ═══════════════════════════════════════════════════════════════════════════

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$BUILD_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$BUILD_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$BUILD_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$BUILD_LOG" "$ERROR_LOG"
}

log_progress() {
    echo -e "${CYAN}⚡${NC} $1" | tee -a "$BUILD_LOG"
}

# Ensure we're in the project directory
ensure_project_directory() {
    if [ "$PWD" != "$PROJECT_ROOT" ]; then
        log_info "Changing to project directory: $PROJECT_ROOT"
        cd "$PROJECT_ROOT"
    fi
}

# Setup log directory
setup_logging() {
    mkdir -p "$LOG_DIR"
    log_info "Logging to: $BUILD_LOG"
}

# ═══════════════════════════════════════════════════════════════════════════
# Tuist Commands - EXCLUSIVELY USING TUIST
# ═══════════════════════════════════════════════════════════════════════════

# 1. Generate Xcode project with Tuist
generate_project() {
    log_progress "Generating Xcode project with Tuist..."
    ensure_project_directory
    
    # Generate without opening Xcode automatically
    tuist generate --no-open 2>&1 | tee -a "$BUILD_LOG"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log_success "Project generated successfully!"
        log_info "Workspace: ClaudeCodeUI.xcworkspace"
    else
        log_error "Failed to generate project"
        exit 1
    fi
}

# 2. Build the project using Tuist
build_project() {
    local configuration="${1:-$DEFAULT_CONFIGURATION}"
    local platform="${2:-$DEFAULT_PLATFORM}"
    
    log_progress "Building project with Tuist..."
    log_info "Configuration: $configuration"
    log_info "Platform: $platform"
    ensure_project_directory
    
    # First ensure project is generated
    if [ ! -d "ClaudeCodeUI.xcworkspace" ]; then
        log_warning "Project not generated, generating now..."
        generate_project
    fi
    
    # Build using Tuist build command
    log_info "Executing: tuist build --configuration $configuration"
    tuist build \
        --configuration "$configuration" \
        --build-output-path .build \
        -- -destination "platform=$platform Simulator,name=$DEFAULT_DEVICE,OS=latest" \
           -allowProvisioningUpdates \
           -parallelizeTargets 2>&1 | tee -a "$BUILD_LOG"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log_success "Build completed successfully!"
        log_info "Build output: .build/"
    else
        log_error "Build failed"
        exit 1
    fi
}

# 3. Run tests using Tuist
run_tests() {
    local device="${1:-$DEFAULT_DEVICE}"
    
    log_progress "Running tests with Tuist..."
    log_info "Device: $device"
    ensure_project_directory
    
    # Ensure project is generated
    if [ ! -d "ClaudeCodeUI.xcworkspace" ]; then
        log_warning "Project not generated, generating now..."
        generate_project
    fi
    
    # Run tests using Tuist test command
    log_info "Executing: tuist test --device \"$device\""
    tuist test \
        --device "$device" \
        --configuration Debug \
        --result-bundle-path TestResults \
        -- -destination "platform=iOS Simulator,name=$device,OS=latest" \
           -parallel-testing-enabled YES \
           -parallel-testing-worker-count 2 2>&1 | tee -a "$BUILD_LOG"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log_success "Tests completed successfully!"
        log_info "Results saved to: TestResults/"
    else
        log_error "Tests failed"
        exit 1
    fi
}

# 4. Run on simulator using Tuist run command (CRITICAL FUNCTION)
run_on_simulator() {
    local device="${1:-$DEFAULT_DEVICE}"
    local configuration="${2:-$DEFAULT_CONFIGURATION}"
    
    log_progress "Running app on simulator with Tuist..."
    log_info "Device: $device"
    log_info "Configuration: $configuration"
    ensure_project_directory
    
    # Ensure project is built first
    if [ ! -d ".build" ]; then
        log_warning "Project not built, building now..."
        build_project "$configuration" "iOS"
    fi
    
    # Boot simulator if needed
    log_info "Preparing simulator..."
    xcrun simctl boot "$device" 2>/dev/null || true
    
    # Open simulator app
    open -a Simulator
    
    # Wait for simulator to be ready
    sleep 3
    
    # Run using Tuist run command - THIS IS THE CRITICAL COMMAND
    log_info "Executing: tuist run $SCHEME --device \"$device\" --configuration $configuration"
    tuist run "$SCHEME" \
        --configuration "$configuration" \
        --device "$device" \
        -- -destination "platform=iOS Simulator,name=$device,OS=latest" 2>&1 | tee -a "$BUILD_LOG"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log_success "App launched on simulator!"
        log_info "App is now running on: $device"
    else
        log_error "Failed to run app"
        exit 1
    fi
}

# 5. Clean build artifacts using Tuist
clean_build() {
    log_progress "Cleaning build artifacts with Tuist..."
    ensure_project_directory
    
    # Clean Tuist cache
    log_info "Cleaning Tuist cache..."
    tuist clean 2>&1 | tee -a "$BUILD_LOG"
    
    # Remove build directories
    log_info "Removing build directories..."
    rm -rf .build
    rm -rf DerivedData
    rm -rf TestResults
    
    # Remove generated workspace/project files
    log_info "Removing generated Xcode files..."
    rm -rf ClaudeCodeUI.xcworkspace
    rm -rf ClaudeCodeUI.xcodeproj
    rm -rf *.xcodeproj
    
    log_success "Clean completed!"
}

# 6. Full build and run cycle - Complete workflow
full_cycle() {
    local device="${1:-$DEFAULT_DEVICE}"
    
    log_progress "Starting full build and run cycle..."
    log_info "This will: clean → generate → build → test → run"
    
    # Clean first
    clean_build
    
    # Generate project
    generate_project
    
    # Build
    build_project "Debug" "iOS"
    
    # Run tests
    run_tests "$device"
    
    # Run on simulator
    run_on_simulator "$device" "Debug"
    
    log_success "Full cycle completed successfully!"
}

# 7. Build for release/archive
build_release() {
    log_progress "Building for Release configuration with Tuist..."
    ensure_project_directory
    
    # Generate if needed
    if [ ! -d "ClaudeCodeUI.xcworkspace" ]; then
        generate_project
    fi
    
    # Build release configuration using Tuist
    log_info "Executing: tuist build --configuration Release"
    tuist build \
        --configuration Release \
        --build-output-path .build/Release \
        -- -destination "generic/platform=iOS" \
           -archivePath .build/ClaudeCodeUI.xcarchive \
           archive 2>&1 | tee -a "$BUILD_LOG"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log_success "Release build completed!"
        log_info "Archive: .build/ClaudeCodeUI.xcarchive"
    else
        log_error "Release build failed"
        exit 1
    fi
}

# 8. Install dependencies with Tuist
install_dependencies() {
    log_progress "Installing dependencies with Tuist..."
    ensure_project_directory
    
    # Install using Tuist
    log_info "Executing: tuist install"
    tuist install 2>&1 | tee -a "$BUILD_LOG"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log_success "Dependencies installed!"
    else
        log_error "Failed to install dependencies"
        exit 1
    fi
}

# 9. Run specific test suite
run_test_suite() {
    local suite="${1:-All}"
    local device="${2:-$DEFAULT_DEVICE}"
    
    log_progress "Running test suite: $suite"
    ensure_project_directory
    
    if [ "$suite" == "All" ]; then
        run_tests "$device"
    else
        log_info "Executing: tuist test with specific suite"
        tuist test \
            --device "$device" \
            --configuration Debug \
            -- -destination "platform=iOS Simulator,name=$device,OS=latest" \
               -only-testing "$SCHEME/$suite" 2>&1 | tee -a "$BUILD_LOG"
        
        if [ ${PIPESTATUS[0]} -eq 0 ]; then
            log_success "Test suite $suite completed!"
        else
            log_error "Test suite $suite failed"
            exit 1
        fi
    fi
}

# 10. Validate project with Tuist
validate_project() {
    log_progress "Validating project configuration with Tuist..."
    ensure_project_directory
    
    # Generate and check for issues
    tuist generate --no-open 2>&1 | tee validation.log
    
    if grep -q "error\|Error\|ERROR" validation.log; then
        log_error "Validation found errors in project configuration"
        cat validation.log | tee -a "$ERROR_LOG"
        rm validation.log
        exit 1
    else
        log_success "Project validation passed!"
        rm validation.log
    fi
}

# 11. Quick simulator run (build if needed, then run)
quick_run() {
    local device="${1:-$DEFAULT_DEVICE}"
    
    log_progress "Quick run on simulator..."
    ensure_project_directory
    
    # Generate if needed
    if [ ! -d "ClaudeCodeUI.xcworkspace" ]; then
        generate_project
    fi
    
    # Build if needed
    if [ ! -d ".build" ]; then
        build_project "Debug" "iOS"
    fi
    
    # Run on simulator
    run_on_simulator "$device" "Debug"
}

# ═══════════════════════════════════════════════════════════════════════════
# Main Menu
# ═══════════════════════════════════════════════════════════════════════════

show_usage() {
    echo "═══════════════════════════════════════════════════════════════════════"
    echo "Tuist Build Script for ClaudeCodeUI iOS"
    echo "═══════════════════════════════════════════════════════════════════════"
    echo ""
    echo "This script EXCLUSIVELY uses Tuist commands for all operations."
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  generate          Generate Xcode project with Tuist"
    echo "  build [config]    Build project using Tuist (Debug/Release)"
    echo "  test [device]     Run tests with Tuist"
    echo "  run [device]      Run app on simulator with Tuist"
    echo "  quick [device]    Quick run (auto-build if needed)"
    echo "  clean             Clean all build artifacts"
    echo "  full              Full cycle: clean, generate, build, test, run"
    echo "  release           Build for Release/Archive"
    echo "  deps              Install dependencies with Tuist"
    echo "  validate          Validate project configuration"
    echo "  suite [name]      Run specific test suite"
    echo ""
    echo "Options:"
    echo "  config:   Debug (default) or Release"
    echo "  device:   Simulator device name (default: iPhone 15 Pro)"
    echo ""
    echo "Examples:"
    echo "  $0 generate                    # Generate Xcode project"
    echo "  $0 build                       # Build with Debug configuration"
    echo "  $0 build Release               # Build with Release configuration"
    echo "  $0 test                        # Run all tests"
    echo "  $0 run                         # Run on default simulator"
    echo "  $0 run \"iPhone 14\"             # Run on iPhone 14 simulator"
    echo "  $0 quick                       # Quick run (auto-builds if needed)"
    echo "  $0 full                        # Complete build and run cycle"
    echo "  $0 suite BackendIntegration    # Run specific test suite"
    echo ""
    echo "Logs:"
    echo "  Build logs: $LOG_DIR/"
    echo "  Latest log: $BUILD_LOG"
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════"
}

# ═══════════════════════════════════════════════════════════════════════════
# Main Script Entry Point
# ═══════════════════════════════════════════════════════════════════════════

main() {
    # Setup logging
    setup_logging
    
    # Log script start
    log_info "═══════════════════════════════════════════════════════════════════════"
    log_info "Tuist Build Script Started at $(date)"
    log_info "═══════════════════════════════════════════════════════════════════════"
    
    case "${1:-help}" in
        generate)
            generate_project
            ;;
        build)
            build_project "${2:-Debug}" "${3:-iOS}"
            ;;
        test)
            run_tests "${2:-$DEFAULT_DEVICE}"
            ;;
        run)
            run_on_simulator "${2:-$DEFAULT_DEVICE}" "${3:-Debug}"
            ;;
        quick)
            quick_run "${2:-$DEFAULT_DEVICE}"
            ;;
        clean)
            clean_build
            ;;
        full)
            full_cycle "${2:-$DEFAULT_DEVICE}"
            ;;
        release)
            build_release
            ;;
        deps|dependencies)
            install_dependencies
            ;;
        validate)
            validate_project
            ;;
        suite)
            run_test_suite "${2:-All}" "${3:-$DEFAULT_DEVICE}"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
    
    log_info "═══════════════════════════════════════════════════════════════════════"
    log_info "Script completed at $(date)"
    log_info "═══════════════════════════════════════════════════════════════════════"
}

# Handle script interruption
trap 'log_error "Script interrupted by user"; exit 130' INT TERM

# Run main function with all arguments
main "$@"