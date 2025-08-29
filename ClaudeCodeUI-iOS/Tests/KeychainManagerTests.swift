//
//  KeychainManagerTests.swift
//  ClaudeCodeUITests
//
//  Created on 2025-01-29
//  Unit tests for KeychainManager secure storage
//

import XCTest
@testable import ClaudeCodeUI

final class KeychainManagerTests: XCTestCase {
    
    // MARK: - Properties
    private let keychainManager = KeychainManager.shared
    private let testToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEsInVzZXJuYW1lIjoidGVzdCIsImV4cCI6MTc1NTIzMjI3Mn0.test_signature"
    private let testRefreshToken = "refresh_token_test_123456789"
    
    // MARK: - Setup/Teardown
    
    override func setUp() {
        super.setUp()
        // Clear any existing test data
        clearAllTestData()
    }
    
    override func tearDown() {
        // Clean up after each test
        clearAllTestData()
        super.tearDown()
    }
    
    private func clearAllTestData() {
        // Clear all authentication data
        try? keychainManager.clearAuthenticationData()
    }
    
    // MARK: - Basic Storage Tests
    
    func testSaveAndRetrieveString() throws {
        // Given
        let testValue = "test_value_123"
        
        // When
        try keychainManager.save(testValue, for: .apiKey)
        let retrieved = try keychainManager.getString(for: .apiKey)
        
        // Then
        XCTAssertEqual(retrieved, testValue)
    }
    
    func testSaveAndRetrieveData() throws {
        // Given
        let testString = "test_data_content"
        let testData = testString.data(using: .utf8)!
        
        // When
        try keychainManager.save(testData, for: .userCredentials)
        let retrieved = try keychainManager.getData(for: .userCredentials)
        
        // Then
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved, testData)
        
        // Verify we can convert back to string
        let retrievedString = String(data: retrieved!, encoding: .utf8)
        XCTAssertEqual(retrievedString, testString)
    }
    
    func testOverwriteExistingValue() throws {
        // Given
        let originalValue = "original"
        let newValue = "updated"
        
        // When - Save original
        try keychainManager.save(originalValue, for: .apiKey)
        let firstRetrieved = try keychainManager.getString(for: .apiKey)
        XCTAssertEqual(firstRetrieved, originalValue)
        
        // When - Overwrite with new value
        try keychainManager.save(newValue, for: .apiKey)
        let secondRetrieved = try keychainManager.getString(for: .apiKey)
        
        // Then
        XCTAssertEqual(secondRetrieved, newValue)
        XCTAssertNotEqual(secondRetrieved, originalValue)
    }
    
    // MARK: - Authentication Token Tests
    
    func testSaveAndRetrieveAuthToken() throws {
        // When
        try keychainManager.saveAuthToken(testToken)
        let retrieved = try keychainManager.getAuthToken()
        
        // Then
        XCTAssertEqual(retrieved, testToken)
    }
    
    func testSaveNilAuthTokenDeletesExisting() throws {
        // Given - Save a token first
        try keychainManager.saveAuthToken(testToken)
        XCTAssertNotNil(try keychainManager.getAuthToken())
        
        // When - Save nil
        try keychainManager.saveAuthToken(nil)
        
        // Then - Token should be deleted
        let retrieved = try keychainManager.getAuthToken()
        XCTAssertNil(retrieved)
    }
    
    func testSaveAndRetrieveRefreshToken() throws {
        // When
        try keychainManager.saveRefreshToken(testRefreshToken)
        let retrieved = try keychainManager.getRefreshToken()
        
        // Then
        XCTAssertEqual(retrieved, testRefreshToken)
    }
    
    // MARK: - Deletion Tests
    
    func testDeleteExistingItem() throws {
        // Given
        try keychainManager.save("test", for: .apiKey)
        XCTAssertTrue(keychainManager.exists(key: .apiKey))
        
        // When
        try keychainManager.delete(key: .apiKey)
        
        // Then
        XCTAssertFalse(keychainManager.exists(key: .apiKey))
        XCTAssertNil(try keychainManager.getString(for: .apiKey))
    }
    
    func testDeleteNonExistentItemDoesNotThrow() {
        // Should not throw when deleting non-existent item
        XCTAssertNoThrow(try keychainManager.delete(key: .apiKey))
    }
    
    func testClearAuthenticationData() throws {
        // Given - Save all authentication data
        try keychainManager.saveAuthToken(testToken)
        try keychainManager.saveRefreshToken(testRefreshToken)
        try keychainManager.save("user_data", for: .userCredentials)
        
        // Verify all exist
        XCTAssertNotNil(try keychainManager.getAuthToken())
        XCTAssertNotNil(try keychainManager.getRefreshToken())
        XCTAssertNotNil(try keychainManager.getString(for: .userCredentials))
        
        // When
        try keychainManager.clearAuthenticationData()
        
        // Then - All authentication data should be cleared
        XCTAssertNil(try keychainManager.getAuthToken())
        XCTAssertNil(try keychainManager.getRefreshToken())
        XCTAssertNil(try keychainManager.getString(for: .userCredentials))
    }
    
    // MARK: - Existence Tests
    
    func testExistsReturnsTrueForExistingItem() throws {
        // Given
        try keychainManager.save("test", for: .apiKey)
        
        // Then
        XCTAssertTrue(keychainManager.exists(key: .apiKey))
    }
    
    func testExistsReturnsFalseForNonExistentItem() {
        // Then
        XCTAssertFalse(keychainManager.exists(key: .apiKey))
    }
    
    // MARK: - Codable Support Tests
    
    struct TestUser: Codable, Equatable {
        let id: Int
        let username: String
        let email: String
    }
    
    func testSaveAndRetrieveCodable() throws {
        // Given
        let testUser = TestUser(id: 1, username: "testuser", email: "test@example.com")
        
        // When
        try keychainManager.saveCodable(testUser, for: .userCredentials)
        let retrieved = try keychainManager.getCodable(TestUser.self, for: .userCredentials)
        
        // Then
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved, testUser)
    }
    
    func testRetrieveNonExistentCodableReturnsNil() throws {
        // When
        let retrieved = try keychainManager.getCodable(TestUser.self, for: .userCredentials)
        
        // Then
        XCTAssertNil(retrieved)
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidDataEncodingThrowsError() {
        // Given - Create a string that can't be encoded (this is contrived since UTF-8 is very permissive)
        // We'll test the error path by trying to decode invalid data instead
        
        // When/Then
        let invalidData = Data([0xFF, 0xFF, 0xFF, 0xFF]) // Invalid UTF-8
        XCTAssertNoThrow(try keychainManager.save(invalidData, for: .apiKey))
        
        // Trying to get as string should fail
        XCTAssertThrowsError(try keychainManager.getString(for: .apiKey)) { error in
            if let keychainError = error as? KeychainManager.KeychainError {
                switch keychainError {
                case .decodingError:
                    // Expected error
                    break
                default:
                    XCTFail("Expected decoding error, got: \(keychainError)")
                }
            } else {
                XCTFail("Expected KeychainError, got: \(error)")
            }
        }
    }
    
    // MARK: - Security Tests
    
    func testTokensAreNotStoredInUserDefaults() throws {
        // Given
        try keychainManager.saveAuthToken(testToken)
        
        // Then - Should NOT be in UserDefaults
        XCTAssertNil(UserDefaults.standard.string(forKey: "authToken"))
    }
    
    func testMultipleKeysDoNotInterfere() throws {
        // Given
        let authToken = "auth_token_123"
        let refreshToken = "refresh_token_456"
        let apiKey = "api_key_789"
        
        // When - Save all
        try keychainManager.saveAuthToken(authToken)
        try keychainManager.saveRefreshToken(refreshToken)
        try keychainManager.save(apiKey, for: .apiKey)
        
        // Then - All should be retrievable independently
        XCTAssertEqual(try keychainManager.getAuthToken(), authToken)
        XCTAssertEqual(try keychainManager.getRefreshToken(), refreshToken)
        XCTAssertEqual(try keychainManager.getString(for: .apiKey), apiKey)
        
        // When - Delete one
        try keychainManager.delete(key: .apiKey)
        
        // Then - Others should remain
        XCTAssertEqual(try keychainManager.getAuthToken(), authToken)
        XCTAssertEqual(try keychainManager.getRefreshToken(), refreshToken)
        XCTAssertNil(try keychainManager.getString(for: .apiKey))
    }
    
    // MARK: - Performance Tests
    
    func testKeychainPerformance() throws {
        measure {
            // Measure average time for save and retrieve operations
            for i in 0..<100 {
                let token = "test_token_\(i)"
                try? keychainManager.saveAuthToken(token)
                _ = try? keychainManager.getAuthToken()
            }
        }
    }
}