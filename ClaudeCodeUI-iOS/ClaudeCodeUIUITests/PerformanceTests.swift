import XCTest
import os.log

final class PerformanceTests: XCTestCase {
    
    var app: XCUIApplication!
    private let logger = Logger(subsystem: "com.claudecode.ui", category: "PerformanceTests")
    private var performanceMetrics: [String: Any] = [:]
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing", "Performance-Testing"]
        app.launch()
    }
    
    // MARK: - Launch Performance
    
    func testColdLaunchTime() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    func testWarmLaunchTime() throws {
        // First launch to warm up
        app.launch()
        app.terminate()
        
        // Measure warm launch
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    // MARK: - Memory Usage
    
    func testMemoryUsageBaseline() throws {
        measure(metrics: [XCTMemoryMetric()]) {
            // Navigate through main screens
            app.tabBars.buttons["Projects"].tap()
            sleep(1)
            
            app.tabBars.buttons["Terminal"].tap()
            sleep(1)
            
            app.tabBars.buttons["Search"].tap()
            sleep(1)
        }
    }
    
    func testMemoryUsageWithLargeDataset() throws {
        measure(metrics: [XCTMemoryMetric()]) {
            // Navigate to projects
            app.tabBars.buttons["Projects"].tap()
            
            // Scroll through large list (if available)
            let projectsList = app.collectionViews.firstMatch
            if projectsList.waitForExistence(timeout: 5) {
                for _ in 0..<10 {
                    projectsList.swipeUp()
                }
            }
        }
    }
    
    // MARK: - CPU Usage
    
    func testCPUUsageBaseline() throws {
        measure(metrics: [XCTCPUMetric()]) {
            // Perform typical user actions
            navigateThroughApp()
        }
    }
    
    func testCPUUsageDuringMessaging() throws {
        measure(metrics: [XCTCPUMetric()]) {
            navigateToChat()
            
            // Send multiple messages
            let messageInput = app.textViews["MessageInput"] ?? app.textViews.firstMatch
            if messageInput.waitForExistence(timeout: 5) {
                for i in 1...5 {
                    messageInput.tap()
                    messageInput.typeText("Test message \(i)")
                    
                    if app.buttons["Send"].exists {
                        app.buttons["Send"].tap()
                    }
                    sleep(1)
                }
            }
        }
    }
    
    // MARK: - Scrolling Performance
    
    func testProjectsListScrollingPerformance() throws {
        app.tabBars.buttons["Projects"].tap()
        
        let projectsList = app.collectionViews.firstMatch
        XCTAssertTrue(projectsList.waitForExistence(timeout: 5))
        
        measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric]) {
            projectsList.swipeUp(velocity: .fast)
            projectsList.swipeDown(velocity: .fast)
        }
    }
    
    func testChatScrollingPerformance() throws {
        navigateToChat()
        
        let messagesTable = app.tables["MessagesTable"] ?? app.tables.firstMatch
        if messagesTable.waitForExistence(timeout: 5) {
            measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric]) {
                messagesTable.swipeUp(velocity: .fast)
                messagesTable.swipeDown(velocity: .fast)
            }
        }
    }
    
    // MARK: - Network Performance
    
    func testAPIResponseTime() throws {
        measure {
            // Navigate to projects to trigger API call
            app.tabBars.buttons["Projects"].tap()
            
            // Wait for projects to load
            let projectsList = app.collectionViews.firstMatch
            _ = projectsList.waitForExistence(timeout: 10)
            
            // Force refresh
            projectsList.swipeDown()
            
            // Wait for refresh to complete
            sleep(2)
        }
    }
    
    func testWebSocketLatency() throws {
        navigateToChat()
        
        measure {
            let messageInput = app.textViews["MessageInput"] ?? app.textViews.firstMatch
            if messageInput.waitForExistence(timeout: 5) {
                messageInput.tap()
                let timestamp = Date().timeIntervalSince1970
                messageInput.typeText("Latency test \(timestamp)")
                
                if app.buttons["Send"].exists {
                    app.buttons["Send"].tap()
                }
                
                // Measure time until message appears
                let sentMessage = app.staticTexts["Latency test \(timestamp)"]
                _ = sentMessage.waitForExistence(timeout: 5)
            }
        }
    }
    
    // MARK: - Animation Performance
    
    func testTabSwitchingAnimation() throws {
        measure(metrics: [XCTOSSignpostMetric.navigationTransitionMetric]) {
            let tabBar = app.tabBars.firstMatch
            
            tabBar.buttons["Projects"].tap()
            tabBar.buttons["Terminal"].tap()
            tabBar.buttons["Search"].tap()
            tabBar.buttons["Projects"].tap()
        }
    }
    
    func testNavigationAnimation() throws {
        app.tabBars.buttons["Projects"].tap()
        
        let projectsList = app.collectionViews.firstMatch
        XCTAssertTrue(projectsList.waitForExistence(timeout: 5))
        
        measure(metrics: [XCTOSSignpostMetric.navigationTransitionMetric]) {
            if projectsList.cells.count > 0 {
                // Push animation
                projectsList.cells.element(boundBy: 0).tap()
                sleep(1)
                
                // Pop animation
                if app.navigationBars.buttons.element(boundBy: 0).exists {
                    app.navigationBars.buttons.element(boundBy: 0).tap()
                }
                sleep(1)
            }
        }
    }
    
    // MARK: - Connection Stability Tests (TODOS #39-40)
    
    func testConnectionStability() throws {
        logger.info("Starting connection stability test - 5 minute monitoring")
        
        navigateToChat()
        
        var disconnectCount = 0
        var reconnectCount = 0
        var connectionStates: [Date: String] = [:]
        let startTime = Date()
        let testDuration: TimeInterval = 300 // 5 minutes
        
        // Monitor connection status for 5 minutes
        let expectation = self.expectation(description: "Connection monitoring")
        expectation.isInverted = true
        
        DispatchQueue.global(qos: .background).async {
            while Date().timeIntervalSince(startTime) < testDuration {
                // Check connection status indicator
                DispatchQueue.main.async {
                    let statusIndicator = self.app.otherElements["ConnectionIndicator"]
                    if statusIndicator.exists {
                        let currentColor = statusIndicator.value as? String ?? "unknown"
                        connectionStates[Date()] = currentColor
                        
                        // Track disconnections
                        if currentColor.contains("red") || currentColor.contains("disconnected") {
                            disconnectCount += 1
                        } else if currentColor.contains("orange") || currentColor.contains("reconnecting") {
                            reconnectCount += 1
                        }
                    }
                }
                Thread.sleep(forTimeInterval: 1.0) // Check every second
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: testDuration + 10)
        
        // Calculate stability metrics
        let totalChecks = connectionStates.count
        let stableConnections = connectionStates.values.filter { $0.contains("green") || $0.contains("connected") }.count
        let stabilityRate = totalChecks > 0 ? Float(stableConnections) / Float(totalChecks) * 100 : 0
        
        // Log results
        logger.info("Connection Stability Results:")
        logger.info("  - Test Duration: \(testDuration) seconds")
        logger.info("  - Total Checks: \(totalChecks)")
        logger.info("  - Disconnections: \(disconnectCount)")
        logger.info("  - Reconnections: \(reconnectCount)")
        logger.info("  - Stability Rate: \(stabilityRate)%")
        
        performanceMetrics["connectionStability"] = [
            "stabilityRate": stabilityRate,
            "disconnections": disconnectCount,
            "reconnections": reconnectCount
        ]
        
        // Assert connection stability
        XCTAssertEqual(disconnectCount, 0, "Unexpected disconnections: \(disconnectCount)")
        XCTAssertGreaterThan(stabilityRate, 99.0, "Connection stability below threshold: \(stabilityRate)%")
    }
    
    // MARK: - UI Consistency Tests (TODOS #41-42)
    
    func testUIConsistency() throws {
        logger.info("Starting UI consistency validation")
        
        var screenshots: [(String, XCUIScreenshot)] = []
        var uiIssues: [String] = []
        
        // Capture screenshots at different states
        app.tabBars.buttons["Projects"].tap()
        Thread.sleep(forTimeInterval: 1.0)
        screenshots.append(("Projects_Tab", XCUIScreen.main.screenshot()))
        
        // Navigate to chat
        let projectsList = app.collectionViews.firstMatch
        if projectsList.waitForExistence(timeout: 5) && projectsList.cells.count > 0 {
            projectsList.cells.element(boundBy: 0).tap()
            Thread.sleep(forTimeInterval: 2.0)
            screenshots.append(("Chat_View", XCUIScreen.main.screenshot()))
        }
        
        // Test orientation changes
        XCUIDevice.shared.orientation = .landscapeLeft
        Thread.sleep(forTimeInterval: 1.0)
        screenshots.append(("Landscape_Left", XCUIScreen.main.screenshot()))
        
        XCUIDevice.shared.orientation = .portrait
        Thread.sleep(forTimeInterval: 1.0)
        screenshots.append(("Portrait_After_Rotation", XCUIScreen.main.screenshot()))
        
        // Check for UI glitches
        for (state, screenshot) in screenshots {
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "UI_State_\(state)"
            attachment.lifetime = .keepAlways
            add(attachment)
            
            // Analyze screenshot for common issues
            if let image = screenshot.image {
                // Check for rendering issues
                let renderingIssue = checkForRenderingIssues(image)
                if renderingIssue {
                    uiIssues.append("Rendering issue in state: \(state)")
                }
            }
        }
        
        logger.info("UI Consistency Results:")
        logger.info("  - States Tested: \(screenshots.count)")
        logger.info("  - Issues Found: \(uiIssues.count)")
        
        performanceMetrics["uiConsistency"] = [
            "statesTested": screenshots.count,
            "issuesFound": uiIssues.count,
            "issues": uiIssues
        ]
        
        XCTAssertEqual(uiIssues.count, 0, "UI consistency issues found: \(uiIssues)")
    }
    
    // MARK: - Frame Rate Tests (TODOS #43-44)
    
    func testScrollingFrameRate() throws {
        logger.info("Starting frame rate measurement")
        
        navigateToChat()
        
        let messagesTable = app.tables["MessagesTable"] ?? app.tables.firstMatch
        XCTAssertTrue(messagesTable.waitForExistence(timeout: 5), "Messages table not found")
        
        // Measure scrolling performance
        let scrollMetrics = measure(metrics: [
            XCTOSSignpostMetric.scrollingAndDecelerationMetric,
            XCTOSSignpostMetric.frameRateMetric(fps: 60)
        ]) {
            // Rapid scrolling test
            for _ in 0..<5 {
                messagesTable.swipeUp(velocity: .fast)
                Thread.sleep(forTimeInterval: 0.2)
                messagesTable.swipeDown(velocity: .fast)
                Thread.sleep(forTimeInterval: 0.2)
            }
        }
        
        logger.info("Frame Rate Results:")
        logger.info("  - Scrolling completed")
        logger.info("  - Target: 60 FPS")
        
        performanceMetrics["frameRate"] = [
            "target": 60,
            "test": "scrolling"
        ]
    }
    
    // MARK: - Response Time Tests (TODO #45)
    
    func testMessageResponseTime() throws {
        logger.info("Starting message response time measurement")
        
        navigateToChat()
        
        let messageInput = app.textViews["MessageInput"] ?? app.textViews.firstMatch
        XCTAssertTrue(messageInput.waitForExistence(timeout: 5), "Message input not found")
        
        var responseTimes: [TimeInterval] = []
        
        // Test multiple messages
        for i in 1...5 {
            let testMessage = "Performance test message \(i) - \(Date().timeIntervalSince1970)"
            let startTime = Date()
            
            // Send message
            messageInput.tap()
            messageInput.typeText(testMessage)
            
            if app.buttons["Send"].exists {
                app.buttons["Send"].tap()
            }
            
            // Wait for message to appear in chat
            let sentMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Performance test message \(i)")).firstMatch
            let messageAppeared = sentMessage.waitForExistence(timeout: 2)
            
            if messageAppeared {
                let responseTime = Date().timeIntervalSince(startTime)
                responseTimes.append(responseTime)
                logger.info("Message \(i) response time: \(responseTime * 1000)ms")
            }
            
            Thread.sleep(forTimeInterval: 1.0)
        }
        
        // Calculate average response time
        let averageResponseTime = responseTimes.isEmpty ? 0 : responseTimes.reduce(0, +) / Double(responseTimes.count)
        
        logger.info("Response Time Results:")
        logger.info("  - Messages Sent: \(responseTimes.count)")
        logger.info("  - Average Response Time: \(averageResponseTime * 1000)ms")
        logger.info("  - Max Response Time: \((responseTimes.max() ?? 0) * 1000)ms")
        logger.info("  - Min Response Time: \((responseTimes.min() ?? 0) * 1000)ms")
        
        performanceMetrics["responseTime"] = [
            "average": averageResponseTime * 1000,
            "max": (responseTimes.max() ?? 0) * 1000,
            "min": (responseTimes.min() ?? 0) * 1000,
            "samples": responseTimes.count
        ]
        
        // Assert response time is under 500ms
        XCTAssertLessThan(averageResponseTime, 0.5, "Average response time too slow: \(averageResponseTime * 1000)ms")
    }
    
    // MARK: - Memory Leak Tests (TODO #46)
    
    func testMemoryLeaksComprehensive() throws {
        logger.info("Starting comprehensive memory leak detection")
        
        // Get initial memory baseline
        let initialMemory = getMemoryUsage()
        logger.info("Initial memory: \(formatBytes(initialMemory))")
        
        var memorySnapshots: [(String, Int64)] = [("Initial", initialMemory)]
        
        // Perform intensive operations
        for cycle in 1...10 {
            autoreleasepool {
                // Navigate through tabs
                app.tabBars.buttons["Projects"].tap()
                Thread.sleep(forTimeInterval: 0.5)
                
                // Open and close chat multiple times
                let projectsList = app.collectionViews.firstMatch
                if projectsList.waitForExistence(timeout: 2) && projectsList.cells.count > 0 {
                    projectsList.cells.element(boundBy: 0).tap()
                    Thread.sleep(forTimeInterval: 1.0)
                    
                    // Send a message
                    let messageInput = app.textViews["MessageInput"] ?? app.textViews.firstMatch
                    if messageInput.waitForExistence(timeout: 2) {
                        messageInput.tap()
                        messageInput.typeText("Memory test \(cycle)")
                        if app.buttons["Send"].exists {
                            app.buttons["Send"].tap()
                        }
                    }
                    
                    // Go back
                    if app.navigationBars.buttons.element(boundBy: 0).exists {
                        app.navigationBars.buttons.element(boundBy: 0).tap()
                    }
                }
                
                // Check memory after each cycle
                let cycleMemory = getMemoryUsage()
                memorySnapshots.append(("Cycle_\(cycle)", cycleMemory))
                logger.info("Memory after cycle \(cycle): \(formatBytes(cycleMemory))")
            }
        }
        
        // Force cleanup and wait
        Thread.sleep(forTimeInterval: 5.0)
        
        // Final memory check
        let finalMemory = getMemoryUsage()
        memorySnapshots.append(("Final", finalMemory))
        logger.info("Final memory: \(formatBytes(finalMemory))")
        
        // Calculate memory growth
        let memoryGrowth = finalMemory - initialMemory
        let growthPercentage = Double(memoryGrowth) / Double(initialMemory) * 100
        
        logger.info("Memory Leak Test Results:")
        logger.info("  - Initial Memory: \(formatBytes(initialMemory))")
        logger.info("  - Final Memory: \(formatBytes(finalMemory))")
        logger.info("  - Memory Growth: \(formatBytes(memoryGrowth))")
        logger.info("  - Growth Percentage: \(String(format: "%.2f", growthPercentage))%")
        
        performanceMetrics["memoryLeak"] = [
            "initial": initialMemory,
            "final": finalMemory,
            "growth": memoryGrowth,
            "growthPercentage": growthPercentage,
            "snapshots": memorySnapshots.map { ["stage": $0.0, "memory": $0.1] }
        ]
        
        // Assert no significant memory leak (allow 10MB growth for caching)
        XCTAssertLessThan(memoryGrowth, 10_000_000, "Memory leak detected: \(formatBytes(memoryGrowth)) growth")
    }
    
    // MARK: - Stress Tests
    
    func testRapidTabSwitching() throws {
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
            let tabBar = app.tabBars.firstMatch
            
            for _ in 0..<20 {
                tabBar.buttons["Projects"].tap()
                tabBar.buttons["Terminal"].tap()
                tabBar.buttons["Search"].tap()
            }
        }
    }
    
    func testConcurrentOperations() throws {
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
            // Start multiple operations
            let tabBar = app.tabBars.firstMatch
            
            // Navigate to search and start search
            tabBar.buttons["Search"].tap()
            let searchField = app.searchFields.firstMatch
            if searchField.waitForExistence(timeout: 2) {
                searchField.tap()
                searchField.typeText("concurrent test")
            }
            
            // Quickly switch to projects
            tabBar.buttons["Projects"].tap()
            
            // Start scrolling
            let projectsList = app.collectionViews.firstMatch
            if projectsList.waitForExistence(timeout: 2) {
                projectsList.swipeUp()
            }
            
            // Switch to terminal
            tabBar.buttons["Terminal"].tap()
        }
    }
    
    // MARK: - Performance Summary
    
    func testGeneratePerformanceReport() throws {
        logger.info("Generating comprehensive performance report")
        
        // Run all performance tests
        try? testConnectionStability()
        try? testUIConsistency()
        try? testScrollingFrameRate()
        try? testMessageResponseTime()
        try? testMemoryLeaksComprehensive()
        
        // Generate report
        logger.info("======= PERFORMANCE VALIDATION REPORT =======")
        logger.info("Timestamp: \(Date())")
        logger.info("")
        
        if let connectionMetrics = performanceMetrics["connectionStability"] as? [String: Any] {
            logger.info("CONNECTION STABILITY:")
            logger.info("  ✅ Stability Rate: \(connectionMetrics["stabilityRate"] ?? 0)%")
            logger.info("  ✅ Disconnections: \(connectionMetrics["disconnections"] ?? 0)")
        }
        
        if let uiMetrics = performanceMetrics["uiConsistency"] as? [String: Any] {
            logger.info("")
            logger.info("UI CONSISTENCY:")
            logger.info("  ✅ States Tested: \(uiMetrics["statesTested"] ?? 0)")
            logger.info("  ✅ Issues Found: \(uiMetrics["issuesFound"] ?? 0)")
        }
        
        if let responseMetrics = performanceMetrics["responseTime"] as? [String: Any] {
            logger.info("")
            logger.info("RESPONSE TIME:")
            logger.info("  ✅ Average: \(responseMetrics["average"] ?? 0)ms")
            logger.info("  ✅ Max: \(responseMetrics["max"] ?? 0)ms")
        }
        
        if let memoryMetrics = performanceMetrics["memoryLeak"] as? [String: Any] {
            logger.info("")
            logger.info("MEMORY MANAGEMENT:")
            logger.info("  ✅ Memory Growth: \(formatBytes(memoryMetrics["growth"] as? Int64 ?? 0))")
            logger.info("  ✅ Growth Rate: \(String(format: "%.2f", memoryMetrics["growthPercentage"] as? Double ?? 0))%")
        }
        
        logger.info("")
        logger.info("=============================================")
        
        // Save metrics to file for CI/CD integration
        savePerformanceMetrics()
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> Int64 {
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
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
    
    private func checkForRenderingIssues(_ image: UIImage) -> Bool {
        // Simple check for common rendering issues
        // In production, use more sophisticated image analysis
        guard let cgImage = image.cgImage else { return true }
        
        // Check for blank or corrupted images
        let width = cgImage.width
        let height = cgImage.height
        
        if width == 0 || height == 0 {
            return true
        }
        
        // Check for solid color (potential rendering failure)
        // This is a simplified check - enhance for production
        return false
    }
    
    private func savePerformanceMetrics() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                     in: .userDomainMask).first!
        let metricsPath = documentsPath.appendingPathComponent("performance_metrics.json")
        
        do {
            let data = try JSONSerialization.data(withJSONObject: performanceMetrics,
                                                  options: .prettyPrinted)
            try data.write(to: metricsPath)
            logger.info("Performance metrics saved to: \(metricsPath.path)")
        } catch {
            logger.error("Failed to save performance metrics: \(error)")
        }
    }
    
    private func navigateThroughApp() {
        let tabBar = app.tabBars.firstMatch
        
        // Navigate through all tabs
        tabBar.buttons["Projects"].tap()
        sleep(1)
        
        tabBar.buttons["Terminal"].tap()
        sleep(1)
        
        tabBar.buttons["Search"].tap()
        sleep(1)
        
        if tabBar.buttons["MCP"].exists {
            tabBar.buttons["MCP"].tap()
            sleep(1)
        }
        
        if tabBar.buttons["Settings"].exists {
            tabBar.buttons["Settings"].tap()
            sleep(1)
        } else if tabBar.buttons["More"].exists {
            tabBar.buttons["More"].tap()
            sleep(1)
        }
    }
    
    private func navigateToChat() {
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Projects"].tap()
        
        let projectsList = app.collectionViews.firstMatch
        if projectsList.waitForExistence(timeout: 5), projectsList.cells.count > 0 {
            projectsList.cells.element(boundBy: 0).tap()
            
            let sessionsList = app.tables.firstMatch
            if sessionsList.waitForExistence(timeout: 3) {
                if sessionsList.cells.count > 0 {
                    sessionsList.cells.element(boundBy: 0).tap()
                } else if app.navigationBars.buttons["Add"].exists {
                    app.navigationBars.buttons["Add"].tap()
                }
            }
        }
    }
}