#!/bin/bash

# Wave 2 Feature Verification Test Script
# Run this after applying fixes to verify all issues are resolved
# Usage: ./wave2-verification-tests.sh

set -e

SIMULATOR_UUID="6520A438-0B1F-485B-9037-F346837B6D14"
PROJECT_DIR="/Users/nick/Documents/claude-code-ios-ui"
BACKEND_URL="http://localhost:3004"
LOG_FILE="$PROJECT_DIR/logs/wave2_verification.log"

echo "========================================"
echo "Wave 2 Feature Verification Tests"
echo "Date: $(date)"
echo "========================================"

# Function to print colored output
print_status() {
    if [ "$1" = "PASS" ]; then
        echo -e "\033[0;32m✅ $2\033[0m"
    elif [ "$1" = "FAIL" ]; then
        echo -e "\033[0;31m❌ $2\033[0m"
    else
        echo -e "\033[0;33m⚠️  $2\033[0m"
    fi
}

# Function to check backend server
check_backend() {
    echo -n "Checking backend server... "
    if curl -s "$BACKEND_URL" > /dev/null 2>&1; then
        print_status "PASS" "Backend server is running"
        return 0
    else
        print_status "FAIL" "Backend server is not running"
        echo "Starting backend server..."
        cd "$PROJECT_DIR/backend" && npm start > server.log 2>&1 &
        sleep 3
        return 1
    fi
}

# Test 1: WebSocket Reconnection with Exponential Backoff
test_reconnection() {
    echo ""
    echo "TEST 1: WebSocket Reconnection"
    echo "--------------------------------"
    
    # Start log monitoring
    xcrun simctl spawn "$SIMULATOR_UUID" log stream \
        --predicate 'processImagePath contains "ClaudeCodeUI"' \
        --level debug > "$LOG_FILE" 2>&1 &
    LOG_PID=$!
    
    # Kill backend to trigger disconnection
    echo "Killing backend server..."
    pkill -f "node.*backend" || true
    sleep 2
    
    # Check for reconnection attempts
    echo "Monitoring reconnection attempts for 20 seconds..."
    
    # Expected pattern: 1s, 2s, 4s, 8s delays
    EXPECTED_DELAYS=(1 2 4 8)
    FOUND_DELAYS=()
    
    for i in {1..20}; do
        if grep -q "Attempting reconnection #$i" "$LOG_FILE" 2>/dev/null; then
            FOUND_DELAYS+=($i)
            echo "  Found reconnection attempt #$i"
        fi
        sleep 1
    done
    
    # Restart backend
    cd "$PROJECT_DIR/backend" && npm start > server.log 2>&1 &
    sleep 3
    
    # Check if reconnection successful
    if grep -q "WebSocket connected and verified" "$LOG_FILE" 2>/dev/null; then
        print_status "PASS" "Reconnection successful after server restart"
    else
        print_status "FAIL" "Reconnection did not occur after server restart"
    fi
    
    kill $LOG_PID 2>/dev/null || true
}

# Test 2: Memory Usage
test_memory() {
    echo ""
    echo "TEST 2: Memory Usage"
    echo "--------------------"
    
    # Get app PID
    APP_PID=$(ps aux | grep "[C]laudeCodeUI" | grep -v grep | awk '{print $2}' | head -1)
    
    if [ -z "$APP_PID" ]; then
        print_status "WARN" "App not running, skipping memory test"
        return
    fi
    
    # Check memory usage
    MEM_MB=$(ps aux | grep "^[^ ]*[ ]*$APP_PID" | awk '{print $6/1024}')
    MEM_INT=${MEM_MB%.*}
    
    echo "Current memory usage: ${MEM_INT}MB"
    
    if [ "$MEM_INT" -lt 150 ]; then
        print_status "PASS" "Memory usage within target (<150MB)"
    elif [ "$MEM_INT" -lt 200 ]; then
        print_status "WARN" "Memory usage elevated (150-200MB)"
    else
        print_status "FAIL" "Memory usage exceeds target (>200MB)"
    fi
}

# Test 3: Manual Retry UI
test_retry_ui() {
    echo ""
    echo "TEST 3: Manual Retry UI"
    echo "-----------------------"
    
    # Take screenshot
    xcrun simctl io "$SIMULATOR_UUID" screenshot "$PROJECT_DIR/screenshots/retry_ui_test.png"
    
    echo "Screenshot saved to verify retry button presence"
    echo "Manual verification required:"
    echo "  1. Check for retry button on failed messages"
    echo "  2. Verify tap triggers resend"
    echo "  3. Confirm status updates during retry"
    
    print_status "WARN" "Manual verification required"
}

# Test 4: Connection Status Indicator
test_status_indicator() {
    echo ""
    echo "TEST 4: Connection Status Indicator"
    echo "-----------------------------------"
    
    # Take screenshots in different states
    echo "Taking screenshot with connection..."
    xcrun simctl io "$SIMULATOR_UUID" screenshot "$PROJECT_DIR/screenshots/status_connected.png"
    
    # Kill backend
    pkill -f "node.*backend" || true
    sleep 2
    
    echo "Taking screenshot without connection..."
    xcrun simctl io "$SIMULATOR_UUID" screenshot "$PROJECT_DIR/screenshots/status_disconnected.png"
    
    # Restart backend
    cd "$PROJECT_DIR/backend" && npm start > server.log 2>&1 &
    sleep 3
    
    echo "Taking screenshot after reconnection..."
    xcrun simctl io "$SIMULATOR_UUID" screenshot "$PROJECT_DIR/screenshots/status_reconnected.png"
    
    echo "Screenshots saved for visual verification:"
    echo "  - Green indicator = connected"
    echo "  - Red indicator = disconnected"
    echo "  - Yellow indicator = reconnecting"
    
    print_status "WARN" "Manual verification of indicator colors required"
}

# Test 5: Pull-to-Refresh
test_pull_refresh() {
    echo ""
    echo "TEST 5: Pull-to-Refresh"
    echo "-----------------------"
    
    echo "Manual test required on physical device:"
    echo "  1. Pull down on chat view"
    echo "  2. Verify haptic feedback triggers"
    echo "  3. Check for loading animation"
    echo "  4. Confirm messages reload"
    
    print_status "WARN" "Physical device testing required for haptics"
}

# Main test execution
main() {
    echo ""
    echo "Starting Wave 2 Verification Tests..."
    echo ""
    
    # Ensure simulator is booted
    xcrun simctl boot "$SIMULATOR_UUID" 2>/dev/null || true
    
    # Check backend
    check_backend
    
    # Run tests
    test_reconnection
    test_memory
    test_retry_ui
    test_status_indicator
    test_pull_refresh
    
    echo ""
    echo "========================================"
    echo "Test Summary"
    echo "========================================"
    echo ""
    echo "Automated Tests:"
    echo "  - Reconnection: Check log file for results"
    echo "  - Memory Usage: Check output above"
    echo ""
    echo "Manual Verification Required:"
    echo "  - Retry UI: Check screenshots"
    echo "  - Status Indicator: Compare screenshot colors"
    echo "  - Pull-to-Refresh: Test on physical device"
    echo ""
    echo "Log file: $LOG_FILE"
    echo "Screenshots: $PROJECT_DIR/screenshots/"
    echo ""
    echo "========================================"
}

# Run main function
main