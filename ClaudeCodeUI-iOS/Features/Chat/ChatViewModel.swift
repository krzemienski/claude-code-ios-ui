//
//  ChatViewModel.swift
//  ClaudeCodeUI
//
//  Created by Refactoring on 2025-01-21.
//

import Foundation
import UIKit
import SwiftData

// MARK: - Chat View Model

@MainActor
class ChatViewModel: ObservableObject {
    
    // MARK: - Properties
    
    private let project: Project
    private(set) var currentSession: Session?
    private(set) var messages: [EnhancedChatMessage] = []
    private let webSocketManager: any WebSocketProtocol
    
    // Session management
    private(set) var currentSessionId: String?
    private(set) var hasMoreMessages = true
    private let messagePageSize = 50
    private let maxMessagesInMemory = 100
    private let messageBatchSize = 50
    
    // State tracking
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var isTyping = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var errorMessage: String?
    
    // Message tracking
    private var lastSentMessageId: String?
    private var messageStatusTimers: [String: Timer] = [:]
    
    // MARK: - Connection Status
    
    enum ConnectionStatus {
        case connecting
        case connected
        case disconnected
        case reconnecting
        case error(String)
        
        var displayText: String {
            switch self {
            case .connecting:
                return "Connecting..."
            case .connected:
                return "Connected"
            case .disconnected:
                return "Disconnected"
            case .reconnecting:
                return "Reconnecting..."
            case .error(let message):
                return "Error: \(message)"
            }
        }
        
        var statusColor: UIColor {
            switch self {
            case .connected:
                return CyberpunkTheme.success
            case .connecting, .reconnecting:
                return CyberpunkTheme.warning
            case .disconnected, .error:
                return CyberpunkTheme.error
            }
        }
    }
    
    // MARK: - Initialization
    
    init(project: Project, session: Session? = nil, webSocketManager: any WebSocketProtocol) {
        self.project = project
        self.currentSession = session
        self.webSocketManager = webSocketManager
        self.currentSessionId = session?.id
    }
    
    deinit {
        cleanupTimers()
    }
    
    // MARK: - Public Methods
    
    func loadInitialMessages() async {
        guard let sessionId = currentSessionId else {
            print("📦 No session ID, skipping message load")
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let projectName = project.name
            print("📦 Loading messages for session: \(sessionId)")
            
            let fetchedMessages = try await APIClient.shared.fetchSessionMessages(
                projectName: projectName,
                sessionId: sessionId,
                limit: messagePageSize,
                offset: 0
            )
            
            // Convert API messages to enhanced messages
            messages = fetchedMessages.map { message in
                EnhancedChatMessage(
                    id: message.id,
                    content: message.content,
                    isUser: message.role == .user,
                    timestamp: message.timestamp,
                    status: .delivered
                )
            }
            
            hasMoreMessages = fetchedMessages.count >= messagePageSize
            print("✅ Loaded \(messages.count) messages")
            
        } catch {
            print("❌ Failed to load messages: \(error)")
            errorMessage = "Failed to load messages: \(error.localizedDescription)"
        }
    }
    
    func loadMoreMessages(offset: Int) async -> [EnhancedChatMessage] {
        guard !isLoadingMore,
              hasMoreMessages,
              let sessionId = currentSessionId else {
            return []
        }
        
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        do {
            let projectName = project.name
            
            let fetchedMessages = try await APIClient.shared.fetchSessionMessages(
                projectName: projectName,
                sessionId: sessionId,
                limit: messageBatchSize,
                offset: offset
            )
            
            hasMoreMessages = fetchedMessages.count >= messageBatchSize
            
            // Convert and return
            let newMessages = fetchedMessages.map { message in
                EnhancedChatMessage(
                    id: message.id,
                    content: message.content,
                    isUser: message.role == .user,
                    timestamp: message.timestamp,
                    status: .delivered
                )
            }
            
            // Prepend to messages array
            messages.insert(contentsOf: newMessages, at: 0)
            
            // Trim messages if exceeding memory limit
            if messages.count > maxMessagesInMemory {
                messages = Array(messages.suffix(maxMessagesInMemory))
            }
            
            return newMessages
            
        } catch {
            print("❌ Failed to load more messages: \(error)")
            errorMessage = "Failed to load more messages"
            return []
        }
    }
    
    func sendMessage(_ content: String) {
        let messageId = UUID().uuidString
        lastSentMessageId = messageId
        
        // Create user message
        let userMessage = EnhancedChatMessage(
            id: messageId,
            content: content,
            isUser: true,
            timestamp: Date(),
            status: .sending
        )
        
        // Add to messages
        messages.append(userMessage)
        
        // Start status timer
        startStatusTimer(for: messageId)
        
        // Send via WebSocket
        webSocketManager.sendMessage(content, projectPath: project.fullPath)
    }
    
    func retryMessage(_ message: EnhancedChatMessage) {
        guard message.status == .failed else { return }
        
        // Update status to sending
        updateMessageStatus(message.id, status: .sending)
        
        // Resend via WebSocket
        webSocketManager.sendMessage(message.content, projectPath: project.fullPath)
        
        // Start status timer
        startStatusTimer(for: message.id)
    }
    
    func addIncomingMessage(_ content: String, messageId: String? = nil) {
        let id = messageId ?? UUID().uuidString
        
        let assistantMessage = EnhancedChatMessage(
            id: id,
            content: content,
            isUser: false,
            timestamp: Date(),
            status: .delivered
        )
        
        messages.append(assistantMessage)
        
        // Update last sent message status if we have one
        if let lastId = lastSentMessageId {
            updateMessageStatus(lastId, status: .delivered)
        }
    }
    
    func updateMessageStatus(_ messageId: String, status: MessageStatus) {
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            messages[index].status = status
            
            // Cancel timer if status is final
            if status == .delivered || status == .read || status == .failed {
                cancelStatusTimer(for: messageId)
            }
        }
    }
    
    func updateConnectionStatus(_ status: ConnectionStatus) {
        connectionStatus = status
    }
    
    func handleMemoryWarning() {
        // Keep only recent messages
        if messages.count > 50 {
            messages = Array(messages.suffix(50))
        }
    }
    
    // MARK: - Private Methods
    
    private func startStatusTimer(for messageId: String) {
        // Cancel existing timer if any
        cancelStatusTimer(for: messageId)
        
        // Create new timer
        let timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            self?.updateMessageStatus(messageId, status: .failed)
        }
        
        messageStatusTimers[messageId] = timer
    }
    
    private func cancelStatusTimer(for messageId: String) {
        messageStatusTimers[messageId]?.invalidate()
        messageStatusTimers[messageId] = nil
    }
    
    private func cleanupTimers() {
        for (_, timer) in messageStatusTimers {
            timer.invalidate()
        }
        messageStatusTimers.removeAll()
    }
}