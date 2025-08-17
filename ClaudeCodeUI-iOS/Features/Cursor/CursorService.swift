//
//  CursorService.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-16.
//

import Foundation

// MARK: - Cursor Service Protocol
protocol CursorServiceProtocol {
    func getConfiguration() async throws -> CursorConfig
    func updateConfiguration(_ config: CursorConfig) async throws -> CursorConfig
    func getMCPServers() async throws -> [CursorMCPServer]
    func addMCPServer(_ server: CursorMCPServerConfig) async throws -> CursorMCPServer
    func removeMCPServer(id: String) async throws
    func getSessions() async throws -> [CursorSession]
    func getSession(id: String) async throws -> CursorSession
    func restoreSession(id: String) async throws -> CursorSession
    func getSettings() async throws -> CursorSettings
    func updateSettings(_ settings: CursorSettings) async throws -> CursorSettings
}

// MARK: - Cursor Service Implementation with Progressive Enhancement
actor CursorService: CursorServiceProtocol {
    
    // MARK: - Singleton
    static let shared = CursorService()
    
    // MARK: - Properties
    private let apiClient = APIClient.shared
    private let userDefaults = UserDefaults.standard
    private let localStorageKey = "com.claudecode.cursor"
    
    // Local fallback storage
    private var localConfig: CursorConfig?
    private var localMCPServers: [CursorMCPServer] = []
    private var localSessions: [CursorSession] = []
    private var localSettings: CursorSettings?
    
    // MARK: - Initialization
    private init() {
        loadLocalData()
    }
    
    // MARK: - Configuration Methods
    func getConfiguration() async throws -> CursorConfig {
        do {
            // Try to fetch from backend first
            let config = try await apiClient.getCursorConfig()
            
            // Cache locally for offline use
            self.localConfig = config
            saveLocalData()
            
            return config
        } catch {
            print("⚠️ Failed to fetch Cursor config from backend: \(error)")
            print("📱 Using local fallback data")
            
            // Return local config or create default
            if let localConfig = self.localConfig {
                return localConfig
            } else {
                // Create default config
                let defaultConfig = CursorConfig(
                    workspacePath: "~/Documents/CursorProjects",
                    modelSettings: CursorModelSettings(),
                    features: CursorFeatures()
                )
                self.localConfig = defaultConfig
                saveLocalData()
                return defaultConfig
            }
        }
    }
    
    func updateConfiguration(_ config: CursorConfig) async throws -> CursorConfig {
        do {
            // Try to update on backend
            let updatedConfig = try await apiClient.updateCursorConfig(config)
            
            // Update local cache
            self.localConfig = updatedConfig
            saveLocalData()
            
            return updatedConfig
        } catch {
            print("⚠️ Failed to update Cursor config on backend: \(error)")
            print("📱 Saving to local storage only")
            
            // Save locally
            self.localConfig = config
            saveLocalData()
            
            return config
        }
    }
    
    // MARK: - MCP Server Methods
    func getMCPServers() async throws -> [CursorMCPServer] {
        do {
            // Try to fetch from backend
            let servers = try await apiClient.getCursorMCPServers()
            
            // Cache locally
            self.localMCPServers = servers
            saveLocalData()
            
            return servers
        } catch {
            print("⚠️ Failed to fetch Cursor MCP servers from backend: \(error)")
            print("📱 Using local fallback data")
            
            // Return local servers or default list
            if !localMCPServers.isEmpty {
                return localMCPServers
            } else {
                // Return some default MCP servers
                let defaultServers = [
                    CursorMCPServer(
                        name: "Claude Flow",
                        command: "npx",
                        args: ["claude-flow@alpha", "mcp", "start"],
                        enabled: true
                    ),
                    CursorMCPServer(
                        name: "Memory",
                        command: "npx",
                        args: ["@modelcontextprotocol/server-memory"],
                        enabled: false
                    ),
                    CursorMCPServer(
                        name: "Filesystem",
                        command: "npx",
                        args: ["@modelcontextprotocol/server-filesystem", "/"],
                        enabled: false
                    )
                ]
                self.localMCPServers = defaultServers
                saveLocalData()
                return defaultServers
            }
        }
    }
    
    func addMCPServer(_ server: CursorMCPServerConfig) async throws -> CursorMCPServer {
        do {
            // Try to add on backend
            let newServer = try await apiClient.addCursorMCPServer(server)
            
            // Update local cache
            self.localMCPServers.append(newServer)
            saveLocalData()
            
            return newServer
        } catch {
            print("⚠️ Failed to add Cursor MCP server to backend: \(error)")
            print("📱 Adding to local storage only")
            
            // Create local server
            let newServer = CursorMCPServer(
                name: server.name,
                command: server.command,
                args: server.args,
                env: server.env
            )
            
            self.localMCPServers.append(newServer)
            saveLocalData()
            
            return newServer
        }
    }
    
    func removeMCPServer(id: String) async throws {
        do {
            // Try to remove from backend
            try await apiClient.removeCursorMCPServer(id)
            
            // Update local cache
            self.localMCPServers.removeAll { $0.id == id }
            saveLocalData()
        } catch {
            print("⚠️ Failed to remove Cursor MCP server from backend: \(error)")
            print("📱 Removing from local storage only")
            
            // Remove locally
            self.localMCPServers.removeAll { $0.id == id }
            saveLocalData()
        }
    }
    
    // MARK: - Session Methods
    func getSessions() async throws -> [CursorSession] {
        do {
            // Try to fetch from backend
            let sessions = try await apiClient.getCursorSessions()
            
            // Cache locally
            self.localSessions = sessions
            saveLocalData()
            
            return sessions
        } catch {
            print("⚠️ Failed to fetch Cursor sessions from backend: \(error)")
            print("📱 Using local fallback data")
            
            // Return local sessions or create demo sessions
            if !localSessions.isEmpty {
                return localSessions
            } else {
                // Create demo sessions
                let demoSessions = [
                    CursorSession(
                        title: "SwiftUI Component Development",
                        messages: [
                            CursorMessage(role: .user, content: "How do I create a custom button in SwiftUI?"),
                            CursorMessage(role: .assistant, content: "Here's how to create a custom button in SwiftUI...")
                        ],
                        metadata: CursorSessionMetadata(model: "gpt-4", tokenCount: 245)
                    ),
                    CursorSession(
                        title: "API Integration Help",
                        messages: [
                            CursorMessage(role: .user, content: "I need help with REST API integration"),
                            CursorMessage(role: .assistant, content: "Let me help you with REST API integration...")
                        ],
                        metadata: CursorSessionMetadata(model: "gpt-4", tokenCount: 512)
                    )
                ]
                self.localSessions = demoSessions
                saveLocalData()
                return demoSessions
            }
        }
    }
    
    func getSession(id: String) async throws -> CursorSession {
        do {
            // Try to fetch from backend
            return try await apiClient.getCursorSession(id)
        } catch {
            print("⚠️ Failed to fetch Cursor session from backend: \(error)")
            print("📱 Looking in local storage")
            
            // Find in local storage
            guard let session = localSessions.first(where: { $0.id == id }) else {
                throw CursorServiceError.sessionNotFound
            }
            
            return session
        }
    }
    
    func restoreSession(id: String) async throws -> CursorSession {
        do {
            // Try to restore from backend
            return try await apiClient.restoreCursorSession(id)
        } catch {
            print("⚠️ Failed to restore Cursor session from backend: \(error)")
            print("📱 Restoring from local storage")
            
            // Restore from local storage
            guard let session = localSessions.first(where: { $0.id == id }) else {
                throw CursorServiceError.sessionNotFound
            }
            
            return session
        }
    }
    
    // MARK: - Settings Methods
    func getSettings() async throws -> CursorSettings {
        // Settings are typically stored locally
        if let localSettings = self.localSettings {
            return localSettings
        }
        
        // Create default settings
        let defaultSettings = CursorSettings()
        self.localSettings = defaultSettings
        saveLocalData()
        return defaultSettings
    }
    
    func updateSettings(_ settings: CursorSettings) async throws -> CursorSettings {
        // Save settings locally
        self.localSettings = settings
        saveLocalData()
        return settings
    }
    
    // MARK: - Local Storage Methods
    private func loadLocalData() {
        let key = "\(localStorageKey).data"
        
        guard let data = userDefaults.data(forKey: key),
              let storedData = try? JSONDecoder().decode(LocalCursorData.self, from: data) else {
            return
        }
        
        self.localConfig = storedData.config
        self.localMCPServers = storedData.mcpServers
        self.localSessions = storedData.sessions
        self.localSettings = storedData.settings
    }
    
    private func saveLocalData() {
        let data = LocalCursorData(
            config: localConfig,
            mcpServers: localMCPServers,
            sessions: localSessions,
            settings: localSettings
        )
        
        let key = "\(localStorageKey).data"
        
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: key)
        }
    }
}

// MARK: - Local Storage Model
private struct LocalCursorData: Codable {
    var config: CursorConfig?
    var mcpServers: [CursorMCPServer]
    var sessions: [CursorSession]
    var settings: CursorSettings?
}

// MARK: - Cursor Service Errors
enum CursorServiceError: LocalizedError {
    case sessionNotFound
    case serverNotFound
    case configurationError(String)
    
    var errorDescription: String? {
        switch self {
        case .sessionNotFound:
            return "Cursor session not found"
        case .serverNotFound:
            return "MCP server not found"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        }
    }
}