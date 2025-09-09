//
//  WebSocketMonitor.swift
//  ClaudeCodeUIIntegrationTests
//
//  WebSocket monitoring and debugging tool for real-time connection analysis
//

import Foundation
@testable import ClaudeCodeUI

/// WebSocket monitoring tool for debugging and performance analysis
class WebSocketMonitor {
    
    // MARK: - Frame Tracking
    
    struct Frame {
        let timestamp: Date
        let direction: Direction
        let type: FrameType
        let size: Int
        let content: String?
        
        enum Direction {
            case sent
            case received
        }
        
        enum FrameType {
            case text
            case binary
            case ping
            case pong
            case close
            case unknown
        }
    }
    
    // MARK: - Connection Metrics
    
    struct ConnectionMetrics {
        var connectTime: Date?
        var disconnectTime: Date?
        var connectionDuration: TimeInterval {
            guard let connect = connectTime else { return 0 }
            let disconnect = disconnectTime ?? Date()
            return disconnect.timeIntervalSince(connect)
        }
        
        var framesSent: Int = 0
        var framesReceived: Int = 0
        var bytesSent: Int = 0
        var bytesReceived: Int = 0
        
        var reconnectAttempts: Int = 0
        var successfulReconnects: Int = 0
        
        var lastPingTime: Date?
        var lastPongTime: Date?
        var pingLatency: TimeInterval? {
            guard let ping = lastPingTime, let pong = lastPongTime else { return nil }
            return pong.timeIntervalSince(ping)
        }
        
        var stateChanges: [(state: WebSocketConnectionState, timestamp: Date)] = []
        
        func generateReport() -> String {
            var report = """
            ========== WebSocket Connection Metrics ==========
            Connection Duration: \(String(format: "%.2f", connectionDuration)) seconds
            
            === Frame Statistics ===
            Frames Sent: \(framesSent)
            Frames Received: \(framesReceived)
            Bytes Sent: \(bytesSent)
            Bytes Received: \(bytesReceived)
            
            === Reconnection Stats ===
            Reconnect Attempts: \(reconnectAttempts)
            Successful Reconnects: \(successfulReconnects)
            Success Rate: \(reconnectAttempts > 0 ? String(format: "%.1f%%", Double(successfulReconnects) / Double(reconnectAttempts) * 100) : "N/A")
            
            === Latency ===
            Ping Latency: \(pingLatency != nil ? String(format: "%.2fms", pingLatency! * 1000) : "N/A")
            
            === State History ===
            """
            
            for change in stateChanges {
                report += "\n[\(ISO8601DateFormatter.shared.string(from: change.timestamp))] -> \(change.state)"
            }
            
            report += "\n=================================================="
            
            return report
        }
    }
    
    // MARK: - Properties
    
    private var frames: [Frame] = []
    private var metrics = ConnectionMetrics()
    private let maxFramesToStore = 1000
    
    private let webSocketManager: WebSocketManager
    private var originalDelegate: WebSocketManagerDelegate?
    
    // MARK: - Initialization
    
    init(webSocketManager: WebSocketManager) {
        self.webSocketManager = webSocketManager
        self.originalDelegate = webSocketManager.delegate
        installMonitor()
    }
    
    deinit {
        // Restore original delegate
        webSocketManager.delegate = originalDelegate
    }
    
    // MARK: - Monitoring
    
    private func installMonitor() {
        // Create intercepting delegate
        let interceptor = MonitoringDelegate(
            monitor: self,
            originalDelegate: originalDelegate
        )
        webSocketManager.delegate = interceptor
    }
    
    func startMonitoring() {
        print("\n🔍 WebSocket Monitor Started")
        print("📊 Monitoring connection to: ws://192.168.0.155:3004/ws")
        metrics = ConnectionMetrics()
        frames.removeAll()
    }
    
    func stopMonitoring() -> String {
        print("\n🛑 WebSocket Monitor Stopped")
        return metrics.generateReport()
    }
    
    // MARK: - Frame Recording
    
    func recordSentFrame(type: Frame.FrameType, content: String?, size: Int) {
        let frame = Frame(
            timestamp: Date(),
            direction: .sent,
            type: type,
            size: size,
            content: content
        )
        
        frames.append(frame)
        if frames.count > maxFramesToStore {
            frames.removeFirst()
        }
        
        metrics.framesSent += 1
        metrics.bytesSent += size
        
        if type == .ping {
            metrics.lastPingTime = Date()
        }
        
        print("📤 [SENT] \(type) - \(size) bytes")
        if let content = content {
            print("   Content: \(content.prefix(200))")
        }
    }
    
    func recordReceivedFrame(type: Frame.FrameType, content: String?, size: Int) {
        let frame = Frame(
            timestamp: Date(),
            direction: .received,
            type: type,
            size: size,
            content: content
        )
        
        frames.append(frame)
        if frames.count > maxFramesToStore {
            frames.removeFirst()
        }
        
        metrics.framesReceived += 1
        metrics.bytesReceived += size
        
        if type == .pong {
            metrics.lastPongTime = Date()
        }
        
        print("📥 [RECEIVED] \(type) - \(size) bytes")
        if let content = content {
            print("   Content: \(content.prefix(200))")
        }
    }
    
    func recordStateChange(_ state: WebSocketConnectionState) {
        metrics.stateChanges.append((state, Date()))
        
        switch state {
        case .connected:
            if metrics.connectTime != nil {
                metrics.successfulReconnects += 1
            }
            metrics.connectTime = Date()
            metrics.disconnectTime = nil
            
        case .disconnected, .failed:
            metrics.disconnectTime = Date()
            
        case .reconnecting:
            metrics.reconnectAttempts += 1
            
        default:
            break
        }
    }
    
    // MARK: - Analysis
    
    func getRecentFrames(count: Int = 20) -> [Frame] {
        return Array(frames.suffix(count))
    }
    
    func getFramesByType(_ type: Frame.FrameType) -> [Frame] {
        return frames.filter { $0.type == type }
    }
    
    func getAverageFrameSize() -> Double {
        guard !frames.isEmpty else { return 0 }
        let totalSize = frames.reduce(0) { $0 + $1.size }
        return Double(totalSize) / Double(frames.count)
    }
    
    func getMessageRate() -> Double {
        guard let connectTime = metrics.connectTime else { return 0 }
        let duration = Date().timeIntervalSince(connectTime)
        guard duration > 0 else { return 0 }
        return Double(metrics.framesReceived) / duration
    }
    
    func exportFrameLog() -> String {
        var log = "WebSocket Frame Log\n"
        log += "==================\n\n"
        
        for frame in frames {
            let timestamp = ISO8601DateFormatter.shared.string(from: frame.timestamp)
            let arrow = frame.direction == .sent ? "→" : "←"
            log += "[\(timestamp)] \(arrow) \(frame.type) (\(frame.size) bytes)\n"
            if let content = frame.content {
                log += "  \(content.prefix(100))\n"
            }
            log += "\n"
        }
        
        return log
    }
}

// MARK: - Monitoring Delegate

private class MonitoringDelegate: NSObject, WebSocketManagerDelegate {
    
    weak var monitor: WebSocketMonitor?
    weak var originalDelegate: WebSocketManagerDelegate?
    
    init(monitor: WebSocketMonitor, originalDelegate: WebSocketManagerDelegate?) {
        self.monitor = monitor
        self.originalDelegate = originalDelegate
        super.init()
    }
    
    func webSocketDidConnect(_ manager: any WebSocketProtocol) {
        monitor?.recordStateChange(.connected)
        originalDelegate?.webSocketDidConnect(manager)
    }
    
    func webSocketDidDisconnect(_ manager: any WebSocketProtocol, error: Error?) {
        monitor?.recordStateChange(.disconnected)
        originalDelegate?.webSocketDidDisconnect(manager, error: error)
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveMessage message: WebSocketMessage) {
        // Record the message frame
        if let payload = message.payload,
           let data = try? JSONSerialization.data(withJSONObject: payload),
           let content = String(data: data, encoding: .utf8) {
            monitor?.recordReceivedFrame(type: .text, content: content, size: data.count)
        }
        
        originalDelegate?.webSocket(manager, didReceiveMessage: message)
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveText text: String) {
        monitor?.recordReceivedFrame(
            type: .text,
            content: text,
            size: text.data(using: .utf8)?.count ?? 0
        )
        originalDelegate?.webSocket(manager, didReceiveText: text)
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveData data: Data) {
        monitor?.recordReceivedFrame(type: .binary, content: nil, size: data.count)
        originalDelegate?.webSocket(manager, didReceiveData: data)
    }
    
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState) {
        monitor?.recordStateChange(state)
        originalDelegate?.webSocketConnectionStateChanged(state)
    }
}

// MARK: - WebSocket Extensions for Monitoring

extension WebSocketManager {
    
    /// Create a monitor for this WebSocket manager
    func createMonitor() -> WebSocketMonitor {
        return WebSocketMonitor(webSocketManager: self)
    }
    
    /// Send a ping frame for latency measurement
    func sendPingFrame() {
        // This would need to be implemented in WebSocketManager
        // For now, we can send a ping message
        sendRawMessage(["type": "ping", "timestamp": Date().timeIntervalSince1970])
    }
}