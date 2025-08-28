//
//  ShellWebSocketManager.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/20.
//  
//  Dedicated WebSocket manager for terminal shell commands
//  Connects to ws://localhost:3004/shell endpoint
//

import Foundation
import UIKit

// MARK: - Shell WebSocket Manager Protocol
protocol ShellWebSocketManagerDelegate: AnyObject {
    func shellWebSocketDidConnect(_ manager: ShellWebSocketManager)
    func shellWebSocketDidDisconnect(_ manager: ShellWebSocketManager, error: Error?)
    func shellWebSocket(_ manager: ShellWebSocketManager, didReceiveOutput output: String)
    func shellWebSocket(_ manager: ShellWebSocketManager, didReceiveError error: String)
    func shellWebSocketDidInitialize(_ manager: ShellWebSocketManager, workingDirectory: String?)
}

// MARK: - Shell Command Queue Item
private struct ShellCommand {
    let command: String
    let workingDirectory: String
    let completion: ((Bool, String?) -> Void)?
}

// MARK: - Shell WebSocket Manager
final class ShellWebSocketManager: NSObject {
    
    // MARK: - Properties
    weak var delegate: ShellWebSocketManagerDelegate?
    private var webSocketTask: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)
    private var pingTimer: Timer?
    private var reconnectTimer: Timer?
    
    // Connection properties
    private var shellURL: URL?
    private(set) var isConnected = false
    private var projectPath: String?
    private var terminalCols = 80
    private var terminalRows = 24
    
    // Reconnection settings
    private var enableAutoReconnect = true
    private var reconnectDelay: TimeInterval = 1.0
    private var maxReconnectAttempts = 5
    private var reconnectAttempts = 0
    private var intentionalDisconnect = false
    
    // Command queue for sequential execution
    private var commandQueue: [ShellCommand] = []
    private var isProcessingCommand = false
    private let commandQueueLimit = 50
    
    // Command history
    private var commandHistory: [String] = []
    private let maxHistorySize = 100
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupNotifications()
    }
    
    deinit {
        disconnect()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    // MARK: - Connection Management
    func connect(projectPath: String? = nil) {
        // Reset state
        intentionalDisconnect = false
        self.projectPath = projectPath
        
        // Build shell WebSocket URL
        let shellURLString = "ws://\(AppConfig.backendHost):\(AppConfig.backendPort)/shell"
        
        // Add JWT token if available
        var finalURLString = shellURLString
        if let authToken = UserDefaults.standard.string(forKey: "authToken") {
            finalURLString = "\(shellURLString)?token=\(authToken)"
        }
        
        guard let url = URL(string: finalURLString) else {
            logError("Invalid shell WebSocket URL: \(finalURLString)", category: "ShellWebSocket")
            return
        }
        
        // Clean up any existing connection
        if webSocketTask != nil {
            webSocketTask?.cancel(with: .goingAway, reason: nil)
            webSocketTask = nil
        }
        
        shellURL = url
        
        var request = URLRequest(url: url)
        
        // Add authentication header for compatibility
        if let authToken = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        
        // Verify connection with ping
        webSocketTask?.sendPing { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                logError("Shell WebSocket ping failed: \(error)", category: "ShellWebSocket")
                self.handleError(error)
            } else {
                self.isConnected = true
                self.reconnectAttempts = 0
                
                DispatchQueue.main.async {
                    self.delegate?.shellWebSocketDidConnect(self)
                }
                
                // Send initialization message
                self.sendInitMessage()
                
                // Start receiving messages
                self.receiveMessage()
                
                // Start ping timer
                self.startPingTimer()
                
                logInfo("Shell WebSocket connected successfully", category: "ShellWebSocket")
            }
        }
    }
    
    func disconnect() {
        stopPingTimer()
        stopReconnectTimer()
        
        intentionalDisconnect = true
        isConnected = false
        
        if let task = webSocketTask {
            task.cancel(with: .goingAway, reason: nil)
        }
        webSocketTask = nil
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.shellWebSocketDidDisconnect(self, error: nil)
        }
    }
    
    // MARK: - Message Handling
    private func sendInitMessage() {
        let initData: [String: Any] = [
            "type": "init",
            "projectPath": projectPath ?? FileManager.default.currentDirectoryPath,
            "sessionId": NSNull(),
            "hasSession": false,
            "provider": "terminal",
            "cols": terminalCols,
            "rows": terminalRows
        ]
        
        sendJSON(initData)
    }
    
    func sendCommand(_ command: String, workingDirectory: String? = nil, completion: ((Bool, String?) -> Void)? = nil) {
        guard isConnected else {
            completion?(false, "Not connected to shell server")
            return
        }
        
        // Add to command history
        addToHistory(command)
        
        // Send command as input to the shell process
        // The backend expects "input" type messages with the command in the "data" field
        let messageData: [String: Any] = [
            "type": "input",
            "data": command + "\n"  // Add newline to execute the command
        ]
        
        // Send the command immediately
        sendJSON(messageData)
        
        // Call completion after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion?(true, nil)
        }
    }
    
    private func processNextCommand() {
        guard !commandQueue.isEmpty else {
            isProcessingCommand = false
            return
        }
        
        isProcessingCommand = true
        let shellCommand = commandQueue.removeFirst()
        
        let messageData: [String: Any] = [
            "type": "shell-command",
            "command": shellCommand.command,
            "cwd": shellCommand.workingDirectory
        ]
        
        sendJSON(messageData)
        
        // Handle completion after a timeout if no response
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            self?.isProcessingCommand = false
            self?.processNextCommand()
        }
    }
    
    func sendTerminalResize(cols: Int, rows: Int) {
        self.terminalCols = cols
        self.terminalRows = rows
        
        let resizeData: [String: Any] = [
            "type": "resize",
            "cols": cols,
            "rows": rows
        ]
        
        sendJSON(resizeData)
    }
    
    func sendInput(_ input: String) {
        let inputData: [String: Any] = [
            "type": "input",
            "data": input
        ]
        
        sendJSON(inputData)
    }
    
    private func sendJSON(_ data: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            logError("Failed to create JSON for shell WebSocket", category: "ShellWebSocket")
            return
        }
        
        let message = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask?.send(message) { [weak self] error in
            if let error = error {
                logError("Failed to send shell command: \(error)", category: "ShellWebSocket")
                self?.handleError(error)
            }
        }
    }
    
    // MARK: - Message Reception
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                self.handleMessage(message)
                // Continue receiving messages
                self.receiveMessage()
                
            case .failure(let error):
                logError("Shell WebSocket receive error: \(error)", category: "ShellWebSocket")
                self.handleError(error)
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            parseShellMessage(text)
            
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                parseShellMessage(text)
            }
            
        @unknown default:
            logWarning("Unknown shell WebSocket message type", category: "ShellWebSocket")
        }
    }
    
    private func parseShellMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            // If not JSON, treat as raw output
            DispatchQueue.main.async {
                self.delegate?.shellWebSocket(self, didReceiveOutput: text)
            }
            return
        }
        
        switch type {
        case "shell-output", "output":
            if let output = json["output"] as? String ?? json["data"] as? String {
                DispatchQueue.main.async {
                    self.delegate?.shellWebSocket(self, didReceiveOutput: output)
                }
            }
            // Mark command as processed
            isProcessingCommand = false
            processNextCommand()
            
        case "shell-error", "error":
            if let error = json["error"] as? String ?? json["data"] as? String {
                DispatchQueue.main.async {
                    self.delegate?.shellWebSocket(self, didReceiveError: error)
                }
            }
            // Mark command as processed even on error
            isProcessingCommand = false
            processNextCommand()
            
        case "init":
            let cwd = json["cwd"] as? String
            DispatchQueue.main.async {
                self.delegate?.shellWebSocketDidInitialize(self, workingDirectory: cwd)
            }
            
        case "exit":
            disconnect()
            
        default:
            logInfo("Unhandled shell message type: \(type)", category: "ShellWebSocket")
        }
    }
    
    // MARK: - Command History
    func addToHistory(_ command: String) {
        // Don't add duplicate consecutive commands
        if commandHistory.last != command {
            commandHistory.append(command)
            
            // Limit history size
            if commandHistory.count > maxHistorySize {
                commandHistory.removeFirst()
            }
        }
    }
    
    func getHistory() -> [String] {
        return commandHistory
    }
    
    func getHistoryItem(at index: Int) -> String? {
        guard index >= 0 && index < commandHistory.count else { return nil }
        return commandHistory[index]
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) {
        isConnected = false
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.shellWebSocketDidDisconnect(self, error: error)
        }
        
        // Attempt reconnection if not intentional disconnect
        if !intentionalDisconnect && enableAutoReconnect && reconnectAttempts < maxReconnectAttempts {
            scheduleReconnect()
        }
    }
    
    // MARK: - Reconnection
    private func scheduleReconnect() {
        guard !intentionalDisconnect else { return }
        
        reconnectAttempts += 1
        let delay = min(reconnectDelay * pow(2.0, Double(reconnectAttempts - 1)), 30.0)
        
        logInfo("Scheduling shell reconnect attempt \(reconnectAttempts) in \(delay) seconds", category: "ShellWebSocket")
        
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.attemptReconnect()
        }
    }
    
    private func attemptReconnect() {
        guard !intentionalDisconnect && !isConnected else { return }
        
        logInfo("Attempting shell WebSocket reconnect...", category: "ShellWebSocket")
        connect(projectPath: projectPath)
    }
    
    // MARK: - Timers
    private func startPingTimer() {
        stopPingTimer()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    private func sendPing() {
        webSocketTask?.sendPing { [weak self] error in
            if let error = error {
                logError("Shell WebSocket ping failed: \(error)", category: "ShellWebSocket")
                self?.handleError(error)
            }
        }
    }
    
    // MARK: - App Lifecycle
    @objc private func appDidEnterBackground() {
        // Disconnect when app goes to background
        if isConnected {
            disconnect()
        }
    }
    
    @objc private func appWillEnterForeground() {
        // Reconnect when app comes to foreground
        if !isConnected && !intentionalDisconnect {
            connect(projectPath: projectPath)
        }
    }
}

// MARK: - Logging Helpers
private func logInfo(_ message: String, category: String) {
    print("ℹ️ [\(category)] \(message)")
}

private func logWarning(_ message: String, category: String) {
    print("⚠️ [\(category)] \(message)")
}

private func logError(_ message: String, category: String) {
    print("❌ [\(category)] \(message)")
}