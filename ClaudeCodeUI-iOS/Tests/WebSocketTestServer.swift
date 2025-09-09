//
//  WebSocketTestServer.swift
//  ClaudeCodeUI
//
//  Local WebSocket echo server for testing and debugging
//

import Foundation
import Network

/// Local WebSocket echo server for testing
class WebSocketTestServer {
    
    // MARK: - Properties
    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private let port: NWEndpoint.Port
    private var isRunning = false
    private let queue = DispatchQueue(label: "com.claudecode.websocket.testserver")
    
    // Configuration
    var enableStreamingSimulation = true
    var streamingDelay: TimeInterval = 0.1
    var enableConnectionLogging = true
    var simulateDisconnection = false
    var disconnectionDelay: TimeInterval = 5.0
    
    // MARK: - Initialization
    init(port: UInt16 = 8765) {
        self.port = NWEndpoint.Port(rawValue: port)!
    }
    
    // MARK: - Server Control
    func start() throws {
        guard !isRunning else { return }
        
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        
        // Configure WebSocket options
        let wsOptions = NWProtocolWebSocket.Options()
        wsOptions.autoReplyPing = true
        parameters.defaultProtocolStack.applicationProtocols.insert(wsOptions, at: 0)
        
        listener = try NWListener(using: parameters, on: port)
        
        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleNewConnection(connection)
        }
        
        listener?.stateUpdateHandler = { [weak self] state in
            self?.handleStateUpdate(state)
        }
        
        listener?.start(queue: queue)
        isRunning = true
        
        log("🚀 WebSocket Test Server started on port \(port)")
    }
    
    func stop() {
        guard isRunning else { return }
        
        connections.forEach { $0.cancel() }
        connections.removeAll()
        listener?.cancel()
        listener = nil
        isRunning = false
        
        log("🛑 WebSocket Test Server stopped")
    }
    
    // MARK: - Connection Handling
    private func handleNewConnection(_ connection: NWConnection) {
        log("📥 New connection from \(connection.endpoint)")
        
        connections.append(connection)
        
        connection.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionStateUpdate(connection, state: state)
        }
        
        connection.start(queue: queue)
        
        // Start receiving messages
        receiveMessage(on: connection)
        
        // Send welcome message
        sendMessage(to: connection, message: [
            "type": "connection",
            "status": "connected",
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "server": "WebSocketTestServer/1.0"
        ])
        
        // Simulate disconnection if enabled
        if simulateDisconnection {
            queue.asyncAfter(deadline: .now() + disconnectionDelay) { [weak self] in
                self?.log("⚠️ Simulating disconnection after \(self?.disconnectionDelay ?? 0)s")
                connection.cancel()
            }
        }
    }
    
    private func handleConnectionStateUpdate(_ connection: NWConnection, state: NWConnection.State) {
        switch state {
        case .ready:
            log("✅ Connection ready: \(connection.endpoint)")
            
        case .failed(let error):
            log("❌ Connection failed: \(error)")
            removeConnection(connection)
            
        case .cancelled:
            log("🚫 Connection cancelled")
            removeConnection(connection)
            
        default:
            break
        }
    }
    
    private func removeConnection(_ connection: NWConnection) {
        connections.removeAll { $0 === connection }
    }
    
    // MARK: - Message Handling
    private func receiveMessage(on connection: NWConnection) {
        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        
        connection.receiveMessage { [weak self] data, context, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                self.log("❌ Receive error: \(error)")
                return
            }
            
            if let data = data, !data.isEmpty {
                self.handleReceivedData(data, from: connection)
            }
            
            // Continue receiving
            if connection.state == .ready {
                self.receiveMessage(on: connection)
            }
        }
    }
    
    private func handleReceivedData(_ data: Data, from connection: NWConnection) {
        guard let message = String(data: data, encoding: .utf8) else {
            log("⚠️ Failed to decode message")
            return
        }
        
        log("📨 Received: \(message.prefix(200))...")
        
        // Parse JSON message
        if let jsonData = message.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            
            // Handle different message types
            if let type = json["type"] as? String {
                switch type {
                case "ping":
                    handlePing(from: connection)
                    
                case "claude-command", "cursor-command":
                    handleCommand(json, from: connection)
                    
                case "abort-session":
                    handleAbort(json, from: connection)
                    
                default:
                    // Echo back with modifications
                    echoMessage(json, to: connection)
                }
            } else {
                // Default echo
                echoMessage(json, to: connection)
            }
        } else {
            // Echo raw text
            sendMessage(to: connection, text: message)
        }
    }
    
    private func handlePing(from connection: NWConnection) {
        sendMessage(to: connection, message: [
            "type": "pong",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ])
    }
    
    private func handleCommand(_ message: [String: Any], from connection: NWConnection) {
        // Simulate streaming response for commands
        if enableStreamingSimulation {
            simulateStreamingResponse(for: message, to: connection)
        } else {
            // Immediate echo
            var response = message
            response["type"] = "response"
            response["status"] = "completed"
            sendMessage(to: connection, message: response)
        }
    }
    
    private func handleAbort(_ message: [String: Any], from connection: NWConnection) {
        sendMessage(to: connection, message: [
            "type": "session-aborted",
            "sessionId": message["sessionId"] as? String ?? "",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ])
    }
    
    private func echoMessage(_ message: [String: Any], to connection: NWConnection) {
        var echo = message
        echo["echo"] = true
        echo["timestamp"] = ISO8601DateFormatter().string(from: Date())
        sendMessage(to: connection, message: echo)
    }
    
    // MARK: - Streaming Simulation
    private func simulateStreamingResponse(for message: [String: Any], to connection: NWConnection) {
        let content = message["content"] as? String ?? message["command"] as? String ?? "Test response"
        let sessionId = message["sessionId"] as? String ?? UUID().uuidString
        
        // Send session created
        sendMessage(to: connection, message: [
            "type": "session-created",
            "sessionId": sessionId,
            "projectPath": message["projectPath"] as? String ?? "/test",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ])
        
        // Simulate streaming chunks
        let chunks = content.split(separator: " ").map(String.init)
        var accumulatedContent = ""
        
        for (index, chunk) in chunks.enumerated() {
            queue.asyncAfter(deadline: .now() + streamingDelay * Double(index + 1)) { [weak self] in
                accumulatedContent += (accumulatedContent.isEmpty ? "" : " ") + chunk
                
                self?.sendMessage(to: connection, message: [
                    "type": "streaming",
                    "content": accumulatedContent,
                    "sessionId": sessionId,
                    "isPartial": true,
                    "timestamp": ISO8601DateFormatter().string(from: Date())
                ])
            }
        }
        
        // Send completion
        queue.asyncAfter(deadline: .now() + streamingDelay * Double(chunks.count + 1)) { [weak self] in
            self?.sendMessage(to: connection, message: [
                "type": "response",
                "content": "Echo: " + content,
                "sessionId": sessionId,
                "status": "completed",
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ])
        }
    }
    
    // MARK: - Message Sending
    private func sendMessage(to connection: NWConnection, message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message, options: []) else {
            log("⚠️ Failed to encode message")
            return
        }
        
        sendMessage(to: connection, data: data)
    }
    
    private func sendMessage(to connection: NWConnection, text: String) {
        guard let data = text.data(using: .utf8) else { return }
        sendMessage(to: connection, data: data)
    }
    
    private func sendMessage(to connection: NWConnection, data: Data) {
        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "WebSocketMessage",
                                                   metadata: [metadata])
        
        connection.send(content: data, contentContext: context, isComplete: true, completion: .contentProcessed { [weak self] error in
            if let error = error {
                self?.log("❌ Send error: \(error)")
            }
        })
    }
    
    // MARK: - State Handling
    private func handleStateUpdate(_ state: NWListener.State) {
        switch state {
        case .ready:
            log("✅ Server ready on port \(port)")
            
        case .failed(let error):
            log("❌ Server failed: \(error)")
            
        case .cancelled:
            log("🚫 Server cancelled")
            
        default:
            break
        }
    }
    
    // MARK: - Logging
    private func log(_ message: String) {
        guard enableConnectionLogging else { return }
        print("[WebSocketTestServer] \(message)")
    }
}

// MARK: - WebSocket Frame Inspector
class WebSocketFrameInspector {
    
    struct Frame {
        let opcode: OpCode
        let payload: Data
        let isFinal: Bool
        let isMasked: Bool
        let timestamp: Date
        
        enum OpCode: UInt8 {
            case continuation = 0x0
            case text = 0x1
            case binary = 0x2
            case close = 0x8
            case ping = 0x9
            case pong = 0xA
        }
    }
    
    private var capturedFrames: [Frame] = []
    private let maxFrames = 100
    
    func captureFrame(_ data: Data, opcode: Frame.OpCode, isFinal: Bool = true, isMasked: Bool = false) {
        let frame = Frame(
            opcode: opcode,
            payload: data,
            isFinal: isFinal,
            isMasked: isMasked,
            timestamp: Date()
        )
        
        capturedFrames.append(frame)
        
        // Limit stored frames
        if capturedFrames.count > maxFrames {
            capturedFrames.removeFirst()
        }
        
        logFrame(frame)
    }
    
    func getFrames() -> [Frame] {
        return capturedFrames
    }
    
    func clearFrames() {
        capturedFrames.removeAll()
    }
    
    private func logFrame(_ frame: Frame) {
        var log = "🔍 WebSocket Frame:"
        log += "\n  OpCode: \(frame.opcode)"
        log += "\n  Final: \(frame.isFinal)"
        log += "\n  Masked: \(frame.isMasked)"
        log += "\n  Payload Size: \(frame.payload.count) bytes"
        
        if frame.opcode == .text,
           let text = String(data: frame.payload, encoding: .utf8) {
            log += "\n  Text: \(text.prefix(200))..."
        }
        
        print(log)
    }
    
    func analyzeFrames() -> String {
        var analysis = "📊 Frame Analysis:\n"
        analysis += "Total Frames: \(capturedFrames.count)\n"
        
        let framesByType = Dictionary(grouping: capturedFrames) { $0.opcode }
        for (opcode, frames) in framesByType {
            analysis += "\(opcode): \(frames.count) frames\n"
        }
        
        if let firstFrame = capturedFrames.first,
           let lastFrame = capturedFrames.last {
            let duration = lastFrame.timestamp.timeIntervalSince(firstFrame.timestamp)
            analysis += "Duration: \(String(format: "%.2f", duration))s\n"
            analysis += "Avg Rate: \(String(format: "%.2f", Double(capturedFrames.count) / duration)) frames/s\n"
        }
        
        return analysis
    }
}