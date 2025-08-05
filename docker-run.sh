#!/bin/bash

# Docker-based iOS run script for Claude Code UI
# This script runs the iOS app in the simulator inside the Docker container

PROJECT_PATH="/workspace/ClaudeCodeUI-iOS.xcodeproj"
SCHEME="ClaudeCodeUI"
DESTINATION="platform=iOS Simulator,name=iPhone 16 Pro Max"

echo "📱 Running iOS app in Docker container..."

# Check if container is running
if ! docker ps | grep -q claude-code-ui-ios-dev; then
    echo "❌ Docker container is not running!"
    echo "Run: docker-compose up -d"
    exit 1
fi

# Run the project
docker exec claude-code-ui-ios-dev xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    run

if [ $? -eq 0 ]; then
    echo "✅ App is running!"
    echo "🖥️  View the simulator at: http://localhost:8006"
else
    echo "❌ Failed to run app! Check errors above."
    exit 1
fi