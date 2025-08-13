//
//  Session.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-12-13.
//

import Foundation
import SwiftData

// MARK: - Session Status
enum SessionStatus: String, Codable {
    case active = "active"
    case inactive = "inactive"
    case archived = "archived"
}

// MARK: - Session Model
@Model
final class Session {
    // MARK: - Properties
    @Attribute(.unique) var id: String
    var projectId: String
    var summary: String?
    var messageCount: Int
    var lastActivity: Date?
    var cwd: String?  // Current working directory from backend
    var status: SessionStatus
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    
    // Additional backend-specific fields
    var startedAt: Date?
    var lastActiveAt: Date?
    
    // MARK: - Relationships
    @Relationship(deleteRule: .cascade)
    var messages: [Message]?
    
    // MARK: - Initialization
    init(
        id: String,
        projectId: String,
        summary: String? = nil,
        messageCount: Int = 0,
        lastActivity: Date? = nil,
        cwd: String? = nil,
        status: SessionStatus = .active
    ) {
        self.id = id
        self.projectId = projectId
        self.summary = summary
        self.messageCount = messageCount
        self.lastActivity = lastActivity
        self.cwd = cwd
        self.status = status
        self.createdAt = Date()
        self.updatedAt = Date()
        self.startedAt = lastActivity
        self.lastActiveAt = lastActivity
        self.messages = []
    }
    
    // MARK: - Computed Properties
    var displaySummary: String {
        return summary ?? "New Session"
    }
    
    var lastActivityFormatted: String {
        guard let lastActivity = lastActivity else {
            return "No activity"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastActivity, relativeTo: Date())
    }
    
    var isActive: Bool {
        return status == .active
    }
    
    // MARK: - Methods
    func updateActivity() {
        self.lastActivity = Date()
        self.lastActiveAt = Date()
        self.updatedAt = Date()
    }
    
    func incrementMessageCount() {
        self.messageCount += 1
        updateActivity()
    }
}

// MARK: - Codable Extension for API Integration
extension Session {
    // Convert from API DTO
    static func from(dto: SessionDTO, projectId: String) -> Session {
        let session = Session(
            id: dto.id,
            projectId: projectId,
            summary: dto.summary,
            messageCount: dto.messageCount ?? 0,
            lastActivity: dto.lastActivity,
            cwd: dto.cwd,
            status: SessionStatus(rawValue: dto.status ?? "active") ?? .active
        )
        return session
    }
    
    // Convert to API request format
    func toAPIFormat() -> [String: Any] {
        return [
            "id": id,
            "projectId": projectId,
            "summary": summary ?? "",
            "messageCount": messageCount,
            "lastActivity": ISO8601DateFormatter().string(from: lastActivity ?? Date()),
            "cwd": cwd ?? "",
            "status": status.rawValue
        ]
    }
}

// MARK: - SessionDTO (moved from APIClient for consistency)
struct SessionDTO: Codable {
    let id: String
    let projectId: String?
    let summary: String?
    let messageCount: Int?
    let lastActivity: Date?
    let cwd: String?
    let status: String?
}