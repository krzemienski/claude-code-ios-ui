//
//  Settings.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import Foundation
import SwiftData
import UIKit

@Model
final class Settings {
    @Attribute(.unique) var id: String
    
    // Authentication
    var authToken: String?
    var authTokenExpiresAt: Date?
    var isFaceIDEnabled: Bool
    
    // API Configuration  
    var apiBaseURL: String
    var webSocketURL: String
    var apiTimeout: TimeInterval
    var webSocketReconnectDelay: TimeInterval
    var maxReconnectAttempts: Int
    
    // UI Preferences
    var theme: ThemePreference
    var fontSize: FontSize
    var showCodeLineNumbers: Bool
    var enableSyntaxHighlighting: Bool
    
    // Session Management
    var autoSaveInterval: TimeInterval
    var maxSessionHistory: Int
    var clearCacheOnExit: Bool
    
    // Developer Options
    var enableDebugLogging: Bool
    var showNetworkActivity: Bool
    var enableCrashReporting: Bool
    
    // App State
    var lastActiveProjectId: String?
    var lastSyncDate: Date?
    var appVersion: String
    
    init(id: String = "default") {
        self.id = id
        
        // Default values
        self.isFaceIDEnabled = true
        self.apiBaseURL = "http://localhost:3001"
        self.webSocketURL = "ws://localhost:3001"
        self.apiTimeout = 30.0
        self.webSocketReconnectDelay = 2.0
        self.maxReconnectAttempts = 5
        
        self.theme = .cyberpunk
        self.fontSize = .medium
        self.showCodeLineNumbers = true
        self.enableSyntaxHighlighting = true
        
        self.autoSaveInterval = 30.0
        self.maxSessionHistory = 100
        self.clearCacheOnExit = false
        
        self.enableDebugLogging = false
        self.showNetworkActivity = false
        self.enableCrashReporting = true
        
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

// MARK: - Supporting Types
enum ThemePreference: String, Codable {
    case cyberpunk
    case dark
    case light
}

enum FontSize: String, Codable {
    case small
    case medium
    case large
    case extraLarge
    
    var pointSize: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 14
        case .large: return 16
        case .extraLarge: return 18
        }
    }
}

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
    
    // Relationship back to project
    var project: Project?
    
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

// MARK: - SessionDTO (for API integration)
struct SessionDTO: Codable {
    let id: String
    let projectId: String?
    let summary: String?
    let messageCount: Int?
    let lastActivity: Date?
    let cwd: String?
    let status: String?
}