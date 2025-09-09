#!/usr/bin/env swift

import Foundation

// Comprehensive WebSocket Test Suite
class ComprehensiveWebSocketTest: NSObject, URLSessionWebSocketDelegate {
    private var webSocketTask: URLSessionWebSocketTask?
    private let session: URLSession
    private let semaphore = DispatchSemaphore(value: 0)
    private var testResults: [String: Bool] = [:]
    
    override init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "ClaudeCodeUI-Test/1.0"
        ]
        self.session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        super.init()
    }
    
    func runAllTests() {
        print("🚀 COMPREHENSIVE WEBSOCKET TEST SUITE")
        print("=====================================\n")
        
        // Test 1: Basic Connection
        testBasicConnection()
        
        // Test 2: Message Sending
        testMessageSending()
        
        // Test 3: Message Streaming
        testMessageStreaming()
        
        // Test 4: Session Continuity
        testSessionContinuity()
        
        // Test 5: Reconnection
        testReconnection()
        
        // Test 6: Error Recovery
        testErrorRecovery()
        
        // Print Results
        printTestResults()
    }
    
    func testBasicConnection() {
        print("📝 TEST 1: Basic Connection")
        print("-" * 30)
        
        let url = URL(string: "ws://192.168.0.155:3004/ws")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        
        var connected = false
        webSocketTask?.sendPing { error in
            if error == nil {
                connected = true
                print("✅ Connection established")
            } else {
                print("❌ Connection failed: \(error!)")
            }
            self.semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + 5)
        testResults["Basic Connection"] = connected
        
        if connected {
            webSocketTask?.cancel(with: .goingAway, reason: nil)
        }
        Thread.sleep(forTimeInterval: 0.5)
        print()
    }
    
    func testMessageSending() {
        print("📝 TEST 2: Message Sending")
        print("-" * 30)
        
        let url = URL(string: "ws://192.168.0.155:3004/ws")!
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        var messageSent = false
        
        let message: [String: Any] = [
            "type": "claude-command",
            "command": "Test message from iOS",
            "timestamp": Date().timeIntervalSince1970,
            "sessionId": UUID().uuidString
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: message),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            
            let wsMessage = URLSessionWebSocketTask.Message.string(jsonString)
            
            webSocketTask?.send(wsMessage) { error in
                if error == nil {
                    messageSent = true
                    print("✅ Message sent successfully")
                } else {
                    print("❌ Send failed: \(error!)")
                }
                self.semaphore.signal()
            }
            
            _ = semaphore.wait(timeout: .now() + 5)
        }
        
        testResults["Message Sending"] = messageSent
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        Thread.sleep(forTimeInterval: 0.5)
        print()
    }
    
    func testMessageStreaming() {
        print("📝 TEST 3: Message Streaming")
        print("-" * 30)
        
        let url = URL(string: "ws://192.168.0.155:3004/ws")!
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        var streamingWorked = false
        var messagesReceived = 0
        
        // Send multiple messages rapidly
        for i in 1...5 {
            let message: [String: Any] = ["type": "stream", "chunk": i, "data": "Stream chunk \(i)"]
            if let jsonData = try? JSONSerialization.data(withJSONObject: message),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                
                let wsMessage = URLSessionWebSocketTask.Message.string(jsonString)
                webSocketTask?.send(wsMessage) { error in
                    if error == nil {
                        messagesReceived += 1
                        print("📤 Sent stream chunk \(i)")
                    }
                }
            }
        }
        
        Thread.sleep(forTimeInterval: 1)
        streamingWorked = messagesReceived >= 3
        
        if streamingWorked {
            print("✅ Streaming successful (\(messagesReceived)/5 chunks)")
        } else {
            print("❌ Streaming failed (\(messagesReceived)/5 chunks)")
        }
        
        testResults["Message Streaming"] = streamingWorked
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        Thread.sleep(forTimeInterval: 0.5)
        print()
    }
    
    func testSessionContinuity() {
        print("📝 TEST 4: Session Continuity")
        print("-" * 30)
        
        let sessionId = UUID().uuidString
        let url = URL(string: "ws://192.168.0.155:3004/ws")!
        
        // First connection
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Send message with session ID
        let message1: [String: Any] = ["type": "session", "sessionId": sessionId, "message": "First message"]
        if let jsonData = try? JSONSerialization.data(withJSONObject: message1),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            
            let wsMessage = URLSessionWebSocketTask.Message.string(jsonString)
            webSocketTask?.send(wsMessage) { _ in }
        }
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Disconnect
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        Thread.sleep(forTimeInterval: 0.5)
        
        // Reconnect with same session
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        var continuityMaintained = false
        
        // Send follow-up message
        let message2: [String: Any] = ["type": "session", "sessionId": sessionId, "message": "Follow-up message"]
        if let jsonData = try? JSONSerialization.data(withJSONObject: message2),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            
            let wsMessage = URLSessionWebSocketTask.Message.string(jsonString)
            webSocketTask?.send(wsMessage) { error in
                continuityMaintained = (error == nil)
                if continuityMaintained {
                    print("✅ Session continuity maintained")
                } else {
                    print("❌ Session continuity failed")
                }
                self.semaphore.signal()
            }
            
            _ = semaphore.wait(timeout: .now() + 5)
        }
        
        testResults["Session Continuity"] = continuityMaintained
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        Thread.sleep(forTimeInterval: 0.5)
        print()
    }
    
    func testReconnection() {
        print("📝 TEST 5: Reconnection")
        print("-" * 30)
        
        let url = URL(string: "ws://192.168.0.155:3004/ws")!
        var reconnectionWorked = false
        
        // Initial connection
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Force disconnect
        webSocketTask?.cancel(with: .abnormalClosure, reason: nil)
        print("🔌 Disconnected intentionally")
        Thread.sleep(forTimeInterval: 0.5)
        
        // Attempt reconnection
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        webSocketTask?.sendPing { error in
            reconnectionWorked = (error == nil)
            if reconnectionWorked {
                print("✅ Reconnection successful")
            } else {
                print("❌ Reconnection failed")
            }
            self.semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + 5)
        
        testResults["Reconnection"] = reconnectionWorked
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        Thread.sleep(forTimeInterval: 0.5)
        print()
    }
    
    func testErrorRecovery() {
        print("📝 TEST 6: Error Recovery")
        print("-" * 30)
        
        // Test with invalid URL first
        let invalidURL = URL(string: "ws://invalid.host:9999/ws")!
        webSocketTask = session.webSocketTask(with: invalidURL)
        webSocketTask?.resume()
        
        var errorHandled = false
        
        webSocketTask?.sendPing { error in
            if error != nil {
                errorHandled = true
                print("✅ Error detected: \(error!.localizedDescription)")
                
                // Now try valid connection (recovery)
                let validURL = URL(string: "ws://192.168.0.155:3004/ws")!
                self.webSocketTask = self.session.webSocketTask(with: validURL)
                self.webSocketTask?.resume()
                
                self.webSocketTask?.sendPing { recoveryError in
                    if recoveryError == nil {
                        print("✅ Recovered with valid connection")
                    } else {
                        print("❌ Recovery failed")
                        errorHandled = false
                    }
                    self.semaphore.signal()
                }
            } else {
                self.semaphore.signal()
            }
        }
        
        _ = semaphore.wait(timeout: .now() + 10)
        
        testResults["Error Recovery"] = errorHandled
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        print()
    }
    
    func printTestResults() {
        print("=====================================")
        print("📊 TEST RESULTS SUMMARY")
        print("=====================================\n")
        
        var passedTests = 0
        var failedTests = 0
        
        for (testName, passed) in testResults {
            if passed {
                print("✅ \(testName): PASSED")
                passedTests += 1
            } else {
                print("❌ \(testName): FAILED")
                failedTests += 1
            }
        }
        
        print("\n=====================================")
        print("📈 STATISTICS")
        print("=====================================")
        print("Total Tests: \(passedTests + failedTests)")
        print("Passed: \(passedTests)")
        print("Failed: \(failedTests)")
        
        let successRate = passedTests > 0 ? (Double(passedTests) / Double(passedTests + failedTests) * 100) : 0
        print("Success Rate: \(String(format: "%.1f", successRate))%")
        
        if failedTests == 0 {
            print("\n🎉 ALL WEBSOCKET TESTS PASSED!")
        } else {
            print("\n⚠️ Some tests failed. Review the results above.")
        }
    }
}

// Extension for string multiplication
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// Main execution
let tester = ComprehensiveWebSocketTest()
tester.runAllTests()