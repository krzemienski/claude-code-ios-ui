#!/bin/bash

# Tuist Clean Script - Comprehensive cleanup of builds, caches, and derived data
# Author: Claude Code Agent - Tuist Build Specialist
# Created: $(date '+%Y-%m-%d %H:%M:%S')

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
CLEAN_LOG="$LOG_DIR/tuist-clean-$(date '+%Y%m%d_%H%M%S').log"
ERROR_LOG="$LOG_DIR/tuist-clean-errors-$(date '+%Y%m%d_%H%M%S').log"

# Clean options
CLEAN_CACHE=true
CLEAN_DERIVED_DATA=true
CLEAN_BUILD_PRODUCTS=true
CLEAN_LOGS=false
CLEAN_WORKSPACE=false
CLEAN_SPM_CACHE=true
CLEAN_SIMULATOR_DATA=false
FORCE_CLEAN=false
VERBOSE=false
DRY_RUN=false

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
        INFO)  echo -e "${GREEN}[INFO]${NC} $message" | tee -a "$CLEAN_LOG" ;;
        WARN)  echo -e "${YELLOW}[WARN]${NC} $message" | tee -a "$CLEAN_LOG" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} $message" | tee -a "$CLEAN_LOG" "$ERROR_LOG" ;;
        DEBUG) [[ "$VERBOSE" == true ]] && echo -e "${BLUE}[DEBUG]${NC} $message" | tee -a "$CLEAN_LOG" ;;
        SUCCESS) echo -e "${GREEN}[SUCCESS]${NC} $message" | tee -a "$CLEAN_LOG" ;;
        DRY_RUN) echo -e "${CYAN}[DRY RUN]${NC} $message" | tee -a "$CLEAN_LOG" ;;
        *) echo "$message" | tee -a "$CLEAN_LOG" ;;
    esac
}

show_progress() {
    local message="$1"
    echo -e "${CYAN}🧹${NC} $message"
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Tuist Clean Script - Comprehensive cleanup of builds, caches, and derived data

OPTIONS:
    --no-cache              Skip cleaning Tuist binary cache
    --no-derived-data       Skip cleaning derived data
    --no-build-products     Skip cleaning build products
    --clean-logs            Clean old log files
    --clean-workspace       Clean generated workspace/project files
    --no-spm-cache          Skip cleaning Swift Package Manager cache
    --clean-simulator-data  Clean iOS Simulator data (use with caution)
    --force                 Force clean without confirmation prompts
    --dry-run               Show what would be cleaned without actually cleaning
    -v, --verbose           Enable verbose logging
    -h, --help              Show this help message

CLEANING TARGETS:
    ✓ Tuist binary cache (~/.tuist/Cache)
    ✓ Derived data (~/Library/Developer/Xcode/DerivedData)
    ✓ Build products (.build, Build directories)
    ✓ Swift Package Manager cache (~/.swiftpm)
    ○ Log files (logs directory) - optional
    ○ Generated workspace/project files - optional
    ○ iOS Simulator data - optional with --clean-simulator-data

EXAMPLES:
    $0                       # Standard cleanup
    $0 --clean-logs          # Include log cleanup
    $0 --clean-workspace --force  # Clean everything including workspace
    $0 --dry-run --verbose   # Preview what would be cleaned
    $0 --no-cache --no-derived-data  # Clean only build products

SAFETY:
    - Use --dry-run first to preview changes
    - Use --force to skip confirmation prompts
    - Workspace cleaning removes generated files (recoverable with tuist generate)
    - Simulator data cleaning affects all iOS apps (use with caution)

LOGS:
    Clean logs: $LOG_DIR/
    Errors: *-errors-*.log
EOF
}

get_size() {
    local path="$1"
    if [[ -d "$path" ]]; then
        du -sh "$path" 2>/dev/null | cut -f1 || echo "0B"
    elif [[ -f "$path" ]]; then
        ls -lh "$path" 2>/dev/null | awk '{print $5}' || echo "0B"
    else
        echo "0B"
    fi
}

confirm_action() {
    local message="$1"
    if [[ "$FORCE_CLEAN" == true ]]; then
        return 0
    fi
    
    echo -e "${YELLOW}⚠️  $message${NC}"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log INFO "Operation cancelled by user"
        return 1
    fi
    return 0
}

safe_remove() {
    local path="$1"
    local description="$2"
    
    if [[ ! -e "$path" ]]; then
        log DEBUG "$description not found: $path"
        return 0
    fi
    
    local size
    size=$(get_size "$path")
    
    if [[ "$DRY_RUN" == true ]]; then
        log DRY_RUN "Would remove $description: $path ($size)"
        return 0
    fi
    
    log INFO "Removing $description: $path ($size)"
    
    if rm -rf "$path" 2>/dev/null; then
        log SUCCESS "Removed $description ($size)"
    else
        log ERROR "Failed to remove $description: $path"
        return 1
    fi
}

# =============================================================================
# Cleanup Functions
# =============================================================================

setup_environment() {
    log INFO "Setting up cleanup environment..."
    
    # Ensure Tuist is in PATH
    export PATH="/opt/homebrew/bin:$PATH"
    
    # Create log directory if it doesn't exist
    mkdir -p "$LOG_DIR"
    
    # Change to project root
    cd "$PROJECT_ROOT"
    
    # Log environment info
    {
        echo "=== Cleanup Environment ==="
        echo "Date: $(date)"
        echo "User: $(whoami)"
        echo "Project: $PROJECT_ROOT"
        echo "Clean Cache: $CLEAN_CACHE"
        echo "Clean Derived Data: $CLEAN_DERIVED_DATA"
        echo "Clean Build Products: $CLEAN_BUILD_PRODUCTS"
        echo "Clean Logs: $CLEAN_LOGS"
        echo "Clean Workspace: $CLEAN_WORKSPACE"
        echo "Clean SPM Cache: $CLEAN_SPM_CACHE"
        echo "Clean Simulator Data: $CLEAN_SIMULATOR_DATA"
        echo "Force Clean: $FORCE_CLEAN"
        echo "Dry Run: $DRY_RUN"
        echo "========================="
    } | tee -a "$CLEAN_LOG"
}

clean_tuist_cache() {
    if [[ "$CLEAN_CACHE" != true ]]; then
        log DEBUG "Skipping Tuist cache cleanup"
        return 0
    fi
    
    show_progress "Cleaning Tuist cache"
    
    # Global Tuist cache
    local tuist_cache="$HOME/.tuist/Cache"
    if [[ -d "$tuist_cache" ]]; then
        safe_remove "$tuist_cache" "Tuist global cache"
    fi
    
    # Project-local cache
    local local_cache="$PROJECT_ROOT/.tuist/Cache"
    if [[ -d "$local_cache" ]]; then
        safe_remove "$local_cache" "Tuist local cache"
    fi
    
    # Tuist derived data
    local tuist_derived="$PROJECT_ROOT/.tuist-derived"
    if [[ -d "$tuist_derived" ]]; then
        safe_remove "$tuist_derived" "Tuist derived data"
    fi
    
    # Clean using tuist command if available
    if command -v tuist &> /dev/null; then
        if [[ "$DRY_RUN" == true ]]; then
            log DRY_RUN "Would run: tuist clean"
        else
            log INFO "Running tuist clean..."
            if tuist clean >> "$CLEAN_LOG" 2>&1; then
                log SUCCESS "Tuist clean command completed"
            else
                log WARN "Tuist clean command failed (non-fatal)"
            fi
        fi
    fi
    
    log SUCCESS "Tuist cache cleanup completed"
}

clean_derived_data() {
    if [[ "$CLEAN_DERIVED_DATA" != true ]]; then
        log DEBUG "Skipping derived data cleanup"
        return 0
    fi
    
    show_progress "Cleaning derived data"
    
    # Xcode derived data
    local derived_data_path="$HOME/Library/Developer/Xcode/DerivedData"
    if [[ -d "$derived_data_path" ]]; then
        # Find project-specific derived data
        local project_derived_data
        project_derived_data=$(find "$derived_data_path" -name "*ClaudeCodeUI*" -type d 2>/dev/null || true)
        
        if [[ -n "$project_derived_data" ]]; then
            for derived_path in $project_derived_data; do
                safe_remove "$derived_path" "Project derived data"
            done
        else
            log DEBUG "No project-specific derived data found"
        fi
        
        # Optionally clean all derived data
        if [[ "$FORCE_CLEAN" == true ]]; then
            if confirm_action "Clean ALL derived data? This affects all Xcode projects."; then
                safe_remove "$derived_data_path" "All Xcode derived data"
            fi
        fi
    fi
    
    # Archives
    local archives_path="$HOME/Library/Developer/Xcode/Archives"
    if [[ -d "$archives_path" ]] && [[ "$FORCE_CLEAN" == true ]]; then
        if confirm_action "Clean Xcode archives?"; then
            safe_remove "$archives_path" "Xcode archives"
        fi
    fi
    
    log SUCCESS "Derived data cleanup completed"
}

clean_build_products() {
    if [[ "$CLEAN_BUILD_PRODUCTS" != true ]]; then
        log DEBUG "Skipping build products cleanup"
        return 0
    fi
    
    show_progress "Cleaning build products"
    
    # Local build directories
    local build_dirs=("build" "Build" ".build" "DerivedData")
    
    for build_dir in "${build_dirs[@]}"; do
        if [[ -d "$PROJECT_ROOT/$build_dir" ]]; then
            safe_remove "$PROJECT_ROOT/$build_dir" "Build directory ($build_dir)"
        fi
    done
    
    # Xcode build products in workspace
    if [[ -d "$PROJECT_ROOT/ClaudeCodeUI.xcworkspace" ]]; then
        local workspace_build="$PROJECT_ROOT/ClaudeCodeUI.xcworkspace/xcuserdata"
        if [[ -d "$workspace_build" ]]; then
            safe_remove "$workspace_build" "Workspace user data"
        fi
    fi
    
    # Project user data
    if [[ -d "$PROJECT_ROOT/ClaudeCodeUI.xcodeproj" ]]; then
        local project_userdata="$PROJECT_ROOT/ClaudeCodeUI.xcodeproj/xcuserdata"
        if [[ -d "$project_userdata" ]]; then
            safe_remove "$project_userdata" "Project user data"
        fi
    fi
    
    log SUCCESS "Build products cleanup completed"
}

clean_spm_cache() {
    if [[ "$CLEAN_SPM_CACHE" != true ]]; then
        log DEBUG "Skipping Swift Package Manager cache cleanup"
        return 0
    fi
    
    show_progress "Cleaning Swift Package Manager cache"
    
    # SPM cache locations
    local spm_cache="$HOME/.swiftpm"
    local spm_build="$HOME/Library/Caches/org.swift.swiftpm"
    local spm_checkouts="$PROJECT_ROOT/.swiftpm"
    
    if [[ -d "$spm_cache" ]]; then
        safe_remove "$spm_cache" "Swift Package Manager cache"
    fi
    
    if [[ -d "$spm_build" ]]; then
        safe_remove "$spm_build" "Swift Package Manager build cache"
    fi
    
    if [[ -d "$spm_checkouts" ]]; then
        safe_remove "$spm_checkouts" "Local Swift Package checkouts"
    fi
    
    # Clean package resolved file
    if [[ -f "$PROJECT_ROOT/Package.resolved" ]]; then
        safe_remove "$PROJECT_ROOT/Package.resolved" "Package.resolved file"
    fi
    
    log SUCCESS "Swift Package Manager cache cleanup completed"
}

clean_logs() {
    if [[ "$CLEAN_LOGS" != true ]]; then
        log DEBUG "Skipping logs cleanup"
        return 0
    fi
    
    show_progress "Cleaning log files"
    
    # Clean old log files (keep last 10)
    if [[ -d "$LOG_DIR" ]]; then
        local log_count
        log_count=$(find "$LOG_DIR" -name "*.log" -type f 2>/dev/null | wc -l)
        
        if [[ $log_count -gt 10 ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                log DRY_RUN "Would clean $((log_count - 10)) old log files"
            else
                log INFO "Cleaning $((log_count - 10)) old log files..."
                find "$LOG_DIR" -name "*.log" -type f -not -path "*$(date '+%Y%m%d')*" | \
                    sort | head -n -10 | xargs rm -f
                log SUCCESS "Old log files cleaned"
            fi
        else
            log DEBUG "No old log files to clean"
        fi
    fi
}

clean_workspace() {
    if [[ "$CLEAN_WORKSPACE" != true ]]; then
        log DEBUG "Skipping workspace cleanup"
        return 0
    fi
    
    show_progress "Cleaning generated workspace and project files"
    
    if ! confirm_action "This will remove generated Xcode workspace/project files. You'll need to run 'tuist generate' to recreate them."; then
        return 0
    fi
    
    # Generated workspace
    local workspace="$PROJECT_ROOT/ClaudeCodeUI.xcworkspace"
    if [[ -d "$workspace" ]]; then
        safe_remove "$workspace" "Generated workspace"
    fi
    
    # Generated project
    local project="$PROJECT_ROOT/ClaudeCodeUI.xcodeproj"
    if [[ -d "$project" ]]; then
        safe_remove "$project" "Generated project"
    fi
    
    log SUCCESS "Workspace cleanup completed"
}

clean_simulator_data() {
    if [[ "$CLEAN_SIMULATOR_DATA" != true ]]; then
        log DEBUG "Skipping simulator data cleanup"
        return 0
    fi
    
    show_progress "Cleaning iOS Simulator data"
    
    if ! confirm_action "This will remove ALL iOS Simulator data for ALL apps. This cannot be undone!"; then
        return 0
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        log DRY_RUN "Would run: xcrun simctl erase all"
    else
        log INFO "Erasing all iOS Simulator data..."
        if xcrun simctl erase all >> "$CLEAN_LOG" 2>&1; then
            log SUCCESS "iOS Simulator data erased"
        else
            log ERROR "Failed to erase iOS Simulator data"
        fi
    fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-cache)
                CLEAN_CACHE=false
                shift
                ;;
            --no-derived-data)
                CLEAN_DERIVED_DATA=false
                shift
                ;;
            --no-build-products)
                CLEAN_BUILD_PRODUCTS=false
                shift
                ;;
            --clean-logs)
                CLEAN_LOGS=true
                shift
                ;;
            --clean-workspace)
                CLEAN_WORKSPACE=true
                shift
                ;;
            --no-spm-cache)
                CLEAN_SPM_CACHE=false
                shift
                ;;
            --clean-simulator-data)
                CLEAN_SIMULATOR_DATA=true
                shift
                ;;
            --force)
                FORCE_CLEAN=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
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
                log ERROR "Unexpected argument: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    if [[ "$DRY_RUN" == true ]]; then
        log INFO "🔍 DRY RUN MODE - No actual changes will be made"
    fi
    
    log INFO "Starting Tuist cleanup process..."
    
    # Setup
    setup_environment
    
    # Execute cleanup operations
    clean_tuist_cache
    clean_derived_data
    clean_build_products
    clean_spm_cache
    clean_logs
    clean_workspace
    clean_simulator_data
    
    # Summary
    if [[ "$DRY_RUN" == true ]]; then
        log SUCCESS "🔍 Dry run completed - review the log to see what would be cleaned"
        log INFO "📋 Run without --dry-run to perform actual cleanup"
    else
        log SUCCESS "🧹 Cleanup process completed successfully!"
        log INFO "📊 Cleanup logs: $LOG_DIR"
        log INFO "💾 Disk space has been freed up"
        
        if [[ "$CLEAN_WORKSPACE" == true ]]; then
            log INFO ""
            log INFO "⚠️  Next steps after workspace cleanup:"
            log INFO "  1. Run './Scripts/tuist-generate.sh' to recreate project files"
            log INFO "  2. Open the generated workspace/project in Xcode"
        fi
    fi
}

# Handle script interruption
trap 'log ERROR "Cleanup interrupted by user"; exit 130' INT TERM

# Execute main function
main "$@"