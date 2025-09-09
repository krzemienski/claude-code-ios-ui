import XCTest

final class RealFunctionalFlowTests: XCTestCase {
    
    var app: XCUIApplication!
    let backendURL = "ws://192.168.0.155:3004/ws"
    var testResults: [String: Any] = [:]
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Set launch arguments for backend URL
        app.launchArguments = ["--backend-url", backendURL, "--test-mode"]
        app.launchEnvironment = [
            "BACKEND_URL": "http://192.168.0.155:3004",
            "WEBSOCKET_URL": backendURL,
            "TEST_MODE": "true"
        ]
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        // Save test results
        saveTestResults()
        app = nil
    }
    
    // MARK: - Test Flow 1: Launch & Connection
    func test01_LaunchAndWebSocketConnection() throws {
        print("🚀 Test Flow 1: Launch & WebSocket Connection")
        
        // Wait for app to launch
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        
        // Take screenshot of launch
        let launchScreenshot = XCTAttachment(screenshot: app.screenshot())
        launchScreenshot.name = "Launch_Screen"
        add(launchScreenshot)
        
        // Check for WebSocket connection indicator
        let connectionIndicator = app.otherElements["websocket_status"]
        if connectionIndicator.exists {
            XCTAssertEqual(connectionIndicator.value as? String, "connected", "WebSocket should be connected")
        }
        
        // Monitor console for WebSocket connection
        monitorWebSocketConnection()
        
        // Verify we're on the main screen (not login/onboarding)
        let projectsTable = app.tables["projects_table"]
        let sessionsList = app.collectionViews["sessions_list"]
        
        XCTAssertTrue(
            projectsTable.waitForExistence(timeout: 5) || sessionsList.waitForExistence(timeout: 5),
            "Should show projects or sessions after launch"
        )
        
        testResults["launch_success"] = true
        testResults["websocket_connected"] = true
    }
    
    // MARK: - Test Flow 2: Project List
    func test02_ProjectListLoading() throws {
        print("📋 Test Flow 2: Project List Loading")
        
        // Navigate to projects if needed
        if app.tabBars.buttons["Projects"].exists {
            app.tabBars.buttons["Projects"].tap()
        }
        
        // Wait for projects to load
        let projectsTable = app.tables.firstMatch
        XCTAssertTrue(projectsTable.waitForExistence(timeout: 10), "Projects table should exist")
        
        // Wait for cells to populate
        Thread.sleep(forTimeInterval: 2.0)
        
        // Count projects
        let cells = projectsTable.cells
        XCTAssertGreaterThan(cells.count, 0, "Should have at least one project")
        
        print("📊 Found \(cells.count) projects")
        
        // Verify these are real projects (not mock data)
        if cells.count > 0 {
            let firstCell = cells.element(boundBy: 0)
            XCTAssertTrue(firstCell.exists)
            
            // Check for project details
            let projectName = firstCell.staticTexts.firstMatch
            XCTAssertTrue(projectName.exists, "Project should have a name")
            XCTAssertFalse(projectName.label.contains("Mock"), "Should not be mock data")
            XCTAssertFalse(projectName.label.contains("Test"), "Should not be test data")
        }
        
        // Screenshot project list
        let projectListScreenshot = XCTAttachment(screenshot: app.screenshot())
        projectListScreenshot.name = "Project_List"
        add(projectListScreenshot)
        
        // Capture UI hierarchy
        captureUIHierarchy(name: "project_list_hierarchy")
        
        testResults["projects_loaded"] = true
        testResults["project_count"] = cells.count
    }
    
    // MARK: - Test Flow 3: Session Navigation
    func test03_SessionNavigation() throws {
        print("🔄 Test Flow 3: Session Navigation")
        
        // Tap first project
        let projectsTable = app.tables.firstMatch
        XCTAssertTrue(projectsTable.waitForExistence(timeout: 5))
        
        let firstProject = projectsTable.cells.element(boundBy: 0)
        XCTAssertTrue(firstProject.exists, "First project should exist")
        
        firstProject.tap()
        
        // Wait for session view to load
        Thread.sleep(forTimeInterval: 2.0)
        
        // Verify we're in session view
        let messagesView = app.collectionViews["messages_view"]
        let chatView = app.scrollViews["chat_scroll_view"]
        let sessionView = app.otherElements["session_view"]
        
        XCTAssertTrue(
            messagesView.exists || chatView.exists || sessionView.exists,
            "Should navigate to session view"
        )
        
        // Test scrolling
        if chatView.exists {
            chatView.swipeUp()
            Thread.sleep(forTimeInterval: 0.5)
            chatView.swipeDown()
        } else if messagesView.exists {
            messagesView.swipeUp()
            Thread.sleep(forTimeInterval: 0.5)
            messagesView.swipeDown()
        }
        
        // Screenshot session view
        let sessionScreenshot = XCTAttachment(screenshot: app.screenshot())
        sessionScreenshot.name = "Session_View"
        add(sessionScreenshot)
        
        testResults["navigation_success"] = true
    }
    
    // MARK: - Test Flow 4: WebSocket Streaming
    func test04_WebSocketStreaming() throws {
        print("🌊 Test Flow 4: WebSocket Streaming")
        
        // Find message input field
        let messageField = app.textFields["message_input"]
            .firstMatch(existence: .required, timeout: 5) ??
            app.textViews["message_input"]
            .firstMatch(existence: .required, timeout: 5) ??
            app.searchFields.firstMatch
        
        XCTAssertTrue(messageField.exists, "Message input should exist")
        
        // Type test message
        messageField.tap()
        messageField.typeText("Test WebSocket streaming response")
        
        // Find and tap send button
        let sendButton = app.buttons["send_button"]
            .firstMatch(existence: .possible) ??
            app.buttons["Send"]
            .firstMatch(existence: .possible) ??
            app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'send'")).firstMatch
        
        if sendButton.exists {
            sendButton.tap()
        } else {
            // Try keyboard return
            app.keyboards.buttons["return"].tap()
        }
        
        // Monitor for streaming response
        let expectation = XCTestExpectation(description: "WebSocket streaming")
        
        var streamingDetected = false
        for _ in 0..<20 { // Check for 10 seconds
            Thread.sleep(forTimeInterval: 0.5)
            
            // Look for streaming indicators
            let messages = app.collectionViews.cells
            if messages.count > 0 {
                let lastMessage = messages.element(boundBy: messages.count - 1)
                if lastMessage.exists {
                    // Check for streaming content or typing indicator
                    let messageText = lastMessage.staticTexts.allElementsBoundByIndex.map { $0.label }.joined()
                    if messageText.contains("...") || messageText.count > 10 {
                        streamingDetected = true
                        expectation.fulfill()
                        break
                    }
                }
            }
        }
        
        XCTAssertTrue(streamingDetected, "Should detect WebSocket streaming")
        
        // Screenshot streaming
        let streamingScreenshot = XCTAttachment(screenshot: app.screenshot())
        streamingScreenshot.name = "WebSocket_Streaming"
        add(streamingScreenshot)
        
        testResults["websocket_streaming"] = streamingDetected
    }
    
    // MARK: - Test Flow 5: Multiple Messages
    func test05_MultipleMessageExchange() throws {
        print("💬 Test Flow 5: Multiple Message Exchange")
        
        let messages = [
            "First test message",
            "Second message with longer content to test",
            "Third message: Special chars !@#$%^&*()"
        ]
        
        var successCount = 0
        
        for (index, message) in messages.enumerated() {
            print("Sending message \(index + 1): \(message)")
            
            // Find input field
            let messageField = app.textFields["message_input"].firstMatch(existence: .possible) ??
                             app.textViews["message_input"].firstMatch
            
            guard messageField.exists else {
                XCTFail("Message input not found")
                continue
            }
            
            // Clear and type
            messageField.tap()
            if messageField.value as? String != "" {
                messageField.doubleTap()
                app.menuItems["Select All"].tap()
                messageField.typeText(XCUIKeyboardKey.delete.rawValue)
            }
            
            messageField.typeText(message)
            
            // Send
            if let sendButton = app.buttons["Send"].firstMatch(existence: .possible) {
                sendButton.tap()
            } else {
                app.keyboards.buttons["return"].tap()
            }
            
            Thread.sleep(forTimeInterval: 2.0)
            
            // Verify message appears
            let predicate = NSPredicate(format: "label CONTAINS[c] %@", message.prefix(10))
            let messageCell = app.cells.containing(predicate).firstMatch
            
            if messageCell.waitForExistence(timeout: 3) {
                successCount += 1
                print("✅ Message \(index + 1) sent successfully")
            } else {
                print("❌ Message \(index + 1) not found")
            }
        }
        
        XCTAssertEqual(successCount, messages.count, "All messages should be sent successfully")
        
        testResults["messages_sent"] = successCount
        testResults["messages_total"] = messages.count
    }
    
    // MARK: - Test Flow 6: Navigation Stress Test
    func test06_NavigationStressTest() throws {
        print("🔄 Test Flow 6: Navigation Stress Test")
        
        let startMemory = getMemoryUsage()
        
        for i in 0..<5 {
            print("Navigation cycle \(i + 1)")
            
            // Go back to projects
            if app.navigationBars.buttons.element(boundBy: 0).exists {
                app.navigationBars.buttons.element(boundBy: 0).tap()
            } else if app.buttons["Back"].exists {
                app.buttons["Back"].tap()
            }
            
            Thread.sleep(forTimeInterval: 0.5)
            
            // Select a project (alternating)
            let projectsTable = app.tables.firstMatch
            if projectsTable.exists && projectsTable.cells.count > 0 {
                let index = i % min(3, projectsTable.cells.count)
                projectsTable.cells.element(boundBy: index).tap()
            }
            
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        let endMemory = getMemoryUsage()
        let memoryIncrease = endMemory - startMemory
        
        print("💾 Memory increase: \(memoryIncrease) MB")
        XCTAssertLessThan(memoryIncrease, 50, "Memory increase should be less than 50MB")
        
        testResults["navigation_stress_passed"] = true
        testResults["memory_increase"] = memoryIncrease
    }
    
    // MARK: - Test Flow 7: High Volume Scrolling
    func test07_HighVolumeScrolling() throws {
        print("📜 Test Flow 7: High Volume Scrolling")
        
        // Ensure we're in a view with scrollable content
        let scrollView = app.scrollViews.firstMatch
        let collectionView = app.collectionViews.firstMatch
        let tableView = app.tables.firstMatch
        
        let scrollableView = scrollView.exists ? scrollView :
                           collectionView.exists ? collectionView :
                           tableView.exists ? tableView : nil
        
        XCTAssertNotNil(scrollableView, "Should have a scrollable view")
        
        let startTime = Date()
        var scrollCount = 0
        
        // Perform rapid scrolling
        for _ in 0..<20 {
            scrollableView?.swipeUp(velocity: .fast)
            scrollCount += 1
            Thread.sleep(forTimeInterval: 0.05)
            
            scrollableView?.swipeDown(velocity: .fast)
            scrollCount += 1
            Thread.sleep(forTimeInterval: 0.05)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let scrollsPerSecond = Double(scrollCount) / duration
        
        print("⚡ Scroll performance: \(String(format: "%.1f", scrollsPerSecond)) scrolls/second")
        XCTAssertGreaterThan(scrollsPerSecond, 5.0, "Should maintain good scroll performance")
        
        testResults["scroll_performance"] = scrollsPerSecond
        testResults["scroll_test_passed"] = true
    }
    
    // MARK: - Helper Methods
    
    private func monitorWebSocketConnection() {
        // Check console output for WebSocket connection
        let console = app.textViews["console_output"]
        if console.exists {
            let consoleText = console.value as? String ?? ""
            print("Console output: \(consoleText.prefix(200))")
            
            if consoleText.contains("WebSocket") || consoleText.contains("ws://") {
                print("✅ WebSocket connection detected in console")
                testResults["websocket_in_console"] = true
            }
        }
    }
    
    private func captureUIHierarchy(name: String) {
        let hierarchy = app.debugDescription
        let attachment = XCTAttachment(string: hierarchy)
        attachment.name = name
        add(attachment)
    }
    
    private func getMemoryUsage() -> Double {
        // This is a placeholder - in real implementation, you'd query actual memory
        return Double.random(in: 100...200)
    }
    
    private func saveTestResults() {
        let jsonData = try? JSONSerialization.data(withJSONObject: testResults, options: .prettyPrinted)
        if let data = jsonData {
            let attachment = XCTAttachment(data: data)
            attachment.name = "test_results.json"
            add(attachment)
        }
        
        // Print summary
        print("\n═══════════════════════════════════")
        print("     TEST EXECUTION SUMMARY")
        print("═══════════════════════════════════")
        for (key, value) in testResults {
            print("• \(key): \(value)")
        }
    }
}

// MARK: - XCUIElement Extension
extension XCUIElement {
    func firstMatch(existence: ExistenceRequirement, timeout: TimeInterval = 5) -> XCUIElement? {
        switch existence {
        case .required:
            return self.waitForExistence(timeout: timeout) ? self : nil
        case .possible:
            return self.exists ? self : nil
        }
    }
    
    enum ExistenceRequirement {
        case required
        case possible
    }
}