#!/bin/bash

# Performance Monitoring Script for iOS App Testing
# This script monitors the app's performance during test execution

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🚀 Starting Performance Monitor for ClaudeCodeUI"

# Configuration
APP_NAME="ClaudeCodeUI"
SIMULATOR_ID=$(xcrun simctl list devices | grep "Booted" | head -1 | awk -F'[()]' '{print $2}')
RESULTS_DIR="TestResults_$(date +%Y%m%d_%H%M%S)"
PERFORMANCE_LOG="$RESULTS_DIR/performance.log"
MEMORY_LOG="$RESULTS_DIR/memory.log"
NETWORK_LOG="$RESULTS_DIR/network.log"

# Create results directory
mkdir -p "$RESULTS_DIR"

echo "📊 Monitoring Simulator: $SIMULATOR_ID"
echo "📁 Results will be saved to: $RESULTS_DIR"

# Function to get memory usage
get_memory_usage() {
    if [ -n "$SIMULATOR_ID" ]; then
        # Get memory usage from simulator
        xcrun simctl spawn "$SIMULATOR_ID" ps aux | grep "$APP_NAME" | awk '{print $4}' | head -1
    fi
}

# Function to monitor network activity
monitor_network() {
    echo "🌐 Starting network monitoring..."
    # Use tcpdump for network monitoring (requires sudo)
    if command -v tcpdump &> /dev/null; then
        sudo tcpdump -i any -n "port 8080 or port 443" -w "$RESULTS_DIR/network.pcap" &
        TCPDUMP_PID=$!
        echo "Network capture PID: $TCPDUMP_PID"
    fi
}

# Function to check for crashes
check_crashes() {
    CRASH_DIR="$HOME/Library/Logs/DiagnosticReports"
    CRASH_COUNT=$(ls -1 "$CRASH_DIR" 2>/dev/null | grep -c "$APP_NAME" || echo 0)
    echo "Crash count: $CRASH_COUNT"
}

# Function to analyze performance
analyze_performance() {
    echo -e "\n${GREEN}📊 Performance Analysis${NC}"
    echo "========================"
    
    # Memory analysis
    if [ -f "$MEMORY_LOG" ]; then
        echo -e "\n${YELLOW}Memory Usage:${NC}"
        awk '{sum+=$1; if(max<$1) max=$1} END {print "  Average: " sum/NR "MB\n  Peak: " max "MB"}' "$MEMORY_LOG"
    fi
    
    # Check for memory leaks
    echo -e "\n${YELLOW}Memory Leak Check:${NC}"
    if [ -n "$SIMULATOR_ID" ]; then
        xcrun simctl spawn "$SIMULATOR_ID" leaks "$APP_NAME" | grep -E "leaks|total leaked" || echo "  ✅ No leaks detected"
    fi
    
    # Network analysis
    if [ -f "$RESULTS_DIR/network.pcap" ]; then
        echo -e "\n${YELLOW}Network Activity:${NC}"
        tcpdump -r "$RESULTS_DIR/network.pcap" -nn 2>/dev/null | wc -l | awk '{print "  Total packets: " $1}'
    fi
    
    # Crash analysis
    echo -e "\n${YELLOW}Stability:${NC}"
    check_crashes
    if [ "$CRASH_COUNT" -eq 0 ]; then
        echo "  ✅ No crashes detected"
    else
        echo "  ❌ $CRASH_COUNT crashes detected"
    fi
}

# Function to monitor during tests
monitor_tests() {
    echo "🔍 Starting performance monitoring..."
    
    # Start monitoring loop
    MONITOR_RUNNING=true
    while $MONITOR_RUNNING; do
        # Get current memory usage
        MEM_USAGE=$(get_memory_usage)
        if [ -n "$MEM_USAGE" ]; then
            echo "$MEM_USAGE" >> "$MEMORY_LOG"
            echo "Memory: ${MEM_USAGE}% | $(date +%H:%M:%S)" >> "$PERFORMANCE_LOG"
        fi
        
        # Check if tests are still running
        if ! pgrep -f "xcodebuild.*test" > /dev/null; then
            echo "Tests completed or not running"
            MONITOR_RUNNING=false
        fi
        
        sleep 2
    done
}

# Function to generate HTML report
generate_report() {
    REPORT_FILE="$RESULTS_DIR/performance_report.html"
    
    cat > "$REPORT_FILE" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Performance Report - ClaudeCodeUI</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif; }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px; }
        .metric { background: white; border: 1px solid #e2e8f0; border-radius: 8px; padding: 20px; margin: 10px 0; }
        .metric h3 { margin-top: 0; color: #4a5568; }
        .pass { color: #48bb78; }
        .fail { color: #f56565; }
        .warning { color: #ed8936; }
        pre { background: #f7fafc; padding: 10px; border-radius: 4px; overflow-x: auto; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 Performance Report</h1>
            <p>ClaudeCodeUI iOS App - $(date)</p>
        </div>
        
        <div class="metric">
            <h3>📊 Memory Performance</h3>
            <pre>$(cat "$MEMORY_LOG" 2>/dev/null || echo "No memory data available")</pre>
        </div>
        
        <div class="metric">
            <h3>🌐 Network Performance</h3>
            <pre>$([ -f "$RESULTS_DIR/network.pcap" ] && echo "Network capture saved to network.pcap" || echo "No network data available")</pre>
        </div>
        
        <div class="metric">
            <h3>📱 Stability</h3>
            <p class="$([ "$CRASH_COUNT" -eq 0 ] && echo "pass" || echo "fail")">
                Crashes detected: $CRASH_COUNT
            </p>
        </div>
        
        <div class="metric">
            <h3>📝 Test Logs</h3>
            <pre>$(cat "$PERFORMANCE_LOG" 2>/dev/null || echo "No performance logs available")</pre>
        </div>
    </div>
</body>
</html>
EOF
    
    echo -e "${GREEN}✅ Report generated: $REPORT_FILE${NC}"
}

# Main execution
main() {
    # Start network monitoring (optional, requires sudo)
    # monitor_network
    
    # Monitor tests
    monitor_tests
    
    # Analyze results
    analyze_performance
    
    # Generate report
    generate_report
    
    echo -e "\n${GREEN}✅ Performance monitoring complete!${NC}"
    echo "Results saved to: $RESULTS_DIR"
    
    # Kill tcpdump if running
    if [ -n "$TCPDUMP_PID" ]; then
        sudo kill "$TCPDUMP_PID" 2>/dev/null || true
    fi
}

# Trap to ensure cleanup on exit
trap 'echo "Cleaning up..."; [ -n "$TCPDUMP_PID" ] && sudo kill "$TCPDUMP_PID" 2>/dev/null || true' EXIT

# Run main function
main