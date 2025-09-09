#!/usr/bin/env swift

import Foundation

// Simple WebSocket connection test
class WebSocketTest: NSObject, URLSessionWebSocketDelegate {
    private var webSocketTask: URLSessionWebSocketTask?
    private let session: URLSession
    private let semaphore = DispatchSemaphore(value: 0)
    private var isConnected = false
    
    override init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "ClaudeCodeUI-Test/1.0"
        ]
        self.session = URLSession(configuration: config)
        super.init()
    }
    
    func testConnection(to urlString: String) {
        print("🔌 Testing WebSocket connection to: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        
        print("📡 Connection attempt started...")
        
        // Send ping to verify connection
        webSocketTask?.sendPing { [weak self] error in
            if let error = error {
                print("❌ Ping failed: \(error.localizedDescription)")
                self?.isConnected = false
            } else {
                print("✅ Ping successful - WebSocket CONNECTED!")
                self?.isConnected = true
                
                // Try sending a test message
                self?.sendTestMessage()
            }
            self?.semaphore.signal()
        }
        
        // Wait for connection test
        _ = semaphore.wait(timeout: .now() + 10)
        
        if isConnected {
            print("\n✅ WebSocket connection test PASSED")
        } else {
            print("\n❌ WebSocket connection test FAILED")
        }
        
        // Clean up
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
    
    func sendTestMessage() {
        let message: [String: Any] = [
            "type": "claude-command",
            "command": "Hello from Swift test",
            "options": [
                "projectPath": "/test",
                "sessionId": UUID().uuidString
            ]
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: message),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            
            print("📤 Sending test message...")
            let wsMessage = URLSessionWebSocketTask.Message.string(jsonString)
            
            webSocketTask?.send(wsMessage) { error in
                if let error = error {
                    print("❌ Send failed: \(error)")
                } else {
                    print("✅ Message sent successfully")
                    
                    // Try to receive a response
                    self.receiveMessage()
                }
            }
        }
    }
    
    func receiveMessage() {
        webSocketTask?.receive { result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("📥 Received response: \(text.prefix(200))...")
                case .data(let data):
                    print("📥 Received data: \(data.count) bytes")
                @unknown default:
                    break
                }
            case .failure(let error):
                print("❌ Receive error: \(error)")
            }
        }
    }
}

// Main execution
print("🚀 WebSocket Connection Test")
print("============================\n")

let tester = WebSocketTest()

// Test the real backend
tester.testConnection(to: "ws://192.168.0.155:3004/ws")

print("\n============================")
print("📊 Test Complete")