//
//  MCPModels.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-16.
//

import Foundation

// MARK: - MCP Server Model
public struct MCPServer: Identifiable, Codable {
    public let id: String
    public var name: String
    public var url: String
    public var description: String
    public var type: MCPServerType
    public var apiKey: String?
    public var isDefault: Bool
    public var isConnected: Bool
    public var lastConnected: Date?
    public var configuration: [String: String]?
    
    public init(id: String, name: String, url: String, description: String, type: MCPServerType, apiKey: String? = nil, isDefault: Bool = false, isConnected: Bool = false, lastConnected: Date? = nil, configuration: [String: String]? = nil) {
        self.id = id
        self.name = name
        self.url = url
        self.description = description
        self.type = type
        self.apiKey = apiKey
        self.isDefault = isDefault
        self.isConnected = isConnected
        self.lastConnected = lastConnected
        self.configuration = configuration
    }
}

public enum MCPServerType: String, CaseIterable, Codable {
    case rest = "REST API"
    case graphql = "GraphQL"
    case websocket = "WebSocket"
    case grpc = "gRPC"
    
    public var icon: String {
        switch self {
        case .rest: return "cloud"
        case .graphql: return "hexagon"
        case .websocket: return "bolt"
        case .grpc: return "cpu"
        }
    }
}

// MARK: - Connection Test Result
public struct ConnectionTestResult {
    public let success: Bool
    public let message: String
    public let latency: Double?
    
    public init(success: Bool, message: String, latency: Double? = nil) {
        self.success = success
        self.message = message
        self.latency = latency
    }
}