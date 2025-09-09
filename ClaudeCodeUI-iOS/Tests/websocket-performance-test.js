#!/usr/bin/env node

const WebSocket = require('ws');
const { performance } = require('perf_hooks');

console.log('🚀 WEBSOCKET PERFORMANCE & STREAMING TEST');
console.log('=' + '='.repeat(59));
console.log(`Time: ${new Date().toISOString()}`);
console.log('=' + '='.repeat(59) + '\n');

const WS_URL = 'ws://localhost:3004/ws';

class PerformanceTester {
    constructor() {
        this.metrics = {
            connectionTime: 0,
            messageLatencies: [],
            throughput: {
                sent: 0,
                received: 0,
                startTime: 0,
                endTime: 0
            },
            streamingMetrics: {
                chunks: 0,
                totalSize: 0,
                startTime: 0,
                endTime: 0
            },
            memoryUsage: {
                initial: process.memoryUsage(),
                peak: process.memoryUsage(),
                final: null
            }
        };
    }

    async runAllTests() {
        console.log('📊 Starting Performance Tests...\n');
        
        await this.testConnectionLatency();
        await this.testMessageLatency();
        await this.testThroughput();
        await this.testStreaming();
        await this.testReconnection();
        
        this.generateReport();
    }

    testConnectionLatency() {
        return new Promise((resolve) => {
            console.log('1️⃣ CONNECTION LATENCY TEST');
            const startTime = performance.now();
            
            const ws = new WebSocket(WS_URL);
            
            ws.on('open', () => {
                this.metrics.connectionTime = performance.now() - startTime;
                console.log(`  ✅ Connection established in ${this.metrics.connectionTime.toFixed(2)}ms`);
                ws.close();
                resolve();
            });
            
            ws.on('error', (error) => {
                console.log(`  ❌ Connection failed: ${error.message}`);
                resolve();
            });
        });
    }

    testMessageLatency() {
        return new Promise((resolve) => {
            console.log('\n2️⃣ MESSAGE LATENCY TEST (10 messages)');
            const ws = new WebSocket(WS_URL);
            let messageCount = 0;
            const targetMessages = 10;
            
            ws.on('open', () => {
                for (let i = 0; i < targetMessages; i++) {
                    const startTime = performance.now();
                    const message = JSON.stringify({
                        type: 'latency-test',
                        id: i,
                        timestamp: Date.now(),
                        content: `Test message ${i}`
                    });
                    
                    ws.send(message, () => {
                        const latency = performance.now() - startTime;
                        this.metrics.messageLatencies.push(latency);
                        messageCount++;
                        
                        if (messageCount === targetMessages) {
                            const avg = this.metrics.messageLatencies.reduce((a, b) => a + b, 0) / targetMessages;
                            const min = Math.min(...this.metrics.messageLatencies);
                            const max = Math.max(...this.metrics.messageLatencies);
                            
                            console.log(`  ✅ Average latency: ${avg.toFixed(2)}ms`);
                            console.log(`  📊 Min: ${min.toFixed(2)}ms, Max: ${max.toFixed(2)}ms`);
                            ws.close();
                            resolve();
                        }
                    });
                }
            });
            
            ws.on('error', () => {
                console.log(`  ❌ Test failed`);
                resolve();
            });
        });
    }

    testThroughput() {
        return new Promise((resolve) => {
            console.log('\n3️⃣ THROUGHPUT TEST (100 messages in 1 second)');
            const ws = new WebSocket(WS_URL);
            const messageCount = 100;
            let sentCount = 0;
            let receivedCount = 0;
            
            ws.on('open', () => {
                this.metrics.throughput.startTime = performance.now();
                
                // Send messages rapidly
                const interval = setInterval(() => {
                    if (sentCount < messageCount) {
                        const message = JSON.stringify({
                            type: 'throughput-test',
                            id: sentCount,
                            timestamp: Date.now(),
                            payload: 'x'.repeat(1024) // 1KB payload
                        });
                        
                        ws.send(message);
                        sentCount++;
                        this.metrics.throughput.sent++;
                    } else {
                        clearInterval(interval);
                        this.metrics.throughput.endTime = performance.now();
                        
                        const duration = (this.metrics.throughput.endTime - this.metrics.throughput.startTime) / 1000;
                        const throughput = sentCount / duration;
                        
                        console.log(`  ✅ Sent ${sentCount} messages in ${duration.toFixed(2)}s`);
                        console.log(`  📊 Throughput: ${throughput.toFixed(0)} messages/second`);
                        console.log(`  📊 Data rate: ${(throughput * 1024 / 1024).toFixed(2)} MB/s`);
                        
                        setTimeout(() => {
                            ws.close();
                            resolve();
                        }, 500);
                    }
                }, 10); // Send every 10ms
            });
            
            ws.on('message', () => {
                receivedCount++;
                this.metrics.throughput.received++;
            });
            
            ws.on('error', () => {
                console.log(`  ❌ Test failed`);
                resolve();
            });
        });
    }

    testStreaming() {
        return new Promise((resolve) => {
            console.log('\n4️⃣ STREAMING TEST (Large message chunking)');
            const ws = new WebSocket(WS_URL);
            
            ws.on('open', () => {
                this.metrics.streamingMetrics.startTime = performance.now();
                
                // Simulate streaming by sending a large message in chunks
                const totalChunks = 20;
                const chunkSize = 5 * 1024; // 5KB per chunk
                let chunksSent = 0;
                
                const sendChunk = () => {
                    if (chunksSent < totalChunks) {
                        const chunk = {
                            type: 'stream-chunk',
                            chunkId: chunksSent,
                            totalChunks: totalChunks,
                            data: 'x'.repeat(chunkSize),
                            isLast: chunksSent === totalChunks - 1
                        };
                        
                        ws.send(JSON.stringify(chunk));
                        this.metrics.streamingMetrics.chunks++;
                        this.metrics.streamingMetrics.totalSize += chunkSize;
                        chunksSent++;
                        
                        // Send next chunk after a small delay to simulate streaming
                        setTimeout(sendChunk, 50);
                    } else {
                        this.metrics.streamingMetrics.endTime = performance.now();
                        const duration = (this.metrics.streamingMetrics.endTime - this.metrics.streamingMetrics.startTime) / 1000;
                        const dataRate = (this.metrics.streamingMetrics.totalSize / 1024) / duration;
                        
                        console.log(`  ✅ Streamed ${totalChunks} chunks (${(this.metrics.streamingMetrics.totalSize / 1024).toFixed(0)}KB)`);
                        console.log(`  📊 Duration: ${duration.toFixed(2)}s`);
                        console.log(`  📊 Stream rate: ${dataRate.toFixed(0)} KB/s`);
                        
                        ws.close();
                        resolve();
                    }
                };
                
                sendChunk();
            });
            
            ws.on('error', () => {
                console.log(`  ❌ Test failed`);
                resolve();
            });
        });
    }

    testReconnection() {
        return new Promise((resolve) => {
            console.log('\n5️⃣ RECONNECTION TEST');
            let reconnectAttempts = 0;
            const maxAttempts = 3;
            
            const attemptConnection = () => {
                reconnectAttempts++;
                const startTime = performance.now();
                const ws = new WebSocket(WS_URL);
                
                ws.on('open', () => {
                    const reconnectTime = performance.now() - startTime;
                    console.log(`  ✅ Reconnection attempt ${reconnectAttempts} succeeded in ${reconnectTime.toFixed(2)}ms`);
                    
                    // Intentionally close to simulate disconnect
                    setTimeout(() => {
                        ws.close();
                        
                        if (reconnectAttempts < maxAttempts) {
                            // Wait with exponential backoff
                            const backoffDelay = Math.min(1000 * Math.pow(2, reconnectAttempts - 1), 4000);
                            console.log(`  ⏳ Waiting ${backoffDelay}ms before next attempt...`);
                            setTimeout(attemptConnection, backoffDelay);
                        } else {
                            console.log(`  ✅ All ${maxAttempts} reconnection attempts successful`);
                            resolve();
                        }
                    }, 100);
                });
                
                ws.on('error', () => {
                    console.log(`  ❌ Reconnection attempt ${reconnectAttempts} failed`);
                    if (reconnectAttempts < maxAttempts) {
                        setTimeout(attemptConnection, 1000);
                    } else {
                        resolve();
                    }
                });
            };
            
            attemptConnection();
        });
    }

    generateReport() {
        this.metrics.memoryUsage.final = process.memoryUsage();
        const memoryDelta = (this.metrics.memoryUsage.final.heapUsed - this.metrics.memoryUsage.initial.heapUsed) / 1024 / 1024;
        
        console.log('\n' + '=' + '='.repeat(59));
        console.log('📊 PERFORMANCE TEST RESULTS');
        console.log('=' + '='.repeat(59));
        
        console.log('\n🎯 KEY METRICS:');
        console.log(`  Connection Time: ${this.metrics.connectionTime.toFixed(2)}ms`);
        
        if (this.metrics.messageLatencies.length > 0) {
            const avgLatency = this.metrics.messageLatencies.reduce((a, b) => a + b, 0) / this.metrics.messageLatencies.length;
            console.log(`  Average Message Latency: ${avgLatency.toFixed(2)}ms`);
        }
        
        if (this.metrics.throughput.sent > 0) {
            const duration = (this.metrics.throughput.endTime - this.metrics.throughput.startTime) / 1000;
            const throughput = this.metrics.throughput.sent / duration;
            console.log(`  Message Throughput: ${throughput.toFixed(0)} msg/s`);
        }
        
        if (this.metrics.streamingMetrics.totalSize > 0) {
            console.log(`  Streaming Data Transferred: ${(this.metrics.streamingMetrics.totalSize / 1024).toFixed(0)}KB`);
        }
        
        console.log(`  Memory Usage Delta: ${memoryDelta.toFixed(2)}MB`);
        
        console.log('\n📈 PERFORMANCE ASSESSMENT:');
        
        // Connection assessment
        if (this.metrics.connectionTime < 100) {
            console.log('  ✅ Connection time: EXCELLENT (<100ms)');
        } else if (this.metrics.connectionTime < 500) {
            console.log('  ⚠️ Connection time: ACCEPTABLE (<500ms)');
        } else {
            console.log('  ❌ Connection time: POOR (>500ms)');
        }
        
        // Latency assessment
        if (this.metrics.messageLatencies.length > 0) {
            const avgLatency = this.metrics.messageLatencies.reduce((a, b) => a + b, 0) / this.metrics.messageLatencies.length;
            if (avgLatency < 10) {
                console.log('  ✅ Message latency: EXCELLENT (<10ms)');
            } else if (avgLatency < 50) {
                console.log('  ⚠️ Message latency: ACCEPTABLE (<50ms)');
            } else {
                console.log('  ❌ Message latency: POOR (>50ms)');
            }
        }
        
        // Throughput assessment
        if (this.metrics.throughput.sent > 0) {
            const duration = (this.metrics.throughput.endTime - this.metrics.throughput.startTime) / 1000;
            const throughput = this.metrics.throughput.sent / duration;
            if (throughput > 50) {
                console.log('  ✅ Throughput: EXCELLENT (>50 msg/s)');
            } else if (throughput > 10) {
                console.log('  ⚠️ Throughput: ACCEPTABLE (>10 msg/s)');
            } else {
                console.log('  ❌ Throughput: POOR (<10 msg/s)');
            }
        }
        
        // Memory assessment
        if (memoryDelta < 10) {
            console.log('  ✅ Memory usage: EXCELLENT (<10MB)');
        } else if (memoryDelta < 50) {
            console.log('  ⚠️ Memory usage: ACCEPTABLE (<50MB)');
        } else {
            console.log('  ❌ Memory usage: HIGH (>50MB)');
        }
        
        console.log('\n' + '=' + '='.repeat(59));
        console.log(`Test completed at: ${new Date().toISOString()}`);
        console.log('=' + '='.repeat(59));
    }
}

// Run the tests
const tester = new PerformanceTester();
tester.runAllTests().catch(console.error);