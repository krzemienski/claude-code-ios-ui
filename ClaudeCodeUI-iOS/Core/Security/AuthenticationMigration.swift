//
//  AuthenticationMigration.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-29
//  Migrates authentication tokens from UserDefaults to secure Keychain storage
//

import Foundation

/// Handles migration of authentication data from insecure to secure storage
final class AuthenticationMigration {
    
    // MARK: - Properties
    private static let migrationKey = "com.claudecode.auth.migrated"
    private static let legacyTokenKey = "authToken"
    private static let legacyRefreshTokenKey = "refreshToken"
    
    // MARK: - Public Methods
    
    /// Performs one-time migration of authentication tokens from UserDefaults to Keychain
    /// This should be called once during app startup
    static func performMigrationIfNeeded() {
        // Check if migration has already been performed
        guard !UserDefaults.standard.bool(forKey: migrationKey) else {
            print("🔐 [AuthMigration] Migration already completed")
            return
        }
        
        print("🔄 [AuthMigration] Starting authentication token migration...")
        
        var migrationSuccess = true
        var migratedItems = 0
        
        // Migrate auth token
        if let legacyToken = UserDefaults.standard.string(forKey: legacyTokenKey) {
            do {
                try KeychainManager.shared.saveAuthToken(legacyToken)
                print("✅ [AuthMigration] Successfully migrated auth token to Keychain")
                
                // Remove from UserDefaults after successful migration
                UserDefaults.standard.removeObject(forKey: legacyTokenKey)
                migratedItems += 1
            } catch {
                print("⚠️ [AuthMigration] Failed to migrate auth token: \(error)")
                migrationSuccess = false
            }
        }
        
        // Migrate refresh token if it exists
        if let legacyRefreshToken = UserDefaults.standard.string(forKey: legacyRefreshTokenKey) {
            do {
                try KeychainManager.shared.saveRefreshToken(legacyRefreshToken)
                print("✅ [AuthMigration] Successfully migrated refresh token to Keychain")
                
                // Remove from UserDefaults after successful migration
                UserDefaults.standard.removeObject(forKey: legacyRefreshTokenKey)
                migratedItems += 1
            } catch {
                print("⚠️ [AuthMigration] Failed to migrate refresh token: \(error)")
                migrationSuccess = false
            }
        }
        
        // Clean up any other sensitive data that might be in UserDefaults
        cleanupLegacyData()
        
        // Mark migration as complete only if successful
        if migrationSuccess {
            UserDefaults.standard.set(true, forKey: migrationKey)
            print("🎉 [AuthMigration] Migration completed successfully. Migrated \(migratedItems) items.")
        } else {
            print("⚠️ [AuthMigration] Migration completed with errors. Will retry on next launch.")
        }
        
        // Synchronize UserDefaults to ensure changes are persisted
        UserDefaults.standard.synchronize()
    }
    
    /// Forces a re-migration (useful for debugging or recovery)
    static func resetMigration() {
        UserDefaults.standard.removeObject(forKey: migrationKey)
        UserDefaults.standard.synchronize()
        print("🔄 [AuthMigration] Migration reset. Will re-run on next launch.")
    }
    
    /// Checks if migration has been completed
    static var isMigrationComplete: Bool {
        return UserDefaults.standard.bool(forKey: migrationKey)
    }
    
    // MARK: - Private Methods
    
    private static func cleanupLegacyData() {
        // List of keys that might contain sensitive data
        let sensitiveKeys = [
            "userPassword",
            "apiKey",
            "secretKey",
            "privateKey",
            "sessionToken",
            "accessToken",
            "bearerToken"
        ]
        
        for key in sensitiveKeys {
            if UserDefaults.standard.object(forKey: key) != nil {
                UserDefaults.standard.removeObject(forKey: key)
                print("🧹 [AuthMigration] Removed legacy sensitive data for key: \(key)")
            }
        }
    }
    
    /// Validates that migration was successful by checking Keychain
    static func validateMigration() -> Bool {
        do {
            // Check if we can retrieve token from Keychain
            let keychainToken = try KeychainManager.shared.getAuthToken()
            
            // Check that UserDefaults no longer contains the token
            let userDefaultsToken = UserDefaults.standard.string(forKey: legacyTokenKey)
            
            // Migration is valid if token exists in Keychain but not in UserDefaults
            let isValid = keychainToken != nil && userDefaultsToken == nil
            
            if isValid {
                print("✅ [AuthMigration] Migration validation successful")
            } else {
                print("⚠️ [AuthMigration] Migration validation failed")
                if keychainToken == nil {
                    print("  - No token found in Keychain")
                }
                if userDefaultsToken != nil {
                    print("  - Token still exists in UserDefaults")
                }
            }
            
            return isValid
        } catch {
            print("⚠️ [AuthMigration] Migration validation error: \(error)")
            return false
        }
    }
}