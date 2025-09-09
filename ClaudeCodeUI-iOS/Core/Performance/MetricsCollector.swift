import Foundation
import UIKit
import os.log

/// Comprehensive metrics collection system for performance baselines and tracking
final class MetricsCollector {
    
    // MARK: - Types
    
    struct PerformanceBaseline {
        let timestamp: Date
        let deviceModel: String
        let iosVersion: String
        let appVersion: String
        let metrics: BaselineMetrics
        let thresholds: PerformanceThresholds
    }
    
    struct BaselineMetrics {
        let averageFrameRate: Double
        let averageMemoryUsage: Float
        let averageCPUUsage: Double
        let averageNetworkLatency: TimeInterval
        let appLaunchTime: TimeInterval
        let scrollingPerformance: ScrollingMetrics
        let renderingPerformance: RenderingMetrics
    }
    
    struct ScrollingMetrics {
        let averageFPS: Double
        let frameDropRate: Double
        let smoothnessScore: Double
        let responsiveness: TimeInterval
    }
    
    struct RenderingMetrics {
        let drawCallsPerFrame: Int
        let averageRenderTime: TimeInterval
        let offscreenRenderingRatio: Double
        let layerComplexity: Int
    }
    
    struct PerformanceThresholds {
        let minFrameRate: Double = 50.0
        let maxMemoryUsage: Float = 150.0 // MB
        let maxCPUUsage: Double = 60.0 // %
        let maxNetworkLatency: TimeInterval = 1.0 // seconds
        let maxAppLaunchTime: TimeInterval = 2.0 // seconds
        let minScrollingFPS: Double = 55.0
    }
    
    struct MetricsSnapshot {
        let timestamp: Date
        let frameRate: Double
        let memoryUsage: Float
        let cpuUsage: Double
        let networkLatency: TimeInterval
        let activeViewControllers: [String]
        let userInteraction: UserInteractionMetrics
    }
    
    struct UserInteractionMetrics {
        var tapCount: Int
        var scrollDistance: CGFloat
        var navigationCount: Int
        var messagesSent: Int
        var sessionsCreated: Int
    }
    
    struct PerformanceHistory {
        let snapshots: [MetricsSnapshot]
        let baseline: PerformanceBaseline
        let trends: PerformanceTrends
        let anomalies: [PerformanceAnomaly]
    }
    
    struct PerformanceTrends {
        let memoryTrend: Trend
        let cpuTrend: Trend
        let frameRateTrend: Trend
        let networkTrend: Trend
    }
    
    struct PerformanceAnomaly {
        let timestamp: Date
        let type: AnomalyType
        let severity: Severity
        let description: String
        let metrics: MetricsSnapshot
    }
    
    enum Trend {
        case improving(rate: Double)
        case stable
        case degrading(rate: Double)
    }
    
    enum AnomalyType {
        case suddenMemorySpike
        case frameRateDrop
        case cpuSpike
        case networkTimeout
        case memoryLeak
        case crashRisk
    }
    
    enum Severity: String {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
    }
    
    // MARK: - Properties
    
    static let shared = MetricsCollector()
    private let logger = Logger.shared
    
    private var currentBaseline: PerformanceBaseline?
    private var metricsHistory: [MetricsSnapshot] = []
    private var anomalies: [PerformanceAnomaly] = []
    private var userInteractionMetrics = UserInteractionMetrics(
        tapCount: 0,
        scrollDistance: 0,
        navigationCount: 0,
        messagesSent: 0,
        sessionsCreated: 0
    )
    
    private let metricsQueue = DispatchQueue(label: "com.claudecode.metrics", qos: .utility)
    private var collectionTimer: Timer?
    private let storage = MetricsStorage()
    
    // MARK: - Initialization
    
    private init() {
        setupBaseline()
        startCollecting()
    }
    
    private func setupBaseline() {
        // Create initial baseline based on device capabilities
        let baseline = createBaseline()
        currentBaseline = baseline
        
        // Load historical baselines if available
        storage.loadHistoricalBaselines()
    }
    
    private func createBaseline() -> PerformanceBaseline {
        let device = UIDevice.current
        let metrics = BaselineMetrics(
            averageFrameRate: 60.0,
            averageMemoryUsage: 50.0,
            averageCPUUsage: 20.0,
            averageNetworkLatency: 0.1,
            appLaunchTime: 1.0,
            scrollingPerformance: ScrollingMetrics(
                averageFPS: 60.0,
                frameDropRate: 0.01,
                smoothnessScore: 95.0,
                responsiveness: 0.016
            ),
            renderingPerformance: RenderingMetrics(
                drawCallsPerFrame: 10,
                averageRenderTime: 0.008,
                offscreenRenderingRatio: 0.1,
                layerComplexity: 3
            )
        )
        
        return PerformanceBaseline(
            timestamp: Date(),
            deviceModel: device.model,
            iosVersion: device.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            metrics: metrics,
            thresholds: PerformanceThresholds()
        )
    }
    
    // MARK: - Collection
    
    private func startCollecting() {
        collectionTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.collectMetrics()
        }
        
        // Setup interaction tracking
        setupInteractionTracking()
    }
    
    private func collectMetrics() {
        metricsQueue.async { [weak self] in
            guard let self = self else { return }
            
            let snapshot = self.createSnapshot()
            self.metricsHistory.append(snapshot)
            
            // Keep only last 1000 snapshots
            if self.metricsHistory.count > 1000 {
                self.metricsHistory.removeFirst()
            }
            
            // Analyze for anomalies
            self.detectAnomalies(in: snapshot)
            
            // Update trends
            self.updateTrends()
            
            // Store metrics
            self.storage.store(snapshot)
        }
    }
    
    private func createSnapshot() -> MetricsSnapshot {
        let performanceMonitor = PerformanceMonitor.shared
        let metrics = performanceMonitor.generatePerformanceReport().metrics
        
        return MetricsSnapshot(
            timestamp: Date(),
            frameRate: metrics.averageFrameRate,
            memoryUsage: metrics.memoryUsage,
            cpuUsage: metrics.cpuUsage,
            networkLatency: metrics.networkLatency,
            activeViewControllers: getActiveViewControllers(),
            userInteraction: userInteractionMetrics
        )
    }
    
    private func getActiveViewControllers() -> [String] {
        var controllers: [String] = []
        
        DispatchQueue.main.sync {
            if let window = UIApplication.shared.windows.first,
               let rootVC = window.rootViewController {
                controllers = collectViewControllerNames(from: rootVC)
            }
        }
        
        return controllers
    }
    
    private func collectViewControllerNames(from viewController: UIViewController) -> [String] {
        var names = [String(describing: type(of: viewController))]
        
        if let navController = viewController as? UINavigationController {
            for vc in navController.viewControllers {
                names.append(contentsOf: collectViewControllerNames(from: vc))
            }
        } else if let tabController = viewController as? UITabBarController {
            for vc in tabController.viewControllers ?? [] {
                names.append(contentsOf: collectViewControllerNames(from: vc))
            }
        }
        
        for child in viewController.children {
            names.append(contentsOf: collectViewControllerNames(from: child))
        }
        
        if let presented = viewController.presentedViewController {
            names.append(contentsOf: collectViewControllerNames(from: presented))
        }
        
        return names
    }
    
    // MARK: - Interaction Tracking
    
    private func setupInteractionTracking() {
        // Track taps
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.cancelsTouchesInView = false
        UIApplication.shared.windows.first?.addGestureRecognizer(tapGesture)
        
        // Track navigation
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNavigation),
            name: NSNotification.Name("UIViewControllerDidAppear"),
            object: nil
        )
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        metricsQueue.async { [weak self] in
            self?.userInteractionMetrics.tapCount += 1
        }
    }
    
    @objc private func handleNavigation(_ notification: Notification) {
        metricsQueue.async { [weak self] in
            self?.userInteractionMetrics.navigationCount += 1
        }
    }
    
    func trackScrollDistance(_ distance: CGFloat) {
        metricsQueue.async { [weak self] in
            self?.userInteractionMetrics.scrollDistance += abs(distance)
        }
    }
    
    func trackMessageSent() {
        metricsQueue.async { [weak self] in
            self?.userInteractionMetrics.messagesSent += 1
        }
    }
    
    func trackSessionCreated() {
        metricsQueue.async { [weak self] in
            self?.userInteractionMetrics.sessionsCreated += 1
        }
    }
    
    // MARK: - Anomaly Detection
    
    private func detectAnomalies(in snapshot: MetricsSnapshot) {
        guard let baseline = currentBaseline else { return }
        
        // Check for memory spikes
        if snapshot.memoryUsage > baseline.thresholds.maxMemoryUsage * 1.5 {
            recordAnomaly(
                type: .suddenMemorySpike,
                severity: .high,
                description: "Memory usage spike: \(snapshot.memoryUsage)MB",
                snapshot: snapshot
            )
        }
        
        // Check for frame rate drops
        if snapshot.frameRate < baseline.thresholds.minFrameRate * 0.5 {
            recordAnomaly(
                type: .frameRateDrop,
                severity: .critical,
                description: "Severe frame rate drop: \(snapshot.frameRate)fps",
                snapshot: snapshot
            )
        }
        
        // Check for CPU spikes
        if snapshot.cpuUsage > baseline.thresholds.maxCPUUsage * 1.5 {
            recordAnomaly(
                type: .cpuSpike,
                severity: .medium,
                description: "CPU usage spike: \(snapshot.cpuUsage)%",
                snapshot: snapshot
            )
        }
        
        // Check for network issues
        if snapshot.networkLatency > baseline.thresholds.maxNetworkLatency * 3 {
            recordAnomaly(
                type: .networkTimeout,
                severity: .medium,
                description: "High network latency: \(snapshot.networkLatency * 1000)ms",
                snapshot: snapshot
            )
        }
        
        // Check for potential memory leaks
        if isMemoryLeakSuspected() {
            recordAnomaly(
                type: .memoryLeak,
                severity: .critical,
                description: "Potential memory leak detected",
                snapshot: snapshot
            )
        }
    }
    
    private func isMemoryLeakSuspected() -> Bool {
        guard metricsHistory.count > 10 else { return false }
        
        // Check if memory has been consistently increasing
        let recentMemory = metricsHistory.suffix(10).map { $0.memoryUsage }
        let isIncreasing = recentMemory.enumerated().allSatisfy { index, memory in
            index == 0 || memory >= recentMemory[index - 1]
        }
        
        if isIncreasing {
            let growth = recentMemory.last! - recentMemory.first!
            return growth > 20.0 // 20MB growth
        }
        
        return false
    }
    
    private func recordAnomaly(type: AnomalyType, severity: Severity, description: String, snapshot: MetricsSnapshot) {
        let anomaly = PerformanceAnomaly(
            timestamp: Date(),
            type: type,
            severity: severity,
            description: description,
            metrics: snapshot
        )
        
        anomalies.append(anomaly)
        
        if severity == .critical {
            logger.critical("CRITICAL ANOMALY: \(description)")
        } else {
            logger.warning("Performance anomaly: \(description)")
        }
    }
    
    // MARK: - Trend Analysis
    
    private func updateTrends() {
        guard metricsHistory.count > 20 else { return }
        
        let recent = metricsHistory.suffix(20)
        
        // Analyze memory trend
        let memoryValues = recent.map { $0.memoryUsage }
        _ = analyzeTrend(values: memoryValues.map { Double($0) })
        
        // Analyze CPU trend
        let cpuValues = recent.map { $0.cpuUsage }
        _ = analyzeTrend(values: cpuValues)
        
        // Analyze frame rate trend
        let frameRateValues = recent.map { $0.frameRate }
        _ = analyzeTrend(values: frameRateValues)
        
        // Analyze network trend
        let networkValues = recent.map { $0.networkLatency }
        _ = analyzeTrend(values: networkValues)
    }
    
    private func analyzeTrend(values: [Double]) -> Trend {
        guard values.count > 1 else { return .stable }
        
        // Simple linear regression
        let n = Double(values.count)
        let sumX = (0..<values.count).reduce(0.0) { $0 + Double($1) }
        let sumY = values.reduce(0.0, +)
        let sumXY = values.enumerated().reduce(0.0) { $0 + Double($1.0) * $1.1 }
        let sumX2 = (0..<values.count).reduce(0.0) { $0 + pow(Double($1), 2) }
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - pow(sumX, 2))
        
        if abs(slope) < 0.01 {
            return .stable
        } else if slope > 0 {
            return .degrading(rate: slope)
        } else {
            return .improving(rate: abs(slope))
        }
    }
    
    // MARK: - Reporting
    
    func generateMetricsReport() -> MetricsReport {
        let history = PerformanceHistory(
            snapshots: metricsHistory,
            baseline: currentBaseline!,
            trends: getCurrentTrends(),
            anomalies: anomalies
        )
        
        return MetricsReport(
            timestamp: Date(),
            history: history,
            summary: generateSummary(),
            recommendations: generateRecommendations()
        )
    }
    
    private func getCurrentTrends() -> PerformanceTrends {
        guard metricsHistory.count > 20 else {
            return PerformanceTrends(
                memoryTrend: .stable,
                cpuTrend: .stable,
                frameRateTrend: .stable,
                networkTrend: .stable
            )
        }
        
        let recent = metricsHistory.suffix(20)
        
        return PerformanceTrends(
            memoryTrend: analyzeTrend(values: recent.map { Double($0.memoryUsage) }),
            cpuTrend: analyzeTrend(values: recent.map { $0.cpuUsage }),
            frameRateTrend: analyzeTrend(values: recent.map { $0.frameRate }),
            networkTrend: analyzeTrend(values: recent.map { $0.networkLatency })
        )
    }
    
    private func generateSummary() -> String {
        guard let baseline = currentBaseline,
              !metricsHistory.isEmpty else {
            return "No metrics collected yet"
        }
        
        let avgMemory = metricsHistory.map { $0.memoryUsage }.reduce(0, +) / Float(metricsHistory.count)
        let avgCPU = metricsHistory.map { $0.cpuUsage }.reduce(0, +) / Double(metricsHistory.count)
        let avgFrameRate = metricsHistory.map { $0.frameRate }.reduce(0, +) / Double(metricsHistory.count)
        
        var summary = "Performance Metrics Summary:\n"
        summary += "• Device: \(baseline.deviceModel) (iOS \(baseline.iosVersion))\n"
        summary += "• App Version: \(baseline.appVersion)\n"
        summary += "• Average Memory: \(String(format: "%.1f", avgMemory))MB\n"
        summary += "• Average CPU: \(String(format: "%.1f", avgCPU))%\n"
        summary += "• Average Frame Rate: \(String(format: "%.1f", avgFrameRate))fps\n"
        summary += "• Anomalies Detected: \(anomalies.count)\n"
        summary += "• User Interactions: \(userInteractionMetrics.tapCount) taps, \(userInteractionMetrics.navigationCount) navigations"
        
        return summary
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        // Based on trends
        let trends = getCurrentTrends()
        
        if case .degrading(let rate) = trends.memoryTrend, rate > 0.5 {
            recommendations.append("Memory usage is increasing rapidly - investigate for leaks")
        }
        
        if case .degrading(let rate) = trends.frameRateTrend, rate > 1.0 {
            recommendations.append("Frame rate is degrading - optimize UI rendering")
        }
        
        // Based on anomalies
        let criticalAnomalies = anomalies.filter { $0.severity == .critical }
        if !criticalAnomalies.isEmpty {
            recommendations.append("Address \(criticalAnomalies.count) critical performance issues immediately")
        }
        
        // Based on baseline comparison
        if let baseline = currentBaseline {
            let recent = metricsHistory.suffix(10)
            if !recent.isEmpty {
                let avgMemory = recent.map { $0.memoryUsage }.reduce(0, +) / Float(recent.count)
                if avgMemory > baseline.thresholds.maxMemoryUsage {
                    recommendations.append("Memory usage exceeds baseline - implement memory optimization")
                }
            }
        }
        
        return recommendations
    }
}

// MARK: - Supporting Types

struct MetricsReport {
    let timestamp: Date
    let history: MetricsCollector.PerformanceHistory
    let summary: String
    let recommendations: [String]
}

// MARK: - Metrics Storage

class MetricsStorage {
    private let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                        in: .userDomainMask).first!
    
    func store(_ snapshot: MetricsCollector.MetricsSnapshot) {
        // Store metrics to file for persistence
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(snapshot)
            let fileName = "metrics_\(snapshot.timestamp.timeIntervalSince1970).json"
            let filePath = documentsPath.appendingPathComponent(fileName)
            try data.write(to: filePath)
        } catch {
            print("Failed to store metrics: \(error)")
        }
    }
    
    func loadHistoricalBaselines() {
        // Load previous baselines from storage
    }
}

// Make types Codable for storage
extension MetricsCollector.MetricsSnapshot: Codable {}
extension MetricsCollector.UserInteractionMetrics: Codable {}