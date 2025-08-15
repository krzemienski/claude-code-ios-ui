//
//  WebSocketManager.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import Foundation
import UIKit

// MARK: - WebSocket Connection State
enum WebSocketConnectionState {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case failed
}

// MARK: - WebSocket Message Types
enum WebSocketMessageType: String, Codable {
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

// MARK: - WebSocket Manager Protocol
protocol WebSocketManagerDelegate: AnyObject {
    func webSocketDidConnect(_ manager: WebSocketManager)
    func webSocketDidDisconnect(_ manager: WebSocketManager, error: Error?)
    func webSocket(_ manager: WebSocketManager, didReceiveMessage message: WebSocketMessage)
    func webSocket(_ manager: WebSocketManager, didReceiveData data: Data)
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState)
    // Optional method for raw text messages (shell WebSocket)
    func webSocket(_ manager: WebSocketManager, didReceiveText text: String)
}

// Provide default implementation for optional method
extension WebSocketManagerDelegate {
    func webSocket(_ manager: WebSocketManager, didReceiveText text: String) {
        // Default implementation - do nothing
    }
}

// MARK: - WebSocket Manager
final class WebSocketManager {
    
    // MARK: - Properties
    weak var delegate: WebSocketManagerDelegate?
    private var webSocketTask: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)
    private var pingTimer: Timer?
    private var reconnectTimer: Timer?
    
    // Thread safety for connection management (serial queue by default)
    private let connectionQueue = DispatchQueue(label: "com.claudecode.websocket.connection")
    
    // Connection properties
    private var url: URL?
    private var originalURLString: String? // Store the original URL without token
    private(set) var connectionState: WebSocketConnectionState = .disconnected {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.webSocketConnectionStateChanged(self.connectionState)
            }
        }
    }
    
    // Reconnection settings
    private var enableAutoReconnect = true
    private var reconnectDelay: TimeInterval = 1.0
    private var maxReconnectAttempts = 10
    private var reconnectAttempts = 0
    private let maxReconnectDelay: TimeInterval = 30.0
    private var intentionalDisconnect = false // Track manual disconnections
    
    // Message queue for offline support
    private var messageQueue: [WebSocketMessage] = []
    private let messageQueueLimit = 100
    
    var isConnected: Bool {
        return connectionState == .connected
    }
    
    // MARK: - Initialization
    init() {
        setupNotifications()
    }
    
    deinit {
        disconnect()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Configuration
    
    func configure(enableAutoReconnect: Bool, reconnectDelay: TimeInterval, maxReconnectAttempts: Int) {
        self.enableAutoReconnect = enableAutoReconnect
        self.reconnectDelay = reconnectDelay
        self.maxReconnectAttempts = maxReconnectAttempts
    }
    
    // MARK: - Connection Management
    
    func connect(to urlString: String) {
        connectionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Prevent multiple simultaneous connection attempts
            guard self.connectionState == .disconnected || self.connectionState == .failed else {
                logInfo("WebSocket already connecting/connected, ignoring connect request", category: "WebSocket")
                return
            }
            
            // Reset intentional disconnect flag when manually connecting
            self.intentionalDisconnect = false
            
            // Store the original URL for reconnection
            self.originalURLString = urlString
            
            // Add JWT token to URL if available
            var finalUrlString = urlString
            if let authToken = UserDefaults.standard.string(forKey: "authToken") {
                // Add token as query parameter for WebSocket connection
                let separator = urlString.contains("?") ? "&" : "?"
                finalUrlString = "\(urlString)\(separator)token=\(authToken)"
            }
            
            guard let url = URL(string: finalUrlString) else {
                logError("Invalid WebSocket URL: \(finalUrlString)", category: "WebSocket")
                self.connectionState = .failed
                return
            }
            
            // Clean up any existing connection
            if self.webSocketTask != nil {
                self.webSocketTask?.cancel(with: .goingAway, reason: nil)
                self.webSocketTask = nil
            }
            
            self.url = url
            self.connectionState = .connecting
            
            var request = URLRequest(url: url)
            
            // Also add authentication token in header for compatibility
            if let authToken = UserDefaults.standard.string(forKey: "authToken") {
                request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            }
            
            self.webSocketTask = self.session.webSocketTask(with: request)
            self.webSocketTask?.resume()
            
            // Send a test ping to verify connection before marking as connected
            self.webSocketTask?.sendPing { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    logError("WebSocket initial ping failed: \(error)", category: "WebSocket")
                    self.handleError(error)
                } else {
                    // Connection is truly established
                    self.connectionState = .connected
                    self.reconnectAttempts = 0
                    self.intentionalDisconnect = false // Reset on successful connection
                    self.delegate?.webSocketDidConnect(self)
                    self.flushMessageQueue()
                    logInfo("WebSocket connected and verified: \(finalUrlString)", category: "WebSocket")
                    
                    // Start receiving messages ONLY after successful connection
                    self.receiveMessage()
                    
                    // Start ping timer after successful connection
                    self.startPingTimer()
                }
            }
        }
    }
    
    func disconnect() {
        connectionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.stopPingTimer()
            self.stopReconnectTimer()
            
            // Mark this as an intentional disconnect to prevent auto-reconnect
            self.intentionalDisconnect = true
            
            if let task = self.webSocketTask {
                task.cancel(with: .goingAway, reason: nil)
            }
            self.webSocketTask = nil
            
            if self.connectionState != .disconnected {
                self.connectionState = .disconnected
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.webSocketDidDisconnect(self, error: nil)
                }
            }
        }
    }
    
    // MARK: - Message Handling
    
    func sendMessage(_ text: String, projectId: String, projectPath: String? = nil, messageType: WebSocketMessageType = .claudeCommand) {
        // Send command through WebSocket with specified type
        let sessionId = UserDefaults.standard.string(forKey: "currentSessionId_\(projectId)")
        
        // Use projectPath if provided, otherwise use projectId as fallback
        let actualProjectPath = projectPath ?? projectId
        
        // Determine the correct message type string
        let typeString: String
        switch messageType {
        case .claudeCommand:
            typeString = "claude-command"
        case .cursorCommand:
            typeString = "cursor-command"
        case .abortSession:
            typeString = "abort-session"
        default:
            typeString = messageType.rawValue
        }
        
        // Backend expects a flat JSON structure with type and other fields at root level
        let messageData: [String: Any] = [
            "type": typeString,
            "content": text,
            "projectPath": actualProjectPath,
            "sessionId": sessionId as Any,
            "resume": sessionId != nil,
            "timestamp": ISO8601DateFormatter.shared.string(from: Date())
        ]
        
        // Send the raw message directly
        sendRawMessage(messageData)
    }
    
    func send(_ message: Message, projectPath: String) async throws {
        // Use claudeCommand type for all messages to Claude
        let wsMessage = WebSocketMessage(
            type: .claudeCommand,
            payload: [
                "id": message.id,
                "content": message.content,
                "role": message.role.rawValue,
                "projectPath": projectPath,  // Include project path
                "timestamp": ISO8601DateFormatter.shared.string(from: message.timestamp)
            ]
        )
        
        send(wsMessage)
    }
    
    func send(_ message: WebSocketMessage) {
        guard isConnected else {
            // Queue message if not connected
            if messageQueue.count < messageQueueLimit {
                messageQueue.append(message)
            }
            
            // Attempt reconnection if enabled
            if enableAutoReconnect && connectionState != .reconnecting {
                attemptReconnection()
            }
            return
        }
        
        guard let webSocketTask = webSocketTask else { return }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(message)
            let string = String(data: data, encoding: .utf8)!
            let wsMessage = URLSessionWebSocketTask.Message.string(string)
            
            webSocketTask.send(wsMessage) { [weak self] error in
                if let error = error {
                    logError("WebSocket send error: \(error)", category: "WebSocket")
                    self?.handleError(error)
                }
            }
        } catch {
            logError("Failed to encode message: \(error)", category: "WebSocket")
        }
    }
    
    /// Send a raw message dictionary directly without WebSocketMessage wrapper
    /// This is needed for the backend which expects flat JSON structure
    func sendRawMessage(_ messageData: [String: Any]) {
        guard isConnected else {
            // Attempt reconnection if enabled
            if enableAutoReconnect && connectionState != .reconnecting {
                attemptReconnection()
            }
            return
        }
        
        guard let webSocketTask = webSocketTask else { return }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: messageData, options: [])
            let string = String(data: jsonData, encoding: .utf8)!
            let wsMessage = URLSessionWebSocketTask.Message.string(string)
            
            webSocketTask.send(wsMessage) { [weak self] error in
                if let error = error {
                    logError("WebSocket send error: \(error)", category: "WebSocket")
                    self?.handleError(error)
                } else {
                    logInfo("Successfully sent message: \(messageData["type"] ?? "unknown")", category: "WebSocket")
                }
            }
        } catch {
            logError("Failed to encode raw message: \(error)", category: "WebSocket")
        }
    }
    
    /// Send a raw text string directly without any JSON encoding
    /// Used for shell WebSocket which expects specific JSON format
    func sendRawText(_ text: String) {
        guard isConnected else {
            // Attempt reconnection if enabled
            if enableAutoReconnect && connectionState != .reconnecting {
                attemptReconnection()
            }
            return
        }
        
        guard let webSocketTask = webSocketTask else { return }
        
        let wsMessage = URLSessionWebSocketTask.Message.string(text)
        
        webSocketTask.send(wsMessage) { [weak self] error in
            if let error = error {
                logError("WebSocket send error: \(error)", category: "WebSocket")
                self?.handleError(error)
            } else {
                logInfo("Successfully sent raw text message", category: "WebSocket")
            }
        }
    }
    
    func sendTypingIndicator(for sessionId: String) {
        let message = WebSocketMessage(
            type: .typing,
            payload: ["sessionId": sessionId],
            sessionId: sessionId
        )
        send(message)
    }
    
    // MARK: - Claude Command Support
    
    func sendClaudeCommand(content: String, projectPath: String, sessionId: String? = nil) {
        // Create message data with claude-command type in flat JSON format
        var messageData: [String: Any] = [
            "type": "claude-command",
            "content": content,
            "projectPath": projectPath,
            "timestamp": ISO8601DateFormatter.shared.string(from: Date())
        ]
        
        if let sessionId = sessionId {
            messageData["sessionId"] = sessionId
            messageData["resume"] = true
        }
        
        // Send raw message to match backend expectations
        sendRawMessage(messageData)
    }
    
    // MARK: - Cursor Command Support
    
    func sendCursorCommand(content: String, projectPath: String, sessionId: String? = nil) {
        // Create message data with cursor-command type
        var messageData: [String: Any] = [
            "type": "cursor-command",
            "content": content,
            "projectPath": projectPath,
            "timestamp": ISO8601DateFormatter.shared.string(from: Date())
        ]
        
        if let sessionId = sessionId {
            messageData["sessionId"] = sessionId
            messageData["resume"] = true
        }
        
        // Send raw message to match backend expectations
        sendRawMessage(messageData)
    }
    
    func abortSession(sessionId: String) {
        // Send abort-session message directly in flat JSON format
        let messageData: [String: Any] = [
            "type": "abort-session",
            "sessionId": sessionId,
            "timestamp": ISO8601DateFormatter.shared.string(from: Date())
        ]
        
        sendRawMessage(messageData)
    }
    
    private func receiveMessage() {
        // Only receive messages if we're actually connected
        guard connectionState == .connected else {
            logInfo("Not receiving messages - connection state: \(connectionState)", category: "WebSocket")
            return
        }
        
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleTextMessage(text)
                case .data(let data):
                    self.delegate?.webSocket(self, didReceiveData: data)
                @unknown default:
                    break
                }
                
                // Continue receiving messages only if still connected
                if self.connectionState == .connected {
                    self.receiveMessage()
                }
                
            case .failure(let error):
                logError("WebSocket receive error: \(error)", category: "WebSocket")
                self.handleError(error)
            }
        }
    }
    
    private func handleTextMessage(_ text: String) {
        // First, notify delegate of raw text for shell WebSocket handling
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.webSocket(self, didReceiveText: text)
        }
        
        guard let data = text.data(using: .utf8) else { return }
        
        // First try to parse as flat JSON from backend
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            // Backend sends flat JSON with type at root level
            if let typeString = json["type"] as? String {
                // Convert the flat JSON to WebSocketMessage format
                let messageType = WebSocketMessageType(rawValue: typeString) ?? .message
                
                // Store session ID if provided
                if messageType == .sessionCreated,
                   let sessionId = json["sessionId"] as? String {
                    // Store the session ID for future use
                    if let projectPath = json["projectPath"] as? String {
                        UserDefaults.standard.set(sessionId, forKey: "currentSessionId_\(projectPath)")
                    }
                }
                
                // Create WebSocketMessage from flat JSON
                let message = WebSocketMessage(
                    type: messageType,
                    payload: json,  // Pass entire JSON as payload
                    sessionId: json["sessionId"] as? String
                )
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.webSocket(self, didReceiveMessage: message)
                }
                return
            }
        }
        
        // Fallback to original WebSocketMessage decoding for compatibility
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let message = try decoder.decode(WebSocketMessage.self, from: data)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.webSocket(self, didReceiveMessage: message)
            }
        } catch {
            // Try to parse as streaming JSON
            if let streamingResponse = parseStreamingJSON(text) {
                let message = WebSocketMessage(
                    type: .streamingResponse,
                    payload: streamingResponse
                )
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.webSocket(self, didReceiveMessage: message)
                }
            } else {
                logError("Failed to decode WebSocket message: \(error) - Raw: \(text)", category: "WebSocket")
            }
        }
    }
    
    private func parseStreamingJSON(_ text: String) -> [String: Any]? {
        guard let data = text.data(using: .utf8) else { return nil }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            return json as? [String: Any]
        } catch {
            return nil
        }
    }
    
    // MARK: - Reconnection Logic
    
    private func attemptReconnection() {
        connectionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Prevent multiple reconnection attempts
            guard self.connectionState != .reconnecting else {
                logInfo("Already attempting reconnection, skipping duplicate attempt", category: "WebSocket")
                return
            }
            
            guard self.enableAutoReconnect,
                  self.reconnectAttempts < self.maxReconnectAttempts,
                  let urlString = self.originalURLString else {
                self.connectionState = .failed
                return
            }
            
            self.connectionState = .reconnecting
            self.reconnectAttempts += 1
            
            // Calculate delay with exponential backoff
            let delay = min(self.reconnectDelay * pow(2.0, Double(self.reconnectAttempts - 1)), self.maxReconnectDelay)
            
            logInfo("Attempting reconnection #\(self.reconnectAttempts) in \(delay)s", category: "WebSocket")
            
            self.stopReconnectTimer()
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                    guard let self = self else { return }
                    // Reset state before attempting to connect
                    self.connectionQueue.async { [weak self] in
                        guard let self = self else { return }
                        self.connectionState = .disconnected
                    }
                    // Use the original URL string to get a fresh token
                    self.connect(to: urlString)
                }
            }
        }
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    // MARK: - Message Queue
    
    private func flushMessageQueue() {
        let messages = messageQueue
        messageQueue.removeAll()
        
        for message in messages {
            send(message)
        }
    }
    
    // MARK: - Ping/Pong
    
    private func startPingTimer() {
        stopPingTimer()
        // Increase ping interval to 45 seconds to be less aggressive
        // Also fire after interval, not immediately
        pingTimer = Timer.scheduledTimer(withTimeInterval: 45.0, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
        // Add timer to run loop to ensure it fires
        if let timer = pingTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func sendPing() {
        webSocketTask?.sendPing { [weak self] error in
            if let error = error {
                logError("WebSocket ping error: \(error)", category: "WebSocket")
                self?.handleError(error)
            }
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        stopPingTimer()
        
        let wasConnected = isConnected
        let previousState = connectionState
        connectionState = .disconnected
        
        // Only notify delegate if we were actually connected or connecting
        if previousState != .disconnected && previousState != .failed {
            delegate?.webSocketDidDisconnect(self, error: error)
        }
        
        // Attempt reconnection only if:
        // 1. We were previously connected
        // 2. Auto-reconnect is enabled
        // 3. This was NOT an intentional disconnect
        // 4. We're not already reconnecting
        if wasConnected && enableAutoReconnect && !intentionalDisconnect && previousState != .reconnecting {
            attemptReconnection()
        }
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
        // Store the URL for later reconnection
        let savedURL = originalURLString
        disconnect()
        originalURLString = savedURL // Preserve URL after disconnect
    }
    
    @objc private func appWillEnterForeground() {
        // Reconnect when app returns to foreground, but only if not already connected/connecting
        if let urlString = originalURLString, 
           connectionState == .disconnected {
            // Small delay to ensure app is fully in foreground
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.connect(to: urlString)
            }
        }
    }
}

// MARK: - WebSocket Message Model
struct WebSocketMessage: Codable {
    let type: WebSocketMessageType
    let payload: [String: Any]?
    let timestamp: Date
    let sessionId: String?
    
    init(type: WebSocketMessageType, payload: [String: Any]? = nil, timestamp: Date = Date(), sessionId: String? = nil) {
        self.type = type
        self.payload = payload
        self.timestamp = timestamp
        self.sessionId = sessionId
    }
    
    // Custom encoding/decoding for payload
    enum CodingKeys: String, CodingKey {
        case type, payload, timestamp, sessionId
    }
    
    init(from decoder: Decoder) throws {
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
    
    func encode(to encoder: Encoder) throws {
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

// MARK: - WebSocket Errors
enum WebSocketError: LocalizedError {
    case invalidURL
    case connectionFailed
    case authenticationFailed
    case messageEncodingFailed
    case messageDecodingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid WebSocket URL"
        case .connectionFailed:
            return "Failed to connect to WebSocket"
        case .authenticationFailed:
            return "WebSocket authentication failed"
        case .messageEncodingFailed:
            return "Failed to encode message"
        case .messageDecodingFailed:
            return "Failed to decode message"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "Please check the WebSocket URL configuration."
        case .connectionFailed:
            return "Please check your internet connection and try again."
        case .authenticationFailed:
            return "Please check your authentication credentials."
        case .messageEncodingFailed, .messageDecodingFailed:
            return "Please check the message format."
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .invalidURL, .messageEncodingFailed, .messageDecodingFailed:
            return false
        case .connectionFailed, .authenticationFailed:
            return true
        }
    }
}

// MARK: - AnyCodable Helper
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
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
    
    func encode(to encoder: Encoder) throws {
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

// MARK: - ISO8601DateFormatter Extension
extension ISO8601DateFormatter {
    static let shared: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}