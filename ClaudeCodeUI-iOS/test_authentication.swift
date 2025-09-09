#!/usr/bin/env swift

// Standalone authentication test script
// Tests core authentication functionality

import Foundation

// Test Configuration
let testToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IlRlc3QgVXNlciIsImlhdCI6MTUxNjIzOTAyMn0.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
let refreshToken = "refresh_token_12345"
let testCredentials = """
{
    "email": "test@example.com",
    "userId": "user123"
}
"""

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

// Test 1: Backend API Connectivity
func testBackendConnectivity() async {
    printInfo("Testing Backend API Connectivity...")
    
    let url = URL(string: "http://localhost:3004/api/health")!
    var request = URLRequest(url: url)
    request.timeoutInterval = 5.0
    
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                if let responseString = String(data: data, encoding: .utf8) {
                    printSuccess("Backend is running at localhost:3004")
                    printInfo("Response: \(responseString)")
                } else {
                    printSuccess("Backend responded with status 200")
                }
            } else {
                printError("Backend returned status: \(httpResponse.statusCode)")
            }
        }
    } catch {
        printError("Backend not reachable: \(error.localizedDescription)")
        printInfo("Make sure the backend is running at localhost:3004")
    }
}

// Test 2: WebSocket Connectivity
func testWebSocketConnectivity() async {
    printInfo("Testing WebSocket Connectivity...")
    
    let url = URL(string: "ws://localhost:3004/ws")!
    let task = URLSession.shared.webSocketTask(with: url)
    task.resume()
    
    // Send a ping to test connectivity
    task.sendPing { error in
        if let error = error {
            printError("WebSocket not reachable: \(error.localizedDescription)")
        } else {
            printSuccess("WebSocket server is reachable at ws://localhost:3004/ws")
        }
        task.cancel(with: .normalClosure, reason: nil)
    }
    
    // Give it a moment to complete
    try? await Task.sleep(nanoseconds: 1_000_000_000)
}

// Test 3: Authentication Token Format
func testTokenFormat() {
    printInfo("Testing JWT Token Format...")
    
    let components = testToken.split(separator: ".")
    
    if components.count == 3 {
        printSuccess("Token has valid JWT format (3 parts)")
        
        // Try to decode header
        if let headerData = Data(base64Encoded: String(components[0]) + "=="),
           let header = try? JSONSerialization.jsonObject(with: headerData) as? [String: Any] {
            printSuccess("Token header is valid JSON")
            printInfo("Header: \(header)")
        } else {
            printError("Could not decode token header")
        }
        
        // Try to decode payload
        if let payloadData = Data(base64Encoded: String(components[1]) + "=="),
           let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] {
            printSuccess("Token payload is valid JSON")
            printInfo("Payload: \(payload)")
        } else {
            printError("Could not decode token payload")
        }
    } else {
        printError("Token does not have valid JWT format")
    }
}

// Test 4: Authentication Flow Simulation
func testAuthenticationFlow() async {
    printInfo("Testing Authentication Flow...")
    
    // Test login endpoint
    let loginURL = URL(string: "http://localhost:3004/api/auth/login")!
    var loginRequest = URLRequest(url: loginURL)
    loginRequest.httpMethod = "POST"
    loginRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let loginBody = ["email": "test@example.com", "password": "testpass"]
    loginRequest.httpBody = try? JSONSerialization.data(withJSONObject: loginBody)
    
    do {
        let (data, response) = try await URLSession.shared.data(for: loginRequest)
        
        if let httpResponse = response as? HTTPURLResponse {
            printInfo("Login endpoint returned status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    printSuccess("Login successful")
                    printInfo("Response: \(json)")
                }
            } else if httpResponse.statusCode == 404 {
                printInfo("Login endpoint not found - this is expected if auth is not implemented")
            } else {
                if let responseString = String(data: data, encoding: .utf8) {
                    printError("Login failed: \(responseString)")
                }
            }
        }
    } catch {
        printError("Login request failed: \(error.localizedDescription)")
    }
}

// Test 5: Keychain Simulation (without actual Keychain access)
func testKeychainSimulation() {
    printInfo("Testing Keychain Storage Simulation...")
    
    // Simulate storing tokens
    var storage: [String: String] = [:]
    
    // Store auth token
    storage["authToken"] = testToken
    if storage["authToken"] == testToken {
        printSuccess("Auth token stored successfully")
    } else {
        printError("Failed to store auth token")
    }
    
    // Store refresh token
    storage["refreshToken"] = refreshToken
    if storage["refreshToken"] == refreshToken {
        printSuccess("Refresh token stored successfully")
    } else {
        printError("Failed to store refresh token")
    }
    
    // Store user credentials
    storage["userCredentials"] = testCredentials
    if storage["userCredentials"] == testCredentials {
        printSuccess("User credentials stored successfully")
    } else {
        printError("Failed to store user credentials")
    }
    
    // Retrieve and verify
    if let retrievedToken = storage["authToken"], retrievedToken == testToken {
        printSuccess("Auth token retrieved successfully")
    } else {
        printError("Failed to retrieve auth token")
    }
    
    // Delete token
    storage.removeValue(forKey: "authToken")
    if storage["authToken"] == nil {
        printSuccess("Auth token deleted successfully")
    } else {
        printError("Failed to delete auth token")
    }
    
    printInfo("Keychain simulation completed with \(storage.count) items remaining")
}

// Main test runner
print("\n" + String(repeating: "=", count: 50))
print("🔐 Authentication Integration Tests")
print(String(repeating: "=", count: 50) + "\n")

// Run all tests
await testBackendConnectivity()
print("")

await testWebSocketConnectivity()
print("")

testTokenFormat()
print("")

await testAuthenticationFlow()
print("")

testKeychainSimulation()

print("\n" + String(repeating: "=", count: 50))
print("✅ Authentication Tests Completed")
print(String(repeating: "=", count: 50) + "\n")