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
        Task { @MainActor in
            try? DIContainer.shared.dataContainer?.save()
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Restart any paused WebSocket connections
        let webSocketManager = DIContainer.shared.webSocketManager
        if !webSocketManager.isConnected {
            let token = UserDefaults.standard.string(forKey: "authToken")
            webSocketManager.connect(to: AppConfig.websocketURL, with: token)
        }
        
        // Run WebSocket streaming test (only for testing - remove in production)
        #if DEBUG
        if ProcessInfo.processInfo.environment["RUN_WEBSOCKET_TEST"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                print("🚀 Running WebSocket Streaming Test...")
                WebSocketStreamingTest.runLiveTest()
            }
        }
        #endif
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Save state
        Task { @MainActor in
            try? DIContainer.shared.dataContainer?.save()
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Save state and disconnect WebSocket
        Task { @MainActor in
            try? DIContainer.shared.dataContainer?.save()
        }
        DIContainer.shared.webSocketManager.disconnect()
    }
}