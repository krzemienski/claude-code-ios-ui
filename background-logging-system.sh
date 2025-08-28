#!/bin/bash

# Background-First Logging System for iOS Development
# Prevents log size issues and app restarts by separating logging from build/launch
# Author: Claude Code Assistant
# Version: 1.0.0

set -e  # Exit on error

# ============================================================================
# CONFIGURATION
# ============================================================================

# Core settings
readonly SIMULATOR_UUID="A707456B-44DB-472F-9722-C88153CDFFA1"
readonly APP_BUNDLE_ID="com.claudecode.ui"
readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOGS_DIR="${PROJECT_ROOT}/logs"
readonly BUILD_DIR="${PROJECT_ROOT}/build"

# Log rotation settings
readonly MAX_LOG_SIZE_MB=50  # Maximum size per log file in MB
readonly MAX_LOG_FILES=10    # Maximum number of rotated logs to keep
readonly LOG_CHECK_INTERVAL=5  # Seconds between log size checks

# Process management
readonly PID_DIR="${LOGS_DIR}/.pids"
readonly LOG_MONITOR_PID_FILE="${PID_DIR}/log_monitor.pid"
readonly LOG_STREAM_PID_FILE="${PID_DIR}/log_stream.pid"
readonly BUILD_PID_FILE="${PID_DIR}/build.pid"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m' # No Color

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo -e "${MAGENTA}[DEBUG]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
    fi
}

# ============================================================================
# DIRECTORY SETUP
# ============================================================================

setup_directories() {
    log_info "Setting up directory structure..."
    mkdir -p "$LOGS_DIR"
    mkdir -p "$BUILD_DIR"
    mkdir -p "$PID_DIR"
    mkdir -p "${LOGS_DIR}/runtime"
    mkdir -p "${LOGS_DIR}/build"
    mkdir -p "${LOGS_DIR}/archived"
    
    # Clean old PID files on startup
    rm -f "${PID_DIR}"/*.pid
    
    log_success "Directory structure ready"
}

# ============================================================================
# LOG ROTATION SYSTEM
# ============================================================================

get_file_size_mb() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local size_bytes=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
        echo $((size_bytes / 1024 / 1024))
    else
        echo 0
    fi
}

rotate_log() {
    local log_file="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local basename=$(basename "$log_file" .log)
    local archived_name="${LOGS_DIR}/archived/${basename}_${timestamp}.log"
    
    log_info "Rotating log: $log_file -> $archived_name"
    
    # Move current log to archive
    mv "$log_file" "$archived_name"
    
    # Compress archived log
    gzip "$archived_name"
    
    # Clean old archived logs
    local archived_count=$(ls -1 "${LOGS_DIR}/archived/${basename}_"*.log.gz 2>/dev/null | wc -l)
    if [[ $archived_count -gt $MAX_LOG_FILES ]]; then
        ls -1t "${LOGS_DIR}/archived/${basename}_"*.log.gz | tail -n +$((MAX_LOG_FILES + 1)) | xargs rm -f
    fi
    
    # Create new empty log file
    touch "$log_file"
}

monitor_log_size() {
    local log_file="$1"
    local monitor_pid_file="$2"
    
    log_info "Starting log size monitor for: $log_file"
    
    (
        echo $$ > "$monitor_pid_file"
        
        while true; do
            if [[ -f "$log_file" ]]; then
                local size_mb=$(get_file_size_mb "$log_file")
                
                if [[ $size_mb -ge $MAX_LOG_SIZE_MB ]]; then
                    log_warning "Log size ($size_mb MB) exceeds limit ($MAX_LOG_SIZE_MB MB)"
                    
                    # Send SIGUSR1 to log stream process to pause
                    if [[ -f "$LOG_STREAM_PID_FILE" ]]; then
                        local stream_pid=$(cat "$LOG_STREAM_PID_FILE")
                        kill -USR1 "$stream_pid" 2>/dev/null || true
                    fi
                    
                    # Rotate the log
                    rotate_log "$log_file"
                    
                    # Send SIGUSR2 to log stream process to resume
                    if [[ -f "$LOG_STREAM_PID_FILE" ]]; then
                        kill -USR2 "$stream_pid" 2>/dev/null || true
                    fi
                fi
            fi
            
            sleep $LOG_CHECK_INTERVAL
        done
    ) &
    
    local monitor_pid=$!
    echo "$monitor_pid" > "$monitor_pid_file"
    log_success "Log monitor started (PID: $monitor_pid)"
}

# ============================================================================
# BACKGROUND LOGGING SYSTEM
# ============================================================================

start_background_logging() {
    local log_file="${LOGS_DIR}/runtime/app_$(date +%Y%m%d_%H%M%S).log"
    
    log_info "Starting background logging system..."
    
    # Kill any existing logging processes
    stop_logging_processes
    
    # Create log file
    touch "$log_file"
    ln -sf "$log_file" "${LOGS_DIR}/runtime/latest.log"
    
    # Start the log stream with broader capture
    # Using a less restrictive predicate to capture all app-related logs
    (
        echo $$ > "$LOG_STREAM_PID_FILE"
        
        # Trap signals for pause/resume during rotation
        trap 'sleep 0.5' USR1
        trap 'continue' USR2
        
        exec xcrun simctl spawn "$SIMULATOR_UUID" log stream \
            --level=debug \
            --style=json \
            --color=none \
            --source \
            --predicate 'subsystem CONTAINS "com.claudecode" OR 
                        processImagePath CONTAINS "ClaudeCode" OR
                        eventMessage CONTAINS[c] "claude"' \
            >> "$log_file" 2>&1
    ) &
    
    local stream_pid=$!
    echo "$stream_pid" > "$LOG_STREAM_PID_FILE"
    log_success "Log stream started (PID: $stream_pid)"
    
    # Start log size monitor
    monitor_log_size "$log_file" "$LOG_MONITOR_PID_FILE"
    
    # Verify logging is active
    sleep 2
    if kill -0 "$stream_pid" 2>/dev/null; then
        log_success "Background logging system active"
        echo "$log_file"
        return 0
    else
        log_error "Failed to start logging system"
        return 1
    fi
}

# ============================================================================
# BUILD SYSTEM (NON-INTRUSIVE)
# ============================================================================

build_without_restart() {
    local scheme="ClaudeCodeUI"
    local project_path="${PROJECT_ROOT}/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj"
    local build_log="${LOGS_DIR}/build/build_$(date +%Y%m%d_%H%M%S).log"
    
    log_info "Starting non-intrusive build process..."
    
    # Create build log
    touch "$build_log"
    ln -sf "$build_log" "${LOGS_DIR}/build/latest.log"
    
    # Build WITHOUT launching or installing
    # This prevents app restart and log interference
    (
        echo $$ > "$BUILD_PID_FILE"
        
        xcodebuild \
            -project "$project_path" \
            -scheme "$scheme" \
            -destination "platform=iOS Simulator,id=$SIMULATOR_UUID" \
            -derivedDataPath "$BUILD_DIR" \
            -configuration Debug \
            -quiet \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            COMPILER_INDEX_STORE_ENABLE=NO \
            build \
            > "$build_log" 2>&1
    ) &
    
    local build_pid=$!
    echo "$build_pid" > "$BUILD_PID_FILE"
    
    log_info "Build started in background (PID: $build_pid)"
    
    # Wait for build with timeout
    local timeout=300  # 5 minutes
    local elapsed=0
    
    while kill -0 "$build_pid" 2>/dev/null && [[ $elapsed -lt $timeout ]]; do
        sleep 5
        elapsed=$((elapsed + 5))
        log_debug "Build in progress... ($elapsed seconds)"
    done
    
    if kill -0 "$build_pid" 2>/dev/null; then
        log_error "Build timeout after $timeout seconds"
        kill "$build_pid" 2>/dev/null
        return 1
    fi
    
    # Check build result
    if wait "$build_pid"; then
        log_success "Build completed successfully"
        rm -f "$BUILD_PID_FILE"
        return 0
    else
        log_error "Build failed - check $build_log for details"
        return 1
    fi
}

# ============================================================================
# APP INSTALLATION (SEPARATE FROM BUILD)
# ============================================================================

install_app_only() {
    log_info "Installing app without restart..."
    
    local app_path="${BUILD_DIR}/Build/Products/Debug-iphonesimulator/ClaudeCodeUI.app"
    
    if [[ ! -d "$app_path" ]]; then
        app_path=$(find "$BUILD_DIR" -name "ClaudeCodeUI.app" -type d | head -n 1)
    fi
    
    if [[ -z "$app_path" ]] || [[ ! -d "$app_path" ]]; then
        log_error "App bundle not found"
        return 1
    fi
    
    # Uninstall quietly to avoid triggering logs
    xcrun simctl uninstall "$SIMULATOR_UUID" "$APP_BUNDLE_ID" 2>/dev/null || true
    
    # Install new version
    xcrun simctl install "$SIMULATOR_UUID" "$app_path"
    
    log_success "App installed at: $app_path"
    return 0
}

# ============================================================================
# APP LAUNCH (CONTROLLED)
# ============================================================================

launch_app_attached() {
    log_info "Launching app with existing logging..."
    
    # Launch without creating new log streams
    xcrun simctl launch \
        --console-pty \
        "$SIMULATOR_UUID" \
        "$APP_BUNDLE_ID" \
        2>/dev/null
    
    log_success "App launched (attached to existing logs)"
    return 0
}

# ============================================================================
# PROCESS MANAGEMENT
# ============================================================================

stop_logging_processes() {
    log_info "Stopping existing logging processes..."
    
    # Stop log monitor
    if [[ -f "$LOG_MONITOR_PID_FILE" ]]; then
        local pid=$(cat "$LOG_MONITOR_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            log_debug "Stopped log monitor (PID: $pid)"
        fi
        rm -f "$LOG_MONITOR_PID_FILE"
    fi
    
    # Stop log stream
    if [[ -f "$LOG_STREAM_PID_FILE" ]]; then
        local pid=$(cat "$LOG_STREAM_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            log_debug "Stopped log stream (PID: $pid)"
        fi
        rm -f "$LOG_STREAM_PID_FILE"
    fi
    
    # Kill any orphaned log processes
    pkill -f "simctl spawn $SIMULATOR_UUID log" 2>/dev/null || true
    
    log_success "Logging processes stopped"
}

get_logging_status() {
    local status="INACTIVE"
    
    if [[ -f "$LOG_STREAM_PID_FILE" ]]; then
        local pid=$(cat "$LOG_STREAM_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            status="ACTIVE"
        fi
    fi
    
    echo "$status"
}

# ============================================================================
# HEALTH CHECKS
# ============================================================================

verify_logging_health() {
    log_info "Verifying logging system health..."
    
    local all_good=true
    
    # Check log stream process
    if [[ -f "$LOG_STREAM_PID_FILE" ]]; then
        local pid=$(cat "$LOG_STREAM_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log_success "✓ Log stream active (PID: $pid)"
        else
            log_error "✗ Log stream dead"
            all_good=false
        fi
    else
        log_error "✗ Log stream not started"
        all_good=false
    fi
    
    # Check log monitor process
    if [[ -f "$LOG_MONITOR_PID_FILE" ]]; then
        local pid=$(cat "$LOG_MONITOR_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log_success "✓ Log monitor active (PID: $pid)"
        else
            log_error "✗ Log monitor dead"
            all_good=false
        fi
    else
        log_error "✗ Log monitor not started"
        all_good=false
    fi
    
    # Check log file growth
    local latest_log="${LOGS_DIR}/runtime/latest.log"
    if [[ -L "$latest_log" ]] && [[ -f "$(readlink "$latest_log")" ]]; then
        local size_mb=$(get_file_size_mb "$(readlink "$latest_log")")
        log_success "✓ Log file active (${size_mb} MB)"
    else
        log_error "✗ No active log file"
        all_good=false
    fi
    
    if $all_good; then
        log_success "Logging system healthy"
        return 0
    else
        log_error "Logging system unhealthy"
        return 1
    fi
}

# ============================================================================
# MAIN WORKFLOW
# ============================================================================

workflow_logs_first() {
    log_info "=== BACKGROUND-FIRST LOGGING WORKFLOW ==="
    
    # Step 1: Setup
    setup_directories
    
    # Step 2: Start background logging
    log_info "STEP 1/4: Starting background logging..."
    local log_file=$(start_background_logging)
    if [[ $? -ne 0 ]]; then
        log_error "Failed to start logging"
        return 1
    fi
    log_success "Logging active: $log_file"
    
    # Step 3: Verify logging health
    log_info "STEP 2/4: Verifying logging system..."
    sleep 3
    if ! verify_logging_health; then
        log_error "Logging system unhealthy"
        return 1
    fi
    
    # Step 4: Build without interference
    log_info "STEP 3/4: Building app (non-intrusive)..."
    if ! build_without_restart; then
        log_error "Build failed"
        return 1
    fi
    
    # Step 5: Install and launch
    log_info "STEP 4/4: Installing and launching app..."
    if install_app_only && launch_app_attached; then
        log_success "=== WORKFLOW COMPLETE ==="
        log_info "Runtime logs: ${LOGS_DIR}/runtime/latest.log"
        log_info "Build logs: ${LOGS_DIR}/build/latest.log"
        return 0
    else
        log_error "Failed to install/launch app"
        return 1
    fi
}

# ============================================================================
# COMMAND LINE INTERFACE
# ============================================================================

show_help() {
    cat << EOF
Background-First Logging System for iOS Development

Usage: $0 [command] [options]

Commands:
    start-logs      Start background logging only
    build          Build app without restarting logs
    install        Install app without launching
    launch         Launch app attached to existing logs
    workflow       Run complete workflow (logs → build → install → launch)
    status         Show logging system status
    health         Run health checks
    stop           Stop all logging processes
    clean          Clean all logs and build artifacts
    help           Show this help message

Options:
    -d, --debug    Enable debug output
    -s, --sim ID   Override simulator UUID (default: $SIMULATOR_UUID)

Examples:
    # Run complete workflow
    $0 workflow

    # Start logging then build separately
    $0 start-logs
    $0 build

    # Check system health
    $0 health

Environment Variables:
    DEBUG=1        Enable debug logging
    MAX_LOG_SIZE_MB   Maximum log file size (default: 50)
    MAX_LOG_FILES     Maximum rotated logs (default: 10)

EOF
}

# Parse command line
main() {
    local command="${1:-help}"
    shift || true
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--debug)
                export DEBUG=1
                shift
                ;;
            -s|--sim)
                SIMULATOR_UUID="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    
    case "$command" in
        start-logs)
            setup_directories
            start_background_logging
            ;;
        build)
            build_without_restart
            ;;
        install)
            install_app_only
            ;;
        launch)
            launch_app_attached
            ;;
        workflow)
            workflow_logs_first
            ;;
        status)
            echo "Logging Status: $(get_logging_status)"
            verify_logging_health
            ;;
        health)
            verify_logging_health
            ;;
        stop)
            stop_logging_processes
            ;;
        clean)
            stop_logging_processes
            rm -rf "$LOGS_DIR" "$BUILD_DIR"
            log_success "Cleaned all logs and build artifacts"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main
main "$@"