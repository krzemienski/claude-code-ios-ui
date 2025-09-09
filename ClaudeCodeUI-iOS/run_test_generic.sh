#!/bin/bash

echo "🚀 Running Comprehensive UI Flow Test"
echo "======================================"

# Use generic iOS Simulator destination
xcodebuild test \
    -workspace ClaudeCodeUI.xcworkspace \
    -scheme ClaudeCodeUI \
    -destination 'platform=iOS Simulator,OS=latest' \
    -only-testing:ClaudeCodeUIUITests/ComprehensiveFlowTest/testCompleteUserFlow \
    2>&1 | while IFS= read -r line; do
        if echo "$line" | grep -qE "(Test Case|Executed|test|Pass|Fail)"; then
            echo "$line"
        elif echo "$line" | grep -qE "(🚀|⏳|📊|📱|🔄|🔍|✅|⚠️|📜|📸|❌)"; then
            echo "$line"
        elif echo "$line" | grep -qE "(Found|CollectionView|Table|project|Project|cell|Cell)"; then
            echo "$line"
        fi
    done

echo "✅ Test complete"
