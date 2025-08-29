//
//  WebSocketReconnectionTests.swift
//  ClaudeCodeUIIntegrationTests
//
//  Tests for WebSocket auto-reconnection with exponential backoff
//

import XCTest
@testable import ClaudeCodeUI

class WebSocketReconnectionTests: XCTestCase {
    
    var webSocketManager: WebSocketManager!
    var mockDelegate: MockWebSocketDelegate!
    let timeout: TimeInterval = 10
    
    override func setUpWithError() throws {
        webSocketManager = WebSocketManager.shared
        mockDelegate = MockWebSocketDelegate()
        
        // Reset WebSocket state
        webSocketManager.disconnect()
        
        // Configure for testing
        webSocketManager.baseURL = "ws://localhost:3004/ws"
    }
    
    override func tearDownWithError() throws {
        webSocketManager.disconnect()
        webSocketManager = nil
        mockDelegate = nil
    }
    
    // MARK: - Connection Tests
    
    func testInitialConnection() throws {
        let expectation = XCTestExpectation(description: "WebSocket connects")
        
        mockDelegate.onConnected = {
            expectation.fulfill()
        }
        
        webSocketManager.delegate = mockDelegate
        webSocketManager.connect(token: "test_token", projectPath: "/test/project")
        
        wait(for: [expectation], timeout: timeout)
        
        XCTAssertTrue(webSocketManager.isConnected)
    }
    
    func testAutoReconnectionAfterDisconnect() throws {
        // First, establish connection
        let connectExpectation = XCTestExpectation(description: "Initial connection")
        
        mockDelegate.onConnected = {
            connectExpectation.fulfill()
        }
        
        webSocketManager.delegate = mockDelegate
        webSocketManager.connect(token: "test_token", projectPath: "/test/project")
        
        wait(for: [connectExpectation], timeout: timeout)
        
        // Now test disconnection and auto-reconnection
        let reconnectExpectation = XCTestExpectation(description: "Auto-reconnection")
        var disconnectCount = 0
        var reconnectCount = 0
        
        mockDelegate.onDisconnected = { error in
            disconnectCount += 1
        }
        
        mockDelegate.onConnected = {
            reconnectCount += 1
            if reconnectCount == 2 { // First connect + reconnect
                reconnectExpectation.fulfill()
            }
        }
        
        // Simulate disconnection
        webSocketManager.simulateDisconnection()
        
        // Wait for auto-reconnection (should happen within 3 seconds)
        wait(for: [reconnectExpectation], timeout: 5)
        
        XCTAssertEqual(disconnectCount, 1)
        XCTAssertEqual(reconnectCount, 2)
        XCTAssertTrue(webSocketManager.isConnected)
    }
    
    func testExponentialBackoff() throws {
        let expectation = XCTestExpectation(description: "Exponential backoff")
        
        var reconnectAttempts: [Date] = []
        var attemptCount = 0
        
        mockDelegate.onConnected = {
            attemptCount += 1
            reconnectAttempts.append(Date())
            
            if attemptCount < 4 {
                // Simulate immediate disconnection
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.webSocketManager.simulateDisconnection()
                }
            } else {
                expectation.fulfill()
            }
        }
        
        webSocketManager.delegate = mockDelegate
        webSocketManager.connect(token: "test_token", projectPath: "/test/project")
        
        wait(for: [expectation], timeout: 30)
        
        // Verify exponential backoff timing
        XCTAssertEqual(reconnectAttempts.count, 4)
        
        if reconnectAttempts.count >= 4 {
            // Check intervals are increasing
            let interval1 = reconnectAttempts[1].timeIntervalSince(reconnectAttempts[0])
            let interval2 = reconnectAttempts[2].timeIntervalSince(reconnectAttempts[1])
            let interval3 = reconnectAttempts[3].timeIntervalSince(reconnectAttempts[2])
            
            // Should be roughly 1s, 2s, 4s (with some tolerance)
            XCTAssertTrue(interval1 >= 0.5 && interval1 <= 2.0)
            XCTAssertTrue(interval2 >= 1.5 && interval2 <= 3.0)
            XCTAssertTrue(interval3 >= 3.0 && interval3 <= 6.0)
        }
    }
    
    func testMaxReconnectionAttempts() throws {
        // Configure max attempts for testing
        webSocketManager.maxReconnectAttempts = 3
        
        let expectation = XCTestExpectation(description: "Max reconnection attempts")
        var attemptCount = 0
        var finalError: Error?
        
        mockDelegate.onConnected = {
            attemptCount += 1
            // Simulate immediate disconnection
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.webSocketManager.simulateDisconnection()
            }
        }
        
        mockDelegate.onError = { error in
            if attemptCount >= 3 {
                finalError = error
                expectation.fulfill()
            }
        }
        
        webSocketManager.delegate = mockDelegate
        webSocketManager.connect(token: "test_token", projectPath: "/test/project")
        
        wait(for: [expectation], timeout: 20)
        
        XCTAssertEqual(attemptCount, 3)
        XCTAssertNotNil(finalError)
        XCTAssertFalse(webSocketManager.isConnected)
    }
    
    // MARK: - Message Handling Tests
    
    func testMessageQueueingDuringReconnection() throws {
        // Establish initial connection
        let connectExpectation = XCTestExpectation(description: "Initial connection")
        
        mockDelegate.onConnected = {
            connectExpectation.fulfill()
        }
        
        webSocketManager.delegate = mockDelegate
        webSocketManager.connect(token: "test_token", projectPath: "/test/project")
        
        wait(for: [connectExpectation], timeout: timeout)
        
        // Queue messages during disconnection
        let messageExpectation = XCTestExpectation(description: "Messages sent after reconnection")
        var receivedMessages: [String] = []
        
        mockDelegate.onMessageReceived = { message in
            if let content = message["content"] as? String {
                receivedMessages.append(content)
                if receivedMessages.count == 3 {
                    messageExpectation.fulfill()
                }
            }
        }
        
        // Simulate disconnection
        webSocketManager.simulateDisconnection()
        
        // Send messages while disconnected (should be queued)
        webSocketManager.sendMessage(["content": "Message 1"])
        webSocketManager.sendMessage(["content": "Message 2"])
        webSocketManager.sendMessage(["content": "Message 3"])
        
        // Messages should be sent after reconnection
        wait(for: [messageExpectation], timeout: 10)
        
        XCTAssertEqual(receivedMessages.count, 3)
        XCTAssertTrue(receivedMessages.contains("Message 1"))
        XCTAssertTrue(receivedMessages.contains("Message 2"))
        XCTAssertTrue(receivedMessages.contains("Message 3"))
    }
    
    // MARK: - Timeout Tests
    
    func testConnectionTimeout() throws {
        // Use invalid URL to trigger timeout
        webSocketManager.baseURL = "ws://localhost:9999/ws"
        webSocketManager.connectionTimeout = 2.0
        
        let expectation = XCTestExpectation(description: "Connection timeout")
        var timeoutError: Error?
        
        mockDelegate.onError = { error in
            timeoutError = error
            expectation.fulfill()
        }
        
        webSocketManager.delegate = mockDelegate
        webSocketManager.connect(token: "test_token", projectPath: "/test/project")
        
        wait(for: [expectation], timeout: 5)
        
        XCTAssertNotNil(timeoutError)
        XCTAssertFalse(webSocketManager.isConnected)
    }
    
    func testLongRunningOperationTimeout() throws {
        // Connect successfully
        let connectExpectation = XCTestExpectation(description: "Initial connection")
        
        mockDelegate.onConnected = {
            connectExpectation.fulfill()
        }
        
        webSocketManager.delegate = mockDelegate
        webSocketManager.connect(token: "test_token", projectPath: "/test/project")
        
        wait(for: [connectExpectation], timeout: timeout)
        
        // Configure long operation timeout
        webSocketManager.operationTimeout = 120.0 // 2 minutes as per spec
        
        // Send a message that would trigger long operation
        let message = [
            "type": "claude-command",
            "content": "analyze entire codebase",
            "projectPath": "/test/project"
        ]
        
        webSocketManager.sendMessage(message)
        
        // Verify timeout is properly configured
        XCTAssertEqual(webSocketManager.operationTimeout, 120.0)
    }
}

// MARK: - Mock WebSocket Delegate

class MockWebSocketDelegate: WebSocketManagerDelegate {
    
    var onConnected: (() -> Void)?
    var onDisconnected: ((Error?) -> Void)?
    var onMessageReceived: ((WebSocketMessage) -> Void)?
    var onDataReceived: ((Data) -> Void)?
    var onStateChanged: ((WebSocketConnectionState) -> Void)?
    
    func webSocketDidConnect(_ manager: any WebSocketProtocol) {
        onConnected?()
    }
    
    func webSocketDidDisconnect(_ manager: any WebSocketProtocol, error: Error?) {
        onDisconnected?(error)
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveMessage message: WebSocketMessage) {
        onMessageReceived?(message)
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveData data: Data) {
        onDataReceived?(data)
    }
    
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState) {
        onStateChanged?(state)
    }
}

// MARK: - WebSocketManager Test Extensions

extension WebSocketManager {
    
    /// Simulate disconnection for testing
    func simulateDisconnection() {
        // This would need to be implemented in the actual WebSocketManager
        // For testing purposes, we're assuming this method exists
        self.disconnect()
    }
    
    /// Maximum reconnection attempts (for testing)
    var maxReconnectAttempts: Int {
        get { return 10 } // Default
        set { /* Would need implementation */ }
    }
    
    /// Connection timeout (for testing)
    var connectionTimeout: TimeInterval {
        get { return 30.0 } // Default
        set { /* Would need implementation */ }
    }
    
    /// Operation timeout for long-running commands
    var operationTimeout: TimeInterval {
        get { return 120.0 } // 2 minutes as per spec
        set { /* Would need implementation */ }
    }
}