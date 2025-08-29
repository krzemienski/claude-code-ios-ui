//
//  ChatWebSocketCoordinator.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-30.
//  Coordinates WebSocket communication between chat components
//

import Foundation
import Combine

// MARK: - ChatWebSocketCoordinator

/// Coordinates WebSocket communication and message routing for chat
@MainActor
final class ChatWebSocketCoordinator: NSObject {
    
    // MARK: - Properties
    
    weak var viewModel: ChatViewModel?
    private let webSocketManager: WebSocketProtocol
    private let streamingHandler: StreamingMessageHandler
    
    var projectPath: String?
    
    private var cancellables = Set<AnyCancellable>()
    private var messageBuffer = [String: String]()
    private var activeStreamIds = Set<String>()
    
    // Configuration
    private let maxReconnectAttempts = 5
    private let reconnectDelayBase = 2.0 // Exponential backoff base
    private var currentReconnectAttempt = 0
    
    // MARK: - Initialization
    
    init(webSocketManager: WebSocketProtocol, viewModel: ChatViewModel) {
        self.webSocketManager = webSocketManager
        self.viewModel = viewModel
        self.streamingHandler = StreamingMessageHandler()
        super.init()
        
        setupBindings()
        setupMessageHandlers()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Listen for connection state changes
        NotificationCenter.default.publisher(for: .webSocketDidConnect)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleConnectionEstablished()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .webSocketDidDisconnect)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleConnectionLost()
            }
            .store(in: &cancellables)
        
        // Listen for incoming messages
        NotificationCenter.default.publisher(for: .webSocketDidReceiveMessage)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let message = notification.object as? String {
                    self?.handleIncomingMessage(message)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupMessageHandlers() {
        // Configure streaming handler callbacks
        streamingHandler.onTokenReceived = { [weak self] token, messageId in
            self?.handleStreamingToken(token, for: messageId)
        }
        
        streamingHandler.onStreamComplete = { [weak self] fullContent, messageId in
            self?.handleStreamComplete(fullContent, for: messageId)
        }
        
        streamingHandler.onError = { [weak self] error, messageId in
            self?.handleStreamError(error, for: messageId)
        }
    }
    
    // MARK: - Public Methods
    
    func connect(to url: URL, with token: String?) {
        webSocketManager.connect(to: url, with: token)
        viewModel?.updateConnectionStatus(.connecting)
    }
    
    func disconnect() {
        webSocketManager.disconnect()
        viewModel?.updateConnectionStatus(.disconnected)
        clearActiveStreams()
    }
    
    func sendMessage(_ content: String, messageId: String) {
        guard let viewModel = viewModel,
              let projectPath = viewModel.projectPath,
              let sessionId = viewModel.session?.id else {
            print("❌ Missing required data for sending message")
            return
        }
        
        let payload: [String: Any] = [
            "type": "claude-command",
            "content": content,
            "projectPath": projectPath,
            "sessionId": sessionId,
            "messageId": messageId
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            webSocketManager.send(jsonString)
            print("📤 Sent message via WebSocket: \(messageId)")
        }
    }
    
    func resendMessage(_ messageId: String) {
        guard let message = viewModel?.messages.first(where: { $0.id == messageId }) else {
            return
        }
        
        sendMessage(message.content, messageId: messageId)
    }
    
    // MARK: - Connection Handling
    
    private func handleConnectionEstablished() {
        currentReconnectAttempt = 0
        viewModel?.updateConnectionStatus(.connected)
        
        // Resend any pending messages
        resendPendingMessages()
        
        print("✅ WebSocket connection established")
    }
    
    private func handleConnectionLost() {
        viewModel?.updateConnectionStatus(.disconnected)
        attemptReconnection()
        
        print("❌ WebSocket connection lost")
    }
    
    private func attemptReconnection() {
        guard currentReconnectAttempt < maxReconnectAttempts else {
            print("❌ Max reconnection attempts reached")
            viewModel?.updateConnectionStatus(.disconnected)
            return
        }
        
        currentReconnectAttempt += 1
        let delay = pow(reconnectDelayBase, Double(currentReconnectAttempt))
        
        viewModel?.updateConnectionStatus(.reconnecting)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            
            print("🔄 Attempting reconnection \(self.currentReconnectAttempt)/\(self.maxReconnectAttempts)")
            
            if let url = self.webSocketManager.currentURL,
               let token = UserDefaults.standard.string(forKey: "authToken") {
                self.connect(to: url, with: token)
            }
        }
    }
    
    private func resendPendingMessages() {
        guard let viewModel = viewModel else { return }
        
        for messageId in viewModel.pendingMessages {
            if let message = viewModel.messages.first(where: { $0.id == messageId }) {
                resendMessage(messageId)
            }
        }
    }
    
    // MARK: - Message Handling
    
    private func handleIncomingMessage(_ message: String) {
        guard let data = message.data(using: .utf8) else { return }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                processIncomingJSON(json)
            }
        } catch {
            // Try handling as plain text streaming
            handleStreamingContent(message)
        }
    }
    
    private func processIncomingJSON(_ json: [String: Any]) {
        guard let type = json["type"] as? String else { return }
        
        switch type {
        case "message":
            handleChatMessage(json)
            
        case "stream-start":
            handleStreamStart(json)
            
        case "stream-token":
            handleStreamToken(json)
            
        case "stream-end":
            handleStreamEnd(json)
            
        case "error":
            handleErrorMessage(json)
            
        case "status":
            handleStatusUpdate(json)
            
        case "typing":
            handleTypingIndicator(json)
            
        default:
            print("📥 Unknown message type: \(type)")
        }
    }
    
    private func handleChatMessage(_ json: [String: Any]) {
        guard let content = json["content"] as? String,
              let role = json["role"] as? String else { return }
        
        let messageId = json["messageId"] as? String ?? UUID().uuidString
        let replyTo = json["replyTo"] as? String
        
        // Mark the user message as delivered if this is a reply
        if let replyTo = replyTo {
            viewModel?.updateMessageStatus(replyTo, to: .delivered)
            viewModel?.pendingMessages.remove(replyTo)
        }
        
        // Create assistant message
        if role == "assistant" {
            let message = ChatMessage(
                id: messageId,
                role: .assistant,
                content: content,
                timestamp: Date(),
                status: .delivered
            )
            
            viewModel?.addMessage(message)
            viewModel?.setTyping(false)
        }
    }
    
    private func handleStreamStart(_ json: [String: Any]) {
        guard let messageId = json["messageId"] as? String else { return }
        
        activeStreamIds.insert(messageId)
        messageBuffer[messageId] = ""
        viewModel?.setTyping(true)
        
        // Create placeholder message for streaming
        let message = ChatMessage(
            id: messageId,
            role: .assistant,
            content: "",
            timestamp: Date(),
            status: .sending
        )
        
        viewModel?.addMessage(message)
    }
    
    private func handleStreamToken(_ json: [String: Any]) {
        guard let messageId = json["messageId"] as? String,
              let token = json["token"] as? String else { return }
        
        streamingHandler.processToken(token, for: messageId)
    }
    
    private func handleStreamEnd(_ json: [String: Any]) {
        guard let messageId = json["messageId"] as? String else { return }
        
        activeStreamIds.remove(messageId)
        
        if let fullContent = messageBuffer[messageId] {
            viewModel?.updateMessageContent(messageId, content: fullContent)
            viewModel?.updateMessageStatus(messageId, to: .delivered)
        }
        
        messageBuffer.removeValue(forKey: messageId)
        viewModel?.setTyping(false)
        
        // Mark related user message as delivered
        if let replyTo = json["replyTo"] as? String {
            viewModel?.updateMessageStatus(replyTo, to: .delivered)
            viewModel?.pendingMessages.remove(replyTo)
        }
    }
    
    private func handleErrorMessage(_ json: [String: Any]) {
        guard let error = json["error"] as? String else { return }
        
        let messageId = json["messageId"] as? String
        
        if let messageId = messageId {
            viewModel?.updateMessageStatus(messageId, to: .failed)
            viewModel?.pendingMessages.remove(messageId)
        }
        
        print("❌ WebSocket error: \(error)")
        
        // Show error to user
        viewModel?.showError(AppError.network(.requestFailed))
    }
    
    private func handleStatusUpdate(_ json: [String: Any]) {
        guard let status = json["status"] as? String else { return }
        
        switch status {
        case "connected":
            viewModel?.updateConnectionStatus(.connected)
            
        case "disconnected":
            viewModel?.updateConnectionStatus(.disconnected)
            
        case "reconnecting":
            viewModel?.updateConnectionStatus(.reconnecting)
            
        default:
            break
        }
    }
    
    private func handleTypingIndicator(_ json: [String: Any]) {
        guard let isTyping = json["isTyping"] as? Bool else { return }
        viewModel?.setTyping(isTyping)
    }
    
    // MARK: - Streaming Handling
    
    private func handleStreamingContent(_ content: String) {
        // Handle raw streaming content
        streamingHandler.processStreamingMessage(content)
    }
    
    private func handleStreamingToken(_ token: String, for messageId: String) {
        // Append token to buffer
        messageBuffer[messageId, default: ""] += token
        
        // Update message with accumulated content
        if let content = messageBuffer[messageId] {
            viewModel?.updateMessageContent(messageId, content: content)
        }
    }
    
    private func handleStreamComplete(_ fullContent: String, for messageId: String) {
        viewModel?.updateMessageContent(messageId, content: fullContent)
        viewModel?.updateMessageStatus(messageId, to: .delivered)
        
        activeStreamIds.remove(messageId)
        messageBuffer.removeValue(forKey: messageId)
        viewModel?.setTyping(false)
    }
    
    private func handleStreamError(_ error: Error, for messageId: String) {
        viewModel?.updateMessageStatus(messageId, to: .failed)
        
        activeStreamIds.remove(messageId)
        messageBuffer.removeValue(forKey: messageId)
        viewModel?.setTyping(false)
        
        print("❌ Streaming error for \(messageId): \(error)")
    }
    
    // MARK: - Cleanup
    
    private func clearActiveStreams() {
        for streamId in activeStreamIds {
            viewModel?.updateMessageStatus(streamId, to: .failed)
        }
        
        activeStreamIds.removeAll()
        messageBuffer.removeAll()
    }
    
    deinit {
        cancellables.removeAll()
        disconnect()
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let webSocketDidConnect = Notification.Name("webSocketDidConnect")
    static let webSocketDidDisconnect = Notification.Name("webSocketDidDisconnect")
    static let webSocketDidReceiveMessage = Notification.Name("webSocketDidReceiveMessage")
}

// MARK: - WebSocketProtocol Extension

extension WebSocketProtocol {
    var currentURL: URL? {
        // This would need to be implemented in the actual WebSocketManager
        // to track the current connection URL
        return nil
    }
}