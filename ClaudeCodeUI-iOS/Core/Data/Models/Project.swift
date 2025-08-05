//
//  Project.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import Foundation
#if canImport(SwiftData)
import SwiftData
#endif

@Model
final class Project {
    @Attribute(.unique) var id: String
    var name: String
    var path: String
    var displayName: String?
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Session.project)
    var sessions: [Session]?
    
    @Transient
    var sessionCount: Int {
        sessions?.count ?? 0
    }
    
    @Transient
    var lastSessionDate: Date? {
        sessions?.max(by: { $0.lastActiveAt < $1.lastActiveAt })?.lastActiveAt
    }
    
    init(id: String = UUID().uuidString, 
         name: String, 
         path: String, 
         displayName: String? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.path = path
        self.displayName = displayName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sessions = []
    }
}

// MARK: - Session Model
@Model
final class Session {
    @Attribute(.unique) var id: String
    var projectId: String
    var startedAt: Date
    var lastActiveAt: Date
    var status: SessionStatus
    
    @Relationship(deleteRule: .nullify)
    var project: Project?
    
    @Relationship(deleteRule: .cascade, inverse: \Message.session)
    var messages: [Message]?
    
    @Transient
    var messageCount: Int {
        messages?.count ?? 0
    }
    
    init(id: String = UUID().uuidString, projectId: String) {
        self.id = id
        self.projectId = projectId
        self.startedAt = Date()
        self.lastActiveAt = Date()
        self.status = .active
        self.messages = []
    }
}

// MARK: - Message Model
@Model
final class Message {
    @Attribute(.unique) var id: String
    var role: MessageRole
    var content: String
    var timestamp: Date
    
    @Relationship(deleteRule: .nullify)
    var session: Session?
    
    // Store metadata as Data (JSON encoded)
    var metadataData: Data?
    
    @Transient
    var metadata: MessageMetadata? {
        get {
            guard let data = metadataData else { return nil }
            return try? JSONDecoder().decode(MessageMetadata.self, from: data)
        }
        set {
            metadataData = try? JSONEncoder().encode(newValue)
        }
    }
    
    init(id: String = UUID().uuidString, role: MessageRole, content: String) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

// MARK: - Supporting Types
enum SessionStatus: String, Codable {
    case active
    case completed
    case aborted
}

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

struct MessageMetadata: Codable {
    let model: String?
    let temperature: Double?
    let maxTokens: Int?
    let stopSequence: [String]?
    let toolUse: [ToolUse]?
}

struct ToolUse: Codable {
    let name: String
    let input: [String: Any]?
    let output: [String: Any]?
    
    // Custom encoding/decoding for Any types
    enum CodingKeys: String, CodingKey {
        case name, input, output
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        
        if let inputData = try? container.decode(Data.self, forKey: .input) {
            input = try? JSONSerialization.jsonObject(with: inputData) as? [String: Any]
        } else {
            input = nil
        }
        
        if let outputData = try? container.decode(Data.self, forKey: .output) {
            output = try? JSONSerialization.jsonObject(with: outputData) as? [String: Any]
        } else {
            output = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        
        if let input = input {
            let data = try JSONSerialization.data(withJSONObject: input)
            try container.encode(data, forKey: .input)
        }
        
        if let output = output {
            let data = try JSONSerialization.data(withJSONObject: output)
            try container.encode(data, forKey: .output)
        }
    }
}