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
    
    // MARK: - Message Persistence Helper
    
    @available(iOS 17.0, *)
    private func persistAllActiveMessages() async {
        // Get current chat view controller if available
        guard let window = window,
              let rootVC = window.rootViewController else { return }
        
        // Find ChatViewController in the navigation hierarchy
        var chatVC: ChatViewController?
        
        if let navController = rootVC as? UINavigationController {
            chatVC = navController.viewControllers.first { $0 is ChatViewController } as? ChatViewController
        } else if let tabController = rootVC as? UITabBarController {
            for viewController in tabController.viewControllers ?? [] {
                if let navController = viewController as? UINavigationController {
                    chatVC = navController.viewControllers.first { $0 is ChatViewController } as? ChatViewController
                    if chatVC != nil { break }
                }
            }
        }
        
        // Persist messages if chat is active
        if let chatVC = chatVC {
            await chatVC.persistCurrentMessages()
        }
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        window?.overrideUserInterfaceStyle = .dark // Force dark mode
        
        // Initialize analytics
        AnalyticsInitializer.initialize()
        
        // Initialize app coordinator with safe unwrapping
        guard let window = window else {
            print("⚠️ Warning: Window is nil in scene delegate")
            return
        }
        
        appCoordinator = AppCoordinator(window: window)
        appCoordinator?.start()
        
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Save any unsaved data
        Task { @MainActor in
            try? DIContainer.shared.dataContainer?.save()
            
            // Persist all messages when app disconnects
            if #available(iOS 17.0, *) {
                await persistAllActiveMessages()
            }
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Track app entered foreground
        AnalyticsManager.shared.track(.appEnteredForeground)
        
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
                print("🚀 WebSocket test would run here if enabled")
                // Test class is in Tests folder, not accessible from main app
                // To run tests, use: RUN_WEBSOCKET_TEST=1 xcodebuild test
            }
        }
        #endif
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Save state and persist messages
        Task { @MainActor in
            try? DIContainer.shared.dataContainer?.save()
            
            // Persist messages when app becomes inactive
            if #available(iOS 17.0, *) {
                await persistAllActiveMessages()
            }
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Track app entered background
        AnalyticsManager.shared.track(.appEnteredBackground)
        AnalyticsManager.shared.flush()
        
        // Save state, persist messages, and disconnect WebSocket
        Task { @MainActor in
            try? DIContainer.shared.dataContainer?.save()
            
            // Persist all messages before going to background
            if #available(iOS 17.0, *) {
                await persistAllActiveMessages()
            }
        }
        DIContainer.shared.webSocketManager.disconnect()
    }
}