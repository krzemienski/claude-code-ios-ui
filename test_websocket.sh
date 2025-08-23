#!/bin/bash

# WebSocket Connection Test Script
# This script builds the app, launches it, and monitors WebSocket logs

echo "🚀 WebSocket Connection Test Script"
echo "=================================="
echo ""

# Configuration
SIMULATOR_UUID="6520A438-0B1F-485B-9037-F346837B6D14"
PROJECT_PATH="/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj"
SCHEME="ClaudeCodeUI"
BUNDLE_ID="com.claudecode.ui"
LOG_FILE="websocket_test_$(date +%Y%m%d_%H%M%S).log"

echo "📱 Simulator UUID: $SIMULATOR_UUID"
echo "📂 Project: $PROJECT_PATH"
echo "📝 Log file: $LOG_FILE"
echo ""

# Check if backend is running
echo "🔍 Checking backend server..."
if curl -s http://192.168.0.43:3004/api/auth/status > /dev/null 2>&1; then
    echo "✅ Backend server is running"
else
    echo "❌ Backend server is NOT running!"
    echo "   Please start the backend with: cd backend && npm start"
    exit 1
fi
echo ""

# Boot simulator if needed
echo "📱 Booting simulator..."
xcrun simctl boot $SIMULATOR_UUID 2>/dev/null || echo "   Simulator already booted"
echo ""

# Build the app
echo "🔨 Building app..."
xcodebuild build \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=$SIMULATOR_UUID" \
    -derivedDataPath ./Build \
    -quiet

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi
echo "✅ Build successful"
echo ""

# Install the app
echo "📦 Installing app..."
APP_PATH="./Build/Build/Products/Debug-iphonesimulator/ClaudeCodeUI.app"
xcrun simctl install $SIMULATOR_UUID "$APP_PATH"
echo "✅ App installed"
echo ""

# Start log streaming in background
echo "📜 Starting log stream..."
xcrun simctl spawn $SIMULATOR_UUID log stream \
    --predicate 'processImagePath contains "ClaudeCodeUI"' \
    --level debug \
    > "$LOG_FILE" 2>&1 &
LOG_PID=$!
echo "   Log PID: $LOG_PID"
echo ""

# Launch the app
echo "🚀 Launching app..."
xcrun simctl launch $SIMULATOR_UUID $BUNDLE_ID
echo ""

# Monitor logs for WebSocket activity
echo "👀 Monitoring WebSocket logs (press Ctrl+C to stop)..."
echo "=================================="
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping log stream..."
    kill $LOG_PID 2>/dev/null
    echo ""
    echo "📊 WebSocket Log Summary:"
    echo "-------------------------"
    echo "Connection attempts: $(grep -c "🔌🔌🔌 WebSocketManager.connect()" "$LOG_FILE" 2>/dev/null || echo 0)"
    echo "Successful pings: $(grep -c "✅✅✅ WebSocket ping successful" "$LOG_FILE" 2>/dev/null || echo 0)"
    echo "Connection established: $(grep -c "🎉🎉🎉 WebSocket CONNECTED successfully" "$LOG_FILE" 2>/dev/null || echo 0)"
    echo "Messages sent: $(grep -c "✅✅✅ WebSocket message SENT successfully" "$LOG_FILE" 2>/dev/null || echo 0)"
    echo "Messages received: $(grep -c "📥📥📥" "$LOG_FILE" 2>/dev/null || echo 0)"
    echo "Errors: $(grep -c "❌❌❌" "$LOG_FILE" 2>/dev/null || echo 0)"
    echo ""
    echo "Full log saved to: $LOG_FILE"
    echo ""
    
    # Show last few error messages if any
    if grep -q "❌❌❌" "$LOG_FILE" 2>/dev/null; then
        echo "⚠️ Last errors found:"
        grep "❌❌❌" "$LOG_FILE" | tail -5
    fi
}

# Set up trap for cleanup on exit
trap cleanup EXIT

# Tail the log file with filtering for WebSocket messages
tail -f "$LOG_FILE" | grep -E "🔌|📤|📨|✅|❌|🎉|🚀|📥|🔄|📵|🔁|⚠️|🔑|🌐|📡|WebSocket"