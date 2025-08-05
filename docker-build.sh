#!/bin/bash

# Docker-based iOS build script for Claude Code UI
# This script builds the iOS app inside the macOS Docker container

PROJECT_PATH="/workspace/ClaudeCodeUI-iOS.xcodeproj"
SCHEME="ClaudeCodeUI"
DESTINATION="platform=iOS Simulator,name=iPhone 16 Pro Max"

echo "🔨 Building iOS app in Docker container..."

# Check if container is running
if ! docker ps | grep -q claude-code-ui-ios-dev; then
    echo "❌ Docker container is not running!"
    echo "Run: docker-compose up -d"
    exit 1
fi

# Build the project
docker exec claude-code-ui-ios-dev xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    build

if [ $? -eq 0 ]; then
    echo "✅ Build succeeded!"
else
    echo "❌ Build failed! Check errors above."
    exit 1
fi