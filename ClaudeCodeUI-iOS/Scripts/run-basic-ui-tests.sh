#!/bin/bash

# Basic UI Test Runner for ClaudeCodeUI iOS App
# Runs simple tests to verify basic functionality

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}        🧪 Basic UI Tests - ClaudeCode iOS                    ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="ClaudeCodeUI"
RESULTS_DIR="$PROJECT_DIR/BasicTestResults_$(date +%Y%m%d_%H%M%S)"

# Create results directory
mkdir -p "$RESULTS_DIR"

# Check backend
echo -e "${YELLOW}🔍 Checking backend status...${NC}"
if curl -s http://localhost:3004/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend is running on port 3004${NC}"
else
    echo -e "${YELLOW}⚠️  Backend not detected, tests may fail${NC}"
fi

# Generate project with Tuist
echo -e "${YELLOW}🔨 Generating project with Tuist...${NC}"
cd "$PROJECT_DIR"
tuist generate

# Run basic UI tests
echo -e "${YELLOW}🚀 Running basic UI tests...${NC}"
xcodebuild test \
    -workspace "$PROJECT_DIR/ClaudeCodeUI.xcworkspace" \
    -scheme "$SCHEME" \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    -only-testing:ClaudeCodeUIUITests/BasicFunctionalTests \
    -resultBundlePath "$RESULTS_DIR/BasicTests.xcresult" \
    2>&1 | tee "$RESULTS_DIR/test_output.log" | grep -E "Test Case|error:|warning:" || true

TEST_EXIT_CODE=${PIPESTATUS[0]}

# Summary
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ Basic UI tests completed successfully!${NC}"
else
    echo -e "${RED}❌ Some tests failed. Check logs for details.${NC}"
fi

echo -e "\n📁 Results: $RESULTS_DIR"
echo -e "📄 Logs: $RESULTS_DIR/test_output.log"
echo -e "📦 Bundle: $RESULTS_DIR/BasicTests.xcresult"

exit $TEST_EXIT_CODE