//
//  MessageTypes.swift
//  ClaudeCodeUI
//
//  Enhanced message type handling for comprehensive display
//

import Foundation
import UIKit

// MARK: - Enhanced Message Type
enum MessageType: String, Codable {
    case text = "text"
    case toolUse = "tool_use"
    case toolResult = "tool_result"
    case todoUpdate = "todo_update"
    case code = "code"
    case error = "error"
    case system = "system"
    case claudeResponse = "claude_response"
    case claudeOutput = "claude_output"
    case thinking = "thinking"
    case fileOperation = "file_operation"
    case gitOperation = "git_operation"
    case terminalCommand = "terminal_command"
    
    var icon: UIImage? {
        switch self {
        case .text:
            return UIImage(systemName: "text.bubble")
        case .toolUse:
            return UIImage(systemName: "wrench.and.screwdriver")
        case .toolResult:
            return UIImage(systemName: "checkmark.square")
        case .todoUpdate:
            return UIImage(systemName: "checklist")
        case .code:
            return UIImage(systemName: "chevron.left.forwardslash.chevron.right")
        case .error:
            return UIImage(systemName: "exclamationmark.triangle")
        case .system:
            return UIImage(systemName: "gear")
        case .claudeResponse, .claudeOutput:
            return UIImage(systemName: "brain")
        case .thinking:
            return UIImage(systemName: "thought.bubble")
        case .fileOperation:
            return UIImage(systemName: "doc.text")
        case .gitOperation:
            return UIImage(systemName: "arrow.triangle.branch")
        case .terminalCommand:
            return UIImage(systemName: "terminal")
        }
    }
    
    var displayName: String {
        switch self {
        case .text:
            return "Message"
        case .toolUse:
            return "Tool Use"
        case .toolResult:
            return "Tool Result"
        case .todoUpdate:
            return "Todo Update"
        case .code:
            return "Code"
        case .error:
            return "Error"
        case .system:
            return "System"
        case .claudeResponse:
            return "Claude Response"
        case .claudeOutput:
            return "Claude Output"
        case .thinking:
            return "Thinking"
        case .fileOperation:
            return "File Operation"
        case .gitOperation:
            return "Git Operation"
        case .terminalCommand:
            return "Terminal Command"
        }
    }
    
    var accentColor: UIColor {
        switch self {
        case .error:
            return CyberpunkTheme.accentPink
        case .toolUse, .toolResult:
            return CyberpunkTheme.primaryCyan
        case .todoUpdate:
            return UIColor.systemGreen
        case .code:
            return UIColor.systemOrange
        case .system:
            return UIColor.systemGray
        case .gitOperation:
            return UIColor.systemPurple
        case .terminalCommand:
            return UIColor.systemYellow
        default:
            return CyberpunkTheme.primaryText
        }
    }
}

// MARK: - Tool Use Data
struct ToolUseData: Codable {
    let name: String
    let parameters: [String: Any]?
    let result: String?
    let duration: TimeInterval?
    let status: String? // success, failed, running
    
    enum CodingKeys: String, CodingKey {
        case name, result, duration, status
    }
    
    init(name: String, parameters: [String: Any]? = nil, result: String? = nil, duration: TimeInterval? = nil, status: String? = nil) {
        self.name = name
        self.parameters = parameters
        self.result = result
        self.duration = duration
        self.status = status
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        result = try container.decodeIfPresent(String.self, forKey: .result)
        duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        // Parameters handled separately due to Any type
        self.parameters = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(result, forKey: .result)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(status, forKey: .status)
    }
}

// MARK: - Todo Item
struct TodoItem: Codable {
    let id: String
    let title: String
    let description: String?
    let status: TodoStatus
    let priority: TodoPriority
    let createdAt: Date
    let completedAt: Date?
    
    enum TodoStatus: String, Codable {
        case pending = "pending"
        case inProgress = "in_progress"
        case completed = "completed"
        case blocked = "blocked"
        case cancelled = "cancelled"
        
        var icon: String {
            switch self {
            case .pending:
                return "⭕"
            case .inProgress:
                return "🔄"
            case .completed:
                return "✅"
            case .blocked:
                return "❌"
            case .cancelled:
                return "🚫"
            }
        }
    }
    
    enum TodoPriority: String, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
        
        var color: UIColor {
            switch self {
            case .low:
                return UIColor.systemGray
            case .medium:
                return UIColor.systemBlue
            case .high:
                return UIColor.systemOrange
            case .critical:
                return UIColor.systemRed
            }
        }
        
        var indicator: String {
            switch self {
            case .low:
                return "🟢"
            case .medium:
                return "🟡"
            case .high:
                return "🟠"
            case .critical:
                return "🔴"
            }
        }
    }
}

// MARK: - Message Status
enum MessageStatus: String, Codable {
    case sending = "sending"
    case sent = "sent"
    case delivered = "delivered"
    case failed = "failed"
    case read = "read"
}

// MARK: - Base Chat Message
class ChatMessage {
    let id: String
    var content: String
    let isUser: Bool
    let timestamp: Date
    var status: MessageStatus
    
    init(id: String, content: String, isUser: Bool, timestamp: Date, status: MessageStatus = .sent) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.status = status
    }
}

// MARK: - Enhanced Chat Message
class EnhancedChatMessage: ChatMessage {
    var messageType: MessageType = .text
    var toolUseData: ToolUseData?
    var todos: [TodoItem]?
    var codeLanguage: String?
    var codeContent: String?
    var errorDetails: String?
    var systemInfo: String?
    var fileOperations: [String]?
    var gitChanges: [String]?
    var terminalOutput: String?
    var isExpanded: Bool = false
    var metadata: [String: Any]?
    
    override init(id: String, content: String, isUser: Bool, timestamp: Date, status: MessageStatus) {
        super.init(id: id, content: content, isUser: isUser, timestamp: timestamp, status: status)
        detectMessageType()
    }
    
    private func detectMessageType() {
        // Auto-detect message type from content
        if content.contains("```") {
            messageType = .code
            extractCodeBlock()
        } else if content.contains("Tool:") || content.contains("🔧") {
            messageType = .toolUse
        } else if content.contains("Todo") || content.contains("✅") || content.contains("📋") {
            messageType = .todoUpdate
        } else if content.hasPrefix("Error:") || content.hasPrefix("❌") {
            messageType = .error
        } else if content.hasPrefix("System:") || content.hasPrefix("🔔") {
            messageType = .system
        } else if content.contains("git ") || content.contains("commit") {
            messageType = .gitOperation
        } else if content.contains("$") || content.contains("npm") || content.contains("bash") {
            messageType = .terminalCommand
        }
    }
    
    private func extractCodeBlock() {
        guard let startIndex = content.range(of: "```")?.upperBound,
              let endIndex = content.range(of: "```", range: startIndex..<content.endIndex)?.lowerBound else {
            return
        }
        
        let codeBlock = String(content[startIndex..<endIndex])
        let lines = codeBlock.components(separatedBy: .newlines)
        
        if let firstLine = lines.first, !firstLine.isEmpty {
            // First line might be the language
            let possibleLanguage = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if possibleLanguage.count < 20 && !possibleLanguage.contains(" ") {
                codeLanguage = possibleLanguage
                codeContent = lines.dropFirst().joined(separator: "\n")
            } else {
                codeContent = codeBlock
            }
        } else {
            codeContent = codeBlock
        }
    }
    
    static func fromWebSocketPayload(_ payload: [String: Any]) -> EnhancedChatMessage? {
        guard let content = payload["content"] as? String else { return nil }
        
        let id = payload["id"] as? String ?? UUID().uuidString
        let isUser = (payload["role"] as? String) == "user" || (payload["role"] as? String) == "human"
        let timestamp = Date()
        
        let message = EnhancedChatMessage(
            id: id,
            content: content,
            isUser: isUser,
            timestamp: timestamp,
            status: .sent
        )
        
        // Parse message type
        if let typeString = payload["type"] as? String,
           let type = MessageType(rawValue: typeString) {
            message.messageType = type
        }
        
        // Parse tool use data
        if message.messageType == .toolUse {
            if let toolName = payload["tool_name"] as? String {
                message.toolUseData = ToolUseData(
                    name: toolName,
                    parameters: payload["parameters"] as? [String: Any],
                    result: payload["result"] as? String,
                    status: payload["status"] as? String
                )
            }
        }
        
        // Parse todos
        if message.messageType == .todoUpdate,
           let todosData = payload["todos"] as? [[String: Any]] {
            message.todos = todosData.compactMap { todoDict in
                guard let id = todoDict["id"] as? String,
                      let title = todoDict["title"] as? String,
                      let statusString = todoDict["status"] as? String,
                      let status = TodoItem.TodoStatus(rawValue: statusString),
                      let priorityString = todoDict["priority"] as? String,
                      let priority = TodoItem.TodoPriority(rawValue: priorityString) else {
                    return nil
                }
                
                return TodoItem(
                    id: id,
                    title: title,
                    description: todoDict["description"] as? String,
                    status: status,
                    priority: priority,
                    createdAt: Date(),
                    completedAt: status == .completed ? Date() : nil
                )
            }
        }
        
        // Store metadata
        message.metadata = payload
        
        return message
    }
}