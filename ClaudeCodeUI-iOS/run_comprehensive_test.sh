#!/bin/bash

echo "🚀 Running Comprehensive UI Flow Test"
echo "======================================"

# Ensure backend is running
if ! curl -s http://localhost:3004/api/projects > /dev/null 2>&1; then
    echo "❌ Backend not responding at localhost:3004"
    echo "Please start the backend first"
    exit 1
fi

# Check projects exist
PROJECT_COUNT=$(curl -s http://localhost:3004/api/projects | python3 -c "import json,sys; print(json.load(sys.stdin)['count'])" 2>/dev/null || echo "0")
echo "✅ Backend has $PROJECT_COUNT projects"

if [ "$PROJECT_COUNT" -eq "0" ]; then
    echo "⚠️ No projects in backend, creating test data..."
    ./Scripts/create_test_projects.sh
fi

# Build and run the test
echo "📱 Building and running UI test..."

xcodebuild test \
    -workspace ClaudeCodeUI.xcworkspace \
    -scheme ClaudeCodeUI \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    -only-testing:ClaudeCodeUIUITests/ComprehensiveFlowTest/testCompleteUserFlow \
    -resultBundlePath ComprehensiveTestResults.xcresult \
    2>&1 | while IFS= read -r line; do
        if echo "$line" | grep -qE "(🚀|⏳|📊|📱|🔄|🔍|✅|⚠️|📜|📸|❌|Test Case|Executed|Passed|Failed)"; then
            echo "$line"
        elif echo "$line" | grep -qE "(Found|CollectionView|Table|project|Project|cell|Cell|Empty|empty)"; then
            echo "$line"
        elif echo "$line" | grep -qE "(TESTING_MODE|BACKEND_URL|localhost|AppConfig)"; then
            echo "$line"
        elif echo "$line" | grep -qiE "(error|fail|crash|exception)"; then
            echo "❌ $line"
        fi
    done

echo ""
echo "✅ Test execution complete"
