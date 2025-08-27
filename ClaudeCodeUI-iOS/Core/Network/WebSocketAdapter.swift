//
//  WebSocketAdapter.swift
//  ClaudeCodeUI
//
//  Created by Claude on 2025-01-15.
//
//  Adapter to make existing WebSocketManager compatible with WebSocketProtocol
//

import Foundation

// MARK: - WebSocket Manager Wrapper

/// Wrapper class to properly adapt WebSocketManager to WebSocketProtocol
final class LegacyWebSocketAdapter: WebSocketProtocol {
    
    private let webSocketManager: WebSocketManager
    
    weak var delegate: WebSocketManagerDelegate? {
        get { return webSocketManager.delegate }
        set { webSocketManager.delegate = newValue }
    }
    
    var isConnected: Bool {
        return webSocketManager.isConnected
    }
    
    init() {
        self.webSocketManager = WebSocketManager()
    }
    
    func connect(to endpoint: String, with token: String?) {
        let baseURL = "ws://localhost:3004"
        let fullURL = "\(baseURL)\(endpoint)"
        
        var finalURL = fullURL
        if let token = token {
            let separator = fullURL.contains("?") ? "&" : "?"
            finalURL = "\(fullURL)\(separator)token=\(token)"
        }
        
        webSocketManager.connect(to: finalURL)
    }
    
    func disconnect() {
        webSocketManager.disconnect()
    }
    
    func send(_ message: String) {
        if let data = message.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            webSocketManager.sendRawMessage(json)
        }
    }
    
    func sendData(_ data: Data) {
        if let string = String(data: data, encoding: .utf8) {
            webSocketManager.sendRawText(string)
        }
    }
}

// MARK: - Updated WebSocket Factory

extension WebSocketFactory {
    
    /// Create WebSocket manager with proper type
    static func create() -> WebSocketProtocol {
        // StarscreamWebSocketManager requires Starscream library to be imported
        // For now, always use legacy adapter
        /*
        if FeatureFlag.useStarscreamWebSocket.isEnabled {
            logInfo("Creating Starscream WebSocket", category: "WebSocketFactory")
            return StarscreamWebSocketManager()
        } else {
        */
        logInfo("Creating legacy WebSocket adapter", category: "WebSocketFactory")
        return LegacyWebSocketAdapter()
        // }
    }
    
    /// Migrate existing WebSocketManager to protocol-based implementation
    static func migrate(from oldManager: WebSocketManager) -> WebSocketProtocol {
        // Disconnect old manager
        oldManager.disconnect()
        
        // Create new manager based on feature flag
        let newManager = create()
        
        // Copy delegate if exists
        newManager.delegate = oldManager.delegate
        
        return newManager
    }
}