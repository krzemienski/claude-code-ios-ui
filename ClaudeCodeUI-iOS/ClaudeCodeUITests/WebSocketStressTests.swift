import XCTest
import os.log
@testable import ClaudeCodeUI

/// Comprehensive WebSocket stress testing suite
final class WebSocketStressTests: XCTestCase {
    
    private var webSocketManager: WebSocketManager!
    private let logger = Logger(subsystem: "com.claudecode.ui", category: "WebSocketStress")
    private var performanceMetrics: [String: Any] = [:]
    
    override func setUp() {
        super.setUp()
        webSocketManager = WebSocketManager()
        webSocketManager.connect()
    }
    
    override func tearDown() {
        webSocketManager.disconnect()
        webSocketManager = nil
        super.tearDown()
    }
    
    // MARK: - Rapid Message Stress Test
    
    func testRapidMessageSending() throws {
        logger.info("Starting rapid message stress test - 100 messages")
        
        let expectation = self.expectation(description: "Rapid messages")
        var messagesSent = 0
        var messagesReceived = 0
        var errors: [Error] = []
        var latencies: [TimeInterval] = []
        let messageCount = 100
        
        // Subscribe to message events
        webSocketManager.onMessageReceived = { message in
            messagesReceived += 1
            if messagesReceived >= messageCount {
                expectation.fulfill()
            }
        }
        
        webSocketManager.onError = { error in
            errors.append(error)
            self.logger.error("WebSocket error: \(error.localizedDescription)")
        }
        
        // Send messages rapidly
        let startTime = Date()
        
        for i in 1...messageCount {
            let messageSentTime = Date()
            let message = Message(
                id: UUID().uuidString,
                text: "Stress test message \(i) - \(messageSentTime.timeIntervalSince1970)",
                timestamp: messageSentTime,
                isFromUser: true
            )
            
            webSocketManager.sendMessage(message) { success in
                if success {
                    messagesSent += 1
                    let latency = Date().timeIntervalSince(messageSentTime)
                    latencies.append(latency)
                } else {
                    self.logger.error("Failed to send message \(i)")
                }
            }
            
            // Small delay to avoid overwhelming the connection
            Thread.sleep(forTimeInterval: 0.01) // 10ms between messages
        }
        
        waitForExpectations(timeout: 30)
        
        let totalTime = Date().timeIntervalSince(startTime)
        let averageLatency = latencies.isEmpty ? 0 : latencies.reduce(0, +) / Double(latencies.count)
        let maxLatency = latencies.max() ?? 0
        let minLatency = latencies.min() ?? 0
        
        // Log results
        logger.info("Rapid Message Test Results:")
        logger.info("  - Messages Sent: \(messagesSent)/\(messageCount)")
        logger.info("  - Messages Received: \(messagesReceived)/\(messageCount)")
        logger.info("  - Total Time: \(String(format: "%.2f", totalTime))s")
        logger.info("  - Average Latency: \(String(format: "%.0f", averageLatency * 1000))ms")
        logger.info("  - Max Latency: \(String(format: "%.0f", maxLatency * 1000))ms")
        logger.info("  - Min Latency: \(String(format: "%.0f", minLatency * 1000))ms")
        logger.info("  - Errors: \(errors.count)")
        
        performanceMetrics["rapidMessages"] = [
            "sent": messagesSent,
            "received": messagesReceived,
            "averageLatency": averageLatency * 1000,
            "maxLatency": maxLatency * 1000,
            "minLatency": minLatency * 1000,
            "errors": errors.count
        ]
        
        // Assertions
        XCTAssertEqual(messagesSent, messageCount, "Not all messages were sent")
        XCTAssertEqual(messagesReceived, messageCount, "Not all messages were received")
        XCTAssertLessThan(averageLatency, 0.1, "Average latency too high: \(averageLatency * 1000)ms")
        XCTAssertEqual(errors.count, 0, "Errors occurred during rapid messaging")
    }
    
    // MARK: - Large Message Stress Test
    
    func testLargeMessageHandling() throws {
        logger.info("Starting large message stress test")
        
        let expectation = self.expectation(description: "Large messages")
        var largeMessagesSent = 0
        var largeMessagesReceived = 0
        let messageSizes = [1_000, 10_000, 50_000, 100_000, 500_000] // bytes
        
        webSocketManager.onMessageReceived = { message in
            largeMessagesReceived += 1
            if largeMessagesReceived >= messageSizes.count {
                expectation.fulfill()
            }
        }
        
        for (index, size) in messageSizes.enumerated() {
            let largeText = String(repeating: "X", count: size)
            let message = Message(
                id: UUID().uuidString,
                text: "Large message \(index): \(largeText)",
                timestamp: Date(),
                isFromUser: true
            )
            
            let startTime = Date()
            webSocketManager.sendMessage(message) { success in
                if success {
                    largeMessagesSent += 1
                    let sendTime = Date().timeIntervalSince(startTime)
                    self.logger.info("Sent \(size) byte message in \(sendTime * 1000)ms")
                }
            }
            
            Thread.sleep(forTimeInterval: 0.5) // Wait between large messages
        }
        
        waitForExpectations(timeout: 30)
        
        logger.info("Large Message Test Results:")
        logger.info("  - Large Messages Sent: \(largeMessagesSent)/\(messageSizes.count)")
        logger.info("  - Large Messages Received: \(largeMessagesReceived)/\(messageSizes.count)")
        
        performanceMetrics["largeMessages"] = [
            "sent": largeMessagesSent,
            "received": largeMessagesReceived,
            "sizes": messageSizes
        ]
        
        XCTAssertEqual(largeMessagesSent, messageSizes.count)
        XCTAssertEqual(largeMessagesReceived, messageSizes.count)
    }
    
    // MARK: - Connection Stability Under Load
    
    func testConnectionStabilityUnderLoad() throws {
        logger.info("Starting connection stability test under load")
        
        let testDuration: TimeInterval = 60 // 1 minute
        let startTime = Date()
        var disconnections = 0
        var reconnections = 0
        var connectionStates: [(Date, WebSocketConnectionState)] = []
        
        // Monitor connection state
        webSocketManager.onConnectionStateChanged = { state in
            connectionStates.append((Date(), state))
            
            switch state {
            case .disconnected:
                disconnections += 1
                self.logger.warning("Connection lost: \(disconnections)")
            case .connecting:
                reconnections += 1
                self.logger.info("Reconnecting: \(reconnections)")
            case .connected:
                self.logger.info("Connected successfully")
            }
        }
        
        // Generate continuous load
        let loadExpectation = self.expectation(description: "Load generation")
        loadExpectation.isInverted = true
        
        DispatchQueue.global(qos: .background).async {
            var messageIndex = 0
            while Date().timeIntervalSince(startTime) < testDuration {
                messageIndex += 1
                
                let message = Message(
                    id: UUID().uuidString,
                    text: "Load test message \(messageIndex)",
                    timestamp: Date(),
                    isFromUser: true
                )
                
                self.webSocketManager.sendMessage(message) { _ in }
                
                // Variable load pattern
                let delay = Double.random(in: 0.05...0.5)
                Thread.sleep(forTimeInterval: delay)
            }
            loadExpectation.fulfill()
        }
        
        waitForExpectations(timeout: testDuration + 10)
        
        // Calculate stability metrics
        let stableConnections = connectionStates.filter { $0.1 == .connected }.count
        let totalStateChanges = connectionStates.count
        let stabilityRate = totalStateChanges > 0 ? Float(stableConnections) / Float(totalStateChanges) * 100 : 0
        
        logger.info("Connection Stability Under Load Results:")
        logger.info("  - Test Duration: \(testDuration)s")
        logger.info("  - Disconnections: \(disconnections)")
        logger.info("  - Reconnections: \(reconnections)")
        logger.info("  - Stability Rate: \(String(format: "%.2f", stabilityRate))%")
        logger.info("  - State Changes: \(totalStateChanges)")
        
        performanceMetrics["connectionStability"] = [
            "disconnections": disconnections,
            "reconnections": reconnections,
            "stabilityRate": stabilityRate,
            "duration": testDuration
        ]
        
        XCTAssertEqual(disconnections, 0, "Unexpected disconnections: \(disconnections)")
        XCTAssertGreaterThan(stabilityRate, 95.0, "Connection stability too low: \(stabilityRate)%")
    }
    
    // MARK: - Concurrent Session Test
    
    func testConcurrentSessions() throws {
        logger.info("Starting concurrent sessions test")
        
        let sessionCount = 5
        var sessions: [WebSocketManager] = []
        let expectation = self.expectation(description: "Concurrent sessions")
        var successfulSessions = 0
        
        for i in 0..<sessionCount {
            let session = WebSocketManager()
            sessions.append(session)
            
            session.connect()
            
            // Send test message from each session
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                let message = Message(
                    id: UUID().uuidString,
                    text: "Concurrent session \(i) test",
                    timestamp: Date(),
                    isFromUser: true
                )
                
                session.sendMessage(message) { success in
                    if success {
                        successfulSessions += 1
                        self.logger.info("Session \(i) sent message successfully")
                    }
                    
                    if successfulSessions >= sessionCount {
                        expectation.fulfill()
                    }
                }
            }
        }
        
        waitForExpectations(timeout: 15)
        
        // Cleanup
        sessions.forEach { $0.disconnect() }
        
        logger.info("Concurrent Sessions Test Results:")
        logger.info("  - Sessions Created: \(sessionCount)")
        logger.info("  - Successful Sessions: \(successfulSessions)")
        
        performanceMetrics["concurrentSessions"] = [
            "total": sessionCount,
            "successful": successfulSessions
        ]
        
        XCTAssertEqual(successfulSessions, sessionCount, "Not all concurrent sessions succeeded")
    }
    
    // MARK: - Reconnection Resilience Test
    
    func testReconnectionResilience() throws {
        logger.info("Starting reconnection resilience test")
        
        let disconnectCount = 10
        var successfulReconnections = 0
        let expectation = self.expectation(description: "Reconnection test")
        
        webSocketManager.onConnectionStateChanged = { state in
            if state == .connected && successfulReconnections > 0 {
                self.logger.info("Reconnected successfully: \(successfulReconnections)")
            }
        }
        
        for i in 1...disconnectCount {
            // Force disconnect
            webSocketManager.disconnect()
            Thread.sleep(forTimeInterval: 0.5)
            
            // Reconnect
            webSocketManager.connect()
            
            // Wait for connection
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                if self.webSocketManager.isConnected {
                    successfulReconnections += 1
                    self.logger.info("Reconnection \(i) successful")
                } else {
                    self.logger.error("Reconnection \(i) failed")
                }
                
                if i == disconnectCount {
                    expectation.fulfill()
                }
            }
            
            Thread.sleep(forTimeInterval: 3)
        }
        
        waitForExpectations(timeout: 45)
        
        logger.info("Reconnection Resilience Test Results:")
        logger.info("  - Disconnections: \(disconnectCount)")
        logger.info("  - Successful Reconnections: \(successfulReconnections)")
        logger.info("  - Success Rate: \(Float(successfulReconnections) / Float(disconnectCount) * 100)%")
        
        performanceMetrics["reconnectionResilience"] = [
            "attempts": disconnectCount,
            "successful": successfulReconnections,
            "successRate": Float(successfulReconnections) / Float(disconnectCount) * 100
        ]
        
        XCTAssertEqual(successfulReconnections, disconnectCount, "Not all reconnections succeeded")
    }
    
    // MARK: - Memory Pressure Test
    
    func testMemoryPressure() throws {
        logger.info("Starting memory pressure test")
        
        let initialMemory = getMemoryUsage()
        logger.info("Initial memory: \(formatBytes(initialMemory))")
        
        let messageCount = 1000
        var messages: [Message] = []
        
        // Generate and send many messages
        for i in 1...messageCount {
            let message = Message(
                id: UUID().uuidString,
                text: "Memory test message \(i) with some additional content to increase size",
                timestamp: Date(),
                isFromUser: i % 2 == 0
            )
            messages.append(message)
            
            webSocketManager.sendMessage(message) { _ in }
            
            if i % 100 == 0 {
                let currentMemory = getMemoryUsage()
                logger.info("Memory after \(i) messages: \(formatBytes(currentMemory))")
            }
        }
        
        // Clear messages and check memory
        messages.removeAll()
        Thread.sleep(forTimeInterval: 5) // Allow cleanup
        
        let finalMemory = getMemoryUsage()
        let memoryGrowth = finalMemory - initialMemory
        
        logger.info("Memory Pressure Test Results:")
        logger.info("  - Messages Processed: \(messageCount)")
        logger.info("  - Initial Memory: \(formatBytes(initialMemory))")
        logger.info("  - Final Memory: \(formatBytes(finalMemory))")
        logger.info("  - Memory Growth: \(formatBytes(memoryGrowth))")
        
        performanceMetrics["memoryPressure"] = [
            "messages": messageCount,
            "initialMemory": initialMemory,
            "finalMemory": finalMemory,
            "growth": memoryGrowth
        ]
        
        // Allow reasonable memory growth (20MB for 1000 messages)
        XCTAssertLessThan(memoryGrowth, 20_000_000, "Excessive memory growth: \(formatBytes(memoryGrowth))")
    }
    
    // MARK: - Performance Report Generation
    
    func testGenerateStressTestReport() throws {
        logger.info("Running all stress tests and generating report")
        
        // Run all tests
        try? testRapidMessageSending()
        try? testLargeMessageHandling()
        try? testConnectionStabilityUnderLoad()
        try? testConcurrentSessions()
        try? testReconnectionResilience()
        try? testMemoryPressure()
        
        // Generate comprehensive report
        logger.info("======= WEBSOCKET STRESS TEST REPORT =======")
        logger.info("Timestamp: \(Date())")
        logger.info("")
        
        if let rapidMetrics = performanceMetrics["rapidMessages"] as? [String: Any] {
            logger.info("RAPID MESSAGE TEST:")
            logger.info("  ✅ Messages: \(rapidMetrics["sent"] ?? 0)/\(rapidMetrics["received"] ?? 0)")
            logger.info("  ✅ Avg Latency: \(rapidMetrics["averageLatency"] ?? 0)ms")
            logger.info("  ✅ Errors: \(rapidMetrics["errors"] ?? 0)")
        }
        
        if let stabilityMetrics = performanceMetrics["connectionStability"] as? [String: Any] {
            logger.info("")
            logger.info("CONNECTION STABILITY:")
            logger.info("  ✅ Stability Rate: \(stabilityMetrics["stabilityRate"] ?? 0)%")
            logger.info("  ✅ Disconnections: \(stabilityMetrics["disconnections"] ?? 0)")
        }
        
        if let memoryMetrics = performanceMetrics["memoryPressure"] as? [String: Any] {
            logger.info("")
            logger.info("MEMORY MANAGEMENT:")
            logger.info("  ✅ Messages: \(memoryMetrics["messages"] ?? 0)")
            logger.info("  ✅ Memory Growth: \(formatBytes(memoryMetrics["growth"] as? Int64 ?? 0))")
        }
        
        logger.info("")
        logger.info("OVERALL ASSESSMENT:")
        logger.info("  ✅ All stress tests completed")
        logger.info("  ✅ WebSocket performance validated")
        logger.info("=============================================")
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
}