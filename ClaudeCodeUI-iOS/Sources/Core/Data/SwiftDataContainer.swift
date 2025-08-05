import Foundation
#if canImport(SwiftData)
import SwiftData

@available(iOS 17.0, *)
public class SwiftDataContainer {
    private let modelContainer: ModelContainer
    
    public init() throws {
        let schema = Schema([
            Project.self,
            Session.self,
            Message.self,
            Settings.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        modelContainer = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
    }
    
    public var mainContext: ModelContext {
        return modelContainer.mainContext
    }
    
    // MARK: - Project Operations
    
    @MainActor
    public func fetchProjects() throws -> [Project] {
        let descriptor = FetchDescriptor<Project>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try mainContext.fetch(descriptor)
    }
    
    @MainActor
    public func createProject(name: String, path: String) throws -> Project {
        let project = Project(name: name, path: path)
        mainContext.insert(project)
        try mainContext.save()
        return project
    }
    
    // MARK: - Settings Operations
    
    @MainActor
    public func fetchSettings() throws -> Settings? {
        let descriptor = FetchDescriptor<Settings>()
        return try mainContext.fetch(descriptor).first
    }
    
    @MainActor
    public func updateSettings(_ settings: Settings) throws {
        try mainContext.save()
    }
}
#else
// Fallback for Linux compilation
public class SwiftDataContainer {
    public init() throws {
        // Use UserDefaults or file-based storage on Linux
    }
    
    public func fetchProjects() throws -> [Project] {
        return []
    }
    
    public func createProject(name: String, path: String) throws -> Project {
        return Project(name: name, path: path)
    }
    
    public func fetchSettings() throws -> Settings? {
        return nil
    }
    
    public func updateSettings(_ settings: Settings) throws {
        // No-op for Linux
    }
}
#endif