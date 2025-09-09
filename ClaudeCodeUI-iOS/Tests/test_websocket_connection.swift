#!/usr/bin/env swift

import Foundation

// Simple WebSocket connection test
class WebSocketTester {
    var webSocket: URLSessionWebSocketTask?
    let session = URLSession(configuration: .default)
    
    func testConnection() {
        print("🔌 Testing WebSocket connection to backend...")
        
        // Backend URL - actual running backend
        let urlString = "ws://192.168.0.155:3004/ws"
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: \(urlString)")
            return
        }
        
        print("📡 Connecting to: \(urlString)")
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        
        // Add authentication
        let token = "test-token-\(UUID().uuidString)"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        webSocket = session.webSocketTask(with: request)
        webSocket?.resume()
        
        // Test ping
        let semaphore = DispatchSemaphore(value: 0)
        var pingSuccess = false
        
        webSocket?.sendPing { error in
            if let error = error {
                print("❌ Ping failed: \(error)")
            } else {
                print("✅ Ping successful!")
                pingSuccess = true
            }
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + 5)
        
        if pingSuccess {
            // Try sending a message
            testMessage()
        }
        
        // Close connection
        webSocket?.cancel(with: .goingAway, reason: nil)
    }
    
    func testMessage() {
        print("\n📨 Testing message send/receive...")
        
        let message: [String: Any] = [
            "type": "claude-command",
            "command": "Hello from iOS test",
            "options": [
                "projectPath": "-Users-nick-Documents-claude-code-ios-ui",
                "cwd": "/Users/nick/Documents/claude-code-ios-ui"
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("❌ Failed to create JSON message")
            return
        }
        
        print("📤 Sending: \(jsonString)")
        
        let wsMessage = URLSessionWebSocketTask.Message.string(jsonString)
        let semaphore = DispatchSemaphore(value: 0)
        
        webSocket?.send(wsMessage) { error in
            if let error = error {
                print("❌ Send failed: \(error)")
            } else {
                print("✅ Message sent successfully!")
                
                // Try to receive response
                self.webSocket?.receive { result in
                    switch result {
                    case .success(let message):
                        switch message {
                        case .string(let text):
                            print("📥 Received text: \(text.prefix(200))...")
                        case .data(let data):
                            print("📥 Received data: \(data.count) bytes")
                        @unknown default:
                            break
                        }
                    case .failure(let error):
                        print("❌ Receive failed: \(error)")
                    }
                    semaphore.signal()
                }
            }
        }
        
        _ = semaphore.wait(timeout: .now() + 10)
    }
}

// Run the test
let tester = WebSocketTester()
tester.testConnection()

print("\n✅ Test complete!")