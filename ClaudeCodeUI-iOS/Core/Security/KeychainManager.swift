//
//  KeychainManager.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-29
//  Provides secure storage for sensitive data using iOS Keychain
//

import Foundation
import Security

/// Manages secure storage of sensitive data in iOS Keychain
final class KeychainManager {
    
    // MARK: - Singleton
    static let shared = KeychainManager()
    
    // MARK: - Properties
    private let serviceName: String
    private let accessGroup: String?
    
    // MARK: - Keys
    enum KeychainKey: String, CaseIterable {
        case authToken = "com.claudecode.authToken"
        case refreshToken = "com.claudecode.refreshToken"
        case userCredentials = "com.claudecode.userCredentials"
        case apiKey = "com.claudecode.apiKey"
        
        var account: String {
            return self.rawValue
        }
    }
    
    // MARK: - Errors
    enum KeychainError: LocalizedError {
        case unhandledError(status: OSStatus)
        case itemNotFound
        case unexpectedData
        case encodingError
        case decodingError
        
        var errorDescription: String? {
            switch self {
            case .unhandledError(let status):
                return "Keychain error: \(status)"
            case .itemNotFound:
                return "Item not found in keychain"
            case .unexpectedData:
                return "Unexpected data format in keychain"
            case .encodingError:
                return "Failed to encode data for keychain"
            case .decodingError:
                return "Failed to decode data from keychain"
            }
        }
    }
    
    // MARK: - Initialization
    private init(serviceName: String = Bundle.main.bundleIdentifier ?? "com.claudecode.ui",
                 accessGroup: String? = nil) {
        self.serviceName = serviceName
        self.accessGroup = accessGroup
    }
    
    // MARK: - Public Methods
    
    /// Saves a string value to the keychain
    /// - Parameters:
    ///   - value: The string value to save
    ///   - key: The key to save the value under
    /// - Throws: KeychainError if the operation fails
    func save(_ value: String, for key: KeychainKey) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingError
        }
        try save(data, for: key)
    }
    
    /// Retrieves a string value from the keychain
    /// - Parameter key: The key to retrieve the value for
    /// - Returns: The string value if found
    /// - Throws: KeychainError if the operation fails
    func getString(for key: KeychainKey) throws -> String? {
        guard let data = try getData(for: key) else {
            return nil
        }
        
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodingError
        }
        
        return string
    }
    
    /// Saves data to the keychain
    /// - Parameters:
    ///   - data: The data to save
    ///   - key: The key to save the data under
    /// - Throws: KeychainError if the operation fails
    func save(_ data: Data, for key: KeychainKey) throws {
        let query = createQuery(for: key)
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        var newItem = query
        newItem[kSecValueData as String] = data
        newItem[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        
        let status = SecItemAdd(newItem as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    /// Retrieves data from the keychain
    /// - Parameter key: The key to retrieve the data for
    /// - Returns: The data if found
    /// - Throws: KeychainError if the operation fails
    func getData(for key: KeychainKey) throws -> Data? {
        var query = createQuery(for: key)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = true
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status != errSecItemNotFound else {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.unexpectedData
        }
        
        return data
    }
    
    /// Deletes an item from the keychain
    /// - Parameter key: The key to delete
    /// - Throws: KeychainError if the operation fails
    func delete(key: KeychainKey) throws {
        let query = createQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    /// Deletes all items from the keychain for this app
    /// - Throws: KeychainError if the operation fails
    func deleteAll() throws {
        for key in KeychainKey.allCases {
            try delete(key: key)
        }
    }
    
    /// Checks if a value exists in the keychain
    /// - Parameter key: The key to check
    /// - Returns: true if the value exists, false otherwise
    func exists(key: KeychainKey) -> Bool {
        var query = createQuery(for: key)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = false
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Convenience Methods
    
    /// Saves the authentication token
    /// - Parameter token: The JWT token to save
    /// - Throws: KeychainError if the operation fails
    func saveAuthToken(_ token: String?) throws {
        if let token = token {
            try save(token, for: .authToken)
        } else {
            try delete(key: .authToken)
        }
    }
    
    /// Retrieves the authentication token
    /// - Returns: The JWT token if found
    /// - Throws: KeychainError if the operation fails
    func getAuthToken() throws -> String? {
        return try getString(for: .authToken)
    }
    
    /// Saves the refresh token
    /// - Parameter token: The refresh token to save
    /// - Throws: KeychainError if the operation fails
    func saveRefreshToken(_ token: String?) throws {
        if let token = token {
            try save(token, for: .refreshToken)
        } else {
            try delete(key: .refreshToken)
        }
    }
    
    /// Retrieves the refresh token
    /// - Returns: The refresh token if found
    /// - Throws: KeychainError if the operation fails
    func getRefreshToken() throws -> String? {
        return try getString(for: .refreshToken)
    }
    
    /// Clears all authentication-related data
    /// - Throws: KeychainError if the operation fails
    func clearAuthenticationData() throws {
        try delete(key: .authToken)
        try delete(key: .refreshToken)
        try delete(key: .userCredentials)
    }
    
    // MARK: - Private Methods
    
    private func createQuery(for key: KeychainKey) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.account
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        return query
    }
}

// MARK: - Codable Support

extension KeychainManager {
    
    /// Saves a Codable object to the keychain
    /// - Parameters:
    ///   - object: The Codable object to save
    ///   - key: The key to save the object under
    /// - Throws: KeychainError if the operation fails
    func saveCodable<T: Codable>(_ object: T, for key: KeychainKey) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        try save(data, for: key)
    }
    
    /// Retrieves a Codable object from the keychain
    /// - Parameters:
    ///   - type: The type of the Codable object
    ///   - key: The key to retrieve the object for
    /// - Returns: The Codable object if found
    /// - Throws: KeychainError if the operation fails
    func getCodable<T: Codable>(_ type: T.Type, for key: KeychainKey) throws -> T? {
        guard let data = try getData(for: key) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
}