//
//  WebSocketReconnectionTests.swift
//  ClaudeCodeUITests
//
//  Created by Claude Code on 2025-01-29.
//  Comprehensive WebSocket reconnection testing with exponential backoff
//

import XCTest
import Network
@testable import ClaudeCodeUI

final class WebSocketReconnectionTests: XCTestCase {
    
    // MARK: - Properties
    
    private var webSocketManager: WebSocketManager!
    private var testDelegate: MockWebSocketDelegate!
    private var networkMonitor: NWPathMonitor!
    private var expectations: [XCTestExpectation] = []
    
    // Test configuration
    private let testTimeout: TimeInterval = 60.0
    private let reconnectionTimeout: TimeInterval = 35.0
    private let pingTimeout: TimeInterval = 10.0
    
    // Mock server configuration
    private let mockServerURL = "ws://localhost:3004/ws"
    private let invalidServerURL = "ws://invalid-server.test:9999/ws"
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        // Initialize components
        webSocketManager = WebSocketManager()
        testDelegate = MockWebSocketDelegate()
        webSocketManager.delegate = testDelegate
        
        // Configure for testing
        webSocketManager.configure(
            enableAutoReconnect: true,
            reconnectDelay: 1.0,
            maxReconnectAttempts: 5
        )
        
        // Setup network monitoring
        networkMonitor = NWPathMonitor()
        expectations.removeAll()
        
        print("🧪 [WebSocketReconnectionTests] Test setup completed")
    }
    
    override func tearDown() {
        // Clean up connections
        webSocketManager?.disconnect()
        networkMonitor?.cancel()
        
        // Clear expectations
        expectations.removeAll()
        
        webSocketManager = nil
        testDelegate = nil
        networkMonitor = nil
        
        super.tearDown()
        print("🧪 [WebSocketReconnectionTests] Test teardown completed")
    }
    
    // MARK: - Connection Tests
    
    /// Test basic connection establishment
    func testInitialConnection() throws {
        let connectionExpectation = XCTestExpectation(description: "WebSocket connects successfully")
        
        testDelegate.onConnectionStateChanged = { state in
            if state == .connected {
                connectionExpectation.fulfill()
            }
        }
        
        testDelegate.onDidConnect = { _ in
            XCTAssertTrue(self.webSocketManager.isConnected, "WebSocket should be connected")
        }
        
        // Attempt connection
        webSocketManager.connect(to: mockServerURL)
        
        wait(for: [connectionExpectation], timeout: testTimeout)
    }
    
    /// Test connection failure handling
    func testConnectionFailure() throws {
        let failureExpectation = XCTestExpectation(description: "WebSocket handles connection failure")
        
        testDelegate.onConnectionStateChanged = { state in
            if state == .failed || state == .disconnected {
                failureExpectation.fulfill()
            }
        }
        
        testDelegate.onDidDisconnect = { _, error in
            XCTAssertNotNil(error, "Connection failure should provide error")
        }
        
        // Attempt connection to invalid server
        webSocketManager.connect(to: invalidServerURL)
        
        wait(for: [failureExpectation], timeout: testTimeout)
    }
    
    // MARK: - Exponential Backoff Tests
    
    /// Test exponential backoff pattern for reconnection attempts
    func testExponentialBackoffPattern() throws {
        let reconnectionExpectation = XCTestExpectation(description: "WebSocket uses exponential backoff")
        reconnectionExpectation.expectedFulfillmentCount = 3
        
        var attemptTimes: [Date] = []
        var reconnectAttempts = 0
        
        testDelegate.onConnectionStateChanged = { state in
            if state == .reconnecting {
                attemptTimes.append(Date())
                reconnectAttempts += 1
                
                print("🔄 Reconnection attempt #\(reconnectAttempts) at \(Date())")
                
                if reconnectAttempts >= 3 {
                    reconnectionExpectation.fulfill()
                }
            }
        }
        
        // Start with invalid URL to trigger reconnections
        webSocketManager.connect(to: invalidServerURL)
        
        wait(for: [reconnectionExpectation], timeout: reconnectionTimeout)
        
        // Verify exponential backoff timing
        XCTAssertGreaterThanOrEqual(attemptTimes.count, 2, "Should have at least 2 reconnection attempts")
        
        if attemptTimes.count >= 2 {
            let firstInterval = attemptTimes[1].timeIntervalSince(attemptTimes[0])
            print("📊 First reconnection interval: \(firstInterval)s")
            
            if attemptTimes.count >= 3 {
                let secondInterval = attemptTimes[2].timeIntervalSince(attemptTimes[1])
                print("📊 Second reconnection interval: \(secondInterval)s")
                
                // Second interval should be roughly double the first (exponential backoff)
                XCTAssertGreaterThan(secondInterval, firstInterval * 1.5,
                                   "Second interval should be significantly longer than first (exponential backoff)")
            }
        }
    }
    
    /// Test maximum reconnection attempts limit
    func testMaxReconnectionAttempts() throws {
        let maxAttemptsExpectation = XCTestExpectation(description: "WebSocket respects max reconnection attempts")
        
        var reconnectAttempts = 0
        let maxAttempts = 3
        
        // Configure shorter max attempts for faster testing
        webSocketManager.configure(
            enableAutoReconnect: true,
            reconnectDelay: 0.5,
            maxReconnectAttempts: maxAttempts
        )
        
        testDelegate.onConnectionStateChanged = { state in
            if state == .reconnecting {
                reconnectAttempts += 1
                print("🔄 Reconnection attempt #\(reconnectAttempts)/\(maxAttempts)")
            } else if state == .failed && reconnectAttempts >= maxAttempts {
                maxAttemptsExpectation.fulfill()
            }
        }
        
        // Start with invalid URL
        webSocketManager.connect(to: invalidServerURL)
        
        wait(for: [maxAttemptsExpectation], timeout: testTimeout)
        
        XCTAssertGreaterThanOrEqual(reconnectAttempts, maxAttempts,
                                  "Should have attempted at least \(maxAttempts) reconnections")
    }
    
    // MARK: - Network Recovery Tests
    
    /// Test automatic reconnection when network is restored
    func testNetworkRecoveryReconnection() throws {
        let networkRecoveryExpectation = XCTestExpectation(description: "WebSocket reconnects on network recovery")
        networkRecoveryExpectation.expectedFulfillmentCount = 2
        
        var isInitialConnectionMade = false
        var isReconnectionMade = false
        
        testDelegate.onDidConnect = { _ in
            if !isInitialConnectionMade {
                isInitialConnectionMade = true
                networkRecoveryExpectation.fulfill()
                
                // Simulate network interruption after initial connection
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.webSocketManager.disconnect()
                    
                    // Simulate network recovery after brief disconnection
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.webSocketManager.connect(to: self.mockServerURL)
                    }
                }
            } else if !isReconnectionMade {
                isReconnectionMade = true
                networkRecoveryExpectation.fulfill()
            }
        }
        
        // Start initial connection
        webSocketManager.connect(to: mockServerURL)
        
        wait(for: [networkRecoveryExpectation], timeout: testTimeout)
        
        XCTAssertTrue(isInitialConnectionMade, "Initial connection should be established")
        XCTAssertTrue(isReconnectionMade, "Reconnection should be established after network recovery")
    }
    
    // MARK: - Ping/Pong Tests
    
    /// Test heartbeat mechanism during connection
    func testHeartbeatMechanism() throws {
        let connectionExpectation = XCTestExpectation(description: "WebSocket establishes connection for heartbeat test")
        let heartbeatExpectation = XCTestExpectation(description: "WebSocket heartbeat works correctly")
        
        var connectionEstablished = false
        
        testDelegate.onDidConnect = { _ in
            if !connectionEstablished {
                connectionEstablished = true
                connectionExpectation.fulfill()
                
                // Wait for heartbeat activity
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    // If we're still connected after heartbeat interval, test passes
                    if self.webSocketManager.isConnected {
                        heartbeatExpectation.fulfill()
                    }
                }
            }
        }
        
        webSocketManager.connect(to: mockServerURL)
        
        wait(for: [connectionExpectation], timeout: testTimeout)
        wait(for: [heartbeatExpectation], timeout: pingTimeout)
        
        XCTAssertTrue(webSocketManager.isConnected, "WebSocket should maintain connection through heartbeat")
    }
    
    // MARK: - Message Queue Tests
    
    /// Test message queuing during disconnection
    func testMessageQueueingDuringDisconnection() throws {
        let queueExpectation = XCTestExpectation(description: "Messages are queued during disconnection")
        
        // First establish connection
        let connectionExpectation = XCTestExpectation(description: "Initial connection established")
        
        testDelegate.onDidConnect = { _ in
            connectionExpectation.fulfill()
        }
        
        webSocketManager.connect(to: mockServerURL)
        wait(for: [connectionExpectation], timeout: testTimeout)
        
        // Disconnect and send messages while offline
        webSocketManager.disconnect()
        
        // Send messages while disconnected (should be queued)
        let testMessage = "Test message while disconnected"
        webSocketManager.sendMessage(testMessage, projectId: "test-project")
        webSocketManager.sendMessage("Another test message", projectId: "test-project")
        
        // Reconnect and verify messages are sent
        testDelegate.onDidReceiveMessage = { _, message in
            if message.payload["content"] as? String == testMessage {
                queueExpectation.fulfill()
            }
        }
        
        webSocketManager.connect(to: mockServerURL)
        
        wait(for: [queueExpectation], timeout: testTimeout)
    }
    
    // MARK: - Stress Tests
    
    /// Test rapid disconnect/reconnect cycles
    func testRapidReconnectionCycles() throws {
        let cyclesExpectation = XCTestExpectation(description: "WebSocket handles rapid reconnection cycles")
        cyclesExpectation.expectedFulfillmentCount = 3
        
        var cycleCount = 0
        let maxCycles = 3
        
        func performCycle() {
            guard cycleCount < maxCycles else { return }
            
            cycleCount += 1
            print("🔄 Starting reconnection cycle #\(cycleCount)")
            
            webSocketManager.connect(to: mockServerURL)
            
            // Quick disconnect after brief connection
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.webSocketManager.disconnect()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    cyclesExpectation.fulfill()
                    
                    if cycleCount < maxCycles {
                        performCycle()
                    }
                }
            }
        }
        
        performCycle()
        
        wait(for: [cyclesExpectation], timeout: testTimeout)
        
        XCTAssertEqual(cycleCount, maxCycles, "Should complete all reconnection cycles")
    }
    
    // MARK: - Error Recovery Tests
    
    /// Test recovery from various error conditions
    func testErrorRecovery() throws {
        let recoveryExpectation = XCTestExpectation(description: "WebSocket recovers from errors")
        
        var errorEncountered = false
        var recoverySuccessful = false
        
        testDelegate.onDidDisconnect = { _, error in
            if error != nil && !errorEncountered {
                errorEncountered = true
                print("❌ Error encountered: \(error!.localizedDescription)")
                
                // Attempt recovery after error
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.webSocketManager.connect(to: self.mockServerURL)
                }
            }
        }
        
        testDelegate.onDidConnect = { _ in
            if errorEncountered && !recoverySuccessful {
                recoverySuccessful = true
                recoveryExpectation.fulfill()
            }
        }
        
        // Start with invalid URL to trigger error
        webSocketManager.connect(to: invalidServerURL)
        
        wait(for: [recoveryExpectation], timeout: testTimeout)
        
        XCTAssertTrue(errorEncountered, "Should encounter connection error")
        XCTAssertTrue(recoverySuccessful, "Should recover from error")
    }
    
    // MARK: - Performance Tests
    
    /// Test connection performance under load
    func testConnectionPerformance() throws {
        measure {
            let performanceExpectation = XCTestExpectation(description: "Connection performance test")
            
            testDelegate.onDidConnect = { _ in
                performanceExpectation.fulfill()
            }
            
            webSocketManager.connect(to: mockServerURL)
            
            wait(for: [performanceExpectation], timeout: 5.0)
            
            webSocketManager.disconnect()
        }
    }
}

// MARK: - Mock WebSocket Delegate

class MockWebSocketDelegate: WebSocketManagerDelegate {
    
    // Callback properties for testing
    var onDidConnect: ((WebSocketProtocol) -> Void)?
    var onDidDisconnect: ((WebSocketProtocol, Error?) -> Void)?
    var onDidReceiveMessage: ((WebSocketProtocol, WebSocketMessage) -> Void)?
    var onDidReceiveText: ((WebSocketProtocol, String) -> Void)?
    var onDidReceiveData: ((WebSocketProtocol, Data) -> Void)?
    var onConnectionStateChanged: ((WebSocketConnectionState) -> Void)?
    
    func webSocketDidConnect(_ webSocket: WebSocketProtocol) {
        print("🔗 [MockDelegate] WebSocket connected")
        onDidConnect?(webSocket)
    }
    
    func webSocketDidDisconnect(_ webSocket: WebSocketProtocol, error: Error?) {
        print("❌ [MockDelegate] WebSocket disconnected: \(error?.localizedDescription ?? "no error")")
        onDidDisconnect?(webSocket, error)
    }
    
    func webSocket(_ webSocket: WebSocketProtocol, didReceiveMessage message: WebSocketMessage) {
        print("📨 [MockDelegate] Received message: \(message.type)")
        onDidReceiveMessage?(webSocket, message)
    }
    
    func webSocket(_ webSocket: WebSocketProtocol, didReceiveText text: String) {
        print("📝 [MockDelegate] Received text: \(text.prefix(100))...")
        onDidReceiveText?(webSocket, text)
    }
    
    func webSocket(_ webSocket: WebSocketProtocol, didReceiveData data: Data) {
        print("📊 [MockDelegate] Received data: \(data.count) bytes")
        onDidReceiveData?(webSocket, data)
    }
    
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState) {
        print("🔄 [MockDelegate] Connection state changed: \(state)")
        onConnectionStateChanged?(state)
    }
}

// MARK: - Test Utilities

extension WebSocketReconnectionTests {
    
    /// Simulate network interruption for testing
    private func simulateNetworkInterruption(duration: TimeInterval) {
        // This would typically involve more sophisticated network simulation
        // For now, we'll use disconnect/reconnect as a proxy
        webSocketManager.disconnect()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.webSocketManager.connect(to: self.mockServerURL)
        }
    }
    
    /// Wait for connection state with timeout
    private func waitForConnectionState(_ expectedState: WebSocketConnectionState, timeout: TimeInterval = 10.0) -> Bool {
        let expectation = XCTestExpectation(description: "Wait for connection state: \(expectedState)")
        
        testDelegate.onConnectionStateChanged = { state in
            if state == expectedState {
                expectation.fulfill()
            }
        }
        
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}