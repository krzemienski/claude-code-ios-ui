#!/usr/bin/swift

import Foundation

// ANSI color codes
let RED = "\u{001B}[0;31m"
let GREEN = "\u{001B}[0;32m"
let YELLOW = "\u{001B}[0;33m"
let BLUE = "\u{001B}[0;34m"
let RESET = "\u{001B}[0m"

print("\(BLUE)🔍 WebSocket Configuration Verification\(RESET)")
print("\(BLUE)==========================================\(RESET)\n")

// Expected values
let expectedBackendURL = "http://192.168.0.155:3004"
let expectedWebSocketURL = "ws://192.168.0.155:3004/ws"

// Check AppConfig file
print("\(YELLOW)1. Checking AppConfig.swift...\(RESET)")
let appConfigPath = "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/Core/Config/AppConfig.swift"
if let appConfig = try? String(contentsOfFile: appConfigPath) {
    // Check for localhost references
    if appConfig.contains("localhost") || appConfig.contains("127.0.0.1") {
        let localhostCount = appConfig.components(separatedBy: "localhost").count - 1
        let loopbackCount = appConfig.components(separatedBy: "127.0.0.1").count - 1
        print("\(RED)   ❌ Found localhost references: \(localhostCount) occurrences of 'localhost', \(loopbackCount) occurrences of '127.0.0.1'\(RESET)")
    } else {
        print("\(GREEN)   ✅ No localhost references found\(RESET)")
    }
    
    // Check for correct backend URL
    if appConfig.contains("192.168.0.155:3004") {
        print("\(GREEN)   ✅ Correct backend URL found (192.168.0.155:3004)\(RESET)")
    } else {
        print("\(RED)   ❌ Backend URL not set to 192.168.0.155:3004\(RESET)")
    }
} else {
    print("\(RED)   ❌ Could not read AppConfig.swift\(RESET)")
}

// Check WebSocketManager
print("\n\(YELLOW)2. Checking WebSocketManager.swift...\(RESET)")
let wsManagerPath = "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/Core/Network/WebSocketManager.swift"
if let wsManager = try? String(contentsOfFile: wsManagerPath) {
    // Check for mock/fake references
    if wsManager.contains("USE_MOCK") || wsManager.contains("useMock") || wsManager.contains("fakeConnection") {
        print("\(RED)   ❌ Found mock/fake connection references\(RESET)")
    } else {
        print("\(GREEN)   ✅ No mock/fake connection code\(RESET)")
    }
    
    // Check for AppConfig usage
    if wsManager.contains("AppConfig.websocketURL") || wsManager.contains("AppConfig.shellWebSocketURL") {
        print("\(GREEN)   ✅ Using AppConfig for WebSocket URLs\(RESET)")
    } else {
        print("\(YELLOW)   ⚠️ May not be using AppConfig for URLs\(RESET)")
    }
} else {
    print("\(RED)   ❌ Could not read WebSocketManager.swift\(RESET)")
}

// Check Info.plist
print("\n\(YELLOW)3. Checking Info.plist...\(RESET)")
let infoPlistPath = "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/App/Info.plist"
if let infoPlist = try? String(contentsOfFile: infoPlistPath) {
    if infoPlist.contains("192.168.0.155") {
        print("\(GREEN)   ✅ NSAppTransportSecurity configured for 192.168.0.155\(RESET)")
    } else {
        print("\(RED)   ❌ NSAppTransportSecurity not configured for 192.168.0.155\(RESET)")
    }
    
    if infoPlist.contains("NSAllowsArbitraryLoads") {
        print("\(GREEN)   ✅ NSAllowsArbitraryLoads enabled (fallback for HTTP)\(RESET)")
    }
} else {
    print("\(RED)   ❌ Could not read Info.plist\(RESET)")
}

// Test actual WebSocket connection
print("\n\(YELLOW)4. Testing WebSocket Connection...\(RESET)")
print("   Attempting to connect to: \(expectedWebSocketURL)")

let url = URL(string: expectedWebSocketURL)!
let session = URLSession(configuration: .default)
let webSocketTask = session.webSocketTask(with: url)

webSocketTask.resume()

let semaphore = DispatchSemaphore(value: 0)
var connectionSuccessful = false

// Send ping to test connection
webSocketTask.sendPing { error in
    if let error = error {
        print("\(RED)   ❌ WebSocket connection failed: \(error.localizedDescription)\(RESET)")
    } else {
        print("\(GREEN)   ✅ WebSocket connection successful!\(RESET)")
        connectionSuccessful = true
    }
    semaphore.signal()
}

// Wait for ping response (5 second timeout)
let timeout = DispatchTime.now() + .seconds(5)
if semaphore.wait(timeout: timeout) == .timedOut {
    print("\(RED)   ❌ WebSocket connection timed out\(RESET)")
}

webSocketTask.cancel(with: .goingAway, reason: nil)

// Summary
print("\n\(BLUE)==========================================\(RESET)")
print("\(BLUE)Summary:\(RESET)")
if connectionSuccessful {
    print("\(GREEN)✅ WebSocket configuration is correct and working!\(RESET)")
    print("\(GREEN)   Backend URL: \(expectedBackendURL)\(RESET)")
    print("\(GREEN)   WebSocket URL: \(expectedWebSocketURL)\(RESET)")
} else {
    print("\(RED)❌ WebSocket configuration needs attention\(RESET)")
    print("\(YELLOW)   Please ensure:\(RESET)")
    print("\(YELLOW)   1. Backend is running at \(expectedBackendURL)\(RESET)")
    print("\(YELLOW)   2. AppConfig uses correct URLs\(RESET)")
    print("\(YELLOW)   3. No mock/fake connection code is active\(RESET)")
}

exit(connectionSuccessful ? 0 : 1)