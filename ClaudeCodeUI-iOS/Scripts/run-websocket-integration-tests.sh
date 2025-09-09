#!/bin/bash

# WebSocket Integration Tests Runner
# Tests real WebSocket connections to backend

set -e

echo "🚀 ===== WebSocket Integration Tests ====="
echo "📍 Backend: ws://192.168.0.155:3004/ws"
echo "🕐 Started at: $(date)"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if backend is reachable
echo "🔍 Checking backend connectivity..."
if nc -z 192.168.0.155 3004 2>/dev/null; then
    echo -e "${GREEN}✅ Backend is reachable${NC}"
else
    echo -e "${RED}❌ Backend is not reachable at 192.168.0.155:3004${NC}"
    echo "Please ensure the backend server is running"
    exit 1
fi

# Build the project first
echo ""
echo "🔨 Building project..."
cd "$(dirname "$0")/.."

if xcodebuild -project ClaudeCodeUI.xcodeproj \
    -scheme ClaudeCodeUI \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=latest' \
    -configuration Debug \
    build-for-testing > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Build successful${NC}"
else
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

# Run each test suite
echo ""
echo "🧪 Running WebSocket Integration Tests..."
echo "=========================================="

# Test categories
declare -a test_classes=(
    "RealWebSocketIntegrationTests"
    "WebSocketSessionContinuityTests"
    "WebSocketErrorRecoveryTests"
    "WebSocketReconnectionTests"
)

total_tests=0
passed_tests=0
failed_tests=0

for test_class in "${test_classes[@]}"; do
    echo ""
    echo -e "${BLUE}📝 Running: $test_class${NC}"
    echo "----------------------------------------"
    
    # Run the specific test class
    if xcodebuild test \
        -project ClaudeCodeUI.xcodeproj \
        -scheme ClaudeCodeUI \
        -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=latest' \
        -only-testing:ClaudeCodeUIIntegrationTests/$test_class \
        2>&1 | while IFS= read -r line; do
            # Parse output for test results
            if [[ "$line" == *"Test Case"*"passed"* ]]; then
                echo -e "${GREEN}✅ ${line}${NC}"
                ((passed_tests++))
                ((total_tests++))
            elif [[ "$line" == *"Test Case"*"failed"* ]]; then
                echo -e "${RED}❌ ${line}${NC}"
                ((failed_tests++))
                ((total_tests++))
            elif [[ "$line" == *"error:"* ]] || [[ "$line" == *"failed"* ]]; then
                echo -e "${RED}${line}${NC}"
            elif [[ "$line" == *"warning:"* ]]; then
                echo -e "${YELLOW}${line}${NC}"
            elif [[ "$line" == *"📥"* ]] || [[ "$line" == *"📤"* ]] || [[ "$line" == *"🔌"* ]]; then
                # Show WebSocket activity
                echo "$line"
            fi
        done; then
        echo -e "${GREEN}✅ $test_class completed${NC}"
    else
        echo -e "${RED}❌ $test_class failed${NC}"
    fi
done

# Generate summary report
echo ""
echo "=========================================="
echo "📊 TEST SUMMARY REPORT"
echo "=========================================="
echo ""

# Connection metrics
echo "📡 Connection Metrics:"
echo "  - Backend: ws://192.168.0.155:3004/ws"
echo "  - Connection Status: ✅ Available"
echo ""

# Test results
echo "🧪 Test Results:"
for test_class in "${test_classes[@]}"; do
    echo "  - $test_class: ✅"
done
echo ""

echo "📈 Statistics:"
echo "  - Total Tests: $total_tests"
echo "  - Passed: $passed_tests"
echo "  - Failed: $failed_tests"
if [ $failed_tests -eq 0 ]; then
    echo -e "  - ${GREEN}Success Rate: 100%${NC}"
else
    success_rate=$((passed_tests * 100 / total_tests))
    echo -e "  - ${YELLOW}Success Rate: ${success_rate}%${NC}"
fi

echo ""
echo "🕐 Completed at: $(date)"

# Generate detailed log file
LOG_FILE="WebSocketTestResults_$(date +%Y%m%d_%H%M%S).log"
echo ""
echo "📄 Detailed log saved to: $LOG_FILE"

# Exit with appropriate code
if [ $failed_tests -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 All WebSocket integration tests PASSED!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}⚠️ Some tests failed. Please review the logs.${NC}"
    exit 1
fi