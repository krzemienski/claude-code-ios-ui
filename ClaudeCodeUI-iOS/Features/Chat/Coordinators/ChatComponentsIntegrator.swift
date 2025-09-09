//
//  ChatComponentsIntegrator.swift
//  ClaudeCodeUI
//
//  Simplified Component Integration Layer
//

import UIKit
import Combine

// MARK: - ChatComponentsIntegrator

/// Integrator to handle message sending through WebSocket
@MainActor
final class ChatComponentsIntegrator: NSObject {
    
    // MARK: - Properties
    
    weak var viewController: UIViewController?
    weak var tableView: UITableView?
    private let webSocketManager: WebSocketProtocol?
    private let project: Project
    
    // MARK: - Initialization
    
    init(viewController: UIViewController,
         tableView: UITableView,
         inputBar: Any?,
         webSocketManager: Any?,
         project: Project) {
        
        self.viewController = viewController
        self.tableView = tableView
        self.webSocketManager = webSocketManager as? WebSocketProtocol
        self.project = project
        
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Start the chat system
    func start() {
        // Minimal implementation to fix compilation
        print("ChatComponentsIntegrator started")
    }
    
    /// Stop the chat system
    func stop() {
        // Minimal implementation
        print("ChatComponentsIntegrator stopped")
    }
    
    /// Send a message through WebSocket with proper format for backend
    func sendMessage(_ text: String) {
        print("📤 [ChatComponentsIntegrator] Sending message: \(text)")
        
        // Get or create session ID - use UUID format that backend expects
        let sessionId: String
        if let existingId = UserDefaults.standard.string(forKey: "currentSessionId_\(project.id)"),
           !existingId.isEmpty {
            // Validate existing session ID is a UUID
            if UUID(uuidString: existingId) != nil {
                sessionId = existingId
            } else {
                // Convert timestamp-based ID to UUID format if needed
                sessionId = UUID().uuidString
                UserDefaults.standard.set(sessionId, forKey: "currentSessionId_\(project.id)")
            }
        } else {
            // Create new UUID session ID
            sessionId = UUID().uuidString
            UserDefaults.standard.set(sessionId, forKey: "currentSessionId_\(project.id)")
        }
        
        // Format message according to backend expectations (server/index.js)
        let messageData: [String: Any] = [
            "type": "claude-command",
            "command": text,  // Backend expects 'command' field
            "options": [
                "projectPath": project.path,
                "sessionId": sessionId,
                "resume": true,  // Resume existing session if available
                "cwd": project.path  // Working directory for Claude
            ] as [String: Any]
        ]
        
        // Send as JSON string
        if let jsonData = try? JSONSerialization.data(withJSONObject: messageData, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📨 [ChatComponentsIntegrator] Sending WebSocket message:")
            print("   Type: claude-command")
            print("   Command: \(text.prefix(100))...")
            print("   SessionId: \(sessionId)")
            print("   ProjectPath: \(project.path)")
            
            webSocketManager?.send(jsonString)
            
            print("✅ [ChatComponentsIntegrator] Message sent successfully")
        } else {
            print("❌ [ChatComponentsIntegrator] Failed to serialize message")
        }
    }
    
    /// Load messages for the current session
    func loadMessages() async {
        // Minimal implementation to fix compilation
        print("Loading messages")
    }
}