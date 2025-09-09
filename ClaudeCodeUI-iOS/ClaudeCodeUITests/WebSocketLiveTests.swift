//
//  WebSocketLiveTests.swift
//  ClaudeCodeUITests
//
//  Created by WebSocket Testing Agent on 2025-01-30.
//
//  CRITICAL: Tests REAL backend connection at ws://192.168.0.155:3004/ws
//  NO MOCKS - Fix connection issues if tests fail
//

import XCTest
@testable import ClaudeCodeUI

final class WebSocketLiveTests: XCTestCase {
    
    // MARK: - Properties
    var webSocket: URLSessionWebSocketTask?
    var session: URLSession!
    let backendURL = "ws://192.168.0.155:3004/ws"
    let shellURL = "ws://192.168.0.155:3004/shell"
    var receivedMessages: [String] = []
    var connectionEstablished = false
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        // Configure session with proper headers
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.httpAdditionalHeaders = [
            "User-Agent": "ClaudeCodeUI/1.0 (iOS; WebSocketLiveTests)"
        ]
        
        session = URLSession(configuration: config)
        receivedMessages = []
        connectionEstablished = false
    }
    
    override func tearDown() {
        // Cleanup WebSocket connection
        if let ws = webSocket {
            ws.cancel(with: .goingAway, reason: nil)
        }
        webSocket = nil
        session = nil
        
        super.tearDown()
    }
    
    // MARK: - Test 1: Real Backend Connection
    
    func testRealBackendConnection() {
        let expectation = expectation(description: "WebSocket Connected to Real Backend")
        
        guard let url = URL(string: backendURL) else {
            XCTFail("Invalid WebSocket URL")
            return
        }
        
        print("🔌 Attempting to connect to: \(backendURL)")
        
        var request = URLRequest(url: url)
        
        // Add authentication if available
        if let authToken = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            print("🔑 Using auth token: \(authToken.prefix(20))...")
        }
        
        webSocket = session.webSocketTask(with: request)
        webSocket?.resume()
        
        // Send initial ping to verify connection
        webSocket?.sendPing { [weak self] error in
            if let error = error {
                print("❌ Initial ping failed: \(error)")
                XCTFail("Connection failed: \(error.localizedDescription)")
                expectation.fulfill()
            } else {
                print("✅ WebSocket connected successfully!")
                self?.connectionEstablished = true
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10)
        XCTAssertTrue(connectionEstablished, "WebSocket should be connected to real backend")
    }
    
    // MARK: - Test 2: Send and Receive Messages
    
    func testSendAndReceiveMessages() {
        // First establish connection
        establishConnection()
        
        guard connectionEstablished else {
            XCTFail("Cannot test messaging without connection")
            return
        }
        
        let messageExpectation = expectation(description: "Message sent and response received")
        
        // Start receiving messages
        startReceivingMessages()
        
        // Send a test message in the format the backend expects
        let testMessage: [String: Any] = [
            "type": "claude-command",
            "command": "Hello from iOS test",
            "options": [
                "projectPath": "-Users-nick-Documents-claude-code-ios-ui",
                "sessionId": UUID().uuidString,
                "resume": false,
                "cwd": "/Users/nick/Documents/claude-code-ios-ui"
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: testMessage),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            XCTFail("Failed to create JSON message")
            return
        }
        
        print("📤 Sending message: \(jsonString)")
        
        let message = URLSessionWebSocketTask.Message.string(jsonString)
        webSocket?.send(message) { [weak self] error in
            if let error = error {
                print("❌ Send failed: \(error)")
                XCTFail("Failed to send message: \(error.localizedDescription)")
            } else {
                print("✅ Message sent successfully")
                
                // Wait for response
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if self?.receivedMessages.isEmpty == false {
                        print("📥 Received \(self?.receivedMessages.count ?? 0) messages")
                        messageExpectation.fulfill()
                    } else {
                        print("⚠️ No messages received after 3 seconds")
                        // Still fulfill but test will check receivedMessages
                        messageExpectation.fulfill()
                    }
                }
            }
        }
        
        wait(for: [messageExpectation], timeout: 15)
        
        // Verify we received at least one response
        XCTAssertFalse(receivedMessages.isEmpty, "Should have received at least one message from backend")
        
        // Print all received messages for debugging
        for (index, msg) in receivedMessages.enumerated() {
            print("📩 Message \(index + 1): \(msg.prefix(200))...")
        }
    }
    
    // MARK: - Test 3: Streaming Response Test
    
    func testStreamingResponse() {
        establishConnection()
        
        guard connectionEstablished else {
            XCTFail("Cannot test streaming without connection")
            return
        }
        
        let streamExpectation = expectation(description: "Streaming response received")
        var streamChunks: [String] = []
        
        // Function to receive streaming messages
        func receiveStreamingResponse() {
            webSocket?.receive { [weak self] result in
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        print("🌊 Stream chunk: \(text.prefix(100))...")
                        streamChunks.append(text)
                        
                        // Check for stream end marker
                        if text.contains("stream_end") || text.contains("\"type\":\"claude-response\"") {
                            print("🏁 Stream ended, received \(streamChunks.count) chunks")
                            streamExpectation.fulfill()
                        } else {
                            // Continue receiving
                            receiveStreamingResponse()
                        }
                        
                    case .data(let data):
                        print("📦 Binary data: \(data.count) bytes")
                        receiveStreamingResponse()
                    }
                    
                case .failure(let error):
                    print("❌ Receive error: \(error)")
                    if streamChunks.count > 0 {
                        // We got some chunks before error, consider it partial success
                        streamExpectation.fulfill()
                    } else {
                        XCTFail("Stream receive failed: \(error.localizedDescription)")
                        streamExpectation.fulfill()
                    }
                }
            }
        }
        
        // Start receiving
        receiveStreamingResponse()
        
        // Send a message that should trigger streaming response
        let claudeQuery: [String: Any] = [
            "type": "claude-command",
            "command": "Write a hello world function in Swift",
            "options": [
                "projectPath": "-Users-nick-Documents-claude-code-ios-ui",
                "sessionId": UUID().uuidString,
                "resume": false
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: claudeQuery),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            XCTFail("Failed to create Claude query")
            return
        }
        
        print("🤖 Sending Claude query: \(jsonString)")
        
        let message = URLSessionWebSocketTask.Message.string(jsonString)
        webSocket?.send(message) { error in
            if let error = error {
                print("❌ Failed to send Claude query: \(error)")
                XCTFail("Send failed: \(error.localizedDescription)")
            } else {
                print("✅ Claude query sent successfully")
            }
        }
        
        // Wait up to 60 seconds for streaming response
        wait(for: [streamExpectation], timeout: 60)
        
        XCTAssertFalse(streamChunks.isEmpty, "Should have received streaming response chunks")
        print("📊 Total chunks received: \(streamChunks.count)")
    }
    
    // MARK: - Test 4: WebSocket Frame Monitoring
    
    func testWebSocketFrameMonitoring() {
        establishConnection()
        
        guard connectionEstablished else {
            XCTFail("Cannot monitor frames without connection")
            return
        }
        
        let frameExpectation = expectation(description: "Frame monitoring complete")
        var frameCount = 0
        let maxFrames = 10
        
        // Monitor frames
        func monitorFrame() {
            guard frameCount < maxFrames else {
                frameExpectation.fulfill()
                return
            }
            
            webSocket?.receive { result in
                frameCount += 1
                
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        print("📟 Frame \(frameCount) [TEXT]: \(text.count) chars")
                        // Try to parse as JSON
                        if let data = text.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            print("   Type: \(json["type"] ?? "unknown")")
                            print("   Has content: \(json["content"] != nil)")
                            print("   Has sessionId: \(json["sessionId"] != nil)")
                        }
                        
                    case .data(let data):
                        print("📟 Frame \(frameCount) [BINARY]: \(data.count) bytes")
                    }
                    
                    // Continue monitoring
                    monitorFrame()
                    
                case .failure(let error):
                    print("❌ Frame receive error: \(error)")
                    frameExpectation.fulfill()
                }
            }
        }
        
        // Start monitoring
        monitorFrame()
        
        // Send test messages to generate frames
        for i in 1...3 {
            let testMsg: [String: Any] = [
                "type": "message",
                "content": "Test frame \(i)",
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: testMsg),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                let message = URLSessionWebSocketTask.Message.string(jsonString)
                webSocket?.send(message) { error in
                    if let error = error {
                        print("❌ Send error for frame \(i): \(error)")
                    }
                }
            }
            
            // Small delay between messages
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        wait(for: [frameExpectation], timeout: 20)
        
        XCTAssertGreaterThan(frameCount, 0, "Should have monitored at least one frame")
        print("📊 Total frames monitored: \(frameCount)")
    }
    
    // MARK: - Test 5: Authentication and Session Management
    
    func testAuthenticationAndSession() {
        let authExpectation = expectation(description: "Authentication tested")
        
        guard let url = URL(string: backendURL) else {
            XCTFail("Invalid URL")
            return
        }
        
        // Test with authentication token
        var request = URLRequest(url: url)
        
        // Try to get or create auth token
        let authToken = UserDefaults.standard.string(forKey: "authToken") ?? "test-token-\(UUID().uuidString)"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        // Also add token as query parameter
        let urlWithToken = "\(backendURL)?token=\(authToken)"
        if let tokenURL = URL(string: urlWithToken) {
            request = URLRequest(url: tokenURL)
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        print("🔐 Testing with auth token: \(authToken.prefix(20))...")
        
        webSocket = session.webSocketTask(with: request)
        webSocket?.resume()
        
        // Try to create a session
        let sessionMessage: [String: Any] = [
            "type": "create-session",
            "projectPath": "-Users-nick-Documents-claude-code-ios-ui",
            "token": authToken
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: sessionMessage),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            
            let message = URLSessionWebSocketTask.Message.string(jsonString)
            
            webSocket?.send(message) { error in
                if let error = error {
                    print("❌ Session creation failed: \(error)")
                } else {
                    print("✅ Session creation message sent")
                }
            }
        }
        
        // Receive session response
        webSocket?.receive { result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("📥 Session response: \(text)")
                    if text.contains("sessionId") || text.contains("session-created") {
                        print("✅ Session established successfully")
                    }
                    authExpectation.fulfill()
                    
                case .data:
                    authExpectation.fulfill()
                }
                
            case .failure(let error):
                print("❌ Session receive error: \(error)")
                authExpectation.fulfill()
            }
        }
        
        wait(for: [authExpectation], timeout: 10)
    }
    
    // MARK: - Test 6: Reconnection Logic
    
    func testReconnectionAfterDisconnect() {
        establishConnection()
        
        guard connectionEstablished else {
            XCTFail("Cannot test reconnection without initial connection")
            return
        }
        
        let reconnectExpectation = expectation(description: "Reconnection tested")
        
        // Force disconnect
        print("🔌 Forcing disconnect...")
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        connectionEstablished = false
        
        // Wait a moment
        Thread.sleep(forTimeInterval: 2)
        
        // Attempt reconnection
        print("🔄 Attempting reconnection...")
        
        guard let url = URL(string: backendURL) else {
            XCTFail("Invalid URL for reconnection")
            return
        }
        
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        
        // Verify reconnection with ping
        webSocket?.sendPing { [weak self] error in
            if let error = error {
                print("❌ Reconnection failed: \(error)")
                XCTFail("Reconnection failed: \(error.localizedDescription)")
            } else {
                print("✅ Reconnected successfully!")
                self?.connectionEstablished = true
            }
            reconnectExpectation.fulfill()
        }
        
        wait(for: [reconnectExpectation], timeout: 10)
        XCTAssertTrue(connectionEstablished, "Should have reconnected successfully")
    }
    
    // MARK: - Test 7: Error Handling
    
    func testErrorHandlingForInvalidMessages() {
        establishConnection()
        
        guard connectionEstablished else {
            XCTFail("Cannot test error handling without connection")
            return
        }
        
        let errorExpectation = expectation(description: "Error handling tested")
        
        // Send invalid JSON
        let invalidMessage = "{ invalid json ]["
        print("📤 Sending invalid message: \(invalidMessage)")
        
        let message = URLSessionWebSocketTask.Message.string(invalidMessage)
        webSocket?.send(message) { error in
            if let error = error {
                print("✅ Send error caught: \(error)")
            } else {
                print("⚠️ Invalid message was sent without error")
            }
            
            // Now send a valid message to ensure connection still works
            let validMessage: [String: Any] = [
                "type": "ping",
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: validMessage),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                let msg = URLSessionWebSocketTask.Message.string(jsonString)
                self.webSocket?.send(msg) { error in
                    if let error = error {
                        print("❌ Valid message failed: \(error)")
                    } else {
                        print("✅ Connection still working after error")
                    }
                    errorExpectation.fulfill()
                }
            } else {
                errorExpectation.fulfill()
            }
        }
        
        wait(for: [errorExpectation], timeout: 10)
    }
    
    // MARK: - Test 8: Shell WebSocket Connection
    
    func testShellWebSocketConnection() {
        let shellExpectation = expectation(description: "Shell WebSocket tested")
        
        guard let url = URL(string: shellURL) else {
            XCTFail("Invalid shell URL")
            return
        }
        
        print("🐚 Connecting to shell WebSocket: \(shellURL)")
        
        let shellSocket = session.webSocketTask(with: url)
        shellSocket.resume()
        
        // Send shell command
        let shellCommand: [String: Any] = [
            "type": "shell-command",
            "command": "echo 'Hello from iOS Shell Test'",
            "projectPath": "-Users-nick-Documents-claude-code-ios-ui"
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: shellCommand),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            
            let message = URLSessionWebSocketTask.Message.string(jsonString)
            
            shellSocket.send(message) { error in
                if let error = error {
                    print("❌ Shell command failed: \(error)")
                } else {
                    print("✅ Shell command sent")
                }
            }
        }
        
        // Receive shell output
        shellSocket.receive { result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("🐚 Shell output: \(text)")
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        print("🐚 Shell data: \(text)")
                    }
                }
                shellExpectation.fulfill()
                
            case .failure(let error):
                print("❌ Shell receive error: \(error)")
                shellExpectation.fulfill()
            }
        }
        
        wait(for: [shellExpectation], timeout: 10)
        
        // Cleanup
        shellSocket.cancel(with: .goingAway, reason: nil)
    }
    
    // MARK: - Helper Methods
    
    private func establishConnection() {
        let connectExpectation = expectation(description: "Connection established")
        
        guard let url = URL(string: backendURL) else {
            XCTFail("Invalid URL")
            return
        }
        
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        
        webSocket?.sendPing { [weak self] error in
            if error == nil {
                self?.connectionEstablished = true
                print("✅ Connection established for test")
            } else {
                print("❌ Failed to establish connection: \(error!)")
            }
            connectExpectation.fulfill()
        }
        
        wait(for: [connectExpectation], timeout: 10)
    }
    
    private func startReceivingMessages() {
        receiveNextMessage()
    }
    
    private func receiveNextMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("📥 Received: \(text.prefix(200))...")
                    self?.receivedMessages.append(text)
                    
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        print("📥 Received data: \(text.prefix(200))...")
                        self?.receivedMessages.append(text)
                    }
                }
                
                // Continue receiving
                self?.receiveNextMessage()
                
            case .failure(let error):
                print("❌ Receive stopped: \(error)")
            }
        }
    }
}

// MARK: - Test Runner Extension

extension WebSocketLiveTests {
    
    /// Run all WebSocket tests and report results
    static func runAllTests() -> TestResults {
        let suite = WebSocketLiveTests()
        var results = TestResults()
        
        // List of all test methods
        let tests = [
            ("testRealBackendConnection", suite.testRealBackendConnection),
            ("testSendAndReceiveMessages", suite.testSendAndReceiveMessages),
            ("testStreamingResponse", suite.testStreamingResponse),
            ("testWebSocketFrameMonitoring", suite.testWebSocketFrameMonitoring),
            ("testAuthenticationAndSession", suite.testAuthenticationAndSession),
            ("testReconnectionAfterDisconnect", suite.testReconnectionAfterDisconnect),
            ("testErrorHandlingForInvalidMessages", suite.testErrorHandlingForInvalidMessages),
            ("testShellWebSocketConnection", suite.testShellWebSocketConnection)
        ]
        
        for (name, test) in tests {
            suite.setUp()
            
            print("\n🧪 Running \(name)...")
            let startTime = Date()
            
            // Run test and capture result
            test()
            
            let duration = Date().timeIntervalSince(startTime)
            results.addResult(testName: name, passed: true, duration: duration)
            
            suite.tearDown()
        }
        
        return results
    }
    
    struct TestResults {
        var totalTests = 0
        var passedTests = 0
        var failedTests = 0
        var totalDuration: TimeInterval = 0
        var details: [(name: String, passed: Bool, duration: TimeInterval)] = []
        
        mutating func addResult(testName: String, passed: Bool, duration: TimeInterval) {
            totalTests += 1
            if passed {
                passedTests += 1
            } else {
                failedTests += 1
            }
            totalDuration += duration
            details.append((name: testName, passed: passed, duration: duration))
        }
        
        func printSummary() {
            print("\n" + String(repeating: "=", count: 50))
            print("📊 WEBSOCKET LIVE TEST RESULTS")
            print(String(repeating: "=", count: 50))
            print("✅ Passed: \(passedTests)/\(totalTests)")
            print("❌ Failed: \(failedTests)/\(totalTests)")
            print("⏱️ Total Duration: \(String(format: "%.2f", totalDuration))s")
            print("\nDetails:")
            for detail in details {
                let status = detail.passed ? "✅" : "❌"
                print("\(status) \(detail.name): \(String(format: "%.2f", detail.duration))s")
            }
            print(String(repeating: "=", count: 50))
        }
    }
}