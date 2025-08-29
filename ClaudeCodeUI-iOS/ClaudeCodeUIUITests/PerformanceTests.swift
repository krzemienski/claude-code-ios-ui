import XCTest

final class PerformanceTests: XCTestCase {
    
    var app: XCUIApplication!
    
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
        measure(metrics: [XCTOSSignpostMetric.customSignpostMetric]) {
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
        
        measure(metrics: [XCTOSSignpostMetric.customSignpostMetric]) {
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
    
    // MARK: - Helper Methods
    
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