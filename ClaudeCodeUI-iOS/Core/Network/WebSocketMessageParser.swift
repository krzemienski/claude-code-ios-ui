//
//  WebSocketMessageParser.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/30.
//

import Foundation

/// WebSocket Message Parser
/// Handles parsing of WebSocket messages with proper error handling
final class WebSocketMessageParser {
    
    // MARK: - Message Types
    
    enum MessageType: String, Codable {
        case text = "text"
        case toolUse = "tool_use"
        case thinking = "thinking"
        case error = "error"
        case system = "system"
        case typing = "typing"
        case status = "status"
        case connected = "connected"
        case disconnected = "disconnected"
    }
    
    // MARK: - Parsing Structures
    
    struct ParsedMessage {
        let id: String
        let type: MessageType
        let content: String
        let metadata: [String: Any]?
        let timestamp: Date
        let sessionId: String?
        let userId: String?
    }
    
    // MARK: - Error Types
    
    enum ParsingError: LocalizedError {
        case invalidJSON
        case missingRequiredField(String)
        case invalidMessageType
        case malformedContent
        
        var errorDescription: String? {
            switch self {
            case .invalidJSON:
                return "Invalid JSON format in WebSocket message"
            case .missingRequiredField(let field):
                return "Missing required field: \(field)"
            case .invalidMessageType:
                return "Invalid or unsupported message type"
            case .malformedContent:
                return "Malformed message content"
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Parse incoming WebSocket message
    /// - Parameter data: Raw data from WebSocket
    /// - Returns: Parsed message structure
    /// - Throws: ParsingError if message cannot be parsed
    static func parse(_ data: Data) throws -> ParsedMessage {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ParsingError.invalidJSON
        }
        
        // Extract required fields with proper error handling
        let id = json["id"] as? String ?? UUID().uuidString
        let typeString = json["type"] as? String ?? "text"
        let type = MessageType(rawValue: typeString) ?? .text
        
        // Handle different content formats
        let content: String
        if let contentString = json["content"] as? String {
            content = contentString
        } else if let contentData = json["content"] as? [String: Any] {
            // Handle structured content
            content = formatStructuredContent(contentData)
        } else if let contentArray = json["content"] as? [[String: Any]] {
            // Handle array content (e.g., tool use results)
            content = formatArrayContent(contentArray)
        } else {
            content = json["message"] as? String ?? ""
        }
        
        // Extract optional metadata
        let metadata = json["metadata"] as? [String: Any]
        
        // Parse timestamp
        let timestamp: Date
        if let timestampString = json["timestamp"] as? String {
            timestamp = ISO8601DateFormatter().date(from: timestampString) ?? Date()
        } else if let timestampInterval = json["timestamp"] as? TimeInterval {
            timestamp = Date(timeIntervalSince1970: timestampInterval)
        } else {
            timestamp = Date()
        }
        
        // Extract session and user IDs with multiple fallback options
        let sessionId = extractSessionId(from: json)
        let userId = json["userId"] as? String ?? json["user_id"] as? String
        
        return ParsedMessage(
            id: id,
            type: type,
            content: content,
            metadata: metadata,
            timestamp: timestamp,
            sessionId: sessionId,
            userId: userId
        )
    }
    
    /// Create a WebSocket message for sending
    /// - Parameters:
    ///   - content: Message content
    ///   - type: Message type
    ///   - sessionId: Session identifier
    /// - Returns: JSON data ready for sending
    static func createMessage(content: String, type: MessageType = .text, sessionId: String) -> Data? {
        let message: [String: Any] = [
            "id": UUID().uuidString,
            "type": type.rawValue,
            "content": content,
            "sessionId": formatSessionId(sessionId),
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        return try? JSONSerialization.data(withJSONObject: message, options: .prettyPrinted)
    }
    
    // MARK: - Private Helper Methods
    
    private static func formatStructuredContent(_ data: [String: Any]) -> String {
        if let text = data["text"] as? String {
            return text
        } else if let type = data["type"] as? String {
            switch type {
            case "tool_use":
                return formatToolUse(data)
            case "thinking":
                return formatThinking(data)
            default:
                return String(describing: data)
            }
        }
        return ""
    }
    
    private static func formatArrayContent(_ array: [[String: Any]]) -> String {
        return array.compactMap { item in
            if let text = item["text"] as? String {
                return text
            } else if let type = item["type"] as? String {
                return "[\(type)]"
            }
            return nil
        }.joined(separator: "\n")
    }
    
    private static func formatToolUse(_ data: [String: Any]) -> String {
        let toolName = data["name"] as? String ?? "unknown"
        let toolInput = data["input"] as? String ?? ""
        return "🔧 Using tool: \(toolName)\n\(toolInput)"
    }
    
    private static func formatThinking(_ data: [String: Any]) -> String {
        let thought = data["thought"] as? String ?? ""
        return "💭 \(thought)"
    }
    
    /// Extract session ID from various possible locations in the JSON
    private static func extractSessionId(from json: [String: Any]) -> String? {
        // Try multiple possible locations for session ID
        if let sessionId = json["sessionId"] as? String {
            return sessionId
        } else if let sessionId = json["session_id"] as? String {
            return sessionId
        } else if let sessionId = json["claudeSessionId"] as? String {
            return sessionId
        } else if let sessionId = json["claude_session_id"] as? String {
            return sessionId
        } else if let metadata = json["metadata"] as? [String: Any] {
            return metadata["sessionId"] as? String ?? metadata["session_id"] as? String
        }
        return nil
    }
    
    /// Format session ID to match backend expectations
    /// Backend expects format: "claude-session-{uuid}"
    private static func formatSessionId(_ sessionId: String) -> String {
        // If already in correct format, return as is
        if sessionId.hasPrefix("claude-session-") {
            return sessionId
        }
        
        // Extract UUID part if present
        let uuidPart: String
        if sessionId.contains("-") && sessionId.count == 36 {
            // Looks like a raw UUID
            uuidPart = sessionId
        } else if sessionId.hasPrefix("session-") {
            // Remove "session-" prefix
            uuidPart = String(sessionId.dropFirst(8))
        } else {
            // Use as is or generate new UUID if invalid
            uuidPart = UUID(uuidString: sessionId)?.uuidString ?? UUID().uuidString
        }
        
        return "claude-session-\(uuidPart.lowercased())"
    }
    
    // MARK: - Validation Methods
    
    /// Validate if a message has all required fields
    static func validateMessage(_ json: [String: Any]) -> Bool {
        // At minimum, we need some form of content
        return json["content"] != nil || json["message"] != nil || json["text"] != nil
    }
    
    /// Check if message is a status update
    static func isStatusMessage(_ json: [String: Any]) -> Bool {
        let type = json["type"] as? String
        return type == "status" || type == "connected" || type == "disconnected"
    }
}

// MARK: - Extensions for Message Conversion

extension WebSocketMessageParser.ParsedMessage {
    /// Convert to EnhancedChatMessage for display
    func toChatMessage() -> [String: Any] {
        return [
            "id": id,
            "content": content,
            "role": type == .error ? "error" : (userId != nil ? "user" : "assistant"),
            "timestamp": timestamp,
            "type": type.rawValue,
            "sessionId": sessionId ?? "",
            "metadata": metadata ?? [:]
        ]
    }
}