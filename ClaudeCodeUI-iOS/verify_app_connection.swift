#!/usr/bin/env swift

import Foundation

// Test both API and WebSocket endpoints
func testBackendConnection() {
    print("\n🔍 Testing ClaudeCodeUI Backend Connection")
    print("=" * 50)
    
    // Test health endpoint
    testHealthEndpoint()
    
    // Test projects endpoint
    testProjectsEndpoint()
    
    // Test WebSocket
    testWebSocketConnection()
}

func testHealthEndpoint() {
    print("\n1️⃣ Testing Health Endpoint...")
    guard let url = URL(string: "http://192.168.0.155:3004/health") else {
        print("❌ Invalid URL")
        return
    }
    
    let semaphore = DispatchSemaphore(value: 0)
    
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            print("❌ Health check failed: \(error)")
        } else if let data = data, let result = String(data: data, encoding: .utf8) {
            print("✅ Health endpoint: \(result)")
        }
        semaphore.signal()
    }.resume()
    
    semaphore.wait()
}

func testProjectsEndpoint() {
    print("\n2️⃣ Testing Projects Endpoint...")
    guard let url = URL(string: "http://192.168.0.155:3004/api/projects") else {
        print("❌ Invalid URL")
        return
    }
    
    let semaphore = DispatchSemaphore(value: 0)
    
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            print("❌ Projects fetch failed: \(error)")
        } else if let data = data, let result = String(data: data, encoding: .utf8) {
            print("✅ Projects endpoint: \(result)")
        }
        semaphore.signal()
    }.resume()
    
    semaphore.wait()
}

func testWebSocketConnection() {
    print("\n3️⃣ Testing WebSocket Connection...")
    
    guard let url = URL(string: "ws://192.168.0.155:3004/ws") else {
        print("❌ Invalid WebSocket URL")
        return
    }
    
    let semaphore = DispatchSemaphore(value: 0)
    
    let session = URLSession(configuration: .default)
    let webSocketTask = session.webSocketTask(with: url)
    webSocketTask.resume()
    
    webSocketTask.sendPing { error in
        if let error = error {
            print("❌ WebSocket ping failed: \(error)")
        } else {
            print("✅ WebSocket connected and responding!")
        }
        semaphore.signal()
    }
    
    semaphore.wait()
}

extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}

// Run tests
testBackendConnection()

print("\n✨ Connection test complete!")
print("\n📱 App Configuration:")
print("   Backend URL: http://192.168.0.155:3004")
print("   WebSocket URL: ws://192.168.0.155:3004/ws")
print("\n🎯 Next Steps:")
print("1. Open the ClaudeCodeUI app in the simulator")
print("2. Check if projects are loading")
print("3. Try creating a new project")
print("4. Send a message in the chat")