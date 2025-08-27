//
//  CursorModels.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-16.
//
//  NOTE: Cursor integration has been removed from this project.
//  This file provides stub types to avoid compilation errors.
//  All Cursor-related functionality has been deprecated.
//

import Foundation

// MARK: - Cursor Settings Stub
struct CursorSettings: Codable {
    var apiKey: String?
    var model: String = "gpt-4"
    var temperature: Double = 0.7
    var maxTokens: Int = 2000
    var streamResponses: Bool = true
}

// MARK: - Extended Cursor Session
extension CursorSession {
    var title: String {
        return name ?? "Session \(id.prefix(8))"
    }
    
    var messages: [String] {
        // Stub - returns empty array
        return []
    }
    
    var metadata: SessionMetadata? {
        // Stub - returns nil
        return nil
    }
}

struct SessionMetadata: Codable {
    let totalTokens: Int?
    let cost: Double?
    let model: String?
}