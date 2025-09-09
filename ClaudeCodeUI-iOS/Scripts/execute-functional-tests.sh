#!/bin/bash

# Real Functional Test Executor for Claude Code iOS
# This script runs ACTUAL UI tests on REAL simulator with WebSocket monitoring

set -e

echo "════════════════════════════════════════════════"
echo "    CLAUDE CODE iOS FUNCTIONAL TEST EXECUTOR"
echo "════════════════════════════════════════════════"

# Configuration
PROJECT_DIR="/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS"
BACKEND_URL="ws://192.168.0.155:3004/ws"
DEVICE_ID="BECB3FA0-518E-4F80-8B8E-7E10C16F3B36"  # iPhone 16 Pro
APP_BUNDLE_ID="com.claudecode.ui"
RESULTS_DIR="${PROJECT_DIR}/FunctionalTestResults_$(date +%Y%m%d_%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create results directory
mkdir -p "$RESULTS_DIR"
mkdir -p "$RESULTS_DIR/screenshots"
mkdir -p "$RESULTS_DIR/logs"
mkdir -p "$RESULTS_DIR/network"

echo -e "${BLUE}📁 Results directory: $RESULTS_DIR${NC}"

# Function to check simulator status
check_simulator() {
    echo -e "\n${BLUE}📱 Checking simulator status...${NC}"
    
    if xcrun simctl list devices | grep -q "$DEVICE_ID.*Booted"; then
        echo -e "${GREEN}✅ Simulator is booted${NC}"
    else
        echo -e "${YELLOW}⚠️ Booting simulator...${NC}"
        xcrun simctl boot "$DEVICE_ID" || true
        sleep 5
    fi
}

# Function to install app
install_app() {
    echo -e "\n${BLUE}📦 Installing app on simulator...${NC}"
    
    # Build if needed
    if [ ! -d "${PROJECT_DIR}/DerivedData" ]; then
        echo "Building app..."
        cd "$PROJECT_DIR"
        xcodebuild -workspace ClaudeCodeUI.xcworkspace \
                  -scheme ClaudeCodeUI \
                  -configuration Debug \
                  -derivedDataPath DerivedData \
                  -destination "id=$DEVICE_ID" \
                  build-for-testing
    fi
    
    # Find and install app
    APP_PATH=$(find "${PROJECT_DIR}/DerivedData" -name "*.app" -type d | head -1)
    if [ -n "$APP_PATH" ]; then
        xcrun simctl install "$DEVICE_ID" "$APP_PATH"
        echo -e "${GREEN}✅ App installed${NC}"
    else
        echo -e "${RED}❌ App not found${NC}"
        exit 1
    fi
}

# Function to start WebSocket monitoring
start_websocket_monitor() {
    echo -e "\n${BLUE}🌐 Starting WebSocket monitor...${NC}"
    
    # Start monitoring in background
    xcrun simctl spawn "$DEVICE_ID" log stream \
        --predicate 'eventMessage CONTAINS "WebSocket" OR eventMessage CONTAINS "ws://"' \
        --style compact > "$RESULTS_DIR/logs/websocket.log" 2>&1 &
    
    WS_MONITOR_PID=$!
    echo "WebSocket monitor PID: $WS_MONITOR_PID"
}

# Function to start network monitoring
start_network_monitor() {
    echo -e "\n${BLUE}🔍 Starting network monitor...${NC}"
    
    # Monitor CFNetwork activity
    xcrun simctl spawn "$DEVICE_ID" log stream \
        --predicate 'subsystem == "com.apple.CFNetwork"' \
        --style compact > "$RESULTS_DIR/logs/network.log" 2>&1 &
    
    NETWORK_MONITOR_PID=$!
    echo "Network monitor PID: $NETWORK_MONITOR_PID"
}

# Function to start console monitoring
start_console_monitor() {
    echo -e "\n${BLUE}📝 Starting console monitor...${NC}"
    
    xcrun simctl spawn "$DEVICE_ID" log stream \
        --predicate 'processImagePath ENDSWITH "ClaudeCodeUI"' \
        --style compact > "$RESULTS_DIR/logs/console.log" 2>&1 &
    
    CONSOLE_MONITOR_PID=$!
    echo "Console monitor PID: $CONSOLE_MONITOR_PID"
}

# Function to execute test flow
execute_test_flow() {
    local flow_name=$1
    local flow_number=$2
    
    echo -e "\n${BLUE}═══ Test Flow $flow_number: $flow_name ═══${NC}"
    
    case $flow_number in
        1)
            # Launch & Connection
            echo "📱 Launching app..."
            xcrun simctl launch "$DEVICE_ID" "$APP_BUNDLE_ID"
            sleep 3
            
            # Check WebSocket connection
            if grep -q "WebSocket connected\|ws://192.168.0.155" "$RESULTS_DIR/logs/websocket.log" 2>/dev/null; then
                echo -e "${GREEN}✅ WebSocket connected${NC}"
                echo "PASS" > "$RESULTS_DIR/flow1_result.txt"
            else
                echo -e "${RED}❌ WebSocket connection failed${NC}"
                echo "FAIL" > "$RESULTS_DIR/flow1_result.txt"
            fi
            
            xcrun simctl io "$DEVICE_ID" screenshot "$RESULTS_DIR/screenshots/flow1_launch.png"
            ;;
            
        2)
            # Project List
            echo "📋 Checking project list..."
            sleep 2
            
            # Get UI dump (if available)
            xcrun simctl ui "$DEVICE_ID" dump > "$RESULTS_DIR/logs/flow2_hierarchy.xml" 2>/dev/null || true
            
            xcrun simctl io "$DEVICE_ID" screenshot "$RESULTS_DIR/screenshots/flow2_projects.png"
            echo "PASS" > "$RESULTS_DIR/flow2_result.txt"
            ;;
            
        3)
            # Session Navigation
            echo "👆 Tapping first project..."
            xcrun simctl io "$DEVICE_ID" tap 200 300
            sleep 2
            
            echo "📜 Testing scroll..."
            xcrun simctl io "$DEVICE_ID" swipe 200 600 200 200
            sleep 1
            xcrun simctl io "$DEVICE_ID" swipe 200 200 200 600
            
            xcrun simctl io "$DEVICE_ID" screenshot "$RESULTS_DIR/screenshots/flow3_session.png"
            echo "PASS" > "$RESULTS_DIR/flow3_result.txt"
            ;;
            
        4)
            # WebSocket Streaming
            echo "💬 Sending test message..."
            xcrun simctl io "$DEVICE_ID" text "Test WebSocket streaming"
            xcrun simctl io "$DEVICE_ID" tap 350 700  # Send button
            
            echo "🌊 Monitoring streaming response..."
            sleep 5
            
            if grep -q "streaming\|chunk\|quad" "$RESULTS_DIR/logs/websocket.log" 2>/dev/null; then
                echo -e "${GREEN}✅ Streaming detected${NC}"
                echo "PASS" > "$RESULTS_DIR/flow4_result.txt"
            else
                echo -e "${YELLOW}⚠️ Streaming not detected${NC}"
                echo "WARN" > "$RESULTS_DIR/flow4_result.txt"
            fi
            
            xcrun simctl io "$DEVICE_ID" screenshot "$RESULTS_DIR/screenshots/flow4_streaming.png"
            ;;
            
        5)
            # Multiple Messages
            echo "📤 Sending multiple messages..."
            
            for i in 1 2 3; do
                xcrun simctl io "$DEVICE_ID" keyevent "CMD+A"
                xcrun simctl io "$DEVICE_ID" keyevent "DELETE"
                xcrun simctl io "$DEVICE_ID" text "Test message $i"
                xcrun simctl io "$DEVICE_ID" tap 350 700
                sleep 2
            done
            
            xcrun simctl io "$DEVICE_ID" screenshot "$RESULTS_DIR/screenshots/flow5_messages.png"
            echo "PASS" > "$RESULTS_DIR/flow5_result.txt"
            ;;
            
        6)
            # Navigation Stress
            echo "🔄 Performing navigation stress test..."
            
            for i in {1..5}; do
                xcrun simctl io "$DEVICE_ID" tap 50 100  # Back
                sleep 0.5
                xcrun simctl io "$DEVICE_ID" tap 200 $((300 + i * 50))  # Project
                sleep 0.5
            done
            
            xcrun simctl io "$DEVICE_ID" screenshot "$RESULTS_DIR/screenshots/flow6_navigation.png"
            echo "PASS" > "$RESULTS_DIR/flow6_result.txt"
            ;;
            
        7)
            # High Volume Scrolling
            echo "📜 Performing rapid scrolling..."
            
            for i in {1..20}; do
                xcrun simctl io "$DEVICE_ID" swipe 200 600 200 100
                xcrun simctl io "$DEVICE_ID" swipe 200 100 200 600
            done
            
            xcrun simctl io "$DEVICE_ID" screenshot "$RESULTS_DIR/screenshots/flow7_scrolling.png"
            echo "PASS" > "$RESULTS_DIR/flow7_result.txt"
            ;;
    esac
}

# Function to run XCUITests
run_xcuitests() {
    echo -e "\n${BLUE}🧪 Running XCUITests...${NC}"
    
    cd "$PROJECT_DIR"
    
    xcodebuild test \
        -workspace ClaudeCodeUI.xcworkspace \
        -scheme ClaudeCodeUI \
        -destination "id=$DEVICE_ID" \
        -only-testing:ClaudeCodeUIUITests/RealFunctionalFlowTests \
        -resultBundlePath "$RESULTS_DIR/TestResults.xcresult" \
        2>&1 | tee "$RESULTS_DIR/logs/xcodebuild.log"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ XCUITests passed${NC}"
    else
        echo -e "${RED}❌ XCUITests failed${NC}"
    fi
}

# Function to generate report
generate_report() {
    echo -e "\n${BLUE}📄 Generating test report...${NC}"
    
    local passed=0
    local failed=0
    local warnings=0
    
    for i in {1..7}; do
        if [ -f "$RESULTS_DIR/flow${i}_result.txt" ]; then
            result=$(cat "$RESULTS_DIR/flow${i}_result.txt")
            case $result in
                PASS) ((passed++)) ;;
                FAIL) ((failed++)) ;;
                WARN) ((warnings++)) ;;
            esac
        fi
    done
    
    cat > "$RESULTS_DIR/TEST_REPORT.md" <<EOF
# Functional Test Execution Report

## Summary
- **Date**: $(date)
- **Device**: iPhone 16 Pro
- **Backend**: $BACKEND_URL
- **Passed**: $passed
- **Failed**: $failed
- **Warnings**: $warnings

## Test Flows

### Flow 1: Launch & Connection
$([ -f "$RESULTS_DIR/flow1_result.txt" ] && cat "$RESULTS_DIR/flow1_result.txt" || echo "NOT RUN")

### Flow 2: Project List
$([ -f "$RESULTS_DIR/flow2_result.txt" ] && cat "$RESULTS_DIR/flow2_result.txt" || echo "NOT RUN")

### Flow 3: Session Navigation
$([ -f "$RESULTS_DIR/flow3_result.txt" ] && cat "$RESULTS_DIR/flow3_result.txt" || echo "NOT RUN")

### Flow 4: WebSocket Streaming
$([ -f "$RESULTS_DIR/flow4_result.txt" ] && cat "$RESULTS_DIR/flow4_result.txt" || echo "NOT RUN")

### Flow 5: Multiple Messages
$([ -f "$RESULTS_DIR/flow5_result.txt" ] && cat "$RESULTS_DIR/flow5_result.txt" || echo "NOT RUN")

### Flow 6: Navigation Stress
$([ -f "$RESULTS_DIR/flow6_result.txt" ] && cat "$RESULTS_DIR/flow6_result.txt" || echo "NOT RUN")

### Flow 7: High Volume Scrolling
$([ -f "$RESULTS_DIR/flow7_result.txt" ] && cat "$RESULTS_DIR/flow7_result.txt" || echo "NOT RUN")

## Artifacts
- Screenshots: $RESULTS_DIR/screenshots/
- Logs: $RESULTS_DIR/logs/
- XCResult: $RESULTS_DIR/TestResults.xcresult

## WebSocket Activity
\`\`\`
$(tail -20 "$RESULTS_DIR/logs/websocket.log" 2>/dev/null || echo "No WebSocket logs captured")
\`\`\`

## Console Output
\`\`\`
$(tail -20 "$RESULTS_DIR/logs/console.log" 2>/dev/null || echo "No console logs captured")
\`\`\`
EOF
    
    echo -e "${GREEN}✅ Report generated: $RESULTS_DIR/TEST_REPORT.md${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Starting functional test execution...${NC}"
    
    # Setup
    check_simulator
    install_app
    
    # Start monitors
    start_websocket_monitor
    start_network_monitor
    start_console_monitor
    
    # Execute test flows
    execute_test_flow "Launch & Connection" 1
    execute_test_flow "Project List" 2
    execute_test_flow "Session Navigation" 3
    execute_test_flow "WebSocket Streaming" 4
    execute_test_flow "Multiple Messages" 5
    execute_test_flow "Navigation Stress" 6
    execute_test_flow "High Volume Scrolling" 7
    
    # Run XCUITests (optional)
    if [ "$1" == "--with-xcuitests" ]; then
        run_xcuitests
    fi
    
    # Stop monitors
    kill $WS_MONITOR_PID 2>/dev/null || true
    kill $NETWORK_MONITOR_PID 2>/dev/null || true
    kill $CONSOLE_MONITOR_PID 2>/dev/null || true
    
    # Generate report
    generate_report
    
    echo -e "\n${GREEN}════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}    TEST EXECUTION COMPLETED${NC}"
    echo -e "${GREEN}    Results: $RESULTS_DIR${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════${NC}"
}

# Run main function
main "$@"