import UIKit
import os.log

/// Memory management and optimization manager
class MemoryManager {
    
    // MARK: - Singleton
    
    static let shared = MemoryManager()
    
    // MARK: - Properties
    
    private let logger = OSLog(subsystem: "com.claudecode.ui", category: "Memory")
    private var memoryWarningHandlers: [() -> Void] = []
    private var memoryPressureMonitor: DispatchSourceMemoryPressure?
    
    // Memory thresholds (in MB)
    private let warningThreshold: Int = 150
    private let criticalThreshold: Int = 200
    
    // Current memory usage tracking
    private(set) var currentMemoryUsage: Int = 0
    private var memoryTimer: Timer?
    
    // MARK: - Initialization
    
    private init() {
        setupMemoryMonitoring()
        setupMemoryPressureMonitor()
        registerForMemoryWarnings()
    }
    
    // MARK: - Public Methods
    
    /// Register a handler for memory warnings
    func registerMemoryWarningHandler(_ handler: @escaping () -> Void) {
        memoryWarningHandlers.append(handler)
    }
    
    /// Get current memory usage in MB
    func getCurrentMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let usageInBytes = info.resident_size
            let usageInMB = Int(usageInBytes / 1024 / 1024)
            return usageInMB
        }
        
        return 0
    }
    
    /// Force cleanup of resources
    func performMemoryCleanup() {
        os_log("Performing memory cleanup", log: logger, type: .info)
        
        // Clear image caches
        ImageCacheManager.shared.clearCache()
        
        // Clear URL cache
        URLCache.shared.removeAllCachedResponses()
        
        // Run all registered handlers
        memoryWarningHandlers.forEach { $0() }
        
        // Force garbage collection
        autoreleasepool {
            // This helps release autoreleased objects
        }
        
        os_log("Memory cleanup completed", log: logger, type: .info)
    }
    
    /// Check if memory usage is within acceptable limits
    func isMemoryUsageAcceptable() -> Bool {
        return currentMemoryUsage < warningThreshold
    }
    
    /// Get memory status
    func getMemoryStatus() -> MemoryStatus {
        if currentMemoryUsage < warningThreshold {
            return .normal
        } else if currentMemoryUsage < criticalThreshold {
            return .warning
        } else {
            return .critical
        }
    }
    
    // MARK: - Private Methods
    
    private func setupMemoryMonitoring() {
        // Update memory usage every 5 seconds
        memoryTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateMemoryUsage()
        }
        
        // Initial update
        updateMemoryUsage()
    }
    
    private func updateMemoryUsage() {
        currentMemoryUsage = getCurrentMemoryUsage()
        
        // Log if above threshold
        if currentMemoryUsage > warningThreshold {
            os_log("Memory usage above threshold: %d MB", log: logger, type: .error, currentMemoryUsage)
            
            // Perform automatic cleanup if critical
            if currentMemoryUsage > criticalThreshold {
                performMemoryCleanup()
            }
        }
    }
    
    private func setupMemoryPressureMonitor() {
        memoryPressureMonitor = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical], queue: .global())
        
        memoryPressureMonitor?.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            let event = self.memoryPressureMonitor?.data
            
            if event?.contains(.warning) == true {
                os_log("Memory pressure warning received", log: self.logger, type: .error)
                DispatchQueue.main.async {
                    self.handleMemoryPressure(level: .warning)
                }
            }
            
            if event?.contains(.critical) == true {
                os_log("Critical memory pressure received", log: self.logger, type: .fault)
                DispatchQueue.main.async {
                    self.handleMemoryPressure(level: .critical)
                }
            }
        }
        
        memoryPressureMonitor?.resume()
    }
    
    private func handleMemoryPressure(level: MemoryPressureLevel) {
        switch level {
        case .warning:
            // Reduce memory usage
            ImageCacheManager.shared.clearCache()
            URLCache.shared.removeAllCachedResponses()
            
        case .critical:
            // Aggressive cleanup
            performMemoryCleanup()
            
            // Notify user if needed
            NotificationCenter.default.post(
                name: NSNotification.Name("CriticalMemoryWarning"),
                object: nil
            )
        }
    }
    
    private func registerForMemoryWarnings() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        os_log("System memory warning received", log: logger, type: .error)
        performMemoryCleanup()
    }
    
    deinit {
        memoryTimer?.invalidate()
        memoryPressureMonitor?.cancel()
    }
}

// MARK: - Supporting Types

enum MemoryStatus {
    case normal     // < 150MB
    case warning    // 150-200MB
    case critical   // > 200MB
    
    var color: UIColor {
        switch self {
        case .normal: return CyberpunkTheme.success
        case .warning: return CyberpunkTheme.warning
        case .critical: return CyberpunkTheme.error
        }
    }
    
    var description: String {
        switch self {
        case .normal: return "Normal"
        case .warning: return "High Usage"
        case .critical: return "Critical"
        }
    }
}

enum MemoryPressureLevel {
    case warning
    case critical
}

// MARK: - Memory Optimized Collections

/// A memory-efficient array that automatically releases objects under memory pressure
class MemoryOptimizedArray<T> {
    private var storage: [T] = []
    private var weakStorage: [Any] = [] // Will be [WeakBox<T>] when T: AnyObject
    private let maxCount: Int
    
    init(maxCount: Int = 100) {
        self.maxCount = maxCount
        
        // Register for memory warnings
        MemoryManager.shared.registerMemoryWarningHandler { [weak self] in
            self?.handleMemoryWarning()
        }
    }
    
    func append(_ element: T) {
        if storage.count >= maxCount {
            storage.removeFirst()
        }
        storage.append(element)
    }
    
    func removeAll() {
        storage.removeAll()
    }
    
    var count: Int {
        return storage.count
    }
    
    var isEmpty: Bool {
        return storage.isEmpty
    }
    
    subscript(index: Int) -> T? {
        guard index >= 0 && index < storage.count else { return nil }
        return storage[index]
    }
    
    private func handleMemoryWarning() {
        // Keep only last 25% of items
        let keepCount = maxCount / 4
        if storage.count > keepCount {
            storage = Array(storage.suffix(keepCount))
        }
    }
}

// Helper class for weak references
private class WeakBox<T: AnyObject> {
    weak var value: T?
    
    init(_ value: T) {
        self.value = value
    }
}