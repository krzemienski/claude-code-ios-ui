#!/bin/bash

echo "🚀 Running Comprehensive UI Flow Test"
echo "======================================"

# 1. Check backend
echo "📡 Checking backend..."
if curl -s http://localhost:3004/api/projects > /dev/null 2>&1; then
    PROJECT_COUNT=$(curl -s http://localhost:3004/api/projects | python3 -c "import json,sys; print(json.load(sys.stdin)['count'])" 2>/dev/null || echo "0")
    echo "✅ Backend running with $PROJECT_COUNT projects"
    
    if [ "$PROJECT_COUNT" -eq "0" ]; then
        echo "⚠️ No projects found, creating test data..."
        curl -X POST http://localhost:3004/api/projects \
            -H "Content-Type: application/json" \
            -d '{"name": "Test Project 1", "description": "Test project for UI testing"}'
        curl -X POST http://localhost:3004/api/projects \
            -H "Content-Type: application/json" \
            -d '{"name": "Test Project 2", "description": "Another test project"}'
        echo "✅ Created test projects"
    fi
else
    echo "❌ Backend not running at localhost:3004"
    echo "Please start the backend first with: npm run dev (in backend directory)"
    exit 1
fi

# 2. Build the app
echo ""
echo "🔨 Building app..."
xcodebuild build-for-testing \
    -workspace ClaudeCodeUI.xcworkspace \
    -scheme ClaudeCodeUI \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' \
    -quiet || {
        echo "❌ Build failed"
        exit 1
    }
echo "✅ Build complete"

# 3. Run the test
echo ""
echo "🧪 Running UI test..."
xcodebuild test-without-building \
    -workspace ClaudeCodeUI.xcworkspace \
    -scheme ClaudeCodeUI \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' \
    -only-testing:ClaudeCodeUIUITests/ComprehensiveFlowTest/testCompleteUserFlow \
    2>&1 | while IFS= read -r line; do
        # Filter for important output
        if echo "$line" | grep -qE "(Test Case|Starting Complete|Found|Collection|Table|Empty|project|Project|Screenshot|passed|failed|Executed)"; then
            echo "$line"
        elif echo "$line" | grep -qE "(🚀|⏳|📊|📱|🔄|🔍|✅|⚠️|📜|📸|❌)"; then
            echo "$line"
        fi
    done

echo ""
echo "✅ Test execution complete"