//
//  AnalyticsManager.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-21.
//

import Foundation
import UIKit
import os.log

/// Analytics event types
enum AnalyticsEvent {
    // App lifecycle
    case appLaunched
    case appEnteredBackground
    case appEnteredForeground
    case appTerminated
    
    // Navigation
    case screenViewed(name: String)
    case tabChanged(from: String, to: String)
    case navigationPush(to: String)
    case navigationPop(from: String)
    
    // Projects
    case projectOpened(name: String)
    case projectCreated(name: String)
    case projectDeleted(name: String)
    case projectRenamed(oldName: String, newName: String)
    case projectDuplicated(name: String)
    case projectArchived(name: String)
    
    // Sessions
    case sessionCreated(projectName: String, sessionId: String)
    case sessionOpened(projectName: String, sessionId: String)
    case sessionDeleted(projectName: String, sessionId: String)
    case sessionRenamed(projectName: String, sessionId: String)
    
    // Messages
    case messageSent(projectName: String, sessionId: String, length: Int)
    case messageReceived(projectName: String, sessionId: String, length: Int)
    case messageDeleted(projectName: String, sessionId: String)
    case messageCopied(projectName: String, sessionId: String)
    
    // Files
    case fileOpened(path: String, type: String)
    case fileCreated(path: String)
    case fileDeleted(path: String)
    case fileRenamed(oldPath: String, newPath: String)
    case fileDuplicated(path: String)
    case fileEdited(path: String, changeSize: Int)
    
    // Terminal
    case terminalCommandExecuted(command: String, projectName: String)
    case terminalSessionStarted(projectName: String)
    case terminalSessionEnded(projectName: String, duration: TimeInterval)
    
    // Search
    case searchPerformed(query: String, scope: String, resultCount: Int)
    case searchResultSelected(query: String, filePath: String)
    case searchFilterChanged(filterType: String, value: String)
    
    // Git
    case gitCommit(projectName: String, fileCount: Int)
    case gitPush(projectName: String, branch: String)
    case gitPull(projectName: String, branch: String)
    case gitBranchCreated(projectName: String, branchName: String)
    case gitBranchSwitched(projectName: String, from: String, to: String)
    case gitMerge(projectName: String, from: String, to: String)
    
    // MCP
    case mcpServerAdded(name: String, type: String)
    case mcpServerRemoved(name: String)
    case mcpServerConnected(name: String)
    case mcpServerDisconnected(name: String, reason: String)
    case mcpCommandExecuted(serverName: String, command: String)
    
    // Settings
    case settingChanged(key: String, oldValue: Any?, newValue: Any?)
    case themeChanged(theme: String)
    case fontSizeChanged(size: CGFloat)
    case backupCreated
    case backupRestored
    
    // Performance
    case performanceMetric(name: String, value: Double, unit: String)
    case memoryWarning(level: Int)
    case networkLatency(endpoint: String, latency: TimeInterval)
    case crashOccurred(reason: String, stackTrace: String)
    
    // User Actions
    case buttonTapped(name: String, screen: String)
    case swipeAction(type: String, screen: String)
    case pullToRefresh(screen: String)
    case contextMenuOpened(screen: String, itemType: String)
    case shareAction(contentType: String)
    
    // Errors
    case errorOccurred(code: String, message: String, screen: String)
    case apiError(endpoint: String, statusCode: Int, message: String)
    case webSocketError(type: String, message: String)
    case validationError(field: String, message: String)
}

/// Analytics provider protocol
protocol AnalyticsProvider {
    func track(event: String, properties: [String: Any]?)
    func setUserProperty(key: String, value: Any)
    func setUserId(_ userId: String?)
    func flush()
    func reset()
}

/// Console analytics provider for development
class ConsoleAnalyticsProvider: AnalyticsProvider {
    private let logger = os.Logger(subsystem: "com.claudecode.ui", category: "Analytics")
    
    func track(event: String, properties: [String: Any]?) {
        if let properties = properties {
            logger.info("📊 Analytics Event: \(event) | Properties: \(String(describing: properties))")
        } else {
            logger.info("📊 Analytics Event: \(event)")
        }
    }
    
    func setUserProperty(key: String, value: Any) {
        logger.info("📊 User Property: \(key) = \(String(describing: value))")
    }
    
    func setUserId(_ userId: String?) {
        logger.info("📊 User ID: \(userId ?? "nil")")
    }
    
    func flush() {
        logger.info("📊 Analytics flushed")
    }
    
    func reset() {
        logger.info("📊 Analytics reset")
    }
}

/// Local storage analytics provider
class LocalAnalyticsProvider: AnalyticsProvider {
    private let queue = DispatchQueue(label: "com.claudecode.analytics", qos: .background)
    private let fileManager = FileManager.default
    private let analyticsDirectory: URL
    private let maxEventsPerFile = 1000
    private let maxFileSize = 10 * 1024 * 1024 // 10MB
    
    init() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        analyticsDirectory = documentsPath.appendingPathComponent("Analytics")
        
        // Create analytics directory if needed
        try? fileManager.createDirectory(at: analyticsDirectory, withIntermediateDirectories: true)
    }
    
    func track(event: String, properties: [String: Any]?) {
        queue.async { [weak self] in
            let eventData: [String: Any] = [
                "event": event,
                "properties": properties ?? [:],
                "timestamp": Date().timeIntervalSince1970,
                "sessionId": self?.getCurrentSessionId() ?? "",
                "deviceInfo": self?.getDeviceInfo() ?? [:]
            ]
            
            self?.writeEvent(eventData)
        }
    }
    
    func setUserProperty(key: String, value: Any) {
        queue.async { [weak self] in
            self?.updateUserProperties([key: value])
        }
    }
    
    func setUserId(_ userId: String?) {
        queue.async { [weak self] in
            self?.updateUserProperties(["userId": userId ?? NSNull()])
        }
    }
    
    func flush() {
        queue.async { [weak self] in
            self?.compressOldFiles()
        }
    }
    
    func reset() {
        queue.async { [weak self] in
            guard let self = self else { return }
            // Remove all analytics files
            if let files = try? self.fileManager.contentsOfDirectory(at: self.analyticsDirectory, includingPropertiesForKeys: nil) {
                for file in files {
                    try? self.fileManager.removeItem(at: file)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func getCurrentSessionId() -> String {
        // Get or create session ID
        if let sessionId = UserDefaults.standard.string(forKey: "AnalyticsSessionId") {
            return sessionId
        } else {
            let sessionId = UUID().uuidString
            UserDefaults.standard.set(sessionId, forKey: "AnalyticsSessionId")
            return sessionId
        }
    }
    
    private func getDeviceInfo() -> [String: Any] {
        return [
            "model": UIDevice.current.model,
            "systemVersion": UIDevice.current.systemVersion,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "Unknown",
            "buildNumber": Bundle.main.infoDictionary?["CFBundleVersion"] ?? "Unknown",
            "screenSize": "\(UIScreen.main.bounds.width)x\(UIScreen.main.bounds.height)",
            "language": {
                if #available(iOS 16, *) {
                    return Locale.current.language.languageCode?.identifier ?? "en"
                } else {
                    return Locale.current.languageCode ?? "en"
                }
            }()
        ]
    }
    
    private func writeEvent(_ eventData: [String: Any]) {
        let fileName = "analytics_\(Date().timeIntervalSince1970).json"
        let fileURL = analyticsDirectory.appendingPathComponent(fileName)
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: eventData)
            try jsonData.write(to: fileURL)
        } catch {
            print("Failed to write analytics event: \(error)")
        }
    }
    
    private func updateUserProperties(_ properties: [String: Any]) {
        let userPropertiesURL = analyticsDirectory.appendingPathComponent("user_properties.json")
        
        var currentProperties: [String: Any] = [:]
        if let data = try? Data(contentsOf: userPropertiesURL),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            currentProperties = existing
        }
        
        // Merge new properties
        for (key, value) in properties {
            currentProperties[key] = value
        }
        
        // Save updated properties
        if let jsonData = try? JSONSerialization.data(withJSONObject: currentProperties) {
            try? jsonData.write(to: userPropertiesURL)
        }
    }
    
    private func compressOldFiles() {
        // Compress analytics files older than 7 days
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        
        if let files = try? fileManager.contentsOfDirectory(at: analyticsDirectory, includingPropertiesForKeys: [.creationDateKey]) {
            for file in files where file.lastPathComponent.hasPrefix("analytics_") {
                if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
                   let creationDate = attributes[.creationDate] as? Date,
                   creationDate < sevenDaysAgo {
                    // Archive old file
                    // In production, you'd compress or upload these
                    try? fileManager.removeItem(at: file)
                }
            }
        }
    }
}

/// Main analytics manager
final class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private var providers: [AnalyticsProvider] = []
    private let performanceTracker = PerformanceTracker()
    private var screenStartTimes: [String: Date] = [:]
    private var sessionStartTime: Date?
    
    private init() {
        setupProviders()
        setupNotifications()
    }
    
    private func setupProviders() {
        // Add console provider for debug builds
        #if DEBUG
        providers.append(ConsoleAnalyticsProvider())
        #endif
        
        // Add local storage provider
        providers.append(LocalAnalyticsProvider())
        
        // In production, you would add real providers here:
        // providers.append(FirebaseAnalyticsProvider())
        // providers.append(MixpanelAnalyticsProvider())
        // providers.append(AmplitudeAnalyticsProvider())
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(memoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    // MARK: - Public Methods
    
    func track(_ event: AnalyticsEvent) {
        let (eventName, properties) = convertEventToNameAndProperties(event)
        
        providers.forEach { provider in
            provider.track(event: eventName, properties: properties)
        }
    }
    
    func startScreenTracking(_ screenName: String) {
        screenStartTimes[screenName] = Date()
        track(.screenViewed(name: screenName))
    }
    
    func endScreenTracking(_ screenName: String) {
        guard let startTime = screenStartTimes[screenName] else { return }
        let duration = Date().timeIntervalSince(startTime)
        
        track(.performanceMetric(
            name: "screen_view_duration",
            value: duration,
            unit: "seconds"
        ))
        
        screenStartTimes.removeValue(forKey: screenName)
    }
    
    func startSession() {
        sessionStartTime = Date()
        track(.appLaunched)
    }
    
    func endSession() {
        if let startTime = sessionStartTime {
            let duration = Date().timeIntervalSince(startTime)
            track(.performanceMetric(
                name: "session_duration",
                value: duration,
                unit: "seconds"
            ))
        }
    }
    
    func setUserId(_ userId: String?) {
        providers.forEach { $0.setUserId(userId) }
    }
    
    func setUserProperty(key: String, value: Any) {
        providers.forEach { $0.setUserProperty(key: key, value: value) }
    }
    
    func flush() {
        providers.forEach { $0.flush() }
    }
    
    func reset() {
        providers.forEach { $0.reset() }
        screenStartTimes.removeAll()
        sessionStartTime = nil
    }
    
    // MARK: - Performance Tracking
    
    func trackPerformance(_ name: String, block: () throws -> Void) rethrows {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            track(.performanceMetric(name: name, value: duration * 1000, unit: "ms"))
        }
        try block()
    }
    
    func trackAPICall(endpoint: String, statusCode: Int, duration: TimeInterval) {
        track(.performanceMetric(
            name: "api_call_duration",
            value: duration * 1000,
            unit: "ms"
        ))
        
        if statusCode >= 400 {
            track(.apiError(
                endpoint: endpoint,
                statusCode: statusCode,
                message: "HTTP \(statusCode)"
            ))
        }
    }
    
    // MARK: - Private Methods
    
    private func convertEventToNameAndProperties(_ event: AnalyticsEvent) -> (String, [String: Any]) {
        switch event {
        case .appLaunched:
            return ("app_launched", [:])
        case .appEnteredBackground:
            return ("app_entered_background", [:])
        case .appEnteredForeground:
            return ("app_entered_foreground", [:])
        case .appTerminated:
            return ("app_terminated", [:])
            
        case .screenViewed(let name):
            return ("screen_viewed", ["screen_name": name])
        case .tabChanged(let from, let to):
            return ("tab_changed", ["from": from, "to": to])
        case .navigationPush(let to):
            return ("navigation_push", ["destination": to])
        case .navigationPop(let from):
            return ("navigation_pop", ["source": from])
            
        case .projectOpened(let name):
            return ("project_opened", ["project_name": name])
        case .projectCreated(let name):
            return ("project_created", ["project_name": name])
        case .projectDeleted(let name):
            return ("project_deleted", ["project_name": name])
        case .projectRenamed(let oldName, let newName):
            return ("project_renamed", ["old_name": oldName, "new_name": newName])
        case .projectDuplicated(let name):
            return ("project_duplicated", ["project_name": name])
        case .projectArchived(let name):
            return ("project_archived", ["project_name": name])
            
        case .sessionCreated(let projectName, let sessionId):
            return ("session_created", ["project_name": projectName, "session_id": sessionId])
        case .sessionOpened(let projectName, let sessionId):
            return ("session_opened", ["project_name": projectName, "session_id": sessionId])
        case .sessionDeleted(let projectName, let sessionId):
            return ("session_deleted", ["project_name": projectName, "session_id": sessionId])
        case .sessionRenamed(let projectName, let sessionId):
            return ("session_renamed", ["project_name": projectName, "session_id": sessionId])
            
        case .messageSent(let projectName, let sessionId, let length):
            return ("message_sent", ["project_name": projectName, "session_id": sessionId, "length": length])
        case .messageReceived(let projectName, let sessionId, let length):
            return ("message_received", ["project_name": projectName, "session_id": sessionId, "length": length])
        case .messageDeleted(let projectName, let sessionId):
            return ("message_deleted", ["project_name": projectName, "session_id": sessionId])
        case .messageCopied(let projectName, let sessionId):
            return ("message_copied", ["project_name": projectName, "session_id": sessionId])
            
        case .fileOpened(let path, let type):
            return ("file_opened", ["path": path, "type": type])
        case .fileCreated(let path):
            return ("file_created", ["path": path])
        case .fileDeleted(let path):
            return ("file_deleted", ["path": path])
        case .fileRenamed(let oldPath, let newPath):
            return ("file_renamed", ["old_path": oldPath, "new_path": newPath])
        case .fileDuplicated(let path):
            return ("file_duplicated", ["path": path])
        case .fileEdited(let path, let changeSize):
            return ("file_edited", ["path": path, "change_size": changeSize])
            
        case .terminalCommandExecuted(let command, let projectName):
            return ("terminal_command", ["command": command, "project_name": projectName])
        case .terminalSessionStarted(let projectName):
            return ("terminal_session_started", ["project_name": projectName])
        case .terminalSessionEnded(let projectName, let duration):
            return ("terminal_session_ended", ["project_name": projectName, "duration": duration])
            
        case .searchPerformed(let query, let scope, let resultCount):
            return ("search_performed", ["query": query, "scope": scope, "result_count": resultCount])
        case .searchResultSelected(let query, let filePath):
            return ("search_result_selected", ["query": query, "file_path": filePath])
        case .searchFilterChanged(let filterType, let value):
            return ("search_filter_changed", ["filter_type": filterType, "value": value])
            
        case .gitCommit(let projectName, let fileCount):
            return ("git_commit", ["project_name": projectName, "file_count": fileCount])
        case .gitPush(let projectName, let branch):
            return ("git_push", ["project_name": projectName, "branch": branch])
        case .gitPull(let projectName, let branch):
            return ("git_pull", ["project_name": projectName, "branch": branch])
        case .gitBranchCreated(let projectName, let branchName):
            return ("git_branch_created", ["project_name": projectName, "branch_name": branchName])
        case .gitBranchSwitched(let projectName, let from, let to):
            return ("git_branch_switched", ["project_name": projectName, "from": from, "to": to])
        case .gitMerge(let projectName, let from, let to):
            return ("git_merge", ["project_name": projectName, "from": from, "to": to])
            
        case .mcpServerAdded(let name, let type):
            return ("mcp_server_added", ["name": name, "type": type])
        case .mcpServerRemoved(let name):
            return ("mcp_server_removed", ["name": name])
        case .mcpServerConnected(let name):
            return ("mcp_server_connected", ["name": name])
        case .mcpServerDisconnected(let name, let reason):
            return ("mcp_server_disconnected", ["name": name, "reason": reason])
        case .mcpCommandExecuted(let serverName, let command):
            return ("mcp_command_executed", ["server_name": serverName, "command": command])
            
        case .settingChanged(let key, let oldValue, let newValue):
            return ("setting_changed", ["key": key, "old_value": String(describing: oldValue), "new_value": String(describing: newValue)])
        case .themeChanged(let theme):
            return ("theme_changed", ["theme": theme])
        case .fontSizeChanged(let size):
            return ("font_size_changed", ["size": size])
        case .backupCreated:
            return ("backup_created", [:])
        case .backupRestored:
            return ("backup_restored", [:])
            
        case .performanceMetric(let name, let value, let unit):
            return ("performance_metric", ["metric_name": name, "value": value, "unit": unit])
        case .memoryWarning(let level):
            return ("memory_warning", ["level": level])
        case .networkLatency(let endpoint, let latency):
            return ("network_latency", ["endpoint": endpoint, "latency": latency])
        case .crashOccurred(let reason, let stackTrace):
            return ("crash_occurred", ["reason": reason, "stack_trace": stackTrace])
            
        case .buttonTapped(let name, let screen):
            return ("button_tapped", ["button_name": name, "screen": screen])
        case .swipeAction(let type, let screen):
            return ("swipe_action", ["type": type, "screen": screen])
        case .pullToRefresh(let screen):
            return ("pull_to_refresh", ["screen": screen])
        case .contextMenuOpened(let screen, let itemType):
            return ("context_menu_opened", ["screen": screen, "item_type": itemType])
        case .shareAction(let contentType):
            return ("share_action", ["content_type": contentType])
            
        case .errorOccurred(let code, let message, let screen):
            return ("error_occurred", ["code": code, "message": message, "screen": screen])
        case .apiError(let endpoint, let statusCode, let message):
            return ("api_error", ["endpoint": endpoint, "status_code": statusCode, "message": message])
        case .webSocketError(let type, let message):
            return ("websocket_error", ["type": type, "message": message])
        case .validationError(let field, let message):
            return ("validation_error", ["field": field, "message": message])
        }
    }
    
    // MARK: - Notification Handlers
    
    @objc private func appDidEnterBackground() {
        track(.appEnteredBackground)
        flush()
    }
    
    @objc private func appWillTerminate() {
        endSession()
        track(.appTerminated)
        flush()
    }
    
    @objc private func memoryWarning() {
        track(.memoryWarning(level: 1))
    }
}

// MARK: - Performance Tracker

private class PerformanceTracker {
    private var startTimes: [String: CFAbsoluteTime] = [:]
    private let queue = DispatchQueue(label: "com.claudecode.performance", attributes: .concurrent)
    
    func start(_ identifier: String) {
        queue.async(flags: .barrier) {
            self.startTimes[identifier] = CFAbsoluteTimeGetCurrent()
        }
    }
    
    func end(_ identifier: String) -> TimeInterval? {
        var duration: TimeInterval?
        queue.sync {
            if let startTime = startTimes[identifier] {
                duration = CFAbsoluteTimeGetCurrent() - startTime
            }
        }
        queue.async(flags: .barrier) {
            self.startTimes.removeValue(forKey: identifier)
        }
        return duration
    }
}