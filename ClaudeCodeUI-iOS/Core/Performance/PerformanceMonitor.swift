import Foundation
import UIKit
import QuartzCore
import os.log

/// Real-time performance monitoring system for iOS app
final class PerformanceMonitor {
    
    // MARK: - Singleton
    
    static let shared = PerformanceMonitor()
    
    // MARK: - Properties
    
    private let logger = Logger.shared
    private var displayLink: CADisplayLink?
    private var frameDropCounter = 0
    private var totalFrames = 0
    private var lastFrameTime: CFTimeInterval = 0
    
    // Performance metrics storage
    private var metrics = PerformanceMetrics()
    private let metricsQueue = DispatchQueue(label: "com.claudecode.performance", qos: .utility)
    
    // Memory monitoring
    private var memoryTimer: Timer?
    private var initialMemoryUsage: Float = 0
    private var peakMemoryUsage: Float = 0
    
    // Network monitoring
    private var requestStartTimes: [String: Date] = [:]
    private var networkLatencies: [TimeInterval] = []
    
    // UI performance
    private var scrollingStartTime: Date?
    private var animationStartTime: Date?
    
    // Monitoring state
    private var isMonitoring = false
    
    // MARK: - Performance Metrics Model
    
    struct PerformanceMetrics: Codable {
        var appLaunchTime: TimeInterval = 0
        var averageFrameRate: Double = 60.0
        var frameDrops: Int = 0
        var memoryUsage: Float = 0
        var peakMemory: Float = 0
        var cpuUsage: Double = 0
        var networkLatency: TimeInterval = 0
        var averageResponseTime: TimeInterval = 0
        var scrollingFPS: Double = 60.0
        var memoryLeaks: [MemoryLeak] = []
        var performanceIssues: [PerformanceIssue] = []
        
        struct MemoryLeak: Codable {
            let className: String
            let retainCount: Int
            let size: Int
            let timestamp: Date
        }
        
        struct PerformanceIssue: Codable {
            enum IssueType: String, Codable {
                case slowScrolling
                case highMemoryUsage
                case networkLatency
                case frameDrop
                case memoryLeak
                case cpuSpike
            }
            
            let type: IssueType
            let description: String
            let severity: Severity
            let timestamp: Date
            let context: [String: String]
        }
        
        enum Severity: String, Codable {
            case low = "Low"
            case medium = "Medium"
            case high = "High"
            case critical = "Critical"
        }
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        isMonitoring = true
        // Start monitoring implementation
        logger.info("Performance monitoring started")
    }
    
    func stopMonitoring() {
        isMonitoring = false
        // Stop monitoring implementation
        logger.info("Performance monitoring stopped")
    }
    
    private func startFrameRateMonitoring() {
        // Frame rate monitoring implementation
    }
    
    private func stopFrameRateMonitoring() {
        // Stop frame rate monitoring
    }
    
    private func startMemoryMonitoring() {
        // Memory monitoring implementation
    }
    
    private func stopMemoryMonitoring() {
        // Stop memory monitoring
    }
    
    func trackCustomMetric(name: String, value: Double) {
        metricsQueue.async { [weak self] in
            self?.logger.info("Custom metric '\(name)': \(value)")
            // Store custom metrics if needed
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        setupMonitoring()
    }
    
    private func setupMonitoring() {
        // Setup frame rate monitoring
        setupFrameRateMonitoring()
        
        // Setup memory monitoring
        setupMemoryMonitoring()
        
        // Setup CPU monitoring
        setupCPUMonitoring()
        
        // Monitor app lifecycle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    // MARK: - Frame Rate Monitoring
    
    private func setupFrameRateMonitoring() {
        displayLink = CADisplayLink(target: self, selector: #selector(frameUpdate))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func frameUpdate(displayLink: CADisplayLink) {
        let currentTime = displayLink.timestamp
        
        if lastFrameTime > 0 {
            let frameDuration = currentTime - lastFrameTime
            let expectedDuration = displayLink.targetTimestamp - displayLink.timestamp
            
            totalFrames += 1
            
            // Detect frame drops (frame taking more than 16.67ms for 60fps)
            if frameDuration > 0.0167 * 1.5 { // 1.5x tolerance
                frameDropCounter += 1
                
                metricsQueue.async { [weak self] in
                    self?.recordPerformanceIssue(
                        type: .frameDrop,
                        description: "Frame drop detected: \(frameDuration * 1000)ms",
                        severity: frameDuration > 0.033 ? .high : .medium,
                        context: ["duration": "\(frameDuration)", "frame": "\(self?.totalFrames ?? 0)"]
                    )
                }
            }
            
            // Update average frame rate
            if totalFrames % 60 == 0 { // Update every second
                let fps = 1.0 / frameDuration
                metrics.averageFrameRate = min(fps, 120.0) // Cap at 120fps
                
                if fps < 30 {
                    logger.warning("Low frame rate detected: \(String(format: "%.1f", fps)) FPS")
                }
            }
        }
        
        lastFrameTime = currentTime
    }
    
    // MARK: - Memory Monitoring
    
    private func setupMemoryMonitoring() {
        initialMemoryUsage = getCurrentMemoryUsage()
        peakMemoryUsage = initialMemoryUsage
        
        memoryTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkMemoryUsage()
        }
    }
    
    private func checkMemoryUsage() {
        let currentMemory = getCurrentMemoryUsage()
        metrics.memoryUsage = currentMemory
        
        // Track peak memory
        if currentMemory > peakMemoryUsage {
            peakMemoryUsage = currentMemory
            metrics.peakMemory = peakMemoryUsage
        }
        
        // Check for memory issues
        let memoryGrowth = currentMemory - initialMemoryUsage
        if memoryGrowth > 50.0 { // 50MB growth
            recordPerformanceIssue(
                type: .highMemoryUsage,
                description: "High memory usage: \(currentMemory)MB (growth: \(memoryGrowth)MB)",
                severity: memoryGrowth > 100 ? .critical : .high,
                context: ["current": String(currentMemory), "initial": String(initialMemoryUsage), "growth": String(memoryGrowth)]
            )
        }
        
        // Check for potential memory leaks
        if memoryGrowth > 10.0 && totalFrames > 600 { // After 10 seconds
            detectMemoryLeaks()
        }
    }
    
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
    
    // MARK: - CPU Monitoring
    
    private func setupCPUMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkCPUUsage()
        }
    }
    
    private func checkCPUUsage() {
        let cpuUsage = getCurrentCPUUsage()
        metrics.cpuUsage = cpuUsage
        
        if cpuUsage > 80.0 {
            recordPerformanceIssue(
                type: .cpuSpike,
                description: "High CPU usage: \(cpuUsage)%",
                severity: cpuUsage > 90 ? .critical : .high,
                context: ["usage": String(cpuUsage)]
            )
        }
    }
    
    private func getCurrentCPUUsage() -> Double {
        var cpuInfo: processor_info_array_t!
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCpus: natural_t = 0
        
        let result = host_processor_info(mach_host_self(),
                                        PROCESSOR_CPU_LOAD_INFO,
                                        &numCpus,
                                        &cpuInfo,
                                        &numCpuInfo)
        
        guard result == KERN_SUCCESS else { return 0.0 }
        
        var totalUsage: Double = 0.0
        for i in 0..<Int(numCpus) {
            let offset = Int(CPU_STATE_MAX) * i
            let user = Double(cpuInfo[offset + Int(CPU_STATE_USER)])
            let system = Double(cpuInfo[offset + Int(CPU_STATE_SYSTEM)])
            let idle = Double(cpuInfo[offset + Int(CPU_STATE_IDLE)])
            let nice = Double(cpuInfo[offset + Int(CPU_STATE_NICE)])
            
            let total = user + system + idle + nice
            if total > 0 {
                totalUsage += (user + system) / total * 100.0
            }
        }
        
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(numCpuInfo))
        
        return totalUsage / Double(numCpus)
    }
    
    // MARK: - Memory Leak Detection
    
    private func detectMemoryLeaks() {
        // This is a simplified leak detection - in production, use Instruments
        metricsQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Check for common leak patterns
            self.checkForRetainCycles()
            self.checkForAbandonedObjects()
        }
    }
    
    private func checkForRetainCycles() {
        // Monitor view controller retain counts
        DispatchQueue.main.async { [weak self] in
            if let window = UIApplication.shared.windows.first,
               let rootVC = window.rootViewController {
                self?.checkViewControllerHierarchy(rootVC)
            }
        }
    }
    
    private func checkViewControllerHierarchy(_ viewController: UIViewController) {
        let mirror = Mirror(reflecting: viewController)
        let className = String(describing: type(of: viewController))
        
        // Check for unusually high retain counts (simplified check)
        let retainCount = CFGetRetainCount(viewController)
        if retainCount > 10 {
            let leak = PerformanceMetrics.MemoryLeak(
                className: className,
                retainCount: retainCount,
                size: MemoryLayout.size(ofValue: viewController),
                timestamp: Date()
            )
            metrics.memoryLeaks.append(leak)
            
            logger.warning("Potential memory leak detected in \(className): retain count = \(retainCount)")
        }
    }
    
    private func checkForAbandonedObjects() {
        // Check for objects that should have been deallocated
        // This is a placeholder - implement based on your app's specific needs
    }
    
    // MARK: - Network Performance
    
    func trackNetworkRequestStart(identifier: String) {
        metricsQueue.async { [weak self] in
            self?.requestStartTimes[identifier] = Date()
        }
    }
    
    func trackNetworkRequestEnd(identifier: String) {
        metricsQueue.async { [weak self] in
            guard let self = self,
                  let startTime = self.requestStartTimes[identifier] else { return }
            
            let latency = Date().timeIntervalSince(startTime)
            self.networkLatencies.append(latency)
            self.requestStartTimes.removeValue(forKey: identifier)
            
            // Update average latency
            if !self.networkLatencies.isEmpty {
                self.metrics.networkLatency = self.networkLatencies.reduce(0, +) / Double(self.networkLatencies.count)
            }
            
            // Check for slow requests
            if latency > 2.0 {
                self.recordPerformanceIssue(
                    type: .networkLatency,
                    description: "Slow network request: \(latency * 1000)ms",
                    severity: latency > 5.0 ? .high : .medium,
                    context: ["identifier": identifier, "latency": String(latency)]
                )
            }
        }
    }
    
    // MARK: - UI Performance
    
    func trackScrollingStart() {
        scrollingStartTime = Date()
        metrics.scrollingFPS = metrics.averageFrameRate
    }
    
    func trackScrollingEnd() {
        guard let startTime = scrollingStartTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        let fps = metrics.averageFrameRate
        
        if fps < 50 {
            recordPerformanceIssue(
                type: .slowScrolling,
                description: "Slow scrolling detected: \(fps)fps over \(duration)s",
                severity: fps < 30 ? .high : .medium,
                context: ["fps": String(fps), "duration": String(duration)]
            )
        }
        
        scrollingStartTime = nil
    }
    
    func trackAnimationStart() {
        animationStartTime = Date()
    }
    
    func trackAnimationEnd() {
        guard let startTime = animationStartTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        if duration > 0.5 {
            logger.warning("Slow animation: \(duration * 1000)ms")
        }
        
        animationStartTime = nil
    }
    
    // MARK: - App Launch Performance
    
    func recordAppLaunchTime(_ time: TimeInterval) {
        metrics.appLaunchTime = time
        
        if time > 2.0 {
            recordPerformanceIssue(
                type: .cpuSpike,
                description: "Slow app launch: \(time)s",
                severity: time > 3.0 ? .high : .medium,
                context: ["launchTime": String(time)]
            )
        }
    }
    
    // MARK: - Performance Issue Recording
    
    private func recordPerformanceIssue(type: PerformanceMetrics.PerformanceIssue.IssueType,
                                       description: String,
                                       severity: PerformanceMetrics.Severity,
                                       context: [String: String]) {
        let issue = PerformanceMetrics.PerformanceIssue(
            type: type,
            description: description,
            severity: severity,
            timestamp: Date(),
            context: context
        )
        
        metrics.performanceIssues.append(issue)
        
        // Log critical issues immediately
        if severity == .critical {
            logger.critical("CRITICAL PERFORMANCE ISSUE: \(description)")
        }
    }
    
    // MARK: - Lifecycle
    
    @objc private func applicationDidBecomeActive() {
        // Reset monitoring when app becomes active
        frameDropCounter = 0
        totalFrames = 0
    }
    
    @objc private func applicationDidReceiveMemoryWarning() {
        logger.warning("Memory warning received! Current usage: \(metrics.memoryUsage)MB")
        recordPerformanceIssue(
            type: .highMemoryUsage,
            description: "Memory warning received",
            severity: .critical,
            context: ["memoryUsage": String(metrics.memoryUsage)]
        )
    }
    
    // MARK: - Reporting
    
    func generatePerformanceReport() -> PerformanceReport {
        return PerformanceReport(
            timestamp: Date(),
            metrics: metrics,
            summary: generateSummary(),
            recommendations: generateRecommendations()
        )
    }
    
    private func generateSummary() -> String {
        var summary = "Performance Summary:\n"
        summary += "• Average FPS: \(String(format: "%.1f", metrics.averageFrameRate))\n"
        summary += "• Frame Drops: \(metrics.frameDrops)\n"
        summary += "• Memory Usage: \(String(format: "%.1f", metrics.memoryUsage))MB\n"
        summary += "• Peak Memory: \(String(format: "%.1f", metrics.peakMemory))MB\n"
        summary += "• CPU Usage: \(String(format: "%.1f", metrics.cpuUsage))%\n"
        summary += "• Network Latency: \(String(format: "%.0f", metrics.networkLatency * 1000))ms\n"
        summary += "• Performance Issues: \(metrics.performanceIssues.count)\n"
        summary += "• Memory Leaks: \(metrics.memoryLeaks.count)"
        return summary
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if metrics.averageFrameRate < 50 {
            recommendations.append("Optimize UI rendering - frame rate is below 50fps")
        }
        
        if metrics.memoryUsage > 100 {
            recommendations.append("Reduce memory usage - currently using over 100MB")
        }
        
        if metrics.cpuUsage > 50 {
            recommendations.append("Optimize CPU-intensive operations")
        }
        
        if metrics.networkLatency > 1.0 {
            recommendations.append("Improve network performance - high latency detected")
        }
        
        if !metrics.memoryLeaks.isEmpty {
            recommendations.append("Fix memory leaks - \(metrics.memoryLeaks.count) potential leaks detected")
        }
        
        return recommendations
    }
    
    // MARK: - Cleanup
    
    deinit {
        displayLink?.invalidate()
        memoryTimer?.invalidate()
    }
}

// MARK: - Performance Report Model

struct PerformanceReport: Codable {
    let timestamp: Date
    let metrics: PerformanceMonitor.PerformanceMetrics
    let summary: String
    let recommendations: [String]
    
    func saveToFile() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(self)
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                     in: .userDomainMask).first!
        let fileName = "performance_report_\(timestamp.timeIntervalSince1970).json"
        let filePath = documentsPath.appendingPathComponent(fileName)
        
        try data.write(to: filePath)
    }
}

// Make PerformanceReport Codable
// Note: Commenting out Codable conformance for types with [String: Any] fields
// extension PerformanceReport: Codable {}
// extension PerformanceMonitor.PerformanceMetrics: Codable {}
// extension PerformanceMonitor.PerformanceMetrics.MemoryLeak: Codable {}
// extension PerformanceMonitor.PerformanceMetrics.PerformanceIssue: Codable {}
// extension PerformanceMonitor.PerformanceMetrics.PerformanceIssue.IssueType: Codable {}
// extension PerformanceMonitor.PerformanceMetrics.Severity: Codable {}