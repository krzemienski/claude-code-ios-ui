//
//  SessionPersistenceService.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-15.
//

import Foundation

/// Service responsible for persisting and restoring session state across app launches
final class SessionPersistenceService {
    
    // MARK: - Singleton
    static let shared = SessionPersistenceService()
    
    // MARK: - Constants
    private enum Keys {
        static func currentSessionId(for projectName: String) -> String {
            return "currentSessionId_\(projectName)"
        }
        static let lastActiveProjectName = "lastActiveProjectName"
        static let sessionCache = "sessionCache"
        static let sessionCacheExpiry = "sessionCacheExpiry"
    }
    
    private let cacheExpiryInterval: TimeInterval = 3600 // 1 hour cache
    
    // MARK: - Properties
    private let userDefaults: UserDefaults
    
    // MARK: - Initialization
    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Session Management
    
    /// Store the current session ID for a project
    func setCurrentSession(_ sessionId: String, for projectName: String) {
        userDefaults.set(sessionId, forKey: Keys.currentSessionId(for: projectName))
        userDefaults.set(projectName, forKey: Keys.lastActiveProjectName)
        userDefaults.set(Date(), forKey: "\(Keys.currentSessionId(for: projectName))_timestamp")
    }
    
    /// Get the current session ID for a project
    func getCurrentSessionId(for projectName: String) -> String? {
        return userDefaults.string(forKey: Keys.currentSessionId(for: projectName))
    }
    
    /// Remove the current session ID for a project
    func clearCurrentSession(for projectName: String) {
        userDefaults.removeObject(forKey: Keys.currentSessionId(for: projectName))
        userDefaults.removeObject(forKey: "\(Keys.currentSessionId(for: projectName))_timestamp")
        
        // If this was the last active project, clear that too
        if userDefaults.string(forKey: Keys.lastActiveProjectName) == projectName {
            userDefaults.removeObject(forKey: Keys.lastActiveProjectName)
        }
    }
    
    /// Get the last active project name
    func getLastActiveProjectName() -> String? {
        return userDefaults.string(forKey: Keys.lastActiveProjectName)
    }
    
    /// Get the last active session info (project and session ID)
    func getLastActiveSession() -> (projectName: String, sessionId: String)? {
        guard let projectName = getLastActiveProjectName(),
              let sessionId = getCurrentSessionId(for: projectName) else {
            return nil
        }
        return (projectName, sessionId)
    }
    
    // MARK: - Session Caching
    
    /// Cache session data locally for offline access
    func cacheSession(_ session: Session) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        // Create a cache key specific to this session
        let cacheKey = "\(Keys.sessionCache)_\(session.projectId)_\(session.id)"
        
        // Create a cacheable version of the session
        let cacheableSession = SessionCache(
            id: session.id,
            projectId: session.projectId,
            summary: session.summary,
            messageCount: session.messageCount,
            lastActivity: session.lastActivity,
            cwd: session.cwd,
            status: session.status.rawValue
        )
        
        if let data = try? encoder.encode(cacheableSession) {
            userDefaults.set(data, forKey: cacheKey)
            userDefaults.set(Date(), forKey: "\(cacheKey)_expiry")
        }
    }
    
    /// Retrieve cached session data
    func getCachedSession(projectId: String, sessionId: String) -> Session? {
        let cacheKey = "\(Keys.sessionCache)_\(projectId)_\(sessionId)"
        
        // Check if cache has expired
        if let expiryDate = userDefaults.object(forKey: "\(cacheKey)_expiry") as? Date {
            if Date().timeIntervalSince(expiryDate) > cacheExpiryInterval {
                // Cache expired, remove it
                userDefaults.removeObject(forKey: cacheKey)
                userDefaults.removeObject(forKey: "\(cacheKey)_expiry")
                return nil
            }
        }
        
        guard let data = userDefaults.data(forKey: cacheKey) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let cacheableSession = try? decoder.decode(SessionCache.self, from: data) else {
            return nil
        }
        
        // Convert back to Session object
        return Session(
            id: cacheableSession.id,
            projectId: cacheableSession.projectId,
            summary: cacheableSession.summary,
            messageCount: cacheableSession.messageCount,
            lastActivity: cacheableSession.lastActivity,
            cwd: cacheableSession.cwd,
            status: SessionStatus(rawValue: cacheableSession.status) ?? .active
        )
    }
    
    /// Cache multiple sessions
    func cacheSessions(_ sessions: [Session], for projectName: String) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let cacheKey = "\(Keys.sessionCache)_list_\(projectName)"
        
        let cacheableSessions = sessions.map { session in
            SessionCache(
                id: session.id,
                projectId: session.projectId,
                summary: session.summary,
                messageCount: session.messageCount,
                lastActivity: session.lastActivity,
                cwd: session.cwd,
                status: session.status.rawValue
            )
        }
        
        if let data = try? encoder.encode(cacheableSessions) {
            userDefaults.set(data, forKey: cacheKey)
            userDefaults.set(Date(), forKey: "\(cacheKey)_expiry")
        }
    }
    
    /// Get cached session list
    func getCachedSessions(for projectName: String) -> [Session]? {
        let cacheKey = "\(Keys.sessionCache)_list_\(projectName)"
        
        // Check if cache has expired
        if let expiryDate = userDefaults.object(forKey: "\(cacheKey)_expiry") as? Date {
            if Date().timeIntervalSince(expiryDate) > cacheExpiryInterval {
                // Cache expired, remove it
                userDefaults.removeObject(forKey: cacheKey)
                userDefaults.removeObject(forKey: "\(cacheKey)_expiry")
                return nil
            }
        }
        
        guard let data = userDefaults.data(forKey: cacheKey) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let cacheableSessions = try? decoder.decode([SessionCache].self, from: data) else {
            return nil
        }
        
        // Convert back to Session objects
        return cacheableSessions.map { cache in
            Session(
                id: cache.id,
                projectId: cache.projectId,
                summary: cache.summary,
                messageCount: cache.messageCount,
                lastActivity: cache.lastActivity,
                cwd: cache.cwd,
                status: SessionStatus(rawValue: cache.status) ?? .active
            )
        }
    }
    
    // MARK: - Clear All Data
    
    /// Clear all persisted session data
    func clearAllSessionData() {
        // Get all keys that match our patterns
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        for key in allKeys {
            if key.contains("currentSessionId_") ||
               key.contains(Keys.sessionCache) ||
               key == Keys.lastActiveProjectName {
                userDefaults.removeObject(forKey: key)
            }
        }
    }
    
    // MARK: - Session State
    
    /// Check if a session should be resumed (was active recently)
    func shouldResumeSession(projectName: String, sessionId: String) -> Bool {
        let timestampKey = "\(Keys.currentSessionId(for: projectName))_timestamp"
        
        guard let timestamp = userDefaults.object(forKey: timestampKey) as? Date else {
            return false
        }
        
        // Resume if session was active within the last 24 hours
        let hoursSinceLastActive = Date().timeIntervalSince(timestamp) / 3600
        return hoursSinceLastActive < 24
    }
}

// MARK: - Private Types

/// Codable version of Session for caching
private struct SessionCache: Codable {
    let id: String
    let projectId: String
    let summary: String?
    let messageCount: Int
    let lastActivity: Date?
    let cwd: String?
    let status: String
}