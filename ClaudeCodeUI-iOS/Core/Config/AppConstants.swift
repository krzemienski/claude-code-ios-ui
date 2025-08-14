//
//  AppConstants.swift
//  ClaudeCodeUI
//
//  Hardcoded constants for the Claude Code iOS UI app
//  All values are fixed for consistent development and testing
//

import Foundation
import UIKit

/// Global constants for the entire app
enum AppConstants {
    
    // MARK: - App Identity
    
    static let appName = "Claude Code"
    static let bundleIdentifier = "com.claudecode.ui"
    static let appVersion = "1.0.0"
    static let buildNumber = "1"
    
    // MARK: - Cyberpunk Theme Colors (Hardcoded)
    
    enum Colors {
        static let primaryCyan = UIColor(red: 0, green: 217/255, blue: 1, alpha: 1) // #00D9FF
        static let primaryPink = UIColor(red: 1, green: 6/255, blue: 110/255, alpha: 1) // #FF006E
        static let darkBackground = UIColor(red: 10/255, green: 10/255, blue: 20/255, alpha: 1)
        static let cardBackground = UIColor(red: 20/255, green: 20/255, blue: 30/255, alpha: 1)
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor(white: 0.7, alpha: 1)
        static let glowColor = UIColor(red: 0, green: 217/255, blue: 1, alpha: 0.6)
    }
    
    // MARK: - UI Dimensions
    
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let spacing: CGFloat = 16
        static let padding: CGFloat = 20
        static let iconSize: CGFloat = 24
        static let buttonHeight: CGFloat = 50
        static let textFieldHeight: CGFloat = 44
        static let navigationBarHeight: CGFloat = 44
        static let tabBarHeight: CGFloat = 49
        static let glowRadius: CGFloat = 20
        static let animationDuration: TimeInterval = 0.3
        static let keyboardAnimationDuration: TimeInterval = 0.25
    }
    
    // MARK: - Chat Configuration
    
    enum Chat {
        static let maxMessageLength = 4000
        static let typingIndicatorDelay: TimeInterval = 0.5
        static let messageStreamingDelay: TimeInterval = 0.05
        static let maxRetryAttempts = 3
        static let retryDelay: TimeInterval = 2.0
        static let sessionTimeoutMinutes = 30
    }
    
    // MARK: - File Management
    
    enum Files {
        static let maxFileSize: Int64 = 10 * 1024 * 1024 // 10MB
        static let supportedExtensions = ["swift", "js", "ts", "jsx", "tsx", "py", "rb", "go", "rs", "java", "kt", "cpp", "c", "h", "m", "mm", "md", "txt", "json", "xml", "yaml", "yml", "toml", "ini", "conf", "sh", "bash", "zsh", "fish"]
        static let imageExtensions = ["png", "jpg", "jpeg", "gif", "webp", "svg"]
        static let syntaxHighlightingEnabled = true
    }
    
    // MARK: - Terminal Configuration
    
    enum Terminal {
        static let fontSize: CGFloat = 13
        static let fontName = "Menlo"
        static let maxHistoryLines = 1000
        static let ansiColorsEnabled = true
        static let cursorBlinkRate: TimeInterval = 0.5
    }
    
    // MARK: - Session Management
    
    enum Sessions {
        static let maxSessionsPerProject = 100
        static let sessionCacheDuration: TimeInterval = 86400 // 24 hours
        static let autoSaveInterval: TimeInterval = 30 // 30 seconds
        static let maxMessagesPerSession = 1000
    }
    
    // MARK: - Authentication
    
    enum Auth {
        static let jwtExpirySeconds = 86400 // 24 hours
        static let refreshTokenExpiryDays = 30
        static let maxLoginAttempts = 5
        static let lockoutDurationMinutes = 15
        static let biometricAuthEnabled = true
    }
    
    // MARK: - Networking
    
    enum Network {
        static let requestTimeout: TimeInterval = 30
        static let uploadTimeout: TimeInterval = 60
        static let downloadTimeout: TimeInterval = 120
        static let maxConcurrentRequests = 5
        static let retryCount = 3
        static let cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
    }
    
    // MARK: - WebSocket
    
    enum WebSocket {
        static let reconnectAttempts = 5
        static let reconnectDelay: TimeInterval = 2.0
        static let heartbeatInterval: TimeInterval = 30
        static let messageQueueSize = 100
        static let compressionEnabled = true
    }
    
    // MARK: - Git Integration (Future)
    
    enum Git {
        static let defaultBranch = "main"
        static let commitMessageMaxLength = 72
        static let fetchInterval: TimeInterval = 300 // 5 minutes
    }
    
    // MARK: - Performance
    
    enum Performance {
        static let launchTimeTarget: TimeInterval = 2.0
        static let memoryWarningThreshold: Float = 150.0 // MB
        static let cpuUsageWarningThreshold: Float = 80.0 // Percentage
        static let fpsTarget = 60
    }
    
    // MARK: - Analytics
    
    enum Analytics {
        static let enabled = false // Disabled for privacy
        static let sessionTimeout: TimeInterval = 1800 // 30 minutes
        static let batchSize = 20
        static let flushInterval: TimeInterval = 60
    }
    
    // MARK: - Debug
    
    enum Debug {
        static let loggingEnabled = true
        static let verboseLogging = false
        static let networkLogging = true
        static let crashReportingEnabled = false
        static let mockDataEnabled = false
    }
    
    // MARK: - Onboarding
    
    enum Onboarding {
        static let numberOfPages = 6
        static let skipEnabled = true
        static let animationDuration: TimeInterval = 0.5
    }
    
    // MARK: - Accessibility
    
    enum Accessibility {
        static let voiceOverEnabled = true
        static let dynamicTypeEnabled = true
        static let reduceMotionRespected = true
        static let increaseContrastSupported = true
    }
    
    // MARK: - Storage Keys (UserDefaults)
    
    enum StorageKeys {
        static let hasCompletedOnboarding = "has_completed_onboarding"
        static let currentTheme = "current_theme"
        static let lastSyncDate = "last_sync_date"
        static let currentSessionId = "current_session_id"
        static let currentProjectName = "current_project_name"
        static let authToken = "auth_token"
        static let refreshToken = "refresh_token"
        static let userId = "user_id"
        static let username = "username"
    }
    
    // MARK: - Notification Names
    
    enum Notifications {
        static let sessionCreated = Notification.Name("SessionCreated")
        static let sessionDeleted = Notification.Name("SessionDeleted")
        static let projectCreated = Notification.Name("ProjectCreated")
        static let projectDeleted = Notification.Name("ProjectDeleted")
        static let themeChanged = Notification.Name("ThemeChanged")
        static let authStateChanged = Notification.Name("AuthStateChanged")
        static let networkStatusChanged = Notification.Name("NetworkStatusChanged")
    }
    
    // MARK: - Error Codes
    
    enum ErrorCodes {
        static let networkError = 1001
        static let authenticationError = 1002
        static let validationError = 1003
        static let serverError = 1004
        static let dataCorruption = 1005
        static let fileNotFound = 1006
        static let permissionDenied = 1007
        static let quotaExceeded = 1008
    }
    
    // MARK: - Regular Expressions
    
    enum Regex {
        static let email = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        static let projectName = "^[a-zA-Z0-9-_]{3,50}$"
        static let fileName = "^[a-zA-Z0-9-_.]{1,255}$"
        static let gitBranch = "^[a-zA-Z0-9/_-]{1,100}$"
    }
}

// MARK: - Type Aliases for Convenience

typealias AC = AppConstants
typealias ACColors = AppConstants.Colors
typealias ACUI = AppConstants.UI