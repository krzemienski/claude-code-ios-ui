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
    private var claudeAPIManager: ClaudeAPIManager?
    private var useClaudeAPIDirectly = false
    
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
        
        // Initialize Claude API Manager for E2E testing
        self.claudeAPIManager = ClaudeAPIManager()
        
        // Check if we should use Claude API directly (for E2E testing)
        if ProcessInfo.processInfo.environment["USE_CLAUDE_API_DIRECT"] == "true" {
            self.useClaudeAPIDirectly = true
            print("🔵 [E2E] ChatComponentsIntegrator using Claude API directly")
        }
        
        // Set delegate if viewController conforms to ClaudeAPIManagerDelegate
        if let chatVC = viewController as? ClaudeAPIManagerDelegate {
            self.claudeAPIManager?.delegate = chatVC
        }
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
    
    /// Send a message through WebSocket or Claude API with proper format
    func sendMessage(_ text: String) {
        print("📤 [ChatComponentsIntegrator] Sending message: \(text)")
        
        if useClaudeAPIDirectly {
            // E2E Testing: Send directly to Claude API
            print("🔵 [E2E] Routing to Claude API for SSE streaming")
            sendToClaudeAPI(text)
        } else {
            // Production: Send to backend WebSocket server
            sendToBackendWebSocket(text)
        }
    }
    
    private func sendToClaudeAPI(_ text: String) {
        print("🔵 [E2E Claude API] Sending message via SSE")
        
        // Build system prompt with project context
        let systemPrompt = """
        You are an AI assistant helping with a software project at path: \(project.path)
        Project name: \(project.name)
        Provide helpful and accurate responses.
        """
        
        // Send to Claude API
        claudeAPIManager?.sendMessage(text, systemPrompt: systemPrompt)
        
        print("✅ [E2E Claude API] Message sent to Claude API")
    }
    
    private func sendToBackendWebSocket(_ text: String) {
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