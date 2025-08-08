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
    static let shared = SwiftDataContainer()
    let container: ModelContainer
    
    private init() {
        let schema = Schema([
            Project.self,
            Session.self,
            Message.self,
            Settings.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
            // groupContainer: .identifier("group.com.claudecodeui.ios") // Disabled for testing
        )
        
        do {
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
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
            sortBy: [SortDescriptor(\.lastActiveAt, order: .reverse)]
        )
        
        var fetchDescriptor = descriptor
        fetchDescriptor.fetchLimit = limit
        fetchDescriptor.fetchOffset = offset
        
        return try container.mainContext.fetch(fetchDescriptor)
    }
    
    func createSession(for project: Project) throws -> Session {
        let session = Session(projectId: project.id)
        session.project = project
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
        let sessionId = session.id
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate { message in
                message.session?.id == sessionId
            },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        return try container.mainContext.fetch(descriptor)
    }
    
    func createMessage(for session: Session, role: MessageRole, content: String) throws -> Message {
        let message = Message(role: role, content: content)
        message.session = session
        container.mainContext.insert(message)
        
        // Update session last active time
        session.lastActiveAt = Date()
        
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
}