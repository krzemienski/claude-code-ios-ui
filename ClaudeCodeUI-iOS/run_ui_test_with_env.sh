#!/bin/bash

echo "🚀 Running Comprehensive UI Flow Test with Environment Variables"
echo "======================================="

# 1. Check backend
echo "📡 Checking backend..."
BACKEND_RESPONSE=$(curl -s http://localhost:3004/api/projects 2>/dev/null)
if [ $? -eq 0 ]; then
    PROJECT_COUNT=$(echo "$BACKEND_RESPONSE" | python3 -c "import json,sys; data=json.load(sys.stdin); print(data.get('count', len(data)) if isinstance(data, dict) else len(data))" 2>/dev/null || echo "0")
    echo "✅ Backend running with $PROJECT_COUNT projects"
    
    if [ "$PROJECT_COUNT" -eq "0" ]; then
        echo "⚠️ No projects found, creating test data..."
        curl -X POST http://localhost:3004/api/projects \
            -H "Content-Type: application/json" \
            -d '{"name": "Test Project 1", "description": "Test project for UI testing"}' \
            -s > /dev/null
        curl -X POST http://localhost:3004/api/projects \
            -H "Content-Type: application/json" \
            -d '{"name": "Test Project 2", "description": "Another test project"}' \
            -s > /dev/null
        curl -X POST http://localhost:3004/api/projects \
            -H "Content-Type: application/json" \
            -d '{"name": "Test Project 3", "description": "Third test project"}' \
            -s > /dev/null
        echo "✅ Created 3 test projects"
    fi
else
    echo "❌ Backend not running at localhost:3004"
    echo "Please start the backend first with: npm run dev (in backend directory)"
    exit 1
fi

# 2. Clean build directory to ensure fresh build with environment variables
echo ""
echo "🧹 Cleaning build directory..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ClaudeCodeUI-*

# 3. Build the app WITH environment variables
echo ""
echo "🔨 Building app with environment variables..."

# Export environment variables so they're available during build
export BACKEND_URL="http://localhost:3004"
export TESTING_MODE="functional"
export ENABLE_LOGGING="true"
export DEBUG_UI="true"

xcodebuild build-for-testing \
    -workspace ClaudeCodeUI.xcworkspace \
    -scheme ClaudeCodeUI \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' \
    -configuration Debug \
    BACKEND_URL="http://localhost:3004" \
    TESTING_MODE="functional" \
    -quiet || {
        echo "❌ Build failed"
        exit 1
    }
echo "✅ Build complete"

# 4. Run the test WITH environment variables
echo ""
echo "🧪 Running UI test with environment variables..."
echo "   BACKEND_URL=http://localhost:3004"
echo "   TESTING_MODE=functional"
echo ""

# Run test with environment variables
BACKEND_URL="http://localhost:3004" \
TESTING_MODE="functional" \
ENABLE_LOGGING="true" \
DEBUG_UI="true" \
xcodebuild test-without-building \
    -workspace ClaudeCodeUI.xcworkspace \
    -scheme ClaudeCodeUI \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' \
    -only-testing:ClaudeCodeUIUITests/ComprehensiveFlowTest/testCompleteUserFlow \
    2>&1 | while IFS= read -r line; do
        # Filter for important output
        if echo "$line" | grep -qE "(Test Case|Starting Complete|Found|Collection|Table|Empty|project|Project|Screenshot|passed|failed|Executed|BACKEND_URL|AppConfig|Using|fetchProjects|Successfully)"; then
            echo "$line"
        elif echo "$line" | grep -qE "(🚀|⏳|📊|📱|🔄|🔍|✅|⚠️|📜|📸|❌|🔧)"; then
            echo "$line"
        fi
    done

echo ""
echo "✅ Test execution complete"