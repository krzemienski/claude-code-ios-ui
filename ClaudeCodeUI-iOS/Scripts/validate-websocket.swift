#!/usr/bin/env swift

import Foundation

// Enhanced WebSocket validation script with proper message formatting
class WebSocketValidator: NSObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private let semaphore = DispatchSemaphore(value: 0)
    private var messageCount = 0
    private var isConnected = false
    
    func validate() {
        let urlString = "ws://192.168.0.155:3004/ws"
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            return
        }
        
        print("🔌 Connecting to WebSocket at \(urlString)...")
        print("📝 Testing WebSocket message protocol...")
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Start receiving messages immediately
        receiveMessage()
        
        // Send ping to verify connection
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            self.sendPing()
        }
        
        // Send properly formatted test messages after connection
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            self.sendTestMessages()
        }
        
        // Wait for 10 seconds to receive responses
        DispatchQueue.global().asyncAfter(deadline: .now() + 10.0) {
            self.close()
        }
        
        // Wait for completion
        semaphore.wait()
    }
    
    private func sendPing() {
        webSocketTask?.sendPing { error in
            if let error = error {
                print("❌ Ping failed: \(error)")
            } else {
                print("✅ Ping successful - connection verified!")
                self.isConnected = true
            }
        }
    }
    
    private func sendTestMessages() {
        print("\n📤 Sending test messages...")
        
        // Test 1: Simple text message (raw)
        let simpleMessage = "Hello from iOS WebSocket validator"
        let message1 = URLSessionWebSocketTask.Message.string(simpleMessage)
        webSocketTask?.send(message1) { error in
            if let error = error {
                print("❌ Failed to send simple message: \(error)")
            } else {
                print("✅ Sent simple text message")
            }
        }
        
        // Wait a bit between messages
        Thread.sleep(forTimeInterval: 0.5)
        
        // Test 2: JSON formatted message (what the backend expects)
        let jsonMessage: [String: Any] = [
            "type": "claude-command",
            "command": "What is 2+2?",
            "options": [
                "projectPath": "/test/project",
                "sessionId": UUID().uuidString,
                "resume": false,
                "cwd": "/test/project"
            ]
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonMessage),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📝 Sending JSON message: \(jsonString)")
            let message2 = URLSessionWebSocketTask.Message.string(jsonString)
            webSocketTask?.send(message2) { error in
                if let error = error {
                    print("❌ Failed to send JSON message: \(error)")
                } else {
                    print("✅ Sent JSON formatted message")
                }
            }
        }
        
        // Wait a bit
        Thread.sleep(forTimeInterval: 0.5)
        
        // Test 3: Session creation message
        let sessionMessage: [String: Any] = [
            "type": "create-session",
            "projectPath": "/test/project"
        ]
        
        if let sessionData = try? JSONSerialization.data(withJSONObject: sessionMessage),
           let sessionString = String(data: sessionData, encoding: .utf8) {
            print("📝 Sending session creation: \(sessionString)")
            let message3 = URLSessionWebSocketTask.Message.string(sessionString)
            webSocketTask?.send(message3) { error in
                if let error = error {
                    print("❌ Failed to send session message: \(error)")
                } else {
                    print("✅ Sent session creation message")
                }
            }
        }
        
        // Test 4: Chat-style message
        Thread.sleep(forTimeInterval: 0.5)
        let chatMessage: [String: Any] = [
            "type": "message",
            "content": "Test chat message",
            "projectPath": "/test/project",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        if let chatData = try? JSONSerialization.data(withJSONObject: chatMessage),
           let chatString = String(data: chatData, encoding: .utf8) {
            print("📝 Sending chat message: \(chatString)")
            let message4 = URLSessionWebSocketTask.Message.string(chatString)
            webSocketTask?.send(message4) { error in
                if let error = error {
                    print("❌ Failed to send chat message: \(error)")
                } else {
                    print("✅ Sent chat message")
                }
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.messageCount += 1
                switch message {
                case .string(let text):
                    print("\n📥 Message #\(self?.messageCount ?? 0) received:")
                    
                    // Try to parse as JSON
                    if let data = text.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("   Type: \(json["type"] ?? "unknown")")
                        if let content = json["content"] as? String {
                            let preview = String(content.prefix(200))
                            print("   Content: \(preview)")
                            if content.count > 200 {
                                print("   ... (truncated from \(content.count) chars)")
                            }
                        }
                        if let error = json["error"] as? String {
                            print("   ⚠️ Error: \(error)")
                        }
                        if let sessionId = json["sessionId"] as? String {
                            print("   Session ID: \(sessionId)")
                        }
                    } else {
                        // Raw text message
                        let preview = String(text.prefix(500))
                        print("   Raw text: \(preview)")
                        if text.count > 500 {
                            print("   ... (truncated from \(text.count) chars)")
                        }
                    }
                    
                    // Check for streaming response pattern
                    if text.contains("```") || text.contains("streaming") {
                        print("   🌊 Detected streaming response!")
                    }
                    
                case .data(let data):
                    print("📥 Received binary data: \(data.count) bytes")
                    
                @unknown default:
                    break
                }
                // Continue receiving
                self?.receiveMessage()
                
            case .failure(let error):
                print("⚠️ Receive stopped: \(error.localizedDescription)")
            }
        }
    }
    
    private func close() {
        print("\n📊 Final Summary:")
        print("   - Messages received: \(messageCount)")
        print("   - Connection status: \(isConnected ? "Was connected" : "Never fully connected")")
        print("   - Test duration: 10 seconds")
        
        webSocketTask?.cancel(with: .goingAway, reason: "Test completed".data(using: .utf8))
        print("👋 Connection closed gracefully")
        semaphore.signal()
    }
}

extension WebSocketValidator: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ WebSocket connected successfully!")
        print("   Protocol: \(String(describing: `protocol`))")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("🔌 WebSocket closed with code: \(closeCode.rawValue)")
        if let reason = reason, let reasonString = String(data: reason, encoding: .utf8) {
            print("   Reason: \(reasonString)")
        }
    }
}

// Run the validator
let validator = WebSocketValidator()
validator.validate()