//
//  ChatViewModel.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-30.
//  Refactored from ChatViewController for improved modularity
//

import Foundation
import UIKit
import Combine

// MARK: - ChatViewModel

/// View model managing chat business logic and state
@MainActor
final class ChatViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var isTyping = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var error: Error?
    @Published var currentProject: Project?
    @Published var currentSession: Session?
    
    // MARK: - Properties
    
    private let webSocketManager: WebSocketProtocol
    private let dataContainer: SwiftDataContainer?
    private let apiClient: APIClient
    private var cancellables = Set<AnyCancellable>()
    
    // Message status tracking
    private var messageStatusTimers: [String: Timer] = [:]
    private var pendingMessages: Set<String> = []
    
    // MARK: - Types
    
    enum ConnectionStatus {
        case connected
        case connecting
        case disconnected
        case reconnecting
        
        var displayText: String {
            switch self {
            case .connected: return "Connected"
            case .connecting: return "Connecting..."
            case .disconnected: return "Disconnected"
            case .reconnecting: return "Reconnecting..."
            }
        }
        
        var color: UIColor {
            switch self {
            case .connected: return .systemGreen
            case .connecting, .reconnecting: return .systemOrange
            case .disconnected: return .systemRed
            }
        }
    }
    
    // MARK: - Initialization
    
    init(webSocketManager: WebSocketProtocol? = nil,
         dataContainer: SwiftDataContainer? = nil,
         apiClient: APIClient? = nil) {
        self.webSocketManager = webSocketManager ?? DIContainer.shared.webSocketManager
        self.dataContainer = dataContainer ?? DIContainer.shared.dataContainer
        self.apiClient = apiClient ?? DIContainer.shared.apiClient
        
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Observe WebSocket connection status
        NotificationCenter.default.publisher(for: .webSocketDidConnect)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.connectionStatus = .connected
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .webSocketDidDisconnect)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.connectionStatus = .disconnected
            }
            .store(in: &cancellables)
        
        // Observe incoming messages
        NotificationCenter.default.publisher(for: .webSocketDidReceiveMessage)
            .receive(on: DispatchQueue.main)
            .compactMap { $0.userInfo?["message"] as? ChatMessage }
            .sink { [weak self] message in
                self?.handleIncomingMessage(message)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Load messages for current session
    func loadMessages() async {
        guard let session = currentSession else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load from local storage first
            if let dataContainer = dataContainer {
                let localMessages = try await dataContainer.fetchMessages(for: session)
                await MainActor.run {
                    // Convert Message to ChatMessage
                    self.messages = localMessages.map { msg in
                        ChatMessage(
                            id: msg.id,
                            content: msg.content,
                            isUser: msg.role.isUser,
                            timestamp: msg.timestamp,
                            status: .sent
                        )
                    }.sorted { $0.timestamp < $1.timestamp }
                }
            }
            
            // Then fetch from backend
            if let projectName = currentProject?.name {
                let remoteMessages = try await apiClient.fetchSessionMessages(
                    projectName: projectName,
                    sessionId: session.id
                )
                
                await MainActor.run {
                    // Convert and merge remote messages
                    let convertedMessages = remoteMessages.map { msg in
                        ChatMessage(
                            id: msg.id,
                            content: msg.content,
                            isUser: msg.role.isUser,
                            timestamp: msg.timestamp,
                            status: .sent
                        )
                    }
                    self.mergeMessages(convertedMessages)
                }
            }
        } catch {
            self.error = error
            print("❌ Failed to load messages: \(error)")
        }
    }
    
    /// Send a new message
    func sendMessage(_ content: String) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let session = currentSession else { return }
        
        // Create message
        let message = ChatMessage(
            id: UUID().uuidString,
            content: content,
            isUser: true,
            timestamp: Date(),
            status: .sending
        )
        
        // Add to messages and track
        messages.append(message)
        pendingMessages.insert(message.id)
        
        // Start status timer
        startStatusTimer(for: message.id)
        
        // Send via WebSocket
        if let projectPath = currentProject?.fullPath {
            let payload: [String: Any] = [
                "type": "claude-command",
                "content": content,
                "projectPath": projectPath,
                "sessionId": session.id,
                "messageId": message.id
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: payload),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                webSocketManager.send(jsonString)
            }
        }
        
        // Save to local storage
        if let dataContainer = dataContainer {
            _ = try? await dataContainer.createMessage(
                for: session,
                role: .user,
                content: content
            )
        }
    }
    
    /// Retry sending a failed message
    func retryMessage(_ messageId: String) async {
        guard let index = messages.firstIndex(where: { $0.id == messageId }),
              messages[index].status == .failed else { return }
        
        let message = messages[index]
        messages[index].status = .sending
        
        // Resend
        await sendMessage(message.content)
    }
    
    /// Delete a message
    func deleteMessage(_ messageId: String) async {
        messages.removeAll { $0.id == messageId }
        
        // Remove from local storage if exists
        if let dataContainer = dataContainer,
           let session = currentSession {
            try? await dataContainer.deleteMessage(messageId, from: session)
        }
    }
    
    /// Clear all messages
    func clearMessages() async {
        messages.removeAll()
        pendingMessages.removeAll()
        messageStatusTimers.values.forEach { $0.invalidate() }
        messageStatusTimers.removeAll()
        
        // Clear from local storage
        if let dataContainer = dataContainer,
           let session = currentSession {
            try? await dataContainer.clearMessages(for: session)
        }
    }
    
    // MARK: - Private Methods
    
    private func handleIncomingMessage(_ message: ChatMessage) {
        // Check if this is a response to a pending message
        if let lastPendingId = pendingMessages.first {
            updateMessageStatus(lastPendingId, to: .delivered)
            pendingMessages.remove(lastPendingId)
        }
        
        // Add assistant message
        messages.append(message)
        
        // Update typing status
        if !message.isUser {
            isTyping = false
        }
    }
    
    private func mergeMessages(_ remoteMessages: [ChatMessage]) {
        let existingIds = Set(messages.map { $0.id })
        let newMessages = remoteMessages.filter { !existingIds.contains($0.id) }
        
        messages.append(contentsOf: newMessages)
        messages.sort { $0.timestamp < $1.timestamp }
    }
    
    func updateMessageStatus(_ messageId: String, to status: MessageStatus) {
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else { return }
        messages[index].status = status
        
        // Cancel timer if delivered or failed
        if status == .delivered || status == .failed {
            messageStatusTimers[messageId]?.invalidate()
            messageStatusTimers[messageId] = nil
        }
    }
    
    private func startStatusTimer(for messageId: String) {
        // Cancel existing timer
        messageStatusTimers[messageId]?.invalidate()
        
        // Start new timer - mark as failed after 30 seconds
        messageStatusTimers[messageId] = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            self?.updateMessageStatus(messageId, to: .failed)
        }
    }
    
    // MARK: - Connection Management
    
    func connect() {
        guard let projectPath = currentProject?.fullPath else { return }
        
        connectionStatus = .connecting
        
        // Get auth token
        let token = UserDefaults.standard.string(forKey: "authToken")
        
        // Connect WebSocket
        webSocketManager.connect(to: AppConfig.websocketURL, with: token)
    }
    
    func disconnect() {
        webSocketManager.disconnect()
        connectionStatus = .disconnected
    }
    
    func reconnect() {
        connectionStatus = .reconnecting
        disconnect()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.connect()
        }
    }
}

// MARK: - ChatMessage Extensions
// Status enum moved to ChatMessage.swift to avoid conflicts

// MARK: - Notification Names

extension Notification.Name {
    static let webSocketDidConnect = Notification.Name("webSocketDidConnect")
    static let webSocketDidDisconnect = Notification.Name("webSocketDidDisconnect")
    static let webSocketDidReceiveMessage = Notification.Name("webSocketDidReceiveMessage")
}