//
//  OfflineDataStore.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-26.
//

import Foundation
import CoreData

// MARK: - Offline Data Store

/// Core Data stack for offline data persistence
final class OfflineDataStore {
    
    // MARK: - Singleton
    
    static let shared = OfflineDataStore()
    
    // MARK: - Properties
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ClaudeCodeOffline")
        
        // Configure for offline mode
        let description = container.persistentStoreDescriptions.first
        description?.shouldMigrateStoreAutomatically = true
        description?.shouldInferMappingModelAutomatically = true
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ Failed to load Core Data stack: \(error)")
                fatalError("Unable to load persistent stores: \(error)")
            }
            print("✅ Core Data stack loaded successfully")
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Save Context
    
    func save() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
            print("💾 Offline data saved to Core Data")
        } catch {
            print("❌ Failed to save Core Data context: \(error)")
        }
    }
    
    // MARK: - Project Operations
    
    func saveProject(_ project: Project, isOffline: Bool = true) {
        let offlineProject = OfflineProject(context: context)
        offlineProject.id = project.id
        offlineProject.name = project.name
        offlineProject.path = project.path
        offlineProject.lastModified = project.updatedAt
        offlineProject.isOffline = isOffline
        offlineProject.syncStatus = "pending"
        offlineProject.createdAt = Date()
        
        save()
        print("💾 Project saved offline: \(project.name)")
    }
    
    func fetchOfflineProjects() -> [OfflineProject] {
        let request: NSFetchRequest<OfflineProject> = OfflineProject.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch offline projects: \(error)")
            return []
        }
    }
    
    func deleteOfflineProject(_ projectId: String) {
        let request: NSFetchRequest<OfflineProject> = OfflineProject.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", projectId)
        
        do {
            let projects = try context.fetch(request)
            projects.forEach { context.delete($0) }
            save()
        } catch {
            print("❌ Failed to delete offline project: \(error)")
        }
    }
    
    // MARK: - Session Operations
    
    func saveSession(_ session: Session, projectId: String, isOffline: Bool = true) {
        let offlineSession = OfflineSession(context: context)
        offlineSession.id = session.id
        offlineSession.title = session.summary ?? "Session \(session.id)"
        offlineSession.projectId = projectId
        offlineSession.createdAt = session.startedAt
        offlineSession.lastModified = Date()
        offlineSession.isOffline = isOffline
        offlineSession.syncStatus = "pending"
        
        save()
        print("💾 Session saved offline: \(session.summary ?? session.id)")
    }
    
    func fetchOfflineSessions(for projectId: String) -> [OfflineSession] {
        let request: NSFetchRequest<OfflineSession> = OfflineSession.fetchRequest()
        request.predicate = NSPredicate(format: "projectId == %@", projectId)
        request.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch offline sessions: \(error)")
            return []
        }
    }
    
    // MARK: - Message Operations
    
    func saveMessage(_ message: Message, sessionId: String, isOffline: Bool = true) {
        let offlineMessage = OfflineMessage(context: context)
        offlineMessage.id = message.id
        offlineMessage.content = message.content
        offlineMessage.role = message.role.rawValue
        offlineMessage.sessionId = sessionId
        offlineMessage.timestamp = message.timestamp
        offlineMessage.isOffline = isOffline
        offlineMessage.syncStatus = "pending"
        
        save()
        print("💾 Message saved offline: \(message.id)")
    }
    
    func fetchOfflineMessages(for sessionId: String) -> [OfflineMessage] {
        let request: NSFetchRequest<OfflineMessage> = OfflineMessage.fetchRequest()
        request.predicate = NSPredicate(format: "sessionId == %@", sessionId)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch offline messages: \(error)")
            return []
        }
    }
    
    // MARK: - File Operations
    
    func saveFile(path: String, content: String, projectId: String, isOffline: Bool = true) {
        let offlineFile = OfflineFile(context: context)
        offlineFile.path = path
        offlineFile.content = content
        offlineFile.projectId = projectId
        offlineFile.lastModified = Date()
        offlineFile.isOffline = isOffline
        offlineFile.syncStatus = "pending"
        
        save()
        print("💾 File saved offline: \(path)")
    }
    
    func fetchOfflineFiles(for projectId: String) -> [OfflineFile] {
        let request: NSFetchRequest<OfflineFile> = OfflineFile.fetchRequest()
        request.predicate = NSPredicate(format: "projectId == %@", projectId)
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch offline files: \(error)")
            return []
        }
    }
    
    // MARK: - Sync Operations
    
    func markAsSynced<T: NSManagedObject>(_ entity: T) where T: SyncableEntity {
        // NSManagedObject properties are mutable even if the parameter is let
        // This is Core Data's behavior - managed objects are reference types
        entity.setValue("synced", forKey: "syncStatus")
        entity.setValue(false, forKey: "isOffline") 
        entity.setValue(Date(), forKey: "syncedAt")
        save()
    }
    
    func fetchPendingSyncItems<T: NSManagedObject & SyncableEntity>(of type: T.Type) -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        request.predicate = NSPredicate(format: "syncStatus == %@", "pending")
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch pending sync items: \(error)")
            return []
        }
    }
    
    // MARK: - Cleanup
    
    func clearAllOfflineData() {
        let entities = ["OfflineProject", "OfflineSession", "OfflineMessage", "OfflineFile"]
        
        for entity in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
            } catch {
                print("❌ Failed to clear \(entity): \(error)")
            }
        }
        
        save()
        print("🗑️ All offline data cleared")
    }
    
    func getOfflineDataSize() -> Int64 {
        var totalSize: Int64 = 0
        
        // Count projects
        let projectRequest: NSFetchRequest<OfflineProject> = OfflineProject.fetchRequest()
        if let projectCount = try? context.count(for: projectRequest) {
            totalSize += Int64(projectCount * 1024) // Estimate 1KB per project
        }
        
        // Count sessions
        let sessionRequest: NSFetchRequest<OfflineSession> = OfflineSession.fetchRequest()
        if let sessionCount = try? context.count(for: sessionRequest) {
            totalSize += Int64(sessionCount * 512) // Estimate 512B per session
        }
        
        // Count messages
        let messageRequest: NSFetchRequest<OfflineMessage> = OfflineMessage.fetchRequest()
        if let messageCount = try? context.count(for: messageRequest) {
            totalSize += Int64(messageCount * 256) // Estimate 256B per message
        }
        
        // Count files
        let fileRequest: NSFetchRequest<OfflineFile> = OfflineFile.fetchRequest()
        if let files = try? context.fetch(fileRequest) {
            for file in files {
                totalSize += Int64(file.content?.count ?? 0)
            }
        }
        
        return totalSize
    }
}

// MARK: - Core Data Models

// Protocol for syncable entities
protocol SyncableEntity {
    var syncStatus: String? { get set }
    var isOffline: Bool { get set }
    var syncedAt: Date? { get set }
}

// Offline Project Entity
@objc(OfflineProject)
class OfflineProject: NSManagedObject, SyncableEntity {
    @NSManaged var id: String?
    @NSManaged var name: String?
    @NSManaged var path: String?
    @NSManaged var lastModified: Date?
    @NSManaged var createdAt: Date?
    @NSManaged var isOffline: Bool
    @NSManaged var syncStatus: String?
    @NSManaged var syncedAt: Date?
}

// Offline Session Entity
@objc(OfflineSession)
class OfflineSession: NSManagedObject, SyncableEntity {
    @NSManaged var id: String?
    @NSManaged var title: String?
    @NSManaged var projectId: String?
    @NSManaged var createdAt: Date?
    @NSManaged var lastModified: Date?
    @NSManaged var isOffline: Bool
    @NSManaged var syncStatus: String?
    @NSManaged var syncedAt: Date?
}

// Offline Message Entity
@objc(OfflineMessage)
class OfflineMessage: NSManagedObject, SyncableEntity {
    @NSManaged var id: String?
    @NSManaged var content: String?
    @NSManaged var role: String?
    @NSManaged var sessionId: String?
    @NSManaged var timestamp: Date?
    @NSManaged var isOffline: Bool
    @NSManaged var syncStatus: String?
    @NSManaged var syncedAt: Date?
}

// Offline File Entity
@objc(OfflineFile)
class OfflineFile: NSManagedObject, SyncableEntity {
    @NSManaged var path: String?
    @NSManaged var content: String?
    @NSManaged var projectId: String?
    @NSManaged var lastModified: Date?
    @NSManaged var isOffline: Bool
    @NSManaged var syncStatus: String?
    @NSManaged var syncedAt: Date?
}

// MARK: - Extension to create fetch requests

extension OfflineProject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<OfflineProject> {
        return NSFetchRequest<OfflineProject>(entityName: "OfflineProject")
    }
}

extension OfflineSession {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<OfflineSession> {
        return NSFetchRequest<OfflineSession>(entityName: "OfflineSession")
    }
}

extension OfflineMessage {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<OfflineMessage> {
        return NSFetchRequest<OfflineMessage>(entityName: "OfflineMessage")
    }
}

extension OfflineFile {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<OfflineFile> {
        return NSFetchRequest<OfflineFile>(entityName: "OfflineFile")
    }
}