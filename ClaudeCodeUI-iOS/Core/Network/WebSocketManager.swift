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
    
    // Client to server
    case claudeCommand = "claude-command"
    case abortSession = "abort-session"
    case message = "message"
    case typing = "typing"
    case status = "status"
    
    // Shell WebSocket
    case shellInit = "init"
    case shellInput = "input"
    case shellResize = "resize"
    case shellOutput = "output"
    case urlOpen = "url_open"
}

// MARK: - WebSocket Manager Protocol
protocol WebSocketManagerDelegate: AnyObject {
    func webSocketDidConnect(_ manager: WebSocketManager)
    func webSocketDidDisconnect(_ manager: WebSocketManager, error: Error?)
    func webSocket(_ manager: WebSocketManager, didReceiveMessage message: WebSocketMessage)
    func webSocket(_ manager: WebSocketManager, didReceiveData data: Data)
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState)
}

// MARK: - WebSocket Manager
final class WebSocketManager {
    
    // MARK: - Properties
    weak var delegate: WebSocketManagerDelegate?
    private var webSocketTask: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)
    private var pingTimer: Timer?
    private var reconnectTimer: Timer?
    
    // Connection properties
    private var url: URL?
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
        // Add JWT token to URL if available
        var finalUrlString = urlString
        if let authToken = UserDefaults.standard.string(forKey: "authToken") {
            // Add token as query parameter for WebSocket connection
            let separator = urlString.contains("?") ? "&" : "?"
            finalUrlString = "\(urlString)\(separator)token=\(authToken)"
        }
        
        guard let url = URL(string: finalUrlString) else {
            logError("Invalid WebSocket URL: \(finalUrlString)", category: "WebSocket")
            connectionState = .failed
            return
        }
        
        disconnect() // Ensure clean state
        
        self.url = url
        connectionState = .connecting
        
        var request = URLRequest(url: url)
        
        // Also add authentication token in header for compatibility
        if let authToken = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        
        // Start receiving messages
        receiveMessage()
        
        // Start ping timer
        startPingTimer()
        
        // Update state after a small delay to ensure connection is established
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            if self.webSocketTask?.state == .running {
                self.connectionState = .connected
                self.reconnectAttempts = 0
                self.delegate?.webSocketDidConnect(self)
                self.flushMessageQueue()
                logInfo("WebSocket connected to: \(urlString)", category: "WebSocket")
            }
        }
    }
    
    func disconnect() {
        stopPingTimer()
        stopReconnectTimer()
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        if connectionState != .disconnected {
            connectionState = .disconnected
            delegate?.webSocketDidDisconnect(self, error: nil)
        }
    }
    
    // MARK: - Message Handling
    
    func sendMessage(_ text: String, projectId: String) {
        // Send Claude command through WebSocket
        let sessionId = UserDefaults.standard.string(forKey: "currentSessionId_\(projectId)")
        
        let message = WebSocketMessage(
            type: .claudeCommand,
            payload: [
                "command": text,
                "projectPath": projectId,
                "sessionId": sessionId as Any,
                "resume": sessionId != nil,
                "timestamp": ISO8601DateFormatter.shared.string(from: Date())
            ]
        )
        send(message)
    }
    
    func send(_ message: Message) async throws {
        let wsMessage = WebSocketMessage(
            type: .message,
            payload: [
                "id": message.id,
                "content": message.content,
                "role": message.role.rawValue,
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
        var payload: [String: Any] = [
            "content": content,
            "projectPath": projectPath
        ]
        
        if let sessionId = sessionId {
            payload["sessionId"] = sessionId
        }
        
        let message = WebSocketMessage(
            type: .claudeCommand,
            payload: payload,
            sessionId: sessionId
        )
        
        send(message)
    }
    
    func abortSession(sessionId: String) {
        let message = WebSocketMessage(
            type: .abortSession,
            payload: ["sessionId": sessionId],
            sessionId: sessionId
        )
        send(message)
    }
    
    private func receiveMessage() {
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
                
                // Continue receiving messages
                self.receiveMessage()
                
            case .failure(let error):
                logError("WebSocket receive error: \(error)", category: "WebSocket")
                self.handleError(error)
            }
        }
    }
    
    private func handleTextMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
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
                logError("Failed to decode WebSocket message: \(error)", category: "WebSocket")
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
        guard enableAutoReconnect,
              reconnectAttempts < maxReconnectAttempts,
              let url = url else {
            connectionState = .failed
            return
        }
        
        connectionState = .reconnecting
        reconnectAttempts += 1
        
        // Calculate delay with exponential backoff
        let delay = min(reconnectDelay * pow(2.0, Double(reconnectAttempts - 1)), maxReconnectDelay)
        
        logInfo("Attempting reconnection #\(reconnectAttempts) in \(delay)s", category: "WebSocket")
        
        stopReconnectTimer()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.connect(to: url.absoluteString)
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
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.sendPing()
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
        connectionState = .disconnected
        
        delegate?.webSocketDidDisconnect(self, error: error)
        
        // Attempt reconnection if it was previously connected
        if wasConnected && enableAutoReconnect {
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
        disconnect()
    }
    
    @objc private func appWillEnterForeground() {
        // Reconnect when app returns to foreground
        if let url = url {
            connect(to: url.absoluteString)
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