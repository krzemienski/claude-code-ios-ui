//
//  PushNotificationManager.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-27.
//

import UIKit
import UserNotifications

// MARK: - Push Notification Manager

/// Central manager for push notifications and local notifications
final class PushNotificationManager: NSObject {
    
    // MARK: - Singleton
    
    static let shared = PushNotificationManager()
    
    // MARK: - Properties
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var deviceToken: String?
    private var isRegistered = false
    private var pendingNotifications: [PendingNotification] = []
    
    // Notification categories
    private let messageCategory = "MESSAGE_CATEGORY"
    private let sessionCategory = "SESSION_CATEGORY"
    private let syncCategory = "SYNC_CATEGORY"
    private let updateCategory = "UPDATE_CATEGORY"
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
        setupNotificationCategories()
    }
    
    // MARK: - Setup
    
    func configure() {
        print("🔔 Configuring push notifications")
        requestAuthorization()
        registerForRemoteNotifications()
    }
    
    private func setupNotificationCategories() {
        // Message category with quick reply
        let replyAction = UNTextInputNotificationAction(
            identifier: "REPLY_ACTION",
            title: "Reply",
            options: [],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Type your message..."
        )
        
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "View",
            options: [.foreground]
        )
        
        let messageCategory = UNNotificationCategory(
            identifier: messageCategory,
            actions: [replyAction, viewAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Session category
        let openSessionAction = UNNotificationAction(
            identifier: "OPEN_SESSION_ACTION",
            title: "Open Session",
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Dismiss",
            options: [.destructive]
        )
        
        let sessionCategory = UNNotificationCategory(
            identifier: sessionCategory,
            actions: [openSessionAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Sync category
        let syncNowAction = UNNotificationAction(
            identifier: "SYNC_NOW_ACTION",
            title: "Sync Now",
            options: []
        )
        
        let syncCategory = UNNotificationCategory(
            identifier: syncCategory,
            actions: [syncNowAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Update category
        let updateAction = UNNotificationAction(
            identifier: "UPDATE_ACTION",
            title: "Update Now",
            options: [.foreground]
        )
        
        let remindLaterAction = UNNotificationAction(
            identifier: "REMIND_LATER_ACTION",
            title: "Remind Later",
            options: []
        )
        
        let updateCategory = UNNotificationCategory(
            identifier: updateCategory,
            actions: [updateAction, remindLaterAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Register categories
        notificationCenter.setNotificationCategories([
            messageCategory,
            sessionCategory,
            syncCategory,
            updateCategory
        ])
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound, .provisional]) { [weak self] granted, error in
            if granted {
                print("✅ Push notification authorization granted")
                self?.isRegistered = true
                
                // Track analytics
                // AnalyticsManager.shared.track(.pushNotificationEnabled) // Not implemented yet
                
                // Process pending notifications
                self?.processPendingNotifications()
            } else if let error = error {
                print("❌ Push notification authorization error: \(error)")
                // AnalyticsManager.shared.track(.pushNotificationDenied) // Not implemented yet
            } else {
                print("⚠️ Push notification authorization denied")
                // AnalyticsManager.shared.track(.pushNotificationDenied) // Not implemented yet
            }
        }
    }
    
    func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: - Device Token
    
    func registerDeviceToken(_ deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        self.deviceToken = token
        
        print("📱 Device token registered: \(token)")
        
        // Send token to backend
        Task {
            await sendTokenToBackend(token)
        }
    }
    
    func handleRegistrationError(_ error: Error) {
        print("❌ Failed to register for push notifications: \(error)")
        // AnalyticsManager.shared.track(.pushNotificationRegistrationFailed(error: error.localizedDescription)) // Not implemented yet
    }
    
    private func sendTokenToBackend(_ token: String) async {
        // Send device token to backend for push notifications
        // This would typically call an API endpoint to register the token
        print("📤 Sending device token to backend: \(token)")
        
        // Store token locally
        UserDefaults.standard.set(token, forKey: "pushNotificationToken")
    }
    
    // MARK: - Local Notifications
    
    func scheduleLocalNotification(
        title: String,
        body: String,
        subtitle: String? = nil,
        badge: NSNumber? = nil,
        sound: UNNotificationSound = .default,
        categoryIdentifier: String? = nil,
        userInfo: [String: Any]? = nil,
        trigger: UNNotificationTrigger? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        
        if let subtitle = subtitle {
            content.subtitle = subtitle
        }
        
        if let badge = badge {
            content.badge = badge
        }
        
        content.sound = sound
        
        if let categoryIdentifier = categoryIdentifier {
            content.categoryIdentifier = categoryIdentifier
        }
        
        if let userInfo = userInfo {
            content.userInfo = userInfo
        }
        
        // Default to immediate notification if no trigger specified
        let notificationTrigger = trigger ?? UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: notificationTrigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule local notification: \(error)")
            } else {
                print("✅ Local notification scheduled")
            }
        }
    }
    
    // MARK: - Notification Types
    
    func notifyNewMessage(from: String, content: String, sessionId: String) {
        scheduleLocalNotification(
            title: "New Message from \(from)",
            body: content,
            categoryIdentifier: messageCategory,
            userInfo: ["sessionId": sessionId, "type": "message"]
        )
    }
    
    func notifySessionComplete(sessionName: String, messageCount: Int) {
        scheduleLocalNotification(
            title: "Session Complete",
            body: "\(sessionName) completed with \(messageCount) messages",
            categoryIdentifier: sessionCategory,
            userInfo: ["type": "session_complete"]
        )
    }
    
    func notifyOfflineSync(itemCount: Int) {
        guard itemCount > 0 else { return }
        
        scheduleLocalNotification(
            title: "Offline Changes Ready",
            body: "\(itemCount) changes ready to sync",
            categoryIdentifier: syncCategory,
            userInfo: ["itemCount": itemCount, "type": "sync"]
        )
    }
    
    func notifyAppUpdate(version: String) {
        scheduleLocalNotification(
            title: "Update Available",
            body: "Version \(version) is now available",
            categoryIdentifier: updateCategory,
            userInfo: ["version": version, "type": "update"]
        )
    }
    
    func notifyProjectActivity(projectName: String, activity: String) {
        scheduleLocalNotification(
            title: projectName,
            body: activity,
            userInfo: ["projectName": projectName, "type": "project_activity"]
        )
    }
    
    // MARK: - Badge Management
    
    func updateBadgeCount(_ count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
    
    func clearBadge() {
        updateBadgeCount(0)
    }
    
    // MARK: - Pending Notifications
    
    private func processPendingNotifications() {
        guard isRegistered else { return }
        
        for notification in pendingNotifications {
            scheduleLocalNotification(
                title: notification.title,
                body: notification.body,
                subtitle: notification.subtitle,
                badge: notification.badge,
                sound: notification.sound,
                categoryIdentifier: notification.categoryIdentifier,
                userInfo: notification.userInfo,
                trigger: notification.trigger
            )
        }
        
        pendingNotifications.removeAll()
    }
    
    // MARK: - Permission Check
    
    func checkNotificationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    // MARK: - Clear Notifications
    
    func removeAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func removeAllDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    func removeNotification(withIdentifier identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationManager: UNUserNotificationCenterDelegate {
    
    // Called when notification is received while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("📬 Notification received in foreground: \(notification.request.content.title)")
        
        // Show notification even when app is in foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
        
        // Track analytics
        // AnalyticsManager.shared.track(.pushNotificationReceived(type: notification.request.content.categoryIdentifier)) // Not implemented yet
    }
    
    // Called when user interacts with notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("📬 Notification interaction: \(response.actionIdentifier)")
        
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case "REPLY_ACTION":
            if let textResponse = response as? UNTextInputNotificationResponse {
                handleReplyAction(text: textResponse.userText, userInfo: userInfo)
            }
            
        case "VIEW_ACTION":
            handleViewAction(userInfo: userInfo)
            
        case "OPEN_SESSION_ACTION":
            handleOpenSessionAction(userInfo: userInfo)
            
        case "SYNC_NOW_ACTION":
            handleSyncAction(userInfo: userInfo)
            
        case "UPDATE_ACTION":
            handleUpdateAction(userInfo: userInfo)
            
        case "REMIND_LATER_ACTION":
            scheduleReminderNotification(userInfo: userInfo)
            
        case UNNotificationDefaultActionIdentifier:
            handleDefaultAction(userInfo: userInfo)
            
        case UNNotificationDismissActionIdentifier:
            print("Notification dismissed")
            
        default:
            break
        }
        
        // Track analytics
        // AnalyticsManager.shared.track(.pushNotificationInteraction(action: response.actionIdentifier)) // Not implemented yet
        
        completionHandler()
    }
    
    // MARK: - Action Handlers
    
    private func handleReplyAction(text: String, userInfo: [AnyHashable: Any]) {
        guard let sessionId = userInfo["sessionId"] as? String else { return }
        
        print("💬 Quick reply: \(text) for session: \(sessionId)")
        
        // Send message through WebSocket
        if let projectId = userInfo["projectId"] as? String,
           let projectPath = userInfo["projectPath"] as? String {
            // Cast to WebSocketManager to access sendMessage method
            if let wsManager = DIContainer.shared.webSocketManager as? WebSocketManager {
                wsManager.sendMessage(text, projectId: projectId, projectPath: projectPath)
            }
        }
    }
    
    private func handleViewAction(userInfo: [AnyHashable: Any]) {
        guard let sessionId = userInfo["sessionId"] as? String else { return }
        
        print("👁️ View session: \(sessionId)")
        
        // Navigate to session
        NotificationCenter.default.post(
            name: .navigateToSession,
            object: nil,
            userInfo: ["sessionId": sessionId]
        )
    }
    
    private func handleOpenSessionAction(userInfo: [AnyHashable: Any]) {
        guard let sessionId = userInfo["sessionId"] as? String else { return }
        
        print("📂 Open session: \(sessionId)")
        
        // Navigate to session
        NotificationCenter.default.post(
            name: .navigateToSession,
            object: nil,
            userInfo: ["sessionId": sessionId]
        )
    }
    
    private func handleSyncAction(userInfo: [AnyHashable: Any]) {
        print("🔄 Sync now action triggered")
        
        Task {
            try? await OfflineManager.shared.forceSyncNow()
        }
    }
    
    private func handleUpdateAction(userInfo: [AnyHashable: Any]) {
        guard let version = userInfo["version"] as? String else { return }
        
        print("⬆️ Update to version: \(version)")
        
        // Open App Store
        if let url = URL(string: "https://apps.apple.com/app/idYOUR_APP_ID") {
            UIApplication.shared.open(url)
        }
    }
    
    private func scheduleReminderNotification(userInfo: [AnyHashable: Any]) {
        guard let version = userInfo["version"] as? String else { return }
        
        // Schedule reminder in 24 hours
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 86400, repeats: false)
        
        scheduleLocalNotification(
            title: "Update Reminder",
            body: "Version \(version) is available",
            categoryIdentifier: updateCategory,
            userInfo: ["version": version, "type": "update_reminder"],
            trigger: trigger
        )
    }
    
    private func handleDefaultAction(userInfo: [AnyHashable: Any]) {
        if let type = userInfo["type"] as? String {
            switch type {
            case "message":
                handleViewAction(userInfo: userInfo)
            case "session_complete":
                handleOpenSessionAction(userInfo: userInfo)
            case "sync":
                handleSyncAction(userInfo: userInfo)
            case "update":
                handleUpdateAction(userInfo: userInfo)
            default:
                print("Unhandled notification type: \(type)")
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToSession = Notification.Name("navigateToSession")
    static let navigateToProject = Notification.Name("navigateToProject")
}

// MARK: - Pending Notification Model

struct PendingNotification {
    let title: String
    let body: String
    let subtitle: String?
    let badge: NSNumber?
    let sound: UNNotificationSound
    let categoryIdentifier: String?
    let userInfo: [String: Any]?
    let trigger: UNNotificationTrigger?
}