//
//  AppError.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-08.
//

import Foundation

/// Application-wide error types
enum AppError: LocalizedError {
    case network(NetworkError)
    case persistence(PersistenceError)
    case validation(ValidationError)
    case unexpected(String)
    
    var errorDescription: String? {
        switch self {
        case .network(let error):
            return error.localizedDescription
        case .persistence(let error):
            return error.localizedDescription
        case .validation(let error):
            return error.localizedDescription
        case .unexpected(let message):
            return message
        }
    }
}

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingFailed
    case connectionFailed
    case serverError(Int)
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingFailed:
            return "Failed to decode response"
        case .connectionFailed:
            return "Connection failed"
        case .serverError(let code):
            return "Server error: \(code)"
        case .timeout:
            return "Request timed out"
        }
    }
}

enum PersistenceError: LocalizedError {
    case saveFailed
    case loadFailed
    case deleteFailed
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save data"
        case .loadFailed:
            return "Failed to load data"
        case .deleteFailed:
            return "Failed to delete data"
        case .notFound:
            return "Data not found"
        }
    }
}

enum ValidationError: LocalizedError {
    case emptyField(String)
    case invalidFormat(String)
    case outOfRange(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyField(let field):
            return "\(field) cannot be empty"
        case .invalidFormat(let field):
            return "\(field) has invalid format"
        case .outOfRange(let field):
            return "\(field) is out of range"
        }
    }
}