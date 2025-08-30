#!/bin/bash

# Tuist Watch Script - Background logging and monitoring with real-time insights
# Author: Claude Code Agent - Tuist Build Specialist
# Created: $(date '+%Y-%m-%d %H:%M:%S')

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
WATCH_LOG="$LOG_DIR/tuist-watch-$(date '+%Y%m%d_%H%M%S').log"
MONITOR_LOG="$LOG_DIR/tuist-monitor.log"
METRICS_LOG="$LOG_DIR/tuist-metrics-$(date '+%Y%m%d_%H%M%S').csv"
PID_FILE="$LOG_DIR/tuist-watch.pid"

# Watch configuration
WATCH_INTERVAL=5
MONITOR_BUILD_TIMES=true
MONITOR_FILE_CHANGES=true
MONITOR_CACHE_USAGE=true
MONITOR_SYSTEM_RESOURCES=true
AUTO_REBUILD=false
NOTIFICATION_ENABLED=true
WEBHOOK_URL=""
BACKGROUND_MODE=false
VERBOSE=false
MAX_LOG_SIZE="100M"
LOG_RETENTION_DAYS=7

# File patterns to watch
WATCH_PATTERNS=("*.swift" "*.m" "*.h" "*.plist" "*.storyboard" "*.xib" "Project.swift" "Tuist.swift")
IGNORE_PATTERNS=(".*" "*.log" "*.tmp" "DerivedData" "build" ".build")

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
    local log_entry="[$timestamp] [$level] $message"
    
    case "$level" in
        INFO)  echo -e "${GREEN}[INFO]${NC} $message" | tee -a "$WATCH_LOG" ;;
        WARN)  echo -e "${YELLOW}[WARN]${NC} $message" | tee -a "$WATCH_LOG" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} $message" | tee -a "$WATCH_LOG" ;;
        DEBUG) [[ "$VERBOSE" == true ]] && echo -e "${BLUE}[DEBUG]${NC} $message" | tee -a "$WATCH_LOG" ;;
        SUCCESS) echo -e "${GREEN}[SUCCESS]${NC} $message" | tee -a "$WATCH_LOG" ;;
        MONITOR) echo -e "${CYAN}[MONITOR]${NC} $message" | tee -a "$MONITOR_LOG" ;;
        *) echo "$log_entry" | tee -a "$WATCH_LOG" ;;
    esac
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [COMMAND]

Tuist Watch Script - Background logging and monitoring with real-time insights

COMMANDS:
    start       Start background monitoring (default)
    stop        Stop background monitoring
    status      Show monitoring status
    logs        Show recent log entries
    metrics     Display performance metrics
    restart     Restart monitoring

OPTIONS:
    -i, --interval SECONDS     Monitor check interval [default: 5]
    --no-build-times           Disable build time monitoring
    --no-file-changes          Disable file change monitoring
    --no-cache-usage           Disable cache usage monitoring
    --no-system-resources      Disable system resource monitoring
    --auto-rebuild             Automatically rebuild on file changes
    --notifications            Enable desktop notifications
    --webhook URL              Send notifications to webhook URL
    -b, --background           Run in background daemon mode
    --max-log-size SIZE        Maximum log file size [default: 100M]
    --retention-days DAYS      Log retention in days [default: 7]
    -v, --verbose              Enable verbose logging
    -h, --help                 Show this help message

MONITORING FEATURES:
    📊 Build Performance Tracking
    📁 File System Change Detection
    💾 Cache Usage Analysis
    🖥️  System Resource Monitoring
    🔔 Real-time Notifications
    📈 Performance Metrics & Trends
    🤖 Auto-rebuild on Changes (optional)

EXAMPLES:
    $0 start                         # Start monitoring with default settings
    $0 start --auto-rebuild          # Monitor with automatic rebuilds
    $0 --interval 10 --verbose start # Monitor every 10 seconds, verbose
    $0 stop                          # Stop background monitoring
    $0 metrics                       # Show performance metrics
    $0 logs --tail 50               # Show last 50 log entries

BACKGROUND MODE:
    When run in background mode, the script creates a daemon process
    Use 'stop' command or kill the PID to stop monitoring

LOGS & METRICS:
    Watch logs: $LOG_DIR/tuist-watch-*.log
    Monitor logs: $MONITOR_LOG
    Metrics: $METRICS_LOG
    PID file: $PID_FILE
EOF
}

setup_environment() {
    log INFO "Setting up watch environment..."
    
    # Ensure Tuist is in PATH
    export PATH="/opt/homebrew/bin:$PATH"
    
    # Create directories
    mkdir -p "$LOG_DIR"
    
    # Change to project root
    cd "$PROJECT_ROOT"
    
    # Setup log rotation
    setup_log_rotation
    
    # Log environment info
    {
        echo "=== Watch Environment ==="
        echo "Date: $(date)"
        echo "User: $(whoami)"
        echo "Project: $PROJECT_ROOT"
        echo "Watch Interval: ${WATCH_INTERVAL}s"
        echo "Auto Rebuild: $AUTO_REBUILD"
        echo "Background Mode: $BACKGROUND_MODE"
        echo "Monitor Build Times: $MONITOR_BUILD_TIMES"
        echo "Monitor File Changes: $MONITOR_FILE_CHANGES"
        echo "Monitor Cache Usage: $MONITOR_CACHE_USAGE"
        echo "Monitor System Resources: $MONITOR_SYSTEM_RESOURCES"
        echo "========================"
    } | tee -a "$WATCH_LOG"
}

setup_log_rotation() {
    # Rotate logs if they exceed max size
    for log_file in "$WATCH_LOG" "$MONITOR_LOG"; do
        if [[ -f "$log_file" ]]; then
            local size
            size=$(stat -f%z "$log_file" 2>/dev/null || echo 0)
            local max_bytes
            
            case "$MAX_LOG_SIZE" in
                *K|*k) max_bytes=$((${MAX_LOG_SIZE%[Kk]} * 1024)) ;;
                *M|*m) max_bytes=$((${MAX_LOG_SIZE%[Mm]} * 1024 * 1024)) ;;
                *G|*g) max_bytes=$((${MAX_LOG_SIZE%[Gg]} * 1024 * 1024 * 1024)) ;;
                *) max_bytes=$MAX_LOG_SIZE ;;
            esac
            
            if [[ $size -gt $max_bytes ]]; then
                mv "$log_file" "${log_file}.old"
                touch "$log_file"
                log DEBUG "Rotated log file: $log_file"
            fi
        fi
    done
    
    # Clean old logs
    find "$LOG_DIR" -name "tuist-*-*.log" -mtime "+$LOG_RETENTION_DAYS" -delete 2>/dev/null || true
}

# =============================================================================
# Monitoring Functions
# =============================================================================

get_build_metrics() {
    local build_log="$LOG_DIR/tuist-build-performance.log"
    
    if [[ ! -f "$build_log" ]]; then
        echo "0,0,0"
        return
    fi
    
    local total_builds
    local avg_time
    local last_build_time
    
    total_builds=$(wc -l < "$build_log" 2>/dev/null || echo 0)
    
    if [[ $total_builds -gt 0 ]]; then
        avg_time=$(awk -F',' '{sum+=$3; count++} END {if(count>0) print int(sum/count); else print 0}' "$build_log" 2>/dev/null || echo 0)
        last_build_time=$(tail -1 "$build_log" 2>/dev/null | cut -d',' -f3 || echo 0)
    else
        avg_time=0
        last_build_time=0
    fi
    
    echo "$total_builds,$avg_time,$last_build_time"
}

get_cache_metrics() {
    local cache_dir="$HOME/.tuist/Cache"
    local cache_size=0
    local cache_entries=0
    
    if [[ -d "$cache_dir" ]]; then
        cache_size=$(du -sk "$cache_dir" 2>/dev/null | cut -f1 || echo 0)
        cache_entries=$(find "$cache_dir" -type f 2>/dev/null | wc -l || echo 0)
    fi
    
    echo "$cache_size,$cache_entries"
}

get_system_metrics() {
    # CPU usage (simplified)
    local cpu_usage
    cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//' || echo 0)
    
    # Memory usage
    local memory_info
    memory_info=$(vm_stat 2>/dev/null || echo "Pages free: 0. Pages active: 0.")
    local free_pages
    local active_pages
    free_pages=$(echo "$memory_info" | grep "Pages free" | awk '{print $3}' | sed 's/\.//' || echo 0)
    active_pages=$(echo "$memory_info" | grep "Pages active" | awk '{print $3}' | sed 's/\.//' || echo 0)
    
    # Calculate memory usage percentage (simplified)
    local memory_usage=0
    if [[ $((free_pages + active_pages)) -gt 0 ]]; then
        memory_usage=$((active_pages * 100 / (free_pages + active_pages)))
    fi
    
    # Disk usage of project directory
    local disk_usage
    disk_usage=$(df -k "$PROJECT_ROOT" 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//' || echo 0)
    
    echo "$cpu_usage,$memory_usage,$disk_usage"
}

check_file_changes() {
    if [[ "$MONITOR_FILE_CHANGES" != true ]]; then
        return 0
    fi
    
    local changes_detected=false
    local change_summary=""
    
    # Check for recent file modifications (last minute)
    for pattern in "${WATCH_PATTERNS[@]}"; do
        local changed_files
        changed_files=$(find "$PROJECT_ROOT" -name "$pattern" -type f -mtime -1m 2>/dev/null || true)
        
        if [[ -n "$changed_files" ]]; then
            changes_detected=true
            local file_count
            file_count=$(echo "$changed_files" | wc -l)
            change_summary="$change_summary $pattern:$file_count"
        fi
    done
    
    if [[ "$changes_detected" == true ]]; then
        log MONITOR "File changes detected: $change_summary"
        
        if [[ "$AUTO_REBUILD" == true ]]; then
            log INFO "Auto-rebuild triggered by file changes"
            trigger_rebuild
        fi
        
        if [[ "$NOTIFICATION_ENABLED" == true ]]; then
            send_notification "File Changes Detected" "Changes in: $change_summary"
        fi
    fi
}

trigger_rebuild() {
    log INFO "Starting automatic rebuild..."
    local start_time=$(date +%s)
    
    if "$SCRIPT_DIR/tuist-build.sh" --quiet >> "$WATCH_LOG" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log SUCCESS "Automatic rebuild completed in ${duration}s"
        send_notification "Build Successful" "Automatic rebuild completed in ${duration}s"
    else
        log ERROR "Automatic rebuild failed"
        send_notification "Build Failed" "Automatic rebuild encountered errors"
    fi
}

send_notification() {
    local title="$1"
    local message="$2"
    
    if [[ "$NOTIFICATION_ENABLED" != true ]]; then
        return 0
    fi
    
    # Desktop notification (macOS)
    if command -v osascript &> /dev/null; then
        osascript -e "display notification \"$message\" with title \"Tuist Watch: $title\"" 2>/dev/null || true
    fi
    
    # Webhook notification
    if [[ -n "$WEBHOOK_URL" ]]; then
        local payload=$(cat <<EOF
{
    "title": "$title",
    "message": "$message",
    "timestamp": "$(date -Iseconds)",
    "project": "$(basename "$PROJECT_ROOT")"
}
EOF
        )
        
        curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$WEBHOOK_URL" &>/dev/null || true
    fi
}

collect_metrics() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local build_metrics
    local cache_metrics
    local system_metrics
    
    # Get metrics
    build_metrics=$(get_build_metrics)
    cache_metrics=$(get_cache_metrics)
    system_metrics=$(get_system_metrics)
    
    # CSV header if file doesn't exist
    if [[ ! -f "$METRICS_LOG" ]]; then
        echo "timestamp,total_builds,avg_build_time,last_build_time,cache_size_kb,cache_entries,cpu_usage,memory_usage,disk_usage" > "$METRICS_LOG"
    fi
    
    # Append metrics
    echo "$timestamp,$build_metrics,$cache_metrics,$system_metrics" >> "$METRICS_LOG"
    
    # Log summary if verbose
    if [[ "$VERBOSE" == true ]]; then
        IFS=',' read -r total_builds avg_build_time last_build_time cache_size_kb cache_entries cpu_usage memory_usage disk_usage <<< "$build_metrics,$cache_metrics,$system_metrics"
        log DEBUG "Metrics: Builds=$total_builds, Avg=${avg_build_time}s, Cache=${cache_size_kb}KB/${cache_entries} files, CPU=${cpu_usage}%, Mem=${memory_usage}%, Disk=${disk_usage}%"
    fi
}

# =============================================================================
# Command Functions
# =============================================================================

start_monitoring() {
    if is_monitoring_active; then
        log WARN "Monitoring is already active (PID: $(cat "$PID_FILE"))"
        return 1
    fi
    
    log INFO "Starting Tuist monitoring..."
    
    if [[ "$BACKGROUND_MODE" == true ]]; then
        # Start background daemon
        nohup "$0" --daemon-mode "${ORIGINAL_ARGS[@]}" > /dev/null 2>&1 &
        local daemon_pid=$!
        echo $daemon_pid > "$PID_FILE"
        log SUCCESS "Background monitoring started (PID: $daemon_pid)"
        log INFO "Use '$0 stop' to stop monitoring"
        log INFO "Use '$0 logs' to view logs"
        log INFO "Use '$0 status' to check status"
    else
        # Start foreground monitoring
        echo $$ > "$PID_FILE"
        monitor_loop
    fi
}

monitor_loop() {
    log INFO "Monitoring loop started (interval: ${WATCH_INTERVAL}s)"
    log INFO "Press Ctrl+C to stop monitoring"
    
    while true; do
        # Collect metrics
        collect_metrics
        
        # Check file changes
        check_file_changes
        
        # Log periodic status
        if [[ $(($(date +%s) % 300)) -eq 0 ]]; then  # Every 5 minutes
            log MONITOR "Monitoring active - $(date)"
        fi
        
        sleep "$WATCH_INTERVAL"
    done
}

stop_monitoring() {
    if [[ ! -f "$PID_FILE" ]]; then
        log WARN "No monitoring process found"
        return 1
    fi
    
    local pid
    pid=$(cat "$PID_FILE")
    
    if kill -0 "$pid" 2>/dev/null; then
        log INFO "Stopping monitoring process (PID: $pid)..."
        kill "$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null
        rm -f "$PID_FILE"
        log SUCCESS "Monitoring stopped"
    else
        log WARN "Process $pid not found, cleaning up PID file"
        rm -f "$PID_FILE"
    fi
}

is_monitoring_active() {
    if [[ ! -f "$PID_FILE" ]]; then
        return 1
    fi
    
    local pid
    pid=$(cat "$PID_FILE")
    
    if kill -0 "$pid" 2>/dev/null; then
        return 0
    else
        rm -f "$PID_FILE"
        return 1
    fi
}

show_status() {
    if is_monitoring_active; then
        local pid
        pid=$(cat "$PID_FILE")
        log SUCCESS "Monitoring is ACTIVE (PID: $pid)"
        
        # Show recent metrics
        if [[ -f "$METRICS_LOG" ]]; then
            local last_metric
            last_metric=$(tail -1 "$METRICS_LOG")
            echo "Latest metrics: $last_metric"
        fi
        
        # Show recent log entries
        echo ""
        echo "Recent log entries:"
        tail -5 "$WATCH_LOG" 2>/dev/null || echo "No recent logs"
    else
        log INFO "Monitoring is INACTIVE"
    fi
}

show_logs() {
    local lines=20
    
    if [[ "$1" == "--tail" ]] && [[ -n "$2" ]]; then
        lines="$2"
    fi
    
    echo "=== Last $lines log entries ==="
    tail -n "$lines" "$WATCH_LOG" 2>/dev/null || echo "No logs available"
    
    if [[ -f "$MONITOR_LOG" ]]; then
        echo ""
        echo "=== Last $lines monitor entries ==="
        tail -n "$lines" "$MONITOR_LOG" 2>/dev/null
    fi
}

show_metrics() {
    if [[ ! -f "$METRICS_LOG" ]]; then
        log WARN "No metrics data available"
        return 1
    fi
    
    echo "=== Performance Metrics Summary ==="
    
    # Show recent metrics
    echo "Recent metrics (last 10 entries):"
    tail -10 "$METRICS_LOG" | column -t -s','
    
    echo ""
    echo "=== Build Statistics ==="
    
    # Calculate statistics
    awk -F',' 'NR>1 {
        total_builds = $2
        if ($3 > 0) {
            build_times[NR] = $3
            build_count++
            sum += $3
            if ($3 > max_time || max_time == 0) max_time = $3
            if ($3 < min_time || min_time == 0) min_time = $3
        }
    }
    END {
        if (build_count > 0) {
            avg = sum / build_count
            printf "Total Builds: %d\n", total_builds
            printf "Average Build Time: %.1f seconds\n", avg
            printf "Min Build Time: %.1f seconds\n", min_time
            printf "Max Build Time: %.1f seconds\n", max_time
        } else {
            print "No build data available"
        }
    }' "$METRICS_LOG"
}

# =============================================================================
# Main Execution
# =============================================================================

cleanup_on_exit() {
    if [[ -f "$PID_FILE" ]] && [[ "$(cat "$PID_FILE")" == "$$" ]]; then
        rm -f "$PID_FILE"
    fi
    log INFO "Monitoring stopped"
    exit 0
}

main() {
    # Store original arguments for daemon mode
    ORIGINAL_ARGS=("$@")
    
    # Parse command line arguments
    local command=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            start|stop|status|logs|metrics|restart)
                if [[ -z "$command" ]]; then
                    command="$1"
                else
                    log ERROR "Multiple commands specified"
                    exit 1
                fi
                shift
                ;;
            --daemon-mode)
                # Internal flag for daemon mode
                BACKGROUND_MODE=false  # Already running in background
                shift
                ;;
            -i|--interval)
                WATCH_INTERVAL="$2"
                shift 2
                ;;
            --no-build-times)
                MONITOR_BUILD_TIMES=false
                shift
                ;;
            --no-file-changes)
                MONITOR_FILE_CHANGES=false
                shift
                ;;
            --no-cache-usage)
                MONITOR_CACHE_USAGE=false
                shift
                ;;
            --no-system-resources)
                MONITOR_SYSTEM_RESOURCES=false
                shift
                ;;
            --auto-rebuild)
                AUTO_REBUILD=true
                shift
                ;;
            --notifications)
                NOTIFICATION_ENABLED=true
                shift
                ;;
            --webhook)
                WEBHOOK_URL="$2"
                shift 2
                ;;
            -b|--background)
                BACKGROUND_MODE=true
                shift
                ;;
            --max-log-size)
                MAX_LOG_SIZE="$2"
                shift 2
                ;;
            --retention-days)
                LOG_RETENTION_DAYS="$2"
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
            --tail)
                # Special handling for logs command
                shift
                ;;
            -*)
                log ERROR "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                # Numeric argument for --tail
                if [[ "$1" =~ ^[0-9]+$ ]]; then
                    shift
                else
                    log ERROR "Unexpected argument: $1"
                    show_usage
                    exit 1
                fi
                ;;
        esac
    done
    
    # Default command
    if [[ -z "$command" ]]; then
        command="start"
    fi
    
    # Setup environment
    setup_environment
    
    # Set up signal handlers
    trap cleanup_on_exit INT TERM
    
    # Execute command
    case "$command" in
        start)
            start_monitoring
            ;;
        stop)
            stop_monitoring
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs "$@"
            ;;
        metrics)
            show_metrics
            ;;
        restart)
            stop_monitoring
            sleep 2
            start_monitoring
            ;;
        *)
            log ERROR "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"