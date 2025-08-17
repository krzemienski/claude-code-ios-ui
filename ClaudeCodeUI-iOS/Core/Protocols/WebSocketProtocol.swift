//
//  WebSocketProtocol.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-16.
//
//  Shared protocol for WebSocket implementations
//

import Foundation

// MARK: - WebSocket Protocol
/// Protocol for WebSocket implementations to ensure consistency across different WebSocket libraries
public protocol WebSocketProtocol: AnyObject {
    /// Connect to WebSocket endpoint with optional authentication token
    func connect(to endpoint: String, with token: String?)
    
    /// Disconnect from WebSocket
    func disconnect()
    
    /// Send a string message
    func send(_ message: String)
    
    /// Send raw data
    func sendData(_ data: Data)
    
    /// WebSocket delegate for handling events
    var delegate: WebSocketManagerDelegate? { get set }
    
    /// Check if WebSocket is currently connected
    var isConnected: Bool { get }
}

// MARK: - WebSocket Connection State
public enum WebSocketConnectionState {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case failed
}

// MARK: - WebSocket Manager Delegate
public protocol WebSocketManagerDelegate: AnyObject {
    func webSocketDidConnect(_ manager: any WebSocketProtocol)
    func webSocketDidDisconnect(_ manager: any WebSocketProtocol, error: Error?)
    func webSocket(_ manager: any WebSocketProtocol, didReceiveMessage message: WebSocketMessage)
    func webSocket(_ manager: any WebSocketProtocol, didReceiveData data: Data)
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState)
    // Optional method for raw text messages (shell WebSocket)
    func webSocket(_ manager: any WebSocketProtocol, didReceiveText text: String)
}

// Provide default implementation for optional method
public extension WebSocketManagerDelegate {
    func webSocket(_ manager: any WebSocketProtocol, didReceiveText text: String) {
        // Default implementation - do nothing
    }
}

// MARK: - WebSocket Message Model
public struct WebSocketMessage: Codable {
    public let type: WebSocketMessageType
    public let payload: [String: Any]?
    public let timestamp: Date
    public let sessionId: String?
    
    public init(type: WebSocketMessageType, payload: [String: Any]? = nil, timestamp: Date = Date(), sessionId: String? = nil) {
        self.type = type
        self.payload = payload
        self.timestamp = timestamp
        self.sessionId = sessionId
    }
    
    // Custom encoding/decoding for payload
    enum CodingKeys: String, CodingKey {
        case type, payload, timestamp, sessionId
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(WebSocketMessageType.self, forKey: .type)
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
        sessionId = try container.decodeIfPresent(String.self, forKey: .sessionId)
        
        // Decode payload as AnyCodable dictionary
        if let anyPayload = try? container.decode([String: AnyCodable].self, forKey: .payload) {
            payload = anyPayload.mapValues { $0.value }
        } else {
            payload = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(sessionId, forKey: .sessionId)
        
        if let payload = payload {
            let anyPayload = payload.mapValues { AnyCodable($0) }
            try container.encode(anyPayload, forKey: .payload)
        }
    }
}

// MARK: - WebSocket Message Types
public enum WebSocketMessageType: String, Codable {
    case connection = "connection"
    case sessionStart = "session:start"
    case sessionMessage = "session:message"
    case sessionEnd = "session:end"
    case sessionCreated = "session-created"
    case claudeCommand = "claude-command"
    case cursorCommand = "cursor-command"
    case claudeOutput = "claude-output"
    case claudeResponse = "claude-response"
    case sessionAborted = "session-aborted"
    case error = "error"
    case projectList = "project:list"
    case projectCreate = "project:create"
    case projectDelete = "project:delete"
    case projectsUpdated = "projects_updated"
    case fileOperation = "file:operation"
    case streamingResponse = "stream:response"
    case streamStart = "stream:start"
    case streamChunk = "stream:chunk"
    case streamEnd = "stream:end"
    case tool_use = "tool_use"
    case tool_result = "tool_result"
    case abortSession = "abort-session"
    case message = "message"
    case typing = "typing"
    case status = "status"
    
    // Shell WebSocket
    case shellInit = "init"
    case shellCommand = "shell-command"
    case shellOutput = "shell-output"
    case shellError = "shell-error"
    case shellInput = "input"
    case shellResize = "resize"
    case urlOpen = "url_open"
}

// MARK: - AnyCodable Helper
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode AnyCodable")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case is NSNull:
            try container.encodeNil()
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Unable to encode AnyCodable"))
        }
    }
}