//
//  GitModels.swift
//  ClaudeCodeUI
//
//  Created by Claude on 2025-01-15.
//
//  Additional Git integration models for API responses
//  Note: Core Git models are defined in APIClient.swift
//

import Foundation

// MARK: - Additional Git Models not in APIClient.swift

// MARK: - Git Diff Details (Extended)
struct GitDiffDetails: Codable {
    let files: [GitDiffFile]
    let additions: Int
    let deletions: Int
}

struct GitDiffFile: Codable {
    let path: String
    let status: String
    let additions: Int
    let deletions: Int
    let hunks: [GitDiffHunk]
}

struct GitDiffHunk: Codable {
    let oldStart: Int
    let oldLines: Int
    let newStart: Int
    let newLines: Int
    let lines: [GitDiffLine]
}

struct GitDiffLine: Codable {
    let type: String // "add", "del", "normal"
    let content: String
    let oldLineNumber: Int?
    let newLineNumber: Int?
}

// MARK: - Git Commits Response
struct GitCommitsResponse: Codable {
    let success: Bool
    let commits: [GitCommitDetails]?
    let error: String?
}

struct GitCommitDetails: Codable {
    let hash: String
    let abbreviatedHash: String
    let author: String
    let authorEmail: String
    let date: Date
    let message: String
    let parentHashes: [String]
    let refs: [String]?
}

// MARK: - Git Commit Diff Response
struct GitCommitDiffResponse: Codable {
    let success: Bool
    let diff: GitDiffDetails?
    let error: String?
}

// MARK: - Git Remote Status
struct GitRemoteStatusResponse: Codable {
    let success: Bool
    let hasRemote: Bool
    let remoteUrl: String?
    let ahead: Int
    let behind: Int
    let diverged: Bool
    let error: String?
}

// MARK: - Git Operation Response (Extended)
struct GitOperationResult: Codable {
    let success: Bool
    let message: String
    let details: String?
    let affectedFiles: [String]?
}

// MARK: - Terminal Output
struct TerminalOutput: Codable {
    let output: String
    let exitCode: Int
    let error: String?
}