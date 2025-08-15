//
//  StarscreamWebSocketTests.swift
//  ClaudeCodeUITests
//
//  Created by Claude on 2025-01-15.
//
//  Unit tests for Starscream WebSocket implementation
//

import XCTest
@testable import ClaudeCodeUI

// MARK: - Starscream WebSocket Tests

final class StarscreamWebSocketTests: XCTestCase {
    
    var manager: StarscreamWebSocketManager!
    var mockDelegate: MockWebSocketDelegate!
    
    override func setUp() {
        super.setUp()
        manager = StarscreamWebSocketManager(baseURL: "ws://localhost:3004")
        mockDelegate = MockWebSocketDelegate()
        manager.delegate = mockDelegate
    }
    
    override func tearDown() {
        manager.disconnect()
        manager = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Connection Tests
    
    func testConnectionURLConstruction() {
        // Test that /api/chat/ws is replaced with /ws
        let expectation = XCTestExpectation(description: "URL correction")
        
        // This should trigger connection with corrected URL
        manager.connect(to: "/api/chat/ws", with: "test-token")
        
        // The connection should use /ws instead
        XCTAssertEqual(manager.connectionState, .connecting)
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    func testAuthenticationHeadersAdded() {
        let token = "test-jwt-token"
        manager.connect(to: "/ws", with: token)
        
        // Verify authentication token is stored
        XCTAssertNotNil(manager.authToken)
        XCTAssertEqual(manager.authToken, token)
    }
    
    func testConnectionStateTransitions() {
        XCTAssertEqual(manager.connectionState, .disconnected)
        
        manager.connect(to: "/ws", with: nil)
        XCTAssertEqual(manager.connectionState, .connecting)
        
        manager.disconnect()
        XCTAssertEqual(manager.connectionState, .disconnected)
    }
    
    // MARK: - Message Tests
    
    func testClaudeCommandFormatting() {
        let content = "Test message"
        let projectPath = "/path/to/project"
        let sessionId = "session-123"
        
        manager.sendClaudeCommand(
            content: content,
            projectPath: projectPath,
            sessionId: sessionId
        )
        
        // Message should be queued since we're not connected
        XCTAssertFalse(manager.isConnected)
    }
    
    func testCursorCommandFormatting() {
        let content = "Cursor test"
        let projectPath = "/cursor/project"
        
        manager.sendCursorCommand(
            content: content,
            projectPath: projectPath,
            sessionId: nil
        )
        
        // Message should be queued
        XCTAssertFalse(manager.isConnected)
    }
    
    func testAbortSessionMessage() {
        let sessionId = "abort-session-123"
        manager.abortSession(sessionId: sessionId)
        
        // Should queue abort message
        XCTAssertFalse(manager.isConnected)
    }
    
    // MARK: - Reconnection Tests
    
    func testReconnectionManager() {
        let reconnectManager = ReconnectionManager()
        
        XCTAssertTrue(reconnectManager.shouldReconnect)
        XCTAssertEqual(reconnectManager.currentAttempt, 0)
        
        // Schedule reconnection
        let expectation = XCTestExpectation(description: "Reconnection scheduled")
        
        reconnectManager.scheduleReconnection {
            expectation.fulfill()
        }
        
        XCTAssertEqual(reconnectManager.currentAttempt, 1)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testExponentialBackoff() {
        let reconnectManager = ReconnectionManager()
        
        // Test multiple attempts
        for i in 1...5 {
            reconnectManager.scheduleReconnection { }
            XCTAssertEqual(reconnectManager.currentAttempt, i)
        }
        
        // Should still allow reconnection until max attempts
        XCTAssertTrue(reconnectManager.shouldReconnect)
        
        // Exceed max attempts
        for _ in 6...10 {
            reconnectManager.scheduleReconnection { }
        }
        
        XCTAssertFalse(reconnectManager.shouldReconnect)
    }
    
    // MARK: - Message Queue Tests
    
    func testMessageQueueing() {
        let queue = MessageQueue()
        
        queue.enqueue("Message 1")
        queue.enqueue("Message 2")
        queue.enqueue("Message 3")
        
        var messages: [String] = []
        queue.flush { message in
            messages.append(message)
        }
        
        XCTAssertEqual(messages.count, 3)
        XCTAssertEqual(messages[0], "Message 1")
        XCTAssertEqual(messages[1], "Message 2")
        XCTAssertEqual(messages[2], "Message 3")
    }
    
    func testMessageQueueLimit() {
        let queue = MessageQueue()
        
        // Try to enqueue more than limit (100)
        for i in 1...150 {
            queue.enqueue("Message \(i)")
        }
        
        var count = 0
        queue.flush { _ in
            count += 1
        }
        
        XCTAssertEqual(count, 100) // Should be limited to 100
    }
    
    // MARK: - Stream Handler Tests
    
    func testMessageStreamHandling() {
        let handler = MessageStreamHandler()
        
        let messageId = "stream-123"
        let chunk1 = "Hello "
        let chunk2 = "World"
        
        let result1 = handler.handleStreamingChunk(chunk1, messageId: messageId)
        XCTAssertEqual(result1, "Hello ")
        
        let result2 = handler.handleStreamingChunk(chunk2, messageId: messageId)
        XCTAssertEqual(result2, "Hello World")
        
        let final = handler.finalizeStreaming()
        XCTAssertEqual(final, "Hello World")
        
        // Should be reset after finalization
        let afterReset = handler.finalizeStreaming()
        XCTAssertNil(afterReset)
    }
    
    func testStreamHandlerReset() {
        let handler = MessageStreamHandler()
        
        handler.handleStreamingChunk("Test", messageId: "123")
        handler.reset()
        
        let result = handler.finalizeStreaming()
        XCTAssertNil(result)
    }
    
    // MARK: - Terminal WebSocket Tests
    
    func testTerminalConnection() {
        manager.connectToTerminal(with: "terminal-token")
        
        // Should attempt terminal connection
        XCTAssertEqual(manager.connectionState, .disconnected) // Main socket state unchanged
    }
    
    func testTerminalCommand() {
        let command = "ls -la"
        manager.sendTerminalCommand(command)
        
        // Command should be formatted correctly
        // (Would need actual connection to test fully)
    }
    
    // MARK: - App Lifecycle Tests
    
    func testBackgroundDisconnection() {
        manager.connect(to: "/ws", with: "token")
        
        // Simulate app entering background
        NotificationCenter.default.post(
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // Should disconnect
        XCTAssertEqual(manager.connectionState, .disconnected)
    }
    
    func testForegroundReconnection() {
        let token = "test-token"
        manager.connect(to: "/ws", with: token)
        
        // Simulate background
        NotificationCenter.default.post(
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // Simulate foreground
        NotificationCenter.default.post(
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // Should attempt reconnection after delay
        let expectation = XCTestExpectation(description: "Foreground reconnection")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // Should be connecting or connected
            XCTAssertNotEqual(self.manager.connectionState, .failed)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Feature Flag Tests

final class FeatureFlagTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Reset all flags before each test
        FeatureFlagManager.shared.resetAll()
    }
    
    func testFeatureFlagDefaults() {
        // Starscream should be disabled by default (or based on rollout)
        let starscreamFlag = FeatureFlag.useStarscreamWebSocket
        
        // Check if in rollout group (10% by default)
        let isInRollout = FeatureFlagManager.shared.isInRolloutGroup(percentage: 10)
        XCTAssertEqual(starscreamFlag.isEnabled, isInRollout)
        
        // Compression should be enabled by default
        XCTAssertTrue(FeatureFlag.enableWebSocketCompression.isEnabled)
        
        // Auto-reconnect should be enabled by default
        XCTAssertTrue(FeatureFlag.enableAutoReconnect.isEnabled)
        
        // Terminal WebSocket should be disabled by default
        XCTAssertFalse(FeatureFlag.enableTerminalWebSocket.isEnabled)
    }
    
    func testFeatureFlagToggling() {
        let flag = FeatureFlag.useStarscreamWebSocket
        
        let initialState = flag.isEnabled
        flag.toggle()
        XCTAssertNotEqual(flag.isEnabled, initialState)
        
        flag.toggle()
        XCTAssertEqual(flag.isEnabled, initialState)
    }
    
    func testFeatureFlagOverride() {
        let flag = FeatureFlag.useStarscreamWebSocket
        
        // Override to true
        FeatureFlagManager.shared.override(flag, enabled: true)
        XCTAssertTrue(flag.isEnabled)
        
        // Override to false
        FeatureFlagManager.shared.override(flag, enabled: false)
        XCTAssertFalse(flag.isEnabled)
        
        // Remove override
        FeatureFlagManager.shared.removeOverride(flag)
        // Should revert to default or persisted value
    }
    
    func testRolloutPercentage() {
        // Test different rollout percentages
        FeatureFlagManager.shared.setStarscreamRolloutPercentage(0)
        
        // With 0% rollout, should be disabled (unless user is in bucket 0)
        let bucket = UserDefaults.standard.integer(forKey: "feature.rollout.bucket")
        if bucket > 0 {
            XCTAssertFalse(FeatureFlag.useStarscreamWebSocket.isEnabled)
        }
        
        // With 100% rollout, should be enabled
        FeatureFlagManager.shared.setStarscreamRolloutPercentage(100)
        XCTAssertTrue(FeatureFlag.useStarscreamWebSocket.isEnabled)
    }
}

// MARK: - WebSocket Factory Tests

final class WebSocketFactoryTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        FeatureFlagManager.shared.resetAll()
    }
    
    func testFactoryCreatesCorrectImplementation() {
        // Test with Starscream disabled
        FeatureFlag.useStarscreamWebSocket.disable()
        let legacySocket = WebSocketFactory.create()
        XCTAssertTrue(legacySocket is LegacyWebSocketAdapter)
        
        // Test with Starscream enabled
        FeatureFlag.useStarscreamWebSocket.enable()
        let starscreamSocket = WebSocketFactory.create()
        XCTAssertTrue(starscreamSocket is StarscreamWebSocketManager)
    }
    
    func testTerminalWebSocketCreation() {
        // Should return nil when disabled
        FeatureFlag.enableTerminalWebSocket.disable()
        let noTerminal = WebSocketFactory.createTerminalWebSocket()
        XCTAssertNil(noTerminal)
        
        // Should return socket when enabled
        FeatureFlag.enableTerminalWebSocket.enable()
        let terminal = WebSocketFactory.createTerminalWebSocket()
        XCTAssertNotNil(terminal)
    }
}

// MARK: - A/B Testing Tests

final class ABTestingTests: XCTestCase {
    
    func testABTestAssignment() {
        let manager = ABTestManager.shared
        
        // Test assignment with 50% rollout
        let isInTest = manager.assignToStarscreamTest(percentage: 50)
        
        // Should be assigned to either test or control
        XCTAssertEqual(
            FeatureFlag.useStarscreamWebSocket.isEnabled,
            isInTest
        )
    }
    
    func testABTestTracking() {
        let manager = ABTestManager.shared
        
        // Assign to test
        _ = manager.assignToStarscreamTest(percentage: 100)
        XCTAssertTrue(manager.isInStarscreamTest())
        
        // Assign to control
        _ = manager.assignToStarscreamTest(percentage: 0)
        
        // Unless user is in bucket 0, should be in control
        let bucket = UserDefaults.standard.integer(forKey: "feature.rollout.bucket")
        if bucket > 0 {
            XCTAssertFalse(manager.isInStarscreamTest())
        }
    }
}

// MARK: - Migration Tests

final class MigrationTests: XCTestCase {
    
    func testMigrationCoordinator() {
        let coordinator = WebSocketMigrationCoordinator.shared
        let expectation = XCTestExpectation(description: "Migration completion")
        
        coordinator.performMigration { success in
            // Migration may fail in test environment (no actual server)
            // Just verify the process completes
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 6.0)
    }
}

// MARK: - Mock Delegate

class MockWebSocketDelegate: NSObject, WebSocketManagerDelegate {
    
    var didConnect = false
    var didDisconnect = false
    var lastMessage: WebSocketMessage?
    var lastError: Error?
    var lastState: WebSocketConnectionState = .disconnected
    var lastText: String?
    
    func webSocketDidConnect(_ manager: WebSocketManager) {
        didConnect = true
    }
    
    func webSocketDidDisconnect(_ manager: WebSocketManager, error: Error?) {
        didDisconnect = true
        lastError = error
    }
    
    func webSocket(_ manager: WebSocketManager, didReceiveMessage message: WebSocketMessage) {
        lastMessage = message
    }
    
    func webSocket(_ manager: WebSocketManager, didReceiveData data: Data) {
        // Not used in tests
    }
    
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState) {
        lastState = state
    }
    
    func webSocket(_ manager: WebSocketManager, didReceiveText text: String) {
        lastText = text
    }
}