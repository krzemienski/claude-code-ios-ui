#!/usr/bin/env swift

import Foundation

// Robust WebSocket test with proper connection handling
class WebSocketRobustTester {
    var webSocket: URLSessionWebSocketTask?
    let session: URLSession
    let semaphore = DispatchSemaphore(value: 0)
    var isConnected = false
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    func test() {
        print("🚀 Starting Robust WebSocket Test\n")
        print("=" * 50)
        
        // Test 1: Connection
        testConnection()
        
        // Test 2: Send and receive
        if isConnected {
            testSendReceive()
        }
        
        // Test 3: Streaming
        if isConnected {
            testStreaming()
        }
        
        // Cleanup
        disconnect()
        
        print("\n" + "=" * 50)
        print("✅ All tests complete!")
    }
    
    func testConnection() {
        print("\n📡 Test 1: Connection Test")
        print("-" * 30)
        
        let urlString = "ws://192.168.0.155:3004/ws"
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer test-token-\(UUID().uuidString)", forHTTPHeaderField: "Authorization")
        
        webSocket = session.webSocketTask(with: request)
        webSocket?.resume()
        
        // Start receiving messages immediately
        receiveMessage()
        
        // Test ping
        webSocket?.sendPing { [weak self] error in
            if let error = error {
                print("❌ Ping failed: \(error)")
                self?.isConnected = false
            } else {
                print("✅ Connection established!")
                self?.isConnected = true
            }
            self?.semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + 5)
    }
    
    func testSendReceive() {
        print("\n📨 Test 2: Send/Receive Test")
        print("-" * 30)
        
        let message: [String: Any] = [
            "type": "claude-command",
            "command": "echo 'Hello from iOS'",
            "options": [
                "projectPath": "-Users-nick-Documents-claude-code-ios-ui",
                "cwd": "/Users/nick/Documents/claude-code-ios-ui"
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("❌ Failed to create message")
            return
        }
        
        print("📤 Sending: \(jsonString)")
        
        let wsMessage = URLSessionWebSocketTask.Message.string(jsonString)
        webSocket?.send(wsMessage) { error in
            if let error = error {
                print("❌ Send failed: \(error)")
            } else {
                print("✅ Message sent!")
            }
        }
        
        // Wait for response
        Thread.sleep(forTimeInterval: 2)
    }
    
    func testStreaming() {
        print("\n🌊 Test 3: Streaming Test")
        print("-" * 30)
        
        let message: [String: Any] = [
            "type": "claude-command",
            "command": "Write a simple Swift function that prints hello world",
            "options": [
                "projectPath": "-Users-nick-Documents-claude-code-ios-ui",
                "cwd": "/Users/nick/Documents/claude-code-ios-ui"
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("❌ Failed to create streaming message")
            return
        }
        
        print("📤 Sending Claude query...")
        
        let wsMessage = URLSessionWebSocketTask.Message.string(jsonString)
        webSocket?.send(wsMessage) { error in
            if let error = error {
                print("❌ Stream send failed: \(error)")
            } else {
                print("✅ Stream query sent!")
            }
        }
        
        // Wait for streaming response
        Thread.sleep(forTimeInterval: 5)
    }
    
    func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("📥 Received: \(text.prefix(200))...")
                    
                    // Parse message type
                    if let data = text.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let type = json["type"] as? String {
                        print("   Message type: \(type)")
                        
                        if type == "streaming-start" {
                            print("   🌊 Streaming started")
                        } else if type == "streaming-chunk" || type == "claude-response" {
                            if let content = json["content"] as? String ?? json["chunk"] as? String {
                                print("   📝 Chunk: \(content.prefix(100))...")
                            }
                        } else if type == "streaming-end" || type == "response-end" {
                            print("   🏁 Streaming ended")
                        }
                    }
                    
                case .data(let data):
                    print("📥 Received data: \(data.count) bytes")
                @unknown default:
                    break
                }
                
                // Continue receiving
                self?.receiveMessage()
                
            case .failure(let error):
                if (error as NSError).code != 57 { // Not "Socket is not connected"
                    print("⚠️ Receive error: \(error)")
                    // Try to continue receiving if not disconnected
                    if self?.isConnected == true {
                        self?.receiveMessage()
                    }
                }
            }
        }
    }
    
    func disconnect() {
        print("\n🔌 Disconnecting...")
        isConnected = false
        webSocket?.cancel(with: .goingAway, reason: nil)
        print("✅ Disconnected")
    }
}

// Extension for string multiplication
extension String {
    static func * (lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}

// Run the test
let tester = WebSocketRobustTester()
tester.test()