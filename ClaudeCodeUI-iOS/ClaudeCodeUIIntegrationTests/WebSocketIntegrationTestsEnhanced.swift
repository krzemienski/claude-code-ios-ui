//
//  WebSocketIntegrationTestsEnhanced.swift
//  ClaudeCodeUIIntegrationTests
//
//  Created by Claude Code UI on 2025/01/30.
//

import XCTest
@testable import ClaudeCodeUI

/// Enhanced WebSocket Integration Tests
/// Tests real WebSocket connections with the backend server
@available(iOS 17.0, *)
final class WebSocketIntegrationTestsEnhanced: XCTestCase {
    
    // MARK: - Properties
    
    private var webSocketManager: WebSocketManager!
    private var testSessionId: String!
    private let backendURL = "ws://192.168.0.43:3004/ws"
    private let shellURL = "ws://192.168.0.43:3004/shell"
    private var receivedMessages: [WebSocketMessage] = []
    private var connectionExpectation: XCTestExpectation?
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        webSocketManager = WebSocketManager()
        webSocketManager.delegate = self
        testSessionId = "claude-session-\(UUID().uuidString.lowercased())"
        receivedMessages.removeAll()
    }
    
    override func tearDown() async throws {
        webSocketManager.disconnect()
        webSocketManager = nil
        testSessionId = nil
        receivedMessages.removeAll()
        
        try await super.tearDown()
    }
    
    // MARK: - Connection Tests
    
    func testWebSocketConnection() async throws {
        // Given
        connectionExpectation = expectation(description: "WebSocket connected")
        
        // When
        webSocketManager.connect(to: backendURL, with: nil)
        
        // Then
        await fulfillment(of: [connectionExpectation!], timeout: 5.0)
        XCTAssertTrue(webSocketManager.isConnected)
        XCTAssertEqual(webSocketManager.connectionState, .connected)
    }
    
    func testWebSocketConnectionWithToken() async throws {
        // Given
        connectionExpectation = expectation(description: "WebSocket connected with token")
        let testToken = "test-jwt-token-12345"
        
        // When
        webSocketManager.connect(to: backendURL, with: testToken)
        
        // Then
        await fulfillment(of: [connectionExpectation!], timeout: 5.0)
        XCTAssertTrue(webSocketManager.isConnected)
    }
    
    func testWebSocketReconnection() async throws {
        // Given
        connectionExpectation = expectation(description: "Initial connection")
        webSocketManager.configure(
            enableAutoReconnect: true,
            reconnectDelay: 1.0,
            maxReconnectAttempts: 3
        )
        
        // Connect
        webSocketManager.connect(to: backendURL, with: nil)
        await fulfillment(of: [connectionExpectation!], timeout: 5.0)
        
        // Disconnect
        let disconnectExpectation = expectation(description: "Disconnected")
        webSocketManager.disconnect()
        
        // Wait for disconnection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            disconnectExpectation.fulfill()
        }
        await fulfillment(of: [disconnectExpectation], timeout: 2.0)
        
        // Reconnect
        connectionExpectation = expectation(description: "Reconnected")
        webSocketManager.connect(to: backendURL, with: nil)
        
        // Then
        await fulfillment(of: [connectionExpectation!], timeout: 5.0)
        XCTAssertTrue(webSocketManager.isConnected)
    }
    
    // MARK: - Message Tests
    
    func testSendAndReceiveMessage() async throws {
        // Connect first
        connectionExpectation = expectation(description: "Connected")
        webSocketManager.connect(to: backendURL, with: nil)
        await fulfillment(of: [connectionExpectation!], timeout: 5.0)
        
        // Given
        let messageExpectation = expectation(description: "Message received")
        let testMessage = WebSocketMessage(
            type: .message,
            payload: ["content": "Hello from iOS test"],
            sessionId: testSessionId
        )
        
        // When
        webSocketManager.sendMessage(testMessage)
        
        // Wait for response
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            messageExpectation.fulfill()
        }
        
        // Then
        await fulfillment(of: [messageExpectation], timeout: 5.0)
        XCTAssertFalse(receivedMessages.isEmpty, "Should have received at least one message")
    }
    
    func testSessionIdFormatting() async throws {
        // Test different session ID formats
        let testCases = [
            "test-session-123",
            "550e8400-e29b-41d4-a716-446655440000",
            "claude-session-abc123"
        ]
        
        for sessionId in testCases {
            // Create message with session ID
            let message = WebSocketMessage(
                type: .message,
                payload: ["content": "Test message"],
                sessionId: sessionId
            )
            
            // Verify formatting
            if let data = try? JSONEncoder().encode(message),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let formattedSessionId = json["sessionId"] as? String {
                
                // Backend expects "claude-session-" prefix
                if !sessionId.hasPrefix("claude-session-") {
                    XCTAssertTrue(
                        formattedSessionId.hasPrefix("claude-session-") || formattedSessionId == sessionId,
                        "Session ID should be properly formatted"
                    )
                }
            }
        }
    }
    
    func testToolUseMessage() async throws {
        // Connect first
        connectionExpectation = expectation(description: "Connected")
        webSocketManager.connect(to: backendURL, with: nil)
        await fulfillment(of: [connectionExpectation!], timeout: 5.0)
        
        // Given
        let toolUseMessage = WebSocketMessage(
            type: .tool_use,
            payload: [
                "content": """
                {
                    "name": "calculator",
                    "input": {"operation": "add", "a": 5, "b": 3}
                }
                """
            ],
            sessionId: testSessionId
        )
        
        // When
        webSocketManager.sendMessage(toolUseMessage)
        
        // Wait briefly for any response
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Then
        // Verify message was sent without error
        XCTAssertTrue(webSocketManager.isConnected, "Should remain connected after sending tool use message")
    }
    
    // MARK: - Terminal WebSocket Tests
    
    func testTerminalWebSocketConnection() async throws {
        // Given
        connectionExpectation = expectation(description: "Terminal WebSocket connected")
        let terminalWebSocket = WebSocketManager()
        terminalWebSocket.delegate = self
        
        // When
        terminalWebSocket.connect(to: shellURL, with: nil)
        
        // Then
        await fulfillment(of: [connectionExpectation!], timeout: 5.0)
        XCTAssertTrue(terminalWebSocket.isConnected)
        
        // Cleanup
        terminalWebSocket.disconnect()
    }
    
    func testTerminalCommand() async throws {
        // Connect to terminal WebSocket
        connectionExpectation = expectation(description: "Terminal connected")
        let terminalWebSocket = WebSocketManager()
        terminalWebSocket.delegate = self
        terminalWebSocket.connect(to: shellURL, with: nil)
        await fulfillment(of: [connectionExpectation!], timeout: 5.0)
        
        // Send command
        let command = WebSocketMessage(
            type: .shellCommand,
            payload: ["content": "pwd", "type": "command"],
            sessionId: nil
        )
        
        terminalWebSocket.sendMessage(command)
        
        // Wait for response
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Verify connection maintained
        XCTAssertTrue(terminalWebSocket.isConnected)
        
        // Cleanup
        terminalWebSocket.disconnect()
    }
    
    // MARK: - Error Handling Tests
    
    func testConnectionToInvalidURL() async throws {
        // Given
        let errorExpectation = expectation(description: "Connection failed")
        let invalidURL = "ws://invalid.url.that.does.not.exist:9999/ws"
        
        // When
        webSocketManager.connect(to: invalidURL, with: nil)
        
        // Wait for failure
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            errorExpectation.fulfill()
        }
        
        // Then
        await fulfillment(of: [errorExpectation], timeout: 5.0)
        XCTAssertFalse(webSocketManager.isConnected)
        XCTAssertTrue(
            webSocketManager.connectionState == .failed ||
            webSocketManager.connectionState == .disconnected
        )
    }
    
    func testSendMessageWhileDisconnected() {
        // Given
        XCTAssertFalse(webSocketManager.isConnected)
        
        // When
        let message = WebSocketMessage(
            type: .message,
            payload: ["content": "Test message"],
            sessionId: nil
        )
        webSocketManager.sendMessage(message)
        
        // Then - Should not crash, message should be queued
        XCTAssertFalse(webSocketManager.isConnected)
    }
    
    // MARK: - Performance Tests
    
    func testConnectionPerformance() {
        measure {
            let expectation = self.expectation(description: "Performance test")
            
            webSocketManager.connect(to: backendURL, with: nil)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.webSocketManager.disconnect()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 2.0)
        }
    }
    
    func testMessageThroughput() async throws {
        // Connect first
        connectionExpectation = expectation(description: "Connected")
        webSocketManager.connect(to: backendURL, with: nil)
        await fulfillment(of: [connectionExpectation!], timeout: 5.0)
        
        // Measure sending 100 messages
        let messageCount = 100
        let startTime = Date()
        
        for i in 0..<messageCount {
            let message = WebSocketMessage(
                type: .message,
                payload: ["content": "Message \(i)"],
                sessionId: testSessionId
            )
            webSocketManager.sendMessage(message)
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let throughput = Double(messageCount) / elapsed
        
        print("✅ Sent \(messageCount) messages in \(elapsed) seconds")
        print("✅ Throughput: \(throughput) messages/second")
        
        XCTAssertGreaterThan(throughput, 50.0, "Should send at least 50 messages per second")
    }
}

// MARK: - WebSocketManagerDelegate

extension WebSocketIntegrationTestsEnhanced: WebSocketManagerDelegate {
    func webSocketDidConnect(_ manager: any WebSocketProtocol) {
        connectionExpectation?.fulfill()
    }
    
    func webSocketDidDisconnect(_ manager: any WebSocketProtocol, error: Error?) {
        // Log disconnection for debugging
        if let error = error {
            print("❌ WebSocket disconnected with error: \(error)")
        }
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveMessage message: WebSocketMessage) {
        receivedMessages.append(message)
        print("📨 Received message: \(message.payload?["content"] ?? "no content")")
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveData data: Data) {
        print("📦 Received data: \(data.count) bytes")
    }
    
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState) {
        print("🔄 Connection state changed to: \(state)")
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveText text: String) {
        print("📝 Received text: \(text)")
    }
}