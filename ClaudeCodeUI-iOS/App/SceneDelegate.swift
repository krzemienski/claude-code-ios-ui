//
//  SceneDelegate.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        window?.overrideUserInterfaceStyle = .dark // Force dark mode
        
        // Initialize app coordinator
        appCoordinator = AppCoordinator(window: window!)
        appCoordinator?.start()
        
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Save any unsaved data
        try? DIContainer.shared.resolve(SwiftDataContainer.self)?.save()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Restart any paused WebSocket connections
        if let webSocketManager = DIContainer.shared.resolve(WebSocketManager.self) {
            if !webSocketManager.isConnected {
                webSocketManager.connect(to: AppConfig.websocketURL)
            }
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Save state
        try? DIContainer.shared.resolve(SwiftDataContainer.self)?.save()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Save state and disconnect WebSocket
        try? DIContainer.shared.resolve(SwiftDataContainer.self)?.save()
        DIContainer.shared.resolve(WebSocketManager.self)?.disconnect()
    }
}