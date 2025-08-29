//
//  ChatWebSocketCoordinator.swift
//  ClaudeCodeUI
//
//  Created by Refactoring on 2025-01-21.
//

import Foundation

// MARK: - Chat WebSocket Coordinator Delegate

protocol ChatWebSocketCoordinatorDelegate: AnyObject {
    func coordinatorDidConnect(_ coordinator: ChatWebSocketCoordinator)
    func coordinatorDidDisconnect(_ coordinator: ChatWebSocketCoordinator, error: Error?)
    func coordinator(_ coordinator: ChatWebSocketCoordinator, didReceiveMessage message: String, messageId: String?)
    func coordinator(_ coordinator: ChatWebSocketCoordinator, didReceiveStreamingChunk chunk: String, messageId: String, isComplete: Bool)
    func coordinator(_ coordinator: ChatWebSocketCoordinator, didReceiveTypingIndicator isTyping: Bool)
    func coordinator(_ coordinator: ChatWebSocketCoordinator, didReceiveError error: String)
    func coordinatorDidStartReconnecting(_ coordinator: ChatWebSocketCoordinator)
}

// MARK: - Chat WebSocket Coordinator

class ChatWebSocketCoordinator: NSObject {
    
    // MARK: - Properties
    
    weak var delegate: ChatWebSocketCoordinatorDelegate?
    private let webSocketManager: any WebSocketProtocol
    private let streamingHandler: StreamingMessageHandler
    private let project: Project
    
    private var isConnected = false
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let baseReconnectDelay: TimeInterval = 2.0
    
    // Message processing
    private var activeStreamingMessageId: String?
    private let messageParser = MessageParser()
    
    // MARK: - Initialization
    
    init(webSocketManager: any WebSocketProtocol, streamingHandler: StreamingMessageHandler, project: Project) {
        self.webSocketManager = webSocketManager
        self.streamingHandler = streamingHandler
        self.project = project
        super.init()
        
        self.webSocketManager.delegate = self
    }
    
    deinit {
        disconnect()
        reconnectTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    func connect() {
        print("🔌 [ChatWebSocketCoordinator] Attempting to connect WebSocket...")
        
        webSocketManager.connect()
        
        // Set initial timeout for connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            if !self?.isConnected ?? false {
                print("⚠️ [ChatWebSocketCoordinator] Connection timeout - attempting reconnect")
                self?.scheduleReconnect()
            }
        }
    }
    
    func disconnect() {
        print("🔌 [ChatWebSocketCoordinator] Disconnecting WebSocket...")
        isConnected = false
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        webSocketManager.disconnect()
    }
    
    func sendMessage(_ content: String, projectPath: String) {
        guard isConnected else {
            print("⚠️ [ChatWebSocketCoordinator] Cannot send message - not connected")
            // Attempt to reconnect
            connect()
            return
        }
        
        webSocketManager.sendMessage(content, projectPath: projectPath)
    }
    
    // MARK: - Private Methods
    
    private func scheduleReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            print("❌ [ChatWebSocketCoordinator] Max reconnect attempts reached")
            delegate?.coordinatorDidDisconnect(self, error: NSError(
                domain: "WebSocket",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to connect after \(maxReconnectAttempts) attempts"]
            ))
            return
        }
        
        reconnectAttempts += 1
        
        // Calculate exponential backoff delay
        let delay = baseReconnectDelay * pow(2.0, Double(reconnectAttempts - 1))
        
        print("🔄 [ChatWebSocketCoordinator] Scheduling reconnect attempt \(reconnectAttempts) in \(delay) seconds")
        
        delegate?.coordinatorDidStartReconnecting(self)
        
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.connect()
        }
    }
    
    private func handleIncomingMessage(_ text: String) {
        print("📥 [ChatWebSocketCoordinator] Processing incoming message")
        
        // Try to parse as JSON first
        if let data = text.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            // Check message type
            if let type = json["type"] as? String {
                switch type {
                case "assistant_message", "message":
                    handleAssistantMessage(json)
                    
                case "streaming_start":
                    handleStreamingStart(json)
                    
                case "streaming_chunk":
                    handleStreamingChunk(json)
                    
                case "streaming_end":
                    handleStreamingEnd(json)
                    
                case "typing_indicator":
                    handleTypingIndicator(json)
                    
                case "error":
                    handleErrorMessage(json)
                    
                default:
                    // Unknown type, treat as regular message
                    if let content = json["content"] as? String {
                        delegate?.coordinator(self, didReceiveMessage: content, messageId: json["id"] as? String)
                    }
                }
            } else if let content = json["content"] as? String {
                // No type field, treat as message
                delegate?.coordinator(self, didReceiveMessage: content, messageId: json["id"] as? String)
            }
        } else {
            // Plain text message
            delegate?.coordinator(self, didReceiveMessage: text, messageId: nil)
        }
    }
    
    private func handleAssistantMessage(_ json: [String: Any]) {
        guard let content = json["content"] as? String else { return }
        let messageId = json["id"] as? String
        
        delegate?.coordinator(self, didReceiveMessage: content, messageId: messageId)
    }
    
    private func handleStreamingStart(_ json: [String: Any]) {
        guard let messageId = json["messageId"] as? String else { return }
        
        activeStreamingMessageId = messageId
        streamingHandler.reset()
        
        // Show typing indicator
        delegate?.coordinator(self, didReceiveTypingIndicator: true)
    }
    
    private func handleStreamingChunk(_ json: [String: Any]) {
        guard let messageId = json["messageId"] as? String,
              let chunk = json["chunk"] as? String else { return }
        
        let isComplete = json["isComplete"] as? Bool ?? false
        
        // Process through streaming handler
        if let processed = streamingHandler.processStreamingChunk(chunk.data(using: .utf8) ?? Data()) {
            delegate?.coordinator(self, didReceiveStreamingChunk: processed.content, messageId: messageId, isComplete: processed.isComplete)
        }
        
        if isComplete {
            handleStreamingEnd(json)
        }
    }
    
    private func handleStreamingEnd(_ json: [String: Any]) {
        guard let messageId = json["messageId"] as? String else { return }
        
        if messageId == activeStreamingMessageId {
            activeStreamingMessageId = nil
            delegate?.coordinator(self, didReceiveTypingIndicator: false)
            
            // Get final message from streaming handler
            if let finalMessage = streamingHandler.getFinalMessage(for: messageId) {
                delegate?.coordinator(self, didReceiveMessage: finalMessage, messageId: messageId)
            }
        }
    }
    
    private func handleTypingIndicator(_ json: [String: Any]) {
        let isTyping = json["isTyping"] as? Bool ?? false
        delegate?.coordinator(self, didReceiveTypingIndicator: isTyping)
    }
    
    private func handleErrorMessage(_ json: [String: Any]) {
        let error = json["error"] as? String ?? "Unknown error"
        delegate?.coordinator(self, didReceiveError: error)
    }
}

// MARK: - WebSocketManagerDelegate

extension ChatWebSocketCoordinator: WebSocketManagerDelegate {
    
    func webSocketDidConnect() {
        print("✅ [ChatWebSocketCoordinator] WebSocket connected successfully")
        isConnected = true
        reconnectAttempts = 0
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        
        delegate?.coordinatorDidConnect(self)
    }
    
    func webSocketDidDisconnect(error: Error?) {
        print("🔌 [ChatWebSocketCoordinator] WebSocket disconnected: \(error?.localizedDescription ?? "No error")")
        
        let wasConnected = isConnected
        isConnected = false
        
        delegate?.coordinatorDidDisconnect(self, error: error)
        
        // Only attempt reconnect if we were previously connected
        if wasConnected {
            scheduleReconnect()
        }
    }
    
    func webSocketDidReceiveMessage(_ message: String) {
        handleIncomingMessage(message)
    }
    
    func webSocketDidReceiveData(_ data: Data) {
        // Handle binary data if needed
        if let processed = streamingHandler.processStreamingChunk(data) {
            delegate?.coordinator(
                self,
                didReceiveStreamingChunk: processed.content,
                messageId: processed.messageId,
                isComplete: processed.isComplete
            )
        }
    }
}

// MARK: - Message Parser

private class MessageParser {
    
    func parseMessage(_ text: String) -> (content: String, messageId: String?, type: String)? {
        // Try JSON parsing
        if let data = text.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            let content = json["content"] as? String ?? text
            let messageId = json["id"] as? String ?? json["messageId"] as? String
            let type = json["type"] as? String ?? "message"
            
            return (content, messageId, type)
        }
        
        // Plain text
        return (text, nil, "message")
    }
    
    func isValidMessage(_ text: String) -> Bool {
        // Filter out pure UUID responses or metadata-only messages
        if text.count == 36 && text.contains("-") {
            // Likely a UUID
            return false
        }
        
        // Check for actual content
        if let data = text.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // Must have content or be a valid message type
            return json["content"] != nil || json["type"] != nil
        }
        
        // Non-empty plain text is valid
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}