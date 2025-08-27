//
//  BiometricAuthManager.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/05.
//

import Foundation
import LocalAuthentication
import UIKit

/// Manages biometric authentication (Face ID/Touch ID) for the app
public class BiometricAuthManager {
    
    // MARK: - Singleton
    
    public static let shared = BiometricAuthManager()
    
    // MARK: - Properties
    
    private var authenticationTimer: Timer?
    private var lastAuthenticationTime: Date?
    private let authenticationTimeout: TimeInterval = 300 // 5 minutes
    
    enum BiometricError: LocalizedError {
        case notAvailable
        case notEnrolled
        case userCancelled
        case authenticationFailed
        case systemCancelled
        case passcodeNotSet
        case unknown(Error?)
        
        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "Biometric authentication is not available on this device"
            case .notEnrolled:
                return "No biometric data is enrolled. Please set up Face ID or Touch ID in Settings"
            case .userCancelled:
                return "Authentication was cancelled by the user"
            case .authenticationFailed:
                return "Biometric authentication failed"
            case .systemCancelled:
                return "Authentication was cancelled by the system"
            case .passcodeNotSet:
                return "Device passcode is not set"
            case .unknown(let error):
                return error?.localizedDescription ?? "An unknown error occurred"
            }
        }
    }
    
    private let context = LAContext()
    private let logger: Logger
    
    init(logger: Logger = .shared) {
        self.logger = logger
    }
    
    /// Check if biometric authentication is available
    var isBiometricAvailable: Bool {
        var error: NSError?
        let available = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        if let error = error {
            logger.debug("Biometric availability check failed: \(error)")
        }
        
        return available
    }
    
    /// The type of biometric authentication available
    var biometricType: String {
        switch context.biometryType {
        case .none:
            return "None"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        @unknown default:
            // Handles future biometric types like .opticID in visionOS
            return "Biometric"
        }
    }
    
    /// Authenticate using biometrics
    func authenticate(reason: String = "Authenticate to access Claude Code UI") async throws {
        logger.info("Starting biometric authentication")
        
        // Check if biometric authentication is available
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error {
                throw mapError(error)
            }
            throw BiometricError.notAvailable
        }
        
        // Perform authentication
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                logger.info("Biometric authentication successful")
            } else {
                logger.error("Biometric authentication failed without error")
                throw BiometricError.authenticationFailed
            }
        } catch let authError as NSError {
            logger.error("Biometric authentication error: \(authError)")
            throw mapError(authError)
        }
    }
    
    /// Authenticate with biometrics or device passcode as fallback
    func authenticateWithPasscodeFallback(reason: String = "Authenticate to access Claude Code UI") async throws {
        logger.info("Starting authentication with passcode fallback")
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            if let error = error {
                throw mapError(error)
            }
            throw BiometricError.notAvailable
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            
            if success {
                logger.info("Authentication successful")
            } else {
                logger.error("Authentication failed without error")
                throw BiometricError.authenticationFailed
            }
        } catch let authError as NSError {
            logger.error("Authentication error: \(authError)")
            throw mapError(authError)
        }
    }
    
    /// Map system errors to our custom errors
    private func mapError(_ error: NSError) -> BiometricError {
        switch error.code {
        case LAError.biometryNotAvailable.rawValue:
            return .notAvailable
        case LAError.biometryNotEnrolled.rawValue:
            return .notEnrolled
        case LAError.userCancel.rawValue:
            return .userCancelled
        case LAError.authenticationFailed.rawValue:
            return .authenticationFailed
        case LAError.systemCancel.rawValue:
            return .systemCancelled
        case LAError.passcodeNotSet.rawValue:
            return .passcodeNotSet
        default:
            return .unknown(error)
        }
    }
    
    /// Reset the authentication context (useful after failed attempts)
    func reset() {
        context.invalidate()
    }
}