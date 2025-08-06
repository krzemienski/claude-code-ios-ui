//
//  AppConfig.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/05.
//

import Foundation

/// App configuration settings
struct AppConfig {
    
    // MARK: - Network Configuration
    
    /// Backend server URL
    /// For local development: "http://192.168.0.36:3004"
    /// For production: Update to your server URL
    static var backendURL: String {
        // Check if there's a saved URL in UserDefaults
        if let savedURL = UserDefaults.standard.string(forKey: "backend_url") {
            return savedURL
        }
        
        // Default to localhost for simulator
        #if targetEnvironment(simulator)
        return "http://localhost:3004"  // Test backend server port
        #else
        // For device, use the machine's IP address
        return "http://192.168.0.36:3004"  // Test backend server port
        #endif
    }
    
    /// WebSocket URL
    static var websocketURL: String {
        let httpURL = backendURL
        let wsURL = httpURL.replacingOccurrences(of: "http://", with: "ws://")
                          .replacingOccurrences(of: "https://", with: "wss://")
        return "\(wsURL)/ws"
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
    
    /// Enable crash reporting
    static let enableCrashReporting = true
    
    /// Maximum file size for uploads (in bytes)
    static let maxFileUploadSize: Int64 = 10 * 1024 * 1024 // 10MB
    
    // MARK: - UI Configuration
    
    /// Enable haptic feedback
    static let enableHapticFeedback = true
    
    /// Animation duration
    static let animationDuration: TimeInterval = 0.3
    
    /// Keyboard animation duration
    static let keyboardAnimationDuration: TimeInterval = 0.25
    
    // MARK: - Methods
    
    /// Update the backend URL
    static func updateBackendURL(_ url: String) {
        UserDefaults.standard.set(url, forKey: "backend_url")
    }
    
    /// Reset to default backend URL
    static func resetBackendURL() {
        UserDefaults.standard.removeObject(forKey: "backend_url")
    }
}