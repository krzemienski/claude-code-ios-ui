#!/bin/bash

# Tuist Generate Script - Project generation with validation and dependency management
# Author: Claude Code Agent - Tuist Build Specialist
# Created: $(date '+%Y-%m-%d %H:%M:%S')

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
GENERATE_LOG="$LOG_DIR/tuist-generate-$(date '+%Y%m%d_%H%M%S').log"
ERROR_LOG="$LOG_DIR/tuist-generate-errors-$(date '+%Y%m%d_%H%M%S').log"
VALIDATION_LOG="$LOG_DIR/tuist-validation.log"

# Configuration options
NO_CACHE=false
FORCE_REGENERATE=false
VALIDATE_ONLY=false
CLEAN_DERIVED_DATA=false
SKIP_DEPENDENCIES=false
VERBOSE=false
QUIET=false

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
    
    if [[ "$QUIET" == true ]] && [[ "$level" != "ERROR" ]]; then
        return
    fi
    
    case "$level" in
        INFO)  echo -e "${GREEN}[INFO]${NC} $message" | tee -a "$GENERATE_LOG" ;;
        WARN)  echo -e "${YELLOW}[WARN]${NC} $message" | tee -a "$GENERATE_LOG" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} $message" | tee -a "$GENERATE_LOG" "$ERROR_LOG" ;;
        DEBUG) [[ "$VERBOSE" == true ]] && echo -e "${BLUE}[DEBUG]${NC} $message" | tee -a "$GENERATE_LOG" ;;
        SUCCESS) echo -e "${GREEN}[SUCCESS]${NC} $message" | tee -a "$GENERATE_LOG" ;;
        *) echo "$message" | tee -a "$GENERATE_LOG" ;;
    esac
}

show_progress() {
    local message="$1"
    [[ "$QUIET" != true ]] && echo -e "${CYAN}⚡${NC} $message"
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Tuist Generate Script - Project generation with validation and dependency management

OPTIONS:
    --no-cache              Disable binary cache during generation
    --force                 Force regeneration even if project exists
    --validate-only         Only validate configuration without generating
    --clean-derived-data    Clean derived data before generation
    --skip-dependencies     Skip dependency installation
    -v, --verbose           Enable verbose logging
    -q, --quiet            Suppress non-error output
    -h, --help             Show this help message

VALIDATION CHECKS:
    - Tuist configuration validation
    - Project manifest syntax
    - Dependency availability
    - Xcode compatibility
    - File system permissions

EXAMPLES:
    $0                          # Standard project generation
    $0 --force --clean-derived-data  # Clean regeneration
    $0 --validate-only          # Validate configuration only
    $0 --no-cache --verbose     # Generate without cache, verbose output
    $0 --quiet                  # Silent generation (errors only)

LOGS:
    Generation logs: $LOG_DIR/
    Validation: $VALIDATION_LOG
    Errors: *-errors-*.log
EOF
}

setup_environment() {
    log INFO "Setting up generation environment..."
    
    # Create log directory
    mkdir -p "$LOG_DIR"
    
    # Change to project root
    cd "$PROJECT_ROOT"
    
    # Log environment info
    {
        echo "=== Generation Environment ==="
        echo "Date: $(date)"
        echo "User: $(whoami)"
        echo "Project: $PROJECT_ROOT"
        echo "Xcode: $(xcode-select --print-path 2>/dev/null || echo 'Not found')"
        echo "Tuist: $(tuist version 2>/dev/null || echo 'Not found')"
        echo "No Cache: $NO_CACHE"
        echo "Force: $FORCE_REGENERATE"
        echo "Validate Only: $VALIDATE_ONLY"
        echo "=============================="
    } | tee -a "$GENERATE_LOG"
}

# =============================================================================
# Validation Functions
# =============================================================================

validate_environment() {
    log INFO "Validating environment..."
    local validation_errors=()
    
    # Ensure Tuist is in PATH
    export PATH="/opt/homebrew/bin:$PATH"
    
    # Check Tuist installation
    if ! command -v tuist &> /dev/null; then
        validation_errors+=("Tuist is not installed or not in PATH")
    else
        log DEBUG "Tuist version: $(tuist version)"
    fi
    
    # Check Xcode installation
    if ! xcode-select --print-path &> /dev/null; then
        validation_errors+=("Xcode command line tools not installed")
    else
        log DEBUG "Xcode path: $(xcode-select --print-path)"
    fi
    
    # Check project structure
    if [[ ! -f "$PROJECT_ROOT/Project.swift" ]]; then
        validation_errors+=("Project.swift not found in project root")
    fi
    
    if [[ ! -f "$PROJECT_ROOT/Tuist.swift" ]]; then
        validation_errors+=("Tuist.swift not found in project root")
    fi
    
    # Check write permissions
    if [[ ! -w "$PROJECT_ROOT" ]]; then
        validation_errors+=("No write permission to project directory")
    fi
    
    if [[ ${#validation_errors[@]} -gt 0 ]]; then
        log ERROR "Environment validation failed:"
        for error in "${validation_errors[@]}"; do
            log ERROR "  - $error"
        done
        return 1
    fi
    
    log SUCCESS "Environment validation passed"
    return 0
}

validate_project_manifest() {
    log INFO "Validating project manifest..."
    
    # Use tuist's built-in validation if available
    if tuist graph --help | grep -q "validate" 2>/dev/null; then
        if tuist graph validate >> "$VALIDATION_LOG" 2>&1; then
            log SUCCESS "Project manifest validation passed"
        else
            log ERROR "Project manifest validation failed"
            return 1
        fi
    else
        log DEBUG "Using basic manifest syntax validation"
        
        # Basic Swift syntax check for Project.swift
        if swift -parse "$PROJECT_ROOT/Project.swift" &>/dev/null; then
            log SUCCESS "Project.swift syntax is valid"
        else
            log ERROR "Project.swift has syntax errors"
            return 1
        fi
        
        # Basic Swift syntax check for Tuist.swift
        if swift -parse "$PROJECT_ROOT/Tuist.swift" &>/dev/null; then
            log SUCCESS "Tuist.swift syntax is valid"
        else
            log ERROR "Tuist.swift has syntax errors"
            return 1
        fi
    fi
    
    return 0
}

validate_dependencies() {
    log INFO "Validating dependencies..."
    
    # Check if Package.swift exists (for SPM dependencies)
    if [[ -f "$PROJECT_ROOT/Package.swift" ]]; then
        log DEBUG "Package.swift found, validating SPM dependencies..."
        if swift package resolve --package-path "$PROJECT_ROOT" >> "$VALIDATION_LOG" 2>&1; then
            log SUCCESS "SPM dependencies validated"
        else
            log WARN "SPM dependency validation failed (non-fatal)"
        fi
    fi
    
    # Check external dependencies from Project.swift
    if grep -q "external(" "$PROJECT_ROOT/Project.swift"; then
        log DEBUG "External dependencies detected in Project.swift"
        local external_deps
        external_deps=$(grep -o 'external(name: "[^"]*")' "$PROJECT_ROOT/Project.swift" | sed 's/external(name: "\([^"]*\)")/\1/' || true)
        
        if [[ -n "$external_deps" ]]; then
            log INFO "Found external dependencies: $external_deps"
            # Note: Actual dependency validation happens during tuist generate
        fi
    fi
    
    log SUCCESS "Dependency validation completed"
    return 0
}

check_existing_project() {
    log INFO "Checking for existing generated project..."
    
    local workspace_path="$PROJECT_ROOT/ClaudeCodeUI.xcworkspace"
    local project_path="$PROJECT_ROOT/ClaudeCodeUI.xcodeproj"
    
    if [[ -d "$workspace_path" ]] || [[ -d "$project_path" ]]; then
        if [[ "$FORCE_REGENERATE" == true ]]; then
            log INFO "Existing project found, will force regeneration"
            return 0
        else
            log WARN "Existing project found. Use --force to regenerate or delete manually."
            log INFO "Workspace: $workspace_path"
            log INFO "Project: $project_path"
            return 1
        fi
    fi
    
    log INFO "No existing project found, proceeding with generation"
    return 0
}

# =============================================================================
# Generation Functions
# =============================================================================

clean_derived_data() {
    if [[ "$CLEAN_DERIVED_DATA" == true ]]; then
        log INFO "Cleaning derived data..."
        
        local derived_data_path
        derived_data_path=$(xcodebuild -showBuildSettings | grep BUILD_DIR | head -1 | sed 's/.*= *//' | sed 's|/Build/Products||' 2>/dev/null || echo "")
        
        if [[ -n "$derived_data_path" ]] && [[ -d "$derived_data_path" ]]; then
            log INFO "Removing derived data at: $derived_data_path"
            rm -rf "$derived_data_path" || log WARN "Failed to remove derived data (non-fatal)"
        fi
        
        # Also clean Tuist's derived data if it exists
        local tuist_derived="$PROJECT_ROOT/.tuist-derived"
        if [[ -d "$tuist_derived" ]]; then
            log INFO "Removing Tuist derived data..."
            rm -rf "$tuist_derived" || log WARN "Failed to remove Tuist derived data (non-fatal)"
        fi
        
        log SUCCESS "Derived data cleanup completed"
    fi
}

install_dependencies() {
    if [[ "$SKIP_DEPENDENCIES" == true ]]; then
        log INFO "Skipping dependency installation"
        return 0
    fi
    
    log INFO "Installing dependencies..."
    local start_time=$(date +%s)
    
    # Install/fetch dependencies
    if tuist install >> "$GENERATE_LOG" 2>&1; then
        log SUCCESS "Dependencies installed successfully"
    else
        # tuist install might not exist in all versions, try tuist fetch
        if tuist fetch >> "$GENERATE_LOG" 2>&1; then
            log SUCCESS "Dependencies fetched successfully"
        else
            log WARN "Dependency installation failed (continuing anyway)"
        fi
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    log DEBUG "Dependency installation took ${duration}s"
    
    return 0
}

generate_project() {
    log INFO "Generating Xcode project..."
    local start_time=$(date +%s)
    
    # Construct generation command
    local cmd="tuist generate"
    
    if [[ "$NO_CACHE" == true ]]; then
        cmd="$cmd --no-binary-cache"
    fi
    
    # Execute generation
    show_progress "Running Tuist generate..."
    
    if [[ "$VERBOSE" == true ]]; then
        eval "$cmd" 2>&1 | tee -a "$GENERATE_LOG"
    else
        eval "$cmd" >> "$GENERATE_LOG" 2>&1
    fi
    
    local exit_code=$?
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [[ $exit_code -eq 0 ]]; then
        log SUCCESS "Project generation completed in ${duration}s"
        
        # Verify generated files
        local workspace_path="$PROJECT_ROOT/ClaudeCodeUI.xcworkspace"
        local project_path="$PROJECT_ROOT/ClaudeCodeUI.xcodeproj"
        
        if [[ -d "$workspace_path" ]]; then
            log SUCCESS "Generated workspace: $workspace_path"
        elif [[ -d "$project_path" ]]; then
            log SUCCESS "Generated project: $project_path"
        else
            log WARN "Generation completed but no workspace/project found"
        fi
        
        return 0
    else
        log ERROR "Project generation failed with exit code: $exit_code"
        return $exit_code
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
                NO_CACHE=true
                shift
                ;;
            --force)
                FORCE_REGENERATE=true
                shift
                ;;
            --validate-only)
                VALIDATE_ONLY=true
                shift
                ;;
            --clean-derived-data)
                CLEAN_DERIVED_DATA=true
                shift
                ;;
            --skip-dependencies)
                SKIP_DEPENDENCIES=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
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
    
    log INFO "Starting Tuist project generation..."
    
    # Setup environment
    show_progress "Setting up environment"
    setup_environment
    
    # Run validations
    show_progress "Validating environment"
    if ! validate_environment; then
        log ERROR "Environment validation failed"
        exit 1
    fi
    
    show_progress "Validating project manifest"
    if ! validate_project_manifest; then
        log ERROR "Project manifest validation failed"
        exit 1
    fi
    
    show_progress "Validating dependencies"
    if ! validate_dependencies; then
        log ERROR "Dependency validation failed"
        exit 1
    fi
    
    # If validate-only mode, exit here
    if [[ "$VALIDATE_ONLY" == true ]]; then
        log SUCCESS "🎉 Validation completed successfully!"
        log INFO "📋 All checks passed, project is ready for generation"
        exit 0
    fi
    
    # Check for existing project
    if ! check_existing_project; then
        log ERROR "Existing project check failed"
        exit 1
    fi
    
    # Clean derived data if requested
    clean_derived_data
    
    # Install dependencies
    show_progress "Installing dependencies"
    install_dependencies
    
    # Generate project
    show_progress "Generating project files"
    if generate_project; then
        log SUCCESS "🎉 Project generation completed successfully!"
        log INFO "📊 Logs available at: $LOG_DIR"
        log INFO "🔧 You can now open the generated workspace/project in Xcode"
        
        # Show next steps
        log INFO ""
        log INFO "Next steps:"
        log INFO "  1. Open ClaudeCodeUI.xcworkspace (if available) or ClaudeCodeUI.xcodeproj"
        log INFO "  2. Build the project using './Scripts/tuist-build.sh'"
        log INFO "  3. Run tests using './Scripts/tuist-test.sh'"
        
        exit 0
    else
        log ERROR "❌ Project generation failed!"
        log ERROR "📋 Check logs at: $GENERATE_LOG"
        log ERROR "🚨 Error details: $ERROR_LOG"
        exit 1
    fi
}

# Handle script interruption
trap 'log ERROR "Generation interrupted by user"; exit 130' INT TERM

# Execute main function
main "$@"