#!/bin/bash

# Run Master Test Suite for ClaudeCodeUI iOS
# This script runs the MasterTestRunner for comprehensive integration testing

echo "═══════════════════════════════════════════════════════════════════"
echo "🧪 Claude Code UI iOS - Master Test Runner"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

# Check if xcodebuild is available
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: xcodebuild not found. Please install Xcode."
    exit 1
fi

# Navigate to project directory
cd "$(dirname "$0")/.." || exit 1

echo "📁 Working directory: $(pwd)"
echo ""

# List available schemes
echo "📋 Available schemes:"
xcodebuild -workspace ClaudeCodeUI.xcworkspace -list 2>/dev/null | grep -A 100 "Schemes:" | tail -n +2 | head -5
echo ""

# Build the test target
echo "🔨 Building test target..."
xcodebuild build-for-testing \
    -workspace ClaudeCodeUI.xcworkspace \
    -scheme ClaudeCodeUITests \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' \
    -quiet \
    COMPILER_INDEX_STORE_ENABLE=NO 2>&1 | grep -E "(Succeeded|Failed|error:)"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ Build failed. Please fix compilation errors first."
    exit 1
fi

echo "✅ Build succeeded"
echo ""

# Run the tests
echo "🚀 Running MasterTestRunner..."
echo "═══════════════════════════════════════════════════════════════════"

xcodebuild test \
    -workspace ClaudeCodeUI.xcworkspace \
    -scheme ClaudeCodeUITests \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' \
    -quiet \
    2>&1 | grep -E "(Test Suite|Test Case|passed|failed|executed|🧪|✅|❌|🚀|📊|⚡|🎯|🏁)"

TEST_RESULT=${PIPESTATUS[0]}

echo ""
echo "═══════════════════════════════════════════════════════════════════"

if [ $TEST_RESULT -eq 0 ]; then
    echo "✅ All tests passed successfully!"
else
    echo "❌ Some tests failed. Please review the output above."
fi

echo "═══════════════════════════════════════════════════════════════════"
echo ""

exit $TEST_RESULT