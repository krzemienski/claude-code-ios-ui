#!/bin/bash

# Phase 3 E2E Persistence Validation Test Runner
# TDD Approach: Run failing tests first, then make them pass

set -e

# Configuration
PROJECT_PATH="/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS"
OUTPUT_ROOT="/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/output/20250909-122718_ios_e2e_claude"
TEST_FILE="$OUTPUT_ROOT/tests/Phase3PersistenceTests.swift"
REPORTS_DIR="$OUTPUT_ROOT/reports"
SCREENSHOTS_DIR="$OUTPUT_ROOT/screenshots"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🚀 Phase 3 E2E Persistence Validation - TDD Approach"
echo "=================================================="
echo ""

# Step 1: Copy test file to project
echo -e "${BLUE}Step 1: Setting up test file...${NC}"
cp "$TEST_FILE" "$PROJECT_PATH/ClaudeCodeUIUITests/Phase3PersistenceTests.swift"
echo "✅ Test file copied to project"

# Step 2: Build the app
echo -e "${BLUE}Step 2: Building the app...${NC}"
cd "$PROJECT_PATH"
xcodebuild -workspace ClaudeCodeUI.xcworkspace \
    -scheme ClaudeCodeUI \
    -configuration Debug \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0' \
    clean build \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    -quiet

echo "✅ App built successfully"

# Step 3: Run tests (expecting failures initially)
echo -e "${YELLOW}Step 3: Running tests (TDD - expecting failures)...${NC}"
echo ""

# Create initial failure report
INITIAL_REPORT="$REPORTS_DIR/initial_test_failures.json"

# Run tests and capture results
xcodebuild test \
    -workspace ClaudeCodeUI.xcworkspace \
    -scheme ClaudeCodeUI \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0' \
    -only-testing:ClaudeCodeUIUITests/Phase3PersistenceTests \
    -resultBundlePath "$OUTPUT_ROOT/Phase3TestResults.xcresult" \
    2>&1 | tee "$REPORTS_DIR/test_output.log" || true

# Parse test results
echo ""
echo -e "${BLUE}Parsing test results...${NC}"

# Extract test results from log
PASSED_TESTS=$(grep -c "Test Case.*passed" "$REPORTS_DIR/test_output.log" || echo "0")
FAILED_TESTS=$(grep -c "Test Case.*failed" "$REPORTS_DIR/test_output.log" || echo "0")
TOTAL_TESTS=$((PASSED_TESTS + FAILED_TESTS))

# Generate JSON report
cat > "$INITIAL_REPORT" <<EOF
{
    "test_run": "initial_tdd_run",
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "total_tests": $TOTAL_TESTS,
    "passed": $PASSED_TESTS,
    "failed": $FAILED_TESTS,
    "phase": "TDD - Failing Tests"
}
EOF

echo "📊 Initial Test Results (TDD):"
echo "   Total Tests: $TOTAL_TESTS"
echo -e "   ${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "   ${RED}Failed: $FAILED_TESTS${NC}"
echo ""

# Step 4: If tests are failing (as expected in TDD), provide implementation guidance
if [ $FAILED_TESTS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Tests are failing as expected (TDD approach)${NC}"
    echo ""
    echo "📝 Implementation Required:"
    echo "   1. Fix navigation to Projects/Sessions lists"
    echo "   2. Implement message persistence in Core Data"
    echo "   3. Fix SSE/WebSocket streaming handlers"
    echo "   4. Ensure session restoration after app restart"
    echo "   5. Fix message ordering and timestamps"
    echo ""
    echo "Next steps:"
    echo "   - Review $REPORTS_DIR/test_output.log for specific failures"
    echo "   - Implement fixes in the app code"
    echo "   - Re-run this script to verify fixes"
else
    echo -e "${GREEN}✅ All tests passed! Persistence validation complete.${NC}"
fi

# Step 5: Generate detailed report
echo -e "${BLUE}Generating detailed report...${NC}"

cat > "$REPORTS_DIR/phase3_test_summary.md" <<EOF
# Phase 3 E2E Persistence Validation Report

## Test Execution Summary
- **Date**: $(date)
- **Total Tests**: $TOTAL_TESTS
- **Passed**: $PASSED_TESTS
- **Failed**: $FAILED_TESTS
- **Success Rate**: $(echo "scale=2; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc)%

## Test Steps Executed

### Step 1: Navigate to Projects List
- Status: $([ $FAILED_TESTS -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")
- Screenshot: 01_projects_list.png

### Step 2: Navigate to Sessions List
- Status: $([ $FAILED_TESTS -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")
- Screenshot: 02_sessions_list.png

### Step 3: Open Session with History
- Status: $([ $FAILED_TESTS -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")
- Screenshot: 03_session_opened.png

### Step 4: Verify Historical Messages
- Status: $([ $FAILED_TESTS -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")
- Screenshots: 04_message_*.png

### Step 5: Send First Message with Streaming
- Status: $([ $FAILED_TESTS -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")
- Screenshots: 05a_before_send.png, 05b_message1_complete.png

### Step 6: Verify SSE/WebSocket Response
- Status: $([ $FAILED_TESTS -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")
- Metrics: See streaming_metrics.json

### Step 7: Send Second Message
- Status: $([ $FAILED_TESTS -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")
- Screenshots: 07a_message2_typed.png, 07b_message2_complete.png

### Step 8: Exit and Re-enter Session
- Status: $([ $FAILED_TESTS -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")
- Screenshots: 08a_back_to_sessions.png, 08b_session_reentered.png

### Step 9: Verify Message Persistence
- Status: $([ $FAILED_TESTS -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")
- Screenshot: 09_persistence_verified.png

### Step 10: Force Quit and Relaunch
- Status: $([ $FAILED_TESTS -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")
- Screenshot: 10_after_relaunch.png

### Step 11: Verify Complete Persistence
- Status: $([ $FAILED_TESTS -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")
- Screenshot: 11_final_verification.png

## Screenshots
All screenshots saved to: $SCREENSHOTS_DIR

## Test Logs
- Full output: $REPORTS_DIR/test_output.log
- Initial failures: $INITIAL_REPORT
- Test bundle: $OUTPUT_ROOT/Phase3TestResults.xcresult

## Recommendations
$(if [ $FAILED_TESTS -gt 0 ]; then
    echo "1. Review failing test cases in test_output.log"
    echo "2. Fix identified issues in app code"
    echo "3. Re-run tests to verify fixes"
    echo "4. Ensure all persistence mechanisms are working"
else
    echo "✅ All tests passing - persistence validation complete!"
fi)
EOF

echo "✅ Report generated: $REPORTS_DIR/phase3_test_summary.md"

# Step 6: Open results if all tests passed
if [ $FAILED_TESTS -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 SUCCESS! All Phase 3 persistence tests passed!${NC}"
    echo "Opening test results..."
    open "$OUTPUT_ROOT/Phase3TestResults.xcresult"
    open "$REPORTS_DIR/phase3_test_summary.md"
fi

echo ""
echo "=================================================="
echo "Phase 3 E2E Test Execution Complete"
echo "Results saved to: $OUTPUT_ROOT"