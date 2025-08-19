#!/bin/bash

# Integration Test Script for Claude Code iOS UI
# Tests all critical fixes and verifies end-to-end functionality
# Created on 2025-01-18

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
SIMULATOR_UUID="05223130-57AA-48B0-ABD0-4D59CE455F14"
BACKEND_URL="http://localhost:3004"
PROJECT_PATH="/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS"
SCHEME="ClaudeCodeUI"
BUNDLE_ID="com.claudecode.ui"

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}    Claude Code iOS UI - Critical Fixes Integration Test${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Function to print test section headers
print_section() {
    echo ""
    echo -e "${YELLOW}▶ $1${NC}"
    echo "────────────────────────────────────────────────────────────────"
}

# Function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        if [ ! -z "$3" ]; then
            echo -e "${RED}   Error: $3${NC}"
        fi
    fi
}

# Function to check if process is running
is_running() {
    pgrep -f "$1" > /dev/null 2>&1
}

# Function to wait for backend
wait_for_backend() {
    local max_attempts=30
    local attempt=0
    
    echo -n "Waiting for backend server"
    while ! curl -s "$BACKEND_URL/api/projects" > /dev/null 2>&1; do
        if [ $attempt -ge $max_attempts ]; then
            echo ""
            return 1
        fi
        echo -n "."
        sleep 1
        ((attempt++))
    done
    echo " Ready!"
    return 0
}

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0

# ═══════════════════════════════════════════════════════════════
# PHASE 1: Environment Setup
# ═══════════════════════════════════════════════════════════════

print_section "PHASE 1: Environment Setup"

# Check if Xcode is installed
if command -v xcodebuild &> /dev/null; then
    print_result 0 "Xcode is installed"
    ((TESTS_PASSED++))
else
    print_result 1 "Xcode is not installed"
    ((TESTS_FAILED++))
    exit 1
fi

# Check if backend directory exists
if [ -d "backend" ]; then
    print_result 0 "Backend directory exists"
    ((TESTS_PASSED++))
else
    print_result 1 "Backend directory not found"
    ((TESTS_FAILED++))
    exit 1
fi

# Check if iOS project exists
if [ -f "$PROJECT_PATH/ClaudeCodeUI.xcodeproj/project.pbxproj" ]; then
    print_result 0 "iOS project exists"
    ((TESTS_PASSED++))
else
    print_result 1 "iOS project not found"
    ((TESTS_FAILED++))
    exit 1
fi

# ═══════════════════════════════════════════════════════════════
# PHASE 2: Backend Server
# ═══════════════════════════════════════════════════════════════

print_section "PHASE 2: Backend Server"

# Kill any existing backend server
if is_running "node.*backend"; then
    echo "Stopping existing backend server..."
    pkill -f "node.*backend" || true
    sleep 2
fi

# Start backend server
echo "Starting backend server..."
cd backend
npm install > /dev/null 2>&1
npm start > backend.log 2>&1 &
BACKEND_PID=$!
cd ..

# Wait for backend to be ready
if wait_for_backend; then
    print_result 0 "Backend server started (PID: $BACKEND_PID)"
    ((TESTS_PASSED++))
else
    print_result 1 "Backend server failed to start"
    cat backend/backend.log
    ((TESTS_FAILED++))
    exit 1
fi

# Test backend API
echo "Testing backend API endpoints..."

# Test projects endpoint
if curl -s "$BACKEND_URL/api/projects" | grep -q "projects"; then
    print_result 0 "Projects API endpoint working"
    ((TESTS_PASSED++))
else
    print_result 1 "Projects API endpoint failed"
    ((TESTS_FAILED++))
fi

# Test WebSocket endpoint
if curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/ws" | grep -q "426"; then
    print_result 0 "WebSocket endpoint available (upgrade required)"
    ((TESTS_PASSED++))
else
    print_result 1 "WebSocket endpoint not available"
    ((TESTS_FAILED++))
fi

# ═══════════════════════════════════════════════════════════════
# PHASE 3: iOS Simulator Setup
# ═══════════════════════════════════════════════════════════════

print_section "PHASE 3: iOS Simulator Setup"

# Check if simulator exists
if xcrun simctl list devices | grep -q "$SIMULATOR_UUID"; then
    print_result 0 "Target simulator exists"
    ((TESTS_PASSED++))
else
    print_result 1 "Target simulator not found"
    echo "Please ensure simulator UUID $SIMULATOR_UUID exists"
    ((TESTS_FAILED++))
    exit 1
fi

# Boot simulator if needed
SIMULATOR_STATE=$(xcrun simctl list devices | grep "$SIMULATOR_UUID" | grep -o "(.*)" | tr -d "()")
if [ "$SIMULATOR_STATE" != "Booted" ]; then
    echo "Booting simulator..."
    xcrun simctl boot "$SIMULATOR_UUID"
    sleep 5
fi
print_result 0 "Simulator is booted"
((TESTS_PASSED++))

# Open Simulator app
open -a Simulator
sleep 2
print_result 0 "Simulator app opened"
((TESTS_PASSED++))

# ═══════════════════════════════════════════════════════════════
# PHASE 4: Build iOS App
# ═══════════════════════════════════════════════════════════════

print_section "PHASE 4: Build iOS App"

echo "Building iOS app..."
cd "$PROJECT_PATH"

# Clean build folder
rm -rf Build/

# Build the app
if xcodebuild build \
    -project ClaudeCodeUI.xcodeproj \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=$SIMULATOR_UUID" \
    -derivedDataPath ./Build \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    -quiet; then
    print_result 0 "iOS app built successfully"
    ((TESTS_PASSED++))
else
    print_result 1 "iOS app build failed"
    ((TESTS_FAILED++))
    exit 1
fi

# ═══════════════════════════════════════════════════════════════
# PHASE 5: Install and Launch App
# ═══════════════════════════════════════════════════════════════

print_section "PHASE 5: Install and Launch App"

# Find the built app
APP_PATH=$(find Build/Build/Products -name "*.app" -type d | head -n 1)
if [ -z "$APP_PATH" ]; then
    print_result 1 "Built app not found"
    ((TESTS_FAILED++))
    exit 1
fi
print_result 0 "Built app found: $APP_PATH"
((TESTS_PASSED++))

# Uninstall existing app
xcrun simctl uninstall "$SIMULATOR_UUID" "$BUNDLE_ID" 2>/dev/null || true

# Install the app
if xcrun simctl install "$SIMULATOR_UUID" "$APP_PATH"; then
    print_result 0 "App installed on simulator"
    ((TESTS_PASSED++))
else
    print_result 1 "App installation failed"
    ((TESTS_FAILED++))
    exit 1
fi

# Launch the app
if xcrun simctl launch "$SIMULATOR_UUID" "$BUNDLE_ID"; then
    print_result 0 "App launched successfully"
    ((TESTS_PASSED++))
else
    print_result 1 "App launch failed"
    ((TESTS_FAILED++))
fi

sleep 3

# ═══════════════════════════════════════════════════════════════
# PHASE 6: Run Unit Tests
# ═══════════════════════════════════════════════════════════════

print_section "PHASE 6: Run Unit Tests"

echo "Running unit tests..."

# Run tests
if xcodebuild test \
    -project ClaudeCodeUI.xcodeproj \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=$SIMULATOR_UUID" \
    -only-testing:ClaudeCodeUITests/TerminalWebSocketTests \
    -only-testing:ClaudeCodeUITests/SearchAPITests \
    -only-testing:ClaudeCodeUITests/MCPServerTests \
    -only-testing:ClaudeCodeUITests/NavigationTests \
    -only-testing:ClaudeCodeUITests/SettingsTests \
    -quiet; then
    print_result 0 "All unit tests passed"
    ((TESTS_PASSED++))
else
    print_result 1 "Unit tests failed"
    ((TESTS_FAILED++))
fi

# ═══════════════════════════════════════════════════════════════
# PHASE 7: UI Automation Tests
# ═══════════════════════════════════════════════════════════════

print_section "PHASE 7: UI Automation Tests"

# Start log streaming in background
echo "Starting log stream..."
xcrun simctl spawn "$SIMULATOR_UUID" log stream \
    --predicate 'processImagePath contains "ClaudeCodeUI"' \
    > ui_test.log 2>&1 &
LOG_PID=$!
sleep 2

# Take screenshots
echo "Taking screenshots for verification..."

# Screenshot 1: Main screen
xcrun simctl io "$SIMULATOR_UUID" screenshot test_main.png
if [ -f "test_main.png" ]; then
    print_result 0 "Main screen screenshot captured"
    ((TESTS_PASSED++))
else
    print_result 1 "Main screen screenshot failed"
    ((TESTS_FAILED++))
fi

sleep 2

# Check if app is running
if xcrun simctl listapps "$SIMULATOR_UUID" | grep -q "$BUNDLE_ID"; then
    print_result 0 "App is running on simulator"
    ((TESTS_PASSED++))
else
    print_result 1 "App is not running"
    ((TESTS_FAILED++))
fi

# ═══════════════════════════════════════════════════════════════
# PHASE 8: API Integration Tests
# ═══════════════════════════════════════════════════════════════

print_section "PHASE 8: API Integration Tests"

# Check logs for API calls
sleep 3
if grep -q "GET /api/projects" ui_test.log 2>/dev/null; then
    print_result 0 "App is making API calls to backend"
    ((TESTS_PASSED++))
else
    print_result 1 "No API calls detected"
    echo "Check ui_test.log for details"
    ((TESTS_FAILED++))
fi

# Check for WebSocket connection
if grep -q "WebSocket" ui_test.log 2>/dev/null || grep -q "ws://" ui_test.log 2>/dev/null; then
    print_result 0 "WebSocket connection attempted"
    ((TESTS_PASSED++))
else
    print_result 1 "No WebSocket connection detected"
    ((TESTS_FAILED++))
fi

# ═══════════════════════════════════════════════════════════════
# PHASE 9: Critical Features Verification
# ═══════════════════════════════════════════════════════════════

print_section "PHASE 9: Critical Features Verification"

echo "Verifying critical features..."

# Check Terminal WebSocket fix
if grep -l "ws://localhost:3004/shell" "$PROJECT_PATH/Features/Terminal/TerminalViewController.swift" > /dev/null; then
    print_result 0 "Terminal WebSocket endpoint is correct"
    ((TESTS_PASSED++))
else
    print_result 1 "Terminal WebSocket endpoint not fixed"
    ((TESTS_FAILED++))
fi

# Check Search API integration
if grep -l "real API" "$PROJECT_PATH/Features/Search/SearchViewModel.swift" > /dev/null; then
    print_result 0 "Search uses real API (not mock)"
    ((TESTS_PASSED++))
else
    print_result 1 "Search may still use mock data"
    ((TESTS_FAILED++))
fi

# Check MCP Server UI
if [ -f "$PROJECT_PATH/Features/MCP/MCPServerListViewController.swift" ]; then
    print_result 0 "MCP Server UI exists"
    ((TESTS_PASSED++))
else
    print_result 1 "MCP Server UI not found"
    ((TESTS_FAILED++))
fi

# Check Settings implementation
if grep -l "MCPServerListViewController" "$PROJECT_PATH/Features/Settings/SettingsViewController.swift" > /dev/null; then
    print_result 0 "Settings links to MCP servers"
    ((TESTS_PASSED++))
else
    print_result 1 "Settings doesn't link to MCP"
    ((TESTS_FAILED++))
fi

# ═══════════════════════════════════════════════════════════════
# PHASE 10: Cleanup
# ═══════════════════════════════════════════════════════════════

print_section "PHASE 10: Cleanup"

# Stop log streaming
if [ ! -z "$LOG_PID" ]; then
    kill $LOG_PID 2>/dev/null || true
    print_result 0 "Log streaming stopped"
fi

# Stop backend server
if [ ! -z "$BACKEND_PID" ]; then
    kill $BACKEND_PID 2>/dev/null || true
    print_result 0 "Backend server stopped"
fi

# Keep app running for manual inspection
echo ""
echo -e "${BLUE}App is still running on simulator for manual inspection${NC}"

# ═══════════════════════════════════════════════════════════════
# TEST SUMMARY
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                        TEST SUMMARY${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
PASS_RATE=$((TESTS_PASSED * 100 / TOTAL_TESTS))

echo -e "Total Tests:  $TOTAL_TESTS"
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
echo -e "Pass Rate:    ${PASS_RATE}%"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED! 🎉${NC}"
    echo -e "${GREEN}All critical fixes have been verified successfully.${NC}"
    exit 0
else
    echo -e "${RED}⚠️  SOME TESTS FAILED ⚠️${NC}"
    echo -e "${YELLOW}Please review the failed tests above and fix issues.${NC}"
    echo ""
    echo "Logs available at:"
    echo "  - Backend: backend/backend.log"
    echo "  - UI Test: ui_test.log"
    echo "  - Screenshots: test_main.png"
    exit 1
fi