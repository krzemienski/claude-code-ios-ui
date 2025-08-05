//
//  DIContainer.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import Foundation

// MARK: - Dependency Injection Container
@MainActor
final class DIContainer {
    
    // MARK: - Singleton
    static let shared = DIContainer()
    
    // MARK: - Properties
    private var services: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]
    
    // MARK: - Convenience Properties
    var apiClient: APIClient {
        resolve(APIClient.self) ?? APIClient()
    }
    
    var webSocketManager: WebSocketManager {
        resolve(WebSocketManager.self) ?? WebSocketManager(endpoint: "/ws")
    }
    
    var dataContainer: SwiftDataContainer {
        resolve(SwiftDataContainer.self) ?? SwiftDataContainer.shared
    }
    
    var errorHandler: ErrorHandlingService {
        resolve(ErrorHandlingService.self) ?? ErrorHandlingService()
    }
    
    // MARK: - Initialization
    private init() {
        registerDefaultServices()
    }
    
    // MARK: - Registration
    func register<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        services[key] = instance
        logDebug("Registered instance for \(key)", category: "DI")
    }
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
        logDebug("Registered factory for \(key)", category: "DI")
    }
    
    func registerSingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
        let instance = factory()
        register(type, instance: instance)
    }
    
    // MARK: - Resolution
    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        
        // Check if we have an instance
        if let instance = services[key] as? T {
            return instance
        }
        
        // Check if we have a factory
        if let factory = factories[key] {
            let instance = factory() as? T
            return instance
        }
        
        logWarning("No registration found for \(key)", category: "DI")
        return nil
    }
    
    func resolve<T>(_ type: T.Type, orElse defaultValue: T) -> T {
        return resolve(type) ?? defaultValue
    }
    
    // MARK: - Private Methods
    private func registerDefaultServices() {
        // Register core services
        registerSingleton(APIClient.self) {
            APIClient()
        }
        
        registerSingleton(APIClientProtocol.self) {
            APIClient()
        }
        
        registerSingleton(WebSocketManager.self) {
            WebSocketManager(endpoint: "/ws")
        }
        
        registerSingleton(SwiftDataContainer.self) {
            SwiftDataContainer.shared
        }
        
        registerSingleton(ErrorHandlingService.self) {
            ErrorHandlingService()
        }
        
        // Register view models (factories for new instances)
        register(ProjectsViewModel.self) {
            ProjectsViewModel()
        }
        
        register(SessionViewModel.self) {
            SessionViewModel()
        }
        
        register(ChatViewModel.self) {
            ChatViewModel()
        }
        
        register(FileExplorerViewModel.self) {
            FileExplorerViewModel()
        }
        
        register(TerminalViewModel.self) {
            TerminalViewModel()
        }
        
        register(SettingsViewModel.self) {
            SettingsViewModel()
        }
        
        logInfo("Default services registered", category: "DI")
    }
    
    // MARK: - Reset
    func reset() {
        services.removeAll()
        factories.removeAll()
        registerDefaultServices()
        logInfo("DI Container reset", category: "DI")
    }
}

// MARK: - Property Wrapper for Dependency Injection
@propertyWrapper
struct Injected<T> {
    private var value: T?
    
    init() {}
    
    var wrappedValue: T {
        get {
            if let value = value {
                return value
            }
            
            guard let resolved = DIContainer.shared.resolve(T.self) else {
                fatalError("No registered service for type \(T.self)")
            }
            
            value = resolved
            return resolved
        }
        mutating set {
            value = newValue
        }
    }
}

// MARK: - Property Wrapper for Optional Injection
@propertyWrapper
struct OptionalInjected<T> {
    private var value: T?
    
    init() {}
    
    var wrappedValue: T? {
        get {
            if let value = value {
                return value
            }
            
            let resolved = DIContainer.shared.resolve(T.self)
            value = resolved
            return resolved
        }
        mutating set {
            value = newValue
        }
    }
}

// MARK: - Injectable Protocol
protocol Injectable {
    associatedtype Dependencies
    init(dependencies: Dependencies)
}

// MARK: - View Model Base Classes (Placeholders)
class ProjectsViewModel: ObservableObject {
    @Injected var apiClient: APIClientProtocol
    @Injected var dataContainer: SwiftDataContainer
    @Injected var webSocketManager: WebSocketManager
    
    init() {}
}

class SessionViewModel: ObservableObject {
    @Injected var apiClient: APIClientProtocol
    @Injected var dataContainer: SwiftDataContainer
    @Injected var webSocketManager: WebSocketManager
    
    init() {}
}

class ChatViewModel: ObservableObject {
    @Injected var apiClient: APIClientProtocol
    @Injected var dataContainer: SwiftDataContainer
    @Injected var webSocketManager: WebSocketManager
    
    init() {}
}

class FileExplorerViewModel: ObservableObject {
    @Injected var apiClient: APIClientProtocol
    @Injected var webSocketManager: WebSocketManager
    
    init() {}
}

class TerminalViewModel: ObservableObject {
    @Injected var webSocketManager: WebSocketManager
    
    init() {}
}

class SettingsViewModel: ObservableObject {
    @Injected var apiClient: APIClientProtocol
    @Injected var dataContainer: SwiftDataContainer
    
    init() {}
}