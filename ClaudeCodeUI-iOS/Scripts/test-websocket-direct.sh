#!/bin/bash

# Test WebSocket connection directly
echo "🔌 Testing WebSocket connection to backend..."
echo "Backend URL: ws://192.168.0.155:3004/ws"
echo ""

# First test HTTP health endpoint
echo "1️⃣ Testing HTTP health endpoint..."
curl -s http://192.168.0.155:3004/health | jq '.' || echo "Health check failed"
echo ""

# Test WebSocket with websocat if available
if command -v websocat &> /dev/null; then
    echo "2️⃣ Testing WebSocket with websocat..."
    echo '{"type":"ping"}' | timeout 5 websocat ws://192.168.0.155:3004/ws 2>&1 | head -5
else
    echo "⚠️ websocat not installed, using Node.js for WebSocket test..."
    
    # Create a simple Node.js WebSocket test
    cat > /tmp/test-ws.js << 'EOF'
const WebSocket = require('ws');

const ws = new WebSocket('ws://192.168.0.155:3004/ws');

ws.on('open', function open() {
    console.log('✅ WebSocket connected successfully!');
    console.log('📤 Sending test message...');
    ws.send(JSON.stringify({
        type: 'message',
        content: 'Test from iOS WebSocket validation'
    }));
});

ws.on('message', function message(data) {
    console.log('📥 Received:', data.toString().substring(0, 200));
    if (data.toString().length > 200) {
        console.log('   ... (truncated)');
    }
});

ws.on('error', function error(err) {
    console.error('❌ WebSocket error:', err.message);
    process.exit(1);
});

setTimeout(() => {
    console.log('⏱️ Closing connection after 3 seconds...');
    ws.close();
    process.exit(0);
}, 3000);
EOF

    # Run the Node.js test
    if command -v node &> /dev/null; then
        echo "2️⃣ Testing WebSocket with Node.js..."
        cd /tmp && npm list ws &>/dev/null || npm install ws &>/dev/null
        node /tmp/test-ws.js
    else
        echo "❌ Neither websocat nor Node.js available for WebSocket testing"
    fi
fi

echo ""
echo "3️⃣ Checking simulator logs for WebSocket activity..."
xcrun simctl spawn booted log stream --predicate 'subsystem contains "WebSocket"' --style compact &
LOG_PID=$!
sleep 2
kill $LOG_PID 2>/dev/null

echo ""
echo "✅ WebSocket validation complete!"