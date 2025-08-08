//
//  WebSocketManager.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import Foundation

// MARK: - WebSocket Message Types
enum WebSocketMessageType: String, Codable {
    case connection = "connection"
    case sessionStart = "session:start"
    case sessionMessage = "session:message"
    case sessionEnd = "session:end"
    case sessionCreated = "session-created"
    case claudeOutput = "claude-output"
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
}

class WebSocketManager: NSObject {
    
    // MARK: - Properties
    weak var delegate: WebSocketManagerDelegate?
    private var webSocketTask: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)
    private var pingTimer: Timer?
    
    private let baseURL: String
    private let endpoint: String
    private var authToken: String?
    
    var isConnected: Bool {
        return webSocketTask?.state == .running
    }
    
    // MARK: - Initialization
    init(baseURL: String = AppConfig.websocketURL.replacingOccurrences(of: "/ws", with: ""), endpoint: String) {
        self.baseURL = baseURL
        self.endpoint = endpoint
        super.init()
    }
    
    // MARK: - Connection Management
    func connect(authToken: String? = nil) {
        self.authToken = authToken
        
        var urlString = "\(baseURL)\(endpoint)"
        if let token = authToken {
            urlString += "?token=\(token)"
        }
        
        guard let url = URL(string: urlString) else {
            delegate?.webSocketDidDisconnect(self, error: WebSocketError.invalidURL)
            return
        }
        
        let request = URLRequest(url: url)
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        
        delegate?.webSocketDidConnect(self)
        
        // Start receiving messages
        receiveMessage()
        
        // Start ping timer
        startPingTimer()
    }
    
    func disconnect() {
        stopPingTimer()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
    
    // MARK: - Message Handling
    func send(_ message: WebSocketMessage) {
        guard let webSocketTask = webSocketTask else { return }
        
        do {
            let data = try JSONEncoder().encode(message)
            let string = String(data: data, encoding: .utf8)!
            let message = URLSessionWebSocketTask.Message.string(string)
            
            webSocketTask.send(message) { [weak self] error in
                if let error = error {
                    print("WebSocket send error: \(error)")
                    self?.handleError(error)
                }
            }
        } catch {
            print("Failed to encode message: \(error)")
        }
    }
    
    func sendData(_ data: Data) {
        guard let webSocketTask = webSocketTask else { return }
        
        let message = URLSessionWebSocketTask.Message.data(data)
        webSocketTask.send(message) { [weak self] error in
            if let error = error {
                print("WebSocket send data error: \(error)")
                self?.handleError(error)
            }
        }
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
                print("WebSocket receive error: \(error)")
                self.handleError(error)
            }
        }
    }
    
    private func handleTextMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            let message = try JSONDecoder().decode(WebSocketMessage.self, from: data)
            delegate?.webSocket(self, didReceiveMessage: message)
        } catch {
            // If it's not a standard message, try to parse it as streaming JSON
            if let streamingResponse = parseStreamingJSON(text) {
                let message = WebSocketMessage(
                    type: .claudeOutput,
                    payload: streamingResponse,
                    timestamp: Date()
                )
                delegate?.webSocket(self, didReceiveMessage: message)
            } else {
                print("Failed to decode WebSocket message: \(error)")
            }
        }
    }
    
    private func parseStreamingJSON(_ text: String) -> [String: Any]? {
        // Handle streaming JSON responses from Claude
        // This is a simplified version - in production, you'd want more robust parsing
        guard let data = text.data(using: .utf8) else { return nil }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            return json as? [String: Any]
        } catch {
            return nil
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
                print("WebSocket ping error: \(error)")
                self?.handleError(error)
            }
        }
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) {
        stopPingTimer()
        delegate?.webSocketDidDisconnect(self, error: error)
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
        
        // Decode payload as generic dictionary
        if let payloadData = try? container.decode(Data.self, forKey: .payload) {
            payload = try? JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any]
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
            let data = try JSONSerialization.data(withJSONObject: payload, options: [])
            try container.encode(data, forKey: .payload)
        }
    }
}

// MARK: - WebSocket Errors
enum WebSocketError: LocalizedError {
    case invalidURL
    case connectionFailed
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid WebSocket URL"
        case .connectionFailed:
            return "Failed to connect to WebSocket"
        case .authenticationFailed:
            return "WebSocket authentication failed"
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
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .invalidURL:
            return false
        case .connectionFailed, .authenticationFailed:
            return true
        }
    }
}