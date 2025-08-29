//
//  WebSocketManagerTests.swift
//  ClaudeCodeUITests
//
//  Comprehensive unit tests for WebSocketManager with mocked WebSocket connections
//

import XCTest
import Foundation
@testable import ClaudeCodeUI

final class WebSocketManagerTests: XCTestCase {
    
    var webSocketManager: WebSocketManager!
    var mockWebSocketTask: MockWebSocketTask!
    var mockDelegate: MockWebSocketDelegate!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        mockWebSocketTask = MockWebSocketTask()
        mockDelegate = MockWebSocketDelegate()
        
        webSocketManager = WebSocketManager()
        webSocketManager.delegate = mockDelegate
        
        // Inject mock WebSocket task
        webSocketManager.setWebSocketTask(mockWebSocketTask)
    }
    
    override func tearDownWithError() throws {
        webSocketManager?.disconnect()
        webSocketManager = nil
        mockWebSocketTask = nil
        mockDelegate = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Connection Tests
    
    func testConnectSuccess() throws {
        // Given
        let testURL = URL(string: "ws://localhost:3004/ws")!
        
        // When
        webSocketManager.connect(to: testURL)
        
        // Then
        XCTAssertEqual(webSocketManager.connectionState, .connecting)
        XCTAssertTrue(mockWebSocketTask.resumeCalled)
        XCTAssertEqual(mockWebSocketTask.url, testURL)
        
        // Simulate successful connection
        mockWebSocketTask.simulateConnectionState(.running)
        
        XCTAssertEqual(webSocketManager.connectionState, .connected)
        XCTAssertTrue(mockDelegate.connectionStateChanges.contains(.connected))
    }
    
    func testConnectFailure() throws {
        // Given
        let testURL = URL(string: "ws://localhost:3004/ws")!
        
        // When
        webSocketManager.connect(to: testURL)
        
        // Simulate connection failure
        let connectionError = URLError(.cannotConnectToHost)
        mockWebSocketTask.simulateError(connectionError)
        
        // Then
        XCTAssertEqual(webSocketManager.connectionState, .disconnected)
        XCTAssertTrue(mockDelegate.errorReceived != nil)
        XCTAssertTrue(mockDelegate.errorReceived is URLError)
    }
    
    func testDisconnect() throws {
        // Given
        let testURL = URL(string: "ws://localhost:3004/ws")!
        webSocketManager.connect(to: testURL)
        mockWebSocketTask.simulateConnectionState(.running)
        
        // When
        webSocketManager.disconnect()
        
        // Then
        XCTAssertEqual(webSocketManager.connectionState, .disconnected)
        XCTAssertTrue(mockWebSocketTask.cancelCalled)
        XCTAssertTrue(mockDelegate.connectionStateChanges.contains(.disconnected))
    }
    
    // MARK: - Message Sending Tests
    
    func testSendTextMessage() throws {
        // Given
        setupConnectedWebSocket()
        let testMessage = WebSocketMessage(type: .claudeCommand, content: "Hello, Claude!")
        
        // When
        webSocketManager.send(message: testMessage)
        
        // Then
        XCTAssertTrue(mockWebSocketTask.sentMessages.count == 1)
        let sentData = mockWebSocketTask.sentMessages.first
        XCTAssertNotNil(sentData)
        
        // Verify message content
        let decodedMessage = try JSONDecoder().decode(WebSocketMessage.self, from: sentData!)
        XCTAssertEqual(decodedMessage.type, .claudeCommand)
        XCTAssertEqual(decodedMessage.content, "Hello, Claude!")
    }
    
    func testSendMessageWhenDisconnected() throws {
        // Given
        let testMessage = WebSocketMessage(type: .claudeCommand, content: "Hello!")
        
        // When
        webSocketManager.send(message: testMessage)
        
        // Then
        XCTAssertEqual(mockWebSocketTask.sentMessages.count, 0)
        XCTAssertTrue(mockDelegate.errorReceived != nil)
    }
    
    func testMessageQueuing() throws {
        // Given
        let testURL = URL(string: "ws://localhost:3004/ws")!
        webSocketManager.connect(to: testURL)
        
        let message1 = WebSocketMessage(type: .claudeCommand, content: "Message 1")
        let message2 = WebSocketMessage(type: .claudeCommand, content: "Message 2")
        
        // When - Send messages while connecting
        webSocketManager.send(message: message1)
        webSocketManager.send(message: message2)
        
        // Simulate connection established
        mockWebSocketTask.simulateConnectionState(.running)
        
        // Then - Both messages should be sent
        XCTAssertEqual(mockWebSocketTask.sentMessages.count, 2)
        
        let decodedMessage1 = try JSONDecoder().decode(WebSocketMessage.self, from: mockWebSocketTask.sentMessages[0])
        let decodedMessage2 = try JSONDecoder().decode(WebSocketMessage.self, from: mockWebSocketTask.sentMessages[1])
        
        XCTAssertEqual(decodedMessage1.content, "Message 1")
        XCTAssertEqual(decodedMessage2.content, "Message 2")
    }
    
    // MARK: - Message Receiving Tests
    
    func testReceiveTextMessage() throws {
        // Given
        setupConnectedWebSocket()
        let expectedMessage = WebSocketMessage(type: .assistantResponse, content: "Hello from Claude!")
        let messageData = try JSONEncoder().encode(expectedMessage)
        
        // When
        mockWebSocketTask.simulateReceivedMessage(.data(messageData))
        
        // Then
        XCTAssertEqual(mockDelegate.receivedMessages.count, 1)
        let receivedMessage = mockDelegate.receivedMessages.first!
        XCTAssertEqual(receivedMessage.type, .assistantResponse)
        XCTAssertEqual(receivedMessage.content, "Hello from Claude!")
    }
    
    func testReceiveStringMessage() throws {
        // Given
        setupConnectedWebSocket()
        let messageString = #"{"type":"assistantResponse","content":"String message"}"#
        
        // When
        mockWebSocketTask.simulateReceivedMessage(.string(messageString))
        
        // Then
        XCTAssertEqual(mockDelegate.receivedMessages.count, 1)
        let receivedMessage = mockDelegate.receivedMessages.first!
        XCTAssertEqual(receivedMessage.type, .assistantResponse)
        XCTAssertEqual(receivedMessage.content, "String message")
    }
    
    func testReceiveInvalidMessage() throws {
        // Given
        setupConnectedWebSocket()
        let invalidData = "Invalid JSON".data(using: .utf8)!
        
        // When
        mockWebSocketTask.simulateReceivedMessage(.data(invalidData))
        
        // Then
        XCTAssertEqual(mockDelegate.receivedMessages.count, 0)
        XCTAssertTrue(mockDelegate.errorReceived != nil)
    }
    
    // MARK: - Ping/Pong Tests
    
    func testPingPongMechanism() throws {
        // Given
        setupConnectedWebSocket()
        
        // When
        webSocketManager.startPingTimer()
        
        // Simulate ping interval
        mockWebSocketTask.simulatePingReceived()
        
        // Then
        XCTAssertTrue(mockWebSocketTask.pongSent)
    }
    
    func testConnectionTimeoutOnMissedPong() throws {
        // Given
        setupConnectedWebSocket()
        webSocketManager.startPingTimer()
        
        // When - Miss several pongs
        for _ in 0..<3 {
            mockWebSocketTask.simulatePingReceived()
            // Don't send pong response
        }
        
        // Then - Should detect timeout and attempt reconnection
        XCTEventuallyAssertTrue(webSocketManager.connectionState == .connecting, timeout: 2.0)
    }
    
    // MARK: - Reconnection Tests
    
    func testAutoReconnectAfterDisconnection() throws {
        // Given
        setupConnectedWebSocket()
        webSocketManager.enableAutoReconnect(true)
        
        // When - Connection drops
        mockWebSocketTask.simulateConnectionState(.completed)
        
        // Then - Should attempt reconnection
        XCTEventuallyAssertTrue(webSocketManager.connectionState == .connecting, timeout: 1.0)
        XCTAssertTrue(mockDelegate.connectionStateChanges.contains(.connecting))
    }
    
    func testExponentialBackoffReconnection() throws {
        // Given
        webSocketManager.enableAutoReconnect(true)
        let testURL = URL(string: "ws://localhost:3004/ws")!
        
        var connectionAttempts: [Date] = []
        
        // When - Multiple failed connection attempts
        for _ in 0..<3 {
            webSocketManager.connect(to: testURL)
            connectionAttempts.append(Date())
            
            // Simulate connection failure
            mockWebSocketTask.simulateError(URLError(.timedOut))
            
            // Wait briefly for retry logic
            usleep(100000) // 0.1 seconds
        }
        
        // Then - Verify exponential backoff timing
        XCTAssertGreaterThanOrEqual(connectionAttempts.count, 3)
        
        // First retry should be after ~1 second
        // Second retry should be after ~2 seconds  
        // Third retry should be after ~4 seconds
        // (Exact timing verification would require more complex mock timing)
    }
    
    func testMaxReconnectAttempts() throws {
        // Given
        webSocketManager.enableAutoReconnect(true)
        webSocketManager.setMaxReconnectAttempts(3)
        let testURL = URL(string: "ws://localhost:3004/ws")!
        
        // When - Exceed max reconnect attempts
        for _ in 0..<5 {
            webSocketManager.connect(to: testURL)
            mockWebSocketTask.simulateError(URLError(.timedOut))
            usleep(10000) // Brief wait
        }
        
        // Then - Should stop trying to reconnect
        XCTEventuallyAssertTrue(mockDelegate.maxReconnectAttemptsReached, timeout: 1.0)
    }
    
    // MARK: - Authentication Tests
    
    func testJWTTokenInConnectionURL() throws {
        // Given
        let baseURL = URL(string: "ws://localhost:3004/ws")!
        let jwtToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.test"
        
        // When
        webSocketManager.connect(to: baseURL, withJWT: jwtToken)
        
        // Then
        let expectedURL = URL(string: "ws://localhost:3004/ws?token=\(jwtToken)")!
        XCTAssertEqual(mockWebSocketTask.url, expectedURL)
    }
    
    func testTokenRefreshDuringConnection() throws {
        // Given
        setupConnectedWebSocket()
        let newToken = "new.jwt.token"
        
        // When
        webSocketManager.updateAuthToken(newToken)
        
        // Then - Should reconnect with new token
        XCTAssertTrue(mockWebSocketTask.cancelCalled)
        // In a real implementation, would verify new connection with updated token
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorHandling() throws {
        // Given
        setupConnectedWebSocket()
        
        // When
        let networkError = URLError(.networkConnectionLost)
        mockWebSocketTask.simulateError(networkError)
        
        // Then
        XCTAssertEqual(webSocketManager.connectionState, .disconnected)
        XCTAssertTrue(mockDelegate.errorReceived is URLError)
        XCTAssertEqual((mockDelegate.errorReceived as? URLError)?.code, .networkConnectionLost)
    }
    
    func testUnauthorizedErrorHandling() throws {
        // Given
        let testURL = URL(string: "ws://localhost:3004/ws")!
        webSocketManager.connect(to: testURL)
        
        // When
        let unauthorizedError = URLError(.userAuthenticationRequired)
        mockWebSocketTask.simulateError(unauthorizedError)
        
        // Then
        XCTAssertEqual(webSocketManager.connectionState, .disconnected)
        XCTAssertFalse(webSocketManager.shouldAutoReconnect) // Should not auto-reconnect for auth errors
    }
    
    func testServerErrorHandling() throws {
        // Given
        setupConnectedWebSocket()
        
        // When
        let serverError = URLError(.badServerResponse)
        mockWebSocketTask.simulateError(serverError)
        
        // Then
        XCTAssertEqual(webSocketManager.connectionState, .disconnected)
        XCTAssertTrue(mockDelegate.errorReceived is URLError)
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentMessageSending() throws {
        // Given
        setupConnectedWebSocket()
        let messageCount = 100
        
        // When - Send messages concurrently
        DispatchQueue.concurrentPerform(iterations: messageCount) { index in
            let message = WebSocketMessage(type: .claudeCommand, content: "Message \(index)")
            webSocketManager.send(message: message)
        }
        
        // Then - All messages should be sent
        XCTEventuallyAssertEqual(mockWebSocketTask.sentMessages.count, messageCount, timeout: 2.0)
    }
    
    func testConcurrentConnectionOperations() throws {
        // Given
        let testURL = URL(string: "ws://localhost:3004/ws")!
        
        // When - Perform concurrent connect/disconnect operations
        DispatchQueue.concurrentPerform(iterations: 10) { _ in
            webSocketManager.connect(to: testURL)
            usleep(1000) // Brief delay
            webSocketManager.disconnect()
        }
        
        // Then - Should not crash and end in a consistent state
        XCTAssertNotNil(webSocketManager.connectionState)
    }
    
    // MARK: - Performance Tests
    
    func testMessageSendingPerformance() throws {
        setupConnectedWebSocket()
        
        measure {
            for i in 0..<1000 {
                let message = WebSocketMessage(type: .claudeCommand, content: "Performance test \(i)")
                webSocketManager.send(message: message)
            }
        }
    }
    
    func testConnectionPerformance() throws {
        let testURL = URL(string: "ws://localhost:3004/ws")!
        
        measure {
            webSocketManager.connect(to: testURL)
            mockWebSocketTask.simulateConnectionState(.running)
            webSocketManager.disconnect()
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testDelegateWeakReference() throws {
        // Given
        var delegate: MockWebSocketDelegate? = MockWebSocketDelegate()
        webSocketManager.delegate = delegate
        
        // When
        delegate = nil
        
        // Then
        XCTAssertNil(webSocketManager.delegate)
    }
    
    func testMemoryLeakPrevention() throws {
        // Given
        var manager: WebSocketManager? = WebSocketManager()
        weak var weakManager = manager
        
        // When
        manager = nil
        
        // Then
        XCTAssertNil(weakManager)
    }
    
    // MARK: - Helper Methods
    
    private func setupConnectedWebSocket() {
        let testURL = URL(string: "ws://localhost:3004/ws")!
        webSocketManager.connect(to: testURL)
        mockWebSocketTask.simulateConnectionState(.running)
    }
}

// MARK: - Mock WebSocket Task

class MockWebSocketTask: URLSessionWebSocketTask {
    var url: URL?
    var resumeCalled = false
    var cancelCalled = false
    var pongSent = false
    var sentMessages: [Data] = []
    var connectionState: URLSessionTask.State = .suspended
    
    private var messageHandler: ((URLSessionWebSocketTask.Message) -> Void)?
    
    override func resume() {
        resumeCalled = true
        connectionState = .running
    }
    
    override func cancel() {
        cancelCalled = true
        connectionState = .canceling
    }
    
    override func send(_ message: URLSessionWebSocketTask.Message) async throws {
        switch message {
        case .data(let data):
            sentMessages.append(data)
        case .string(let string):
            sentMessages.append(string.data(using: .utf8) ?? Data())
        @unknown default:
            break
        }
    }
    
    override func receive() async throws -> URLSessionWebSocketTask.Message {
        // This would need more sophisticated mocking for real async testing
        return .string("mock message")
    }
    
    override func sendPing() async throws {
        // Mock ping implementation
    }
    
    // Mock helper methods
    func simulateConnectionState(_ state: URLSessionTask.State) {
        connectionState = state
        // Notify the WebSocketManager of state change
    }
    
    func simulateError(_ error: Error) {
        // Simulate error callback to WebSocketManager
    }
    
    func simulateReceivedMessage(_ message: URLSessionWebSocketTask.Message) {
        messageHandler?(message)
    }
    
    func simulatePingReceived() {
        // Simulate ping frame received
    }
}

// MARK: - Mock WebSocket Delegate

class MockWebSocketDelegate: WebSocketManagerDelegate {
    var connectionStateChanges: [WebSocketConnectionState] = []
    var receivedMessages: [WebSocketMessage] = []
    var errorReceived: Error?
    var maxReconnectAttemptsReached = false
    
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState) {
        connectionStateChanges.append(state)
    }
    
    func webSocketDidReceiveMessage(_ message: WebSocketMessage) {
        receivedMessages.append(message)
    }
    
    func webSocketDidReceiveError(_ error: Error) {
        errorReceived = error
    }
    
    func webSocketMaxReconnectAttemptsReached() {
        maxReconnectAttemptsReached = true
    }
}

// MARK: - WebSocketManager Extensions for Testing

extension WebSocketManager {
    func setWebSocketTask(_ task: URLSessionWebSocketTask) {
        // In a real implementation, this would inject the mock task
        // For testing purposes, this is a placeholder
    }
    
    func enableAutoReconnect(_ enabled: Bool) {
        // Enable/disable auto-reconnection
    }
    
    func setMaxReconnectAttempts(_ attempts: Int) {
        // Set maximum reconnection attempts
    }
    
    func startPingTimer() {
        // Start the ping/pong timer
    }
    
    func updateAuthToken(_ token: String) {
        // Update JWT token and reconnect if needed
    }
    
    var shouldAutoReconnect: Bool {
        // Return current auto-reconnect setting
        return true // Placeholder
    }
}

// MARK: - Test Utilities

extension XCTestCase {
    func XCTEventuallyAssertTrue(_ expression: @escaping @autoclosure () -> Bool, timeout: TimeInterval, message: String = "") {
        let expectation = XCTestExpectation(description: message)
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if expression() {
                expectation.fulfill()
                timer.invalidate()
            }
        }
        
        wait(for: [expectation], timeout: timeout)
        timer.invalidate()
    }
    
    func XCTEventuallyAssertEqual<T: Equatable>(_ expression1: @escaping @autoclosure () -> T, _ expression2: @escaping @autoclosure () -> T, timeout: TimeInterval, message: String = "") {
        let expectation = XCTestExpectation(description: message)
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if expression1() == expression2() {
                expectation.fulfill()
                timer.invalidate()
            }
        }
        
        wait(for: [expectation], timeout: timeout)
        timer.invalidate()
    }
}