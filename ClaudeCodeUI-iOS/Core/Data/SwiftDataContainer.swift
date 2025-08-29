//
//  SwiftDataContainer.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import SwiftData
import Foundation

@MainActor
class SwiftDataContainer {
    private static var _shared: SwiftDataContainer?
    
    static var shared: SwiftDataContainer {
        if let existing = _shared {
            return existing
        }
        
        do {
            let container = try SwiftDataContainer()
            _shared = container
            return container
        } catch {
            // Log error and create fallback in-memory container
            print("⚠️ Failed to create SwiftDataContainer: \(error)")
            print("📦 Creating fallback in-memory container")
            
            // Try to create an in-memory only container as fallback
            if let fallbackContainer = try? SwiftDataContainer(inMemoryOnly: true) {
                _shared = fallbackContainer
                return fallbackContainer
            }
            
            // If even in-memory fails, fatal error with useful information
            fatalError("❌ Critical: Cannot create SwiftDataContainer even in-memory mode. Error: \(error)")
        }
    }
    
    let container: ModelContainer
    
    public init(inMemoryOnly: Bool = false) throws {
        let schema = Schema([
            Project.self,
            Session.self,
            Message.self,
            Settings.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemoryOnly,
            allowsSave: true
            // groupContainer: .identifier("group.com.claudecodeui.ios") // Disabled for testing
        )
        
        // Try to create the container with migration handling
        container = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        
        // Ensure default settings exist
        Task { @MainActor in
            try? ensureDefaultSettings()
        }
    }
    
    // Ensure default settings exist
    private func ensureDefaultSettings() throws {
        let descriptor = FetchDescriptor<Settings>(
            predicate: #Predicate { $0.id == "default" }
        )
        
        let existingSettings = try container.mainContext.fetch(descriptor)
        if existingSettings.isEmpty {
            let settings = Settings()
            container.mainContext.insert(settings)
            try container.mainContext.save()
        }
    }
    
    // MARK: - Convenience Methods
    
    func save() throws {
        try container.mainContext.save()
    }
    
    // MARK: - Project Operations
    
    func fetchProjects() throws -> [Project] {
        let descriptor = FetchDescriptor<Project>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try container.mainContext.fetch(descriptor)
    }
    
    func fetchProject(byId id: String) throws -> Project? {
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate { $0.id == id }
        )
        return try container.mainContext.fetch(descriptor).first
    }
    
    func createProject(name: String, path: String) throws -> Project {
        let project = Project(name: name, path: path)
        container.mainContext.insert(project)
        try save()
        return project
    }
    
    func deleteProject(_ project: Project) throws {
        container.mainContext.delete(project)
        try save()
    }
    
    // MARK: - Session Operations
    
    func fetchSessions(for project: Project, limit: Int = 5, offset: Int = 0) throws -> [Session] {
        let projectId = project.id
        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { session in
                session.projectId == projectId
            },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        
        var fetchDescriptor = descriptor
        fetchDescriptor.fetchLimit = limit
        fetchDescriptor.fetchOffset = offset
        
        return try container.mainContext.fetch(fetchDescriptor)
    }
    
    func createSession(for project: Project) throws -> Session {
        let session = Session(
            id: UUID().uuidString,
            projectId: project.id
        )
        // Session doesn't have a direct project relationship, it uses projectId
        container.mainContext.insert(session)
        try save()
        return session
    }
    
    func deleteSession(_ session: Session) throws {
        container.mainContext.delete(session)
        try save()
    }
    
    // MARK: - Message Operations
    
    func fetchMessages(for session: Session) throws -> [Message] {
        // Messages are related directly to the session
        return session.messages ?? []
    }
    
    func createMessage(for session: Session, role: MessageRole, content: String) throws -> Message {
        let message = Message(role: role, content: content)
        // Message doesn't have a session property anymore, it's handled through relationships
        container.mainContext.insert(message)
        
        // Update session activity time
        session.lastActiveAt = Date()
        
        // Add message to session's messages
        if session.messages == nil {
            session.messages = []
        }
        session.messages?.append(message)
        
        try save()
        return message
    }
    
    // MARK: - Settings Operations
    
    func fetchSettings() throws -> Settings {
        let descriptor = FetchDescriptor<Settings>(
            predicate: #Predicate { $0.id == "default" }
        )
        
        if let settings = try container.mainContext.fetch(descriptor).first {
            return settings
        } else {
            // Create default settings if none exist
            let settings = Settings()
            container.mainContext.insert(settings)
            try save()
            return settings
        }
    }
    
    func updateSettings(_ settings: Settings) throws {
        try save()
    }
    
    // MARK: - Sync Operations
    
    func syncWithServer(projects: [[String: Any]]) throws {
        // This method would sync server data with local SwiftData
        // For now, it's a placeholder for the sync logic
        
        for projectData in projects {
            guard let name = projectData["name"] as? String,
                  let path = projectData["path"] as? String else {
                continue
            }
            
            // Check if project exists
            if try fetchProject(byId: name) == nil {
                // Create new project
                _ = try createProject(name: name, path: path)
            }
        }
    }
    
    // MARK: - Async Operations (for use from async contexts)
    
    func fetchProjects() async throws -> [Project] {
        return try await Task { @MainActor in
            try fetchProjects()
        }.value
    }
    
    func fetchSettings() async throws -> Settings {
        return try await Task { @MainActor in
            try fetchSettings()
        }.value
    }
    
    func saveProject(_ project: Project) async throws {
        container.mainContext.insert(project)
        try save()
    }
    
    func deleteProject(_ project: Project) async throws {
        container.mainContext.delete(project)
        try save()
    }
}