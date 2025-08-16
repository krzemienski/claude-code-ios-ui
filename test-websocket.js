#!/usr/bin/env node

// Test WebSocket real-time JSON streaming with real backend
const WebSocket = require('ws');

console.log('🚀 WEBSOCKET REAL-TIME JSON STREAMING TEST');
console.log('='.repeat(50));
console.log('Backend: http://localhost:3004');
console.log('WebSocket: ws://localhost:3004/ws');
console.log('='.repeat(50));

const ws = new WebSocket('ws://localhost:3004/ws');

ws.on('open', () => {
    console.log('\n✅ WebSocket connected successfully!');
    console.log('Sending test Claude command...\n');
    
    const testMessage = {
        type: 'claude-command',
        content: 'Say "Hello from iOS WebSocket Test" and explain what 2+2 equals in one sentence.',
        projectPath: '/Users/nick/Documents/claude-code-ios-ui',
        timestamp: new Date().toISOString()
    };
    
    console.log('📤 Sending:', JSON.stringify(testMessage, null, 2));
    ws.send(JSON.stringify(testMessage));
    
    // Set timeout to close after 10 seconds
    setTimeout(() => {
        console.log('\n⏱️ Test complete. Closing connection...');
        ws.close();
        process.exit(0);
    }, 10000);
});

ws.on('message', (data) => {
    try {
        const message = JSON.parse(data.toString());
        console.log('\n📥 Received message:');
        console.log('  Type:', message.type);
        
        if (message.content) {
            // For streaming messages, just show the content
            if (message.type === 'claude-output' || message.type === 'claude-response') {
                process.stdout.write(message.content);
            } else {
                console.log('  Content:', message.content.substring(0, 100) + '...');
            }
        }
        
        if (message.sessionId) {
            console.log('  Session ID:', message.sessionId);
        }
    } catch (e) {
        console.log('📥 Raw message:', data.toString());
    }
});

ws.on('error', (error) => {
    console.error('❌ WebSocket error:', error.message);
    process.exit(1);
});

ws.on('close', () => {
    console.log('\n🔌 WebSocket disconnected');
});
