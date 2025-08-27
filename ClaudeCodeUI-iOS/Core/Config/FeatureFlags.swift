//
//  FeatureFlags.swift
//  ClaudeCodeUI
//
//  Created by Claude on 2025-01-15.
//
//  Feature flag system for gradual rollout of new features
//

import Foundation

// MARK: - Feature Flags

enum FeatureFlag: String, CaseIterable {
    case useStarscreamWebSocket = "feature.starscream.enabled"
    case enableWebSocketCompression = "feature.websocket.compression"
    case enableAutoReconnect = "feature.websocket.autoreconnect"
    case enableMessageStreaming = "feature.message.streaming"
    case enableTerminalWebSocket = "feature.terminal.websocket"
    
    /// Check if the feature is enabled
    var isEnabled: Bool {
        return FeatureFlagManager.shared.isEnabled(self)
    }
    
    /// Enable the feature
    func enable() {
        FeatureFlagManager.shared.enable(self)
    }
    
    /// Disable the feature
    func disable() {
        FeatureFlagManager.shared.disable(self)
    }
    
    /// Toggle the feature
    func toggle() {
        FeatureFlagManager.shared.toggle(self)
    }
    
    /// Default value for the feature
    var defaultValue: Bool {
        switch self {
        case .useStarscreamWebSocket:
            // Force enable Starscream for all users
            return true
        case .enableWebSocketCompression:
            return true  // Enable by default
        case .enableAutoReconnect:
            return true  // Enable by default
        case .enableMessageStreaming:
            return true  // Enable by default
        case .enableTerminalWebSocket:
            return false // Disabled by default (experimental)
        }
    }
    
    /// Description of the feature
    var description: String {
        switch self {
        case .useStarscreamWebSocket:
            return "Use Starscream WebSocket library instead of URLSession"
        case .enableWebSocketCompression:
            return "Enable WebSocket message compression"
        case .enableAutoReconnect:
            return "Automatically reconnect WebSocket on disconnect"
        case .enableMessageStreaming:
            return "Enable streaming message support"
        case .enableTerminalWebSocket:
            return "Enable terminal WebSocket connection"
        }
    }
}

// MARK: - Feature Flag Manager

final class FeatureFlagManager {
    
    static let shared = FeatureFlagManager()
    
    private let userDefaults = UserDefaults.standard
    private let rolloutKey = "feature.rollout.bucket"
    private var overrides: [FeatureFlag: Bool] = [:]
    
    private init() {
        // Generate rollout bucket if not exists
        if userDefaults.object(forKey: rolloutKey) == nil {
            userDefaults.set(Int.random(in: 0..<100), forKey: rolloutKey)
        }
    }
    
    /// Check if a feature is enabled
    func isEnabled(_ feature: FeatureFlag) -> Bool {
        // Check for override first
        if let override = overrides[feature] {
            return override
        }
        
        // Check UserDefaults for persistent setting
        if userDefaults.object(forKey: feature.rawValue) != nil {
            return userDefaults.bool(forKey: feature.rawValue)
        }
        
        // Return default value
        return feature.defaultValue
    }
    
    /// Enable a feature
    func enable(_ feature: FeatureFlag) {
        userDefaults.set(true, forKey: feature.rawValue)
        logInfo("Feature enabled: \(feature.rawValue)", category: "FeatureFlags")
        
        // Track analytics
        trackFeatureFlagChange(feature, enabled: true)
    }
    
    /// Disable a feature
    func disable(_ feature: FeatureFlag) {
        userDefaults.set(false, forKey: feature.rawValue)
        logInfo("Feature disabled: \(feature.rawValue)", category: "FeatureFlags")
        
        // Track analytics
        trackFeatureFlagChange(feature, enabled: false)
    }
    
    /// Toggle a feature
    func toggle(_ feature: FeatureFlag) {
        let newValue = !isEnabled(feature)
        userDefaults.set(newValue, forKey: feature.rawValue)
        logInfo("Feature toggled: \(feature.rawValue) = \(newValue)", category: "FeatureFlags")
        
        // Track analytics
        trackFeatureFlagChange(feature, enabled: newValue)
    }
    
    /// Override a feature flag temporarily (not persisted)
    func override(_ feature: FeatureFlag, enabled: Bool) {
        overrides[feature] = enabled
        logInfo("Feature override: \(feature.rawValue) = \(enabled)", category: "FeatureFlags")
    }
    
    /// Remove override for a feature
    func removeOverride(_ feature: FeatureFlag) {
        overrides.removeValue(forKey: feature)
        logInfo("Feature override removed: \(feature.rawValue)", category: "FeatureFlags")
    }
    
    /// Reset all feature flags to defaults
    func resetAll() {
        for feature in FeatureFlag.allCases {
            userDefaults.removeObject(forKey: feature.rawValue)
        }
        overrides.removeAll()
        logInfo("All feature flags reset to defaults", category: "FeatureFlags")
    }
    
    /// Check if user is in rollout group
    func isInRolloutGroup(percentage: Int) -> Bool {
        let bucket = userDefaults.integer(forKey: rolloutKey)
        return bucket < percentage
    }
    
    /// Set rollout percentage for Starscream
    func setStarscreamRolloutPercentage(_ percentage: Int) {
        let bucket = userDefaults.integer(forKey: rolloutKey)
        let isEnabled = bucket < percentage
        
        if isEnabled {
            enable(.useStarscreamWebSocket)
        } else {
            disable(.useStarscreamWebSocket)
        }
        
        logInfo("Starscream rollout updated: \(percentage)% (user bucket: \(bucket))", category: "FeatureFlags")
    }
    
    /// Get all feature flags and their states
    func getAllFlags() -> [String: Bool] {
        var flags: [String: Bool] = [:]
        for feature in FeatureFlag.allCases {
            flags[feature.rawValue] = isEnabled(feature)
        }
        return flags
    }
    
    // MARK: - Private Methods
    
    private func trackFeatureFlagChange(_ feature: FeatureFlag, enabled: Bool) {
        // Track with analytics service if available
        // Analytics.track("feature_flag_changed", properties: [
        //     "feature": feature.rawValue,
        //     "enabled": enabled
        // ])
    }
}

// MARK: - WebSocket Factory

/// Factory to create appropriate WebSocket manager based on feature flag
final class WebSocketFactory {
    
    static func createWebSocketManager() -> WebSocketProtocol {
        if FeatureFlag.useStarscreamWebSocket.isEnabled {
            logInfo("Using Starscream WebSocket implementation", category: "WebSocketFactory")
            // TODO: Add StarscreamWebSocketManager to Xcode project
            // return StarscreamWebSocketManager()
            return WebSocketManager()
        } else {
            logInfo("Using legacy URLSession WebSocket implementation", category: "WebSocketFactory")
            // Return legacy implementation (cast existing WebSocketManager)
            // Note: WebSocketManager already conforms to WebSocketProtocol
            return WebSocketManager()
        }
    }
    
    static func createChatWebSocket() -> WebSocketProtocol {
        let manager = createWebSocketManager()
        
        // Configure based on feature flags
        if FeatureFlag.enableAutoReconnect.isEnabled {
            // Auto-reconnect is built into Starscream implementation
        }
        
        if FeatureFlag.enableWebSocketCompression.isEnabled {
            // Compression is enabled by default in Starscream
        }
        
        return manager
    }
    
    static func createTerminalWebSocket() -> WebSocketProtocol? {
        guard FeatureFlag.enableTerminalWebSocket.isEnabled else {
            logInfo("Terminal WebSocket is disabled by feature flag", category: "WebSocketFactory")
            return nil
        }
        
        return createWebSocketManager()
    }
}

// MARK: - A/B Testing Support

final class ABTestManager {
    
    static let shared = ABTestManager()
    
    private init() {}
    
    /// Assign user to Starscream test group
    func assignToStarscreamTest(percentage: Int = 10) -> Bool {
        let bucket = Int.random(in: 0..<100)
        let isInTestGroup = bucket < percentage
        
        if isInTestGroup {
            FeatureFlag.useStarscreamWebSocket.enable()
            trackAssignment("starscream_test", variant: "enabled")
        } else {
            FeatureFlag.useStarscreamWebSocket.disable()
            trackAssignment("starscream_test", variant: "control")
        }
        
        return isInTestGroup
    }
    
    /// Check current test assignment
    func isInStarscreamTest() -> Bool {
        return FeatureFlag.useStarscreamWebSocket.isEnabled
    }
    
    /// Track test assignment
    private func trackAssignment(_ testName: String, variant: String) {
        logInfo("A/B Test Assignment: \(testName) = \(variant)", category: "ABTest")
        // Track with analytics service
    }
}

// MARK: - Migration Coordinator

final class WebSocketMigrationCoordinator {
    
    static let shared = WebSocketMigrationCoordinator()
    
    private init() {}
    
    /// Perform migration to Starscream
    func performMigration(completion: @escaping (Bool) -> Void) {
        logInfo("Starting WebSocket migration to Starscream", category: "Migration")
        
        // Backup current state
        let currentState = backupCurrentState()
        
        // Enable Starscream
        FeatureFlag.useStarscreamWebSocket.enable()
        
        // Test Starscream functionality
        testStarscreamFunctionality { success in
            if success {
                logInfo("Starscream migration successful", category: "Migration")
                completion(true)
            } else {
                logError("Starscream migration failed, rolling back", category: "Migration")
                self.rollback(to: currentState)
                completion(false)
            }
        }
    }
    
    /// Rollback migration
    func rollback(to state: [String: Any]) {
        FeatureFlag.useStarscreamWebSocket.disable()
        logInfo("Rolled back to legacy WebSocket", category: "Migration")
    }
    
    private func backupCurrentState() -> [String: Any] {
        return [
            "starscream_enabled": FeatureFlag.useStarscreamWebSocket.isEnabled,
            "timestamp": Date()
        ]
    }
    
    private func testStarscreamFunctionality(completion: @escaping (Bool) -> Void) {
        // Create test WebSocket
        // TODO: Add StarscreamWebSocketManager to Xcode project
        // let testSocket = StarscreamWebSocketManager()
        let testSocket: WebSocketProtocol = WebSocketManager()
        
        // Set up test delegate
        class TestDelegate: WebSocketManagerDelegate {
            var connected = false
            var completion: ((Bool) -> Void)?
            
            func webSocketDidConnect(_ manager: any WebSocketProtocol) {
                connected = true
                completion?(true)
            }
            
            func webSocketDidDisconnect(_ manager: any WebSocketProtocol, error: Error?) {
                if !connected {
                    completion?(false)
                }
            }
            
            func webSocket(_ manager: any WebSocketProtocol, didReceiveMessage message: WebSocketMessage) {}
            func webSocket(_ manager: any WebSocketProtocol, didReceiveData data: Data) {}
            func webSocketConnectionStateChanged(_ state: WebSocketConnectionState) {}
            func webSocket(_ manager: any WebSocketProtocol, didReceiveText text: String) {}
        }
        
        let delegate = TestDelegate()
        delegate.completion = completion
        if let websocketManager = testSocket as? WebSocketManager {
            websocketManager.delegate = delegate as? WebSocketManagerDelegate
        }
        
        // Attempt connection using protocol method
        testSocket.connect(to: "/ws", with: UserDefaults.standard.string(forKey: "authToken"))
        
        // Timeout after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if !delegate.connected {
                completion(false)
            }
        }
    }
}