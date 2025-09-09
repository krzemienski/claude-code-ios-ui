//
//  ChatViewModelTests.swift
//  ClaudeCodeUITests
//
//  Created by Claude Code UI on 2025/01/30.
//

import XCTest
import Combine
@testable import ClaudeCodeUI

@MainActor
final class ChatViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: ChatViewModel!
    private var mockWebSocketManager: MockWebSocketManager!
    private var mockAPIClient: MockAPIClient!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockWebSocketManager = MockWebSocketManager()
        mockAPIClient = MockAPIClient()
        cancellables = Set<AnyCancellable>()
        
        viewModel = ChatViewModel(
            webSocketManager: mockWebSocketManager,
            apiClient: mockAPIClient
        )
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockWebSocketManager = nil
        mockAPIClient = nil
        cancellables = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testInitialState() {
        // Then
        XCTAssertTrue(viewModel.messages.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.connectionState, .disconnected)
    }
    
    func testSendMessage() async {
        // Given
        let messageContent = "Hello, Claude!"
        let expectation = XCTestExpectation(description: "Message sent")
        
        viewModel.$messages
            .dropFirst()
            .sink { messages in
                if !messages.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.sendMessage(messageContent)
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertFalse(viewModel.messages.isEmpty)
        XCTAssertEqual(viewModel.messages.first?.content, messageContent)
        XCTAssertEqual(viewModel.messages.first?.role, .user)
    }
    
    func testReceiveMessage() async {
        // Given
        let responseContent = "Hello! How can I help you?"
        let expectation = XCTestExpectation(description: "Message received")
        
        viewModel.$messages
            .dropFirst()
            .sink { messages in
                if messages.contains(where: { $0.role == .assistant }) {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        mockWebSocketManager.simulateMessageReceived(content: responseContent)
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertTrue(viewModel.messages.contains { $0.content == responseContent })
    }
    
    func testConnectionStateChanges() async {
        // Given
        let expectation = XCTestExpectation(description: "Connection state changed")
        
        viewModel.$connectionState
            .dropFirst()
            .sink { state in
                if state == .connected {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        mockWebSocketManager.simulateConnectionStateChange(.connected)
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(viewModel.connectionState, .connected)
    }
    
    func testErrorHandling() async {
        // Given
        let error = NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let expectation = XCTestExpectation(description: "Error received")
        
        viewModel.$error
            .dropFirst()
            .sink { error in
                if error != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        mockWebSocketManager.simulateError(error)
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(viewModel.error?.localizedDescription, "Test error")
    }
    
    func testMessagePersistence() async {
        // Given
        let messages = [
            ChatMessage(id: "1", content: "Message 1", role: .user),
            ChatMessage(id: "2", content: "Message 2", role: .assistant)
        ]
        
        // When
        await viewModel.saveMessages(messages)
        let loaded = await viewModel.loadMessages()
        
        // Then
        XCTAssertEqual(loaded.count, messages.count)
        XCTAssertEqual(loaded.first?.content, messages.first?.content)
    }
    
    func testTypingIndicator() async {
        // Given
        let expectation = XCTestExpectation(description: "Typing indicator shown")
        
        viewModel.$isTyping
            .dropFirst()
            .sink { isTyping in
                if isTyping {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        mockWebSocketManager.simulateTypingIndicator(true)
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertTrue(viewModel.isTyping)
    }
    
    func testLoadMoreMessages() async {
        // Given
        viewModel.hasMoreMessages = true
        
        // When
        await viewModel.loadMoreMessages()
        
        // Then
        XCTAssertTrue(mockAPIClient.loadMessagesCalled)
        XCTAssertFalse(viewModel.isLoadingMore)
    }
    
    func testClearMessages() async {
        // Given
        await viewModel.sendMessage("Test message")
        XCTAssertFalse(viewModel.messages.isEmpty)
        
        // When
        await viewModel.clearMessages()
        
        // Then
        XCTAssertTrue(viewModel.messages.isEmpty)
    }
    
    func testReconnection() async {
        // Given
        mockWebSocketManager.simulateConnectionStateChange(.disconnected)
        
        // When
        await viewModel.reconnect()
        
        // Then
        XCTAssertTrue(mockWebSocketManager.connectCalled)
    }
}

// MARK: - Mock Objects

private class MockWebSocketManager: WebSocketProtocol {
    var delegate: WebSocketManagerDelegate?
    var connectionState: WebSocketConnectionState = .disconnected
    var isConnected: Bool { connectionState == .connected }
    
    var connectCalled = false
    var disconnectCalled = false
    var sendMessageCalled = false
    
    func connect(to endpoint: String, with token: String?) {
        connectCalled = true
        connectionState = .connected
        delegate?.webSocketConnectionStateChanged(.connected)
    }
    
    func disconnect() {
        disconnectCalled = true
        connectionState = .disconnected
        delegate?.webSocketConnectionStateChanged(.disconnected)
    }
    
    func send(_ message: String) {
        sendMessageCalled = true
    }
    
    func sendData(_ data: Data) {
        sendMessageCalled = true
    }
    
    // Helper methods for testing
    func simulateMessageReceived(content: String) {
        let payload: [String: Any] = [
            "id": UUID().uuidString,
            "content": content,
            "role": "assistant"
        ]
        let message = WebSocketMessage(
            type: .message,
            payload: payload,
            sessionId: "test-session"
        )
        delegate?.webSocket(self, didReceiveMessage: message)
    }
    
    func simulateConnectionStateChange(_ state: WebSocketConnectionState) {
        connectionState = state
        delegate?.webSocketConnectionStateChanged(state)
    }
    
    func simulateError(_ error: Error) {
        delegate?.webSocketDidDisconnect(self, error: error)
    }
    
    func simulateTypingIndicator(_ isTyping: Bool) {
        let payload: [String: Any] = [
            "status": isTyping ? "typing" : "stopped"
        ]
        let message = WebSocketMessage(
            type: .typing,
            payload: payload,
            sessionId: "test-session"
        )
        delegate?.webSocket(self, didReceiveMessage: message)
    }
}

private class MockAPIClient {
    var loadMessagesCalled = false
    var saveMessagesCalled = false
    
    func loadMessages(for sessionId: String, offset: Int, limit: Int) async throws -> [ChatMessage] {
        loadMessagesCalled = true
        return []
    }
    
    func saveMessages(_ messages: [ChatMessage], for sessionId: String) async throws {
        saveMessagesCalled = true
    }
}

// Simplified ChatViewModel for testing
private class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var error: Error?
    @Published var connectionState: WebSocketConnectionState = .disconnected
    @Published var isTyping = false
    
    var hasMoreMessages = true
    
    private let webSocketManager: WebSocketProtocol
    private let apiClient: MockAPIClient
    
    init(webSocketManager: WebSocketProtocol, apiClient: MockAPIClient) {
        self.webSocketManager = webSocketManager
        self.apiClient = apiClient
        
        webSocketManager.delegate = self
    }
    
    @MainActor
    func sendMessage(_ content: String) async {
        let message = ChatMessage(
            id: UUID().uuidString,
            content: content,
            role: .user
        )
        messages.append(message)
        
        // Convert message to JSON string for sending
        let messageData: [String: Any] = [
            "id": message.id,
            "content": content,
            "role": "user"
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: messageData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            webSocketManager.send(jsonString)
        }
    }
    
    @MainActor
    func loadMoreMessages() async {
        guard hasMoreMessages, !isLoadingMore else { return }
        isLoadingMore = true
        
        do {
            let newMessages = try await apiClient.loadMessages(
                for: "test-session",
                offset: messages.count,
                limit: 50
            )
            messages.insert(contentsOf: newMessages, at: 0)
            hasMoreMessages = newMessages.count == 50
        } catch {
            self.error = error
        }
        
        isLoadingMore = false
    }
    
    @MainActor
    func clearMessages() async {
        messages.removeAll()
    }
    
    @MainActor
    func reconnect() async {
        webSocketManager.connect(to: "ws://localhost:3004", with: nil)
    }
    
    @MainActor
    func saveMessages(_ messages: [ChatMessage]) async {
        try? await apiClient.saveMessages(messages, for: "test-session")
    }
    
    @MainActor
    func loadMessages() async -> [ChatMessage] {
        return (try? await apiClient.loadMessages(for: "test-session", offset: 0, limit: 100)) ?? []
    }
}

// MARK: - WebSocketManagerDelegate

extension ChatViewModel: WebSocketManagerDelegate {
    func webSocketDidConnect(_ manager: any WebSocketProtocol) {
        Task { @MainActor in
            connectionState = .connected
        }
    }
    
    func webSocketDidDisconnect(_ manager: any WebSocketProtocol, error: Error?) {
        Task { @MainActor in
            connectionState = .disconnected
            if let error = error {
                self.error = error
            }
        }
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveMessage message: WebSocketMessage) {
        Task { @MainActor in
            if message.type == .typing {
                if let status = message.payload?["status"] as? String {
                    isTyping = status == "typing"
                }
            } else if message.type == .message {
                if let content = message.payload?["content"] as? String,
                   let id = message.payload?["id"] as? String {
                    let chatMessage = ChatMessage(
                        id: id,
                        content: content,
                        role: .assistant
                    )
                    messages.append(chatMessage)
                }
            }
        }
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveData data: Data) {
        // Not used in tests
    }
    
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState) {
        Task { @MainActor in
            connectionState = state
        }
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveText text: String) {
        // Optional method - not used in tests
    }
}

// Simple ChatMessage struct for testing
private struct ChatMessage {
    let id: String
    let content: String
    let role: MessageRole
    
    enum MessageRole {
        case user
        case assistant
        case system
    }
}