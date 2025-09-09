#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Comprehensive UI Flow Test${NC}"
echo "================================"

# 1. Check backend
echo -e "\n${YELLOW}Checking backend...${NC}"
if curl -s http://localhost:3004/api/projects > /dev/null 2>&1; then
    PROJECT_COUNT=$(curl -s http://localhost:3004/api/projects | python3 -c "import json,sys; print(json.load(sys.stdin)['count'])" 2>/dev/null || echo "0")
    echo -e "${GREEN}✅ Backend running with $PROJECT_COUNT projects${NC}"
else
    echo -e "${RED}❌ Backend not running at localhost:3004${NC}"
    exit 1
fi

# 2. Clean previous results
echo -e "\n${YELLOW}Cleaning previous results...${NC}"
rm -rf ComprehensiveFlowResults.xcresult
rm -f comprehensive_flow_output.log

# 3. Build the app first
echo -e "\n${YELLOW}Building app...${NC}"
xcodebuild build-for-testing \
    -workspace ClaudeCodeUI.xcworkspace \
    -scheme ClaudeCodeUI \
    -destination 'generic/platform=iOS Simulator' \
    -quiet

echo -e "${GREEN}✅ Build complete${NC}"

# 4. Run the test
echo -e "\n${YELLOW}Running UI test...${NC}"
echo "This will capture screenshots and test the complete flow"

xcodebuild test-without-building \
    -workspace ClaudeCodeUI.xcworkspace \
    -scheme ClaudeCodeUI \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' \
    -only-testing:ClaudeCodeUIUITests/ComprehensiveFlowTest/testCompleteUserFlow \
    -resultBundlePath ComprehensiveFlowResults.xcresult \
    2>&1 | tee comprehensive_flow_output.log | while IFS= read -r line; do
        # Show test progress
        if echo "$line" | grep -q "Test Case.*started"; then
            echo -e "${BLUE}🧪 Test started${NC}"
        elif echo "$line" | grep -q "Test Case.*passed"; then
            echo -e "${GREEN}✅ Test passed${NC}"
        elif echo "$line" | grep -q "Test Case.*failed"; then
            echo -e "${RED}❌ Test failed${NC}"
        fi
        
        # Show our debug output
        if echo "$line" | grep -qE "🚀|⏳|📊|📱|🔄|🔍|✅|⚠️|📜|📸|❌"; then
            echo "$line"
        fi
        
        # Show UI element discovery
        if echo "$line" | grep -qiE "Found.*collection|Found.*table|Found.*project|Found.*cell"; then
            echo -e "${GREEN}$line${NC}"
        fi
        
        # Show errors
        if echo "$line" | grep -qiE "error|fail|crash|exception" && ! echo "$line" | grep -q "0 failures"; then
            echo -e "${RED}$line${NC}"
        fi
    done

# 5. Extract test results
echo -e "\n${YELLOW}Extracting test results...${NC}"

if [ -d "ComprehensiveFlowResults.xcresult" ]; then
    # Try to get screenshots
    SCREENSHOT_COUNT=$(find ComprehensiveFlowResults.xcresult -name "*.png" 2>/dev/null | wc -l | tr -d ' ')
    echo -e "${GREEN}✅ Captured $SCREENSHOT_COUNT screenshots${NC}"
    
    # Extract key findings from log
    echo -e "\n${BLUE}Key Findings:${NC}"
    grep -E "Collection Views:|Tables:|Static Texts:|project|Project" comprehensive_flow_output.log | tail -10 || true
fi

echo -e "\n${GREEN}✅ Test execution complete${NC}"
echo "Check comprehensive_flow_output.log for full details"
