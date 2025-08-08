const WebSocket = require('ws');

const ws = new WebSocket('ws://localhost:3004/ws');

ws.on('open', function open() {
  console.log('✅ WebSocket connected successfully');
  
  // Send a test message
  const testMessage = JSON.stringify({
    type: 'message',
    payload: {
      content: 'Test message from Node.js client',
      projectId: 'test-project',
      userId: 'test-user'
    }
  });
  
  console.log('📤 Sending:', testMessage);
  ws.send(testMessage);
  
  // Send ping
  setTimeout(() => {
    ws.send(JSON.stringify({ type: 'ping' }));
  }, 1000);
});

ws.on('message', function message(data) {
  console.log('📥 Received:', data.toString());
});

ws.on('error', function error(err) {
  console.error('❌ WebSocket error:', err.message);
});

ws.on('close', function close() {
  console.log('🔌 WebSocket disconnected');
});

// Close after 5 seconds
setTimeout(() => {
  ws.close();
  process.exit(0);
}, 5000);