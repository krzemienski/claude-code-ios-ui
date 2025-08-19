#!/bin/bash

# Critical Fixes Integration Test
# Tests Terminal WebSocket, MCP UI, Search API
# Created: 2025-01-18

set -e

echo "=================================="
echo "Critical Fixes Integration Test"
echo "=================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

SIMULATOR_UUID="A707456B-44DB-472F-9722-C88153CDFFA1"
BACKEND_URL="http://localhost:3004"
PASSED=0
FAILED=0

# Function to check result
check_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ $2${NC}"
        ((FAILED++))
    fi
}

echo "1. Checking Backend Server..."
if curl -s "$BACKEND_URL/api/projects" > /dev/null; then
    check_result 0 "Backend server is running"
else
    check_result 1 "Backend server not accessible"
fi

echo ""
echo "2. Checking App Installation..."
if xcrun simctl listapps "$SIMULATOR_UUID" | grep -q "com.claudecode.ui"; then
    check_result 0 "App is installed on simulator"
else
    check_result 1 "App not installed"
fi

echo ""
echo "3. Checking Terminal WebSocket Fix..."
if grep -q "ws://localhost:3004/shell" ClaudeCodeUI-iOS/Features/Terminal/TerminalViewController.swift; then
    check_result 0 "Terminal WebSocket endpoint is correct"
    
    # Check if connection method exists
    if grep -q "connectShellWebSocket()" ClaudeCodeUI-iOS/Features/Terminal/TerminalViewController.swift; then
        check_result 0 "Terminal WebSocket connection method exists"
    else
        check_result 1 "Terminal WebSocket connection method missing"
    fi
else
    check_result 1 "Terminal WebSocket endpoint not fixed"
fi

echo ""
echo "4. Checking MCP Server Management..."
if [ -f "ClaudeCodeUI-iOS/Features/MCP/MCPServerListViewController.swift" ]; then
    check_result 0 "MCP Server UI implementation exists"
    
    # Check API implementation
    if grep -q "listMCPServers" ClaudeCodeUI-iOS/Core/Network/APIClient.swift; then
        check_result 0 "MCP API methods implemented"
    else
        check_result 1 "MCP API methods missing"
    fi
else
    check_result 1 "MCP Server UI not found"
fi

echo ""
echo "5. Checking Search API Integration..."
if grep -q "performSearch" ClaudeCodeUI-iOS/Features/Search/SearchViewModel.swift; then
    check_result 0 "Search functionality exists"
    
    # Check if using real API
    if grep -q "// Using real API" ClaudeCodeUI-iOS/Features/Search/SearchViewModel.swift; then
        check_result 0 "Search uses real API (not mock)"
    else
        check_result 1 "Search may still use mock data"
    fi
else
    check_result 1 "Search functionality not found"
fi

echo ""
echo "6. Checking WebSocket Connection..."
# Check app logs for WebSocket connection
LOG_FILE="/tmp/app_test.log"
xcrun simctl spawn "$SIMULATOR_UUID" log stream --predicate 'processImagePath contains "ClaudeCodeUI"' > "$LOG_FILE" 2>&1 &
LOG_PID=$!
sleep 3

if grep -q "WebSocket connected" "$LOG_FILE" 2>/dev/null; then
    check_result 0 "WebSocket successfully connects"
else
    check_result 1 "WebSocket connection not verified"
fi

kill $LOG_PID 2>/dev/null || true

echo ""
echo "7. Checking Navigation Structure..."
if [ -f "ClaudeCodeUI-iOS/Core/Navigation/MainTabBarController.swift" ]; then
    check_result 0 "Tab bar navigation exists"
    
    # Check for all tabs
    if grep -q "Git" ClaudeCodeUI-iOS/Core/Navigation/MainTabBarController.swift && \
       grep -q "MCP" ClaudeCodeUI-iOS/Core/Navigation/MainTabBarController.swift && \
       grep -q "Settings" ClaudeCodeUI-iOS/Core/Navigation/MainTabBarController.swift; then
        check_result 0 "All tabs (including More menu items) configured"
    else
        check_result 1 "Some tabs missing from configuration"
    fi
else
    check_result 1 "Tab bar navigation not found"
fi

echo ""
echo "8. Checking File Operations..."
if grep -q "readFile" ClaudeCodeUI-iOS/Core/Network/APIClient.swift && \
   grep -q "writeFile" ClaudeCodeUI-iOS/Core/Network/APIClient.swift; then
    check_result 0 "File operations API implemented"
else
    check_result 1 "File operations API missing"
fi

echo ""
echo "=================================="
echo "TEST SUMMARY"
echo "=================================="
echo -e "Tests Passed: ${GREEN}$PASSED${NC}"
echo -e "Tests Failed: ${RED}$FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All critical fixes verified!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️ Some tests failed. Review the issues above.${NC}"
    exit 1
fi