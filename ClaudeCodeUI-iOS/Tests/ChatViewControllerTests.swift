//
//  ChatViewControllerTests.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-08-30.
//  Tests for critical P0 fixes in ChatViewController
//

import XCTest
import SwiftData
@testable import ClaudeCodeUI

class ChatViewControllerTests: XCTestCase {
    
    var sut: ChatViewController!
    var mockWebSocketManager: MockWebSocketManager!
    var mockContainer: SwiftDataContainer!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory SwiftData container for testing
        mockContainer = try! SwiftDataContainer(inMemoryOnly: true)
        
        // Initialize ChatViewController
        sut = ChatViewController()
        
        // Create mock WebSocket manager
        mockWebSocketManager = MockWebSocketManager()
        sut.webSocketManager = mockWebSocketManager
        
        // Load view to trigger viewDidLoad
        _ = sut.view
    }
    
    override func tearDown() {
        sut = nil
        mockWebSocketManager = nil
        mockContainer = nil
        super.tearDown()
    }
    
    // MARK: - CM-CHAT-01: Message Status State Machine Tests
    
    func testMessageStatusTransition_SendingToDelivered() {
        // Given
        let messageId = UUID().uuidString
        let message = Message(role: .user, content: "Test message")
        message.id = messageId
        message.status = .sending
        sut.messages.append(message)
        
        // When
        sut.updateMessageStatus(messageId: messageId, to: .delivered)
        
        // Then
        XCTAssertEqual(message.status, .delivered, "Message status should transition to delivered")
    }
    
    func testMessageStatusTransition_DeliveredToRead() {
        // Given
        let messageId = UUID().uuidString
        let message = Message(role: .user, content: "Test message")
        message.id = messageId
        message.status = .delivered
        sut.messages.append(message)
        
        // When
        sut.updateMessageStatus(messageId: messageId, to: .read)
        
        // Then
        XCTAssertEqual(message.status, .read, "Message status should transition to read")
    }
    
    func testMessageStatusUpdatesOnWebSocketResponse() {
        // Given
        let messageId = UUID().uuidString
        let message = Message(role: .user, content: "Test message")
        message.id = messageId
        message.status = .sending
        sut.messages.append(message)
        sut.lastSentMessageId = messageId
        
        // When - Simulate WebSocket response
        let payload: [String: Any] = [
            "type": "message",
            "content": "Response",
            "replyToMessageId": messageId
        ]
        sut.webSocket(mockWebSocketManager, didReceiveMessage: "message", payload: payload)
        
        // Then
        XCTAssertEqual(message.status, .delivered, "Message status should be updated to delivered on response")
    }
    
    // MARK: - CM-CHAT-03: Message Persistence Tests
    
    func testUserMessagePersistence() async throws {
        // Given
        let expectation = XCTestExpectation(description: "User message persisted")
        let userMessage = "Test user message"
        
        // Create a session for testing
        let project = try mockContainer.createProject(name: "Test", path: "/test")
        let session = try mockContainer.createSession(for: project)
        sut.currentSessionId = session.id
        
        // When
        sut.sendMessage(userMessage)
        
        // Wait for async persistence
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Then
        let messages = try mockContainer.fetchMessages(for: session)
        XCTAssertTrue(messages.contains { $0.content == userMessage && $0.role == .user },
                     "User message should be persisted to SwiftData")
        expectation.fulfill()
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testAssistantMessagePersistence() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Assistant message persisted")
        let assistantMessage = "Test assistant response"
        
        // Create a session for testing
        let project = try mockContainer.createProject(name: "Test", path: "/test")
        let session = try mockContainer.createSession(for: project)
        sut.currentSessionId = session.id
        
        // When - Simulate receiving assistant message
        let payload: [String: Any] = [
            "type": "message",
            "content": assistantMessage
        ]
        sut.webSocket(mockWebSocketManager, didReceiveMessage: "message", payload: payload)
        
        // Wait for async persistence
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Then
        let messages = try mockContainer.fetchMessages(for: session)
        XCTAssertTrue(messages.contains { $0.content == assistantMessage && $0.role == .assistant },
                     "Assistant message should be persisted to SwiftData")
        expectation.fulfill()
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    // MARK: - CM-CHAT-05: Connection Status UI Tests
    
    func testConnectionStatusUI_Connecting() {
        // When
        sut.webSocketDidConnect(mockWebSocketManager)
        
        // Then
        XCTAssertEqual(sut.connectionStatusLabel.text, "Connected",
                      "Connection status should show 'Connected'")
        XCTAssertEqual(sut.connectionStatusLabel.textColor, .systemGreen,
                      "Connection status color should be green")
    }
    
    func testConnectionStatusUI_Disconnected() {
        // When
        sut.webSocketDidDisconnect(mockWebSocketManager, error: nil)
        
        // Then
        XCTAssertEqual(sut.connectionStatusLabel.text, "Disconnected",
                      "Connection status should show 'Disconnected'")
        XCTAssertEqual(sut.connectionStatusLabel.textColor, .systemRed,
                      "Connection status color should be red")
    }
    
    func testConnectionStatusUI_Error() {
        // Given
        let error = NSError(domain: "WebSocket", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Connection failed"])
        
        // When
        sut.webSocketDidDisconnect(mockWebSocketManager, error: error)
        
        // Then
        XCTAssertEqual(sut.connectionStatusLabel.text, "Error: Connection failed",
                      "Connection status should show error message")
        XCTAssertEqual(sut.connectionStatusLabel.textColor, .systemRed,
                      "Connection status color should be red on error")
    }
    
    func testConnectionStatusUI_Reconnecting() {
        // When
        sut.webSocketIsReconnecting(mockWebSocketManager)
        
        // Then
        XCTAssertEqual(sut.connectionStatusLabel.text, "Reconnecting...",
                      "Connection status should show 'Reconnecting...'")
        XCTAssertEqual(sut.connectionStatusLabel.textColor, .systemOrange,
                      "Connection status color should be orange when reconnecting")
    }
}

// MARK: - Mock WebSocketManager

class MockWebSocketManager: WebSocketManager {
    var isConnectedValue = false
    var didConnectCalled = false
    var didDisconnectCalled = false
    var sentMessages: [String] = []
    
    override var isConnected: Bool {
        return isConnectedValue
    }
    
    override func connect() {
        didConnectCalled = true
        isConnectedValue = true
        delegate?.webSocketDidConnect(self)
    }
    
    override func disconnect() {
        didDisconnectCalled = true
        isConnectedValue = false
        delegate?.webSocketDidDisconnect(self, error: nil)
    }
    
    override func send(message: String) {
        sentMessages.append(message)
    }
    
    func simulateMessage(_ message: String, payload: [String: Any]) {
        delegate?.webSocket(self, didReceiveMessage: message, payload: payload)
    }
    
    func simulateError(_ error: Error) {
        delegate?.webSocketDidDisconnect(self, error: error)
    }
    
    func simulateReconnecting() {
        delegate?.webSocketIsReconnecting(self)
    }
}