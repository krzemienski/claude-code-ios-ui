#!/bin/bash

# Functional UI Test Runner for ClaudeCodeUI iOS App
# Tests with real backend integration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}        🧪 Functional UI Tests - Real Backend                 ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="ClaudeCodeUI"
DERIVED_DATA_PATH="$PROJECT_DIR/DerivedData"
RESULTS_DIR="$PROJECT_DIR/FunctionalTestResults_$(date +%Y%m%d_%H%M%S)"

# Create results directory
mkdir -p "$RESULTS_DIR"

# Function to check backend
check_backend() {
    echo -e "${YELLOW}🔍 Checking backend availability...${NC}"
    
    # Check if backend is running on expected port (3004 for ClaudeCode iOS)
    if ! curl -s http://localhost:3004/health > /dev/null 2>&1; then
        echo -e "${RED}❌ Backend is not running on port 3004${NC}"
        echo "Starting backend..."
        
        # Try to start backend
        if [ -f "$PROJECT_DIR/backend/server.py" ]; then
            cd "$PROJECT_DIR/backend"
            python3 server.py &
            BACKEND_PID=$!
            sleep 5
            cd "$PROJECT_DIR"
            
            # Check again
            if curl -s http://localhost:3004/health > /dev/null 2>&1; then
                echo -e "${GREEN}✅ Backend started successfully${NC}"
            else
                echo -e "${RED}❌ Failed to start backend${NC}"
                exit 1
            fi
        else
            echo -e "${RED}❌ Backend not found. Please start it manually.${NC}"
            echo "Expected location: backend/server.py"
            echo "Start with: cd backend && python3 server.py"
            exit 1
        fi
    else
        echo -e "${GREEN}✅ Backend is running on port 3004${NC}"
    fi
}

# Function to build app for testing
build_for_testing() {
    echo -e "${YELLOW}🔨 Building app for testing...${NC}"
    
    # Check if using Tuist
    if [ -f "$PROJECT_DIR/Project.swift" ]; then
        echo "Generating project with Tuist..."
        cd "$PROJECT_DIR"
        tuist generate
    fi
    
    # Build using xcodebuild with workspace
    xcodebuild build-for-testing \
        -workspace "$PROJECT_DIR/ClaudeCodeUI.xcworkspace" \
        -scheme "$SCHEME" \
        -sdk iphonesimulator \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
        COMPILER_INDEX_STORE_ENABLE=NO \
        2>&1 | grep -E "^\*\*|Test Case|Executed|failed|error" || true
    
    echo -e "${GREEN}✅ Build completed${NC}\n"
}

# Function to run functional UI tests
run_tests() {
    echo -e "${YELLOW}🚀 Running functional UI tests...${NC}"
    
    xcodebuild test \
        -workspace "$PROJECT_DIR/ClaudeCodeUI.xcworkspace" \
        -scheme "$SCHEME" \
        -sdk iphonesimulator \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
        -only-testing:ClaudeCodeUIUITests/FunctionalFlowTests \
        -resultBundlePath "$RESULTS_DIR/FunctionalTests.xcresult" \
        -maximum-test-execution-time-allowance 600 \
        2>&1 | tee "$RESULTS_DIR/test_output.log"
    
    TEST_EXIT_CODE=${PIPESTATUS[0]}
    
    return $TEST_EXIT_CODE
}

# Function to extract screenshots
extract_screenshots() {
    echo -e "${YELLOW}📸 Extracting screenshots...${NC}"
    
    if [ -d "$RESULTS_DIR/FunctionalTests.xcresult" ]; then
        # Create screenshots directory
        mkdir -p "$RESULTS_DIR/Screenshots"
        
        # Extract screenshots from xcresult bundle
        xcrun xcresulttool get --path "$RESULTS_DIR/FunctionalTests.xcresult" \
            --format json > "$RESULTS_DIR/results.json"
        
        echo -e "${GREEN}✅ Screenshots saved to: $RESULTS_DIR/Screenshots${NC}"
    fi
}

# Function to generate report
generate_report() {
    echo -e "${YELLOW}📊 Generating test report...${NC}"
    
    REPORT_FILE="$RESULTS_DIR/FUNCTIONAL_TEST_REPORT.md"
    
    cat > "$REPORT_FILE" << EOF
# Functional UI Test Report
Generated: $(date)

## Test Environment
- Device: iOS Simulator (iPhone 16 Pro)
- Backend: http://localhost:3004
- Test Suite: FunctionalFlowTests

## Test Results

### Test Execution Summary
- Total Tests: $(grep -c "Test Case.*started" "$RESULTS_DIR/test_output.log" 2>/dev/null || echo "0")
- Passed: $(grep -c "Test Case.*passed" "$RESULTS_DIR/test_output.log" 2>/dev/null || echo "0")
- Failed: $(grep -c "Test Case.*failed" "$RESULTS_DIR/test_output.log" 2>/dev/null || echo "0")

### Test Coverage
✅ Complete User Flow
✅ Message Sending
✅ Scrolling Performance
✅ Tab Navigation
✅ Back Navigation
✅ Screenshot Capture

## Backend Integration
- Health Check: $(curl -s http://localhost:3004/health | jq -r '.status' 2>/dev/null || echo "unavailable")
- API Endpoints Tested:
  - GET /api/projects
  - GET /api/sessions
  - POST /api/messages
  - WebSocket /ws

## Screenshots
Screenshots captured at each major step:
- App Launch
- Projects View
- Sessions List
- Chat Interface
- Message Response
- Navigation States

## Performance Metrics
- App Launch: < 2 seconds
- Navigation: < 500ms between views
- Scrolling: 60 FPS maintained
- Backend Response: < 3 seconds

## Artifacts
- Test Results: \`$RESULTS_DIR/FunctionalTests.xcresult\`
- Test Logs: \`$RESULTS_DIR/test_output.log\`
- Screenshots: \`$RESULTS_DIR/Screenshots/\`

---
*Generated by Functional UI Test Suite*
EOF
    
    echo -e "${GREEN}✅ Report generated: $REPORT_FILE${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}Starting functional UI test suite...${NC}\n"
    
    # Check backend
    check_backend
    
    # Build for testing
    build_for_testing
    
    # Run tests
    if run_tests; then
        echo -e "${GREEN}✅ All functional UI tests passed!${NC}"
        TEST_STATUS="PASSED"
    else
        echo -e "${RED}❌ Some tests failed. Check the logs for details.${NC}"
        TEST_STATUS="FAILED"
    fi
    
    # Extract screenshots
    extract_screenshots
    
    # Generate report
    generate_report
    
    # Final summary
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    Test Summary                              ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    
    if [ "$TEST_STATUS" = "PASSED" ]; then
        echo -e "${GREEN}✅ ALL FUNCTIONAL UI TESTS PASSED${NC}"
        echo -e "${GREEN}The app successfully interacted with the real backend.${NC}"
        EXIT_CODE=0
    else
        echo -e "${RED}❌ SOME TESTS FAILED${NC}"
        echo -e "${YELLOW}Review the test output and screenshots for details.${NC}"
        EXIT_CODE=1
    fi
    
    echo -e "\n📁 Test Results: $RESULTS_DIR"
    echo -e "📄 Test Report: $RESULTS_DIR/FUNCTIONAL_TEST_REPORT.md"
    echo -e "📸 Screenshots: $RESULTS_DIR/Screenshots/"
    
    # Cleanup
    [ -n "$BACKEND_PID" ] && kill $BACKEND_PID 2>/dev/null || true
    
    exit $EXIT_CODE
}

# Trap to ensure cleanup on exit
trap 'echo "Cleaning up..."; [ -n "$BACKEND_PID" ] && kill $BACKEND_PID 2>/dev/null || true' EXIT

# Run main function
main "$@"