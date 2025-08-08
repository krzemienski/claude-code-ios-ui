#!/usr/bin/env node

const WebSocket = require('ws');

console.log('Testing WebSocket connection to backend...');

const ws = new WebSocket('ws://localhost:3004/ws');

ws.on('open', function open() {
  console.log('✅ Connected to WebSocket server');
  
  // Send a test message
  const testMessage = {
    type: 'status',
    content: 'Test message from Node.js client',
    timestamp: new Date().toISOString()
  };
  
  ws.send(JSON.stringify(testMessage));
  console.log('📤 Sent test message:', testMessage);
});

ws.on('message', function message(data) {
  console.log('📨 Received:', data.toString());
  
  // Parse and display the message
  try {
    const msg = JSON.parse(data.toString());
    console.log('📊 Parsed message:', msg);
  } catch (e) {
    console.log('Raw message:', data.toString());
  }
});

ws.on('error', function error(err) {
  console.error('❌ WebSocket error:', err);
});

ws.on('close', function close() {
  console.log('🔌 Disconnected from WebSocket server');
});

// Send a chat message after 2 seconds
setTimeout(() => {
  const chatMessage = {
    type: 'session:message',
    payload: {
      projectId: 'test-project-123',
      content: 'Hello from test client!',
      sender: 'user'
    },
    timestamp: new Date().toISOString()
  };
  
  ws.send(JSON.stringify(chatMessage));
  console.log('💬 Sent chat message:', chatMessage);
}, 2000);

// Close connection after 5 seconds
setTimeout(() => {
  console.log('Closing connection...');
  ws.close();
  process.exit(0);
}, 5000);