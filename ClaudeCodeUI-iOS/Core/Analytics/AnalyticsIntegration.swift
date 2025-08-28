//
//  AnalyticsIntegration.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-21.
//

import UIKit

/// Extension to integrate analytics into all view controllers
extension UIViewController {
    
    private struct AssociatedKeys {
        static var analyticsScreenName = "analyticsScreenName"
        static var analyticsScreenStartTime = "analyticsScreenStartTime"
    }
    
    /// The analytics screen name for this view controller
    var analyticsScreenName: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.analyticsScreenName) as? String
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.analyticsScreenName, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// Track when this screen started being viewed
    private var analyticsScreenStartTime: Date? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.analyticsScreenStartTime) as? Date
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.analyticsScreenStartTime, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// Swizzle viewDidAppear and viewDidDisappear for automatic screen tracking
    static func setupAnalyticsTracking() {
        let originalViewDidAppearSelector = #selector(UIViewController.viewDidAppear(_:))
        let swizzledViewDidAppearSelector = #selector(UIViewController.analytics_viewDidAppear(_:))
        
        let originalViewDidDisappearSelector = #selector(UIViewController.viewDidDisappear(_:))
        let swizzledViewDidDisappearSelector = #selector(UIViewController.analytics_viewDidDisappear(_:))
        
        guard let originalViewDidAppearMethod = class_getInstanceMethod(UIViewController.self, originalViewDidAppearSelector),
              let swizzledViewDidAppearMethod = class_getInstanceMethod(UIViewController.self, swizzledViewDidAppearSelector),
              let originalViewDidDisappearMethod = class_getInstanceMethod(UIViewController.self, originalViewDidDisappearSelector),
              let swizzledViewDidDisappearMethod = class_getInstanceMethod(UIViewController.self, swizzledViewDidDisappearSelector) else {
            return
        }
        
        method_exchangeImplementations(originalViewDidAppearMethod, swizzledViewDidAppearMethod)
        method_exchangeImplementations(originalViewDidDisappearMethod, swizzledViewDidDisappearMethod)
    }
    
    @objc private func analytics_viewDidAppear(_ animated: Bool) {
        // Call original implementation
        analytics_viewDidAppear(animated)
        
        // Track screen view
        if let screenName = determineScreenName() {
            analyticsScreenName = screenName
            analyticsScreenStartTime = Date()
            AnalyticsManager.shared.startScreenTracking(screenName)
        }
    }
    
    @objc private func analytics_viewDidDisappear(_ animated: Bool) {
        // Call original implementation
        analytics_viewDidDisappear(animated)
        
        // Track screen exit
        if let screenName = analyticsScreenName {
            AnalyticsManager.shared.endScreenTracking(screenName)
            analyticsScreenName = nil
            analyticsScreenStartTime = nil
        }
    }
    
    /// Determine the screen name for analytics
    private func determineScreenName() -> String? {
        // Skip container view controllers
        if self is UINavigationController || 
           self is UITabBarController ||
           self is UIPageViewController ||
           self is UISplitViewController {
            return nil
        }
        
        // Get class name and clean it up
        let className = String(describing: type(of: self))
        
        // Map known view controllers to friendly names
        let screenNameMapping: [String: String] = [
            "ProjectsViewController": "Projects",
            "SessionListViewController": "Sessions",
            "ChatViewController": "Chat",
            "FileExplorerViewController": "FileExplorer",
            "TerminalViewController": "Terminal",
            "GitViewController": "Git",
            "MCPServerListViewController": "MCPServers",
            "SettingsViewController": "Settings",
            "TranscriptionViewController": "Transcription",
            "OnboardingViewController": "Onboarding",
            "LoginViewController": "Login"
        ]
        
        return screenNameMapping[className] ?? className
    }
    
    /// Track a button tap event
    func trackButtonTap(_ buttonName: String) {
        if let screenName = analyticsScreenName ?? determineScreenName() {
            AnalyticsManager.shared.track(.buttonTapped(name: buttonName, screen: screenName))
        }
    }
    
    /// Track a swipe action
    func trackSwipeAction(_ type: String) {
        if let screenName = analyticsScreenName ?? determineScreenName() {
            AnalyticsManager.shared.track(.swipeAction(type: type, screen: screenName))
        }
    }
    
    /// Track pull to refresh
    func trackPullToRefresh() {
        if let screenName = analyticsScreenName ?? determineScreenName() {
            AnalyticsManager.shared.track(.pullToRefresh(screen: screenName))
        }
    }
    
    /// Track context menu opened
    func trackContextMenu(itemType: String) {
        if let screenName = analyticsScreenName ?? determineScreenName() {
            AnalyticsManager.shared.track(.contextMenuOpened(screen: screenName, itemType: itemType))
        }
    }
    
    /// Track an error
    func trackError(code: String, message: String) {
        if let screenName = analyticsScreenName ?? determineScreenName() {
            AnalyticsManager.shared.track(.errorOccurred(code: code, message: message, screen: screenName))
        }
    }
}

// MARK: - UITabBarController Extension

extension UITabBarController {
    
    /// Swizzle tab bar delegate methods for analytics
    static func setupTabBarAnalytics() {
        let originalSelector = #selector(UITabBarControllerDelegate.tabBarController(_:didSelect:))
        let swizzledSelector = #selector(UITabBarController.analytics_tabBarController(_:didSelect:))
        
        guard let originalMethod = class_getInstanceMethod(UITabBarController.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UITabBarController.self, swizzledSelector) else {
            return
        }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    @objc private func analytics_tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        // Track tab change
        if let fromTab = tabBarController.selectedViewController?.title,
           let toTab = viewController.title {
            AnalyticsManager.shared.track(.tabChanged(from: fromTab, to: toTab))
        }
        
        // Call any existing delegate method
        if let delegate = tabBarController.delegate,
           delegate.responds(to: #selector(UITabBarControllerDelegate.tabBarController(_:didSelect:))) {
            delegate.tabBarController?(tabBarController, didSelect: viewController)
        }
    }
}

// MARK: - Project Analytics Helpers

extension Project {
    
    /// Track project opened
    func trackOpened() {
        AnalyticsManager.shared.track(.projectOpened(name: self.displayName ?? self.name))
    }
    
    /// Track project created
    func trackCreated() {
        AnalyticsManager.shared.track(.projectCreated(name: self.displayName ?? self.name))
    }
    
    /// Track project deleted
    func trackDeleted() {
        AnalyticsManager.shared.track(.projectDeleted(name: self.displayName ?? self.name))
    }
    
    /// Track project renamed
    func trackRenamed(from oldName: String) {
        AnalyticsManager.shared.track(.projectRenamed(oldName: oldName, newName: self.displayName ?? self.name))
    }
    
    /// Track project duplicated
    func trackDuplicated() {
        AnalyticsManager.shared.track(.projectDuplicated(name: self.displayName ?? self.name))
    }
    
    /// Track project archived
    func trackArchived() {
        AnalyticsManager.shared.track(.projectArchived(name: self.displayName ?? self.name))
    }
}

// MARK: - Session Analytics Helpers

extension Session {
    
    /// Track session created
    func trackCreated(projectName: String) {
        AnalyticsManager.shared.track(.sessionCreated(projectName: projectName, sessionId: self.id))
    }
    
    /// Track session opened
    func trackOpened(projectName: String) {
        AnalyticsManager.shared.track(.sessionOpened(projectName: projectName, sessionId: self.id))
    }
    
    /// Track session deleted
    func trackDeleted(projectName: String) {
        AnalyticsManager.shared.track(.sessionDeleted(projectName: projectName, sessionId: self.id))
    }
    
    /// Track session renamed
    func trackRenamed(projectName: String) {
        AnalyticsManager.shared.track(.sessionRenamed(projectName: projectName, sessionId: self.id))
    }
}

// MARK: - Message Analytics Helpers

extension Message {
    
    /// Track message sent
    func trackSent(projectName: String, sessionId: String) {
        AnalyticsManager.shared.track(.messageSent(
            projectName: projectName,
            sessionId: sessionId,
            length: self.content.count
        ))
    }
    
    /// Track message received
    func trackReceived(projectName: String, sessionId: String) {
        AnalyticsManager.shared.track(.messageReceived(
            projectName: projectName,
            sessionId: sessionId,
            length: self.content.count
        ))
    }
    
    /// Track message deleted
    func trackDeleted(projectName: String, sessionId: String) {
        AnalyticsManager.shared.track(.messageDeleted(
            projectName: projectName,
            sessionId: sessionId
        ))
    }
    
    /// Track message copied
    func trackCopied(projectName: String, sessionId: String) {
        AnalyticsManager.shared.track(.messageCopied(
            projectName: projectName,
            sessionId: sessionId
        ))
    }
}

// MARK: - WebSocket Analytics

extension WebSocketManager {
    
    /// Track WebSocket errors
    func trackWebSocketError(type: String, message: String) {
        AnalyticsManager.shared.track(.webSocketError(type: type, message: message))
    }
}

// MARK: - API Analytics

extension APIClient {
    
    /// Track API errors
    func trackAPIError(endpoint: String, statusCode: Int, message: String) {
        AnalyticsManager.shared.track(.apiError(
            endpoint: endpoint,
            statusCode: statusCode,
            message: message
        ))
    }
    
    /// Track network latency
    func trackNetworkLatency(endpoint: String, latency: TimeInterval) {
        AnalyticsManager.shared.track(.networkLatency(endpoint: endpoint, latency: latency))
    }
}

// MARK: - Performance Analytics

extension UIApplication {
    
    /// Track memory warnings
    func trackMemoryWarning() {
        AnalyticsManager.shared.track(.memoryWarning(level: 1))
    }
    
    /// Track app performance metrics
    func trackPerformanceMetric(name: String, value: Double, unit: String = "ms") {
        AnalyticsManager.shared.track(.performanceMetric(
            name: name,
            value: value,
            unit: unit
        ))
    }
}

// MARK: - Initialize Analytics

public class AnalyticsInitializer {
    
    /// Initialize analytics tracking for the app
    public static func initialize() {
        // Setup method swizzling for automatic tracking
        UIViewController.setupAnalyticsTracking()
        
        // Start session tracking
        AnalyticsManager.shared.startSession()
        
        // Set default user properties
        AnalyticsManager.shared.setUserProperty(key: "app_version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "Unknown")
        AnalyticsManager.shared.setUserProperty(key: "ios_version", value: UIDevice.current.systemVersion)
        AnalyticsManager.shared.setUserProperty(key: "device_model", value: UIDevice.current.model)
        
        print("📊 Analytics initialized successfully")
    }
}