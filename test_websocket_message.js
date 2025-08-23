#!/usr/bin/env node

const WebSocket = require('ws');

// Connect to the backend WebSocket
const ws = new WebSocket('ws://192.168.0.43:3004/ws');

ws.on('open', () => {
    console.log('✅ Connected to WebSocket');
    
    // Send a test message with the CORRECT format
    const message = {
        type: 'claude-command',
        content: 'Test message from iOS fix verification',  // This is the fixed field
        projectPath: '/Users/nick/test-project',
        sessionId: 'test-session-123'
    };
    
    console.log('📤 Sending message:', JSON.stringify(message, null, 2));
    ws.send(JSON.stringify(message));
});

ws.on('message', (data) => {
    console.log('📥 Received:', data.toString());
    const parsed = JSON.parse(data.toString());
    console.log('Parsed message:', parsed);
});

ws.on('error', (err) => {
    console.error('❌ WebSocket error:', err);
});

ws.on('close', () => {
    console.log('🔌 WebSocket closed');
});

// Keep the script running for 10 seconds
setTimeout(() => {
    console.log('⏰ Test complete, closing connection');
    ws.close();
    process.exit(0);
}, 10000);