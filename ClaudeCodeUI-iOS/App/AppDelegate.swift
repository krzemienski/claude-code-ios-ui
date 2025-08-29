//
//  AppDelegate.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Setup logging
        Logger.shared.minimumLogLevel = .debug
        Logger.shared.isFileLoggingEnabled = true
        
        // Setup error handling
        ErrorHandlingService.shared.setupCrashReporting()
        
        // SECURITY FIX: Migrate authentication tokens from UserDefaults to secure Keychain storage
        // This is a one-time migration to move away from insecure storage
        // TODO: Add AuthenticationMigration to Xcode project
        // AuthenticationMigration.performMigrationIfNeeded()
        
        // Initialize authentication manager (will load tokens from secure storage)
        // TODO: Add AuthenticationManager to Xcode project
        // Task {
        //     await AuthenticationManager.shared.checkAuthenticationStatus()
        // }
        
        // Configure appearance
        setupAppearance()
        
        // Register for authentication notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthenticationChange),
            name: NSNotification.Name("authenticationChanged"),
            object: nil
        )
        
        logInfo("Claude Code UI launched", category: "App")
        // logInfo("🔐 Authentication migration status: \(AuthenticationMigration.isMigrationComplete ? "Complete" : "Pending")", category: "App")
        
        return true
    }
    
    @objc private func handleAuthenticationChange(_ notification: Notification) {
        logInfo("🔐 Authentication state changed", category: "App")
        
        // Handle authentication state changes if needed
        // For example, refresh UI or reconnect WebSockets
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // MARK: - Private Methods
    
    private func setupAppearance() {
        // Configure navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = CyberpunkTheme.background
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: CyberpunkTheme.textPrimary,
            .font: UIFont.systemFont(ofSize: 18, weight: .bold)
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: CyberpunkTheme.textPrimary,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = CyberpunkTheme.primaryCyan
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = CyberpunkTheme.background
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = CyberpunkTheme.primaryCyan
        UITabBar.appearance().unselectedItemTintColor = CyberpunkTheme.textTertiary
        
        // Configure other UI elements
        UITextField.appearance().tintColor = CyberpunkTheme.primaryCyan
        UITextView.appearance().tintColor = CyberpunkTheme.primaryCyan
        UISwitch.appearance().onTintColor = CyberpunkTheme.primaryCyan
        UISlider.appearance().tintColor = CyberpunkTheme.primaryCyan
        UIProgressView.appearance().tintColor = CyberpunkTheme.primaryCyan
        
        // Configure window tint
        UIWindow.appearance().tintColor = CyberpunkTheme.primaryCyan
    }
}