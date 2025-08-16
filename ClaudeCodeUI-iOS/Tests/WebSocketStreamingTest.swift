//
//  WebSocketStreamingTest.swift
//  ClaudeCodeUI
//
//  Real-time WebSocket JSON streaming test
//  NO MOCKS - REAL BACKEND RESPONSES ONLY
//

import Foundation
import UIKit

final class WebSocketStreamingTest: NSObject {
    
    private let webSocketManager = WebSocketManager()
    private var streamingBuffer = ""
    private var messageCount = 0
    private var chunkCount = 0
    private let testProjectPath = "/Users/nick/test-project"
    private var testSessionId: String?
    private let startTime = Date()
    
    override init() {
        super.init()
        webSocketManager.delegate = self
    }
    
    func runTest() {
        print("=" * 80)
        print("🚀 WEBSOCKET REAL-TIME JSON STREAMING TEST")
        print("=" * 80)
        print("Backend: http://localhost:3004")
        print("WebSocket: ws://localhost:3004/ws")
        print("Time: \(Date())")
        print("=" * 80)
        
        // Connect to real backend WebSocket
        print("\n📡 Connecting to WebSocket...")
        webSocketManager.connect(to: "ws://localhost:3004/ws")
        
        // Wait for connection then send test command
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.sendTestCommand()
        }
    }
    
    private func sendTestCommand() {
        print("\n📤 Sending claude-command to backend...")
        print("Project Path: \(testProjectPath)")
        
        // Send a real claude-command that will trigger streaming response
        let testMessage = "Write a simple hello world function in Swift with detailed comments"
        
        print("\nJSON Payload being sent:")
        let payload: [String: Any] = [
            "type": "claude-command",
            "content": testMessage,
            "projectPath": testProjectPath,
            "timestamp": ISO8601DateFormatter.shared.string(from: Date())
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
        
        // Send using the real sendClaudeCommand method
        webSocketManager.sendClaudeCommand(
            content: testMessage,
            projectPath: testProjectPath,
            sessionId: testSessionId
        )
        
        print("\n⏳ Waiting for streaming response...")
        print("-" * 80)
    }
    
    private func logReceivedJSON(_ json: [String: Any], raw: String) {
        messageCount += 1
        
        print("\n📥 MESSAGE #\(messageCount) RECEIVED")
        print("Time: +\(String(format: "%.2f", Date().timeIntervalSince(startTime)))s")
        print("Type: \(json["type"] ?? "unknown")")
        
        // Log raw JSON
        print("\nRaw JSON:")
        print(raw)
        
        // Pretty print parsed JSON
        if let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            print("\nParsed JSON:")
            print(prettyString)
        }
        
        // Handle specific message types
        if let type = json["type"] as? String {
            switch type {
            case "session-created":
                if let sessionId = json["sessionId"] as? String {
                    testSessionId = sessionId
                    print("\n✅ Session Created: \(sessionId)")
                }
                
            case "claude-output", "claude-response":
                chunkCount += 1
                print("\n📝 STREAMING CHUNK #\(chunkCount)")
                if let content = json["content"] as? String {
                    streamingBuffer += content
                    print("Content Length: \(content.count) chars")
                    print("Content Preview: \(String(content.prefix(100)))...")
                }
                
            case "tool_use":
                print("\n🔧 TOOL USE DETECTED")
                if let toolName = json["name"] as? String {
                    print("Tool: \(toolName)")
                }
                if let input = json["input"] {
                    print("Input: \(input)")
                }
                
            case "error":
                print("\n❌ ERROR RECEIVED")
                if let error = json["error"] as? String {
                    print("Error: \(error)")
                }
                
            default:
                print("\n📦 Message Type: \(type)")
            }
        }
        
        print("\n" + "-" * 80)
    }
    
    func endTest() {
        let duration = Date().timeIntervalSince(startTime)
        
        print("\n" + "=" * 80)
        print("✅ TEST COMPLETE")
        print("=" * 80)
        print("Duration: \(String(format: "%.2f", duration)) seconds")
        print("Messages Received: \(messageCount)")
        print("Streaming Chunks: \(chunkCount)")
        print("Total Content Length: \(streamingBuffer.count) chars")
        
        if !streamingBuffer.isEmpty {
            print("\n📄 COMPLETE STREAMED CONTENT:")
            print(streamingBuffer)
        }
        
        print("\n" + "=" * 80)
        
        // Disconnect
        webSocketManager.disconnect()
    }
}

// MARK: - WebSocketManagerDelegate

extension WebSocketStreamingTest: WebSocketManagerDelegate {
    
    func webSocketDidConnect(_ manager: any WebSocketProtocol) {
        print("\n✅ WebSocket CONNECTED to real backend")
        print("Ready to receive real-time JSON streaming")
    }
    
    func webSocketDidDisconnect(_ manager: any WebSocketProtocol, error: Error?) {
        print("\n⚠️ WebSocket DISCONNECTED")
        if let error = error {
            print("Error: \(error)")
        }
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveMessage message: WebSocketMessage) {
        // Log structured WebSocketMessage
        print("\n🔵 WebSocketMessage Received")
        print("Type: \(message.type.rawValue)")
        if let payload = message.payload {
            logReceivedJSON(payload, raw: "WebSocketMessage payload")
        }
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveText text: String) {
        // Log raw text message (real JSON from backend)
        print("\n🟢 RAW TEXT RECEIVED FROM BACKEND")
        print("Length: \(text.count) chars")
        
        // Try to parse as JSON
        if let data = text.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            logReceivedJSON(json, raw: text)
        } else {
            print("Raw Text (not JSON):")
            print(text)
        }
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveData data: Data) {
        print("\n🔴 BINARY DATA Received: \(data.count) bytes")
    }
    
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState) {
        print("\n🔄 Connection State: \(state)")
    }
}

// MARK: - Test Runner

extension WebSocketStreamingTest {
    static func runLiveTest() {
        let test = WebSocketStreamingTest()
        test.runTest()
        
        // Run test for 30 seconds then end
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
            test.endTest()
        }
    }
}

// Helper for string multiplication
fileprivate func *(string: String, count: Int) -> String {
    return String(repeating: string, count: count)
}

// ISO8601DateFormatter extension
fileprivate extension ISO8601DateFormatter {
    static let shared: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}