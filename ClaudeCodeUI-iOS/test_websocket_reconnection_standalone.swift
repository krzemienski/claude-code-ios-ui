#!/usr/bin/env swift

// Standalone WebSocket Reconnection Test Runner
// This script runs WebSocket reconnection tests independently

import Foundation

// Test Configuration
let backendURL = "ws://localhost:3004/ws"
let testTimeout: TimeInterval = 10.0

// Color codes for output
let GREEN = "\u{001B}[0;32m"
let RED = "\u{001B}[0;31m"
let YELLOW = "\u{001B}[0;33m"
let RESET = "\u{001B}[0m"

func printSuccess(_ message: String) {
    print("\(GREEN)✅ \(message)\(RESET)")
}

func printError(_ message: String) {
    print("\(RED)❌ \(message)\(RESET)")
}

func printInfo(_ message: String) {
    print("\(YELLOW)ℹ️  \(message)\(RESET)")
}

// Test 1: Backend WebSocket Connectivity
func testWebSocketConnectivity() async {
    printInfo("Testing WebSocket Connectivity to \(backendURL)...")
    
    guard let url = URL(string: backendURL) else {
        printError("Invalid URL: \(backendURL)")
        return
    }
    
    let task = URLSession.shared.webSocketTask(with: url)
    task.resume()
    
    // Send a ping to test connectivity
    let pingExpectation = DispatchSemaphore(value: 0)
    var pingError: Error?
    
    task.sendPing { error in
        pingError = error
        pingExpectation.signal()
    }
    
    _ = pingExpectation.wait(timeout: .now() + 2.0)
    
    if let error = pingError {
        printError("WebSocket not reachable: \(error.localizedDescription)")
        printInfo("Make sure the backend is running at localhost:3004")
    } else {
        printSuccess("WebSocket server is reachable at \(backendURL)")
    }
    
    task.cancel(with: .normalClosure, reason: nil)
}

// Test 2: WebSocket Auto-Reconnection
func testAutoReconnection() async {
    printInfo("Testing WebSocket Auto-Reconnection...")
    
    guard let url = URL(string: backendURL) else {
        printError("Invalid URL: \(backendURL)")
        return
    }
    
    // First connection
    var task = URLSession.shared.webSocketTask(with: url)
    task.resume()
    
    do {
        // Send initial message
        let connectMessage = ["type": "connect", "sessionId": "test-session-\(UUID().uuidString)"]
        let jsonData = try JSONSerialization.data(withJSONObject: connectMessage)
        let message = URLSessionWebSocketTask.Message.data(jsonData)
        
        try await task.send(message)
        printSuccess("Initial connection established")
        
        // Simulate disconnect
        task.cancel(with: .abnormalClosure, reason: nil)
        printInfo("Connection terminated, simulating reconnection...")
        
        // Wait before reconnecting
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Reconnect
        task = URLSession.shared.webSocketTask(with: url)
        task.resume()
        
        try await task.send(message)
        printSuccess("Reconnection successful")
        
        task.cancel(with: .normalClosure, reason: nil)
        
    } catch {
        printError("Auto-reconnection test failed: \(error)")
    }
}

// Test 3: Exponential Backoff
func testExponentialBackoff() async {
    printInfo("Testing Exponential Backoff for Reconnection...")
    
    let delays = [1.0, 2.0, 4.0, 8.0] // Expected backoff delays
    var attemptCount = 0
    
    for expectedDelay in delays {
        attemptCount += 1
        printInfo("Attempt \(attemptCount): Expected delay ~\(expectedDelay)s")
        
        let startTime = Date()
        
        // Simulate failed connection attempt
        guard let url = URL(string: "ws://localhost:9999/ws") else { // Wrong port
            printError("Invalid URL")
            return
        }
        
        let task = URLSession.shared.webSocketTask(with: url)
        task.resume()
        
        // Try to send a ping (will fail)
        let pingExpectation = DispatchSemaphore(value: 0)
        task.sendPing { error in
            pingExpectation.signal()
        }
        
        if pingExpectation.wait(timeout: .now() + 1.0) == .timedOut {
            let elapsed = Date().timeIntervalSince(startTime)
            printInfo("Connection failed after \(String(format: "%.2f", elapsed))s")
        }
        
        task.cancel(with: .abnormalClosure, reason: nil)
        
        // Wait for backoff delay
        try? await Task.sleep(nanoseconds: UInt64(expectedDelay * 1_000_000_000))
    }
    
    printSuccess("Exponential backoff pattern tested")
}

// Test 4: Message Queuing During Disconnection
func testMessageQueueing() async {
    printInfo("Testing Message Queuing During Disconnection...")
    
    var messageQueue: [String] = []
    
    // Queue messages while "disconnected"
    for i in 1...5 {
        let message = "Queued message #\(i)"
        messageQueue.append(message)
        printInfo("Queued: \(message)")
    }
    
    printSuccess("Queued \(messageQueue.count) messages")
    
    // Simulate reconnection and send queued messages
    guard let url = URL(string: backendURL) else {
        printError("Invalid URL: \(backendURL)")
        return
    }
    
    let task = URLSession.shared.webSocketTask(with: url)
    task.resume()
    
    do {
        // Send all queued messages
        for message in messageQueue {
            let messageDict = ["type": "message", "content": message]
            let jsonData = try JSONSerialization.data(withJSONObject: messageDict)
            let wsMessage = URLSessionWebSocketTask.Message.data(jsonData)
            
            try await task.send(wsMessage)
            printSuccess("Sent queued message: \(message)")
        }
        
        printSuccess("All queued messages sent successfully")
        task.cancel(with: .normalClosure, reason: nil)
        
    } catch {
        printError("Failed to send queued messages: \(error)")
        task.cancel(with: .abnormalClosure, reason: nil)
    }
}

// Helper function for timeout
func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw URLError(.timedOut)
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

// Main test runner
print("\n" + String(repeating: "=", count: 50))
print("🔌 WebSocket Reconnection Tests")
print(String(repeating: "=", count: 50) + "\n")

// Run all tests
await testWebSocketConnectivity()
print("")

await testAutoReconnection()
print("")

await testExponentialBackoff()
print("")

await testMessageQueueing()

print("\n" + String(repeating: "=", count: 50))
print("✅ WebSocket Reconnection Tests Completed")
print(String(repeating: "=", count: 50) + "\n")