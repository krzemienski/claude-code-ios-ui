#!/bin/bash

# ============================================================================
# Automated Test Runner - Local and CI Compatible
# ============================================================================
# Purpose: Execute automated tests with full reporting and monitoring
# Author: Agent-5 - Automation & Continuous Testing Specialist
# Usage: ./automated-test-runner.sh [options]
# ============================================================================

set -euo pipefail

# Default Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
TEST_MODE="${1:-all}"
PARALLEL="${2:-false}"
REPORT_FORMAT="${3:-html}"
CI_MODE="${CI:-false}"

# Colors (disabled in CI)
if [ "$CI_MODE" = "true" ]; then
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    CYAN=""
    NC=""
    BOLD=""
else
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'
    BOLD='\033[1m'
fi

# Test Suites Configuration
declare -A TEST_SUITES
TEST_SUITES["functional"]="AutomatedFunctionalTestSuite"
TEST_SUITES["navigation"]="NavigationFlowTests"
TEST_SUITES["messages"]="MessageInteractionTests"
TEST_SUITES["projects"]="ProjectListTests"
TEST_SUITES["sessions"]="SessionNavigationTests"
TEST_SUITES["performance"]="PerformanceTests"
TEST_SUITES["websocket"]="WebSocketIntegrationTests"
TEST_SUITES["offline"]="EdgeCaseIntegrationTests"

# Results tracking
RESULTS_DIR="${PROJECT_ROOT}/TestResults_$(date +%Y%m%d_%H%M%S)"
PASSED_TESTS=0
FAILED_TESTS=0
TOTAL_TESTS=0
START_TIME=$(date +%s)

# ============================================================================
# Functions
# ============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    
    case "$level" in
        INFO)    echo -e "${BLUE}[INFO]${NC} ${message}" ;;
        SUCCESS) echo -e "${GREEN}[✓]${NC} ${message}" ;;
        WARNING) echo -e "${YELLOW}[⚠]${NC} ${message}" ;;
        ERROR)   echo -e "${RED}[✗]${NC} ${message}" ;;
        STEP)    echo -e "\n${CYAN}${BOLD}▶ ${message}${NC}\n" ;;
    esac
    
    if [ "$CI_MODE" = "true" ]; then
        # GitHub Actions annotations
        case "$level" in
            ERROR)   echo "::error::${message}" ;;
            WARNING) echo "::warning::${message}" ;;
        esac
    fi
}

usage() {
    cat << EOF
Usage: $0 [mode] [parallel] [format]

Modes:
    all         - Run all test suites (default)
    functional  - Run functional tests only
    performance - Run performance tests only
    websocket   - Run WebSocket tests only
    quick       - Run quick smoke tests
    ci          - Run CI-optimized test suite

Options:
    parallel    - Run tests in parallel (true/false, default: false)
    format      - Report format (html/json/junit, default: html)

Environment Variables:
    CI          - Set to 'true' for CI mode
    SIMULATOR   - Override simulator device name
    BACKEND_URL - Override backend URL

Examples:
    $0 all false html        # Run all tests sequentially with HTML report
    $0 functional true json  # Run functional tests in parallel with JSON report
    $0 ci true junit         # Run CI suite in parallel with JUnit report

EOF
    exit 0
}

setup_environment() {
    log STEP "Setting up test environment"
    
    # Create results directory
    mkdir -p "${RESULTS_DIR}"/{logs,screenshots,reports,artifacts}
    
    # Check for required tools
    local missing_tools=()
    
    command -v xcrun >/dev/null 2>&1 || missing_tools+=("Xcode Command Line Tools")
    command -v tuist >/dev/null 2>&1 || missing_tools+=("Tuist")
    command -v xcpretty >/dev/null 2>&1 || missing_tools+=("xcpretty")
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log ERROR "Missing required tools: ${missing_tools[*]}"
        log INFO "Install missing tools and try again"
        exit 1
    fi
    
    # Set up simulator
    SIMULATOR_NAME="${SIMULATOR:-iPhone 15 Pro}"
    SIMULATOR_ID=$(xcrun simctl list devices | grep "$SIMULATOR_NAME" | grep -v unavailable | head -1 | awk -F'[()]' '{print $2}')
    
    if [ -z "$SIMULATOR_ID" ]; then
        log WARNING "Simulator not found, creating new one"
        SIMULATOR_ID=$(xcrun simctl create "$SIMULATOR_NAME" \
            "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro" \
            "com.apple.CoreSimulator.SimRuntime.iOS-17-0")
    fi
    
    # Boot simulator if needed
    local state=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | awk -F'[()]' '{print $3}')
    if [ "$state" != "Booted" ]; then
        log INFO "Booting simulator..."
        xcrun simctl boot "$SIMULATOR_ID"
        sleep 10
    fi
    
    echo "$SIMULATOR_ID" > "${RESULTS_DIR}/simulator_id.txt"
    log SUCCESS "Environment ready (Simulator: $SIMULATOR_ID)"
}

build_app() {
    log STEP "Building application"
    
    cd "$PROJECT_ROOT"
    
    # Generate project
    log INFO "Generating Xcode project with Tuist"
    tuist generate
    
    # Build for testing
    log INFO "Building app for testing"
    
    local build_log="${RESULTS_DIR}/logs/build.log"
    
    if [ "$CI_MODE" = "true" ]; then
        echo "::group::Build Output"
    fi
    
    xcodebuild build-for-testing \
        -workspace ClaudeCodeUI.xcworkspace \
        -scheme ClaudeCodeUI \
        -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
        -derivedDataPath DerivedData \
        -configuration Debug \
        CODE_SIGNING_ALLOWED=NO \
        ONLY_ACTIVE_ARCH=YES \
        2>&1 | tee "$build_log" | xcpretty
    
    local build_result=${PIPESTATUS[0]}
    
    if [ "$CI_MODE" = "true" ]; then
        echo "::endgroup::"
    fi
    
    if [ $build_result -ne 0 ]; then
        log ERROR "Build failed! Check $build_log for details"
        exit 1
    fi
    
    log SUCCESS "Build completed successfully"
}

install_app() {
    log INFO "Installing app on simulator"
    
    local app_path="${PROJECT_ROOT}/DerivedData/Build/Products/Debug-iphonesimulator/ClaudeCodeUI.app"
    
    if [ ! -d "$app_path" ]; then
        log ERROR "App bundle not found at: $app_path"
        exit 1
    fi
    
    # Uninstall if exists
    xcrun simctl uninstall "$SIMULATOR_ID" "com.example.ClaudeCodeUI" 2>/dev/null || true
    
    # Install app
    xcrun simctl install "$SIMULATOR_ID" "$app_path"
    
    log SUCCESS "App installed successfully"
}

run_test_suite() {
    local suite_name="$1"
    local suite_class="$2"
    
    log INFO "Running test suite: $suite_name"
    
    local test_log="${RESULTS_DIR}/logs/${suite_name}.log"
    local result_bundle="${RESULTS_DIR}/artifacts/${suite_name}.xcresult"
    local junit_report="${RESULTS_DIR}/reports/${suite_name}_junit.xml"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$CI_MODE" = "true" ]; then
        echo "::group::Test Suite: $suite_name"
    fi
    
    if xcodebuild test-without-building \
        -workspace "${PROJECT_ROOT}/ClaudeCodeUI.xcworkspace" \
        -scheme ClaudeCodeUI \
        -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
        -derivedDataPath "${PROJECT_ROOT}/DerivedData" \
        -only-testing:"ClaudeCodeUIUITests/$suite_class" \
        -resultBundlePath "$result_bundle" \
        -enableCodeCoverage YES \
        2>&1 | tee "$test_log" | xcpretty --report junit --output "$junit_report"; then
        
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log SUCCESS "$suite_name tests passed"
        
        if [ "$CI_MODE" = "true" ]; then
            echo "::notice title=$suite_name::✅ Test suite passed"
        fi
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log ERROR "$suite_name tests failed"
        
        # Capture failure screenshot
        xcrun simctl io "$SIMULATOR_ID" screenshot \
            "${RESULTS_DIR}/screenshots/${suite_name}_failure.png"
        
        if [ "$CI_MODE" = "true" ]; then
            echo "::error title=$suite_name::❌ Test suite failed"
        fi
    fi
    
    if [ "$CI_MODE" = "true" ]; then
        echo "::endgroup::"
    fi
}

run_all_tests() {
    log STEP "Running all test suites"
    
    if [ "$PARALLEL" = "true" ]; then
        log INFO "Running tests in parallel"
        
        # Run tests in background
        for suite in "${!TEST_SUITES[@]}"; do
            run_test_suite "$suite" "${TEST_SUITES[$suite]}" &
        done
        
        # Wait for all background jobs
        wait
    else
        log INFO "Running tests sequentially"
        
        for suite in "${!TEST_SUITES[@]}"; do
            run_test_suite "$suite" "${TEST_SUITES[$suite]}"
        done
    fi
}

run_specific_tests() {
    local mode="$1"
    
    case "$mode" in
        functional)
            run_test_suite "functional" "${TEST_SUITES[functional]}"
            ;;
        performance)
            run_test_suite "performance" "${TEST_SUITES[performance]}"
            ;;
        websocket)
            run_test_suite "websocket" "${TEST_SUITES[websocket]}"
            ;;
        quick)
            log STEP "Running quick smoke tests"
            run_test_suite "functional" "${TEST_SUITES[functional]}"
            run_test_suite "navigation" "${TEST_SUITES[navigation]}"
            ;;
        ci)
            log STEP "Running CI test suite"
            run_test_suite "functional" "${TEST_SUITES[functional]}"
            run_test_suite "websocket" "${TEST_SUITES[websocket]}"
            run_test_suite "performance" "${TEST_SUITES[performance]}"
            ;;
        *)
            log ERROR "Unknown test mode: $mode"
            usage
            ;;
    esac
}

generate_report() {
    log STEP "Generating test report"
    
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    local pass_rate=0
    
    if [ $TOTAL_TESTS -gt 0 ]; then
        pass_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    fi
    
    case "$REPORT_FORMAT" in
        html)
            generate_html_report "$pass_rate" "$duration"
            ;;
        json)
            generate_json_report "$pass_rate" "$duration"
            ;;
        junit)
            merge_junit_reports
            ;;
        *)
            log WARNING "Unknown report format: $REPORT_FORMAT"
            ;;
    esac
    
    # Summary
    log STEP "Test Execution Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Total Tests:  $TOTAL_TESTS"
    echo "Passed:       $PASSED_TESTS"
    echo "Failed:       $FAILED_TESTS"
    echo "Pass Rate:    ${pass_rate}%"
    echo "Duration:     ${duration}s"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [ "$CI_MODE" = "true" ]; then
        # Set GitHub Actions outputs
        echo "total-tests=$TOTAL_TESTS" >> $GITHUB_OUTPUT
        echo "passed-tests=$PASSED_TESTS" >> $GITHUB_OUTPUT
        echo "failed-tests=$FAILED_TESTS" >> $GITHUB_OUTPUT
        echo "pass-rate=$pass_rate" >> $GITHUB_OUTPUT
        echo "duration=$duration" >> $GITHUB_OUTPUT
    fi
    
    # Open report if not in CI
    if [ "$CI_MODE" != "true" ] && [ -f "${RESULTS_DIR}/reports/test_report.html" ]; then
        open "${RESULTS_DIR}/reports/test_report.html"
    fi
}

generate_html_report() {
    local pass_rate="$1"
    local duration="$2"
    local report_file="${RESULTS_DIR}/reports/test_report.html"
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Test Report - $(date '+%Y-%m-%d %H:%M:%S')</title>
    <style>
        body { font-family: -apple-system, sans-serif; margin: 20px; }
        .header { background: linear-gradient(135deg, #667eea, #764ba2); color: white; padding: 30px; border-radius: 10px; }
        .metrics { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 20px; margin: 20px 0; }
        .metric { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); text-align: center; }
        .metric .value { font-size: 2em; font-weight: bold; margin: 10px 0; }
        .success { color: #10b981; }
        .failure { color: #ef4444; }
        .warning { color: #f59e0b; }
    </style>
</head>
<body>
    <div class="header">
        <h1>iOS Automated Test Report</h1>
        <p>Generated: $(date '+%Y-%m-%d %H:%M:%S')</p>
    </div>
    <div class="metrics">
        <div class="metric">
            <div class="value">${TOTAL_TESTS}</div>
            <div>Total Tests</div>
        </div>
        <div class="metric">
            <div class="value success">${PASSED_TESTS}</div>
            <div>Passed</div>
        </div>
        <div class="metric">
            <div class="value failure">${FAILED_TESTS}</div>
            <div>Failed</div>
        </div>
        <div class="metric">
            <div class="value ${pass_rate -ge 80 ? 'success' : 'warning'}">${pass_rate}%</div>
            <div>Pass Rate</div>
        </div>
        <div class="metric">
            <div class="value">${duration}s</div>
            <div>Duration</div>
        </div>
    </div>
</body>
</html>
EOF
    
    log SUCCESS "HTML report generated: $report_file"
}

generate_json_report() {
    local pass_rate="$1"
    local duration="$2"
    local report_file="${RESULTS_DIR}/reports/test_report.json"
    
    cat > "$report_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "summary": {
        "total": ${TOTAL_TESTS},
        "passed": ${PASSED_TESTS},
        "failed": ${FAILED_TESTS},
        "pass_rate": ${pass_rate},
        "duration": ${duration}
    },
    "environment": {
        "simulator": "${SIMULATOR_NAME}",
        "ci_mode": ${CI_MODE}
    }
}
EOF
    
    log SUCCESS "JSON report generated: $report_file"
}

merge_junit_reports() {
    local merged_file="${RESULTS_DIR}/reports/merged_junit.xml"
    
    echo '<?xml version="1.0" encoding="UTF-8"?>' > "$merged_file"
    echo '<testsuites>' >> "$merged_file"
    
    for report in "${RESULTS_DIR}/reports/"*_junit.xml; do
        if [ -f "$report" ]; then
            # Extract testsuite content
            sed -n '/<testsuite/,/<\/testsuite>/p' "$report" >> "$merged_file"
        fi
    done
    
    echo '</testsuites>' >> "$merged_file"
    
    log SUCCESS "JUnit reports merged: $merged_file"
}

cleanup() {
    log INFO "Cleaning up..."
    
    # Shutdown simulator
    if [ -f "${RESULTS_DIR}/simulator_id.txt" ]; then
        local sim_id=$(cat "${RESULTS_DIR}/simulator_id.txt")
        xcrun simctl shutdown "$sim_id" 2>/dev/null || true
    fi
    
    # Archive results
    if [ -d "$RESULTS_DIR" ]; then
        tar -czf "${RESULTS_DIR}.tar.gz" "$RESULTS_DIR"
        log SUCCESS "Results archived: ${RESULTS_DIR}.tar.gz"
    fi
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    # Parse arguments
    case "${1:-}" in
        -h|--help|help)
            usage
            ;;
    esac
    
    # Set up trap for cleanup
    trap cleanup EXIT
    
    # Setup
    setup_environment
    build_app
    install_app
    
    # Run tests based on mode
    if [ "$TEST_MODE" = "all" ]; then
        run_all_tests
    else
        run_specific_tests "$TEST_MODE"
    fi
    
    # Generate report
    generate_report
    
    # Exit with appropriate code
    [ $FAILED_TESTS -eq 0 ] && exit 0 || exit 1
}

# Run main
main "$@"