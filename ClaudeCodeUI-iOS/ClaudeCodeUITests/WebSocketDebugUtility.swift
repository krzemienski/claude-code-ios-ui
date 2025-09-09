//
//  WebSocketDebugUtility.swift
//  ClaudeCodeUITests
//
//  Real-time WebSocket debugging and monitoring utilities
//

import Foundation
import XCTest

/// WebSocket Frame Analyzer for debugging connection issues
final class WebSocketDebugUtility {
    
    // MARK: - Properties
    private var webSocket: URLSessionWebSocketTask?
    private var session: URLSession
    private let backendURL = "ws://192.168.0.155:3004/ws"
    
    // Frame monitoring
    private var frameLog: [FrameInfo] = []
    private var messageLog: [MessageInfo] = []
    
    struct FrameInfo {
        let timestamp: Date
        let type: FrameType
        let size: Int
        let content: String?
        let direction: Direction
        
        enum FrameType {
            case text
            case binary
            case ping
            case pong
            case close
        }
        
        enum Direction {
            case sent
            case received
        }
    }
    
    struct MessageInfo {
        let timestamp: Date
        let messageType: String
        let sessionId: String?
        let content: String?
        let status: MessageStatus
        
        enum MessageStatus {
            case pending
            case sent
            case acknowledged
            case delivered
            case failed
        }
    }
    
    // MARK: - Initialization
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
    }
    
    // MARK: - Connection Diagnostics
    
    /// Diagnose connection issues and provide detailed report
    func diagnoseConnection(completion: @escaping (DiagnosticReport) -> Void) {
        var report = DiagnosticReport()
        
        // Test 1: URL reachability
        testURLReachability { reachable in
            report.urlReachable = reachable
            
            // Test 2: WebSocket handshake
            self.testWebSocketHandshake { handshakeSuccess in
                report.handshakeSuccess = handshakeSuccess
                
                // Test 3: Authentication
                self.testAuthentication { authSuccess in
                    report.authenticationSuccess = authSuccess
                    
                    // Test 4: Message format
                    self.testMessageFormat { formatValid in
                        report.messageFormatValid = formatValid
                        
                        // Test 5: Streaming capability
                        self.testStreamingCapability { streamingWorks in
                            report.streamingWorks = streamingWorks
                            
                            completion(report)
                        }
                    }
                }
            }
        }
    }
    
    struct DiagnosticReport {
        var urlReachable = false
        var handshakeSuccess = false
        var authenticationSuccess = false
        var messageFormatValid = false
        var streamingWorks = false
        
        var summary: String {
            """
            🔍 WebSocket Diagnostic Report
            ==============================
            ✓ URL Reachable: \(urlReachable ? "✅" : "❌")
            ✓ WebSocket Handshake: \(handshakeSuccess ? "✅" : "❌")
            ✓ Authentication: \(authenticationSuccess ? "✅" : "❌")
            ✓ Message Format: \(messageFormatValid ? "✅" : "❌")
            ✓ Streaming: \(streamingWorks ? "✅" : "❌")
            
            Overall: \(overallStatus)
            """
        }
        
        var overallStatus: String {
            if urlReachable && handshakeSuccess && authenticationSuccess && messageFormatValid && streamingWorks {
                return "✅ All systems operational"
            } else if !urlReachable {
                return "❌ Backend not reachable - Check if server is running"
            } else if !handshakeSuccess {
                return "❌ WebSocket handshake failed - Check WebSocket endpoint"
            } else if !authenticationSuccess {
                return "⚠️ Authentication issues - Check token configuration"
            } else if !messageFormatValid {
                return "❌ Message format invalid - Check JSON structure"
            } else {
                return "⚠️ Partial functionality - Check streaming configuration"
            }
        }
    }
    
    // MARK: - Individual Tests
    
    private func testURLReachability(completion: @escaping (Bool) -> Void) {
        // Convert WebSocket URL to HTTP for reachability test
        let httpURL = backendURL.replacingOccurrences(of: "ws://", with: "http://")
        guard let url = URL(string: httpURL) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5
        
        let task = session.dataTask(with: request) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                // Any response means server is reachable
                completion(httpResponse.statusCode > 0)
            } else {
                completion(false)
            }
        }
        task.resume()
    }
    
    private func testWebSocketHandshake(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: backendURL) else {
            completion(false)
            return
        }
        
        let ws = session.webSocketTask(with: url)
        ws.resume()
        
        ws.sendPing { error in
            if error == nil {
                completion(true)
                ws.cancel(with: .goingAway, reason: nil)
            } else {
                completion(false)
            }
        }
    }
    
    private func testAuthentication(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: backendURL) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        
        // Add auth token if available
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let ws = session.webSocketTask(with: request)
        ws.resume()
        
        // Send authenticated message
        let authMessage: [String: Any] = [
            "type": "ping",
            "authenticated": true
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: authMessage),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            
            let message = URLSessionWebSocketTask.Message.string(jsonString)
            ws.send(message) { error in
                completion(error == nil)
                ws.cancel(with: .goingAway, reason: nil)
            }
        } else {
            completion(false)
        }
    }
    
    private func testMessageFormat(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: backendURL) else {
            completion(false)
            return
        }
        
        let ws = session.webSocketTask(with: url)
        ws.resume()
        
        // Test message in expected format
        let testMessage: [String: Any] = [
            "type": "claude-command",
            "command": "test",
            "options": [
                "projectPath": "-Users-nick-Documents-claude-code-ios-ui",
                "sessionId": UUID().uuidString,
                "resume": false
            ]
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: testMessage),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            
            let message = URLSessionWebSocketTask.Message.string(jsonString)
            ws.send(message) { error in
                if error == nil {
                    // Try to receive response
                    ws.receive { result in
                        switch result {
                        case .success:
                            completion(true)
                        case .failure:
                            completion(false)
                        }
                        ws.cancel(with: .goingAway, reason: nil)
                    }
                } else {
                    completion(false)
                    ws.cancel(with: .goingAway, reason: nil)
                }
            }
        } else {
            completion(false)
        }
    }
    
    private func testStreamingCapability(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: backendURL) else {
            completion(false)
            return
        }
        
        let ws = session.webSocketTask(with: url)
        ws.resume()
        
        var receivedChunks = 0
        let maxWaitTime: TimeInterval = 10
        let startTime = Date()
        
        // Function to receive streaming messages
        func receiveStream() {
            ws.receive { result in
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        receivedChunks += 1
                        
                        // Check if it's a streaming message
                        if text.contains("streaming") || text.contains("chunk") || text.contains("claude") {
                            completion(true)
                            ws.cancel(with: .goingAway, reason: nil)
                            return
                        }
                        
                        // Continue receiving if within time limit
                        if Date().timeIntervalSince(startTime) < maxWaitTime {
                            receiveStream()
                        } else {
                            completion(receivedChunks > 0)
                            ws.cancel(with: .goingAway, reason: nil)
                        }
                        
                    case .data:
                        receiveStream()
                    }
                    
                case .failure:
                    completion(false)
                    ws.cancel(with: .goingAway, reason: nil)
                }
            }
        }
        
        // Start receiving
        receiveStream()
        
        // Send a message that might trigger streaming
        let streamMessage: [String: Any] = [
            "type": "claude-command",
            "command": "Hello",
            "options": [
                "projectPath": "-Users-nick-Documents-claude-code-ios-ui"
            ]
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: streamMessage),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let message = URLSessionWebSocketTask.Message.string(jsonString)
            ws.send(message) { _ in }
        }
    }
    
    // MARK: - Frame Monitoring
    
    /// Monitor WebSocket frames in real-time
    func startFrameMonitoring(onFrame: @escaping (FrameInfo) -> Void) {
        guard let url = URL(string: backendURL) else { return }
        
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        
        // Continuously receive frames
        func receiveFrame() {
            webSocket?.receive { [weak self] result in
                switch result {
                case .success(let message):
                    let frameInfo: FrameInfo
                    
                    switch message {
                    case .string(let text):
                        frameInfo = FrameInfo(
                            timestamp: Date(),
                            type: .text,
                            size: text.count,
                            content: text,
                            direction: .received
                        )
                        
                    case .data(let data):
                        frameInfo = FrameInfo(
                            timestamp: Date(),
                            type: .binary,
                            size: data.count,
                            content: nil,
                            direction: .received
                        )
                    }
                    
                    self?.frameLog.append(frameInfo)
                    onFrame(frameInfo)
                    
                    // Continue receiving
                    receiveFrame()
                    
                case .failure(let error):
                    print("❌ Frame monitoring error: \(error)")
                }
            }
        }
        
        receiveFrame()
    }
    
    /// Stop frame monitoring
    func stopFrameMonitoring() {
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
    }
    
    // MARK: - Message Tracking
    
    /// Track message lifecycle from send to delivery
    func trackMessage(_ messageId: String, content: String) -> MessageTracker {
        let tracker = MessageTracker(messageId: messageId, content: content)
        
        // Monitor for this specific message
        tracker.startTracking(webSocket: webSocket)
        
        return tracker
    }
    
    class MessageTracker {
        let messageId: String
        let content: String
        private var startTime: Date
        private var events: [(Date, String)] = []
        
        init(messageId: String, content: String) {
            self.messageId = messageId
            self.content = content
            self.startTime = Date()
            events.append((startTime, "Created"))
        }
        
        func startTracking(webSocket: URLSessionWebSocketTask?) {
            events.append((Date(), "Sent to WebSocket"))
            
            // Monitor for response
            webSocket?.receive { [weak self] result in
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        if text.contains(self?.messageId ?? "") {
                            self?.events.append((Date(), "Response received"))
                        }
                    case .data:
                        break
                    }
                case .failure:
                    self?.events.append((Date(), "Connection failed"))
                }
            }
        }
        
        var report: String {
            var output = "📊 Message Tracking Report\n"
            output += "ID: \(messageId)\n"
            output += "Content: \(content.prefix(50))...\n"
            output += "\nEvents:\n"
            
            for event in events {
                let timeElapsed = event.0.timeIntervalSince(startTime)
                output += String(format: "  +%.2fs: %@\n", timeElapsed, event.1)
            }
            
            return output
        }
    }
    
    // MARK: - Fix Suggestions
    
    /// Analyze issues and provide fix suggestions
    func analyzeProblemAndSuggestFix(error: Error?) -> FixSuggestion {
        var suggestion = FixSuggestion()
        
        if let error = error {
            let errorString = error.localizedDescription
            
            if errorString.contains("refused") || errorString.contains("timeout") {
                suggestion.problem = "Connection refused or timeout"
                suggestion.possibleCauses = [
                    "Backend server not running",
                    "Wrong IP address or port",
                    "Firewall blocking connection"
                ]
                suggestion.fixes = [
                    "1. Check if backend is running: docker ps",
                    "2. Verify IP address: ifconfig or ipconfig",
                    "3. Test with curl: curl http://192.168.0.155:3004",
                    "4. Check firewall settings"
                ]
            } else if errorString.contains("401") || errorString.contains("auth") {
                suggestion.problem = "Authentication failure"
                suggestion.possibleCauses = [
                    "Missing or invalid auth token",
                    "Token expired",
                    "Wrong token format"
                ]
                suggestion.fixes = [
                    "1. Check UserDefaults for authToken",
                    "2. Verify token format (Bearer prefix)",
                    "3. Get new token from login",
                    "4. Check backend auth middleware"
                ]
            } else if errorString.contains("parse") || errorString.contains("JSON") {
                suggestion.problem = "Message parsing failure"
                suggestion.possibleCauses = [
                    "Invalid JSON format",
                    "Missing required fields",
                    "Type mismatch"
                ]
                suggestion.fixes = [
                    "1. Validate JSON structure",
                    "2. Check required fields: type, content/command",
                    "3. Match backend expectations",
                    "4. Use JSONSerialization for encoding"
                ]
            }
        } else {
            // No specific error, general diagnostics
            suggestion.problem = "WebSocket not receiving responses"
            suggestion.possibleCauses = [
                "Message format mismatch",
                "Backend not processing messages",
                "WebSocket not properly connected"
            ]
            suggestion.fixes = [
                "1. Check message format matches backend",
                "2. Monitor backend logs: docker logs claude-backend",
                "3. Test with simple ping message",
                "4. Verify WebSocket state is connected"
            ]
        }
        
        return suggestion
    }
    
    struct FixSuggestion {
        var problem = ""
        var possibleCauses: [String] = []
        var fixes: [String] = []
        
        var formatted: String {
            var output = "\n🔧 FIX SUGGESTIONS\n"
            output += "================\n"
            output += "Problem: \(problem)\n\n"
            output += "Possible Causes:\n"
            for cause in possibleCauses {
                output += "  • \(cause)\n"
            }
            output += "\nSuggested Fixes:\n"
            for fix in fixes {
                output += "  \(fix)\n"
            }
            return output
        }
    }
}

// MARK: - Test Extensions

extension XCTestCase {
    
    /// Run WebSocket diagnostics and print report
    func runWebSocketDiagnostics() {
        let debugUtil = WebSocketDebugUtility()
        let expectation = expectation(description: "Diagnostics complete")
        
        debugUtil.diagnoseConnection { report in
            print(report.summary)
            
            // If not all tests pass, get fix suggestions
            if !report.urlReachable || !report.handshakeSuccess || 
               !report.authenticationSuccess || !report.messageFormatValid || 
               !report.streamingWorks {
                
                let suggestion = debugUtil.analyzeProblemAndSuggestFix(nil)
                print(suggestion.formatted)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30)
    }
}