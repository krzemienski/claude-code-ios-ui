//
//  WebSocketErrorRecoveryTests.swift
//  ClaudeCodeUIIntegrationTests
//
//  Tests for WebSocket error recovery and automatic reconnection
//

import XCTest
@testable import ClaudeCodeUI

class WebSocketErrorRecoveryTests: XCTestCase {
    
    var webSocketManager: WebSocketManager!
    var monitor: WebSocketMonitor!
    var delegate: ErrorRecoveryDelegate!
    let realBackendURL = "ws://192.168.0.155:3004/ws"
    let invalidURL = "ws://invalid.host.that.does.not.exist:9999/ws"
    let timeout: TimeInterval = 30
    
    override func setUpWithError() throws {
        super.setUp()
        print("\n🚀 ===== STARTING ERROR RECOVERY TEST =====")
        
        webSocketManager = WebSocketManager()
        monitor = webSocketManager.createMonitor()
        delegate = ErrorRecoveryDelegate()
        webSocketManager.delegate = delegate
        
        // Configure for testing
        webSocketManager.configure(
            enableAutoReconnect: true,
            reconnectDelay: 1.0,
            maxReconnectAttempts: 5
        )
        
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
        
        print("\n🔚 ===== ENDING ERROR RECOVERY TEST =====\n")
        super.tearDown()
    }
    
    // MARK: - Error Recovery Tests
    
    func testConnectionToInvalidHost() throws {
        print("\n📝 TEST: Connection to Invalid Host")
        
        let errorExpectation = XCTestExpectation(description: "Connection error")
        var connectionError: Error?
        var stateHistory: [WebSocketConnectionState] = []
        
        delegate.onError = { error in
            connectionError = error
            print("❌ Error received: \(error)")
            errorExpectation.fulfill()
        }
        
        delegate.onStateChanged = { state in
            stateHistory.append(state)
            print("🔄 State: \(state)")
        }
        
        print("🔌 Attempting connection to invalid host...")
        webSocketManager.connect(to: invalidURL)
        
        wait(for: [errorExpectation], timeout: 10)
        
        XCTAssertNotNil(connectionError, "Should receive connection error")
        XCTAssertTrue(stateHistory.contains(.connecting), "Should attempt connection")
        XCTAssertTrue(stateHistory.contains(.failed) || stateHistory.contains(.disconnected), 
                      "Should fail or disconnect")
        
        print("✅ Invalid host test PASSED")
    }
    
    func testAutomaticReconnection() throws {
        print("\n📝 TEST: Automatic Reconnection")
        
        // First establish a good connection
        let connectExpectation = XCTestExpectation(description: "Initial connection")
        delegate.onConnected = { connectExpectation.fulfill() }
        
        webSocketManager.connect(to: realBackendURL)
        wait(for: [connectExpectation], timeout: timeout)
        
        print("✅ Initial connection established")
        
        // Now test auto-reconnection
        let reconnectExpectation = XCTestExpectation(description: "Auto reconnection")
        var disconnectCount = 0
        var reconnectCount = 0
        
        delegate.onDisconnected = { error in
            disconnectCount += 1
            print("⚠️ Disconnected (count: \(disconnectCount))")
        }
        
        delegate.onConnected = {
            reconnectCount += 1
            print("✅ Connected (count: \(reconnectCount))")
            
            if reconnectCount == 2 { // Initial + reconnect
                reconnectExpectation.fulfill()
            }
        }
        
        delegate.onStateChanged = { state in
            if state == .reconnecting {
                print("🔄 Attempting reconnection...")
            }
        }
        
        // Force disconnection to trigger auto-reconnect
        print("🔌 Forcing disconnection...")
        // We need to simulate a network error, not a clean disconnect
        // This requires access to internal WebSocket task
        webSocketManager.simulateNetworkError()
        
        wait(for: [reconnectExpectation], timeout: 15)
        
        XCTAssertEqual(disconnectCount, 1, "Should disconnect once")
        XCTAssertEqual(reconnectCount, 2, "Should reconnect successfully")
        XCTAssertTrue(webSocketManager.isConnected, "Should be connected after reconnection")
        
        print("✅ Auto-reconnection test PASSED")
    }
    
    func testExponentialBackoffReconnection() throws {
        print("\n📝 TEST: Exponential Backoff Reconnection")
        
        var reconnectTimes: [Date] = []
        var attemptCount = 0
        
        delegate.onStateChanged = { state in
            if state == .reconnecting {
                attemptCount += 1
                reconnectTimes.append(Date())
                print("🔄 Reconnect attempt #\(attemptCount) at \(Date())")
            }
        }
        
        // Connect to invalid host to trigger reconnection attempts
        print("🔌 Connecting to invalid host to trigger backoff...")
        webSocketManager.connect(to: invalidURL)
        
        // Wait for multiple reconnection attempts
        Thread.sleep(forTimeInterval: 10)
        
        // Analyze backoff timing
        if reconnectTimes.count >= 3 {
            for i in 1..<reconnectTimes.count {
                let interval = reconnectTimes[i].timeIntervalSince(reconnectTimes[i-1])
                print("📊 Interval \(i): \(String(format: "%.2f", interval)) seconds")
                
                // Verify exponential increase (with some tolerance)
                if i > 1 {
                    let prevInterval = reconnectTimes[i-1].timeIntervalSince(reconnectTimes[i-2])
                    XCTAssertGreaterThan(interval, prevInterval * 1.5, 
                                         "Backoff should increase exponentially")
                }
            }
        }
        
        print("✅ Exponential backoff test PASSED")
    }
    
    func testMessageQueueDuringReconnection() throws {
        print("\n📝 TEST: Message Queue During Reconnection")
        
        // Connect first
        let connectExpectation = XCTestExpectation(description: "Connect")
        delegate.onConnected = { connectExpectation.fulfill() }
        
        webSocketManager.connect(to: realBackendURL)
        wait(for: [connectExpectation], timeout: timeout)
        
        // Setup for queued messages
        let queueExpectation = XCTestExpectation(description: "Queued messages sent")
        queueExpectation.expectedFulfillmentCount = 3
        
        var receivedMessages = 0
        delegate.onTextReceived = { text in
            receivedMessages += 1
            print("📥 Received queued message response #\(receivedMessages)")
            queueExpectation.fulfill()
        }
        
        // Force disconnection
        print("🔌 Forcing disconnection...")
        webSocketManager.simulateNetworkError()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Send messages while reconnecting (should be queued)
        print("📤 Sending messages during reconnection...")
        webSocketManager.sendMessage(
            "Queued during reconnect 1",
            projectId: "queue-test",
            projectPath: "/queue",
            messageType: .claudeCommand
        )
        
        webSocketManager.sendMessage(
            "Queued during reconnect 2",
            projectId: "queue-test",
            projectPath: "/queue",
            messageType: .claudeCommand
        )
        
        webSocketManager.sendMessage(
            "Queued during reconnect 3",
            projectId: "queue-test",
            projectPath: "/queue",
            messageType: .claudeCommand
        )
        
        // Wait for reconnection and message delivery
        wait(for: [queueExpectation], timeout: 20)
        
        XCTAssertEqual(receivedMessages, 3, "All queued messages should be delivered")
        print("✅ Message queue test PASSED")
    }
    
    func testMaxReconnectionAttempts() throws {
        print("\n📝 TEST: Max Reconnection Attempts")
        
        // Configure limited attempts
        webSocketManager.configure(
            enableAutoReconnect: true,
            reconnectDelay: 0.5,
            maxReconnectAttempts: 3
        )
        
        var attemptCount = 0
        var finalState: WebSocketConnectionState?
        
        delegate.onStateChanged = { state in
            print("🔄 State: \(state)")
            
            if state == .reconnecting {
                attemptCount += 1
                print("🔄 Reconnection attempt #\(attemptCount)")
            }
            
            if state == .failed {
                finalState = state
            }
        }
        
        // Connect to invalid host to exhaust attempts
        print("🔌 Connecting to invalid host...")
        webSocketManager.connect(to: invalidURL)
        
        // Wait for all attempts to exhaust
        Thread.sleep(forTimeInterval: 10)
        
        XCTAssertLessThanOrEqual(attemptCount, 3, "Should not exceed max attempts")
        XCTAssertEqual(finalState, .failed, "Should end in failed state")
        
        print("✅ Max attempts test PASSED")
    }
    
    func testRecoveryFromTemporaryNetworkLoss() throws {
        print("\n📝 TEST: Recovery from Temporary Network Loss")
        
        // Connect
        let connectExpectation = XCTestExpectation(description: "Connect")
        delegate.onConnected = { connectExpectation.fulfill() }
        
        webSocketManager.connect(to: realBackendURL)
        wait(for: [connectExpectation], timeout: timeout)
        
        // Send a message and track session
        var sessionId: String?
        delegate.onSessionCreated = { id in
            sessionId = id
            print("📝 Session created: \(id)")
        }
        
        webSocketManager.sendMessage(
            "Initial message before network loss",
            projectId: "recovery-test",
            projectPath: "/recovery",
            messageType: .claudeCommand
        )
        
        Thread.sleep(forTimeInterval: 2)
        
        // Simulate temporary network loss
        print("📡 Simulating network loss...")
        webSocketManager.simulateNetworkError()
        
        // Wait for reconnection
        let recoveryExpectation = XCTestExpectation(description: "Recovery")
        
        delegate.onConnected = {
            print("✅ Recovered from network loss")
            recoveryExpectation.fulfill()
        }
        
        wait(for: [recoveryExpectation], timeout: 10)
        
        // Test that we can still send messages
        let postRecoveryExpectation = XCTestExpectation(description: "Post-recovery message")
        
        delegate.onTextReceived = { text in
            if text.contains("after recovery") {
                postRecoveryExpectation.fulfill()
            }
        }
        
        webSocketManager.sendMessage(
            "Message after recovery",
            projectId: "recovery-test",
            projectPath: "/recovery",
            messageType: .claudeCommand
        )
        
        wait(for: [postRecoveryExpectation], timeout: timeout)
        
        XCTAssertTrue(webSocketManager.isConnected, "Should be connected after recovery")
        print("✅ Network recovery test PASSED")
    }
}

// MARK: - Error Recovery Delegate

class ErrorRecoveryDelegate: NSObject, WebSocketManagerDelegate {
    
    var onConnected: (() -> Void)?
    var onDisconnected: ((Error?) -> Void)?
    var onSessionCreated: ((String) -> Void)?
    var onMessageReceived: ((WebSocketMessage) -> Void)?
    var onTextReceived: ((String) -> Void)?
    var onStateChanged: ((WebSocketConnectionState) -> Void)?
    var onError: ((Error) -> Void)?
    
    func webSocketDidConnect(_ manager: any WebSocketProtocol) {
        print("🎉 [ErrorDelegate] Connected")
        onConnected?()
    }
    
    func webSocketDidDisconnect(_ manager: any WebSocketProtocol, error: Error?) {
        if let error = error {
            print("❌ [ErrorDelegate] Disconnected with error: \(error)")
            onError?(error)
        } else {
            print("ℹ️ [ErrorDelegate] Disconnected cleanly")
        }
        onDisconnected?(error)
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveMessage message: WebSocketMessage) {
        print("📨 [ErrorDelegate] Message type: \(message.type)")
        
        if message.type == .sessionCreated {
            if let sessionId = message.sessionId ?? message.payload?["sessionId"] as? String {
                onSessionCreated?(sessionId)
            }
        }
        
        onMessageReceived?(message)
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveText text: String) {
        print("📝 [ErrorDelegate] Text: \(text.prefix(100))...")
        onTextReceived?(text)
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveData data: Data) {
        print("📦 [ErrorDelegate] Data: \(data.count) bytes")
    }
    
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState) {
        print("🔄 [ErrorDelegate] State changed: \(state)")
        onStateChanged?(state)
    }
}

// MARK: - WebSocketManager Test Extensions

extension WebSocketManager {
    
    /// Simulate a network error for testing
    func simulateNetworkError() {
        // This simulates a network error by forcefully closing the connection
        // without marking it as intentional, which should trigger auto-reconnect
        
        // Access the internal state to force an error condition
        // Note: This is a test-only method
        self.performSelector(onMainThread: NSSelectorFromString("handleError:"),
                            with: NSError(domain: "TestError", code: -1, userInfo: [
                                NSLocalizedDescriptionKey: "Simulated network error"
                            ]),
                            waitUntilDone: false)
    }
}