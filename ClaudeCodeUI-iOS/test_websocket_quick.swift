#!/usr/bin/env swift

import Foundation

class WebSocketTest: NSObject, URLSessionWebSocketDelegate {
    private var webSocketTask: URLSessionWebSocketTask?
    private let session: URLSession
    
    override init() {
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config)
        super.init()
    }
    
    func testConnection() {
        print("🔌 Testing WebSocket connection to ws://192.168.0.155:3004/ws")
        
        guard let url = URL(string: "ws://192.168.0.155:3004/ws") else {
            print("❌ Invalid URL")
            return
        }
        
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Send initial ping
        webSocketTask?.sendPing { error in
            if let error = error {
                print("❌ Ping failed: \(error)")
                exit(1)
            } else {
                print("✅ WebSocket connected successfully!")
                
                // Send a test message
                let testMessage = """
                {
                    "type": "ping",
                    "timestamp": "\(Date())"
                }
                """
                
                let message = URLSessionWebSocketTask.Message.string(testMessage)
                self.webSocketTask?.send(message) { error in
                    if let error = error {
                        print("❌ Send failed: \(error)")
                    } else {
                        print("✅ Message sent successfully!")
                    }
                    exit(0)
                }
            }
        }
    }
}

let tester = WebSocketTest()
tester.testConnection()

// Keep the script running
RunLoop.current.run(until: Date(timeIntervalSinceNow: 5))