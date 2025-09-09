#!/bin/bash

# UI Test Runner Script for ClaudeCodeUI-iOS
# This script runs comprehensive UI tests with real UI interaction

set -e

echo "🚀 Starting UI Test Suite..."
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="ClaudeCodeUI"
DESTINATION="platform=iOS Simulator,name=iPhone 15 Pro,OS=18.0"
RESULT_BUNDLE="$PROJECT_DIR/UITestResults.xcresult"

# Clean previous results
if [ -d "$RESULT_BUNDLE" ]; then
    echo "🧹 Cleaning previous test results..."
    rm -rf "$RESULT_BUNDLE"
fi

# Start backend server if not running
check_backend() {
    if ! nc -z localhost 3004 2>/dev/null; then
        echo -e "${YELLOW}⚠️ Backend server not running on port 3004${NC}"
        echo "Starting backend server..."
        
        # Start backend in background
        cd "$PROJECT_DIR/backend" 2>/dev/null || {
            echo -e "${RED}❌ Backend directory not found${NC}"
            echo "Please ensure backend is running on http://localhost:3004"
            exit 1
        }
        
        npm start &
        BACKEND_PID=$!
        
        # Wait for backend to be ready
        echo "Waiting for backend to start..."
        for i in {1..30}; do
            if nc -z localhost 3004 2>/dev/null; then
                echo -e "${GREEN}✅ Backend is ready${NC}"
                break
            fi
            sleep 1
        done
    else
        echo -e "${GREEN}✅ Backend is already running${NC}"
    fi
}

# Function to run specific test class
run_test_class() {
    local test_class=$1
    local test_name=$2
    
    echo ""
    echo "🧪 Running $test_name..."
    echo "--------------------------------"
    
    xcodebuild test \
        -project "$PROJECT_DIR/ClaudeCodeUI.xcodeproj" \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -only-testing:"ClaudeCodeUIUITests/$test_class" \
        -resultBundlePath "$RESULT_BUNDLE-$test_class" \
        -quiet \
        2>&1 | while IFS= read -r line; do
            if [[ $line == *"Test Case"* ]]; then
                echo "$line"
            elif [[ $line == *"error:"* ]] || [[ $line == *"failed"* ]]; then
                echo -e "${RED}$line${NC}"
            elif [[ $line == *"passed"* ]]; then
                echo -e "${GREEN}$line${NC}"
            fi
        done
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $test_name passed${NC}"
        return 0
    else
        echo -e "${RED}❌ $test_name failed${NC}"
        return 1
    fi
}

# Check backend
check_backend

echo ""
echo "📱 Building app for testing..."
echo "--------------------------------"

# Build the app first
xcodebuild build-for-testing \
    -project "$PROJECT_DIR/ClaudeCodeUI.xcodeproj" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -quiet

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build successful${NC}"

# Run UI tests in sequence
FAILED_TESTS=()
PASSED_TESTS=()

# Test suite
declare -a TESTS=(
    "ProjectListTests:Project List Tests"
    "SessionNavigationTests:Session Navigation Tests"
    "MessageInteractionTests:Message Interaction Tests"
    "CompleteUIFlowTests:Complete UI Flow Tests"
)

echo ""
echo "🎯 Running UI Test Suite"
echo "================================"

for test_spec in "${TESTS[@]}"; do
    IFS=':' read -r test_class test_name <<< "$test_spec"
    
    if run_test_class "$test_class" "$test_name"; then
        PASSED_TESTS+=("$test_name")
    else
        FAILED_TESTS+=("$test_name")
    fi
done

# Summary
echo ""
echo "================================"
echo "📊 Test Results Summary"
echo "================================"

if [ ${#PASSED_TESTS[@]} -gt 0 ]; then
    echo -e "${GREEN}✅ Passed Tests (${#PASSED_TESTS[@]}):${NC}"
    for test in "${PASSED_TESTS[@]}"; do
        echo "   • $test"
    done
fi

if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}❌ Failed Tests (${#FAILED_TESTS[@]}):${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo "   • $test"
    done
fi

echo ""
echo "--------------------------------"
TOTAL_TESTS=$((${#PASSED_TESTS[@]} + ${#FAILED_TESTS[@]}))
echo "Total: ${#PASSED_TESTS[@]}/$TOTAL_TESTS tests passed"

# Generate screenshots report
echo ""
echo "📸 Screenshots saved to:"
for result in "$PROJECT_DIR"/UITestResults*.xcresult; do
    if [ -d "$result" ]; then
        echo "   • $result"
    fi
done

# Cleanup
if [ ! -z "$BACKEND_PID" ]; then
    echo ""
    echo "🛑 Stopping backend server..."
    kill $BACKEND_PID 2>/dev/null || true
fi

# Exit with appropriate code
if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}⚠️ Some tests failed. Please review the results.${NC}"
    exit 1
else
    echo ""
    echo -e "${GREEN}🎉 All UI tests passed successfully!${NC}"
    exit 0
fi