#!/bin/bash

# Functional Automation Test Runner for ClaudeCodeUI
# Runs UI tests against real backend at 192.168.0.155:3004

set -e

# Configuration
BACKEND_URL="http://192.168.0.155:3004"
SIMULATOR_ID="BECB3FA0-518E-4F80-8B8E-7E10C16F3B36"  # iPhone 16 Pro
WORKSPACE="ClaudeCodeUI.xcworkspace"
SCHEME="ClaudeCodeUI"
TEST_CLASS="FunctionalAutomationTests"
RESULTS_PATH="FunctionalTestResults.xcresult"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 ClaudeCodeUI Functional Automation Test Runner${NC}"
echo "=================================================="
echo "Backend URL: $BACKEND_URL"
echo "Simulator: iPhone 16 Pro ($SIMULATOR_ID)"
echo ""

# Step 1: Verify backend is accessible
echo -e "${YELLOW}1️⃣ Checking backend connectivity...${NC}"
if curl -f -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/health" | grep -q "200"; then
    echo -e "${GREEN}✅ Backend is accessible at $BACKEND_URL${NC}"
else
    echo -e "${RED}❌ Backend is not accessible at $BACKEND_URL${NC}"
    echo "Please ensure the backend is running:"
    echo "  cd backend && npm start"
    exit 1
fi

# Step 2: Boot simulator
echo -e "${YELLOW}2️⃣ Preparing iOS Simulator...${NC}"
xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
sleep 2

# Check if simulator is booted
if xcrun simctl list devices | grep -q "$SIMULATOR_ID.*Booted"; then
    echo -e "${GREEN}✅ Simulator is booted${NC}"
else
    echo -e "${RED}❌ Failed to boot simulator${NC}"
    exit 1
fi

# Step 3: Clean previous results
echo -e "${YELLOW}3️⃣ Cleaning previous test results...${NC}"
rm -rf "$RESULTS_PATH"
rm -rf DerivedData

# Step 4: Build for testing
echo -e "${YELLOW}4️⃣ Building app for testing...${NC}"
xcodebuild build-for-testing \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -derivedDataPath DerivedData \
    -quiet

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build successful${NC}"
else
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

# Step 5: Run the tests
echo -e "${YELLOW}5️⃣ Running functional automation tests...${NC}"
echo ""

xcodebuild test-without-building \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -derivedDataPath DerivedData \
    -resultBundlePath "$RESULTS_PATH" \
    -only-testing:"ClaudeCodeUIUITests/$TEST_CLASS" \
    BACKEND_URL="$BACKEND_URL" \
    USE_REAL_BACKEND="true" \
    | xcpretty --color --report junit

TEST_RESULT=$?

# Step 6: Generate report
echo ""
echo -e "${YELLOW}6️⃣ Generating test report...${NC}"

if [ -f "$RESULTS_PATH" ]; then
    # Extract test results
    xcrun xcresulttool get --path "$RESULTS_PATH" --format json > test-results.json
    
    # Count results
    TOTAL_TESTS=$(grep -o '"test"' test-results.json | wc -l)
    FAILURES=$(grep -o '"failure"' test-results.json | wc -l)
    
    echo ""
    echo "=================================================="
    echo -e "${GREEN}📊 Test Results Summary${NC}"
    echo "=================================================="
    echo "Total Tests: $TOTAL_TESTS"
    echo "Failures: $FAILURES"
    echo "Results saved to: $RESULTS_PATH"
    echo ""
fi

# Step 7: Open results in Xcode (optional)
if [ "$1" == "--open" ]; then
    echo -e "${YELLOW}7️⃣ Opening results in Xcode...${NC}"
    open "$RESULTS_PATH"
fi

# Final status
if [ $TEST_RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed successfully!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Check the results for details.${NC}"
    
    # Capture screenshot of failure
    xcrun simctl io booted screenshot failure-screenshot.png
    echo "Screenshot saved to: failure-screenshot.png"
    
    exit 1
fi