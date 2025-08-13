//
//  Settings.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-08.
//

import Foundation
import SwiftData

@Model
final class Settings {
    @Attribute(.unique) var id: String = "default"
    var apiBaseURL: String
    var theme: String
    var fontSize: Int
    var fontFamily: String
    var showLineNumbers: Bool
    var enableSyntaxHighlighting: Bool
    var autoSave: Bool
    var autoSaveInterval: Int // seconds
    var enableWebSocket: Bool
    var webSocketReconnectDelay: Int // milliseconds
    var maxReconnectAttempts: Int
    var enableNotifications: Bool
    var enableHapticFeedback: Bool
    var enableDebugMode: Bool
    var metadata: [String: String]?
    var lastUpdated: Date
    var authToken: String?
    var lastUsername: String?
    var webSocketURL: String?
    
    init() {
        self.id = "default"
        self.apiBaseURL = "http://localhost:3004"
        self.theme = "cyberpunk"
        self.fontSize = 14
        self.fontFamily = "SF Mono"
        self.showLineNumbers = true
        self.enableSyntaxHighlighting = true
        self.autoSave = true
        self.autoSaveInterval = 30
        self.enableWebSocket = true
        self.webSocketReconnectDelay = 1000
        self.maxReconnectAttempts = 10
        self.enableNotifications = true
        self.enableHapticFeedback = true
        self.enableDebugMode = false
        self.metadata = [:]
        self.lastUpdated = Date()
    }
}

extension Settings: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case apiBaseURL
        case theme
        case fontSize
        case fontFamily
        case showLineNumbers
        case enableSyntaxHighlighting
        case autoSave
        case autoSaveInterval
        case enableWebSocket
        case webSocketReconnectDelay
        case maxReconnectAttempts
        case enableNotifications
        case enableHapticFeedback
        case enableDebugMode
        case metadata
        case lastUpdated
    }
    
    convenience init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode all properties with defaults
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? "default"
        self.apiBaseURL = try container.decodeIfPresent(String.self, forKey: .apiBaseURL) ?? "http://localhost:3004"
        self.theme = try container.decodeIfPresent(String.self, forKey: .theme) ?? "cyberpunk"
        self.fontSize = try container.decodeIfPresent(Int.self, forKey: .fontSize) ?? 14
        self.fontFamily = try container.decodeIfPresent(String.self, forKey: .fontFamily) ?? "SF Mono"
        self.showLineNumbers = try container.decodeIfPresent(Bool.self, forKey: .showLineNumbers) ?? true
        self.enableSyntaxHighlighting = try container.decodeIfPresent(Bool.self, forKey: .enableSyntaxHighlighting) ?? true
        self.autoSave = try container.decodeIfPresent(Bool.self, forKey: .autoSave) ?? true
        self.autoSaveInterval = try container.decodeIfPresent(Int.self, forKey: .autoSaveInterval) ?? 30
        self.enableWebSocket = try container.decodeIfPresent(Bool.self, forKey: .enableWebSocket) ?? true
        self.webSocketReconnectDelay = try container.decodeIfPresent(Int.self, forKey: .webSocketReconnectDelay) ?? 1000
        self.maxReconnectAttempts = try container.decodeIfPresent(Int.self, forKey: .maxReconnectAttempts) ?? 10
        self.enableNotifications = try container.decodeIfPresent(Bool.self, forKey: .enableNotifications) ?? true
        self.enableHapticFeedback = try container.decodeIfPresent(Bool.self, forKey: .enableHapticFeedback) ?? true
        self.enableDebugMode = try container.decodeIfPresent(Bool.self, forKey: .enableDebugMode) ?? false
        self.metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata)
        
        // Handle date decoding with ISO8601 format for backend compatibility
        if let dateString = try? container.decode(String.self, forKey: .lastUpdated) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            self.lastUpdated = formatter.date(from: dateString) ?? Date()
        } else if let date = try? container.decode(Date.self, forKey: .lastUpdated) {
            self.lastUpdated = date
        } else {
            self.lastUpdated = Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(apiBaseURL, forKey: .apiBaseURL)
        try container.encode(theme, forKey: .theme)
        try container.encode(fontSize, forKey: .fontSize)
        try container.encode(fontFamily, forKey: .fontFamily)
        try container.encode(showLineNumbers, forKey: .showLineNumbers)
        try container.encode(enableSyntaxHighlighting, forKey: .enableSyntaxHighlighting)
        try container.encode(autoSave, forKey: .autoSave)
        try container.encode(autoSaveInterval, forKey: .autoSaveInterval)
        try container.encode(enableWebSocket, forKey: .enableWebSocket)
        try container.encode(webSocketReconnectDelay, forKey: .webSocketReconnectDelay)
        try container.encode(maxReconnectAttempts, forKey: .maxReconnectAttempts)
        try container.encode(enableNotifications, forKey: .enableNotifications)
        try container.encode(enableHapticFeedback, forKey: .enableHapticFeedback)
        try container.encode(enableDebugMode, forKey: .enableDebugMode)
        try container.encodeIfPresent(metadata, forKey: .metadata)
        
        // Encode date as ISO8601 string for backend compatibility
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = formatter.string(from: lastUpdated)
        try container.encode(dateString, forKey: .lastUpdated)
    }
}

// MARK: - Settings Extensions for UI

extension Settings {
    var reconnectDelayTimeInterval: TimeInterval {
        return Double(webSocketReconnectDelay) / 1000.0
    }
    
    var autoSaveTimeInterval: TimeInterval {
        return Double(autoSaveInterval)
    }
    
    func export() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }
    
    static func importFrom(data: Data) throws -> Settings {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Settings.self, from: data)
    }
}