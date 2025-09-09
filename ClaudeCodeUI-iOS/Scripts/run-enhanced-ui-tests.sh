#!/bin/bash

# Enhanced UI Test Runner with Debug Output
# Tests with improved element discovery and real backend

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}        🧪 Enhanced Functional UI Tests                       ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="ClaudeCodeUI"
DERIVED_DATA_PATH="$PROJECT_DIR/DerivedData"
RESULTS_DIR="$PROJECT_DIR/EnhancedTestResults_$(date +%Y%m%d_%H%M%S)"

# Create results directory
mkdir -p "$RESULTS_DIR"

# Function to check backend
check_backend() {
    echo -e "${YELLOW}🔍 Checking backend availability...${NC}"
    
    if curl -s http://localhost:3004/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend is running on port 3004${NC}"
        
        # Check WebSocket endpoint
        echo -e "${YELLOW}🔍 Testing WebSocket connection...${NC}"
        if [ -f "$PROJECT_DIR/Scripts/validate-websocket.swift" ]; then
            swift "$PROJECT_DIR/Scripts/validate-websocket.swift" > "$RESULTS_DIR/websocket_test.log" 2>&1 &
            WS_PID=$!
            sleep 5
            kill $WS_PID 2>/dev/null || true
            
            if grep -q "WebSocket connected successfully" "$RESULTS_DIR/websocket_test.log"; then
                echo -e "${GREEN}✅ WebSocket connection verified${NC}"
            else
                echo -e "${YELLOW}⚠️ WebSocket may have issues${NC}"
            fi
        fi
    else
        echo -e "${RED}❌ Backend is not running on port 3004${NC}"
        echo "Please start the backend with: cd backend && python3 server.py"
        exit 1
    fi
}

# Function to generate project if needed
generate_project() {
    echo -e "${YELLOW}🔨 Checking project generation...${NC}"
    
    if [ ! -d "$PROJECT_DIR/ClaudeCodeUI.xcworkspace" ]; then
        echo "Generating project with Tuist..."
        cd "$PROJECT_DIR"
        tuist generate
    fi
    
    echo -e "${GREEN}✅ Project ready${NC}\n"
}

# Function to clean build artifacts
clean_build() {
    echo -e "${YELLOW}🧹 Cleaning build artifacts...${NC}"
    
    # Clean specific test-related derived data
    rm -rf "$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/*.xctest"
    rm -rf "$DERIVED_DATA_PATH/Build/Intermediates.noindex/*UITests.build"
    
    echo -e "${GREEN}✅ Build artifacts cleaned${NC}\n"
}

# Function to build for testing
build_for_testing() {
    echo -e "${YELLOW}🔨 Building app for testing...${NC}"
    
    xcodebuild build-for-testing \
        -workspace "$PROJECT_DIR/ClaudeCodeUI.xcworkspace" \
        -scheme "$SCHEME" \
        -sdk iphonesimulator \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
        COMPILER_INDEX_STORE_ENABLE=NO \
        2>&1 | grep -E "^(Building |Compiling |Linking |▸|✓|✗)" || true
    
    echo -e "${GREEN}✅ Build completed${NC}\n"
}

# Function to run enhanced tests
run_enhanced_tests() {
    echo -e "${YELLOW}🚀 Running enhanced UI tests...${NC}"
    
    # Create test output file
    TEST_OUTPUT="$RESULTS_DIR/test_output.log"
    
    # Run tests with timeout and capture output
    set +e  # Don't exit on test failure
    
    timeout 300 xcodebuild test \
        -workspace "$PROJECT_DIR/ClaudeCodeUI.xcworkspace" \
        -scheme "$SCHEME" \
        -sdk iphonesimulator \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
        -only-testing:ClaudeCodeUIUITests/EnhancedFunctionalFlowTests \
        -resultBundlePath "$RESULTS_DIR/EnhancedTests.xcresult" \
        -maximum-test-execution-time-allowance 600 \
        2>&1 | tee "$TEST_OUTPUT"
    
    TEST_EXIT_CODE=${PIPESTATUS[0]}
    set -e
    
    # Parse test results
    echo -e "\n${YELLOW}📊 Parsing test results...${NC}"
    
    TOTAL_TESTS=$(grep -c "Test Case.*started" "$TEST_OUTPUT" 2>/dev/null || echo "0")
    PASSED_TESTS=$(grep -c "Test Case.*passed" "$TEST_OUTPUT" 2>/dev/null || echo "0")
    FAILED_TESTS=$(grep -c "Test Case.*failed" "$TEST_OUTPUT" 2>/dev/null || echo "0")
    
    echo -e "Total Tests: ${TOTAL_TESTS}"
    echo -e "${GREEN}Passed: ${PASSED_TESTS}${NC}"
    echo -e "${RED}Failed: ${FAILED_TESTS}${NC}"
    
    return $TEST_EXIT_CODE
}

# Function to extract debug info
extract_debug_info() {
    echo -e "${YELLOW}📋 Extracting debug information...${NC}"
    
    # Extract view hierarchy dumps
    grep -A 5 "View Hierarchy" "$RESULTS_DIR/test_output.log" > "$RESULTS_DIR/view_hierarchy.txt" 2>/dev/null || true
    
    # Extract button information
    grep "Available Buttons:" -A 20 "$RESULTS_DIR/test_output.log" > "$RESULTS_DIR/available_buttons.txt" 2>/dev/null || true
    
    # Extract element discovery issues
    grep -E "not found|timed out|Failed to find" "$RESULTS_DIR/test_output.log" > "$RESULTS_DIR/element_issues.txt" 2>/dev/null || true
    
    echo -e "${GREEN}✅ Debug info extracted${NC}"
}

# Function to generate comprehensive report
generate_report() {
    echo -e "${YELLOW}📊 Generating comprehensive test report...${NC}"
    
    REPORT_FILE="$RESULTS_DIR/ENHANCED_TEST_REPORT.md"
    
    cat > "$REPORT_FILE" << EOF
# Enhanced Functional UI Test Report
Generated: $(date)

## Test Environment
- Device: iOS Simulator (iPhone 16 Pro)
- Backend: http://localhost:3004
- Test Suite: EnhancedFunctionalFlowTests

## Test Results Summary

| Metric | Value |
|--------|-------|
| Total Tests | $TOTAL_TESTS |
| Passed | $PASSED_TESTS |
| Failed | $FAILED_TESTS |
| Success Rate | $(( TOTAL_TESTS > 0 ? PASSED_TESTS * 100 / TOTAL_TESTS : 0 ))% |

## Element Discovery Status

### Successfully Found Elements
$(grep "✅ Found" "$RESULTS_DIR/test_output.log" 2>/dev/null || echo "No elements logged as found")

### Failed Element Discovery
$(grep "❌\|not found" "$RESULTS_DIR/test_output.log" 2>/dev/null || echo "No element failures logged")

## View Hierarchy Analysis
$(head -20 "$RESULTS_DIR/view_hierarchy.txt" 2>/dev/null || echo "No view hierarchy captured")

## Debug Information

### Available UI Elements
$(head -30 "$RESULTS_DIR/available_buttons.txt" 2>/dev/null || echo "No button information captured")

### WebSocket Status
$(grep -E "WebSocket|socket" "$RESULTS_DIR/websocket_test.log" 2>/dev/null | head -5 || echo "WebSocket test not performed")

## Test Execution Details

### Test Duration
- Start: $(grep "Test Suite.*started" "$RESULTS_DIR/test_output.log" 2>/dev/null | head -1 || echo "Not captured")
- End: $(grep "Test Suite.*passed\|failed" "$RESULTS_DIR/test_output.log" 2>/dev/null | tail -1 || echo "Not captured")

### Individual Test Results
$(grep "Test Case" "$RESULTS_DIR/test_output.log" 2>/dev/null || echo "No individual test results captured")

## Recommendations

$(if [ "$FAILED_TESTS" -gt 0 ]; then
    echo "### Failed Tests Need Attention"
    echo "1. Review element identifiers in the app code"
    echo "2. Ensure accessibility identifiers are set correctly"
    echo "3. Check if UI elements are loaded asynchronously"
    echo "4. Verify backend is returning expected data"
else
    echo "### All Tests Passed Successfully"
    echo "- Continue monitoring for regressions"
    echo "- Consider adding more test scenarios"
fi)

## Artifacts
- Test Results: \`$RESULTS_DIR/EnhancedTests.xcresult\`
- Test Output: \`$RESULTS_DIR/test_output.log\`
- View Hierarchy: \`$RESULTS_DIR/view_hierarchy.txt\`
- Element Issues: \`$RESULTS_DIR/element_issues.txt\`

---
*Enhanced Test Suite with Debug Capabilities*
EOF
    
    echo -e "${GREEN}✅ Report generated: $REPORT_FILE${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}Starting enhanced UI test suite...${NC}\n"
    
    # Check backend
    check_backend
    
    # Generate project if needed
    generate_project
    
    # Clean build artifacts
    clean_build
    
    # Build for testing
    build_for_testing
    
    # Run enhanced tests
    if run_enhanced_tests; then
        echo -e "\n${GREEN}✅ Enhanced UI tests completed successfully!${NC}"
        TEST_STATUS="PASSED"
    else
        echo -e "\n${YELLOW}⚠️ Some enhanced tests failed or timed out${NC}"
        TEST_STATUS="FAILED"
    fi
    
    # Extract debug information
    extract_debug_info
    
    # Generate report
    generate_report
    
    # Final summary
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    Final Summary                             ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    
    if [ "$TEST_STATUS" = "PASSED" ]; then
        echo -e "${GREEN}✅ ALL ENHANCED TESTS PASSED${NC}"
        EXIT_CODE=0
    else
        echo -e "${YELLOW}⚠️ TEST SUITE NEEDS ATTENTION${NC}"
        echo -e "Review the debug output to fix element discovery issues"
        EXIT_CODE=1
    fi
    
    echo -e "\n📁 Results Directory: $RESULTS_DIR"
    echo -e "📄 Test Report: $RESULTS_DIR/ENHANCED_TEST_REPORT.md"
    echo -e "🔍 Debug Info: $RESULTS_DIR/view_hierarchy.txt"
    echo -e "⚠️ Issues: $RESULTS_DIR/element_issues.txt"
    
    exit $EXIT_CODE
}

# Run main function
main "$@"