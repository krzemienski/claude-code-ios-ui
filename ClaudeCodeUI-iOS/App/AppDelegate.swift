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
        // Override point for customization after application launch.
        
        // Set up appearance
        setupAppearance()
        
        return true
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
        // Force dark mode
        if #available(iOS 13.0, *) {
            UIWindow.appearance().overrideUserInterfaceStyle = .dark
        }
        
        // Navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(red: 10/255, green: 10/255, blue: 15/255, alpha: 1.0) // #0A0A0F
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(red: 0/255, green: 217/255, blue: 255/255, alpha: 1.0) // #00D9FF
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(red: 0/255, green: 217/255, blue: 255/255, alpha: 1.0) // #00D9FF
        ]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        
        // Tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(red: 10/255, green: 10/255, blue: 15/255, alpha: 1.0) // #0A0A0F
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Set tint color
        UITabBar.appearance().tintColor = UIColor(red: 0/255, green: 217/255, blue: 255/255, alpha: 1.0) // #00D9FF
    }
}