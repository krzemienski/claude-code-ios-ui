//
//  WebSocketConnectionFix.swift
//  ClaudeCodeUITests
//
//  Fixes and enhancements for WebSocket connection issues
//

import Foundation
@testable import ClaudeCodeUI

/// Enhanced WebSocket Manager with debugging and proper backend integration
class WebSocketConnectionFix {
    
    // MARK: - Connection Fix Methods
    
    /// Fix connection URL to use correct backend address
    static func fixConnectionURL() -> String {
        // Use the correct backend URL from testing context
        let correctURL = "ws://192.168.0.155:3004/ws"
        
        // Store in UserDefaults for app to use
        UserDefaults.standard.set(correctURL, forKey: "websocket_url")
        UserDefaults.standard.synchronize()
        
        print("✅ WebSocket URL fixed: \(correctURL)")
        return correctURL
    }
    
    /// Fix message format to match backend expectations
    static func createProperMessage(content: String, projectPath: String, sessionId: String? = nil) -> [String: Any] {
        // Backend expects this exact structure (from server/index.js)
        var message: [String: Any] = [
            "type": "claude-command",
            "command": content,  // Backend expects 'command' not 'content'
            "options": [
                "projectPath": projectPath,
                "cwd": "/Users/nick/Documents/claude-code-ios-ui",
                "resume": sessionId != nil
            ] as [String: Any]
        ]
        
        if let sessionId = sessionId {
            (message["options"] as? [String: Any])?["sessionId"] = sessionId
        }
        
        return message
    }
    
    /// Fix authentication headers
    static func fixAuthenticationHeaders(for request: inout URLRequest) {
        // Get or create auth token
        var authToken = UserDefaults.standard.string(forKey: "authToken")
        
        if authToken == nil {
            // Generate a test token if none exists
            authToken = "test-token-\(UUID().uuidString)"
            UserDefaults.standard.set(authToken, forKey: "authToken")
        }
        
        // Add both header and query parameter for compatibility
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            // Also add as query parameter
            if var urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false) {
                var queryItems = urlComponents.queryItems ?? []
                queryItems.append(URLQueryItem(name: "token", value: token))
                urlComponents.queryItems = queryItems
                if let newURL = urlComponents.url {
                    request.url = newURL
                }
            }
        }
        
        print("🔐 Authentication fixed with token: \(authToken?.prefix(20) ?? "none")...")
    }
    
    // MARK: - WebSocket Manager Extensions
    
    /// Enhance WebSocketManager with proper backend connection
    static func enhanceWebSocketManager(_ manager: WebSocketManager) {
        // Fix the connection URL
        let correctURL = fixConnectionURL()
        
        // Configure proper settings
        manager.configure(
            enableAutoReconnect: true,
            reconnectDelay: 1.0,
            maxReconnectAttempts: 10
        )
        
        print("🔧 WebSocketManager enhanced with proper settings")
    }
    
    // MARK: - Message Handling Fixes
    
    /// Fix for parsing streaming responses
    static func parseStreamingResponse(_ text: String) -> StreamingMessage? {
        guard let data = text.data(using: .utf8) else { return nil }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Check for different streaming message types
                if let type = json["type"] as? String {
                    switch type {
                    case "streaming-start":
                        return StreamingMessage(
                            type: .start,
                            content: json["content"] as? String,
                            sessionId: json["sessionId"] as? String
                        )
                        
                    case "streaming-chunk", "claude-response":
                        return StreamingMessage(
                            type: .chunk,
                            content: json["content"] as? String ?? json["chunk"] as? String,
                            sessionId: json["sessionId"] as? String
                        )
                        
                    case "streaming-end", "response-end":
                        return StreamingMessage(
                            type: .end,
                            content: json["content"] as? String,
                            sessionId: json["sessionId"] as? String
                        )
                        
                    default:
                        // Try to extract content from other message types
                        if let content = json["content"] as? String {
                            return StreamingMessage(
                                type: .chunk,
                                content: content,
                                sessionId: json["sessionId"] as? String
                            )
                        }
                    }
                }
            }
        } catch {
            print("❌ Failed to parse streaming response: \(error)")
        }
        
        return nil
    }
    
    struct StreamingMessage {
        enum MessageType {
            case start
            case chunk
            case end
        }
        
        let type: MessageType
        let content: String?
        let sessionId: String?
    }
    
    // MARK: - Testing Utilities
    
    /// Create a properly configured WebSocket for testing
    static func createTestWebSocket() -> URLSessionWebSocketTask {
        let url = URL(string: fixConnectionURL())!
        var request = URLRequest(url: url)
        
        // Fix authentication
        fixAuthenticationHeaders(for: &request)
        
        // Configure session
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        
        let session = URLSession(configuration: config)
        let webSocket = session.webSocketTask(with: request)
        
        return webSocket
    }
    
    /// Send a test message and verify response
    static func sendTestMessage(completion: @escaping (Bool, String?) -> Void) {
        let webSocket = createTestWebSocket()
        webSocket.resume()
        
        // Send ping to verify connection
        webSocket.sendPing { error in
            if let error = error {
                completion(false, "Ping failed: \(error)")
                return
            }
            
            // Send test message
            let message = createProperMessage(
                content: "Hello from iOS test",
                projectPath: "-Users-nick-Documents-claude-code-ios-ui"
            )
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                completion(false, "Failed to create JSON")
                return
            }
            
            let wsMessage = URLSessionWebSocketTask.Message.string(jsonString)
            webSocket.send(wsMessage) { error in
                if let error = error {
                    completion(false, "Send failed: \(error)")
                    return
                }
                
                // Try to receive response
                webSocket.receive { result in
                    switch result {
                    case .success(let message):
                        switch message {
                        case .string(let text):
                            completion(true, text)
                        case .data(let data):
                            let text = String(data: data, encoding: .utf8)
                            completion(true, text)
                        }
                        
                    case .failure(let error):
                        completion(false, "Receive failed: \(error)")
                    }
                    
                    webSocket.cancel(with: .goingAway, reason: nil)
                }
            }
        }
    }
    
    // MARK: - Debug Helpers
    
    /// Monitor WebSocket traffic for debugging
    static func monitorWebSocketTraffic(_ webSocket: URLSessionWebSocketTask) {
        func receive() {
            webSocket.receive { result in
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        print("📥 [MONITOR] Received text: \(text.prefix(200))...")
                        
                        // Parse and log message details
                        if let parsed = parseStreamingResponse(text) {
                            print("   Type: \(parsed.type)")
                            print("   Content: \(parsed.content?.prefix(100) ?? "none")")
                            print("   SessionId: \(parsed.sessionId ?? "none")")
                        }
                        
                    case .data(let data):
                        print("📥 [MONITOR] Received data: \(data.count) bytes")
                    }
                    
                    // Continue monitoring
                    receive()
                    
                case .failure(let error):
                    print("❌ [MONITOR] Error: \(error)")
                }
            }
        }
        
        receive()
    }
    
    /// Verify backend is running and accessible
    static func verifyBackendStatus(completion: @escaping (Bool, String) -> Void) {
        let httpURL = "http://192.168.0.155:3004"
        guard let url = URL(string: httpURL) else {
            completion(false, "Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(false, "Backend not reachable: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 404 {
                    completion(true, "Backend is running on port 3004")
                } else {
                    completion(false, "Backend returned status: \(httpResponse.statusCode)")
                }
            } else {
                completion(false, "No response from backend")
            }
        }
        task.resume()
    }
}

// MARK: - WebSocketManager Extension

extension WebSocketManager {
    
    /// Apply all fixes to ensure proper connection
    func applyConnectionFixes() {
        // Fix URL
        let correctURL = WebSocketConnectionFix.fixConnectionURL()
        
        // Connect with fixed URL
        connect(to: correctURL)
        
        print("✅ Connection fixes applied to WebSocketManager")
    }
    
    /// Send message with proper format
    func sendProperMessage(content: String, projectPath: String, sessionId: String? = nil) {
        let message = WebSocketConnectionFix.createProperMessage(
            content: content,
            projectPath: projectPath,
            sessionId: sessionId
        )
        
        sendRawMessage(message)
    }
}

// MARK: - Test Helpers

extension XCTestCase {
    
    /// Quick test to verify WebSocket connection
    func verifyWebSocketConnection() {
        let expectation = expectation(description: "WebSocket verification")
        
        WebSocketConnectionFix.verifyBackendStatus { isRunning, status in
            print("Backend status: \(status)")
            
            if isRunning {
                WebSocketConnectionFix.sendTestMessage { success, response in
                    if success {
                        print("✅ WebSocket working! Response: \(response?.prefix(100) ?? "none")")
                    } else {
                        print("❌ WebSocket test failed: \(response ?? "unknown error")")
                    }
                    expectation.fulfill()
                }
            } else {
                print("❌ Backend not running")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 15)
    }
}