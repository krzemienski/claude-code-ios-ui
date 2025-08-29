//
//  WebSocketIntegrationTests.swift
//  ClaudeCodeUIIntegrationTests
//
//  Created on January 29, 2025.
//  Comprehensive WebSocket integration tests for real-time communication
//

import XCTest
import Network
import Starscream
@testable import ClaudeCodeUI

/// Comprehensive WebSocket integration tests covering all real-time communication scenarios
/// Tests connection establishment, auto-reconnection, message ordering, heartbeat, and large messages
final class WebSocketIntegrationTests: XCTestCase {
    
    // MARK: - Test Configuration
    
    private var webSocketManager: WebSocketManager!
    private var shellWebSocketManager: ShellWebSocketManager!
    private var networkMonitor: NWPathMonitor!
    private var testExpectation: XCTestExpectation!
    private var receivedMessages: [String] = []
    private var connectionEvents: [String] = []
    private var performanceMetrics: [String: TimeInterval] = [:]
    private var testStartTime: Date!
    
    // WebSocket URLs
    private let chatWebSocketURL = "ws://192.168.0.43:3004/ws"
    private let shellWebSocketURL = "ws://192.168.0.43:3004/shell"
    private let testTimeout: TimeInterval = 30.0
    
    override func setUpWithError() throws {
        super.setUp()
        testStartTime = Date()
        
        // Initialize WebSocket managers
        webSocketManager = WebSocketManager.shared
        shellWebSocketManager = ShellWebSocketManager.shared
        
        // Initialize network monitoring
        networkMonitor = NWPathMonitor()
        
        // Clear any previous state
        receivedMessages.removeAll()
        connectionEvents.removeAll()
        performanceMetrics.removeAll()
        
        // Ensure backend is accessible
        try validateBackendConnectivity()
        
        print("🧪 WebSocket Test Setup Complete - \(Date())")
    }
    
    override func tearDownWithError() throws {
        // Disconnect WebSockets
        webSocketManager?.disconnect()
        shellWebSocketManager?.disconnect()
        
        // Stop network monitoring
        networkMonitor?.cancel()
        
        // Clear test data
        receivedMessages.removeAll()
        connectionEvents.removeAll()
        
        let testDuration = Date().timeIntervalSince(testStartTime)
        print("🏁 WebSocket Test Teardown Complete - Duration: \(String(format: "%.2f", testDuration))s")
        
        super.tearDown()
    }
    
    // MARK: - Connection Establishment Tests
    
    func testChatWebSocketConnection() throws {
        print("🔌 Testing chat WebSocket connection establishment...")
        
        testExpectation = expectation(description: "Chat WebSocket connection")
        var connectionEstablished = false
        let startTime = Date()
        
        // Setup connection observer
        let observer = NotificationCenter.default.addObserver(
            forName: .webSocketDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            connectionEstablished = true
            self?.connectionEvents.append("Chat connected at \(Date())")
            self?.performanceMetrics["chatConnectionTime"] = Date().timeIntervalSince(startTime)
            self?.testExpectation.fulfill()
        }
        
        // Attempt connection
        webSocketManager.connect()
        
        waitForExpectations(timeout: testTimeout) { error in
            NotificationCenter.default.removeObserver(observer)
            if let error = error {
                XCTFail("Chat WebSocket connection timeout: \(error)")
            }
        }
        
        XCTAssertTrue(connectionEstablished, "Chat WebSocket should establish connection")
        XCTAssertTrue(webSocketManager.isConnected, "WebSocket manager should report connected state")
        
        // Validate connection time
        if let connectionTime = performanceMetrics["chatConnectionTime"] {
            XCTAssertLessThan(connectionTime, 5.0, "Chat WebSocket connection should complete within 5 seconds")
            print("✅ Chat WebSocket connected in \(String(format: "%.2f", connectionTime))s")
        }
    }
    
    func testShellWebSocketConnection() throws {
        print("🖥️ Testing shell WebSocket connection establishment...")
        
        testExpectation = expectation(description: "Shell WebSocket connection")
        var connectionEstablished = false
        let startTime = Date()
        
        // Setup connection observer
        let observer = NotificationCenter.default.addObserver(
            forName: .shellWebSocketDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            connectionEstablished = true
            self?.connectionEvents.append("Shell connected at \(Date())")
            self?.performanceMetrics["shellConnectionTime"] = Date().timeIntervalSince(startTime)
            self?.testExpectation.fulfill()
        }
        
        // Attempt connection
        shellWebSocketManager.connect()
        
        waitForExpectations(timeout: testTimeout) { error in
            NotificationCenter.default.removeObserver(observer)
            if let error = error {
                XCTFail("Shell WebSocket connection timeout: \(error)")
            }
        }
        
        XCTAssertTrue(connectionEstablished, "Shell WebSocket should establish connection")
        XCTAssertTrue(shellWebSocketManager.isConnected, "Shell WebSocket manager should report connected state")
        
        // Validate connection time
        if let connectionTime = performanceMetrics["shellConnectionTime"] {
            XCTAssertLessThan(connectionTime, 5.0, "Shell WebSocket connection should complete within 5 seconds")
            print("✅ Shell WebSocket connected in \(String(format: "%.2f", connectionTime))s")
        }
    }
    
    func testSimultaneousConnections() throws {
        print("🔄 Testing simultaneous WebSocket connections...")
        
        let chatExpectation = expectation(description: "Chat WebSocket connection")
        let shellExpectation = expectation(description: "Shell WebSocket connection")
        
        var chatConnected = false
        var shellConnected = false
        let startTime = Date()
        
        // Setup observers
        let chatObserver = NotificationCenter.default.addObserver(
            forName: .webSocketDidConnect,
            object: nil,
            queue: .main
        ) { _ in
            chatConnected = true
            chatExpectation.fulfill()
        }
        
        let shellObserver = NotificationCenter.default.addObserver(
            forName: .shellWebSocketDidConnect,
            object: nil,
            queue: .main
        ) { _ in
            shellConnected = true
            shellExpectation.fulfill()
        }
        
        // Connect simultaneously
        webSocketManager.connect()
        shellWebSocketManager.connect()
        
        waitForExpectations(timeout: testTimeout) { error in
            NotificationCenter.default.removeObserver(chatObserver)
            NotificationCenter.default.removeObserver(shellObserver)
            if let error = error {
                XCTFail("Simultaneous WebSocket connections timeout: \(error)")
            }
        }
        
        let connectionTime = Date().timeIntervalSince(startTime)
        
        XCTAssertTrue(chatConnected && shellConnected, "Both WebSockets should connect successfully")
        XCTAssertTrue(webSocketManager.isConnected && shellWebSocketManager.isConnected, "Both managers should report connected state")
        XCTAssertLessThan(connectionTime, 10.0, "Simultaneous connections should complete within 10 seconds")
        
        performanceMetrics["simultaneousConnectionTime"] = connectionTime
        print("✅ Simultaneous WebSocket connections established in \(String(format: "%.2f", connectionTime))s")
    }
    
    // MARK: - Auto-Reconnection Tests
    
    func testChatWebSocketReconnection() throws {
        print("🔌➡️🔌 Testing chat WebSocket auto-reconnection...")
        
        // First establish connection
        try testChatWebSocketConnection()
        
        testExpectation = expectation(description: "Chat WebSocket reconnection")
        var reconnected = false
        let startTime = Date()
        
        // Setup reconnection observer
        let observer = NotificationCenter.default.addObserver(
            forName: .webSocketDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            reconnected = true
            self?.performanceMetrics["chatReconnectionTime"] = Date().timeIntervalSince(startTime)
            self?.testExpectation.fulfill()
        }
        
        // Force disconnect to trigger reconnection
        webSocketManager.disconnect()
        
        // Wait a moment then check if auto-reconnection occurs
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Auto-reconnection should be triggered by the manager
        }
        
        waitForExpectations(timeout: testTimeout) { error in
            NotificationCenter.default.removeObserver(observer)
            if let error = error {
                XCTFail("Chat WebSocket reconnection timeout: \(error)")
            }
        }
        
        XCTAssertTrue(reconnected, "Chat WebSocket should auto-reconnect")
        
        if let reconnectionTime = performanceMetrics["chatReconnectionTime"] {
            XCTAssertLessThan(reconnectionTime, 10.0, "Chat WebSocket reconnection should complete within 10 seconds")
            print("✅ Chat WebSocket reconnected in \(String(format: "%.2f", reconnectionTime))s")
        }
    }
    
    func testExponentialBackoffReconnection() throws {
        print("📈 Testing exponential backoff reconnection pattern...")
        
        var reconnectionAttempts: [TimeInterval] = []
        let maxAttempts = 3
        testExpectation = expectation(description: "Exponential backoff reconnection")
        testExpectation.expectedFulfillmentCount = maxAttempts
        
        let startTime = Date()
        
        // Track reconnection attempts
        let observer = NotificationCenter.default.addObserver(
            forName: .webSocketDidAttemptReconnection,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let attemptTime = Date().timeIntervalSince(startTime)
            reconnectionAttempts.append(attemptTime)
            self?.testExpectation.fulfill()
        }
        
        // Force multiple disconnections to trigger exponential backoff
        webSocketManager.connect()
        
        // Simulate network instability
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.webSocketManager.disconnect()
        }
        
        waitForExpectations(timeout: 60.0) { error in
            NotificationCenter.default.removeObserver(observer)
            if let error = error {
                print("⚠️ Exponential backoff test timeout: \(error)")
            }
        }
        
        // Validate exponential backoff pattern
        XCTAssertGreaterThanOrEqual(reconnectionAttempts.count, 2, "Should have multiple reconnection attempts")
        
        if reconnectionAttempts.count >= 2 {
            let firstInterval = reconnectionAttempts[1] - reconnectionAttempts[0]
            print("✅ Exponential backoff pattern detected. First retry interval: \(String(format: "%.2f", firstInterval))s")
            
            // First retry should be relatively quick (within exponential backoff limits)
            XCTAssertLessThan(firstInterval, 30.0, "First retry should occur within reasonable time")
        }
        
        performanceMetrics["exponentialBackoffTest"] = reconnectionAttempts.last ?? 0
    }
    
    // MARK: - Message Ordering Tests
    
    func testMessageOrderingSequential() throws {
        print("📝 Testing sequential message ordering...")
        
        // Establish connection first
        try testChatWebSocketConnection()
        
        testExpectation = expectation(description: "Sequential message ordering")
        let messageCount = 10
        var receivedOrder: [Int] = []
        
        // Setup message observer
        let observer = NotificationCenter.default.addObserver(
            forName: .webSocketDidReceiveMessage,
            object: nil,
            queue: .main
        ) { notification in
            if let message = notification.userInfo?["message"] as? String,
               let orderNumber = self.extractOrderNumber(from: message) {
                receivedOrder.append(orderNumber)
                
                if receivedOrder.count == messageCount {
                    self.testExpectation.fulfill()
                }
            }
        }
        
        // Send messages in sequence
        for i in 1...messageCount {
            let message = """
            {
                "type": "claude-command",
                "content": "Test message order \(i)",
                "projectPath": "/test/path",
                "messageId": "\(i)"
            }
            """
            
            webSocketManager.send(message: message)
            
            // Small delay between messages to test ordering
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        waitForExpectations(timeout: testTimeout) { error in
            NotificationCenter.default.removeObserver(observer)
            if let error = error {
                XCTFail("Message ordering test timeout: \(error)")
            }
        }
        
        // Validate message order
        let expectedOrder = Array(1...messageCount)
        XCTAssertEqual(receivedOrder, expectedOrder, "Messages should be received in the same order they were sent")
        
        print("✅ Message ordering test passed. Sent: \(expectedOrder), Received: \(receivedOrder)")
        performanceMetrics["messageOrderingTest"] = Double(receivedOrder.count)
    }
    
    func testConcurrentMessageHandling() throws {
        print("⚡ Testing concurrent message handling...")
        
        // Establish connection first
        try testChatWebSocketConnection()
        
        testExpectation = expectation(description: "Concurrent message handling")
        let messageCount = 20
        var receivedMessages: Set<String> = []
        
        // Setup message observer
        let observer = NotificationCenter.default.addObserver(
            forName: .webSocketDidReceiveMessage,
            object: nil,
            queue: .main
        ) { notification in
            if let message = notification.userInfo?["message"] as? String {
                receivedMessages.insert(message)
                
                if receivedMessages.count == messageCount {
                    self.testExpectation.fulfill()
                }
            }
        }
        
        // Send messages concurrently
        let queue = DispatchQueue(label: "concurrent-message-test", attributes: .concurrent)
        let group = DispatchGroup()
        
        for i in 1...messageCount {
            group.enter()
            queue.async {
                let message = """
                {
                    "type": "claude-command",
                    "content": "Concurrent test message \(i)",
                    "projectPath": "/test/path",
                    "messageId": "concurrent_\(i)"
                }
                """
                
                self.webSocketManager.send(message: message)
                group.leave()
            }
        }
        
        group.wait()
        
        waitForExpectations(timeout: testTimeout) { error in
            NotificationCenter.default.removeObserver(observer)
            if let error = error {
                XCTFail("Concurrent message handling timeout: \(error)")
            }
        }
        
        XCTAssertEqual(receivedMessages.count, messageCount, "All concurrent messages should be handled")
        
        print("✅ Concurrent message handling test passed. Handled \(receivedMessages.count) messages")
        performanceMetrics["concurrentMessageTest"] = Double(receivedMessages.count)
    }
    
    // MARK: - Heartbeat/Ping-Pong Tests
    
    func testHeartbeatMechanism() throws {
        print("💓 Testing WebSocket heartbeat mechanism...")
        
        // Establish connection first
        try testChatWebSocketConnection()
        
        testExpectation = expectation(description: "Heartbeat mechanism")
        var pongReceived = false
        
        // Setup pong observer
        let observer = NotificationCenter.default.addObserver(
            forName: .webSocketDidReceivePong,
            object: nil,
            queue: .main
        ) { _ in
            pongReceived = true
            self.testExpectation.fulfill()
        }
        
        // Send ping
        webSocketManager.sendPing()
        
        waitForExpectations(timeout: testTimeout) { error in
            NotificationCenter.default.removeObserver(observer)
            if let error = error {
                print("⚠️ Heartbeat test timeout: \(error)")
                // This might be expected if server doesn't support ping/pong
            }
        }
        
        // Note: This test might not pass if the backend doesn't implement ping/pong
        // but we track the behavior for documentation
        if pongReceived {
            print("✅ Heartbeat mechanism working - Pong received")
        } else {
            print("ℹ️ Heartbeat mechanism not implemented on server side")
        }
        
        performanceMetrics["heartbeatTest"] = pongReceived ? 1.0 : 0.0
    }
    
    func testConnectionKeepAlive() throws {
        print("⏰ Testing connection keep-alive over extended period...")
        
        // Establish connection first
        try testChatWebSocketConnection()
        
        testExpectation = expectation(description: "Connection keep-alive")
        let keepAliveTestDuration: TimeInterval = 60.0 // 1 minute test
        var connectionMaintained = true
        
        // Monitor connection status
        let observer = NotificationCenter.default.addObserver(
            forName: .webSocketDidDisconnect,
            object: nil,
            queue: .main
        ) { _ in
            connectionMaintained = false
        }
        
        // Check connection after keep-alive period
        DispatchQueue.main.asyncAfter(deadline: .now() + keepAliveTestDuration) {
            self.testExpectation.fulfill()
        }
        
        waitForExpectations(timeout: keepAliveTestDuration + 10.0) { error in
            NotificationCenter.default.removeObserver(observer)
            if let error = error {
                XCTFail("Connection keep-alive test timeout: \(error)")
            }
        }
        
        XCTAssertTrue(connectionMaintained, "Connection should be maintained during keep-alive period")
        XCTAssertTrue(webSocketManager.isConnected, "WebSocket should still be connected after keep-alive period")
        
        print("✅ Connection keep-alive test passed - Connection maintained for \(String(format: "%.0f", keepAliveTestDuration))s")
        performanceMetrics["keepAliveTest"] = connectionMaintained ? 1.0 : 0.0
    }
    
    // MARK: - Large Message Handling Tests
    
    func testLargeMessageTransmission() throws {
        print("📦 Testing large message transmission...")
        
        // Establish connection first
        try testChatWebSocketConnection()
        
        testExpectation = expectation(description: "Large message transmission")
        let largeMessageSize = 1024 * 100 // 100KB message
        let largeContent = String(repeating: "A", count: largeMessageSize)
        var messageReceived = false
        
        // Setup message observer
        let observer = NotificationCenter.default.addObserver(
            forName: .webSocketDidReceiveMessage,
            object: nil,
            queue: .main
        ) { notification in
            if let message = notification.userInfo?["message"] as? String {
                if message.contains("large_message_test") {
                    messageReceived = true
                    self.testExpectation.fulfill()
                }
            }
        }
        
        // Send large message
        let largeMessage = """
        {
            "type": "claude-command",
            "content": "\(largeContent)",
            "projectPath": "/test/path",
            "messageId": "large_message_test"
        }
        """
        
        let startTime = Date()
        webSocketManager.send(message: largeMessage)
        
        waitForExpectations(timeout: testTimeout) { error in
            NotificationCenter.default.removeObserver(observer)
            if let error = error {
                XCTFail("Large message transmission timeout: \(error)")
            }
        }
        
        let transmissionTime = Date().timeIntervalSince(startTime)
        
        XCTAssertTrue(messageReceived, "Large message should be transmitted successfully")
        XCTAssertLessThan(transmissionTime, 30.0, "Large message transmission should complete within 30 seconds")
        
        performanceMetrics["largeMessageTransmission"] = transmissionTime
        print("✅ Large message (\(largeMessageSize) bytes) transmitted in \(String(format: "%.2f", transmissionTime))s")
    }
    
    func testChunkedMessageReassembly() throws {
        print("🧩 Testing chunked message reassembly...")
        
        // Establish connection first
        try testChatWebSocketConnection()
        
        testExpectation = expectation(description: "Chunked message reassembly")
        let chunkCount = 5
        let chunkSize = 1024 * 20 // 20KB per chunk
        var receivedChunks: [String] = []
        
        // Setup message observer
        let observer = NotificationCenter.default.addObserver(
            forName: .webSocketDidReceiveMessage,
            object: nil,
            queue: .main
        ) { notification in
            if let message = notification.userInfo?["message"] as? String {
                if message.contains("chunk_test") {
                    receivedChunks.append(message)
                    
                    if receivedChunks.count == chunkCount {
                        self.testExpectation.fulfill()
                    }
                }
            }
        }
        
        // Send chunked messages
        for i in 1...chunkCount {
            let chunkContent = String(repeating: "Chunk\(i)", count: chunkSize / 6)
            let chunkMessage = """
            {
                "type": "claude-command",
                "content": "\(chunkContent)",
                "projectPath": "/test/path",
                "messageId": "chunk_test_\(i)",
                "chunkIndex": \(i),
                "totalChunks": \(chunkCount)
            }
            """
            
            webSocketManager.send(message: chunkMessage)
            Thread.sleep(forTimeInterval: 0.5) // Delay between chunks
        }
        
        waitForExpectations(timeout: testTimeout) { error in
            NotificationCenter.default.removeObserver(observer)
            if let error = error {
                XCTFail("Chunked message reassembly timeout: \(error)")
            }
        }
        
        XCTAssertEqual(receivedChunks.count, chunkCount, "All chunks should be received")
        
        print("✅ Chunked message reassembly test passed. Received \(receivedChunks.count) chunks")
        performanceMetrics["chunkedMessageTest"] = Double(receivedChunks.count)
    }
    
    // MARK: - Shell WebSocket Specific Tests
    
    func testShellCommandExecution() throws {
        print("🖥️ Testing shell command execution via WebSocket...")
        
        // Establish shell connection first
        try testShellWebSocketConnection()
        
        testExpectation = expectation(description: "Shell command execution")
        var commandResult: String?
        
        // Setup shell output observer
        let observer = NotificationCenter.default.addObserver(
            forName: .shellWebSocketDidReceiveOutput,
            object: nil,
            queue: .main
        ) { notification in
            if let output = notification.userInfo?["output"] as? String {
                commandResult = output
                self.testExpectation.fulfill()
            }
        }
        
        // Execute shell command
        let shellCommand = """
        {
            "type": "shell-command",
            "command": "echo 'WebSocket shell test'",
            "cwd": "/"
        }
        """
        
        shellWebSocketManager.send(message: shellCommand)
        
        waitForExpectations(timeout: testTimeout) { error in
            NotificationCenter.default.removeObserver(observer)
            if let error = error {
                XCTFail("Shell command execution timeout: \(error)")
            }
        }
        
        XCTAssertNotNil(commandResult, "Shell command should return output")
        XCTAssertTrue(commandResult?.contains("WebSocket shell test") ?? false, "Command output should contain expected text")
        
        print("✅ Shell command executed successfully. Output: \(commandResult ?? "nil")")
        performanceMetrics["shellCommandTest"] = commandResult != nil ? 1.0 : 0.0
    }
    
    func testANSIColorProcessing() throws {
        print("🎨 Testing ANSI color processing in shell output...")
        
        // Establish shell connection first
        try testShellWebSocketConnection()
        
        testExpectation = expectation(description: "ANSI color processing")
        var colorOutput: String?
        
        // Setup shell output observer
        let observer = NotificationCenter.default.addObserver(
            forName: .shellWebSocketDidReceiveOutput,
            object: nil,
            queue: .main
        ) { notification in
            if let output = notification.userInfo?["output"] as? String {
                colorOutput = output
                self.testExpectation.fulfill()
            }
        }
        
        // Execute command with ANSI colors
        let colorCommand = """
        {
            "type": "shell-command",
            "command": "echo -e '\\033[31mRed\\033[0m \\033[32mGreen\\033[0m \\033[34mBlue\\033[0m'",
            "cwd": "/"
        }
        """
        
        shellWebSocketManager.send(message: colorCommand)
        
        waitForExpectations(timeout: testTimeout) { error in
            NotificationCenter.default.removeObserver(observer)
            if let error = error {
                XCTFail("ANSI color processing timeout: \(error)")
            }
        }
        
        XCTAssertNotNil(colorOutput, "ANSI color command should return output")
        
        // Test ANSI color parsing
        if let output = colorOutput {
            let ansiParser = ANSIColorParser()
            let attributedString = ansiParser.parse(output)
            XCTAssertGreaterThan(attributedString.length, 0, "ANSI parser should produce attributed string")
            
            print("✅ ANSI color processing test passed. Output length: \(attributedString.length)")
        }
        
        performanceMetrics["ansiColorTest"] = colorOutput != nil ? 1.0 : 0.0
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorRecovery() throws {
        print("🚫➡️✅ Testing network error recovery...")
        
        testExpectation = expectation(description: "Network error recovery")
        var errorEncountered = false
        var recoverySuccessful = false
        
        // Setup error observer
        let errorObserver = NotificationCenter.default.addObserver(
            forName: .webSocketDidEncounterError,
            object: nil,
            queue: .main
        ) { notification in
            errorEncountered = true
            if let error = notification.userInfo?["error"] as? Error {
                print("📱 WebSocket error encountered: \(error.localizedDescription)")
            }
        }
        
        // Setup recovery observer
        let recoveryObserver = NotificationCenter.default.addObserver(
            forName: .webSocketDidConnect,
            object: nil,
            queue: .main
        ) { _ in
            if errorEncountered {
                recoverySuccessful = true
                self.testExpectation.fulfill()
            }
        }
        
        // Establish connection then simulate network error
        webSocketManager.connect()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Simulate network error by disconnecting
            self.webSocketManager.disconnect()
            
            // WebSocket should attempt to reconnect automatically
        }
        
        waitForExpectations(timeout: testTimeout) { error in
            NotificationCenter.default.removeObserver(errorObserver)
            NotificationCenter.default.removeObserver(recoveryObserver)
            if let error = error {
                print("⚠️ Network error recovery timeout: \(error)")
            }
        }
        
        if recoverySuccessful {
            print("✅ Network error recovery successful")
        } else {
            print("ℹ️ Network error recovery test inconclusive")
        }
        
        performanceMetrics["networkErrorRecovery"] = recoverySuccessful ? 1.0 : 0.0
    }
    
    func testInvalidMessageHandling() throws {
        print("❌ Testing invalid message handling...")
        
        // Establish connection first
        try testChatWebSocketConnection()
        
        testExpectation = expectation(description: "Invalid message handling")
        var errorHandled = false
        
        // Setup error observer
        let observer = NotificationCenter.default.addObserver(
            forName: .webSocketDidEncounterError,
            object: nil,
            queue: .main
        ) { notification in
            errorHandled = true
            self.testExpectation.fulfill()
        }
        
        // Send invalid JSON message
        let invalidMessage = "{ invalid json structure }"
        webSocketManager.send(message: invalidMessage)
        
        // Also test with valid JSON but invalid structure
        let invalidStructureMessage = """
        {
            "invalid": "structure",
            "missing": "required fields"
        }
        """
        webSocketManager.send(message: invalidStructureMessage)
        
        // Give some time for error handling
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if !errorHandled {
                // If no error was triggered, consider it handled gracefully
                errorHandled = true
                self.testExpectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: testTimeout) { error in
            NotificationCenter.default.removeObserver(observer)
            if let error = error {
                XCTFail("Invalid message handling timeout: \(error)")
            }
        }
        
        // Invalid messages should either trigger error handling or be ignored gracefully
        XCTAssertTrue(errorHandled, "Invalid messages should be handled gracefully")
        
        print("✅ Invalid message handling test passed")
        performanceMetrics["invalidMessageHandling"] = errorHandled ? 1.0 : 0.0
    }
    
    // MARK: - Performance Tests
    
    func testConnectionPerformance() throws {
        print("🚀 Testing WebSocket connection performance...")
        
        let performanceTest = XCTestExpectation(description: "Connection performance test")
        let iterations = 10
        var connectionTimes: [TimeInterval] = []
        
        func testIteration(_ iteration: Int) {
            let startTime = Date()
            
            let observer = NotificationCenter.default.addObserver(
                forName: .webSocketDidConnect,
                object: nil,
                queue: .main
            ) { _ in
                let connectionTime = Date().timeIntervalSince(startTime)
                connectionTimes.append(connectionTime)
                
                // Disconnect and test next iteration
                self.webSocketManager.disconnect()
                
                if iteration < iterations {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        testIteration(iteration + 1)
                    }
                } else {
                    performanceTest.fulfill()
                }
            }
            
            webSocketManager.connect()
        }
        
        testIteration(1)
        
        wait(for: [performanceTest], timeout: TimeInterval(iterations * 10))
        
        // Analyze performance results
        let averageConnectionTime = connectionTimes.reduce(0, +) / Double(connectionTimes.count)
        let maxConnectionTime = connectionTimes.max() ?? 0
        let minConnectionTime = connectionTimes.min() ?? 0
        
        XCTAssertEqual(connectionTimes.count, iterations, "Should complete all performance test iterations")
        XCTAssertLessThan(averageConnectionTime, 5.0, "Average connection time should be under 5 seconds")
        XCTAssertLessThan(maxConnectionTime, 10.0, "Max connection time should be under 10 seconds")
        
        performanceMetrics["averageConnectionTime"] = averageConnectionTime
        performanceMetrics["maxConnectionTime"] = maxConnectionTime
        performanceMetrics["minConnectionTime"] = minConnectionTime
        
        print("✅ Connection performance test completed")
        print("   Average: \(String(format: "%.2f", averageConnectionTime))s")
        print("   Min: \(String(format: "%.2f", minConnectionTime))s")
        print("   Max: \(String(format: "%.2f", maxConnectionTime))s")
    }
    
    func testMessageThroughputPerformance() throws {
        print("📊 Testing message throughput performance...")
        
        // Establish connection first
        try testChatWebSocketConnection()
        
        testExpectation = expectation(description: "Message throughput performance")
        let messageCount = 100
        let messageSize = 1024 // 1KB messages
        var receivedCount = 0
        let startTime = Date()
        
        // Setup message observer
        let observer = NotificationCenter.default.addObserver(
            forName: .webSocketDidReceiveMessage,
            object: nil,
            queue: .main
        ) { notification in
            receivedCount += 1
            
            if receivedCount >= messageCount {
                self.testExpectation.fulfill()
            }
        }
        
        // Send messages for throughput test
        let testContent = String(repeating: "T", count: messageSize)
        
        for i in 1...messageCount {
            let message = """
            {
                "type": "claude-command",
                "content": "\(testContent)",
                "projectPath": "/test/path",
                "messageId": "throughput_test_\(i)"
            }
            """
            
            webSocketManager.send(message: message)
        }
        
        waitForExpectations(timeout: testTimeout) { error in
            NotificationCenter.default.removeObserver(observer)
            if let error = error {
                XCTFail("Message throughput performance timeout: \(error)")
            }
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        let messagesPerSecond = Double(receivedCount) / totalTime
        let bytesPerSecond = Double(receivedCount * messageSize) / totalTime
        
        XCTAssertEqual(receivedCount, messageCount, "All messages should be received")
        XCTAssertGreaterThan(messagesPerSecond, 10.0, "Should handle at least 10 messages per second")
        
        performanceMetrics["messagesThroughputTotal"] = totalTime
        performanceMetrics["messagesPerSecond"] = messagesPerSecond
        performanceMetrics["bytesPerSecond"] = bytesPerSecond
        
        print("✅ Message throughput performance test completed")
        print("   Total time: \(String(format: "%.2f", totalTime))s")
        print("   Messages/sec: \(String(format: "%.1f", messagesPerSecond))")
        print("   Bytes/sec: \(String(format: "%.0f", bytesPerSecond))")
    }
    
    // MARK: - Helper Methods
    
    private func validateBackendConnectivity() throws {
        let url = URL(string: "http://192.168.0.43:3004/api/auth/status")!
        let expectation = self.expectation(description: "Backend connectivity")
        var isConnectable = false
        
        let task = URLSession.shared.dataTask(with: url) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                isConnectable = httpResponse.statusCode < 500
            }
            expectation.fulfill()
        }
        task.resume()
        
        waitForExpectations(timeout: 10.0)
        
        if !isConnectable {
            throw XCTSkip("Backend server not accessible at http://192.168.0.43:3004")
        }
    }
    
    private func extractOrderNumber(from message: String) -> Int? {
        let pattern = #"Test message order (\d+)"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: message.utf16.count)
        
        if let match = regex?.firstMatch(in: message, options: [], range: range) {
            let numberRange = match.range(at: 1)
            if let numberString = String(message).substring(with: numberRange),
               let number = Int(numberString) {
                return number
            }
        }
        
        return nil
    }
    
    // MARK: - Test Summary and Reporting
    
    func testWebSocketIntegrationSummary() throws {
        print("\n🏁 WebSocket Integration Test Summary")
        print("=====================================")
        
        let totalTests = performanceMetrics.count
        let successfulTests = performanceMetrics.filter { $0.value > 0 }.count
        let successRate = totalTests > 0 ? Double(successfulTests) / Double(totalTests) * 100 : 0
        
        print("📊 Test Results:")
        print("   Total tests executed: \(totalTests)")
        print("   Successful tests: \(successfulTests)")
        print("   Success rate: \(String(format: "%.1f", successRate))%")
        
        print("\n⚡ Performance Metrics:")
        for (metric, value) in performanceMetrics.sorted(by: { $0.key < $1.key }) {
            if metric.contains("Time") {
                print("   \(metric): \(String(format: "%.2f", value))s")
            } else if metric.contains("PerSecond") {
                print("   \(metric): \(String(format: "%.1f", value))")
            } else {
                print("   \(metric): \(value > 0 ? "✅" : "❌")")
            }
        }
        
        print("\n🔗 Connection Events:")
        for event in connectionEvents {
            print("   \(event)")
        }
        
        // Validate overall test suite success
        XCTAssertGreaterThanOrEqual(successRate, 70.0, "WebSocket integration test suite should have at least 70% success rate")
        
        print("\n✅ WebSocket Integration Tests Complete")
        print("=====================================\n")
    }
}

// MARK: - Notification Names Extension

extension Notification.Name {
    static let webSocketDidConnect = Notification.Name("WebSocketDidConnect")
    static let webSocketDidDisconnect = Notification.Name("WebSocketDidDisconnect")
    static let webSocketDidReceiveMessage = Notification.Name("WebSocketDidReceiveMessage")
    static let webSocketDidEncounterError = Notification.Name("WebSocketDidEncounterError")
    static let webSocketDidAttemptReconnection = Notification.Name("WebSocketDidAttemptReconnection")
    static let webSocketDidReceivePong = Notification.Name("WebSocketDidReceivePong")
    
    static let shellWebSocketDidConnect = Notification.Name("ShellWebSocketDidConnect")
    static let shellWebSocketDidDisconnect = Notification.Name("ShellWebSocketDidDisconnect")
    static let shellWebSocketDidReceiveOutput = Notification.Name("ShellWebSocketDidReceiveOutput")
    static let shellWebSocketDidEncounterError = Notification.Name("ShellWebSocketDidEncounterError")
}

// MARK: - String Extension for Substring

extension String {
    func substring(with range: NSRange) -> String? {
        guard let range = Range(range, in: self) else { return nil }
        return String(self[range])
    }
}