//
//  StarscreamWebSocketManager.swift
//  ClaudeCodeUI
//
//  Created by Claude on 2025-01-15.
//
//  Starscream-based WebSocket implementation for improved reliability
//

import Foundation
import Starscream

// MARK: - WebSocket Protocol
protocol WebSocketProtocol: AnyObject {
    func connect(to endpoint: String, with token: String?)
    func disconnect()
    func send(_ message: String)
    func sendData(_ data: Data)
    var delegate: WebSocketManagerDelegate? { get set }
    var isConnected: Bool { get }
}

// MARK: - Starscream WebSocket Manager
final class StarscreamWebSocketManager: NSObject, WebSocketProtocol {
    
    // MARK: - Properties
    
    weak var delegate: WebSocketManagerDelegate?
    private var socket: WebSocket?
    private let baseURL: String
    private var authToken: String?
    private let reconnectionManager = ReconnectionManager()
    private let messageQueue = MessageQueue()
    private let streamHandler = MessageStreamHandler()
    
    // Connection state management
    private(set) var connectionState: WebSocketConnectionState = .disconnected {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.webSocketConnectionStateChanged(self.connectionState)
            }
        }
    }
    
    var isConnected: Bool {
        return connectionState == .connected
    }
    
    // Dual socket support for chat and terminal
    private var terminalSocket: WebSocket?
    private var currentEndpoint: String?
    
    // MARK: - Initialization
    
    init(baseURL: String = "ws://localhost:3004") {
        self.baseURL = baseURL
        super.init()
        setupNotifications()
    }
    
    deinit {
        disconnect()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    func connect(to endpoint: String, with token: String? = nil) {
        // Store token for reconnection
        authToken = token
        currentEndpoint = endpoint
        
        // Fix WebSocket URL path - use /ws instead of /api/chat/ws
        let fixedEndpoint = endpoint.replacingOccurrences(of: "/api/chat/ws", with: "/ws")
        
        guard let url = URL(string: "\(baseURL)\(fixedEndpoint)") else {
            logError("Invalid WebSocket URL: \(baseURL)\(fixedEndpoint)", category: "StarscreamWS")
            connectionState = .failed
            delegate?.webSocketDidDisconnect(self as! WebSocketManager, error: WebSocketError.invalidURL)
            return
        }
        
        // Create URLRequest with authentication
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        
        // Add authentication headers if token provided
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            // Also add as query parameter for compatibility
            if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                components.queryItems = [URLQueryItem(name: "token", value: token)]
                if let urlWithToken = components.url {
                    request.url = urlWithToken
                }
            }
        }
        
        // Configure Starscream WebSocket
        socket = WebSocket(request: request)
        socket?.delegate = self
        
        // Set callback queue to main for UI updates
        socket?.callbackQueue = DispatchQueue.main
        
        // Enable compression for better performance
        socket?.enableCompression = true
        
        // Set connection state and connect
        connectionState = .connecting
        socket?.connect()
        
        logInfo("Connecting to WebSocket: \(fixedEndpoint)", category: "StarscreamWS")
    }
    
    func disconnect() {
        reconnectionManager.cancel()
        messageQueue.clear()
        
        socket?.disconnect(closeCode: CloseCode.normal.rawValue)
        terminalSocket?.disconnect(closeCode: CloseCode.normal.rawValue)
        
        socket = nil
        terminalSocket = nil
        
        connectionState = .disconnected
    }
    
    func send(_ message: String) {
        guard isConnected else {
            // Queue message if not connected
            messageQueue.enqueue(message)
            
            // Attempt reconnection
            if reconnectionManager.shouldReconnect {
                attemptReconnection()
            }
            return
        }
        
        socket?.write(string: message) {
            logInfo("Message sent successfully", category: "StarscreamWS")
        }
    }
    
    func sendData(_ data: Data) {
        guard isConnected else {
            // Queue binary data if needed
            return
        }
        
        socket?.write(data: data) {
            logInfo("Binary data sent successfully", category: "StarscreamWS")
        }
    }
    
    // MARK: - Enhanced Message Sending
    
    func sendClaudeCommand(content: String, projectPath: String, sessionId: String? = nil) {
        // Create properly formatted message for backend
        var messageData: [String: Any] = [
            "type": "claude-command",  // Fix: Use correct message type
            "content": content,
            "projectPath": projectPath,  // Fix: Include project path
            "timestamp": ISO8601DateFormatter.shared.string(from: Date())
        ]
        
        if let sessionId = sessionId {
            messageData["sessionId"] = sessionId
            messageData["resume"] = true
        }
        
        // Convert to JSON and send
        if let jsonData = try? JSONSerialization.data(withJSONObject: messageData, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            send(jsonString)
        }
    }
    
    func sendCursorCommand(content: String, projectPath: String, sessionId: String? = nil) {
        var messageData: [String: Any] = [
            "type": "cursor-command",  // Fix: Use correct message type
            "content": content,
            "projectPath": projectPath,
            "timestamp": ISO8601DateFormatter.shared.string(from: Date())
        ]
        
        if let sessionId = sessionId {
            messageData["sessionId"] = sessionId
            messageData["resume"] = true
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: messageData, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            send(jsonString)
        }
    }
    
    func abortSession(sessionId: String) {
        let messageData: [String: Any] = [
            "type": "abort-session",
            "sessionId": sessionId,
            "timestamp": ISO8601DateFormatter.shared.string(from: Date())
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: messageData, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            send(jsonString)
        }
    }
    
    // MARK: - Terminal WebSocket Support
    
    func connectToTerminal(with token: String? = nil) {
        guard let url = URL(string: "\(baseURL)/shell") else {
            logError("Invalid terminal WebSocket URL", category: "StarscreamWS")
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        terminalSocket = WebSocket(request: request)
        terminalSocket?.delegate = self
        terminalSocket?.callbackQueue = DispatchQueue.main
        terminalSocket?.connect()
        
        logInfo("Connecting to terminal WebSocket", category: "StarscreamWS")
    }
    
    func sendTerminalCommand(_ command: String) {
        let messageData: [String: Any] = [
            "type": "shell-command",
            "command": command,
            "timestamp": ISO8601DateFormatter.shared.string(from: Date())
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: messageData, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            terminalSocket?.write(string: jsonString)
        }
    }
    
    // MARK: - Private Methods
    
    private func handleConnection() {
        connectionState = .connected
        reconnectionManager.reset()
        
        // Flush queued messages
        messageQueue.flush { [weak self] message in
            self?.send(message)
        }
        
        // Notify delegate
        if let manager = self as? WebSocketManager {
            delegate?.webSocketDidConnect(manager)
        }
        
        logInfo("WebSocket connected successfully", category: "StarscreamWS")
    }
    
    private func handleDisconnection(reason: String?, code: UInt16) {
        let wasConnected = isConnected
        connectionState = .disconnected
        
        // Notify delegate
        if let manager = self as? WebSocketManager {
            delegate?.webSocketDidDisconnect(manager, error: nil)
        }
        
        // Attempt reconnection if it was an unexpected disconnect
        if wasConnected && reconnectionManager.shouldReconnect {
            attemptReconnection()
        }
        
        logInfo("WebSocket disconnected - Reason: \(reason ?? "Unknown"), Code: \(code)", category: "StarscreamWS")
    }
    
    private func handleTextMessage(_ text: String) {
        // First notify delegate of raw text (for terminal)
        if let manager = self as? WebSocketManager {
            delegate?.webSocket(manager, didReceiveText: text)
        }
        
        // Parse JSON message
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                // Handle session creation
                if let type = json["type"] as? String, type == "session-created",
                   let sessionId = json["sessionId"] as? String,
                   let projectPath = json["projectPath"] as? String {
                    // Store session ID for future use
                    UserDefaults.standard.set(sessionId, forKey: "currentSessionId_\(projectPath)")
                }
                
                // Convert to WebSocketMessage for compatibility
                let messageType = WebSocketMessageType(rawValue: json["type"] as? String ?? "message") ?? .message
                let message = WebSocketMessage(
                    type: messageType,
                    payload: json,
                    sessionId: json["sessionId"] as? String
                )
                
                if let manager = self as? WebSocketManager {
                    delegate?.webSocket(manager, didReceiveMessage: message)
                }
            }
        } catch {
            logError("Failed to parse WebSocket message: \(error)", category: "StarscreamWS")
        }
    }
    
    private func handleError(_ error: Error?) {
        connectionState = .failed
        
        if let manager = self as? WebSocketManager {
            delegate?.webSocketDidDisconnect(manager, error: error)
        }
        
        // Attempt reconnection
        if reconnectionManager.shouldReconnect {
            attemptReconnection()
        }
        
        logError("WebSocket error: \(error?.localizedDescription ?? "Unknown")", category: "StarscreamWS")
    }
    
    private func attemptReconnection() {
        guard let endpoint = currentEndpoint else { return }
        
        connectionState = .reconnecting
        
        reconnectionManager.scheduleReconnection { [weak self] in
            self?.connect(to: endpoint, with: self?.authToken)
        }
        
        logInfo("Scheduling reconnection attempt #\(reconnectionManager.currentAttempt)", category: "StarscreamWS")
    }
    
    // MARK: - App Lifecycle
    
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
    
    @objc private func appDidEnterBackground() {
        // Disconnect when app goes to background
        disconnect()
    }
    
    @objc private func appWillEnterForeground() {
        // Reconnect when app returns to foreground
        if let endpoint = currentEndpoint {
            connect(to: endpoint, with: authToken)
        }
    }
}

// MARK: - Starscream WebSocketDelegate

extension StarscreamWebSocketManager: WebSocketDelegate {
    
    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        switch event {
        case .connected(let headers):
            logInfo("WebSocket connected with headers: \(headers)", category: "StarscreamWS")
            handleConnection()
            
        case .disconnected(let reason, let code):
            handleDisconnection(reason: reason, code: code)
            
        case .text(let text):
            handleTextMessage(text)
            
        case .binary(let data):
            if let manager = self as? WebSocketManager {
                delegate?.webSocket(manager, didReceiveData: data)
            }
            
        case .pong(_):
            logInfo("Received pong", category: "StarscreamWS")
            
        case .ping(_):
            logInfo("Received ping", category: "StarscreamWS")
            
        case .error(let error):
            handleError(error)
            
        case .viabilityChanged(let viable):
            logInfo("WebSocket viability changed: \(viable)", category: "StarscreamWS")
            if !viable && reconnectionManager.shouldReconnect {
                attemptReconnection()
            }
            
        case .reconnectSuggested(let suggested):
            if suggested && reconnectionManager.shouldReconnect {
                attemptReconnection()
            }
            
        case .cancelled:
            connectionState = .disconnected
            logInfo("WebSocket cancelled", category: "StarscreamWS")
            
        case .peerClosed:
            handleDisconnection(reason: "Peer closed connection", code: 1000)
        }
    }
}

// MARK: - Reconnection Manager

class ReconnectionManager {
    private var reconnectTimer: Timer?
    private(set) var currentAttempt = 0
    private let maxAttempts = 10
    private let baseDelay: TimeInterval = 1.0
    private let maxDelay: TimeInterval = 30.0
    private var isReconnecting = false
    
    var shouldReconnect: Bool {
        return currentAttempt < maxAttempts && !isReconnecting
    }
    
    func scheduleReconnection(completion: @escaping () -> Void) {
        guard shouldReconnect else { return }
        
        isReconnecting = true
        currentAttempt += 1
        
        // Exponential backoff with jitter
        let delay = min(baseDelay * pow(2.0, Double(currentAttempt - 1)), maxDelay)
        let jitter = Double.random(in: 0...1.0)
        let finalDelay = delay + jitter
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: finalDelay, repeats: false) { [weak self] _ in
            self?.isReconnecting = false
            completion()
        }
    }
    
    func reset() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        currentAttempt = 0
        isReconnecting = false
    }
    
    func cancel() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        isReconnecting = false
    }
}

// MARK: - Message Queue

class MessageQueue {
    private var queue: [String] = []
    private let maxSize = 100
    private let lock = NSLock()
    
    func enqueue(_ message: String) {
        lock.lock()
        defer { lock.unlock() }
        
        if queue.count < maxSize {
            queue.append(message)
        }
    }
    
    func flush(handler: (String) -> Void) {
        lock.lock()
        let messages = queue
        queue.removeAll()
        lock.unlock()
        
        messages.forEach(handler)
    }
    
    func clear() {
        lock.lock()
        queue.removeAll()
        lock.unlock()
    }
}

// MARK: - Message Stream Handler

class MessageStreamHandler {
    private var partialMessage = ""
    private var streamingMessageId: String?
    
    func handleStreamingChunk(_ chunk: String, messageId: String) -> String {
        if streamingMessageId != messageId {
            partialMessage = ""
            streamingMessageId = messageId
        }
        
        partialMessage += chunk
        return partialMessage
    }
    
    func finalizeStreaming() -> String? {
        guard !partialMessage.isEmpty else { return nil }
        let result = partialMessage
        reset()
        return result
    }
    
    func reset() {
        partialMessage = ""
        streamingMessageId = nil
    }
}