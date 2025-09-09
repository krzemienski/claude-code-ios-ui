#!/usr/bin/env swift

import Foundation

// Test Configuration
let baseURL = "http://192.168.0.155:3004"
let wsURL = "ws://192.168.0.155:3004/ws"
let testToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjIsInVzZXJuYW1lIjoiZGVtbyIsImlhdCI6MTc1NTEzMjI3Mn0.D2ca9DyDwRR8rcJ3Latt86KyfsfuN4_8poJCQCjQ8TI"

// Test Results Structure
struct TestResult {
    let testName: String
    let passed: Bool
    let details: String
    let timestamp: Date
}

var testResults: [TestResult] = []

// MARK: - Test 1: API Connectivity
func testAPIConnectivity() {
    print("\n🔍 Test 1: API Connectivity")
    
    let url = URL(string: "\(baseURL)/api/projects")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let semaphore = DispatchSemaphore(value: 0)
    var result: TestResult?
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            result = TestResult(
                testName: "API Connectivity",
                passed: false,
                details: "Failed to connect: \(error.localizedDescription)",
                timestamp: Date()
            )
        } else if let httpResponse = response as? HTTPURLResponse {
            let passed = httpResponse.statusCode == 200 || httpResponse.statusCode == 401
            result = TestResult(
                testName: "API Connectivity",
                passed: passed,
                details: "Status Code: \(httpResponse.statusCode)",
                timestamp: Date()
            )
        }
        semaphore.signal()
    }
    
    task.resume()
    semaphore.wait()
    
    if let result = result {
        testResults.append(result)
        print("   ✓ API Status: \(result.passed ? "✅ Connected" : "❌ Failed") - \(result.details)")
    }
}

// MARK: - Test 2: WebSocket Connectivity
func testWebSocketConnectivity() {
    print("\n🔍 Test 2: WebSocket Connectivity")
    
    let urlString = "\(wsURL)?token=\(testToken)"
    guard let url = URL(string: urlString) else {
        testResults.append(TestResult(
            testName: "WebSocket Connectivity",
            passed: false,
            details: "Invalid WebSocket URL",
            timestamp: Date()
        ))
        return
    }
    
    let webSocketTask = URLSession.shared.webSocketTask(with: url)
    webSocketTask.resume()
    
    let semaphore = DispatchSemaphore(value: 0)
    var result: TestResult?
    
    // Send ping
    webSocketTask.sendPing { error in
        if let error = error {
            result = TestResult(
                testName: "WebSocket Connectivity",
                passed: false,
                details: "Ping failed: \(error.localizedDescription)",
                timestamp: Date()
            )
        } else {
            result = TestResult(
                testName: "WebSocket Connectivity",
                passed: true,
                details: "WebSocket connected and responding",
                timestamp: Date()
            )
        }
        webSocketTask.cancel(with: .goingAway, reason: nil)
        semaphore.signal()
    }
    
    // Wait up to 5 seconds
    _ = semaphore.wait(timeout: .now() + 5)
    
    if let result = result {
        testResults.append(result)
        print("   ✓ WebSocket Status: \(result.passed ? "✅ Connected" : "❌ Failed") - \(result.details)")
    } else {
        let timeoutResult = TestResult(
            testName: "WebSocket Connectivity",
            passed: false,
            details: "Connection timeout",
            timestamp: Date()
        )
        testResults.append(timeoutResult)
        print("   ✓ WebSocket Status: ❌ Timeout")
    }
}

// MARK: - Test 3: Message Sending
func testMessageSending() {
    print("\n🔍 Test 3: Message Sending via API")
    
    let url = URL(string: "\(baseURL)/api/chat/send")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(testToken)", forHTTPHeaderField: "Authorization")
    
    let messageData: [String: Any] = [
        "sessionId": "test-session-\(Int(Date().timeIntervalSince1970))",
        "message": "Test message from iOS app at \(Date())",
        "model": "claude-3"
    ]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: messageData)
    } catch {
        testResults.append(TestResult(
            testName: "Message Sending",
            passed: false,
            details: "Failed to serialize message",
            timestamp: Date()
        ))
        return
    }
    
    let semaphore = DispatchSemaphore(value: 0)
    var result: TestResult?
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            result = TestResult(
                testName: "Message Sending",
                passed: false,
                details: "Send failed: \(error.localizedDescription)",
                timestamp: Date()
            )
        } else if let httpResponse = response as? HTTPURLResponse {
            let passed = httpResponse.statusCode == 200
            result = TestResult(
                testName: "Message Sending",
                passed: passed,
                details: "Status Code: \(httpResponse.statusCode)",
                timestamp: Date()
            )
        }
        semaphore.signal()
    }
    
    task.resume()
    _ = semaphore.wait(timeout: .now() + 10)
    
    if let result = result {
        testResults.append(result)
        print("   ✓ Message Send: \(result.passed ? "✅ Success" : "❌ Failed") - \(result.details)")
    } else {
        testResults.append(TestResult(
            testName: "Message Sending",
            passed: false,
            details: "Request timeout",
            timestamp: Date()
        ))
        print("   ✓ Message Send: ❌ Timeout")
    }
}

// MARK: - Test 4: Session History
func testSessionHistory() {
    print("\n🔍 Test 4: Session History Retrieval")
    
    let url = URL(string: "\(baseURL)/api/sessions")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(testToken)", forHTTPHeaderField: "Authorization")
    
    let semaphore = DispatchSemaphore(value: 0)
    var result: TestResult?
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            result = TestResult(
                testName: "Session History",
                passed: false,
                details: "Failed: \(error.localizedDescription)",
                timestamp: Date()
            )
        } else if let httpResponse = response as? HTTPURLResponse {
            let passed = httpResponse.statusCode == 200
            var details = "Status: \(httpResponse.statusCode)"
            
            if passed, let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                        details += ", Sessions found: \(json.count)"
                    }
                } catch {
                    details += ", Could not parse response"
                }
            }
            
            result = TestResult(
                testName: "Session History",
                passed: passed,
                details: details,
                timestamp: Date()
            )
        }
        semaphore.signal()
    }
    
    task.resume()
    _ = semaphore.wait(timeout: .now() + 10)
    
    if let result = result {
        testResults.append(result)
        print("   ✓ Session History: \(result.passed ? "✅ Success" : "❌ Failed") - \(result.details)")
    } else {
        testResults.append(TestResult(
            testName: "Session History",
            passed: false,
            details: "Request timeout",
            timestamp: Date()
        ))
        print("   ✓ Session History: ❌ Timeout")
    }
}

// MARK: - Main Test Execution
print("🚀 Claude Code UI - iOS Chat Feature Test Suite")
print("================================================")
print("Backend URL: \(baseURL)")
print("WebSocket URL: \(wsURL)")
print("Test Started: \(Date())")

// Run all tests
testAPIConnectivity()
testWebSocketConnectivity()
testMessageSending()
testSessionHistory()

// Generate Report
print("\n📊 Test Results Summary")
print("========================")

let passedTests = testResults.filter { $0.passed }.count
let totalTests = testResults.count
let passRate = Double(passedTests) / Double(totalTests) * 100

for (index, result) in testResults.enumerated() {
    print("\(index + 1). \(result.testName): \(result.passed ? "✅ PASSED" : "❌ FAILED")")
    if !result.passed {
        print("   Details: \(result.details)")
    }
}

print("\n📈 Overall Results:")
print("   Total Tests: \(totalTests)")
print("   Passed: \(passedTests)")
print("   Failed: \(totalTests - passedTests)")
print("   Pass Rate: \(String(format: "%.1f", passRate))%")
print("\n✅ Test Suite Completed at \(Date())")

// Exit with appropriate code
exit(passedTests == totalTests ? 0 : 1)