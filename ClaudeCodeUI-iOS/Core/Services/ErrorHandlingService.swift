//
//  ErrorHandlingService.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import Foundation
import UIKit

// MARK: - App Error
enum AppError: LocalizedError {
    case network(NetworkError)
    case webSocket(WebSocketError)
    case persistence(PersistenceError)
    case authentication(AuthError)
    case validation(ValidationError)
    case system(SystemError)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .network(let error):
            return error.localizedDescription
        case .webSocket(let error):
            return error.localizedDescription
        case .persistence(let error):
            return error.localizedDescription
        case .authentication(let error):
            return error.localizedDescription
        case .validation(let error):
            return error.localizedDescription
        case .system(let error):
            return error.localizedDescription
        case .unknown(let error):
            return error.localizedDescription
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .network(let error):
            return error.recoverySuggestion
        case .webSocket(let error):
            return error.recoverySuggestion
        case .persistence(let error):
            return error.recoverySuggestion
        case .authentication(let error):
            return error.recoverySuggestion
        case .validation(let error):
            return error.recoverySuggestion
        case .system(let error):
            return error.recoverySuggestion
        case .unknown:
            return "Please try again. If the problem persists, contact support."
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .network(let error):
            return error.isRetryable
        case .webSocket(let error):
            return error.isRetryable
        case .persistence(let error):
            return error.isRetryable
        case .authentication(let error):
            return error.isRetryable
        case .validation:
            return false
        case .system(let error):
            return error.isRetryable
        case .unknown:
            return true
        }
    }
}

// MARK: - Network Error
enum NetworkError: LocalizedError {
    case noConnection
    case timeout
    case serverError(statusCode: Int)
    case invalidRequest
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .serverError(let statusCode):
            return "Server error (code: \(statusCode))"
        case .invalidRequest:
            return "Invalid request"
        case .rateLimited:
            return "Too many requests"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return "Please check your internet connection and try again."
        case .timeout:
            return "The request took too long. Please try again."
        case .serverError:
            return "There's an issue with the server. Please try again later."
        case .invalidRequest:
            return "The request was invalid. Please check your input."
        case .rateLimited:
            return "You've made too many requests. Please wait a moment before trying again."
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .noConnection, .timeout, .serverError, .rateLimited:
            return true
        case .invalidRequest:
            return false
        }
    }
}

// MARK: - Persistence Error
enum PersistenceError: LocalizedError {
    case saveFailed
    case loadFailed
    case deleteFailed
    case migrationFailed
    case diskFull
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save data"
        case .loadFailed:
            return "Failed to load data"
        case .deleteFailed:
            return "Failed to delete data"
        case .migrationFailed:
            return "Failed to migrate data"
        case .diskFull:
            return "Not enough storage space"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .saveFailed, .loadFailed, .deleteFailed:
            return "Please try again. If the problem persists, restart the app."
        case .migrationFailed:
            return "Data migration failed. Please reinstall the app."
        case .diskFull:
            return "Please free up some storage space and try again."
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .saveFailed, .loadFailed, .deleteFailed:
            return true
        case .migrationFailed, .diskFull:
            return false
        }
    }
}

// MARK: - Auth Error
enum AuthError: LocalizedError {
    case invalidCredentials
    case tokenExpired
    case unauthorized
    case biometricFailed
    case biometricNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .tokenExpired:
            return "Session expired"
        case .unauthorized:
            return "Unauthorized access"
        case .biometricFailed:
            return "Biometric authentication failed"
        case .biometricNotAvailable:
            return "Biometric authentication not available"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidCredentials:
            return "Please check your email and password and try again."
        case .tokenExpired:
            return "Your session has expired. Please log in again."
        case .unauthorized:
            return "You don't have permission to access this resource."
        case .biometricFailed:
            return "Please try again or use your password instead."
        case .biometricNotAvailable:
            return "Please set up Face ID or Touch ID in Settings."
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .invalidCredentials, .biometricFailed:
            return true
        case .tokenExpired, .unauthorized, .biometricNotAvailable:
            return false
        }
    }
}

// MARK: - Validation Error
enum ValidationError: LocalizedError {
    case emptyField(fieldName: String)
    case invalidFormat(fieldName: String)
    case tooShort(fieldName: String, minLength: Int)
    case tooLong(fieldName: String, maxLength: Int)
    
    var errorDescription: String? {
        switch self {
        case .emptyField(let fieldName):
            return "\(fieldName) cannot be empty"
        case .invalidFormat(let fieldName):
            return "Invalid \(fieldName) format"
        case .tooShort(let fieldName, let minLength):
            return "\(fieldName) must be at least \(minLength) characters"
        case .tooLong(let fieldName, let maxLength):
            return "\(fieldName) must be at most \(maxLength) characters"
        }
    }
    
    var recoverySuggestion: String? {
        return "Please check your input and try again."
    }
}

// MARK: - System Error
enum SystemError: LocalizedError {
    case fileNotFound
    case permissionDenied
    case outOfMemory
    case crashDetected
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "File not found"
        case .permissionDenied:
            return "Permission denied"
        case .outOfMemory:
            return "Out of memory"
        case .crashDetected:
            return "Previous crash detected"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .fileNotFound:
            return "The requested file could not be found."
        case .permissionDenied:
            return "Please grant the necessary permissions in Settings."
        case .outOfMemory:
            return "Please close other apps and try again."
        case .crashDetected:
            return "The app recovered from a previous crash."
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .fileNotFound, .permissionDenied:
            return false
        case .outOfMemory, .crashDetected:
            return true
        }
    }
}

// MARK: - Error Handling Service
@MainActor
final class ErrorHandlingService {
    
    // MARK: - Singleton
    static let shared = ErrorHandlingService()
    
    // MARK: - Properties
    private var errorHandlers: [String: (AppError) -> Void] = [:]
    private var currentAlert: UIAlertController?
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Error Handling
    func handle(_ error: Error, context: String? = nil, retryAction: (() -> Void)? = nil) {
        let appError = mapToAppError(error)
        
        // Log the error
        logError("[\(context ?? "General")] \(appError.localizedDescription)", category: "ErrorHandling")
        
        // Check for custom handler
        if let context = context, let handler = errorHandlers[context] {
            handler(appError)
            return
        }
        
        // Default handling
        if shouldShowAlert(for: appError) {
            showErrorAlert(appError, retryAction: retryAction)
        }
    }
    
    func registerHandler(for context: String, handler: @escaping (AppError) -> Void) {
        errorHandlers[context] = handler
    }
    
    // MARK: - Private Methods
    private func mapToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        if let apiError = error as? APIError {
            switch apiError {
            case .unauthorized:
                return .authentication(.unauthorized)
            case .httpError(let statusCode, _):
                return .network(.serverError(statusCode: statusCode))
            case .networkError:
                return .network(.noConnection)
            default:
                return .network(.invalidRequest)
            }
        }
        
        if let webSocketError = error as? WebSocketError {
            return .webSocket(webSocketError)
        }
        
        return .unknown(error)
    }
    
    private func shouldShowAlert(for error: AppError) -> Bool {
        // Don't show alerts for certain errors
        switch error {
        case .network(.rateLimited):
            return false
        default:
            return true
        }
    }
    
    private func showErrorAlert(_ error: AppError, retryAction: (() -> Void)?) {
        // Dismiss current alert if any
        currentAlert?.dismiss(animated: false)
        
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        if let suggestion = error.recoverySuggestion {
            alert.message = "\(error.localizedDescription)\n\n\(suggestion)"
        }
        
        // Add retry action if available and error is retryable
        if let retryAction = retryAction, error.isRetryable {
            alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
                retryAction()
            })
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        // Present alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            currentAlert = alert
            rootViewController.present(alert, animated: true)
        }
    }
    
    // MARK: - Crash Reporting
    func setupCrashReporting() {
        // Set up exception handler
        NSSetUncaughtExceptionHandler { exception in
            logCritical("Uncaught exception: \(exception)", category: "Crash")
            logCritical("Stack trace: \(exception.callStackSymbols)", category: "Crash")
            
            // Save crash info for next launch
            UserDefaults.standard.set(true, forKey: "didCrashLastTime")
            UserDefaults.standard.set(Date(), forKey: "lastCrashDate")
            UserDefaults.standard.set(exception.reason, forKey: "lastCrashReason")
        }
        
        // Check for previous crash
        if UserDefaults.standard.bool(forKey: "didCrashLastTime") {
            let crashDate = UserDefaults.standard.object(forKey: "lastCrashDate") as? Date
            let crashReason = UserDefaults.standard.string(forKey: "lastCrashReason")
            
            logWarning("Previous crash detected on \(crashDate?.description ?? "unknown date")", category: "Crash")
            logWarning("Crash reason: \(crashReason ?? "unknown")", category: "Crash")
            
            // Clear crash flag
            UserDefaults.standard.set(false, forKey: "didCrashLastTime")
            
            // Handle crash recovery
            handle(AppError.system(.crashDetected), context: "CrashRecovery")
        }
    }
}

// MARK: - Error Extensions
extension Error {
    var asAppError: AppError {
        return ErrorHandlingService.shared.mapToAppError(self)
    }
}