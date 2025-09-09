#!/bin/bash

# Direct execution of simplified Phase 3 test

set -e

echo "=== Phase 3 Simplified Persistence Test ==="
echo "Date: $(date)"
echo

PROJECT_PATH="/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS"
OUTPUT_DIR="$PROJECT_PATH/output/20250909-122718_ios_e2e_claude"

cd "$PROJECT_PATH"

# First, let's just build the app without tests
echo "Building app..."
xcodebuild clean build \
    -scheme ClaudeCodeUI \
    -configuration Debug \
    -destination "platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6" \
    -derivedDataPath "$OUTPUT_DIR/DerivedData" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    2>&1 | grep -E "^(Building|Succeeded|Failed)" || true

echo
echo "Build complete. Now let's check if we can run the existing UI tests..."

# List available UI test classes
echo "Available UI test classes:"
find "$PROJECT_PATH/ClaudeCodeUIUITests" -name "*.swift" -type f | head -10

echo
echo "Attempting to run a simple existing test..."

# Try running just the basic ClaudeCodeUIUITests
xcodebuild test \
    -scheme ClaudeCodeUI \
    -destination "platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6" \
    -only-testing:ClaudeCodeUIUITests/ClaudeCodeUIUITests/testExample \
    2>&1 | tail -20

echo
echo "Test execution attempt complete."