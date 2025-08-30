//
//  AuthenticationManager.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-29
//  Manages authentication flow and token lifecycle
//

import Foundation

/// Manages authentication state and token lifecycle
@MainActor
final class AuthenticationManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AuthenticationManager()
    
    // MARK: - Published Properties
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUser: User?
    @Published private(set) var authError: AuthenticationError?
    
    // MARK: - Properties
    private let keychainManager = KeychainManager.shared
    private let apiClient = APIClient.shared
    private var tokenRefreshTask: Task<Void, Never>?
    private var tokenExpiryTimer: Timer?
    
    // MARK: - Models
    struct User: Codable {
        let id: Int
        let username: String
        let email: String?
        let createdAt: Date?
    }
    
    struct AuthTokens: Codable {
        let accessToken: String
        let refreshToken: String?
        let expiresIn: TimeInterval?
        let tokenType: String?
        
        var expiryDate: Date? {
            guard let expiresIn = expiresIn else { return nil }
            return Date().addingTimeInterval(expiresIn)
        }
    }
    
    struct LoginCredentials {
        let username: String
        let password: String
    }
    
    // MARK: - Errors
    enum AuthenticationError: LocalizedError {
        case invalidCredentials
        case tokenExpired
        case refreshFailed
        case networkError(Error)
        case keychainError(Error)
        case serverError(String)
        case unauthorized
        
        var errorDescription: String? {
            switch self {
            case .invalidCredentials:
                return "Invalid username or password"
            case .tokenExpired:
                return "Your session has expired. Please log in again."
            case .refreshFailed:
                return "Failed to refresh authentication. Please log in again."
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .keychainError(let error):
                return "Security error: \(error.localizedDescription)"
            case .serverError(let message):
                return "Server error: \(message)"
            case .unauthorized:
                return "You are not authorized to perform this action"
            }
        }
    }
    
    // MARK: - Initialization
    private init() {
        Task {
            await checkAuthenticationStatus()
        }
    }
    
    // MARK: - Public Methods
    
    /// Attempts to log in with the provided credentials
    /// - Parameter credentials: The user's login credentials
    /// - Throws: AuthenticationError if login fails
    func login(with credentials: LoginCredentials) async throws {
        do {
            // Call backend login endpoint
            let loginData = try await apiClient.login(
                username: credentials.username,
                password: credentials.password
            )
            
            // Parse tokens from response
            if let token = loginData["token"] as? String {
                // Save token securely
                try keychainManager.saveAuthToken(token)
                
                // Update API client
                await apiClient.setAuthToken(token)
                
                // Parse user info from token if needed
                if let user = parseUserFromToken(token) {
                    self.currentUser = user
                }
                
                // Update authentication state
                self.isAuthenticated = true
                self.authError = nil
                
                // Setup token refresh if needed
                setupTokenRefresh(for: token)
                
                // Notify WebSocket to reconnect with new token
                NotificationCenter.default.post(
                    name: .authenticationChanged,
                    object: nil,
                    userInfo: ["token": token]
                )
            } else {
                throw AuthenticationError.serverError("Invalid response format")
            }
        } catch let error as AuthenticationError {
            self.authError = error
            throw error
        } catch {
            let authError = AuthenticationError.networkError(error)
            self.authError = authError
            throw authError
        }
    }
    
    /// Logs out the current user
    func logout() async {
        // Cancel token refresh
        tokenRefreshTask?.cancel()
        tokenRefreshTask = nil
        tokenExpiryTimer?.invalidate()
        tokenExpiryTimer = nil
        
        // Clear keychain
        do {
            try keychainManager.clearAuthenticationData()
        } catch {
            print("⚠️ [AuthenticationManager] Failed to clear keychain: \(error)")
        }
        
        // Clear API client token
        await apiClient.setAuthToken(nil)
        
        // Update state
        self.isAuthenticated = false
        self.currentUser = nil
        self.authError = nil
        
        // Notify WebSocket to disconnect
        NotificationCenter.default.post(
            name: .authenticationChanged,
            object: nil,
            userInfo: ["token": NSNull()]
        )
        
        // Call backend logout if needed
        try? await apiClient.logout()
    }
    
    /// Refreshes the authentication token
    /// - Throws: AuthenticationError if refresh fails
    func refreshToken() async throws {
        do {
            // Get refresh token from keychain
            guard let refreshToken = try keychainManager.getRefreshToken() else {
                throw AuthenticationError.refreshFailed
            }
            
            // Call refresh endpoint
            let refreshData = try await apiClient.refreshToken(refreshToken)
            
            if let newToken = refreshData["token"] as? String {
                // Save new token
                try keychainManager.saveAuthToken(newToken)
                
                // Update API client
                await apiClient.setAuthToken(newToken)
                
                // Setup new refresh timer
                setupTokenRefresh(for: newToken)
                
                // Notify WebSocket
                NotificationCenter.default.post(
                    name: .authenticationChanged,
                    object: nil,
                    userInfo: ["token": newToken]
                )
            } else {
                throw AuthenticationError.refreshFailed
            }
        } catch {
            // If refresh fails, user needs to log in again
            await logout()
            throw AuthenticationError.refreshFailed
        }
    }
    
    /// Checks if the user is authenticated and tokens are valid
    func checkAuthenticationStatus() async {
        do {
            // Try to get token from keychain
            if let token = try keychainManager.getAuthToken() {
                // Validate token
                if isTokenValid(token) {
                    // Update API client
                    await apiClient.setAuthToken(token)
                    
                    // Parse user info
                    if let user = parseUserFromToken(token) {
                        self.currentUser = user
                    }
                    
                    self.isAuthenticated = true
                    
                    // Setup token refresh
                    setupTokenRefresh(for: token)
                } else {
                    // Token expired, try to refresh
                    if try keychainManager.getRefreshToken() != nil {
                        try await refreshToken()
                    } else {
                        // No refresh token, need to log in
                        await logout()
                    }
                }
            } else {
                // No token stored
                self.isAuthenticated = false
            }
        } catch {
            print("⚠️ [AuthenticationManager] Failed to check auth status: \(error)")
            self.isAuthenticated = false
        }
    }
    
    /// Gets the current authentication token
    /// - Returns: The JWT token if available
    func getCurrentToken() -> String? {
        return try? keychainManager.getAuthToken()
    }
    
    // MARK: - Private Methods
    
    private func setupTokenRefresh(for token: String) {
        // Cancel existing refresh task
        tokenRefreshTask?.cancel()
        tokenExpiryTimer?.invalidate()
        
        // Parse token expiry
        if let expiryDate = getTokenExpiry(from: token) {
            // Schedule refresh 5 minutes before expiry
            let refreshDate = expiryDate.addingTimeInterval(-300)
            let timeInterval = refreshDate.timeIntervalSinceNow
            
            if timeInterval > 0 {
                tokenExpiryTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
                    Task { @MainActor in
                        do {
                            try await self.refreshToken()
                        } catch {
                            print("⚠️ [AuthenticationManager] Token refresh failed: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    private func isTokenValid(_ token: String) -> Bool {
        // Parse JWT and check expiry
        guard let expiryDate = getTokenExpiry(from: token) else {
            return false
        }
        
        return expiryDate > Date()
    }
    
    private func getTokenExpiry(from token: String) -> Date? {
        // Parse JWT payload
        let segments = token.split(separator: ".")
        guard segments.count == 3,
              let payloadData = Data(base64URLEncoded: String(segments[1])),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let exp = payload["exp"] as? TimeInterval else {
            return nil
        }
        
        return Date(timeIntervalSince1970: exp)
    }
    
    private func parseUserFromToken(_ token: String) -> User? {
        // Parse JWT payload for user info
        let segments = token.split(separator: ".")
        guard segments.count == 3,
              let payloadData = Data(base64URLEncoded: String(segments[1])),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            return nil
        }
        
        return User(
            id: payload["userId"] as? Int ?? 0,
            username: payload["username"] as? String ?? "",
            email: payload["email"] as? String,
            createdAt: nil
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let authenticationChanged = Notification.Name("AuthenticationChanged")
    static let tokenRefreshed = Notification.Name("TokenRefreshed")
    static let authenticationFailed = Notification.Name("AuthenticationFailed")
}

// MARK: - Data Extension for Base64URL

extension Data {
    init?(base64URLEncoded: String) {
        var base64 = base64URLEncoded
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if needed
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        
        self.init(base64Encoded: base64)
    }
}