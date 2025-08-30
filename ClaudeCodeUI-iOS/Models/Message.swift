//
//  Message.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-12-13.
//

import Foundation
import SwiftData

// MARK: - Message Status Value (for Message model)
enum MessageStatusValue: String, Codable {
    case sending = "sending"
    case sent = "sent" 
    case delivered = "delivered"
    case failed = "failed"
    case read = "read"
}

// MARK: - Message Role
enum MessageRole: String, Codable, CaseIterable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
    case human = "human"  // Backend compatibility
    
    // Display properties
    var displayName: String {
        switch self {
        case .user, .human:
            return "You"
        case .assistant:
            return "Claude"
        case .system:
            return "System"
        }
    }
    
    var isUser: Bool {
        return self == .user || self == .human
    }
}

// MARK: - Message Metadata
struct MessageMetadata: Codable {
    var model: String?
    var tokens: Int?
    var processingTime: TimeInterval?
    var error: String?
    var streamCompleted: Bool?
    var projectPath: String?
    var sessionId: String?
    
    // Additional metadata fields from backend
    var commandType: String?  // claude-command, cursor-command, etc.
    var aborted: Bool?
    var resumedFrom: String?  // Previous session ID if resumed
}

// MARK: - Message Model
@available(iOS 17.0, *)
@Model
final class Message {
    // MARK: - Properties
    @Attribute(.unique) var id: String
    var sessionId: String  // Foreign key to Session
    var content: String
    var role: MessageRole
    var timestamp: Date
    
    // Metadata stored as JSON string (SwiftData doesn't support Codable structs directly)
    private var metadataJSON: String?
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    
    // Additional properties
    var isStreaming: Bool = false
    var isError: Bool = false
    var isAborted: Bool = false
    var statusString: String = "sent"  // Store as String for SwiftData compatibility
    
    // MARK: - Computed Properties
    
    // Status computed property - since MessageStatus is defined in MessageTypes.swift,
    // we'll use a simple enum here to avoid circular dependencies
    var status: MessageStatusValue {
        get {
            return MessageStatusValue(rawValue: statusString) ?? .sent
        }
        set {
            statusString = newValue.rawValue
        }
    }
    
    var metadata: MessageMetadata? {
        get {
            guard let json = metadataJSON,
                  let data = json.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode(MessageMetadata.self, from: data)
        }
        set {
            guard let newValue = newValue else {
                metadataJSON = nil
                return
            }
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                metadataJSON = json
            }
        }
    }
    
    var displayTimestamp: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: timestamp)
    }
    
    var displayContent: String {
        if isError {
            return "❌ \(content)"
        } else if isAborted {
            return "⚠️ \(content) (Aborted)"
        } else {
            return content
        }
    }
    
    // MARK: - Initialization
    init(
        id: String = UUID().uuidString,
        sessionId: String,
        content: String,
        role: MessageRole,
        timestamp: Date = Date(),
        metadata: MessageMetadata? = nil
    ) {
        self.id = id
        self.sessionId = sessionId
        self.content = content
        self.role = role
        self.timestamp = timestamp
        self.createdAt = Date()
        self.updatedAt = Date()
        self.metadata = metadata
    }
    
    // Convenience initializer for quick creation
    convenience init(
        id: String = UUID().uuidString,
        role: MessageRole,
        content: String
    ) {
        self.init(
            id: id,
            sessionId: "",  // Will be set when adding to session
            content: content,
            role: role
        )
    }
    
    // MARK: - Methods
    func updateContent(_ newContent: String) {
        self.content = newContent
        self.updatedAt = Date()
    }
    
    func appendContent(_ additionalContent: String) {
        self.content += additionalContent
        self.updatedAt = Date()
    }
    
    func markAsError(_ errorMessage: String? = nil) {
        self.isError = true
        if let errorMessage = errorMessage {
            var meta = self.metadata ?? MessageMetadata()
            meta.error = errorMessage
            self.metadata = meta
        }
        self.updatedAt = Date()
    }
    
    func markAsAborted() {
        self.isAborted = true
        self.isStreaming = false
        var meta = self.metadata ?? MessageMetadata()
        meta.aborted = true
        meta.streamCompleted = false
        self.metadata = meta
        self.updatedAt = Date()
    }
    
    func startStreaming() {
        self.isStreaming = true
        self.content = ""
        self.updatedAt = Date()
    }
    
    func finishStreaming() {
        self.isStreaming = false
        var meta = self.metadata ?? MessageMetadata()
        meta.streamCompleted = true
        self.metadata = meta
        self.updatedAt = Date()
    }
}

// MARK: - Codable Extension for API Integration
extension Message {
    // Convert from API DTO
    static func from(dto: MessageDTO, sessionId: String) -> Message {
        let message = Message(
            id: dto.id ?? UUID().uuidString,
            sessionId: sessionId,
            content: dto.content,
            role: MessageRole(rawValue: dto.role) ?? .user,
            timestamp: dto.timestamp ?? Date()
        )
        
        // Parse any additional metadata from the DTO if needed
        return message
    }
    
    // Convert to API request format
    func toAPIFormat() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "sessionId": sessionId,
            "content": content,
            "role": role.rawValue,
            "timestamp": ISO8601DateFormatter().string(from: timestamp)
        ]
        
        // Include metadata if present
        if let metadata = metadata {
            if let model = metadata.model {
                dict["model"] = model
            }
            if let tokens = metadata.tokens {
                dict["tokens"] = tokens
            }
            if let projectPath = metadata.projectPath {
                dict["projectPath"] = projectPath
            }
        }
        
        return dict
    }
    
    // Create from WebSocket message
    static func from(webSocketPayload: [String: Any], sessionId: String) -> Message? {
        guard let content = webSocketPayload["content"] as? String else { return nil }
        
        let roleString = webSocketPayload["role"] as? String ?? "assistant"
        let role = MessageRole(rawValue: roleString) ?? .assistant
        
        let message = Message(
            id: webSocketPayload["id"] as? String ?? UUID().uuidString,
            sessionId: sessionId,
            content: content,
            role: role,
            timestamp: Date()
        )
        
        // Parse metadata
        var metadata = MessageMetadata()
        metadata.model = webSocketPayload["model"] as? String
        metadata.tokens = webSocketPayload["tokens"] as? Int
        metadata.projectPath = webSocketPayload["projectPath"] as? String
        metadata.commandType = webSocketPayload["type"] as? String
        message.metadata = metadata
        
        return message
    }
}

// MARK: - Message Collection Extensions
extension [Message] {
    // Sort messages by timestamp
    func sortedByTimestamp(ascending: Bool = true) -> [Message] {
        return self.sorted { ascending ? $0.timestamp < $1.timestamp : $0.timestamp > $1.timestamp }
    }
    
    // Filter messages by role
    func filtered(by role: MessageRole) -> [Message] {
        return self.filter { $0.role == role }
    }
    
    // Get last message from user
    var lastUserMessage: Message? {
        return self.reversed().first { $0.role.isUser }
    }
    
    // Get last assistant message
    var lastAssistantMessage: Message? {
        return self.reversed().first { $0.role == .assistant }
    }
}