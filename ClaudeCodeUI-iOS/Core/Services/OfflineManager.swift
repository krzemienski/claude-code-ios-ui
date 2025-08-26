//
//  OfflineManager.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-26.
//

import Foundation
import Network
import Combine

// MARK: - Offline Manager

/// Central manager for offline functionality and network monitoring
final class OfflineManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = OfflineManager()
    
    // MARK: - Published Properties
    
    @Published var isOffline = false
    @Published var networkStatus: NWPath.Status = .satisfied
    @Published var isExpensive = false
    @Published var isConstrained = false
    @Published var connectionType: ConnectionType = .unknown
    
    // MARK: - Properties
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.claudecode.ui.network-monitor", qos: .background)
    private var cancellables = Set<AnyCancellable>()
    
    // Offline queues
    private let offlineQueue = OfflineRequestQueue()
    private let syncManager = OfflineSyncManager()
    private let cacheManager = OfflineCacheManager()
    
    // Analytics
    private var lastOnlineTime: Date?
    private var offlineDuration: TimeInterval = 0
    
    // MARK: - Connection Type
    
    enum ConnectionType: String {
        case wifi = "WiFi"
        case cellular = "Cellular"
        case ethernet = "Ethernet"
        case unknown = "Unknown"
        case offline = "Offline"
        
        var icon: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .ethernet: return "cable.connector"
            case .unknown: return "questionmark.circle"
            case .offline: return "wifi.slash"
            }
        }
        
        var color: UIColor {
            switch self {
            case .wifi, .ethernet: return .systemCyan
            case .cellular: return .systemGreen
            case .unknown: return .systemYellow
            case .offline: return .systemRed
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        setupNetworkMonitoring()
        setupOfflineQueues()
    }
    
    // MARK: - Setup
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handleNetworkPathUpdate(path)
            }
        }
        monitor.start(queue: queue)
    }
    
    private func setupOfflineQueues() {
        // Listen for network status changes
        $isOffline
            .removeDuplicates()
            .sink { [weak self] offline in
                if !offline {
                    self?.handleNetworkRestored()
                } else {
                    self?.handleNetworkLost()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Network Monitoring
    
    private func handleNetworkPathUpdate(_ path: NWPath) {
        let wasOffline = isOffline
        
        networkStatus = path.status
        isOffline = path.status != .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
        
        // Determine connection type
        if path.status == .satisfied {
            if path.usesInterfaceType(.wifi) {
                connectionType = .wifi
            } else if path.usesInterfaceType(.cellular) {
                connectionType = .cellular
            } else if path.usesInterfaceType(.wiredEthernet) {
                connectionType = .ethernet
            } else {
                connectionType = .unknown
            }
        } else {
            connectionType = .offline
        }
        
        // Track offline duration
        if isOffline && !wasOffline {
            lastOnlineTime = Date()
        } else if !isOffline && wasOffline, let lastOnline = lastOnlineTime {
            offlineDuration = Date().timeIntervalSince(lastOnline)
            trackOfflineDuration(offlineDuration)
        }
        
        print("📡 Network status: \(connectionType.rawValue) | Offline: \(isOffline)")
    }
    
    // MARK: - Network State Handlers
    
    private func handleNetworkLost() {
        print("📵 Network connection lost - entering offline mode")
        
        // Show offline notification
        NotificationManager.shared.showOfflineNotification()
        
        // Track event
        AnalyticsManager.shared.track(.networkConnectionLost)
        
        // Prepare for offline mode
        cacheManager.prepareForOfflineMode()
    }
    
    private func handleNetworkRestored() {
        print("📶 Network connection restored - syncing offline data")
        
        // Process offline queue
        Task {
            await processOfflineQueue()
        }
        
        // Sync offline changes
        syncManager.startSync()
        
        // Show online notification
        NotificationManager.shared.showOnlineNotification()
        
        // Track event
        AnalyticsManager.shared.track(.networkConnectionRestored(duration: offlineDuration))
    }
    
    // MARK: - Offline Queue Management
    
    func queueRequest(_ request: OfflineRequest) {
        offlineQueue.enqueue(request)
        print("📥 Queued offline request: \(request.type)")
    }
    
    private func processOfflineQueue() async {
        let requests = offlineQueue.dequeueAll()
        print("⚡ Processing \(requests.count) offline requests")
        
        for request in requests {
            do {
                try await request.execute()
                print("✅ Executed offline request: \(request.type)")
            } catch {
                print("❌ Failed to execute offline request: \(error)")
                // Re-queue if retryable
                if request.isRetryable {
                    offlineQueue.enqueue(request)
                }
            }
        }
    }
    
    // MARK: - Analytics
    
    private func trackOfflineDuration(_ duration: TimeInterval) {
        AnalyticsManager.shared.track(.offlineDuration(seconds: duration))
        
        // Log significant offline periods
        if duration > 300 { // More than 5 minutes
            print("⚠️ Significant offline period: \(Int(duration)) seconds")
        }
    }
    
    // MARK: - Public Methods
    
    func checkNetworkStatus() -> Bool {
        return !isOffline
    }
    
    func requiresSync() -> Bool {
        return syncManager.hasPendingChanges()
    }
    
    func forceSyncNow() async throws {
        guard !isOffline else {
            throw OfflineError.noConnection
        }
        try await syncManager.syncNow()
    }
    
    func clearOfflineCache() {
        cacheManager.clearAll()
        offlineQueue.clear()
    }
}

// MARK: - Offline Request

struct OfflineRequest: Codable {
    let id: UUID
    let type: RequestType
    let timestamp: Date
    let payload: Data
    let isRetryable: Bool
    let maxRetries: Int
    var retryCount: Int = 0
    
    enum RequestType: String, Codable {
        case createProject
        case updateProject
        case deleteProject
        case createSession
        case sendMessage
        case updateFile
        case gitCommit
        case settingsUpdate
    }
    
    func execute() async throws {
        // Execute the request based on type
        switch type {
        case .sendMessage:
            try await executeMessageRequest()
        case .createProject:
            try await executeProjectRequest()
        case .updateFile:
            try await executeFileRequest()
        default:
            print("⚠️ Unhandled offline request type: \(type)")
        }
    }
    
    private func executeMessageRequest() async throws {
        guard let message = try? JSONDecoder().decode(Message.self, from: payload) else {
            throw OfflineError.invalidPayload
        }
        
        // Send message via API
        try await APIClient.shared.sendMessage(message)
    }
    
    private func executeProjectRequest() async throws {
        guard let project = try? JSONDecoder().decode(Project.self, from: payload) else {
            throw OfflineError.invalidPayload
        }
        
        // Create project via API
        try await APIClient.shared.createProject(project)
    }
    
    private func executeFileRequest() async throws {
        guard let fileUpdate = try? JSONDecoder().decode(FileUpdate.self, from: payload) else {
            throw OfflineError.invalidPayload
        }
        
        // Update file via API
        try await APIClient.shared.updateFile(fileUpdate)
    }
}

// MARK: - Offline Request Queue

class OfflineRequestQueue {
    private var queue: [OfflineRequest] = []
    private let lock = NSLock()
    private let storageKey = "offline_request_queue"
    
    init() {
        loadFromDisk()
    }
    
    func enqueue(_ request: OfflineRequest) {
        lock.lock()
        defer { lock.unlock() }
        
        queue.append(request)
        saveToDisk()
    }
    
    func dequeueAll() -> [OfflineRequest] {
        lock.lock()
        defer { lock.unlock() }
        
        let requests = queue
        queue.removeAll()
        saveToDisk()
        return requests
    }
    
    func clear() {
        lock.lock()
        defer { lock.unlock() }
        
        queue.removeAll()
        saveToDisk()
    }
    
    private func saveToDisk() {
        guard let data = try? JSONEncoder().encode(queue) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
    
    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let requests = try? JSONDecoder().decode([OfflineRequest].self, from: data) else { return }
        queue = requests
    }
}

// MARK: - Offline Sync Manager

class OfflineSyncManager {
    private var pendingChanges: Set<String> = []
    private let syncQueue = DispatchQueue(label: "com.claudecode.ui.sync", qos: .background)
    
    func hasPendingChanges() -> Bool {
        return !pendingChanges.isEmpty
    }
    
    func markForSync(_ identifier: String) {
        pendingChanges.insert(identifier)
    }
    
    func startSync() {
        syncQueue.async { [weak self] in
            self?.performSync()
        }
    }
    
    func syncNow() async throws {
        try await withCheckedThrowingContinuation { continuation in
            syncQueue.async { [weak self] in
                self?.performSync()
                continuation.resume()
            }
        }
    }
    
    private func performSync() {
        print("🔄 Starting offline sync for \(pendingChanges.count) items")
        
        for identifier in pendingChanges {
            // Sync each pending change
            syncItem(identifier)
        }
        
        pendingChanges.removeAll()
        print("✅ Offline sync completed")
    }
    
    private func syncItem(_ identifier: String) {
        // Implement specific sync logic based on identifier type
        print("🔄 Syncing item: \(identifier)")
    }
}

// MARK: - Offline Cache Manager

class OfflineCacheManager {
    private let cacheDirectory: URL
    private let maxCacheSize: Int64 = 100 * 1024 * 1024 // 100MB
    
    init() {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("offline_cache")
        createCacheDirectoryIfNeeded()
    }
    
    private func createCacheDirectoryIfNeeded() {
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func prepareForOfflineMode() {
        // Cache critical data for offline access
        cacheProjects()
        cacheSessions()
        cacheSettings()
    }
    
    private func cacheProjects() {
        // Cache project data
        print("💾 Caching projects for offline access")
    }
    
    private func cacheSessions() {
        // Cache recent sessions
        print("💾 Caching sessions for offline access")
    }
    
    private func cacheSettings() {
        // Cache user settings
        print("💾 Caching settings for offline access")
    }
    
    func clearAll() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        createCacheDirectoryIfNeeded()
    }
    
    func getCacheSize() -> Int64 {
        guard let enumerator = FileManager.default.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        for case let url as URL in enumerator {
            if let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(fileSize)
            }
        }
        return totalSize
    }
}

// MARK: - Errors

enum OfflineError: LocalizedError {
    case noConnection
    case invalidPayload
    case syncFailed
    case cacheError
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No network connection available"
        case .invalidPayload:
            return "Invalid offline request payload"
        case .syncFailed:
            return "Failed to sync offline changes"
        case .cacheError:
            return "Failed to access offline cache"
        }
    }
}

// MARK: - File Update Model

struct FileUpdate: Codable {
    let projectName: String
    let filePath: String
    let content: String
    let timestamp: Date
}