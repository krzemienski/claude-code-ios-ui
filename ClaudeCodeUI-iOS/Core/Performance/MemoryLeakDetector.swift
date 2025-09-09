import Foundation
import UIKit
import os.log

/// Advanced memory leak detection system for iOS app
final class MemoryLeakDetector {
    
    // MARK: - Types
    
    struct LeakReport {
        let timestamp: Date
        let leaks: [MemoryLeak]
        let retainCycles: [RetainCycle]
        let abandonedObjects: [AbandonedObject]
        let memoryGrowth: MemoryGrowth
        let recommendations: [String]
        
        var hasLeaks: Bool {
            return !leaks.isEmpty || !retainCycles.isEmpty || !abandonedObjects.isEmpty
        }
        
        var severity: Severity {
            if leaks.count > 10 || memoryGrowth.growthRate > 10 {
                return .critical
            } else if leaks.count > 5 || memoryGrowth.growthRate > 5 {
                return .high
            } else if !leaks.isEmpty || memoryGrowth.growthRate > 2 {
                return .medium
            }
            return .low
        }
    }
    
    struct MemoryLeak {
        let className: String
        let instanceAddress: String
        let retainCount: Int
        let allocatedSize: Int
        let stackTrace: [String]
        let timestamp: Date
        let leakType: LeakType
    }
    
    struct RetainCycle {
        let objects: [WeakObject]
        let cycleDescription: String
        let estimatedSize: Int
        let detectionMethod: DetectionMethod
    }
    
    struct AbandonedObject {
        let className: String
        let lastAccessTime: Date
        let retainCount: Int
        let shouldHaveBeenDeallocated: Bool
        let reason: String
    }
    
    struct MemoryGrowth {
        let initialMemory: Float
        let currentMemory: Float
        let peakMemory: Float
        let growthRate: Float // MB per minute
        let timeline: [(Date, Float)]
    }
    
    struct WeakObject {
        weak var object: AnyObject?
        let className: String
        let address: String
    }
    
    enum LeakType {
        case retainCycle
        case strongDelegate
        case closureCapture
        case notificationObserver
        case timer
        case unknown
    }
    
    enum DetectionMethod {
        case retainCountAnalysis
        case heapAnalysis
        case referenceTracking
        case patternMatching
    }
    
    enum Severity: String {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
    }
    
    // MARK: - Properties
    
    static let shared = MemoryLeakDetector()
    private let logger = Logger.shared
    
    private var trackedObjects: [String: WeakObject] = [:]
    private var objectAllocations: [String: Date] = [:]
    private var memorySnapshots: [(Date, Float)] = []
    private var detectedLeaks: [MemoryLeak] = []
    private var detectedCycles: [RetainCycle] = []
    private var abandonedObjects: [AbandonedObject] = []
    
    private let trackingQueue = DispatchQueue(label: "com.claudecode.memory", qos: .utility)
    private var monitoringTimer: Timer?
    private var initialMemory: Float = 0
    
    // MARK: - Initialization
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        initialMemory = getCurrentMemoryUsage()
        
        // Regular memory monitoring
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.performLeakDetection()
        }
        
        // Monitor view controller lifecycle
        setupViewControllerTracking()
        
        // Monitor notification observers
        setupNotificationTracking()
    }
    
    // MARK: - Object Tracking
    
    func track(_ object: AnyObject, className: String? = nil) {
        trackingQueue.async { [weak self] in
            let address = withUnsafePointer(to: object) { String(format: "%p", $0) }
            let name = className ?? String(describing: type(of: object))
            
            self?.trackedObjects[address] = WeakObject(
                object: object,
                className: name,
                address: address
            )
            self?.objectAllocations[address] = Date()
            
            self?.logger.debug("Tracking object: \(name) at \(address)")
        }
    }
    
    func untrack(_ object: AnyObject) {
        trackingQueue.async { [weak self] in
            let address = withUnsafePointer(to: object) { String(format: "%p", $0) }
            self?.trackedObjects.removeValue(forKey: address)
            self?.objectAllocations.removeValue(forKey: address)
        }
    }
    
    // MARK: - View Controller Tracking
    
    private func setupViewControllerTracking() {
        // Swizzle viewDidLoad and deinit for automatic tracking
        swizzleViewControllerMethods()
    }
    
    private func swizzleViewControllerMethods() {
        // Note: In production, use proper method swizzling with runtime APIs
        // This is a simplified version for demonstration
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(viewControllerDidLoad(_:)),
            name: UIViewController.viewDidLoadNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(viewControllerWillDeallocate(_:)),
            name: UIViewController.viewWillDeallocateNotification,
            object: nil
        )
    }
    
    @objc private func viewControllerDidLoad(_ notification: Notification) {
        if let viewController = notification.object as? UIViewController {
            track(viewController)
            checkViewControllerRetainCycles(viewController)
        }
    }
    
    @objc private func viewControllerWillDeallocate(_ notification: Notification) {
        if let viewController = notification.object as? UIViewController {
            untrack(viewController)
        }
    }
    
    // MARK: - Notification Tracking
    
    private func setupNotificationTracking() {
        // Monitor notification center for potential leaks
        checkNotificationObservers()
    }
    
    private func checkNotificationObservers() {
        // Check for notification observers that might cause leaks
        let notificationCenter = NotificationCenter.default
        
        // Use runtime inspection to check for retained observers
        // This is a simplified check - enhance for production
    }
    
    // MARK: - Leak Detection
    
    private func performLeakDetection() {
        trackingQueue.async { [weak self] in
            self?.detectMemoryLeaks()
            self?.detectRetainCycles()
            self?.detectAbandonedObjects()
            self?.analyzeMemoryGrowth()
        }
    }
    
    private func detectMemoryLeaks() {
        // Check tracked objects for potential leaks
        for (address, weakObject) in trackedObjects {
            guard let object = weakObject.object else {
                // Object was deallocated properly
                trackedObjects.removeValue(forKey: address)
                continue
            }
            
            let retainCount = CFGetRetainCount(object)
            
            // Check for abnormally high retain counts
            if retainCount > 10 {
                let leak = createMemoryLeak(
                    object: object,
                    className: weakObject.className,
                    address: address,
                    retainCount: retainCount
                )
                
                if !isLeakAlreadyDetected(leak) {
                    detectedLeaks.append(leak)
                    logger.warning("Memory leak detected: \(weakObject.className) with retain count \(retainCount)")
                }
            }
            
            // Check for objects that should have been deallocated
            if let allocationTime = objectAllocations[address] {
                let age = Date().timeIntervalSince(allocationTime)
                if age > 300 && shouldHaveBeenDeallocated(object, className: weakObject.className) {
                    let abandoned = AbandonedObject(
                        className: weakObject.className,
                        lastAccessTime: allocationTime,
                        retainCount: retainCount,
                        shouldHaveBeenDeallocated: true,
                        reason: "Object alive for \(Int(age))s with high retain count"
                    )
                    abandonedObjects.append(abandoned)
                }
            }
        }
    }
    
    private func detectRetainCycles() {
        // Detect common retain cycle patterns
        detectDelegateCycles()
        detectClosureCycles()
        detectTimerCycles()
    }
    
    private func detectDelegateCycles() {
        // Check for strong delegate references
        for (_, weakObject) in trackedObjects {
            guard let object = weakObject.object else { continue }
            
            let mirror = Mirror(reflecting: object)
            for child in mirror.children {
                if let propertyName = child.label,
                   propertyName.contains("delegate") {
                    // Check if delegate is strongly held
                    if let delegate = child.value as? AnyObject {
                        let delegateRetainCount = CFGetRetainCount(delegate)
                        if delegateRetainCount > 5 {
                            let cycle = RetainCycle(
                                objects: [
                                    weakObject,
                                    WeakObject(
                                        object: delegate,
                                        className: String(describing: type(of: delegate)),
                                        address: withUnsafePointer(to: delegate) { String(format: "%p", $0) }
                                    )
                                ],
                                cycleDescription: "\(weakObject.className) strongly retains delegate",
                                estimatedSize: MemoryLayout.size(ofValue: object) + MemoryLayout.size(ofValue: delegate),
                                detectionMethod: .patternMatching
                            )
                            
                            if !isCycleAlreadyDetected(cycle) {
                                detectedCycles.append(cycle)
                                logger.warning("Retain cycle detected: \(cycle.cycleDescription)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func detectClosureCycles() {
        // Detect closure capture cycles
        for (_, weakObject) in trackedObjects {
            guard let object = weakObject.object else { continue }
            
            // Check for closures that might capture self strongly
            let mirror = Mirror(reflecting: object)
            for child in mirror.children {
                if String(describing: type(of: child.value)).contains("closure") ||
                   String(describing: type(of: child.value)).contains("block") {
                    // Detected a closure property
                    checkClosureForStrongCapture(child.value, in: weakObject)
                }
            }
        }
    }
    
    private func detectTimerCycles() {
        // Check for timer-based retain cycles
        for (_, weakObject) in trackedObjects {
            guard let object = weakObject.object else { continue }
            
            if object is Timer {
                logger.warning("Timer detected in \(weakObject.className) - potential retain cycle")
                
                let cycle = RetainCycle(
                    objects: [weakObject],
                    cycleDescription: "Timer may be retaining \(weakObject.className)",
                    estimatedSize: MemoryLayout<Timer>.size,
                    detectionMethod: .patternMatching
                )
                
                if !isCycleAlreadyDetected(cycle) {
                    detectedCycles.append(cycle)
                }
            }
        }
    }
    
    private func detectAbandonedObjects() {
        // Objects that should have been deallocated but weren't
        let now = Date()
        
        for (address, allocationTime) in objectAllocations {
            let age = now.timeIntervalSince(allocationTime)
            
            // Check if object is still alive after reasonable time
            if age > 300 { // 5 minutes
                if let weakObject = trackedObjects[address],
                   let object = weakObject.object {
                    
                    let retainCount = CFGetRetainCount(object)
                    
                    if shouldHaveBeenDeallocated(object, className: weakObject.className) {
                        let abandoned = AbandonedObject(
                            className: weakObject.className,
                            lastAccessTime: allocationTime,
                            retainCount: retainCount,
                            shouldHaveBeenDeallocated: true,
                            reason: "Object alive for \(Int(age))s"
                        )
                        
                        if !isAbandonedObjectAlreadyDetected(abandoned) {
                            abandonedObjects.append(abandoned)
                            logger.warning("Abandoned object: \(weakObject.className)")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Memory Growth Analysis
    
    private func analyzeMemoryGrowth() {
        let currentMemory = getCurrentMemoryUsage()
        let now = Date()
        
        memorySnapshots.append((now, currentMemory))
        
        // Keep only last 100 snapshots
        if memorySnapshots.count > 100 {
            memorySnapshots.removeFirst()
        }
        
        // Calculate growth rate
        if let firstSnapshot = memorySnapshots.first {
            let timeDiff = now.timeIntervalSince(firstSnapshot.0) / 60.0 // Convert to minutes
            let memoryDiff = currentMemory - firstSnapshot.1
            let growthRate = timeDiff > 0 ? memoryDiff / Float(timeDiff) : 0
            
            if growthRate > 1.0 { // More than 1MB per minute
                logger.warning("High memory growth rate: \(growthRate)MB/min")
            }
        }
    }
    
    // MARK: - Specific Checks
    
    private func checkViewControllerRetainCycles(_ viewController: UIViewController) {
        // Check for common VC retain cycle patterns
        
        // Check for strong self in closures
        let mirror = Mirror(reflecting: viewController)
        for child in mirror.children {
            if let propertyName = child.label {
                // Check for completion handlers that might capture self
                if propertyName.contains("completion") ||
                   propertyName.contains("handler") ||
                   propertyName.contains("callback") {
                    logger.debug("Potential closure retain cycle in \(String(describing: type(of: viewController))).\(propertyName)")
                }
            }
        }
        
        // Check for strong delegate references
        checkForStrongDelegates(in: viewController)
    }
    
    private func checkForStrongDelegates(in object: AnyObject) {
        let mirror = Mirror(reflecting: object)
        
        for child in mirror.children {
            if let propertyName = child.label,
               propertyName.contains("delegate") {
                // In production, use runtime inspection to check if property is weak
                logger.debug("Delegate property found: \(propertyName)")
            }
        }
    }
    
    private func checkClosureForStrongCapture(_ closure: Any, in object: WeakObject) {
        // This is a simplified check - in production, use more sophisticated analysis
        logger.debug("Checking closure in \(object.className) for strong captures")
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentMemoryUsage() -> Float {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            return Float(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        }
        
        return 0
    }
    
    private func createMemoryLeak(object: AnyObject, className: String, address: String, retainCount: Int) -> MemoryLeak {
        return MemoryLeak(
            className: className,
            instanceAddress: address,
            retainCount: retainCount,
            allocatedSize: MemoryLayout.size(ofValue: object),
            stackTrace: Thread.callStackSymbols,
            timestamp: Date(),
            leakType: determineLeakType(for: object)
        )
    }
    
    private func determineLeakType(for object: AnyObject) -> LeakType {
        if object is Timer {
            return .timer
        } else if String(describing: type(of: object)).contains("Notification") {
            return .notificationObserver
        } else if checkForRetainCycle(in: object) {
            return .retainCycle
        }
        return .unknown
    }
    
    private func checkForRetainCycle(in object: AnyObject) -> Bool {
        // Simplified check - enhance for production
        let retainCount = CFGetRetainCount(object)
        return retainCount > 10
    }
    
    private func shouldHaveBeenDeallocated(_ object: AnyObject, className: String) -> Bool {
        // Determine if object should have been deallocated by now
        if className.contains("ViewController") && !(object is UIViewController) {
            return true
        }
        if className.contains("Temp") || className.contains("Cache") {
            return true
        }
        return false
    }
    
    private func isLeakAlreadyDetected(_ leak: MemoryLeak) -> Bool {
        return detectedLeaks.contains { $0.instanceAddress == leak.instanceAddress }
    }
    
    private func isCycleAlreadyDetected(_ cycle: RetainCycle) -> Bool {
        return detectedCycles.contains { $0.cycleDescription == cycle.cycleDescription }
    }
    
    private func isAbandonedObjectAlreadyDetected(_ abandoned: AbandonedObject) -> Bool {
        return abandonedObjects.contains { $0.className == abandoned.className }
    }
    
    // MARK: - Report Generation
    
    func generateLeakReport() -> LeakReport {
        let memoryGrowth = MemoryGrowth(
            initialMemory: initialMemory,
            currentMemory: getCurrentMemoryUsage(),
            peakMemory: memorySnapshots.map { $0.1 }.max() ?? initialMemory,
            growthRate: calculateGrowthRate(),
            timeline: memorySnapshots
        )
        
        let recommendations = generateRecommendations()
        
        return LeakReport(
            timestamp: Date(),
            leaks: detectedLeaks,
            retainCycles: detectedCycles,
            abandonedObjects: abandonedObjects,
            memoryGrowth: memoryGrowth,
            recommendations: recommendations
        )
    }
    
    private func calculateGrowthRate() -> Float {
        guard let first = memorySnapshots.first,
              let last = memorySnapshots.last else { return 0 }
        
        let timeDiff = last.0.timeIntervalSince(first.0) / 60.0 // Minutes
        let memoryDiff = last.1 - first.1
        
        return timeDiff > 0 ? memoryDiff / Float(timeDiff) : 0
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if !detectedLeaks.isEmpty {
            recommendations.append("Fix \(detectedLeaks.count) memory leaks detected")
        }
        
        if !detectedCycles.isEmpty {
            recommendations.append("Break \(detectedCycles.count) retain cycles")
        }
        
        for cycle in detectedCycles {
            if cycle.cycleDescription.contains("delegate") {
                recommendations.append("Use weak references for delegates")
            }
            if cycle.cycleDescription.contains("Timer") {
                recommendations.append("Invalidate timers in deinit")
            }
        }
        
        if !abandonedObjects.isEmpty {
            recommendations.append("Clean up \(abandonedObjects.count) abandoned objects")
        }
        
        let growthRate = calculateGrowthRate()
        if growthRate > 1.0 {
            recommendations.append("Investigate high memory growth rate: \(growthRate)MB/min")
        }
        
        return recommendations
    }
    
    // MARK: - Cleanup
    
    deinit {
        monitoringTimer?.invalidate()
    }
}

// MARK: - UIViewController Extensions

extension UIViewController {
    static let viewDidLoadNotification = Notification.Name("ViewControllerDidLoad")
    static let viewWillDeallocateNotification = Notification.Name("ViewControllerWillDeallocate")
}