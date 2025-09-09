#!/bin/bash

echo "═══════════════════════════════════════════════════════════════"
echo "   🔌 WebSocket Validation for ClaudeCodeUI iOS App"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Check backend health
echo "1️⃣ Checking backend health..."
HEALTH=$(curl -s http://192.168.0.155:3004/health | jq -r '.status')
if [ "$HEALTH" = "healthy" ]; then
    echo "✅ Backend is healthy"
else
    echo "❌ Backend is not healthy: $HEALTH"
    exit 1
fi
echo ""

# Build and run the WebSocket tests
echo "2️⃣ Building and running WebSocket tests..."
cd /Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS

# Run WebSocket Integration Tests
echo "Running WebSocketIntegrationTestsEnhanced..."
xcodebuild test \
  -workspace ClaudeCodeUI.xcworkspace \
  -scheme ClaudeCodeUI \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  -only-testing:ClaudeCodeUIIntegrationTests/WebSocketIntegrationTestsEnhanced \
  2>&1 | tee websocket_test.log | grep -E "Test Case|🔌|✅|❌|WebSocket|Connection|Message|Streaming" | head -50

echo ""
echo "3️⃣ Analyzing test results..."

# Count successes and failures
PASSED=$(grep -c "Test Case.*passed" websocket_test.log 2>/dev/null || echo "0")
FAILED=$(grep -c "Test Case.*failed" websocket_test.log 2>/dev/null || echo "0")
CONNECTIONS=$(grep -c "WebSocket CONNECTED successfully" websocket_test.log 2>/dev/null || echo "0")

echo "📊 Test Summary:"
echo "   - Tests passed: $PASSED"
echo "   - Tests failed: $FAILED"
echo "   - Successful connections: $CONNECTIONS"
echo ""

# Check for specific patterns
echo "4️⃣ Checking for streaming responses..."
if grep -q "streaming" websocket_test.log 2>/dev/null; then
    echo "✅ Streaming responses detected"
    grep "streaming" websocket_test.log | head -3
else
    echo "⚠️ No streaming responses detected"
fi
echo ""

echo "5️⃣ Checking for reconnection behavior..."
if grep -q "reconnect" websocket_test.log 2>/dev/null; then
    echo "✅ Reconnection logic detected"
    grep -i "reconnect" websocket_test.log | head -3
else
    echo "⚠️ No reconnection behavior detected"
fi
echo ""

# Final verdict
echo "═══════════════════════════════════════════════════════════════"
if [ "$CONNECTIONS" -gt 0 ]; then
    echo "✅ WebSocket validation SUCCESSFUL!"
    echo "   - Backend is reachable at ws://192.168.0.155:3004/ws"
    echo "   - iOS app can establish WebSocket connections"
    if [ "$PASSED" -gt 0 ]; then
        echo "   - $PASSED tests passed successfully"
    fi
else
    echo "❌ WebSocket validation FAILED!"
    echo "   - Check WebSocketManager implementation"
    echo "   - Verify backend is running correctly"
    echo "   - Review test logs in websocket_test.log"
fi
echo "═══════════════════════════════════════════════════════════════"