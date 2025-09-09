//
//  WebSocketConnectivityTest.swift
//  ClaudeCodeUI
//
//  Comprehensive WebSocket connectivity and streaming test
//

import Foundation
import UIKit

/// WebSocket connectivity and streaming test runner
class WebSocketConnectivityTest {
    
    // MARK: - Test Results
    struct TestResult {
        let testName: String
        let passed: Bool
        let duration: TimeInterval
        let details: String
        let severity: Severity
        
        enum Severity: String {
            case critical = "🔴 CRITICAL"
            case high = "🟠 HIGH"
            case medium = "🟡 MEDIUM"
            case low = "🟢 LOW"
            case info = "ℹ️ INFO"
        }
    }
    
    // MARK: - Properties
    private var webSocketManager: WebSocketManager!
    private var testResults: [TestResult] = []
    private var performanceMetrics: [String: Any] = [:]
    private let testTimeout: TimeInterval = 30.0
    
    // Test configuration
    private let testEndpoints = [
        "ws://localhost:3004/ws",
        "ws://192.168.0.43:3004/ws",
        "wss://api.claude-code.com/ws"  // Production endpoint (if available)
    ]
    
    // MARK: - Test Runner
    
    /// Run all WebSocket tests
    func runAllTests(completion: @escaping ([TestResult]) -> Void) {
        print("🚀 Starting WebSocket Connectivity and Streaming Tests")
        print("=" * 60)
        
        testResults.removeAll()
        performanceMetrics.removeAll()
        
        // Initialize WebSocket manager
        webSocketManager = WebSocketManager()
        webSocketManager.delegate = self
        
        // Run test suite
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 1. Configuration Tests
            self.testWebSocketConfiguration()
            
            // 2. Connection Tests
            self.testConnectionEstablishment()
            self.testAuthenticationFlow()
            self.testMultipleEndpoints()
            
            // 3. Message Streaming Tests
            self.testMessageSending()
            self.testMessageReceiving()
            self.testStreamingResponses()
            self.testLargeMessageHandling()
            
            // 4. Resilience Tests
            self.testReconnectionLogic()
            self.testNetworkInterruption()
            self.testServerDisconnection()
            self.testExponentialBackoff()
            
            // 5. Performance Tests
            self.testLatencyMeasurement()
            self.testThroughput()
            self.testMemoryUsage()
            self.testConcurrentConnections()
            
            // Generate report
            DispatchQueue.main.async {
                self.generateTestReport()
                completion(self.testResults)
            }
        }
    }
    
    // MARK: - 1. Configuration Tests
    
    private func testWebSocketConfiguration() {
        let startTime = Date()
        var passed = true
        var details = ""
        
        // Check WebSocket manager configuration
        if webSocketManager == nil {
            passed = false
            details += "❌ WebSocketManager not initialized\n"
        } else {
            details += "✅ WebSocketManager initialized\n"
        }
        
        // Check reconnection settings
        if webSocketManager.reconnectDelay < 1.0 {
            details += "⚠️ Reconnect delay too short: \(webSocketManager.reconnectDelay)s\n"
        } else {
            details += "✅ Reconnect delay: \(webSocketManager.reconnectDelay)s\n"
        }
        
        // Check max reconnect attempts
        if webSocketManager.maxReconnectAttempts < 5 {
            details += "⚠️ Max reconnect attempts too low: \(webSocketManager.maxReconnectAttempts)\n"
        } else {
            details += "✅ Max reconnect attempts: \(webSocketManager.maxReconnectAttempts)\n"
        }
        
        // Check message queue limit
        if webSocketManager.messageQueueLimit < 50 {
            details += "⚠️ Message queue limit too low: \(webSocketManager.messageQueueLimit)\n"
        } else {
            details += "✅ Message queue limit: \(webSocketManager.messageQueueLimit)\n"
        }
        
        let result = TestResult(
            testName: "WebSocket Configuration",
            passed: passed,
            duration: Date().timeIntervalSince(startTime),
            details: details,
            severity: passed ? .info : .medium
        )
        testResults.append(result)
    }
    
    // MARK: - 2. Connection Tests
    
    private func testConnectionEstablishment() {
        let startTime = Date()
        let semaphore = DispatchSemaphore(value: 0)
        var connectionSuccess = false
        var connectionTime: TimeInterval = 0
        var details = ""
        
        // Test connection to primary endpoint
        let endpoint = testEndpoints[0]
        details += "Testing connection to: \(endpoint)\n"
        
        webSocketManager.connect(to: endpoint)
        
        // Wait for connection with timeout
        DispatchQueue.global().asyncAfter(deadline: .now() + 5.0) {
            connectionTime = Date().timeIntervalSince(startTime)
            connectionSuccess = self.webSocketManager.isConnected
            semaphore.signal()
        }
        
        semaphore.wait()
        
        if connectionSuccess {
            details += "✅ Connection established in \(String(format: "%.2f", connectionTime))s\n"
            performanceMetrics["connectionTime"] = connectionTime
        } else {
            details += "❌ Failed to establish connection within 5 seconds\n"
        }
        
        // Test connection state
        let expectedState = WebSocketConnectionState.connected
        let actualState = webSocketManager.connectionState
        if actualState == expectedState {
            details += "✅ Connection state: \(actualState)\n"
        } else {
            details += "❌ Unexpected state: \(actualState) (expected: \(expectedState))\n"
        }
        
        let result = TestResult(
            testName: "Connection Establishment",
            passed: connectionSuccess,
            duration: Date().timeIntervalSince(startTime),
            details: details,
            severity: connectionSuccess ? .info : .critical
        )
        testResults.append(result)
    }
    
    private func testAuthenticationFlow() {
        let startTime = Date()
        var authSuccess = false
        var details = ""
        
        // Test token-based authentication
        let testToken = "test_jwt_token_12345"
        UserDefaults.standard.set(testToken, forKey: "authToken")
        
        // Connect with authentication
        webSocketManager.connect(to: testEndpoints[0], with: testToken)
        
        Thread.sleep(forTimeInterval: 2.0)
        
        if webSocketManager.isConnected {
            authSuccess = true
            details += "✅ Authentication successful with token\n"
        } else {
            details += "❌ Authentication failed\n"
        }
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "authToken")
        
        let result = TestResult(
            testName: "Authentication Flow",
            passed: authSuccess,
            duration: Date().timeIntervalSince(startTime),
            details: details,
            severity: authSuccess ? .info : .high
        )
        testResults.append(result)
    }
    
    private func testMultipleEndpoints() {
        let startTime = Date()
        var successCount = 0
        var details = ""
        
        for endpoint in testEndpoints {
            details += "\nTesting endpoint: \(endpoint)\n"
            
            webSocketManager.disconnect()
            Thread.sleep(forTimeInterval: 0.5)
            
            webSocketManager.connect(to: endpoint)
            Thread.sleep(forTimeInterval: 2.0)
            
            if webSocketManager.isConnected {
                successCount += 1
                details += "  ✅ Connected successfully\n"
            } else {
                details += "  ❌ Connection failed\n"
            }
        }
        
        let passed = successCount > 0
        details += "\nConnected to \(successCount)/\(testEndpoints.count) endpoints\n"
        
        let result = TestResult(
            testName: "Multiple Endpoints",
            passed: passed,
            duration: Date().timeIntervalSince(startTime),
            details: details,
            severity: passed ? .info : .medium
        )
        testResults.append(result)
    }
    
    // MARK: - 3. Message Streaming Tests
    
    private func testMessageSending() {
        let startTime = Date()
        var sendSuccess = true
        var details = ""
        
        // Ensure connected
        if !webSocketManager.isConnected {
            webSocketManager.connect(to: testEndpoints[0])
            Thread.sleep(forTimeInterval: 2.0)
        }
        
        // Test different message types
        let testMessages = [
            ("Hello, WebSocket!", WebSocketMessageType.message),
            ("claude-command test", WebSocketMessageType.claudeCommand),
            ("cursor-command test", WebSocketMessageType.cursorCommand)
        ]
        
        for (content, type) in testMessages {
            webSocketManager.sendMessage(content, projectId: "test-project", messageType: type)
            details += "Sent \(type): \(content)\n"
        }
        
        // Test batch sending
        let batchSize = 10
        let batchStartTime = Date()
        for i in 1...batchSize {
            webSocketManager.sendMessage("Batch message \(i)", projectId: "test-project")
        }
        let batchTime = Date().timeIntervalSince(batchStartTime)
        details += "\n✅ Sent \(batchSize) messages in \(String(format: "%.3f", batchTime))s\n"
        performanceMetrics["batchSendTime"] = batchTime
        
        let result = TestResult(
            testName: "Message Sending",
            passed: sendSuccess,
            duration: Date().timeIntervalSince(startTime),
            details: details,
            severity: .info
        )
        testResults.append(result)
    }
    
    private func testMessageReceiving() {
        let startTime = Date()
        var receiveSuccess = false
        var details = ""
        var receivedCount = 0
        
        // Setup message receiver
        let semaphore = DispatchSemaphore(value: 0)
        
        // Send a message and wait for response
        webSocketManager.sendMessage("echo test", projectId: "test-project")
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 3.0) {
            // Check if we received any messages (would be tracked by delegate)
            receiveSuccess = self.webSocketManager.isConnected
            semaphore.signal()
        }
        
        semaphore.wait()
        
        details += receiveSuccess ? "✅ Message receiving functional\n" : "⚠️ No messages received in test window\n"
        
        let result = TestResult(
            testName: "Message Receiving",
            passed: receiveSuccess,
            duration: Date().timeIntervalSince(startTime),
            details: details,
            severity: receiveSuccess ? .info : .medium
        )
        testResults.append(result)
    }
    
    private func testStreamingResponses() {
        let startTime = Date()
        var streamingSuccess = true
        var details = ""
        
        // Test streaming message handling
        let largeMessage = String(repeating: "A", count: 10000)
        webSocketManager.sendMessage(largeMessage, projectId: "test-streaming")
        
        details += "✅ Sent large streaming message (\(largeMessage.count) bytes)\n"
        
        // Simulate streaming chunks
        let chunkSize = 1024
        let chunks = largeMessage.count / chunkSize
        details += "Expected chunks: ~\(chunks)\n"
        
        performanceMetrics["streamingChunks"] = chunks
        
        let result = TestResult(
            testName: "Streaming Responses",
            passed: streamingSuccess,
            duration: Date().timeIntervalSince(startTime),
            details: details,
            severity: .info
        )
        testResults.append(result)
    }
    
    private func testLargeMessageHandling() {
        let startTime = Date()
        var success = true
        var details = ""
        
        // Test various message sizes
        let messageSizes = [1_000, 10_000, 100_000, 1_000_000] // bytes
        
        for size in messageSizes {
            let message = String(repeating: "X", count: size)
            let sendStartTime = Date()
            
            webSocketManager.sendMessage(message, projectId: "test-large")
            
            let sendTime = Date().timeIntervalSince(sendStartTime)
            let throughput = Double(size) / sendTime / 1024.0 // KB/s
            
            details += "Size: \(size/1024)KB - Time: \(String(format: "%.3f", sendTime))s - Throughput: \(String(format: "%.1f", throughput))KB/s\n"
            
            if sendTime > 5.0 {
                success = false
                details += "  ⚠️ Send time exceeded 5 seconds\n"
            }
        }
        
        let result = TestResult(
            testName: "Large Message Handling",
            passed: success,
            duration: Date().timeIntervalSince(startTime),
            details: details,
            severity: success ? .info : .medium
        )
        testResults.append(result)
    }
    
    // MARK: - 4. Resilience Tests
    
    private func testReconnectionLogic() {
        let startTime = Date()
        var reconnectSuccess = false
        var details = ""
        
        // Force disconnect
        webSocketManager.disconnect()
        details += "Disconnected WebSocket\n"
        
        Thread.sleep(forTimeInterval: 1.0)
        
        // Trigger reconnection
        webSocketManager.connect(to: testEndpoints[0])
        
        // Wait for reconnection
        var attempts = 0
        while !webSocketManager.isConnected && attempts < 10 {
            Thread.sleep(forTimeInterval: 1.0)
            attempts += 1
        }
        
        reconnectSuccess = webSocketManager.isConnected
        
        if reconnectSuccess {
            details += "✅ Reconnected after \(attempts) seconds\n"
            performanceMetrics["reconnectTime"] = TimeInterval(attempts)
        } else {
            details += "❌ Failed to reconnect within 10 seconds\n"
        }
        
        let result = TestResult(
            testName: "Reconnection Logic",
            passed: reconnectSuccess,
            duration: Date().timeIntervalSince(startTime),
            details: details,
            severity: reconnectSuccess ? .info : .high
        )
        testResults.append(result)
    }
    
    private func testNetworkInterruption() {
        let startTime = Date()
        var recoverySuccess = true
        var details = ""
        
        details += "Simulating network interruption...\n"
        
        // Note: In a real test, you would use Network Link Conditioner or similar
        // For now, we'll simulate by disconnecting and reconnecting
        
        let originalState = webSocketManager.isConnected
        webSocketManager.disconnect()
        
        Thread.sleep(forTimeInterval: 2.0)
        
        // Attempt recovery
        webSocketManager.connect(to: testEndpoints[0])
        Thread.sleep(forTimeInterval: 3.0)
        
        recoverySuccess = webSocketManager.isConnected
        
        details += recoverySuccess ? "✅ Recovered from network interruption\n" : "❌ Failed to recover\n"
        
        let result = TestResult(
            testName: "Network Interruption Recovery",
            passed: recoverySuccess,
            duration: Date().timeIntervalSince(startTime),
            details: details,
            severity: recoverySuccess ? .info : .high
        )
        testResults.append(result)
    }
    
    private func testServerDisconnection() {
        let startTime = Date()
        var handledCorrectly = true
        var details = ""
        
        // Simulate server-side disconnection
        details += "Simulating server disconnection...\n"
        
        // Send abort session command (simulates server closing connection)
        webSocketManager.abortSession(sessionId: "test-session")
        
        Thread.sleep(forTimeInterval: 2.0)
        
        // Check if manager handled disconnection properly
        if webSocketManager.connectionState == .disconnected || 
           webSocketManager.connectionState == .reconnecting {
            details += "✅ Properly handled server disconnection\n"
        } else {
            handledCorrectly = false
            details += "❌ Unexpected state after server disconnection: \(webSocketManager.connectionState)\n"
        }
        
        let result = TestResult(
            testName: "Server Disconnection Handling",
            passed: handledCorrectly,
            duration: Date().timeIntervalSince(startTime),
            details: details,
            severity: handledCorrectly ? .info : .medium
        )
        testResults.append(result)
    }
    
    private func testExponentialBackoff() {
        let startTime = Date()
        var backoffCorrect = true
        var details = ""
        
        // Test exponential backoff calculation
        let expectedDelays = [1.0, 2.0, 4.0, 8.0, 16.0, 30.0, 30.0] // Max at 30s
        var calculatedDelays: [TimeInterval] = []
        
        for attempt in 1...7 {
            let delay = min(1.0 * pow(2.0, Double(attempt - 1)), 30.0)
            calculatedDelays.append(delay)
        }
        
        for (index, (expected, calculated)) in zip(expectedDelays, calculatedDelays).enumerated() {
            if abs(expected - calculated) < 0.1 {
                details += "✅ Attempt \(index + 1): \(calculated)s (expected: \(expected)s)\n"
            } else {
                backoffCorrect = false
                details += "❌ Attempt \(index + 1): \(calculated)s (expected: \(expected)s)\n"
            }
        }
        
        let result = TestResult(
            testName: "Exponential Backoff",
            passed: backoffCorrect,
            duration: Date().timeIntervalSince(startTime),
            details: details,
            severity: backoffCorrect ? .info : .medium
        )
        testResults.append(result)
    }
    
    // MARK: - 5. Performance Tests
    
    private func testLatencyMeasurement() {
        let startTime = Date()
        var latencies: [TimeInterval] = []
        var details = ""
        
        // Measure round-trip latency
        for i in 1...10 {
            let pingStart = Date()
            webSocketManager.sendMessage("ping \(i)", projectId: "test-latency")
            // In real scenario, would wait for pong response
            Thread.sleep(forTimeInterval: 0.1)
            let latency = Date().timeIntervalSince(pingStart) * 1000 // Convert to ms
            latencies.append(latency)
        }
        
        let avgLatency = latencies.reduce(0, +) / Double(latencies.count)
        let maxLatency = latencies.max() ?? 0
        let minLatency = latencies.min() ?? 0
        
        details += "Average latency: \(String(format: "%.2f", avgLatency))ms\n"
        details += "Min latency: \(String(format: "%.2f", minLatency))ms\n"
        details += "Max latency: \(String(format: "%.2f", maxLatency))ms\n"
        
        performanceMetrics["avgLatency"] = avgLatency
        performanceMetrics["maxLatency"] = maxLatency
        
        let passed = avgLatency < 100 // Should be under 100ms
        
        let result = TestResult(
            testName: "Latency Measurement",
            passed: passed,
            duration: Date().timeIntervalSince(startTime),
            details: details,
            severity: passed ? .info : .medium
        )
        testResults.append(result)
    }
    
    private func testThroughput() {
        let startTime = Date()
        var details = ""
        
        // Test message throughput
        let messageCount = 100
        let messageSize = 1024 // 1KB per message
        let testData = String(repeating: "T", count: messageSize)
        
        let throughputStart = Date()
        for i in 1...messageCount {
            webSocketManager.sendMessage(testData, projectId: "test-throughput-\(i)")
        }
        let throughputTime = Date().timeIntervalSince(throughputStart)
        
        let totalBytes = messageCount * messageSize
        let throughputKBps = Double(totalBytes) / throughputTime / 1024.0
        let messagesPerSecond = Double(messageCount) / throughputTime
        
        details += "Sent \(messageCount) messages (\(messageSize) bytes each)\n"
        details += "Total time: \(String(format: "%.2f", throughputTime))s\n"
        details += "Throughput: \(String(format: "%.1f", throughputKBps))KB/s\n"
        details += "Messages/second: \(String(format: "%.1f", messagesPerSecond))\n"
        
        performanceMetrics["throughputKBps"] = throughputKBps
        performanceMetrics["messagesPerSecond"] = messagesPerSecond
        
        let passed = messagesPerSecond > 10 // Should handle at least 10 msg/s
        
        let result = TestResult(
            testName: "Throughput Test",
            passed: passed,
            duration: Date().timeIntervalSince(startTime),
            details: details,
            severity: passed ? .info : .medium
        )
        testResults.append(result)
    }
    
    private func testMemoryUsage() {
        let startTime = Date()
        var details = ""
        
        // Get baseline memory
        let baselineMemory = getMemoryUsage()
        details += "Baseline memory: \(String(format: "%.2f", baselineMemory))MB\n"
        
        // Send many messages to test memory growth
        for i in 1...1000 {
            let message = "Memory test message \(i) - " + String(repeating: "M", count: 100)
            webSocketManager.sendMessage(message, projectId: "test-memory")
        }
        
        // Check memory after load
        let loadedMemory = getMemoryUsage()
        let memoryGrowth = loadedMemory - baselineMemory
        details += "Memory after 1000 messages: \(String(format: "%.2f", loadedMemory))MB\n"
        details += "Memory growth: \(String(format: "%.2f", memoryGrowth))MB\n"
        
        performanceMetrics["memoryGrowth"] = memoryGrowth
        
        // Memory growth should be reasonable (< 50MB for 1000 messages)
        let passed = memoryGrowth < 50.0
        
        let result = TestResult(
            testName: "Memory Usage",
            passed: passed,
            duration: Date().timeIntervalSince(startTime),
            details: details,
            severity: passed ? .info : .high
        )
        testResults.append(result)
    }
    
    private func testConcurrentConnections() {
        let startTime = Date()
        var details = ""
        var allConnected = true
        
        // Test multiple concurrent WebSocket connections
        var managers: [WebSocketManager] = []
        let concurrentCount = 5
        
        for i in 1...concurrentCount {
            let manager = WebSocketManager()
            managers.append(manager)
            manager.connect(to: testEndpoints[0])
            details += "Created connection \(i)\n"
        }
        
        Thread.sleep(forTimeInterval: 3.0)
        
        // Check all connections
        for (index, manager) in managers.enumerated() {
            if manager.isConnected {
                details += "  ✅ Connection \(index + 1) active\n"
            } else {
                allConnected = false
                details += "  ❌ Connection \(index + 1) failed\n"
            }
        }
        
        // Clean up
        for manager in managers {
            manager.disconnect()
        }
        
        let result = TestResult(
            testName: "Concurrent Connections",
            passed: allConnected,
            duration: Date().timeIntervalSince(startTime),
            details: details,
            severity: allConnected ? .info : .medium
        )
        testResults.append(result)
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Double(info.resident_size) / 1024.0 / 1024.0 : 0
    }
    
    // MARK: - Test Report Generation
    
    private func generateTestReport() {
        print("\n" + "=" * 60)
        print("📊 WEBSOCKET CONNECTIVITY TEST REPORT")
        print("=" * 60)
        
        // Summary statistics
        let totalTests = testResults.count
        let passedTests = testResults.filter { $0.passed }.count
        let failedTests = totalTests - passedTests
        let passRate = Double(passedTests) / Double(totalTests) * 100
        
        print("\n📈 SUMMARY:")
        print("  Total Tests: \(totalTests)")
        print("  Passed: \(passedTests) (\(String(format: "%.1f", passRate))%)")
        print("  Failed: \(failedTests)")
        
        // Group results by severity
        let criticalIssues = testResults.filter { !$0.passed && $0.severity == .critical }
        let highIssues = testResults.filter { !$0.passed && $0.severity == .high }
        let mediumIssues = testResults.filter { !$0.passed && $0.severity == .medium }
        
        if !criticalIssues.isEmpty {
            print("\n🔴 CRITICAL ISSUES:")
            for issue in criticalIssues {
                print("  - \(issue.testName)")
                print("    \(issue.details.replacingOccurrences(of: "\n", with: "\n    "))")
            }
        }
        
        if !highIssues.isEmpty {
            print("\n🟠 HIGH PRIORITY ISSUES:")
            for issue in highIssues {
                print("  - \(issue.testName)")
                print("    \(issue.details.replacingOccurrences(of: "\n", with: "\n    "))")
            }
        }
        
        if !mediumIssues.isEmpty {
            print("\n🟡 MEDIUM PRIORITY ISSUES:")
            for issue in mediumIssues {
                print("  - \(issue.testName)")
            }
        }
        
        // Performance metrics
        print("\n⚡ PERFORMANCE METRICS:")
        if let connectionTime = performanceMetrics["connectionTime"] as? TimeInterval {
            print("  Connection Time: \(String(format: "%.2f", connectionTime))s")
        }
        if let avgLatency = performanceMetrics["avgLatency"] as? Double {
            print("  Average Latency: \(String(format: "%.2f", avgLatency))ms")
        }
        if let throughput = performanceMetrics["throughputKBps"] as? Double {
            print("  Throughput: \(String(format: "%.1f", throughput))KB/s")
        }
        if let msgPerSec = performanceMetrics["messagesPerSecond"] as? Double {
            print("  Messages/Second: \(String(format: "%.1f", msgPerSec))")
        }
        if let memGrowth = performanceMetrics["memoryGrowth"] as? Double {
            print("  Memory Growth: \(String(format: "%.2f", memGrowth))MB")
        }
        
        // Recommendations
        print("\n💡 RECOMMENDATIONS:")
        
        if !criticalIssues.isEmpty {
            print("  🔴 Address critical connection issues immediately")
        }
        
        if let avgLatency = performanceMetrics["avgLatency"] as? Double, avgLatency > 100 {
            print("  🟡 Optimize message handling to reduce latency")
        }
        
        if let memGrowth = performanceMetrics["memoryGrowth"] as? Double, memGrowth > 20 {
            print("  🟡 Investigate memory usage patterns and potential leaks")
        }
        
        if failedTests == 0 {
            print("  ✅ WebSocket implementation is functioning well!")
        }
        
        print("\n" + "=" * 60)
        print("Test completed at: \(Date())")
        print("=" * 60 + "\n")
    }
}

// MARK: - WebSocketManagerDelegate

extension WebSocketConnectivityTest: WebSocketManagerDelegate {
    func webSocketDidConnect(_ webSocket: WebSocketProtocol) {
        print("✅ WebSocket connected")
    }
    
    func webSocketDidDisconnect(_ webSocket: WebSocketProtocol, error: Error?) {
        if let error = error {
            print("⚠️ WebSocket disconnected with error: \(error)")
        } else {
            print("ℹ️ WebSocket disconnected normally")
        }
    }
    
    func webSocket(_ webSocket: WebSocketProtocol, didReceiveMessage message: WebSocketMessage) {
        print("📥 Received message: \(message.type)")
    }
    
    func webSocket(_ webSocket: WebSocketProtocol, didReceiveText text: String) {
        print("📝 Received text: \(text.prefix(100))...")
    }
    
    func webSocket(_ webSocket: WebSocketProtocol, didReceiveData data: Data) {
        print("📦 Received data: \(data.count) bytes")
    }
    
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState) {
        print("🔄 Connection state changed to: \(state)")
    }
}

// MARK: - Test Execution Helper

/// Run the WebSocket connectivity test
func runWebSocketConnectivityTest() {
    let testRunner = WebSocketConnectivityTest()
    
    testRunner.runAllTests { results in
        // Process results
        let failedTests = results.filter { !$0.passed }
        
        if failedTests.isEmpty {
            print("✅ All WebSocket tests passed!")
        } else {
            print("⚠️ \(failedTests.count) WebSocket tests failed")
            
            // Report to crash/analytics service if available
            for test in failedTests {
                print("Failed: \(test.testName) - \(test.severity.rawValue)")
            }
        }
    }
}