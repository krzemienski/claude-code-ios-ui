//
//  Settings.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import Foundation
import SwiftData
import UIKit

@available(iOS 17.0, *)
@Model
final class Settings {
    @Attribute(.unique) var id: String = "default"
    
    // Authentication
    var authToken: String? = nil
    var authTokenExpiresAt: Date? = nil
    var isFaceIDEnabled: Bool = true
    
    // API Configuration  
    var apiBaseURL: String = "http://localhost:3004"
    var webSocketURL: String = "ws://localhost:3004"
    var apiTimeout: TimeInterval = 30.0
    var webSocketReconnectDelay: TimeInterval = 2.0
    var maxReconnectAttempts: Int = 5
    
    // UI Preferences
    var theme: ThemePreference
    var fontSize: FontSize
    var showCodeLineNumbers: Bool = true
    var enableSyntaxHighlighting: Bool = true
    
    // Session Management
    var autoSaveInterval: TimeInterval = 30.0
    var maxSessionHistory: Int = 100
    var clearCacheOnExit: Bool = false
    
    // Developer Options
    var enableDebugLogging: Bool = false
    var showNetworkActivity: Bool = false
    var enableCrashReporting: Bool = true
    
    // App State
    var lastActiveProjectId: String? = nil
    var lastSyncDate: Date? = nil
    var appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    
    init(id: String = "default") {
        self.id = id
        
        // Default values
        self.isFaceIDEnabled = true
        self.apiBaseURL = "http://localhost:3004"
        self.webSocketURL = "ws://localhost:3004"
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

// MARK: - Session Model
// Session model and SessionStatus have been moved to Models/Session.swift to avoid duplication
/*
@available(iOS 17.0, *)
@Model
final class Session {
    // MARK: - Properties
    @Attribute(.unique) var id: String = UUID().uuidString
    var projectId: String = ""
    var summary: String? = nil
    var messageCount: Int = 0
    var lastActivity: Date? = nil
    var cwd: String? = nil  // Current working directory from backend
    var status: SessionStatus
    
    // Timestamps
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Additional backend-specific fields
    var startedAt: Date? = nil
    var lastActiveAt: Date? = nil
    
    // MARK: - Relationships
    @Relationship(deleteRule: .cascade)
    var messages: [Message]? = []
    
    // Relationship back to project
    var project: Project? = nil
    
    // MARK: - Initialization
    init(
        id: String = UUID().uuidString,
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
*/

// SessionDTO has been moved to Models/Session.swift