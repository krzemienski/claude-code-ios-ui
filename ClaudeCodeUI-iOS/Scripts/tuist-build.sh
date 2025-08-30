#!/bin/bash

# Tuist Build Script - Primary build automation with comprehensive logging
# Author: Claude Code Agent - Tuist Build Specialist
# Created: $(date '+%Y-%m-%d %H:%M:%S')

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
BUILD_LOG="$LOG_DIR/tuist-build-$(date '+%Y%m%d_%H%M%S').log"
ERROR_LOG="$LOG_DIR/tuist-build-errors-$(date '+%Y%m%d_%H%M%S').log"
PERFORMANCE_LOG="$LOG_DIR/tuist-build-performance.log"

# Default configuration
SCHEME=""
CONFIGURATION="Debug"
CLEAN_BUILD=false
NO_CACHE=false
PARALLEL_BUILD=true
ENABLE_INSIGHTS=true
MAX_RETRIES=3
VERBOSE=false

# Available schemes in the project
AVAILABLE_SCHEMES=("ClaudeCodeUI" "ClaudeCodeUITests" "ClaudeCodeUIUITests" "ClaudeCodeUIIntegrationTests")

# =============================================================================
# Utility Functions
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        INFO)  echo -e "${GREEN}[INFO]${NC} $message" | tee -a "$BUILD_LOG" ;;
        WARN)  echo -e "${YELLOW}[WARN]${NC} $message" | tee -a "$BUILD_LOG" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} $message" | tee -a "$BUILD_LOG" "$ERROR_LOG" ;;
        DEBUG) [[ "$VERBOSE" == true ]] && echo -e "${BLUE}[DEBUG]${NC} $message" | tee -a "$BUILD_LOG" ;;
        SUCCESS) echo -e "${GREEN}[SUCCESS]${NC} $message" | tee -a "$BUILD_LOG" ;;
        *) echo "$message" | tee -a "$BUILD_LOG" ;;
    esac
}

show_progress() {
    local message="$1"
    echo -e "${CYAN}⚡${NC} $message"
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [SCHEME]

Tuist Build Script - Advanced build automation with logging and performance tracking

OPTIONS:
    -c, --configuration CONFIG  Build configuration (Debug/Release) [default: Debug]
    --clean                     Perform clean build
    --no-cache                  Disable binary cache
    --no-parallel              Disable parallel build
    --no-insights              Disable build insights tracking
    -r, --retry COUNT          Maximum retry attempts [default: 3]
    -v, --verbose              Enable verbose logging
    -h, --help                 Show this help message

SCHEME:
    One of: ${AVAILABLE_SCHEMES[*]}
    If not specified, builds all schemes

EXAMPLES:
    $0                              # Build all schemes with Debug configuration
    $0 ClaudeCodeUI                 # Build main app only
    $0 --configuration Release ClaudeCodeUI  # Release build of main app
    $0 --clean --no-cache           # Clean build without cache
    $0 --verbose ClaudeCodeUITests  # Verbose build of tests

LOGS:
    Build logs: $LOG_DIR/
    Performance: $PERFORMANCE_LOG
    Errors: *-errors-*.log
EOF
}

validate_scheme() {
    local scheme="$1"
    for available in "${AVAILABLE_SCHEMES[@]}"; do
        if [[ "$available" == "$scheme" ]]; then
            return 0
        fi
    done
    return 1
}

setup_environment() {
    log INFO "Setting up build environment..."
    
    # Ensure Tuist is in PATH
    export PATH="/opt/homebrew/bin:$PATH"
    
    # Create log directory
    mkdir -p "$LOG_DIR"
    
    # Change to project root
    cd "$PROJECT_ROOT"
    
    # Log environment info
    {
        echo "=== Build Environment ==="
        echo "Date: $(date)"
        echo "User: $(whoami)"
        echo "Project: $PROJECT_ROOT"
        echo "Xcode: $(xcode-select --print-path 2>/dev/null || echo 'Not found')"
        echo "Tuist: $(tuist version 2>/dev/null || echo 'Not found')"
        echo "Configuration: $CONFIGURATION"
        echo "Scheme: ${SCHEME:-'ALL'}"
        echo "Clean Build: $CLEAN_BUILD"
        echo "Cache Disabled: $NO_CACHE"
        echo "=========================="
    } | tee -a "$BUILD_LOG"
}

check_dependencies() {
    log INFO "Checking dependencies..."
    
    # Check if tuist is available
    if ! command -v tuist &> /dev/null; then
        log ERROR "Tuist is not installed or not in PATH"
        log ERROR "Install with: curl -Ls https://install.tuist.io | bash"
        exit 1
    fi
    
    # Check if xcbeautify is available (optional but recommended)
    if command -v xcbeautify &> /dev/null; then
        log DEBUG "xcbeautify is available for better output formatting"
        XCBEAUTIFY_AVAILABLE=true
    else
        log DEBUG "xcbeautify not found - install with 'brew install xcbeautify' for better output"
        XCBEAUTIFY_AVAILABLE=false
    fi
    
    log SUCCESS "Dependencies check passed"
}

# =============================================================================
# Build Functions
# =============================================================================

generate_project() {
    log INFO "Generating Xcode project..."
    local start_time=$(date +%s)
    
    local cmd="tuist generate"
    if [[ "$NO_CACHE" == true ]]; then
        cmd="$cmd --no-binary-cache"
    fi
    
    if [[ "$VERBOSE" == true ]]; then
        eval "$cmd" 2>&1 | tee -a "$BUILD_LOG"
    else
        eval "$cmd" >> "$BUILD_LOG" 2>&1
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo "$(date '+%Y-%m-%d %H:%M:%S'),generate,$duration" >> "$PERFORMANCE_LOG"
    
    log SUCCESS "Project generation completed in ${duration}s"
}

build_scheme() {
    local scheme="$1"
    log INFO "Building scheme: $scheme"
    local start_time=$(date +%s)
    
    # Construct build command
    local cmd="tuist build $scheme"
    
    # Add configuration
    cmd="$cmd -- -configuration $CONFIGURATION"
    
    # Add additional flags
    if [[ "$PARALLEL_BUILD" == true ]]; then
        cmd="$cmd -parallelizeTargets"
    fi
    
    if [[ "$CLEAN_BUILD" == true ]]; then
        cmd="$cmd clean build"
    else
        cmd="$cmd build"
    fi
    
    # Add result bundle path for better analysis
    local result_bundle="$LOG_DIR/build-results-$scheme-$(date '+%Y%m%d_%H%M%S').xcresult"
    cmd="$cmd -resultBundlePath '$result_bundle'"
    
    # Execute build with retries
    local attempt=1
    while [[ $attempt -le $MAX_RETRIES ]]; do
        log INFO "Build attempt $attempt/$MAX_RETRIES for $scheme"
        
        if [[ "$XCBEAUTIFY_AVAILABLE" == true ]] && [[ "$VERBOSE" == true ]]; then
            if eval "$cmd" 2>&1 | tee -a "$BUILD_LOG" | xcbeautify; then
                break
            fi
        else
            if eval "$cmd" >> "$BUILD_LOG" 2>&1; then
                break
            fi
        fi
        
        if [[ $attempt -eq $MAX_RETRIES ]]; then
            log ERROR "Build failed for $scheme after $MAX_RETRIES attempts"
            return 1
        fi
        
        log WARN "Build attempt $attempt failed, retrying in 5 seconds..."
        sleep 5
        ((attempt++))
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo "$(date '+%Y-%m-%d %H:%M:%S'),build-$scheme,$duration" >> "$PERFORMANCE_LOG"
    
    log SUCCESS "Build completed for $scheme in ${duration}s"
    
    # Run build insights if enabled
    if [[ "$ENABLE_INSIGHTS" == true ]]; then
        log INFO "Collecting build insights for $scheme..."
        if tuist inspect build >> "$BUILD_LOG" 2>&1; then
            log DEBUG "Build insights collected successfully"
        else
            log WARN "Failed to collect build insights (non-fatal)"
        fi
    fi
}

build_all_schemes() {
    log INFO "Building all schemes..."
    local total_start_time=$(date +%s)
    local failed_schemes=()
    
    for scheme in "${AVAILABLE_SCHEMES[@]}"; do
        if ! build_scheme "$scheme"; then
            failed_schemes+=("$scheme")
        fi
    done
    
    local total_end_time=$(date +%s)
    local total_duration=$((total_end_time - total_start_time))
    echo "$(date '+%Y-%m-%d %H:%M:%S'),build-all,$total_duration" >> "$PERFORMANCE_LOG"
    
    if [[ ${#failed_schemes[@]} -eq 0 ]]; then
        log SUCCESS "All schemes built successfully in ${total_duration}s"
        return 0
    else
        log ERROR "Failed schemes: ${failed_schemes[*]}"
        return 1
    fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--configuration)
                CONFIGURATION="$2"
                shift 2
                ;;
            --clean)
                CLEAN_BUILD=true
                shift
                ;;
            --no-cache)
                NO_CACHE=true
                shift
                ;;
            --no-parallel)
                PARALLEL_BUILD=false
                shift
                ;;
            --no-insights)
                ENABLE_INSIGHTS=false
                shift
                ;;
            -r|--retry)
                MAX_RETRIES="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                log ERROR "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [[ -z "$SCHEME" ]]; then
                    SCHEME="$1"
                else
                    log ERROR "Multiple schemes specified. Use only one scheme or none for all."
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate scheme if specified
    if [[ -n "$SCHEME" ]] && ! validate_scheme "$SCHEME"; then
        log ERROR "Invalid scheme: $SCHEME"
        log ERROR "Available schemes: ${AVAILABLE_SCHEMES[*]}"
        exit 1
    fi
    
    # Validate configuration
    if [[ "$CONFIGURATION" != "Debug" ]] && [[ "$CONFIGURATION" != "Release" ]]; then
        log ERROR "Invalid configuration: $CONFIGURATION. Must be Debug or Release."
        exit 1
    fi
    
    log INFO "Starting Tuist build process..."
    show_progress "Initializing build environment"
    
    # Setup and checks
    setup_environment
    check_dependencies
    
    # Generate project
    show_progress "Generating Xcode project"
    if ! generate_project; then
        log ERROR "Project generation failed"
        exit 1
    fi
    
    # Build
    show_progress "Building project"
    local build_success=false
    
    if [[ -n "$SCHEME" ]]; then
        if build_scheme "$SCHEME"; then
            build_success=true
        fi
    else
        if build_all_schemes; then
            build_success=true
        fi
    fi
    
    # Final status
    if [[ "$build_success" == true ]]; then
        log SUCCESS "🎉 Build process completed successfully!"
        log INFO "📊 Logs available at: $LOG_DIR"
        log INFO "📈 Performance data: $PERFORMANCE_LOG"
        exit 0
    else
        log ERROR "❌ Build process failed!"
        log ERROR "📋 Check logs at: $BUILD_LOG"
        log ERROR "🚨 Error details: $ERROR_LOG"
        exit 1
    fi
}

# Handle script interruption
trap 'log ERROR "Build interrupted by user"; exit 130' INT TERM

# Execute main function
main "$@"