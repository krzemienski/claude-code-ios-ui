#!/bin/bash

# Quick Performance Check for ClaudeCodeUI iOS App
# Run this to get immediate performance feedback

set -e

echo "🚀 Quick Performance Check"
echo "========================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if simulator is running
SIMULATOR_ID=$(xcrun simctl list devices | grep "Booted" | head -1 | awk -F'[()]' '{print $2}')

if [ -z "$SIMULATOR_ID" ]; then
    echo -e "${YELLOW}No simulator running. Starting iPhone 16 Pro...${NC}"
    xcrun simctl boot "iPhone 16 Pro"
    SIMULATOR_ID=$(xcrun simctl list devices | grep "iPhone 16 Pro" | head -1 | awk -F'[()]' '{print $2}')
    sleep 3
fi

echo "📱 Using Simulator: $SIMULATOR_ID"

# Function to get app PID
get_app_pid() {
    xcrun simctl spawn "$SIMULATOR_ID" ps aux | grep "ClaudeCodeUI" | grep -v grep | awk '{print $2}' | head -1
}

# Function to check memory
check_memory() {
    local PID=$(get_app_pid)
    if [ -n "$PID" ]; then
        xcrun simctl spawn "$SIMULATOR_ID" ps aux | grep "$PID" | awk '{printf "Memory: %.1f MB\n", $6/1024}'
    else
        echo "App not running"
    fi
}

# Function to check for memory leaks
check_leaks() {
    local PID=$(get_app_pid)
    if [ -n "$PID" ]; then
        echo "Checking for memory leaks..."
        xcrun simctl spawn "$SIMULATOR_ID" leaks "$PID" 2>/dev/null | grep -E "leaks|total leaked" || echo "✅ No leaks detected"
    else
        echo "App not running"
    fi
}

# Function to monitor network
monitor_network() {
    echo "🌐 Monitoring WebSocket connections..."
    xcrun simctl spawn "$SIMULATOR_ID" netstat -an | grep -E "8080|ws" | head -5
}

# Function to check crashes
check_crashes() {
    local CRASH_DIR="$HOME/Library/Logs/DiagnosticReports"
    local TODAY=$(date +%Y-%m-%d)
    local CRASHES=$(ls -la "$CRASH_DIR" 2>/dev/null | grep "ClaudeCodeUI" | grep "$TODAY" | wc -l | tr -d ' ')
    
    if [ "$CRASHES" -eq 0 ]; then
        echo -e "${GREEN}✅ No crashes today${NC}"
    else
        echo -e "${RED}❌ $CRASHES crashes detected today${NC}"
    fi
}

# Function to run performance metrics
performance_metrics() {
    echo -e "\n📊 Performance Metrics"
    echo "====================="
    
    # Memory check
    echo -e "\n${YELLOW}Memory Usage:${NC}"
    check_memory
    
    # CPU check
    echo -e "\n${YELLOW}CPU Usage:${NC}"
    local PID=$(get_app_pid)
    if [ -n "$PID" ]; then
        xcrun simctl spawn "$SIMULATOR_ID" top -pid "$PID" -l 1 | grep "$PID" | awk '{print "CPU: " $3 "%"}'
    else
        echo "App not running"
    fi
    
    # Leak check
    echo -e "\n${YELLOW}Memory Leaks:${NC}"
    check_leaks
    
    # Network check
    echo -e "\n${YELLOW}Network Status:${NC}"
    monitor_network
    
    # Crash check
    echo -e "\n${YELLOW}Stability:${NC}"
    check_crashes
}

# Function to test WebSocket performance
test_websocket() {
    echo -e "\n🔌 Testing WebSocket Performance"
    echo "================================"
    
    # Test connection
    echo "Testing connection to backend..."
    START=$(date +%s%N)
    curl -s http://localhost:8080/health > /dev/null
    END=$(date +%s%N)
    LATENCY=$(( (END - START) / 1000000 ))
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Backend responsive (${LATENCY}ms)${NC}"
    else
        echo -e "${RED}❌ Backend not responding${NC}"
    fi
    
    # Test WebSocket echo
    echo "Testing WebSocket echo..."
    (echo "test"; sleep 1) | websocat ws://localhost:8080/ws 2>/dev/null | head -1 && echo -e "${GREEN}✅ WebSocket working${NC}" || echo -e "${YELLOW}⚠️ WebSocket test inconclusive${NC}"
}

# Function to generate summary
generate_summary() {
    echo -e "\n📋 Performance Summary"
    echo "===================="
    
    local STATUS="PASS"
    local ISSUES=""
    
    # Check memory
    local MEM=$(check_memory | grep -oE '[0-9]+\.[0-9]+' | head -1)
    if [ -n "$MEM" ] && (( $(echo "$MEM > 100" | bc -l) )); then
        STATUS="FAIL"
        ISSUES="${ISSUES}\n  - High memory usage: ${MEM} MB"
    fi
    
    # Check crashes
    local CRASH_COUNT=$(ls -la "$HOME/Library/Logs/DiagnosticReports" 2>/dev/null | grep "ClaudeCodeUI" | grep "$(date +%Y-%m-%d)" | wc -l | tr -d ' ')
    if [ "$CRASH_COUNT" -gt 0 ]; then
        STATUS="FAIL"
        ISSUES="${ISSUES}\n  - Crashes detected: $CRASH_COUNT"
    fi
    
    # Check backend
    if ! curl -s http://localhost:8080/health > /dev/null 2>&1; then
        STATUS="WARNING"
        ISSUES="${ISSUES}\n  - Backend not available"
    fi
    
    # Print summary
    if [ "$STATUS" = "PASS" ]; then
        echo -e "${GREEN}✅ PERFORMANCE CHECK PASSED${NC}"
        echo "All metrics within acceptable ranges"
    elif [ "$STATUS" = "WARNING" ]; then
        echo -e "${YELLOW}⚠️ PERFORMANCE CHECK WARNING${NC}"
        echo -e "Issues found:${ISSUES}"
    else
        echo -e "${RED}❌ PERFORMANCE CHECK FAILED${NC}"
        echo -e "Critical issues found:${ISSUES}"
    fi
}

# Main execution
main() {
    # Run all checks
    performance_metrics
    test_websocket
    generate_summary
    
    echo -e "\n✨ Quick check complete!"
    echo "For detailed analysis, run: ./Scripts/run-performance-tests.sh"
}

# Run main
main