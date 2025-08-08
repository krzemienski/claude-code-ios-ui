//
//  TerminalOutput.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-08.
//

import Foundation

/// Model for terminal command execution output
struct TerminalOutput: Codable {
    let command: String
    let output: String
    let error: String?
    let exitCode: Int
    let timestamp: Date
    
    init(command: String, output: String, error: String? = nil, exitCode: Int = 0) {
        self.command = command
        self.output = output
        self.error = error
        self.exitCode = exitCode
        self.timestamp = Date()
    }
}