#!/bin/bash

# Tuist Test Script - Comprehensive test execution with coverage and reporting
# Author: Claude Code Agent - Tuist Build Specialist
# Created: $(date '+%Y-%m-%d %H:%M:%S')

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
TEST_LOG="$LOG_DIR/tuist-test-$(date '+%Y%m%d_%H%M%S').log"
ERROR_LOG="$LOG_DIR/tuist-test-errors-$(date '+%Y%m%d_%H%M%S').log"
COVERAGE_DIR="$LOG_DIR/coverage"
RESULTS_DIR="$LOG_DIR/test-results"

# Test configuration
TEST_SCHEME=""
TEST_CONFIGURATION="Debug"
ENABLE_COVERAGE=true
ENABLE_PARALLEL=true
ENABLE_UI_TESTS=true
ENABLE_INTEGRATION_TESTS=true
DEVICE_TARGET="iPhone 15 Pro"
IOS_VERSION="17.0"
TIMEOUT=300
MAX_RETRIES=2
VERBOSE=false
QUIET=false
FAIL_FAST=false
GENERATE_HTML_REPORT=true

# Available test schemes
UNIT_TEST_SCHEMES=("ClaudeCodeUITests")
UI_TEST_SCHEMES=("ClaudeCodeUIUITests")
INTEGRATION_TEST_SCHEMES=("ClaudeCodeUIIntegrationTests")
ALL_TEST_SCHEMES=("${UNIT_TEST_SCHEMES[@]}" "${UI_TEST_SCHEMES[@]}" "${INTEGRATION_TEST_SCHEMES[@]}")

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
        INFO)  echo -e "${GREEN}[INFO]${NC} $message" | tee -a "$TEST_LOG" ;;
        WARN)  echo -e "${YELLOW}[WARN]${NC} $message" | tee -a "$TEST_LOG" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} $message" | tee -a "$TEST_LOG" "$ERROR_LOG" ;;
        DEBUG) [[ "$VERBOSE" == true ]] && echo -e "${BLUE}[DEBUG]${NC} $message" | tee -a "$TEST_LOG" ;;
        SUCCESS) echo -e "${GREEN}[SUCCESS]${NC} $message" | tee -a "$TEST_LOG" ;;
        TEST) echo -e "${PURPLE}[TEST]${NC} $message" | tee -a "$TEST_LOG" ;;
        *) echo "$message" | tee -a "$TEST_LOG" ;;
    esac
}

show_progress() {
    local message="$1"
    [[ "$QUIET" != true ]] && echo -e "${CYAN}🧪${NC} $message"
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [SCHEME]

Tuist Test Script - Comprehensive test execution with coverage and reporting

OPTIONS:
    -c, --configuration CONFIG  Test configuration (Debug/Release) [default: Debug]
    --no-coverage               Disable code coverage collection
    --no-parallel               Disable parallel test execution
    --no-ui-tests              Skip UI tests
    --no-integration-tests     Skip integration tests
    --device TARGET            Target device for testing [default: iPhone 15 Pro]
    --ios-version VERSION      iOS version [default: 17.0]
    --timeout SECONDS          Test timeout in seconds [default: 300]
    -r, --retry COUNT          Maximum retry attempts [default: 2]
    --fail-fast                Stop on first test failure
    --no-html-report           Skip HTML coverage report generation
    -v, --verbose              Enable verbose logging
    -q, --quiet               Suppress non-error output
    -h, --help                Show this help message

SCHEME:
    Specific test scheme to run:
    Unit Tests: ${UNIT_TEST_SCHEMES[*]}
    UI Tests: ${UI_TEST_SCHEMES[*]}
    Integration Tests: ${INTEGRATION_TEST_SCHEMES[*]}
    
    If not specified, runs all applicable test schemes

TEST TYPES:
    Unit Tests: Fast, isolated tests
    UI Tests: User interface automation tests
    Integration Tests: Component integration tests

EXAMPLES:
    $0                                    # Run all tests with coverage
    $0 ClaudeCodeUITests                  # Run unit tests only
    $0 --no-coverage --fail-fast          # Quick test run without coverage
    $0 --device "iPhone 14" --ios-version "16.0"  # Test on specific device
    $0 --configuration Release --verbose   # Release build with verbose output

COVERAGE:
    Coverage data: $COVERAGE_DIR/
    HTML reports: $COVERAGE_DIR/html/
    Xcode reports: $RESULTS_DIR/

LOGS:
    Test logs: $LOG_DIR/
    Results: $RESULTS_DIR/
    Errors: *-errors-*.log
EOF
}

validate_scheme() {
    local scheme="$1"
    for available in "${ALL_TEST_SCHEMES[@]}"; do
        if [[ "$available" == "$scheme" ]]; then
            return 0
        fi
    done
    return 1
}

setup_environment() {
    log INFO "Setting up test environment..."
    
    # Ensure Tuist is in PATH
    export PATH="/opt/homebrew/bin:$PATH"
    
    # Create directories
    mkdir -p "$LOG_DIR" "$COVERAGE_DIR" "$RESULTS_DIR"
    
    # Change to project root
    cd "$PROJECT_ROOT"
    
    # Log environment info
    {
        echo "=== Test Environment ==="
        echo "Date: $(date)"
        echo "User: $(whoami)"
        echo "Project: $PROJECT_ROOT"
        echo "Xcode: $(xcode-select --print-path 2>/dev/null || echo 'Not found')"
        echo "Tuist: $(tuist version 2>/dev/null || echo 'Not found')"
        echo "Configuration: $TEST_CONFIGURATION"
        echo "Test Scheme: ${TEST_SCHEME:-'ALL'}"
        echo "Device Target: $DEVICE_TARGET"
        echo "iOS Version: $IOS_VERSION"
        echo "Coverage Enabled: $ENABLE_COVERAGE"
        echo "UI Tests Enabled: $ENABLE_UI_TESTS"
        echo "Integration Tests Enabled: $ENABLE_INTEGRATION_TESTS"
        echo "========================"
    } | tee -a "$TEST_LOG"
}

check_dependencies() {
    log INFO "Checking dependencies..."
    
    # Check tuist
    if ! command -v tuist &> /dev/null; then
        log ERROR "Tuist is not installed or not in PATH"
        exit 1
    fi
    
    # Check simulator
    if ! xcrun simctl list devices | grep -q "$DEVICE_TARGET"; then
        log WARN "Device '$DEVICE_TARGET' not found, using default device"
        DEVICE_TARGET="iPhone 15 Pro"
    fi
    
    # Check for test coverage tools
    if [[ "$ENABLE_COVERAGE" == true ]]; then
        if command -v xcov &> /dev/null; then
            log DEBUG "xcov found for coverage reporting"
        elif command -v slather &> /dev/null; then
            log DEBUG "slather found for coverage reporting"
        else
            log DEBUG "No coverage tools found, using Xcode built-in coverage"
        fi
    fi
    
    log SUCCESS "Dependencies check completed"
}

# =============================================================================
# Test Functions
# =============================================================================

generate_project_if_needed() {
    log INFO "Ensuring project is generated..."
    
    if [[ ! -d "$PROJECT_ROOT/ClaudeCodeUI.xcworkspace" ]] && [[ ! -d "$PROJECT_ROOT/ClaudeCodeUI.xcodeproj" ]]; then
        log INFO "Project not found, generating..."
        if tuist generate >> "$TEST_LOG" 2>&1; then
            log SUCCESS "Project generated successfully"
        else
            log ERROR "Failed to generate project"
            return 1
        fi
    else
        log DEBUG "Project already exists"
    fi
}

get_available_simulators() {
    log DEBUG "Getting available simulators..."
    xcrun simctl list devices available | grep "$DEVICE_TARGET" | grep "$IOS_VERSION" | head -1 | \
        grep -o '[A-F0-9\-]\{36\}' || echo ""
}

boot_simulator_if_needed() {
    local simulator_id
    simulator_id=$(get_available_simulators)
    
    if [[ -z "$simulator_id" ]]; then
        log WARN "No matching simulator found for $DEVICE_TARGET iOS $IOS_VERSION"
        return 1
    fi
    
    local sim_state
    sim_state=$(xcrun simctl list devices | grep "$simulator_id" | awk '{print $NF}' | tr -d '()')
    
    if [[ "$sim_state" != "Booted" ]]; then
        log INFO "Booting simulator: $DEVICE_TARGET ($simulator_id)"
        xcrun simctl boot "$simulator_id" >> "$TEST_LOG" 2>&1 || true
        sleep 10  # Wait for simulator to boot
    else
        log DEBUG "Simulator already booted"
    fi
}

run_unit_tests() {
    if [[ "$TEST_SCHEME" != "" ]] && [[ ! " ${UNIT_TEST_SCHEMES[*]} " =~ " ${TEST_SCHEME} " ]]; then
        return 0
    fi
    
    show_progress "Running unit tests"
    
    local schemes_to_test=("${UNIT_TEST_SCHEMES[@]}")
    if [[ -n "$TEST_SCHEME" ]]; then
        schemes_to_test=("$TEST_SCHEME")
    fi
    
    for scheme in "${schemes_to_test[@]}"; do
        run_test_scheme "$scheme" "unit"
    done
}

run_ui_tests() {
    if [[ "$ENABLE_UI_TESTS" != true ]]; then
        log DEBUG "UI tests disabled, skipping"
        return 0
    fi
    
    if [[ "$TEST_SCHEME" != "" ]] && [[ ! " ${UI_TEST_SCHEMES[*]} " =~ " ${TEST_SCHEME} " ]]; then
        return 0
    fi
    
    show_progress "Running UI tests"
    
    # Boot simulator for UI tests
    boot_simulator_if_needed
    
    local schemes_to_test=("${UI_TEST_SCHEMES[@]}")
    if [[ -n "$TEST_SCHEME" ]]; then
        schemes_to_test=("$TEST_SCHEME")
    fi
    
    for scheme in "${schemes_to_test[@]}"; do
        run_test_scheme "$scheme" "ui"
    done
}

run_integration_tests() {
    if [[ "$ENABLE_INTEGRATION_TESTS" != true ]]; then
        log DEBUG "Integration tests disabled, skipping"
        return 0
    fi
    
    if [[ "$TEST_SCHEME" != "" ]] && [[ ! " ${INTEGRATION_TEST_SCHEMES[*]} " =~ " ${TEST_SCHEME} " ]]; then
        return 0
    fi
    
    show_progress "Running integration tests"
    
    local schemes_to_test=("${INTEGRATION_TEST_SCHEMES[@]}")
    if [[ -n "$TEST_SCHEME" ]]; then
        schemes_to_test=("$TEST_SCHEME")
    fi
    
    for scheme in "${schemes_to_test[@]}"; do
        run_test_scheme "$scheme" "integration"
    done
}

run_test_scheme() {
    local scheme="$1"
    local test_type="$2"
    
    log TEST "Running $test_type tests: $scheme"
    local start_time=$(date +%s)
    
    # Construct test command
    local cmd="tuist test $scheme"
    local result_bundle="$RESULTS_DIR/$scheme-$(date '+%Y%m%d_%H%M%S').xcresult"
    
    # Add configuration and options
    cmd="$cmd -- -configuration $TEST_CONFIGURATION"
    cmd="$cmd -resultBundlePath '$result_bundle'"
    cmd="$cmd -destination 'platform=iOS Simulator,name=$DEVICE_TARGET,OS=$IOS_VERSION'"
    
    # Add parallel testing if enabled
    if [[ "$ENABLE_PARALLEL" == true ]]; then
        cmd="$cmd -parallel-testing-enabled YES"
    fi
    
    # Add coverage if enabled
    if [[ "$ENABLE_COVERAGE" == true ]]; then
        cmd="$cmd -enableCodeCoverage YES"
    fi
    
    # Add timeout
    if [[ -n "$TIMEOUT" ]]; then
        timeout "$TIMEOUT" bash -c "eval '$cmd'" >> "$TEST_LOG" 2>&1
        local exit_code=$?
    else
        eval "$cmd" >> "$TEST_LOG" 2>&1
        local exit_code=$?
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [[ $exit_code -eq 0 ]]; then
        log SUCCESS "$test_type tests passed: $scheme (${duration}s)"
        
        # Process coverage if enabled and available
        if [[ "$ENABLE_COVERAGE" == true ]] && [[ -d "$result_bundle" ]]; then
            process_coverage "$result_bundle" "$scheme"
        fi
        
        return 0
    else
        log ERROR "$test_type tests failed: $scheme (${duration}s, exit code: $exit_code)"
        
        if [[ "$FAIL_FAST" == true ]]; then
            log ERROR "Fail fast enabled, stopping test execution"
            exit $exit_code
        fi
        
        return $exit_code
    fi
}

process_coverage() {
    local result_bundle="$1"
    local scheme="$2"
    
    log INFO "Processing coverage for $scheme..."
    
    # Extract coverage data
    local coverage_file="$COVERAGE_DIR/$scheme-coverage.json"
    
    if xcrun xccov view --report --json "$result_bundle" > "$coverage_file" 2>/dev/null; then
        log DEBUG "Coverage data extracted to: $coverage_file"
        
        # Generate human-readable coverage report
        local coverage_text="$COVERAGE_DIR/$scheme-coverage.txt"
        xcrun xccov view --report "$result_bundle" > "$coverage_text" 2>/dev/null || true
        
        # Parse overall coverage percentage
        local coverage_percent
        coverage_percent=$(xcrun xccov view --report "$result_bundle" 2>/dev/null | grep -E "^\s*[0-9]+\.[0-9]+%" | tail -1 | awk '{print $1}' || echo "0.00%")
        
        log SUCCESS "Coverage for $scheme: $coverage_percent"
    else
        log WARN "Failed to extract coverage data for $scheme"
    fi
}

generate_html_coverage_report() {
    if [[ "$GENERATE_HTML_REPORT" != true ]] || [[ "$ENABLE_COVERAGE" != true ]]; then
        return 0
    fi
    
    log INFO "Generating HTML coverage report..."
    
    # Find all result bundles
    local result_bundles
    result_bundles=$(find "$RESULTS_DIR" -name "*.xcresult" -type d 2>/dev/null || true)
    
    if [[ -z "$result_bundles" ]]; then
        log WARN "No result bundles found for HTML report generation"
        return 0
    fi
    
    local html_dir="$COVERAGE_DIR/html"
    mkdir -p "$html_dir"
    
    # Generate combined HTML report if xcov is available
    if command -v xcov &> /dev/null; then
        log INFO "Generating xcov HTML report..."
        xcov --output_directory "$html_dir" --exclude_targets "$PROJECT_ROOT/ClaudeCodeUIUITests" >> "$TEST_LOG" 2>&1 || \
            log WARN "xcov HTML report generation failed"
    else
        log DEBUG "xcov not available, skipping HTML report generation"
    fi
    
    if [[ -f "$html_dir/index.html" ]]; then
        log SUCCESS "HTML coverage report generated: $html_dir/index.html"
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
                TEST_CONFIGURATION="$2"
                shift 2
                ;;
            --no-coverage)
                ENABLE_COVERAGE=false
                shift
                ;;
            --no-parallel)
                ENABLE_PARALLEL=false
                shift
                ;;
            --no-ui-tests)
                ENABLE_UI_TESTS=false
                shift
                ;;
            --no-integration-tests)
                ENABLE_INTEGRATION_TESTS=false
                shift
                ;;
            --device)
                DEVICE_TARGET="$2"
                shift 2
                ;;
            --ios-version)
                IOS_VERSION="$2"
                shift 2
                ;;
            --timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            -r|--retry)
                MAX_RETRIES="$2"
                shift 2
                ;;
            --fail-fast)
                FAIL_FAST=true
                shift
                ;;
            --no-html-report)
                GENERATE_HTML_REPORT=false
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
                if [[ -z "$TEST_SCHEME" ]]; then
                    TEST_SCHEME="$1"
                else
                    log ERROR "Multiple schemes specified. Use only one scheme or none for all."
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate scheme if specified
    if [[ -n "$TEST_SCHEME" ]] && ! validate_scheme "$TEST_SCHEME"; then
        log ERROR "Invalid test scheme: $TEST_SCHEME"
        log ERROR "Available schemes: ${ALL_TEST_SCHEMES[*]}"
        exit 1
    fi
    
    # Validate configuration
    if [[ "$TEST_CONFIGURATION" != "Debug" ]] && [[ "$TEST_CONFIGURATION" != "Release" ]]; then
        log ERROR "Invalid configuration: $TEST_CONFIGURATION. Must be Debug or Release."
        exit 1
    fi
    
    log INFO "Starting Tuist test execution..."
    
    # Setup and checks
    setup_environment
    check_dependencies
    
    # Generate project if needed
    show_progress "Ensuring project is ready"
    if ! generate_project_if_needed; then
        log ERROR "Project generation failed"
        exit 1
    fi
    
    # Run tests
    local test_failures=0
    
    # Unit tests
    if ! run_unit_tests; then
        ((test_failures++))
    fi
    
    # UI tests
    if ! run_ui_tests; then
        ((test_failures++))
    fi
    
    # Integration tests
    if ! run_integration_tests; then
        ((test_failures++))
    fi
    
    # Generate reports
    show_progress "Generating reports"
    generate_html_coverage_report
    
    # Final summary
    if [[ $test_failures -eq 0 ]]; then
        log SUCCESS "🎉 All tests completed successfully!"
        log INFO "📊 Test logs: $LOG_DIR"
        log INFO "📋 Test results: $RESULTS_DIR"
        if [[ "$ENABLE_COVERAGE" == true ]]; then
            log INFO "📈 Coverage reports: $COVERAGE_DIR"
            [[ -f "$COVERAGE_DIR/html/index.html" ]] && log INFO "🌐 HTML report: $COVERAGE_DIR/html/index.html"
        fi
        exit 0
    else
        log ERROR "❌ $test_failures test suite(s) failed!"
        log ERROR "📋 Check logs at: $TEST_LOG"
        log ERROR "🚨 Error details: $ERROR_LOG"
        exit 1
    fi
}

# Handle script interruption
trap 'log ERROR "Tests interrupted by user"; exit 130' INT TERM

# Execute main function
main "$@"