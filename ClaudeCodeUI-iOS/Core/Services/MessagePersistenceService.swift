//
//  MessagePersistenceService.swift
//  ClaudeCodeUI
//
//  Created by Claude on 2025-01-21.
//

import Foundation
import CoreData

@available(iOS 17.0, *)
class MessagePersistenceService {
    static let shared = MessagePersistenceService()
    
    private let persistentContainer: NSPersistentContainer
    private let backgroundContext: NSManagedObjectContext
    
    private init() {
        // Configure for messages
        let messageEntity = NSEntityDescription()
        messageEntity.name = "CachedMessage"
        messageEntity.managedObjectClassName = NSStringFromClass(CachedMessage.self)
        
        // Add properties
        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.type = .string
        idAttribute.isOptional = false
        
        let sessionIdAttribute = NSAttributeDescription()
        sessionIdAttribute.name = "sessionId"
        sessionIdAttribute.type = .string
        sessionIdAttribute.isOptional = false
        
        let contentAttribute = NSAttributeDescription()
        contentAttribute.name = "content"
        contentAttribute.type = .string
        contentAttribute.isOptional = false
        
        let roleAttribute = NSAttributeDescription()
        roleAttribute.name = "role"
        roleAttribute.type = .string
        roleAttribute.isOptional = false
        
        let timestampAttribute = NSAttributeDescription()
        timestampAttribute.name = "timestamp"
        timestampAttribute.type = .date
        timestampAttribute.isOptional = false
        
        let metadataAttribute = NSAttributeDescription()
        metadataAttribute.name = "metadata"
        metadataAttribute.type = .binaryData
        metadataAttribute.isOptional = true
        
        let orderAttribute = NSAttributeDescription()
        orderAttribute.name = "order"
        orderAttribute.type = .integer32
        orderAttribute.isOptional = false
        
        messageEntity.properties = [
            idAttribute,
            sessionIdAttribute,
            contentAttribute,
            roleAttribute,
            timestampAttribute,
            metadataAttribute,
            orderAttribute
        ]
        
        // Create model
        let model = NSManagedObjectModel()
        model.entities = [messageEntity]
        
        // Initialize container with the model
        persistentContainer = NSPersistentContainer(name: "ClaudeCodeUI", managedObjectModel: model)
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                print("❌ Failed to load Core Data store: \\(error)")
            }
        }
        
        backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - Save Messages
    
    func saveMessages(_ messages: [Message], for sessionId: String) async {
        await backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            
            // Delete existing messages for this session
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CachedMessage")
            fetchRequest.predicate = NSPredicate(format: "sessionId == %@", sessionId)
            
            do {
                let existing = try self.backgroundContext.fetch(fetchRequest)
                existing.forEach { self.backgroundContext.delete($0) }
                
                // Save new messages
                for (index, message) in messages.enumerated() {
                    let cached = NSEntityDescription.insertNewObject(
                        forEntityName: "CachedMessage",
                        into: self.backgroundContext
                    )
                    
                    cached.setValue(message.id, forKey: "id")
                    cached.setValue(sessionId, forKey: "sessionId")
                    cached.setValue(message.content, forKey: "content")
                    cached.setValue(message.role.rawValue, forKey: "role")
                    cached.setValue(message.timestamp, forKey: "timestamp")
                    cached.setValue(index, forKey: "order")
                    
                    // Save metadata as JSON
                    if let metadata = message.metadata,
                       let data = try? JSONEncoder().encode(metadata) {
                        cached.setValue(data, forKey: "metadata")
                    }
                }
                
                try self.backgroundContext.save()
                print("✅ Saved \\(messages.count) messages for session \\(sessionId)")
            } catch {
                print("❌ Failed to save messages: \\(error)")
            }
        }
    }
    
    // MARK: - Load Messages
    
    func loadMessages(for sessionId: String) async -> [Message] {
        await backgroundContext.perform { [weak self] in
            guard let self = self else { return [] }
            
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CachedMessage")
            fetchRequest.predicate = NSPredicate(format: "sessionId == %@", sessionId)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
            
            do {
                let cached = try self.backgroundContext.fetch(fetchRequest)
                
                return cached.compactMap { object in
                    guard let id = object.value(forKey: "id") as? String,
                          let content = object.value(forKey: "content") as? String,
                          let roleString = object.value(forKey: "role") as? String,
                          let timestamp = object.value(forKey: "timestamp") as? Date else {
                        return nil
                    }
                    
                    let message = Message(
                        id: id,
                        role: MessageRole(rawValue: roleString) ?? .user,
                        content: content
                    )
                    message.timestamp = timestamp
                    
                    // Load metadata
                    if let metadataData = object.value(forKey: "metadata") as? Data,
                       let metadata = try? JSONDecoder().decode(MessageMetadata.self, from: metadataData) {
                        message.metadata = metadata
                    }
                    
                    return message
                }
            } catch {
                print("❌ Failed to load cached messages: \\(error)")
                return []
            }
        }
    }
    
    // MARK: - Append Message
    
    func appendMessage(_ message: Message, to sessionId: String) async {
        await backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            
            // Get current count for ordering
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CachedMessage")
            fetchRequest.predicate = NSPredicate(format: "sessionId == %@", sessionId)
            
            do {
                let count = try self.backgroundContext.count(for: fetchRequest)
                
                let cached = NSEntityDescription.insertNewObject(
                    forEntityName: "CachedMessage",
                    into: self.backgroundContext
                )
                
                cached.setValue(message.id, forKey: "id")
                cached.setValue(sessionId, forKey: "sessionId")
                cached.setValue(message.content, forKey: "content")
                cached.setValue(message.role.rawValue, forKey: "role")
                cached.setValue(message.timestamp, forKey: "timestamp")
                cached.setValue(count, forKey: "order")
                
                if let metadata = message.metadata,
                   let data = try? JSONEncoder().encode(metadata) {
                    cached.setValue(data, forKey: "metadata")
                }
                
                try self.backgroundContext.save()
            } catch {
                print("❌ Failed to append message: \\(error)")
            }
        }
    }
    
    // MARK: - Clear Cache
    
    func clearCache(for sessionId: String? = nil) async {
        await backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CachedMessage")
            if let sessionId = sessionId {
                fetchRequest.predicate = NSPredicate(format: "sessionId == %@", sessionId)
            }
            
            do {
                let messages = try self.backgroundContext.fetch(fetchRequest)
                messages.forEach { self.backgroundContext.delete($0) }
                try self.backgroundContext.save()
                print("✅ Cleared cache for session: \(sessionId ?? "all")")
            } catch {
                print("❌ Failed to clear cache: \\(error)")
            }
        }
    }
    
    // MARK: - Message Count
    
    func messageCount(for sessionId: String) async -> Int {
        await backgroundContext.perform { [weak self] in
            guard let self = self else { return 0 }
            
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CachedMessage")
            fetchRequest.predicate = NSPredicate(format: "sessionId == %@", sessionId)
            
            do {
                return try self.backgroundContext.count(for: fetchRequest)
            } catch {
                print("❌ Failed to count messages: \\(error)")
                return 0
            }
        }
    }
}

// MARK: - Core Data Entity

@objc(CachedMessage)
class CachedMessage: NSManagedObject {
    // Core Data will manage the properties dynamically
}