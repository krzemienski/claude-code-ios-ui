#!/usr/bin/env node

const WebSocket = require('ws');

console.log('🚀 WEBSOCKET CONNECTIVITY TEST');
console.log('=' + '='.repeat(59));
console.log(`Time: ${new Date().toISOString()}`);
console.log('=' + '='.repeat(59) + '\n');

const endpoints = [
    'ws://localhost:3004/ws',
    'ws://192.168.0.43:3004/ws'
];

let results = [];
let testsCompleted = 0;

function testEndpoint(url) {
    return new Promise((resolve) => {
        const startTime = Date.now();
        console.log(`Testing: ${url}`);
        
        const ws = new WebSocket(url, {
            handshakeTimeout: 5000
        });
        
        let connected = false;
        
        ws.on('open', () => {
            connected = true;
            const duration = Date.now() - startTime;
            console.log(`  ✅ Connected successfully (${duration}ms)`);
            
            // Test sending a message
            const testMessage = JSON.stringify({
                type: 'message',
                content: 'WebSocket test message',
                timestamp: new Date().toISOString()
            });
            
            ws.send(testMessage, (error) => {
                if (error) {
                    console.log(`  ❌ Send failed: ${error.message}`);
                } else {
                    console.log(`  ✅ Message sent successfully`);
                }
            });
            
            // Test receiving
            ws.on('message', (data) => {
                console.log(`  ✅ Received message: ${data.toString().substring(0, 50)}...`);
            });
            
            setTimeout(() => {
                ws.close();
                results.push({
                    url,
                    success: true,
                    duration,
                    status: 'Connected and tested'
                });
                resolve();
            }, 1000);
        });
        
        ws.on('error', (error) => {
            const duration = Date.now() - startTime;
            console.log(`  ❌ Connection failed: ${error.message}`);
            results.push({
                url,
                success: false,
                duration,
                status: error.message
            });
            if (!connected) resolve();
        });
        
        ws.on('close', () => {
            if (!connected) {
                const duration = Date.now() - startTime;
                results.push({
                    url,
                    success: false,
                    duration,
                    status: 'Connection closed before opening'
                });
                resolve();
            }
        });
        
        setTimeout(() => {
            if (!connected) {
                console.log(`  ❌ Connection timeout`);
                ws.terminate();
                results.push({
                    url,
                    success: false,
                    duration: 5000,
                    status: 'Timeout'
                });
                resolve();
            }
        }, 5000);
    });
}

async function runTests() {
    for (const endpoint of endpoints) {
        await testEndpoint(endpoint);
        console.log('');
    }
    
    // Summary
    console.log('=' + '='.repeat(59));
    console.log('📊 TEST RESULTS');
    console.log('=' + '='.repeat(59));
    
    const successful = results.filter(r => r.success).length;
    const failed = results.length - successful;
    
    console.log(`\n📈 SUMMARY:`);
    console.log(`  Total Endpoints: ${results.length}`);
    console.log(`  Successful: ${successful}`);
    console.log(`  Failed: ${failed}`);
    
    if (successful > 0) {
        console.log(`\n✅ CONNECTIVITY CONFIRMED`);
        console.log(`  At least one WebSocket endpoint is reachable`);
        
        // Performance metrics
        const successfulResults = results.filter(r => r.success);
        const avgLatency = successfulResults.reduce((sum, r) => sum + r.duration, 0) / successfulResults.length;
        console.log(`  Average connection time: ${avgLatency.toFixed(0)}ms`);
    } else {
        console.log(`\n🔴 CRITICAL: No WebSocket endpoints are reachable`);
        console.log(`  Check if backend server is running on port 3004`);
    }
    
    console.log('\n' + '=' + '='.repeat(59));
    console.log(`Test completed at: ${new Date().toISOString()}`);
    console.log('=' + '='.repeat(59));
}

runTests().catch(console.error);