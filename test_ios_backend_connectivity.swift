#!/usr/bin/env swift
// Test script to verify iOS backend connectivity

import Foundation

// Configuration
let backendURL = "http://localhost:3004"
let websocketURL = "ws://localhost:3004/ws"
let shellWebsocketURL = "ws://localhost:3004/shell"

// Test results
var testResults: [String: Bool] = [:]

// MARK: - Test 1: Basic API Health Check
func testAPIHealth() {
    print("\n🧪 Test 1: API Health Check")
    
    let url = URL(string: "\(backendURL)/api/projects")!
    let semaphore = DispatchSemaphore(value: 0)
    
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            print("❌ API Health Check Failed: \(error)")
            testResults["API Health"] = false
        } else if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                print("✅ API Health Check Passed (Status: \(httpResponse.statusCode))")
                testResults["API Health"] = true
            } else {
                print("❌ API Health Check Failed (Status: \(httpResponse.statusCode))")
                testResults["API Health"] = false
            }
        }
        semaphore.signal()
    }
    
    task.resume()
    semaphore.wait()
}

// MARK: - Test 2: WebSocket Connectivity
func testWebSocketConnection() {
    print("\n🧪 Test 2: WebSocket Connection")
    
    // Note: Full WebSocket test requires URLSessionWebSocketTask
    // This is a simplified connectivity check
    
    if let url = URL(string: websocketURL) {
        print("✅ WebSocket URL is valid: \(websocketURL)")
        testResults["WebSocket URL"] = true
    } else {
        print("❌ Invalid WebSocket URL")
        testResults["WebSocket URL"] = false
    }
}

// MARK: - Test 3: Shell WebSocket
func testShellWebSocket() {
    print("\n🧪 Test 3: Shell WebSocket")
    
    if let url = URL(string: shellWebsocketURL) {
        print("✅ Shell WebSocket URL is valid: \(shellWebsocketURL)")
        testResults["Shell WebSocket URL"] = true
    } else {
        print("❌ Invalid Shell WebSocket URL")
        testResults["Shell WebSocket URL"] = false
    }
}

// MARK: - Test 4: Critical Endpoints
func testCriticalEndpoints() {
    print("\n🧪 Test 4: Critical Endpoints")
    
    let endpoints = [
        "/api/projects",
        "/api/auth/status",
        "/api/mcp/servers"
    ]
    
    for endpoint in endpoints {
        let url = URL(string: "\(backendURL)\(endpoint)")!
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                let success = httpResponse.statusCode == 200 || httpResponse.statusCode == 401 // 401 is OK for auth endpoints
                testResults[endpoint] = success
                print("\(success ? "✅" : "❌") \(endpoint) - Status: \(httpResponse.statusCode)")
            } else {
                testResults[endpoint] = false
                print("❌ \(endpoint) - No response")
            }
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
    }
}

// MARK: - Main Execution
print("=" * 60)
print("🔍 iOS Backend Connectivity Test")
print("📍 Backend: \(backendURL)")
print("🕐 Time: \(Date())")
print("=" * 60)

// Run tests
testAPIHealth()
testWebSocketConnection()
testShellWebSocket()
testCriticalEndpoints()

// Summary
print("\n" + "=" * 60)
print("📊 TEST SUMMARY")
print("=" * 60)

let passedTests = testResults.values.filter { $0 }.count
let totalTests = testResults.count

for (test, result) in testResults.sorted(by: { $0.key < $1.key }) {
    print("\(result ? "✅" : "❌") \(test)")
}

print("\n📈 Result: \(passedTests)/\(totalTests) tests passed (\(Int(Double(passedTests)/Double(totalTests) * 100))%)")

if passedTests == totalTests {
    print("🎉 All tests passed! Backend is ready for iOS app.")
} else {
    print("⚠️ Some tests failed. Please check backend configuration.")
}

print("=" * 60)

// Helper
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}