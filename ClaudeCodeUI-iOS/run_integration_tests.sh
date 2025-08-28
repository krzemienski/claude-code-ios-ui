#!/bin/bash

# Integration Tests Runner for ClaudeCodeUI iOS App
# Tests against REAL BACKEND - NO MOCKS!

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_URL="http://192.168.0.43:3004"
SIMULATOR_UUID="A707456B-44DB-472F-9722-C88153CDFFA1"
PROJECT_PATH="ClaudeCodeUI.xcodeproj"
SCHEME="ClaudeCodeUI"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🧪 ClaudeCodeUI Integration Tests - REAL BACKEND${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check if backend is running
echo -e "\n${YELLOW}📡 Checking backend at ${BACKEND_URL}...${NC}"
if curl -s -o /dev/null -w "%{http_code}" "${BACKEND_URL}/api/health" | grep -q "200\|404"; then
    echo -e "${GREEN}✅ Backend is running!${NC}"
else
    echo -e "${RED}❌ Backend is not running!${NC}"
    echo -e "${YELLOW}Please start the backend first:${NC}"
    echo -e "  cd ../backend"
    echo -e "  npm start"
    exit 1
fi

# Check if simulator is available
echo -e "\n${YELLOW}📱 Checking simulator...${NC}"
if xcrun simctl list devices | grep -q "${SIMULATOR_UUID}"; then
    echo -e "${GREEN}✅ Simulator found: ${SIMULATOR_UUID}${NC}"
else
    echo -e "${RED}❌ Simulator not found!${NC}"
    echo -e "${YELLOW}Please create a simulator with UUID: ${SIMULATOR_UUID}${NC}"
    exit 1
fi

# Boot simulator if needed
SIMULATOR_STATE=$(xcrun simctl list devices | grep "${SIMULATOR_UUID}" | grep -o "(Booted)\|(Shutdown)")
if [[ "$SIMULATOR_STATE" == "(Shutdown)" ]]; then
    echo -e "${YELLOW}🔄 Booting simulator...${NC}"
    xcrun simctl boot "${SIMULATOR_UUID}"
    sleep 5
fi

# Menu for test selection
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Select tests to run:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "1) 🎯 All Integration Tests"
echo "2) 💬 Chat Messaging with Real Backend (Claude)"
echo "3) 🖥️  Terminal with Real Shell WebSocket"
echo "4) 🔌 MCP Server Management"
echo "5) 🔄 WebSocket Reconnection"
echo "6) 🚀 Full E2E Flow"
echo "7) ⚡ Performance Tests"
echo "q) Quit"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

read -p "Enter choice [1-7 or q]: " choice

case $choice in
    1)
        echo -e "\n${GREEN}🎯 Running ALL Integration Tests...${NC}"
        TEST_FILTER=""
        ;;
    2)
        echo -e "\n${GREEN}💬 Running Chat Messaging Test...${NC}"
        TEST_FILTER="-only-testing:ClaudeCodeUIUITests/ClaudeCodeUIUITests/testChatMessagingWithRealBackend"
        ;;
    3)
        echo -e "\n${GREEN}🖥️ Running Terminal Test...${NC}"
        TEST_FILTER="-only-testing:ClaudeCodeUIUITests/ClaudeCodeUIUITests/testTerminalWithRealShell"
        ;;
    4)
        echo -e "\n${GREEN}🔌 Running MCP Server Management Test...${NC}"
        TEST_FILTER="-only-testing:ClaudeCodeUIUITests/ClaudeCodeUIUITests/testMCPServerManagement"
        ;;
    5)
        echo -e "\n${GREEN}🔄 Running WebSocket Reconnection Test...${NC}"
        TEST_FILTER="-only-testing:ClaudeCodeUIUITests/ClaudeCodeUIUITests/testWebSocketReconnection"
        ;;
    6)
        echo -e "\n${GREEN}🚀 Running Full E2E Flow Test...${NC}"
        TEST_FILTER="-only-testing:ClaudeCodeUIUITests/ClaudeCodeUIUITests/testFullE2EFlowWithRealBackend"
        ;;
    7)
        echo -e "\n${GREEN}⚡ Running Performance Tests...${NC}"
        TEST_FILTER="-only-testing:ClaudeCodeUIUITests/ClaudeCodeUIUITests/testLaunchPerformance -only-testing:ClaudeCodeUIUITests/ClaudeCodeUIUITests/testScrollPerformance"
        ;;
    q)
        echo -e "${YELLOW}Exiting...${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice!${NC}"
        exit 1
        ;;
esac

# Run the tests
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🏃 Executing Tests...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ -z "$TEST_FILTER" ]; then
    # Run all tests
    xcodebuild test \
        -project "${PROJECT_PATH}" \
        -scheme "${SCHEME}" \
        -destination "platform=iOS Simulator,id=${SIMULATOR_UUID}" \
        -resultBundlePath TestResults \
        | xcpretty --color --report junit
else
    # Run specific tests
    xcodebuild test \
        -project "${PROJECT_PATH}" \
        -scheme "${SCHEME}" \
        -destination "platform=iOS Simulator,id=${SIMULATOR_UUID}" \
        ${TEST_FILTER} \
        -resultBundlePath TestResults \
        | xcpretty --color --report junit
fi

TEST_RESULT=$?

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [ $TEST_RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ Tests PASSED!${NC}"
    echo -e "${GREEN}All integration tests verified against real backend at ${BACKEND_URL}${NC}"
else
    echo -e "${RED}❌ Tests FAILED!${NC}"
    echo -e "${YELLOW}Check the test output above for details.${NC}"
    echo -e "${YELLOW}Ensure the backend is running and has test data.${NC}"
fi
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Open test results if available
if [ -d "TestResults.xcresult" ]; then
    echo -e "\n${YELLOW}📊 Opening test results...${NC}"
    open TestResults.xcresult
fi

exit $TEST_RESULT