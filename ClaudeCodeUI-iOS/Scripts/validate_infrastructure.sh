#!/bin/bash

# Infrastructure Validation Script
# Created by Agent-2: Build & Infrastructure Specialist

echo "=" 
echo "🔧 iOS App Infrastructure Validation"
echo "="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Results tracking
TESTS_PASSED=0
TESTS_FAILED=0

# Function to check a condition
check() {
    local name="$1"
    local condition="$2"
    
    echo -n "Checking $name... "
    
    if eval "$condition"; then
        echo -e "${GREEN}✅ PASSED${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAILED${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# 1. Check if app is built
echo "1️⃣ Build Verification"
check "App binary exists" "[ -f build/ClaudeCodeUI.app/ClaudeCodeUI ]"
check "Info.plist exists" "[ -f build/ClaudeCodeUI.app/Info.plist ]"
check "App size reasonable" "[ $(du -sm build/ClaudeCodeUI.app | cut -f1) -gt 1 ]"
echo ""

# 2. Check simulator status
echo "2️⃣ Simulator Status"
SIMULATOR_STATUS=$(xcrun simctl list devices | grep "iPhone 16 Pro" | grep "Booted" | wc -l)
check "iPhone 16 Pro is booted" "[ $SIMULATOR_STATUS -gt 0 ]"

# Get simulator UDID
SIMULATOR_UDID=$(xcrun simctl list devices | grep "iPhone 16 Pro" | grep "Booted" | head -1 | grep -o "([A-F0-9-]*)" | tr -d "()")
echo "   Simulator UDID: $SIMULATOR_UDID"
echo ""

# 3. Check app installation
echo "3️⃣ App Installation"
APP_INSTALLED=$(xcrun simctl listapps "$SIMULATOR_UDID" 2>/dev/null | grep "com.claudecode.ui" | wc -l)
check "App installed on simulator" "[ $APP_INSTALLED -gt 0 ]"

if [ $APP_INSTALLED -gt 0 ]; then
    echo "   Bundle ID: com.claudecode.ui"
    APP_PATH=$(xcrun simctl listapps "$SIMULATOR_UDID" | grep -A5 "com.claudecode.ui" | grep "Path" | cut -d':' -f2- | xargs)
    echo "   Installed at: $APP_PATH"
fi
echo ""

# 4. Check backend connectivity
echo "4️⃣ Backend Connectivity"
BACKEND_URL="http://192.168.0.155:3004"

# Check if backend is reachable
if curl -s --connect-timeout 2 "$BACKEND_URL" > /dev/null 2>&1; then
    check "Backend reachable" "true"
    
    # Get backend status
    BACKEND_RESPONSE=$(curl -s "$BACKEND_URL")
    echo "   Backend response: $BACKEND_RESPONSE"
else
    check "Backend reachable" "false"
fi

# Check WebSocket endpoint
WS_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "${BACKEND_URL}/ws" 2>/dev/null)
if [ "$WS_CHECK" = "426" ] || [ "$WS_CHECK" = "400" ]; then
    # 426 Upgrade Required or 400 Bad Request is expected for WebSocket endpoints
    echo -e "   WebSocket endpoint: ${GREEN}✅ Available${NC}"
    ((TESTS_PASSED++))
else
    echo -e "   WebSocket endpoint: ${YELLOW}⚠️ Status: $WS_CHECK${NC}"
fi
echo ""

# 5. App Launch Test
echo "5️⃣ App Launch Test"
echo -n "Attempting to launch app... "

# Kill any existing instance
xcrun simctl terminate "$SIMULATOR_UDID" com.claudecode.ui 2>/dev/null

# Launch the app
LAUNCH_OUTPUT=$(xcrun simctl launch "$SIMULATOR_UDID" com.claudecode.ui 2>&1)
LAUNCH_EXIT=$?

if [ $LAUNCH_EXIT -eq 0 ]; then
    echo -e "${GREEN}✅ LAUNCHED${NC}"
    ((TESTS_PASSED++))
    
    # Extract PID
    PID=$(echo "$LAUNCH_OUTPUT" | grep -o "[0-9]*$")
    echo "   Process ID: $PID"
    
    # Give app time to initialize
    sleep 3
    
    # Check if still running
    if xcrun simctl spawn "$SIMULATOR_UDID" launchctl list | grep -q "com.claudecode.ui"; then
        echo -e "   App status: ${GREEN}Running${NC}"
    else
        echo -e "   App status: ${YELLOW}May have crashed${NC}"
    fi
else
    echo -e "${RED}❌ FAILED TO LAUNCH${NC}"
    echo "   Error: $LAUNCH_OUTPUT"
    ((TESTS_FAILED++))
fi
echo ""

# 6. UI Test Infrastructure
echo "6️⃣ Test Infrastructure"
check "UI test files exist" "[ -d ClaudeCodeUIUITests ]"
check "Test runner created" "[ -f ClaudeCodeUIUITests/FunctionalTestRunner.swift ]"
check "Test scheme exists" "xcodebuild -workspace ClaudeCodeUI.xcworkspace -list 2>/dev/null | grep -q 'ClaudeCodeUI-Tests'"
echo ""

# 7. Network Configuration
echo "7️⃣ Network Configuration"
echo "   Backend URL: $BACKEND_URL"
echo "   WebSocket URL: ws://192.168.0.155:3004/ws"

# Check if simulator can reach backend
SIMULATOR_NETWORK=$(xcrun simctl spawn "$SIMULATOR_UDID" ping -c 1 -t 1 192.168.0.155 2>&1)
if echo "$SIMULATOR_NETWORK" | grep -q "1 packets received"; then
    echo -e "   Simulator network: ${GREEN}✅ Can reach backend${NC}"
    ((TESTS_PASSED++))
else
    echo -e "   Simulator network: ${RED}❌ Cannot reach backend${NC}"
    ((TESTS_FAILED++))
fi
echo ""

# Summary
echo "="
echo "📊 Infrastructure Validation Summary"
echo "="
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Infrastructure is READY for functional testing!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Open Xcode and run UI tests"
    echo "2. Or use: xcodebuild test -workspace ClaudeCodeUI.xcworkspace -scheme ClaudeCodeUI"
    echo "3. Monitor app logs with: xcrun simctl spawn booted log stream --predicate 'subsystem == \"com.claudecode.ui\"'"
    exit 0
else
    echo ""
    echo -e "${RED}⚠️ Infrastructure has issues that need fixing${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "1. Rebuild app if binary issues"
    echo "2. Reset simulator if installation issues"
    echo "3. Check backend is running on 192.168.0.155:3004"
    echo "4. Verify network connectivity between simulator and backend"
    exit 1
fi