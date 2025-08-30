//
//  AppConfig.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/05.
//

import Foundation
import CoreGraphics

/// App configuration settings
struct AppConfig {
    
    // MARK: - Network Configuration
    
    /// Backend URL - can be configured via environment variable or UserDefaults
    static var backendURL: String = {
        // First check environment variable
        if let envURL = ProcessInfo.processInfo.environment["BACKEND_URL"] {
            return envURL
        }
        // Then check UserDefaults
        if let savedURL = UserDefaults.standard.string(forKey: "backendURL") {
            return savedURL
        }
        // Default for development
        return "http://192.168.0.43:3004"
    }()
    
    /// Default backend URL for resetting
    private static let defaultBackendURL = "http://192.168.0.43:3004"
    
    /// WebSocket URLs derived from backend URL
    static var websocketURL: String {
        let base = backendURL
        if base.hasPrefix("https://") {
            return base.replacingOccurrences(of: "https://", with: "wss://") + "/ws"
        } else if base.hasPrefix("http://") {
            return base.replacingOccurrences(of: "http://", with: "ws://") + "/ws"
        }
        return "ws://\(base)/ws"
    }
    
    static var shellWebSocketURL: String {
        let base = backendURL
        if base.hasPrefix("https://") {
            return base.replacingOccurrences(of: "https://", with: "wss://") + "/shell"
        } else if base.hasPrefix("http://") {
            return base.replacingOccurrences(of: "http://", with: "ws://") + "/shell"
        }
        return "ws://\(base)/shell"
    }
    
    /// Backend host (extracted from URL)
    static var backendHost: String {
        if let url = URL(string: backendURL),
           let host = url.host {
            return host
        }
        return "192.168.0.43"
    }
    
    static var backendPort: Int {
        if let url = URL(string: backendURL),
           let port = url.port {
            return port
        }
        return 3004
    }
    
    // MARK: - API Endpoints (Hardcoded for consistency)
    
    struct Endpoints {
        // Authentication
        static let authRegister = "/api/auth/register"
        static let authLogin = "/api/auth/login"
        static let authStatus = "/api/auth/status"
        static let authUser = "/api/auth/user"
        static let authLogout = "/api/auth/logout"
        
        // Projects
        static let projects = "/api/projects"
        static let projectsCreate = "/api/projects/create"
        static func projectRename(_ name: String) -> String { "/api/projects/\(name)/rename" }
        static func projectDelete(_ name: String) -> String { "/api/projects/\(name)" }
        
        // Sessions
        static func projectSessions(_ name: String) -> String { "/api/projects/\(name)/sessions" }
        static func sessionMessages(_ project: String, _ session: String) -> String {
            "/api/projects/\(project)/sessions/\(session)/messages"
        }
        static func sessionDelete(_ project: String, _ session: String) -> String {
            "/api/projects/\(project)/sessions/\(session)"
        }
        
        // Files
        static func projectFiles(_ name: String) -> String { "/api/projects/\(name)/files" }
        static func projectFile(_ name: String) -> String { "/api/projects/\(name)/file" }
        
        // Git (Future implementation)
        static let gitStatus = "/api/git/status"
        static let gitCommit = "/api/git/commit"
        static let gitBranches = "/api/git/branches"
        static let gitPush = "/api/git/push"
        static let gitPull = "/api/git/pull"
        
        // MCP Servers (Future implementation)
        static let mcpServers = "/api/mcp/servers"
        static let mcpAdd = "/api/mcp/add"
        static let mcpRemove = "/api/mcp/remove"
        
        // Cursor Integration (Future implementation)
        static let cursorConfig = "/api/cursor/config"
        static let cursorSessions = "/api/cursor/sessions"
    }
    
    // MARK: - WebSocket Message Types (Hardcoded)
    
    struct WebSocketMessageTypes {
        static let claudeCommand = "claude-command"
        static let cursorCommand = "cursor-command"
        static let claudeOutput = "claude-output"
        static let claudeResponse = "claude-response"
        static let toolUse = "tool_use"
        static let sessionCreated = "session-created"
        static let abortSession = "abort-session"
        static let error = "error"
        static let ping = "ping"
        static let pong = "pong"
    }
    
    // MARK: - API Configuration
    
    /// API request timeout
    static let apiTimeout: TimeInterval = 30.0
    
    /// WebSocket reconnection attempts
    static let websocketReconnectAttempts = 5
    
    /// WebSocket reconnection delay
    static let websocketReconnectDelay: TimeInterval = 2.0
    
    // MARK: - App Configuration
    
    /// Enable debug logging
    static let enableDebugLogging = true
    
    /// Debug mode flag
    static var isDebugMode = false
    
    /// Code editor font size
    static var codeFontSize: CGFloat = 14.0
    
    /// Enable crash reporting
    static let enableCrashReporting = true
    
    /// Maximum file size for uploads (in bytes)
    static let maxFileUploadSize: Int64 = 10 * 1024 * 1024 // 10MB
    
    // MARK: - UI Configuration
    
    /// Enable haptic feedback
    static var enableHapticFeedback = true
    
    /// Animation duration
    static let animationDuration: TimeInterval = 0.3
    
    /// Keyboard animation duration
    static let keyboardAnimationDuration: TimeInterval = 0.25
    
    // MARK: - Configuration Methods
    
    /// Update the backend URL
    static func updateBackendURL(_ url: String) {
        backendURL = url
        // Save to UserDefaults for persistence
        UserDefaults.standard.set(url, forKey: "backendURL")
    }
    
    /// Reset backend URL to default
    static func resetBackendURL() {
        backendURL = defaultBackendURL
        UserDefaults.standard.removeObject(forKey: "backendURL")
    }
    
    /// Load saved configuration
    static func loadConfiguration() {
        if let savedURL = UserDefaults.standard.string(forKey: "backendURL") {
            backendURL = savedURL
        }
    }
    
    // MARK: - Hardcoded Configuration Notes
    
    /// All configurations are now hardcoded for consistency.
    /// To change the backend server:
    /// 1. Update backendURL above to your server address
    /// 2. Update websocketURL and shellWebSocketURL accordingly
    /// 3. Rebuild the app
    ///
    /// For production deployment:
    /// - Change "localhost" to your production server domain
    /// - Update from "http://" and "ws://" to "https://" and "wss://" for SSL
    /// - Consider using environment-specific build configurations
}