//
//  DIContainer.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-08.
//

import Foundation
import UIKit

/// Dependency Injection Container for managing app-wide services
final class DIContainer {
    
    // MARK: - Singleton
    static let shared = DIContainer()
    
    // MARK: - Services
    
    private(set) lazy var apiClient: APIClient = {
        // Use the shared APIClient which already has auth configured
        return APIClient.shared
    }()
    
    private(set) lazy var webSocketManager: WebSocketManager = {
        return WebSocketManager()
    }()
    
    private(set) lazy var dataContainer: SwiftDataContainer? = {
        return SwiftDataContainer.shared
    }()
    
    private(set) lazy var errorHandler: ErrorHandlingService = {
        return ErrorHandlingService.shared
    }()
    
    private(set) lazy var logger: Logger = {
        return Logger.shared
    }()
    
    private(set) lazy var cacheManager: CacheManager = {
        return CacheManager.shared
    }()
    
    private(set) lazy var settingsManager: SettingsManager = {
        return SettingsManager(dataContainer: dataContainer)
    }()
    
    private(set) lazy var projectService: ProjectService = {
        return ProjectService(
            apiClient: apiClient,
            dataContainer: dataContainer,
            cacheManager: cacheManager
        )
    }()
    
    private(set) lazy var chatService: ChatService = {
        return ChatService(
            webSocketManager: webSocketManager,
            dataContainer: dataContainer
        )
    }()
    
    private(set) lazy var fileService: FileService = {
        return FileService(
            apiClient: apiClient,
            cacheManager: cacheManager
        )
    }()
    
    private(set) lazy var terminalService: TerminalService = {
        return TerminalService(apiClient: apiClient)
    }()
    
    // MARK: - Initialization
    
    private init() {
        setupServices()
    }
    
    private func setupServices() {
        // Setup error handler crash reporting
        errorHandler.setupCrashReporting()
        
        // Load settings and update services
        Task {
            await loadAndApplySettings()
        }
    }
    
    // MARK: - Settings Management
    
    @MainActor
    func loadAndApplySettings() async {
        guard let dataContainer = dataContainer else { return }
        
        do {
            let settings = try await dataContainer.fetchSettings()
            updateServicesWithSettings(settings)
        } catch {
            logger.error("Failed to load settings: \(error)")
        }
    }
    
    func updateServicesWithSettings(_ settings: Settings) {
        // Since services are lazy-loaded and use shared instances,
        // we only need to update configurations, not recreate services
        
        // Update WebSocket manager configuration without losing connection
        // This preserves the existing connection state
        webSocketManager.configure(
            enableAutoReconnect: true,
            reconnectDelay: TimeInterval(settings.webSocketReconnectDelay),
            maxReconnectAttempts: settings.maxReconnectAttempts
        )
        
        // Update logger debug mode
        logger.isDebugEnabled = settings.enableDebugLogging
        
        // Note: APIClient is a singleton (APIClient.shared) and manages its own state
        // CacheManager is also a singleton (CacheManager.shared) and preserves cached data
        // Services that depend on these will automatically use the updated configurations
    }
    
    // MARK: - Service Registration (for testing)
    
    func register<T>(_ service: T, for type: T.Type) {
        // This would be used for testing to inject mock services
        // Implementation depends on specific testing needs
    }
}

// MARK: - Settings Manager

final class SettingsManager {
    private let dataContainer: SwiftDataContainer?
    private var cachedSettings: Settings?
    
    init(dataContainer: SwiftDataContainer?) {
        self.dataContainer = dataContainer
    }
    
    func loadSettings() async throws -> Settings {
        if let cached = cachedSettings {
            return cached
        }
        
        guard let dataContainer = dataContainer else {
            // Return default settings if no data container
            return Settings()
        }
        
        let settings = try await dataContainer.fetchSettings()
        cachedSettings = settings
        return settings
    }
    
    func saveSettings(_ settings: Settings) async throws {
        guard let dataContainer = dataContainer else { return }
        
        try await dataContainer.updateSettings(settings)
        cachedSettings = settings
        
        // Update services with new settings
        DIContainer.shared.updateServicesWithSettings(settings)
    }
    
    func clearCache() {
        cachedSettings = nil
    }
}

// MARK: - Service Protocols

protocol ProjectServiceProtocol {
    func fetchProjects() async throws -> [Project]
    func createProject(name: String, path: String) async throws -> Project
    func updateProject(_ project: Project) async throws
    func deleteProject(id: String) async throws
}

protocol ChatServiceProtocol {
    func sendMessage(_ message: String, in session: Session) async throws
    func receiveMessage() async throws -> Message
    func startSession(for project: Project) async throws -> Session
}

protocol FileServiceProtocol {
    func fetchFileTree(for projectId: String) async throws -> FileNode
    func createFile(at path: String, content: String?) async throws
    func deleteFile(at path: String) async throws
    func renameFile(from: String, to: String) async throws
}

protocol TerminalServiceProtocol {
    func executeCommand(_ command: String, in projectId: String) async throws -> TerminalOutput
}

// MARK: - Service Implementations

final class ProjectService: ProjectServiceProtocol {
    private let apiClient: APIClient
    private let dataContainer: SwiftDataContainer?
    private let cacheManager: CacheManager
    
    init(apiClient: APIClient, dataContainer: SwiftDataContainer?, cacheManager: CacheManager) {
        self.apiClient = apiClient
        self.dataContainer = dataContainer
        self.cacheManager = cacheManager
    }
    
    func fetchProjects() async throws -> [Project] {
        // Try cache first
        if let cached: [Project] = cacheManager.retrieve(forKey: "projects") {
            return cached
        }
        
        // Fetch from API
        let projects = try await apiClient.fetchProjects()
        
        // Cache result
        cacheManager.store(projects, forKey: "projects", expiresIn: 300) // 5 minutes
        
        // Sync with local database in background
        if let dataContainer = dataContainer {
            for project in projects {
                try? await dataContainer.saveProject(project)
            }
        }
        
        return projects
    }
    
    func createProject(name: String, path: String) async throws -> Project {
        let project = try await apiClient.createProject(name: name, path: path)
        
        // Clear cache to force refresh
        cacheManager.remove(forKey: "projects")
        
        // Save to local database
        if let dataContainer = dataContainer {
            try? await dataContainer.saveProject(project)
        }
        
        return project
    }
    
    func updateProject(_ project: Project) async throws {
        try await apiClient.updateProject(project)
        
        // Clear cache
        cacheManager.remove(forKey: "projects")
        
        // Update in local database
        if let dataContainer = dataContainer {
            try? await dataContainer.saveProject(project)
        }
    }
    
    func deleteProject(id: String) async throws {
        try await apiClient.deleteProject(id: id)
        
        // Clear cache
        cacheManager.remove(forKey: "projects")
        
        // Delete from local database
        if let dataContainer = dataContainer,
           let project = try? await dataContainer.fetchProject(byId: id) {
            try? await dataContainer.deleteProject(project)
        }
    }
}

final class ChatService: ChatServiceProtocol {
    private let webSocketManager: WebSocketManager
    private let dataContainer: SwiftDataContainer?
    
    init(webSocketManager: WebSocketManager, dataContainer: SwiftDataContainer?) {
        self.webSocketManager = webSocketManager
        self.dataContainer = dataContainer
    }
    
    func sendMessage(_ message: String, in session: Session) async throws {
        // Create message model
        let chatMessage = Message(
            role: .user,
            content: message
        )
        
        // Send via WebSocket
        let payload: [String: Any] = [
            "content": message,
            "projectPath": session.cwd ?? "/Users/nick",  // Use current working directory or fallback
            "sessionId": session.id
        ]
        let wsMessage = WebSocketMessage(
            type: .claudeCommand,
            payload: payload,
            sessionId: session.id
        )
        webSocketManager.send(wsMessage)
        
        // Save to database
        if let dataContainer = dataContainer {
            _ = try? await dataContainer.createMessage(for: session, role: .user, content: message)
        }
    }
    
    func receiveMessage() async throws -> Message {
        // This would be implemented with WebSocket listeners
        fatalError("Not yet implemented - needs WebSocket event handling")
    }
    
    func startSession(for project: Project) async throws -> Session {
        guard let dataContainer = dataContainer else {
            throw AppError.persistence(.saveFailed)
        }
        
        let session = try await dataContainer.createSession(for: project)
        
        // Connect WebSocket for this session
        let wsURL = "\(AppConfig.backendURL.replacingOccurrences(of: "http", with: "ws"))/ws"
        webSocketManager.connect(to: wsURL)
        
        return session
    }
}

final class FileService: FileServiceProtocol {
    private let apiClient: APIClient
    private let cacheManager: CacheManager
    
    init(apiClient: APIClient, cacheManager: CacheManager) {
        self.apiClient = apiClient
        self.cacheManager = cacheManager
    }
    
    func fetchFileTree(for projectId: String) async throws -> FileNode {
        // Check cache
        let cacheKey = "file_tree_\(projectId)"
        if let cached: FileNode = cacheManager.retrieve(forKey: cacheKey) {
            return cached
        }
        
        // Fetch from API
        let fileTree = try await apiClient.fetchFileTree(projectId: projectId)
        
        // Cache for 1 minute
        cacheManager.store(fileTree, forKey: cacheKey, expiresIn: 60)
        
        return fileTree
    }
    
    func createFile(at path: String, content: String?) async throws {
        try await apiClient.createFile(path: path, content: content)
        
        // Clear relevant cache
        if let projectId = extractProjectId(from: path) {
            cacheManager.remove(forKey: "file_tree_\(projectId)")
        }
    }
    
    func deleteFile(at path: String) async throws {
        try await apiClient.deleteFile(path: path)
        
        // Clear relevant cache
        if let projectId = extractProjectId(from: path) {
            cacheManager.remove(forKey: "file_tree_\(projectId)")
        }
    }
    
    func renameFile(from: String, to: String) async throws {
        try await apiClient.renameFile(from: from, to: to)
        
        // Clear relevant cache
        if let projectId = extractProjectId(from: from) {
            cacheManager.remove(forKey: "file_tree_\(projectId)")
        }
    }
    
    private func extractProjectId(from path: String) -> String? {
        // Extract project ID from file path
        // This is a simplified implementation
        return path.components(separatedBy: "/").first
    }
}

final class TerminalService: TerminalServiceProtocol {
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    func executeCommand(_ command: String, in projectId: String) async throws -> TerminalOutput {
        return try await apiClient.executeTerminalCommand(command, projectId: projectId)
    }
}