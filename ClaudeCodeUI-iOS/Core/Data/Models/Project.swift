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

@available(iOS 17.0, *)
@Model
final class Project: Codable {
    @Attribute(.unique) var id: String = UUID().uuidString
    var name: String = ""
    var path: String = ""
    var fullPath: String? = nil
    var displayName: String? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Temporarily disabled due to circular dependency
    // @Relationship(deleteRule: .cascade, inverse: \Session.project)
    // @Transient
    // var sessions: [Session]? = []
    
    @Transient
    var sessionCount: Int {
        // Temporarily return 0 until sessions relationship is fixed
        return 0
    }
    
    @Transient
    var lastSessionDate: Date? {
        // Temporarily disabled
        return nil
    }
    
    init(id: String = UUID().uuidString, 
         name: String, 
         path: String, 
         fullPath: String? = nil,
         displayName: String? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.path = path
        self.fullPath = fullPath
        self.displayName = displayName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        // self.sessions = [] // Temporarily disabled
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case path
        case fullPath = "full_path"
        case displayName = "display_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Make id optional and generate from name if not present
        if let id = try container.decodeIfPresent(String.self, forKey: .id) {
            self.id = id
        } else {
            // Generate id from name if backend doesn't provide one
            let name = try container.decode(String.self, forKey: .name)
            self.id = name // Use name as id for backend compatibility
        }
        self.name = try container.decode(String.self, forKey: .name)
        self.path = try container.decode(String.self, forKey: .path)
        self.fullPath = try container.decodeIfPresent(String.self, forKey: .fullPath)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        // self.sessions = [] // Temporarily disabled
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(path, forKey: .path)
        try container.encodeIfPresent(fullPath, forKey: .fullPath)
        try container.encodeIfPresent(displayName, forKey: .displayName)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

// MARK: - Session Model
// Session class is now defined in Models/Session.swift
/*
@Model
final class Session: Codable {
    @Attribute(.unique) var id: String
    var projectId: String
    var startedAt: Date
    var lastActiveAt: Date
    var status: SessionStatus
    var summary: String?
    var cwd: String?  // Current working directory
    
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
        self.summary = nil
        self.cwd = nil
        self.messages = []
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id
        case projectId
        case startedAt
        case lastActiveAt
        case status
        case summary
        case cwd
        case messageCount
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.projectId = try container.decodeIfPresent(String.self, forKey: .projectId) ?? ""
        self.startedAt = try container.decodeIfPresent(Date.self, forKey: .startedAt) ?? Date()
        self.lastActiveAt = try container.decodeIfPresent(Date.self, forKey: .lastActiveAt) ?? Date()
        let statusString = try container.decodeIfPresent(String.self, forKey: .status) ?? "active"
        self.status = SessionStatus(rawValue: statusString) ?? .active
        self.summary = try container.decodeIfPresent(String.self, forKey: .summary)
        self.cwd = try container.decodeIfPresent(String.self, forKey: .cwd)
        self.messages = []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(startedAt, forKey: .startedAt)
        try container.encode(lastActiveAt, forKey: .lastActiveAt)
        try container.encode(status.rawValue, forKey: .status)
        try container.encodeIfPresent(summary, forKey: .summary)
        try container.encodeIfPresent(cwd, forKey: .cwd)
        try container.encode(messageCount, forKey: .messageCount)
    }
}
*/

// MARK: - Message Model
@available(iOS 17.0, *)
@Model
final class Message {
    @Attribute(.unique) var id: String = UUID().uuidString
    var role: MessageRole
    var content: String = ""
    var timestamp: Date = Date()
    
    // Temporarily disabled due to Session import issue
    // @Relationship(deleteRule: .nullify)
    // var session: Session?
    
    // Store metadata as Data (JSON encoded)
    var metadataData: Data? = nil
    
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
// Commented out - using SessionStatus from Session.swift instead
// enum SessionStatus: String, Codable {
//     case active
//     case completed
//     case aborted
// }

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