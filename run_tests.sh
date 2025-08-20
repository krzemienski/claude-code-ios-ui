#!/bin/bash

# Quick test runner for iOS Claude Code UI
# Usage: ./run_tests.sh [test-suite]

set -e

SIMULATOR_UUID="A707456B-44DB-472F-9722-C88153CDFFA1"
PROJECT_PATH="ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj"
SCHEME="ClaudeCodeUI"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_usage() {
    echo "Usage: $0 [test-suite]"
    echo ""
    echo "Test Suites:"
    echo "  ui         - Run UI features integration tests"
    echo "  websocket  - Run WebSocket reconnection tests"
    echo "  e2e        - Run session flow end-to-end tests"
    echo "  all        - Run all integration tests"
    echo "  unit       - Run unit tests only"
    echo "  perf       - Run performance tests"
    echo ""
    echo "Options:"
    echo "  --verbose  - Show detailed output"
    echo "  --no-build - Skip building (use existing build)"
}

# Parse arguments
TEST_SUITE=${1:-all}
VERBOSE=false
NO_BUILD=false

for arg in "$@"; do
    case $arg in
        --verbose)
            VERBOSE=true
            ;;
        --no-build)
            NO_BUILD=true
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
    esac
done

# Ensure backend is running
if ! curl -s -f "http://localhost:3004/api/health" > /dev/null 2>&1; then
    echo -e "${YELLOW}Warning: Backend server not running. Starting it now...${NC}"
    cd backend && npm start &
    BACKEND_PID=$!
    sleep 5
fi

# Boot simulator if needed
if ! xcrun simctl list devices | grep -q "$SIMULATOR_UUID.*Booted"; then
    echo "Booting simulator..."
    xcrun simctl boot $SIMULATOR_UUID
    sleep 3
fi

# Determine which tests to run
case $TEST_SUITE in
    ui)
        TEST_CLASS="ClaudeCodeUIIntegrationTests.UIFeaturesIntegrationTests"
        ;;
    websocket)
        TEST_CLASS="ClaudeCodeUIIntegrationTests.WebSocketReconnectionTests"
        ;;
    e2e)
        TEST_CLASS="ClaudeCodeUIIntegrationTests.SessionFlowE2ETests"
        ;;
    perf)
        TEST_CLASS="ClaudeCodeUIIntegrationTests.SessionFlowE2ETests/testSessionFlowPerformance"
        ;;
    unit)
        TEST_CLASS="ClaudeCodeUITests"
        ;;
    all)
        TEST_CLASS="ClaudeCodeUIIntegrationTests"
        ;;
    *)
        echo -e "${RED}Unknown test suite: $TEST_SUITE${NC}"
        print_usage
        exit 1
        ;;
esac

echo -e "${GREEN}Running $TEST_SUITE tests...${NC}"

# Build if needed
if [ "$NO_BUILD" = false ]; then
    echo "Building app..."
    if [ "$VERBOSE" = true ]; then
        xcodebuild build-for-testing \
            -project "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            -destination "platform=iOS Simulator,id=$SIMULATOR_UUID" \
            | xcpretty
    else
        xcodebuild build-for-testing \
            -project "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            -destination "platform=iOS Simulator,id=$SIMULATOR_UUID" \
            -quiet
    fi
fi

# Run tests
echo "Executing tests..."
if [ "$VERBOSE" = true ]; then
    xcodebuild test-without-building \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,id=$SIMULATOR_UUID" \
        -only-testing:"$TEST_CLASS" \
        | xcpretty --test --color
else
    xcodebuild test-without-building \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,id=$SIMULATOR_UUID" \
        -only-testing:"$TEST_CLASS" \
        -quiet \
        | grep -E "Test Suite|passed|failed"
fi

TEST_RESULT=$?

# Cleanup
if [ ! -z "$BACKEND_PID" ]; then
    echo "Stopping backend server..."
    kill $BACKEND_PID 2>/dev/null || true
fi

if [ $TEST_RESULT -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi