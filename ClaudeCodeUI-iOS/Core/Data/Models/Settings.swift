//
//  Settings.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import Foundation
import SwiftData

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