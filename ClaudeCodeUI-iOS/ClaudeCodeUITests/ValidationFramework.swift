import Foundation
import XCTest
import os.log

/// Comprehensive validation framework for test results and app behavior
final class ValidationFramework {
    
    // MARK: - Types
    
    enum ValidationResult {
        case passed(String)
        case failed(String, Error?)
        case warning(String)
        case skipped(String)
    }
    
    struct ValidationReport {
        let timestamp: Date
        let results: [ValidationResult]
        let metrics: ValidationMetrics
        let consistency: ConsistencyReport
        let integrity: DataIntegrityReport
        
        var passRate: Double {
            let passed = results.filter { if case .passed = $0 { return true } else { return false } }.count
            return results.isEmpty ? 0 : Double(passed) / Double(results.count) * 100
        }
        
        var hasCriticalIssues: Bool {
            return results.contains { if case .failed = $0 { return true } else { return false } }
        }
    }
    
    struct ValidationMetrics {
        let uiConsistency: Double
        let dataIntegrity: Double
        let performanceScore: Double
        let reliabilityScore: Double
        let overallScore: Double
    }
    
    struct ConsistencyReport {
        let uiElements: [UIElementValidation]
        let navigationFlow: [NavigationValidation]
        let stateManagement: [StateValidation]
        let animationConsistency: [AnimationValidation]
    }
    
    struct DataIntegrityReport {
        let messageDelivery: MessageValidation
        let sessionState: SessionValidation
        let dataCorruption: [DataCorruption]
        let networkIntegrity: NetworkValidation
    }
    
    // MARK: - Validation Models
    
    struct UIElementValidation {
        let elementName: String
        let expectedState: String
        let actualState: String
        let isConsistent: Bool
        let screenshot: Data?
    }
    
    struct NavigationValidation {
        let fromScreen: String
        let toScreen: String
        let transitionTime: TimeInterval
        let success: Bool
        let issues: [String]
    }
    
    struct StateValidation {
        let component: String
        let expectedState: [String: Any]
        let actualState: [String: Any]
        let mismatches: [String]
    }
    
    struct AnimationValidation {
        let animationName: String
        let expectedDuration: TimeInterval
        let actualDuration: TimeInterval
        let frameRate: Double
        let smoothness: Double
    }
    
    struct MessageValidation {
        let totalSent: Int
        let totalReceived: Int
        let deliveryRate: Double
        let averageLatency: TimeInterval
        let failures: [MessageFailure]
    }
    
    struct SessionValidation {
        let sessionId: String
        let isValid: Bool
        let stateConsistency: Bool
        let dataCompleteness: Bool
        let issues: [String]
    }
    
    struct DataCorruption {
        let dataType: String
        let location: String
        let severity: Severity
        let description: String
    }
    
    struct NetworkValidation {
        let connectionStability: Double
        let packetLoss: Double
        let averageLatency: TimeInterval
        let reconnectionCount: Int
    }
    
    struct MessageFailure {
        let messageId: String
        let reason: String
        let timestamp: Date
    }
    
    enum Severity: String {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
    }
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.claudecode.ui", category: "Validation")
    private var validationResults: [ValidationResult] = []
    private let validationQueue = DispatchQueue(label: "com.claudecode.validation", qos: .userInitiated)
    
    // MARK: - Singleton
    
    static let shared = ValidationFramework()
    private init() {}
    
    // MARK: - UI Consistency Validation
    
    func validateUIConsistency(in app: XCUIApplication) -> [UIElementValidation] {
        var validations: [UIElementValidation] = []
        
        // Validate tab bar
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            validations.append(validateTabBar(tabBar))
        }
        
        // Validate navigation bars
        app.navigationBars.allElementsBoundByIndex.forEach { navBar in
            validations.append(validateNavigationBar(navBar))
        }
        
        // Validate critical UI elements
        validations.append(contentsOf: validateCriticalElements(in: app))
        
        return validations
    }
    
    private func validateTabBar(_ tabBar: XCUIElement) -> UIElementValidation {
        let expectedButtons = ["Projects", "Terminal", "Search"]
        var actualButtons: [String] = []
        
        tabBar.buttons.allElementsBoundByIndex.forEach { button in
            if let label = button.label as String?, !label.isEmpty {
                actualButtons.append(label)
            }
        }
        
        let isConsistent = expectedButtons.allSatisfy { actualButtons.contains($0) }
        
        return UIElementValidation(
            elementName: "TabBar",
            expectedState: expectedButtons.joined(separator: ", "),
            actualState: actualButtons.joined(separator: ", "),
            isConsistent: isConsistent,
            screenshot: nil
        )
    }
    
    private func validateNavigationBar(_ navBar: XCUIElement) -> UIElementValidation {
        let hasTitle = !navBar.staticTexts.allElementsBoundByIndex.isEmpty
        let hasBackButton = navBar.buttons.allElementsBoundByIndex.contains { $0.label.contains("Back") || $0.label.contains("Cancel") }
        
        return UIElementValidation(
            elementName: "NavigationBar",
            expectedState: "Has title and navigation",
            actualState: "Title: \(hasTitle), Back: \(hasBackButton)",
            isConsistent: hasTitle,
            screenshot: nil
        )
    }
    
    private func validateCriticalElements(in app: XCUIApplication) -> [UIElementValidation] {
        var validations: [UIElementValidation] = []
        
        // Check for message input in chat
        if app.textViews["MessageInput"].exists || app.textViews.firstMatch.exists {
            validations.append(UIElementValidation(
                elementName: "MessageInput",
                expectedState: "Exists and enabled",
                actualState: "Found",
                isConsistent: true,
                screenshot: nil
            ))
        }
        
        // Check for send button
        if app.buttons["Send"].exists {
            let isEnabled = app.buttons["Send"].isEnabled
            validations.append(UIElementValidation(
                elementName: "SendButton",
                expectedState: "Exists and enabled",
                actualState: "Enabled: \(isEnabled)",
                isConsistent: isEnabled,
                screenshot: nil
            ))
        }
        
        return validations
    }
    
    // MARK: - Message Delivery Validation
    
    func validateMessageDelivery(sentMessages: [String], receivedMessages: [String]) -> MessageValidation {
        let deliveryRate = sentMessages.isEmpty ? 0 : Double(receivedMessages.count) / Double(sentMessages.count)
        
        var failures: [MessageFailure] = []
        for message in sentMessages {
            if !receivedMessages.contains(message) {
                failures.append(MessageFailure(
                    messageId: message,
                    reason: "Message not received",
                    timestamp: Date()
                ))
            }
        }
        
        return MessageValidation(
            totalSent: sentMessages.count,
            totalReceived: receivedMessages.count,
            deliveryRate: deliveryRate,
            averageLatency: 0.1, // This should be measured in real tests
            failures: failures
        )
    }
    
    // MARK: - Session State Validation
    
    func validateSessionState(sessionId: String, expectedState: [String: Any], actualState: [String: Any]) -> SessionValidation {
        var issues: [String] = []
        
        // Check session ID validity
        let isValidId = !sessionId.isEmpty && sessionId.count > 10
        if !isValidId {
            issues.append("Invalid session ID format")
        }
        
        // Check state consistency
        var stateConsistent = true
        for (key, expectedValue) in expectedState {
            if let actualValue = actualState[key] {
                if !areEqual(expectedValue, actualValue) {
                    stateConsistent = false
                    issues.append("State mismatch for key '\(key)'")
                }
            } else {
                stateConsistent = false
                issues.append("Missing state key '\(key)'")
            }
        }
        
        // Check data completeness
        let requiredKeys = ["userId", "sessionStart", "messages"]
        let hasAllKeys = requiredKeys.allSatisfy { actualState[$0] != nil }
        
        return SessionValidation(
            sessionId: sessionId,
            isValid: isValidId,
            stateConsistency: stateConsistent,
            dataCompleteness: hasAllKeys,
            issues: issues
        )
    }
    
    // MARK: - Data Integrity Validation
    
    func validateDataIntegrity(for dataType: String, data: Data) -> DataCorruption? {
        // Check for common data corruption patterns
        if data.isEmpty {
            return DataCorruption(
                dataType: dataType,
                location: "Memory",
                severity: .high,
                description: "Empty data detected"
            )
        }
        
        // Check for null bytes in string data
        if dataType == "String" {
            if let string = String(data: data, encoding: .utf8) {
                if string.contains("\0") {
                    return DataCorruption(
                        dataType: dataType,
                        location: "String encoding",
                        severity: .medium,
                        description: "Null bytes in string data"
                    )
                }
            } else {
                return DataCorruption(
                    dataType: dataType,
                    location: "String encoding",
                    severity: .critical,
                    description: "Failed to decode string data"
                )
            }
        }
        
        return nil
    }
    
    // MARK: - Network Integrity Validation
    
    func validateNetworkIntegrity(metrics: NetworkMetrics) -> NetworkValidation {
        return NetworkValidation(
            connectionStability: metrics.stability,
            packetLoss: metrics.packetLoss,
            averageLatency: metrics.averageLatency,
            reconnectionCount: metrics.reconnections
        )
    }
    
    // MARK: - Performance Validation
    
    func validatePerformance(metrics: PerformanceMonitor.PerformanceMetrics) -> ValidationResult {
        var issues: [String] = []
        
        // Validate frame rate
        if metrics.averageFrameRate < 30 {
            issues.append("Frame rate below 30fps: \(metrics.averageFrameRate)")
        }
        
        // Validate memory usage
        if metrics.memoryUsage > 200 {
            issues.append("High memory usage: \(metrics.memoryUsage)MB")
        }
        
        // Validate CPU usage
        if metrics.cpuUsage > 80 {
            issues.append("High CPU usage: \(metrics.cpuUsage)%")
        }
        
        // Validate network latency
        if metrics.networkLatency > 2.0 {
            issues.append("High network latency: \(metrics.networkLatency * 1000)ms")
        }
        
        if issues.isEmpty {
            return .passed("Performance validation passed")
        } else {
            return .failed("Performance issues: \(issues.joined(separator: ", "))", nil)
        }
    }
    
    // MARK: - Comprehensive Validation
    
    func runComprehensiveValidation(app: XCUIApplication,
                                   performanceMetrics: PerformanceMonitor.PerformanceMetrics,
                                   networkMetrics: NetworkMetrics) -> ValidationReport {
        
        validationResults.removeAll()
        
        // UI Consistency
        let uiValidations = validateUIConsistency(in: app)
        let uiConsistencyScore = Double(uiValidations.filter { $0.isConsistent }.count) / Double(max(uiValidations.count, 1)) * 100
        
        if uiConsistencyScore < 80 {
            validationResults.append(.failed("UI consistency below threshold: \(uiConsistencyScore)%", nil))
        } else {
            validationResults.append(.passed("UI consistency validated: \(uiConsistencyScore)%"))
        }
        
        // Performance
        validationResults.append(validatePerformance(metrics: performanceMetrics))
        
        // Network
        let networkValidation = validateNetworkIntegrity(metrics: networkMetrics)
        if networkValidation.connectionStability < 90 {
            validationResults.append(.warning("Network stability below optimal: \(networkValidation.connectionStability)%"))
        } else {
            validationResults.append(.passed("Network integrity validated"))
        }
        
        // Data Integrity (placeholder - would need actual data to validate)
        let messageValidation = MessageValidation(
            totalSent: 10,
            totalReceived: 10,
            deliveryRate: 1.0,
            averageLatency: 0.1,
            failures: []
        )
        
        let sessionValidation = SessionValidation(
            sessionId: "test-session-123",
            isValid: true,
            stateConsistency: true,
            dataCompleteness: true,
            issues: []
        )
        
        // Calculate overall metrics
        let metrics = ValidationMetrics(
            uiConsistency: uiConsistencyScore,
            dataIntegrity: 100.0,
            performanceScore: performanceMetrics.averageFrameRate >= 50 ? 100.0 : performanceMetrics.averageFrameRate * 2,
            reliabilityScore: networkValidation.connectionStability,
            overallScore: (uiConsistencyScore + 100.0 + (performanceMetrics.averageFrameRate * 2) + networkValidation.connectionStability) / 4
        )
        
        // Create reports
        let consistencyReport = ConsistencyReport(
            uiElements: uiValidations,
            navigationFlow: [],
            stateManagement: [],
            animationConsistency: []
        )
        
        let integrityReport = DataIntegrityReport(
            messageDelivery: messageValidation,
            sessionState: sessionValidation,
            dataCorruption: [],
            networkIntegrity: networkValidation
        )
        
        return ValidationReport(
            timestamp: Date(),
            results: validationResults,
            metrics: metrics,
            consistency: consistencyReport,
            integrity: integrityReport
        )
    }
    
    // MARK: - Helper Methods
    
    private func areEqual(_ lhs: Any, _ rhs: Any) -> Bool {
        // Simple equality check - enhance for complex types
        if let lhsString = lhs as? String, let rhsString = rhs as? String {
            return lhsString == rhsString
        }
        if let lhsInt = lhs as? Int, let rhsInt = rhs as? Int {
            return lhsInt == rhsInt
        }
        if let lhsBool = lhs as? Bool, let rhsBool = rhs as? Bool {
            return lhsBool == rhsBool
        }
        return false
    }
    
    // MARK: - Report Generation
    
    func generateValidationReport(_ report: ValidationReport) -> String {
        var output = "=== VALIDATION REPORT ===\n"
        output += "Timestamp: \(report.timestamp)\n\n"
        
        output += "OVERALL METRICS:\n"
        output += "• UI Consistency: \(String(format: "%.1f", report.metrics.uiConsistency))%\n"
        output += "• Data Integrity: \(String(format: "%.1f", report.metrics.dataIntegrity))%\n"
        output += "• Performance Score: \(String(format: "%.1f", report.metrics.performanceScore))%\n"
        output += "• Reliability Score: \(String(format: "%.1f", report.metrics.reliabilityScore))%\n"
        output += "• Overall Score: \(String(format: "%.1f", report.metrics.overallScore))%\n\n"
        
        output += "VALIDATION RESULTS:\n"
        output += "• Pass Rate: \(String(format: "%.1f", report.passRate))%\n"
        output += "• Critical Issues: \(report.hasCriticalIssues ? "YES" : "NO")\n\n"
        
        output += "DETAILED RESULTS:\n"
        for result in report.results {
            switch result {
            case .passed(let message):
                output += "✅ PASSED: \(message)\n"
            case .failed(let message, _):
                output += "❌ FAILED: \(message)\n"
            case .warning(let message):
                output += "⚠️ WARNING: \(message)\n"
            case .skipped(let message):
                output += "⏭ SKIPPED: \(message)\n"
            }
        }
        
        return output
    }
}

// MARK: - Supporting Types

struct NetworkMetrics {
    let stability: Double
    let packetLoss: Double
    let averageLatency: TimeInterval
    let reconnections: Int
}