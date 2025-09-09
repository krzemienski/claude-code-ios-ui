#!/bin/bash

# Comprehensive Test Suite Runner for ClaudeCodeUI iOS
# Executes all test categories with detailed reporting

echo "══════════════════════════════════════════════════════════════════════"
echo "🧪 Claude Code UI iOS - Comprehensive Test Execution"
echo "══════════════════════════════════════════════════════════════════════"
echo ""
echo "📅 Test Date: $(date)"
echo "📱 Platform: iOS Simulator"
echo ""

# Set project directory
PROJECT_DIR="$(dirname "$0")/.."
cd "$PROJECT_DIR" || exit 1

# Results directory
RESULTS_DIR="TestResults_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULTS_DIR"

# Test report file
REPORT_FILE="$RESULTS_DIR/comprehensive_test_report.txt"

# Function to run tests for a specific scheme
run_test_scheme() {
    local scheme=$1
    local description=$2
    local result_bundle="$RESULTS_DIR/${scheme}_results.xcresult"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎯 Running: $description"
    echo "📦 Scheme: $scheme"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Run the test
    xcodebuild test \
        -workspace ClaudeCodeUI.xcworkspace \
        -scheme "$scheme" \
        -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' \
        -resultBundlePath "$result_bundle" \
        -quiet \
        2>&1 | tee -a "$REPORT_FILE" | grep -E "(Test Suite|Test Case|passed|failed|executed|error:)"
    
    local test_result=${PIPESTATUS[0]}
    
    if [ $test_result -eq 0 ]; then
        echo "✅ $description: PASSED" | tee -a "$REPORT_FILE"
    else
        echo "❌ $description: FAILED" | tee -a "$REPORT_FILE"
    fi
    
    echo "" | tee -a "$REPORT_FILE"
    return $test_result
}

# Initialize report
{
    echo "══════════════════════════════════════════════════════════════════════"
    echo "COMPREHENSIVE TEST EXECUTION REPORT"
    echo "══════════════════════════════════════════════════════════════════════"
    echo "Date: $(date)"
    echo "Project: ClaudeCodeUI iOS"
    echo ""
} > "$REPORT_FILE"

# Track overall status
OVERALL_STATUS=0

# Run Unit Tests
echo "🔬 PHASE 1: Unit Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if run_test_scheme "ClaudeCodeUITests" "Unit Tests"; then
    echo "✅ Unit Tests Suite: SUCCESS" | tee -a "$REPORT_FILE"
else
    echo "❌ Unit Tests Suite: FAILURE" | tee -a "$REPORT_FILE"
    OVERALL_STATUS=1
fi

# Run Integration Tests
echo ""
echo "🔗 PHASE 2: Integration Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if integration test scheme exists
if xcodebuild -workspace ClaudeCodeUI.xcworkspace -list 2>/dev/null | grep -q "ClaudeCodeUIIntegrationTests"; then
    if run_test_scheme "ClaudeCodeUIIntegrationTests" "Integration Tests"; then
        echo "✅ Integration Tests Suite: SUCCESS" | tee -a "$REPORT_FILE"
    else
        echo "❌ Integration Tests Suite: FAILURE" | tee -a "$REPORT_FILE"
        OVERALL_STATUS=1
    fi
else
    echo "⚠️  Integration test scheme not found, checking for files..." | tee -a "$REPORT_FILE"
    
    # Try to compile and run integration tests directly
    if [ -d "ClaudeCodeUIIntegrationTests" ]; then
        echo "📁 Found integration test directory, attempting direct execution..." | tee -a "$REPORT_FILE"
        
        xcodebuild test \
            -workspace ClaudeCodeUI.xcworkspace \
            -scheme ClaudeCodeUI \
            -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' \
            -only-testing:ClaudeCodeUIIntegrationTests \
            -resultBundlePath "$RESULTS_DIR/integration_direct.xcresult" \
            -quiet \
            2>&1 | tee -a "$REPORT_FILE" | grep -E "(Test|passed|failed|executed)"
    fi
fi

# Run UI Tests
echo ""
echo "🖥️ PHASE 3: UI Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check for UI test scheme
if xcodebuild -workspace ClaudeCodeUI.xcworkspace -list 2>/dev/null | grep -q "ClaudeCodeUIUITests"; then
    if run_test_scheme "ClaudeCodeUIUITests" "UI Tests"; then
        echo "✅ UI Tests Suite: SUCCESS" | tee -a "$REPORT_FILE"
    else
        echo "❌ UI Tests Suite: FAILURE" | tee -a "$REPORT_FILE"
        OVERALL_STATUS=1
    fi
else
    echo "⚠️  UI test scheme not found" | tee -a "$REPORT_FILE"
fi

# Generate summary report
echo ""
echo "══════════════════════════════════════════════════════════════════════"
echo "📊 TEST EXECUTION SUMMARY"
echo "══════════════════════════════════════════════════════════════════════"

{
    echo ""
    echo "══════════════════════════════════════════════════════════════════════"
    echo "FINAL SUMMARY"
    echo "══════════════════════════════════════════════════════════════════════"
    echo ""
    echo "Test Categories Executed:"
    echo "  • Unit Tests"
    echo "  • Integration Tests (if available)"
    echo "  • UI Tests (if available)"
    echo ""
    echo "Results Location: $RESULTS_DIR"
    echo "Report File: $REPORT_FILE"
    echo ""
    
    if [ $OVERALL_STATUS -eq 0 ]; then
        echo "🎉 OVERALL RESULT: ALL TESTS PASSED"
    else
        echo "⚠️  OVERALL RESULT: SOME TESTS FAILED"
        echo ""
        echo "Please review the detailed report for failure information."
    fi
    
    echo ""
    echo "Execution completed at: $(date)"
    echo "══════════════════════════════════════════════════════════════════════"
} | tee -a "$REPORT_FILE"

# Display report location
echo ""
echo "📄 Full report saved to: $REPORT_FILE"
echo "📦 Test results bundles in: $RESULTS_DIR"
echo ""

exit $OVERALL_STATUS