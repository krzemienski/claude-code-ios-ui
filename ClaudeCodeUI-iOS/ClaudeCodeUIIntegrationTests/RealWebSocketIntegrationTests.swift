//
//  RealWebSocketIntegrationTests.swift
//  ClaudeCodeUIIntegrationTests
//
//  Real WebSocket integration tests connecting to actual backend
//

import XCTest
@testable import ClaudeCodeUI

class RealWebSocketIntegrationTests: XCTestCase {
    
    var webSocketManager: WebSocketManager!
    var mockDelegate: RealWebSocketTestDelegate!
    let realBackendURL = "ws://192.168.0.155:3004/ws"
    let timeout: TimeInterval = 30
    
    override func setUpWithError() throws {
        super.setUp()
        print("\n🚀 ===== STARTING REAL WEBSOCKET TEST =====")
        print("🌐 Backend URL: \(realBackendURL)")
        
        webSocketManager = WebSocketManager()
        mockDelegate = RealWebSocketTestDelegate()
        webSocketManager.delegate = mockDelegate
        
        // Reset any existing connection
        webSocketManager.disconnect()
        Thread.sleep(forTimeInterval: 0.5)
    }
    
    override func tearDownWithError() throws {
        print("\n🔚 ===== ENDING WEBSOCKET TEST =====\n")
        webSocketManager.disconnect()
        webSocketManager = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Real Connection Tests
    
    func testRealBackendConnection() throws {
        print("\n📝 TEST: Real Backend Connection")
        let expectation = XCTestExpectation(description: "WebSocket connects to real backend")
        
        mockDelegate.onConnected = {
            print("✅ WebSocket CONNECTED to real backend!")
            expectation.fulfill()
        }
        
        mockDelegate.onError = { error in
            print("❌ Connection ERROR: \(error.localizedDescription)")
            XCTFail("Failed to connect: \(error)")
        }
        
        mockDelegate.onStateChanged = { state in
            print("🔄 State changed to: \(state)")
        }
        
        print("🔌 Attempting to connect to: \(realBackendURL)")
        webSocketManager.connect(to: realBackendURL)
        
        wait(for: [expectation], timeout: timeout)
        
        XCTAssertTrue(webSocketManager.isConnected, "WebSocket should be connected")
        print("✅ Connection test PASSED")
    }
    
    func testSendRealMessage() throws {
        print("\n📝 TEST: Send Real Message")
        
        // First establish connection
        let connectExpectation = XCTestExpectation(description: "Connect to backend")
        
        mockDelegate.onConnected = {
            print("✅ Connected, ready to send message")
            connectExpectation.fulfill()
        }
        
        print("🔌 Connecting to backend...")
        webSocketManager.connect(to: realBackendURL)
        wait(for: [connectExpectation], timeout: timeout)
        
        // Now send a real message
        let messageExpectation = XCTestExpectation(description: "Send and receive message")
        var receivedResponse = false
        
        mockDelegate.onMessageReceived = { message in
            print("📥 Received message type: \(message.type)")
            print("📥 Payload: \(String(describing: message.payload))")
            
            // Check for any response from backend
            if message.type == .claudeResponse || 
               message.type == .sessionCreated ||
               message.type == .error ||
               message.type == .message {
                receivedResponse = true
                messageExpectation.fulfill()
            }
        }
        
        mockDelegate.onTextReceived = { text in
            print("📥 Raw text received: \(text.prefix(200))...")
            if !receivedResponse {
                receivedResponse = true
                messageExpectation.fulfill()
            }
        }
        
        // Send a simple test message
        print("📤 Sending test message...")
        let testMessage = "Hello from iOS test"
        webSocketManager.sendMessage(
            testMessage,
            projectId: "test-project",
            projectPath: "/test/path",
            messageType: .claudeCommand
        )
        
        wait(for: [messageExpectation], timeout: timeout)
        
        XCTAssertTrue(receivedResponse, "Should have received a response from backend")
        print("✅ Message send test PASSED")
    }
    
    func testStreamingMessageResponse() throws {
        print("\n📝 TEST: Streaming Message Response")
        
        // Connect first
        let connectExpectation = XCTestExpectation(description: "Connect")
        mockDelegate.onConnected = { connectExpectation.fulfill() }
        
        webSocketManager.connect(to: realBackendURL)
        wait(for: [connectExpectation], timeout: timeout)
        
        // Test streaming response
        let streamExpectation = XCTestExpectation(description: "Receive streaming response")
        var streamingMessages: [String] = []
        var sessionId: String?
        
        mockDelegate.onMessageReceived = { message in
            print("📥 Message type: \(message.type)")
            
            if message.type == .sessionCreated {
                sessionId = message.sessionId ?? message.payload?["sessionId"] as? String
                print("📝 Session created: \(sessionId ?? "unknown")")
            }
            
            if message.type == .claudeResponse || message.type == .message {
                if let content = message.payload?["content"] as? String {
                    streamingMessages.append(content)
                    print("📥 Streaming content: \(content.prefix(100))...")
                }
            }
        }
        
        mockDelegate.onTextReceived = { text in
            print("📥 Raw streaming text: \(text.prefix(100))...")
            
            // Parse streaming response
            if let data = text.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                if let type = json["type"] as? String {
                    print("📥 Parsed type: \(type)")
                    
                    if type == "session-created" {
                        sessionId = json["sessionId"] as? String
                        print("📝 Session ID from raw: \(sessionId ?? "unknown")")
                    }
                    
                    if type == "claude-response" || type == "streaming" {
                        if let content = json["content"] as? String {
                            streamingMessages.append(content)
                            
                            // Check for stream end
                            if let isComplete = json["complete"] as? Bool, isComplete {
                                print("✅ Stream complete")
                                streamExpectation.fulfill()
                            }
                        }
                    }
                }
            }
            
            // Simple timeout fallback
            if streamingMessages.count > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if streamExpectation.expectedFulfillmentCount > 0 {
                        streamExpectation.fulfill()
                    }
                }
            }
        }
        
        // Send a message that will generate streaming response
        print("📤 Sending message to trigger streaming...")
        webSocketManager.sendMessage(
            "Tell me about quad code in one sentence",
            projectId: "test-project",
            projectPath: "/test/path",
            messageType: .claudeCommand
        )
        
        wait(for: [streamExpectation], timeout: timeout)
        
        XCTAssertTrue(streamingMessages.count > 0, "Should have received streaming messages")
        print("✅ Received \(streamingMessages.count) streaming messages")
        print("✅ Streaming test PASSED")
    }
    
    func testConnectionStateTransitions() throws {
        print("\n📝 TEST: Connection State Transitions")
        
        var stateHistory: [WebSocketConnectionState] = []
        
        mockDelegate.onStateChanged = { state in
            stateHistory.append(state)
            print("🔄 State transition: \(state)")
        }
        
        // Connect
        let connectExpectation = XCTestExpectation(description: "Connect")
        mockDelegate.onConnected = { connectExpectation.fulfill() }
        
        webSocketManager.connect(to: realBackendURL)
        wait(for: [connectExpectation], timeout: timeout)
        
        // Verify state transitions
        XCTAssertTrue(stateHistory.contains(.connecting), "Should have connecting state")
        XCTAssertTrue(stateHistory.contains(.connected), "Should have connected state")
        XCTAssertEqual(webSocketManager.connectionState, .connected, "Final state should be connected")
        
        // Disconnect
        webSocketManager.disconnect()
        Thread.sleep(forTimeInterval: 0.5)
        
        XCTAssertEqual(webSocketManager.connectionState, .disconnected, "Should be disconnected")
        print("✅ State transition test PASSED")
    }
    
    func testMultipleMessagesInSequence() throws {
        print("\n📝 TEST: Multiple Messages in Sequence")
        
        // Connect
        let connectExpectation = XCTestExpectation(description: "Connect")
        mockDelegate.onConnected = { connectExpectation.fulfill() }
        
        webSocketManager.connect(to: realBackendURL)
        wait(for: [connectExpectation], timeout: timeout)
        
        // Send multiple messages
        let messages = [
            "First test message",
            "Second test message",
            "Third test message"
        ]
        
        let messageExpectation = XCTestExpectation(description: "Receive responses")
        messageExpectation.expectedFulfillmentCount = messages.count
        
        var responseCount = 0
        mockDelegate.onTextReceived = { text in
            print("📥 Response \(responseCount + 1): \(text.prefix(100))...")
            responseCount += 1
            messageExpectation.fulfill()
        }
        
        // Send messages with small delay
        for (index, message) in messages.enumerated() {
            print("📤 Sending message \(index + 1): \(message)")
            webSocketManager.sendMessage(
                message,
                projectId: "test-project-\(index)",
                projectPath: "/test/path",
                messageType: .claudeCommand
            )
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        wait(for: [messageExpectation], timeout: timeout)
        
        XCTAssertEqual(responseCount, messages.count, "Should receive response for each message")
        print("✅ Multiple messages test PASSED")
    }
    
    func testReconnectionAfterDisconnect() throws {
        print("\n📝 TEST: Reconnection After Disconnect")
        
        // Initial connection
        let connectExpectation = XCTestExpectation(description: "Initial connection")
        mockDelegate.onConnected = { connectExpectation.fulfill() }
        
        webSocketManager.connect(to: realBackendURL)
        wait(for: [connectExpectation], timeout: timeout)
        
        print("✅ Initial connection established")
        
        // Disconnect
        webSocketManager.disconnect()
        Thread.sleep(forTimeInterval: 1)
        
        XCTAssertFalse(webSocketManager.isConnected, "Should be disconnected")
        print("✅ Disconnected successfully")
        
        // Reconnect
        let reconnectExpectation = XCTestExpectation(description: "Reconnection")
        mockDelegate.onConnected = { reconnectExpectation.fulfill() }
        
        print("🔌 Attempting reconnection...")
        webSocketManager.connect(to: realBackendURL)
        wait(for: [reconnectExpectation], timeout: timeout)
        
        XCTAssertTrue(webSocketManager.isConnected, "Should be reconnected")
        print("✅ Reconnection test PASSED")
    }
    
    func testMessageLatencyMeasurement() throws {
        print("\n📝 TEST: Message Latency Measurement")
        
        // Connect
        let connectExpectation = XCTestExpectation(description: "Connect")
        mockDelegate.onConnected = { connectExpectation.fulfill() }
        
        webSocketManager.connect(to: realBackendURL)
        wait(for: [connectExpectation], timeout: timeout)
        
        // Measure latency
        let latencyExpectation = XCTestExpectation(description: "Measure latency")
        var sendTime: Date?
        var receiveTime: Date?
        
        mockDelegate.onTextReceived = { _ in
            receiveTime = Date()
            latencyExpectation.fulfill()
        }
        
        print("📤 Sending ping message...")
        sendTime = Date()
        webSocketManager.sendMessage(
            "ping",
            projectId: "latency-test",
            projectPath: "/test",
            messageType: .claudeCommand
        )
        
        wait(for: [latencyExpectation], timeout: timeout)
        
        if let send = sendTime, let receive = receiveTime {
            let latency = receive.timeIntervalSince(send) * 1000 // Convert to milliseconds
            print("📊 Message latency: \(String(format: "%.2f", latency))ms")
            
            // Assert reasonable latency (under 5 seconds for local network)
            XCTAssertLessThan(latency, 5000, "Latency should be under 5 seconds")
            print("✅ Latency test PASSED")
        } else {
            XCTFail("Failed to measure latency")
        }
    }
}

// MARK: - Real WebSocket Test Delegate

class RealWebSocketTestDelegate: WebSocketManagerDelegate {
    
    var onConnected: (() -> Void)?
    var onDisconnected: ((Error?) -> Void)?
    var onMessageReceived: ((WebSocketMessage) -> Void)?
    var onTextReceived: ((String) -> Void)?
    var onDataReceived: ((Data) -> Void)?
    var onStateChanged: ((WebSocketConnectionState) -> Void)?
    var onError: ((Error) -> Void)?
    
    func webSocketDidConnect(_ manager: any WebSocketProtocol) {
        print("🎉 [Delegate] WebSocket CONNECTED!")
        onConnected?()
    }
    
    func webSocketDidDisconnect(_ manager: any WebSocketProtocol, error: Error?) {
        if let error = error {
            print("⚠️ [Delegate] WebSocket disconnected with error: \(error)")
            onError?(error)
        } else {
            print("ℹ️ [Delegate] WebSocket disconnected cleanly")
        }
        onDisconnected?(error)
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveMessage message: WebSocketMessage) {
        print("📨 [Delegate] Received WebSocketMessage:")
        print("  - Type: \(message.type)")
        print("  - SessionID: \(message.sessionId ?? "none")")
        print("  - Payload keys: \(message.payload?.keys.joined(separator: ", ") ?? "none")")
        onMessageReceived?(message)
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveText text: String) {
        print("📝 [Delegate] Received raw text: \(text.prefix(200))...")
        onTextReceived?(text)
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveData data: Data) {
        print("📦 [Delegate] Received data: \(data.count) bytes")
        onDataReceived?(data)
    }
    
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState) {
        print("🔄 [Delegate] Connection state changed: \(state)")
        onStateChanged?(state)
    }
}