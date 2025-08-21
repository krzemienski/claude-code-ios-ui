//
//  StreamingMessageHandler.swift
//  ClaudeCodeUI
//
//  Created by Claude on 2025-01-21.
//

import Foundation

class StreamingMessageHandler {
    private var messageAccumulator: [String: StreamingMessage] = [:]
    private let jsonDecoder = JSONDecoder()
    
    struct StreamingMessage {
        var id: String
        var content: String
        var type: String
        var isComplete: Bool
        var metadata: [String: Any]
        var lastUpdate: Date
    }
    
    // MARK: - Process Streaming Chunk
    
    func processStreamingChunk(_ data: Data) -> (messageId: String, content: String, isComplete: Bool)? {
        // Try to parse as JSON first
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return processJSONChunk(json)
        }
        
        // Try as plain text
        if let text = String(data: data, encoding: .utf8) {
            return processTextChunk(text)
        }
        
        return nil
    }
    
    private func processJSONChunk(_ json: [String: Any]) -> (String, String, Bool)? {
        guard let messageId = json["id"] as? String ?? json["messageId"] as? String else {
            return nil
        }
        
        var message = messageAccumulator[messageId] ?? StreamingMessage(
            id: messageId,
            content: "",
            type: "text",
            isComplete: false,
            metadata: [:],
            lastUpdate: Date()
        )
        
        // Extract content based on different formats
        if let content = json["content"] as? String {
            message.content += content
        } else if let delta = json["delta"] as? [String: Any],
                  let deltaContent = delta["text"] as? String {
            message.content += deltaContent
        } else if let chunk = json["chunk"] as? String {
            message.content += chunk
        }
        
        // Check for completion
        if let isComplete = json["complete"] as? Bool {
            message.isComplete = isComplete
        } else if let type = json["type"] as? String {
            message.isComplete = type == "complete" || type == "end" || type == "done"
        }
        
        // Update metadata
        if let metadata = json["metadata"] as? [String: Any] {
            message.metadata.merge(metadata) { _, new in new }
        }
        
        message.lastUpdate = Date()
        messageAccumulator[messageId] = message
        
        return (messageId, message.content, message.isComplete)
    }
    
    private func processTextChunk(_ text: String) -> (String, String, Bool)? {
        // Handle Server-Sent Events format
        if text.hasPrefix("data: ") {
            let dataContent = String(text.dropFirst(6))
            if let data = dataContent.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return processJSONChunk(json)
            }
        }
        
        // Handle plain text streaming - use a default message ID
        let defaultId = "stream-\(Date().timeIntervalSince1970)"
        var message = messageAccumulator[defaultId] ?? StreamingMessage(
            id: defaultId,
            content: "",
            type: "text",
            isComplete: false,
            metadata: [:],
            lastUpdate: Date()
        )
        
        message.content += text
        message.lastUpdate = Date()
        messageAccumulator[defaultId] = message
        
        // Check for completion markers
        let isComplete = text.contains("[DONE]") || text.contains("</stream>")
        message.isComplete = isComplete
        
        return (defaultId, message.content, isComplete)
    }
    
    // MARK: - Clean Up
    
    func completeMessage(id: String) -> String? {
        guard let message = messageAccumulator[id] else { return nil }
        messageAccumulator.removeValue(forKey: id)
        return message.content
    }
    
    func cleanupStaleMessages(olderThan timeout: TimeInterval = 300) {
        let cutoff = Date().addingTimeInterval(-timeout)
        messageAccumulator = messageAccumulator.filter { $0.value.lastUpdate > cutoff }
    }
    
    func reset() {
        messageAccumulator.removeAll()
    }
    
    // MARK: - Parse Message Types
    
    func detectMessageType(from content: String) -> MessageType {
        // Tool use detection
        if content.contains("🔧") || content.contains("Tool:") || content.contains("tool_use") {
            return .toolUse
        }
        
        // Code detection
        if content.contains("```") {
            return .code
        }
        
        // Thinking detection
        if content.contains("💭") || content.contains("thinking") || content.starts(with: "<thinking>") {
            return .thinking
        }
        
        // Error detection
        if content.hasPrefix("Error:") || content.hasPrefix("❌") || content.contains("error") {
            return .error
        }
        
        // System message detection
        if content.hasPrefix("System:") || content.hasPrefix("🔔") {
            return .system
        }
        
        return .text
    }
    
    // MARK: - Extract Structured Content
    
    func extractStructuredContent(from message: String) -> (type: MessageType, mainContent: String, metadata: [String: Any]) {
        var metadata: [String: Any] = [:]
        var mainContent = message
        let type = detectMessageType(from: message)
        
        switch type {
        case .code:
            // Extract code blocks
            let pattern = "```(\\w*)\\n([\\s\\S]*?)```"
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: message, range: NSRange(message.startIndex..., in: message)) {
                
                if let langRange = Range(match.range(at: 1), in: message) {
                    metadata["language"] = String(message[langRange])
                }
                
                if let codeRange = Range(match.range(at: 2), in: message) {
                    metadata["code"] = String(message[codeRange])
                    mainContent = String(message[codeRange])
                }
            }
            
        case .toolUse:
            // Extract tool information
            if let toolRange = message.range(of: "Tool: ") {
                let toolInfo = message[toolRange.upperBound...]
                if let endRange = toolInfo.firstIndex(of: "\n") {
                    metadata["toolName"] = String(toolInfo[..<endRange])
                }
            }
            
        case .thinking:
            // Remove thinking tags if present
            mainContent = mainContent
                .replacingOccurrences(of: "<thinking>", with: "")
                .replacingOccurrences(of: "</thinking>", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
        default:
            break
        }
        
        return (type, mainContent, metadata)
    }
}