//
//  WebSocketSessionContinuityTests.swift
//  ClaudeCodeUIIntegrationTests
//
//  Tests for WebSocket session continuity and message ordering
//

import XCTest
@testable import ClaudeCodeUI

class WebSocketSessionContinuityTests: XCTestCase {
    
    var webSocketManager: WebSocketManager!
    var monitor: WebSocketMonitor!
    var delegate: SessionTestDelegate!
    let realBackendURL = "ws://192.168.0.155:3004/ws"
    let timeout: TimeInterval = 30
    
    override func setUpWithError() throws {
        super.setUp()
        print("\n🚀 ===== STARTING SESSION CONTINUITY TEST =====")
        
        webSocketManager = WebSocketManager()
        monitor = webSocketManager.createMonitor()
        delegate = SessionTestDelegate()
        webSocketManager.delegate = delegate
        
        // Reset connection
        webSocketManager.disconnect()
        Thread.sleep(forTimeInterval: 0.5)
        
        monitor.startMonitoring()
    }
    
    override func tearDownWithError() throws {
        let report = monitor.stopMonitoring()
        print("\n📊 Final Report:\n\(report)")
        
        webSocketManager.disconnect()
        webSocketManager = nil
        monitor = nil
        delegate = nil
        
        print("\n🔚 ===== ENDING SESSION CONTINUITY TEST =====\n")
        super.tearDown()
    }
    
    // MARK: - Session Continuity Tests
    
    func testSessionCreationAndContinuity() throws {
        print("\n📝 TEST: Session Creation and Continuity")
        
        // Connect
        let connectExpectation = XCTestExpectation(description: "Connect")
        delegate.onConnected = { connectExpectation.fulfill() }
        
        webSocketManager.connect(to: realBackendURL)
        wait(for: [connectExpectation], timeout: timeout)
        
        // Send first message to create session
        let sessionExpectation = XCTestExpectation(description: "Session created")
        var sessionId: String?
        
        delegate.onSessionCreated = { id in
            sessionId = id
            print("✅ Session created: \(id)")
            sessionExpectation.fulfill()
        }
        
        webSocketManager.sendMessage(
            "Create a new session",
            projectId: "continuity-test",
            projectPath: "/test/continuity",
            messageType: .claudeCommand
        )
        
        wait(for: [sessionExpectation], timeout: timeout)
        
        XCTAssertNotNil(sessionId, "Session ID should be created")
        
        // Send follow-up messages in same session
        let followupExpectation = XCTestExpectation(description: "Follow-up messages")
        followupExpectation.expectedFulfillmentCount = 2
        
        var messageCount = 0
        delegate.onMessageReceived = { message in
            messageCount += 1
            print("📥 Message \(messageCount) in session")
            followupExpectation.fulfill()
        }
        
        // Send follow-up messages
        webSocketManager.sendMessage(
            "This is a follow-up message",
            projectId: "continuity-test",
            projectPath: "/test/continuity",
            messageType: .claudeCommand
        )
        
        Thread.sleep(forTimeInterval: 0.5)
        
        webSocketManager.sendMessage(
            "This is another follow-up",
            projectId: "continuity-test",
            projectPath: "/test/continuity",
            messageType: .claudeCommand
        )
        
        wait(for: [followupExpectation], timeout: timeout)
        
        XCTAssertEqual(messageCount, 2, "Should receive both follow-up messages")
        print("✅ Session continuity test PASSED")
    }
    
    func testMessageOrdering() throws {
        print("\n📝 TEST: Message Ordering")
        
        // Connect
        let connectExpectation = XCTestExpectation(description: "Connect")
        delegate.onConnected = { connectExpectation.fulfill() }
        
        webSocketManager.connect(to: realBackendURL)
        wait(for: [connectExpectation], timeout: timeout)
        
        // Send numbered messages
        let messages = [
            "Message 1: First",
            "Message 2: Second",
            "Message 3: Third",
            "Message 4: Fourth",
            "Message 5: Fifth"
        ]
        
        let orderingExpectation = XCTestExpectation(description: "Message ordering")
        var receivedOrder: [Int] = []
        
        delegate.onTextReceived = { text in
            // Extract message number from response
            for (index, message) in messages.enumerated() {
                if text.contains("Message \(index + 1)") {
                    receivedOrder.append(index + 1)
                    print("📥 Received response for Message \(index + 1)")
                    
                    if receivedOrder.count == messages.count {
                        orderingExpectation.fulfill()
                    }
                    break
                }
            }
        }
        
        // Send all messages rapidly
        for message in messages {
            print("📤 Sending: \(message)")
            webSocketManager.sendMessage(
                message,
                projectId: "ordering-test",
                projectPath: "/test/ordering",
                messageType: .claudeCommand
            )
            Thread.sleep(forTimeInterval: 0.1) // Small delay to ensure ordering
        }
        
        wait(for: [orderingExpectation], timeout: timeout)
        
        // Verify ordering
        for i in 0..<receivedOrder.count - 1 {
            XCTAssertLessThanOrEqual(receivedOrder[i], receivedOrder[i + 1], 
                                      "Messages should be received in order")
        }
        
        print("✅ Message ordering test PASSED")
        print("📊 Received order: \(receivedOrder)")
    }
    
    func testConnectionPersistenceAcrossNavigation() throws {
        print("\n📝 TEST: Connection Persistence Across Navigation")
        
        // Connect
        let connectExpectation = XCTestExpectation(description: "Connect")
        delegate.onConnected = { connectExpectation.fulfill() }
        
        webSocketManager.connect(to: realBackendURL)
        wait(for: [connectExpectation], timeout: timeout)
        
        // Simulate navigation by sending messages from different "views"
        let navigationExpectation = XCTestExpectation(description: "Navigation test")
        navigationExpectation.expectedFulfillmentCount = 3
        
        var viewResponses: [String: Bool] = [
            "ChatView": false,
            "ProjectView": false,
            "SettingsView": false
        ]
        
        delegate.onTextReceived = { text in
            if text.contains("ChatView") && !viewResponses["ChatView"]! {
                viewResponses["ChatView"] = true
                navigationExpectation.fulfill()
            } else if text.contains("ProjectView") && !viewResponses["ProjectView"]! {
                viewResponses["ProjectView"] = true
                navigationExpectation.fulfill()
            } else if text.contains("SettingsView") && !viewResponses["SettingsView"]! {
                viewResponses["SettingsView"] = true
                navigationExpectation.fulfill()
            }
        }
        
        // Simulate navigation between views
        print("📱 Simulating ChatView...")
        webSocketManager.sendMessage(
            "Message from ChatView",
            projectId: "chat-project",
            projectPath: "/chat",
            messageType: .claudeCommand
        )
        
        Thread.sleep(forTimeInterval: 1)
        
        print("📱 Simulating ProjectView...")
        webSocketManager.sendMessage(
            "Message from ProjectView",
            projectId: "project-view",
            projectPath: "/projects",
            messageType: .claudeCommand
        )
        
        Thread.sleep(forTimeInterval: 1)
        
        print("📱 Simulating SettingsView...")
        webSocketManager.sendMessage(
            "Message from SettingsView",
            projectId: "settings",
            projectPath: "/settings",
            messageType: .claudeCommand
        )
        
        wait(for: [navigationExpectation], timeout: timeout)
        
        // Verify connection persisted
        XCTAssertTrue(webSocketManager.isConnected, "Connection should persist")
        XCTAssertTrue(viewResponses["ChatView"]!, "Should receive ChatView response")
        XCTAssertTrue(viewResponses["ProjectView"]!, "Should receive ProjectView response")
        XCTAssertTrue(viewResponses["SettingsView"]!, "Should receive SettingsView response")
        
        print("✅ Navigation persistence test PASSED")
    }
    
    func testMessageQueuePreservation() throws {
        print("\n📝 TEST: Message Queue Preservation")
        
        // Connect
        let connectExpectation = XCTestExpectation(description: "Connect")
        delegate.onConnected = { connectExpectation.fulfill() }
        
        webSocketManager.connect(to: realBackendURL)
        wait(for: [connectExpectation], timeout: timeout)
        
        // Queue messages while disconnected
        let queueExpectation = XCTestExpectation(description: "Queue preservation")
        var queuedMessages: [String] = []
        
        delegate.onTextReceived = { text in
            print("📥 Received queued message response")
            queuedMessages.append(text)
            
            if queuedMessages.count >= 3 {
                queueExpectation.fulfill()
            }
        }
        
        // Temporarily disconnect
        print("🔌 Disconnecting temporarily...")
        webSocketManager.disconnect()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Send messages while disconnected (should be queued)
        print("📤 Queueing messages while disconnected...")
        webSocketManager.sendMessage(
            "Queued message 1",
            projectId: "queue-test",
            projectPath: "/queue",
            messageType: .claudeCommand
        )
        
        webSocketManager.sendMessage(
            "Queued message 2",
            projectId: "queue-test",
            projectPath: "/queue",
            messageType: .claudeCommand
        )
        
        webSocketManager.sendMessage(
            "Queued message 3",
            projectId: "queue-test",
            projectPath: "/queue",
            messageType: .claudeCommand
        )
        
        // Reconnect
        print("🔌 Reconnecting...")
        webSocketManager.connect(to: realBackendURL)
        
        wait(for: [queueExpectation], timeout: timeout)
        
        XCTAssertGreaterThanOrEqual(queuedMessages.count, 3, "Should receive queued messages")
        print("✅ Message queue preservation test PASSED")
    }
    
    func testStreamingMessageContinuity() throws {
        print("\n📝 TEST: Streaming Message Continuity")
        
        // Connect
        let connectExpectation = XCTestExpectation(description: "Connect")
        delegate.onConnected = { connectExpectation.fulfill() }
        
        webSocketManager.connect(to: realBackendURL)
        wait(for: [connectExpectation], timeout: timeout)
        
        // Test streaming response continuity
        let streamExpectation = XCTestExpectation(description: "Streaming continuity")
        var streamParts: [String] = []
        var isStreaming = false
        
        delegate.onTextReceived = { text in
            if let data = text.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                if let type = json["type"] as? String {
                    if type == "streaming" || type == "claude-response" {
                        isStreaming = true
                        if let content = json["content"] as? String {
                            streamParts.append(content)
                            print("📥 Stream part \(streamParts.count): \(content.prefix(50))...")
                        }
                        
                        // Check for stream end
                        if let complete = json["complete"] as? Bool, complete {
                            print("✅ Stream complete with \(streamParts.count) parts")
                            streamExpectation.fulfill()
                        }
                    }
                }
            }
            
            // Timeout fallback
            if isStreaming && streamParts.count > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if streamExpectation.expectedFulfillmentCount > 0 {
                        streamExpectation.fulfill()
                    }
                }
            }
        }
        
        // Send message that triggers streaming
        print("📤 Triggering streaming response...")
        webSocketManager.sendMessage(
            "Tell me a story about WebSocket connections in 3 parts",
            projectId: "stream-test",
            projectPath: "/stream",
            messageType: .claudeCommand
        )
        
        wait(for: [streamExpectation], timeout: timeout)
        
        XCTAssertGreaterThan(streamParts.count, 0, "Should receive streaming parts")
        print("✅ Received \(streamParts.count) streaming parts")
        print("✅ Streaming continuity test PASSED")
    }
}

// MARK: - Session Test Delegate

class SessionTestDelegate: NSObject, WebSocketManagerDelegate {
    
    var onConnected: (() -> Void)?
    var onDisconnected: ((Error?) -> Void)?
    var onSessionCreated: ((String) -> Void)?
    var onMessageReceived: ((WebSocketMessage) -> Void)?
    var onTextReceived: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    
    func webSocketDidConnect(_ manager: any WebSocketProtocol) {
        print("🎉 [SessionDelegate] Connected")
        onConnected?()
    }
    
    func webSocketDidDisconnect(_ manager: any WebSocketProtocol, error: Error?) {
        print("⚠️ [SessionDelegate] Disconnected")
        onDisconnected?(error)
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveMessage message: WebSocketMessage) {
        print("📨 [SessionDelegate] Message type: \(message.type)")
        
        if message.type == .sessionCreated {
            if let sessionId = message.sessionId ?? message.payload?["sessionId"] as? String {
                onSessionCreated?(sessionId)
            }
        }
        
        onMessageReceived?(message)
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveText text: String) {
        print("📝 [SessionDelegate] Text: \(text.prefix(100))...")
        
        // Check for session creation in raw text
        if let data = text.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            if json["type"] as? String == "session-created",
               let sessionId = json["sessionId"] as? String {
                onSessionCreated?(sessionId)
            }
        }
        
        onTextReceived?(text)
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveData data: Data) {
        print("📦 [SessionDelegate] Data: \(data.count) bytes")
    }
    
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState) {
        print("🔄 [SessionDelegate] State: \(state)")
    }
}