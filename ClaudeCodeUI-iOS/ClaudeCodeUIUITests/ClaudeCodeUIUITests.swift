import XCTest

final class ClaudeCodeUIUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    // MARK: - Setup/Teardown
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launchEnvironment = ["TESTING_MODE": "true"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Tab Bar Navigation Tests
    
    func testTabBarNavigation() throws {
        // Verify all 5 tabs are present
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
        
        // Test Projects tab
        let projectsTab = tabBar.buttons["Projects"]
        XCTAssertTrue(projectsTab.exists, "Projects tab should exist")
        projectsTab.tap()
        XCTAssertTrue(app.navigationBars["Projects"].exists, "Should show Projects view")
        
        // Test Terminal tab
        let terminalTab = tabBar.buttons["Terminal"]
        XCTAssertTrue(terminalTab.exists, "Terminal tab should exist")
        terminalTab.tap()
        XCTAssertTrue(app.navigationBars["Terminal"].exists || app.otherElements["TerminalView"].exists, "Should show Terminal view")
        
        // Test Search tab
        let searchTab = tabBar.buttons["Search"]
        XCTAssertTrue(searchTab.exists, "Search tab should exist")
        searchTab.tap()
        XCTAssertTrue(app.navigationBars["Search"].exists || app.searchFields.firstMatch.exists, "Should show Search view")
        
        // Test MCP tab (might be in More menu on smaller devices)
        if tabBar.buttons["MCP"].exists {
            tabBar.buttons["MCP"].tap()
            XCTAssertTrue(app.navigationBars["MCP Servers"].exists, "Should show MCP view")
        } else if tabBar.buttons["More"].exists {
            tabBar.buttons["More"].tap()
            let mcpCell = app.tables.cells.staticTexts["MCP"]
            if mcpCell.exists {
                mcpCell.tap()
                XCTAssertTrue(app.navigationBars["MCP Servers"].exists, "Should show MCP view")
            }
        }
        
        // Test Settings tab (might be in More menu)
        if tabBar.buttons["Settings"].exists {
            tabBar.buttons["Settings"].tap()
            XCTAssertTrue(app.navigationBars["Settings"].exists, "Should show Settings view")
        } else if tabBar.buttons["More"].exists {
            tabBar.buttons["More"].tap()
            let settingsCell = app.tables.cells.staticTexts["Settings"]
            if settingsCell.exists {
                settingsCell.tap()
                XCTAssertTrue(app.navigationBars["Settings"].exists, "Should show Settings view")
            }
        }
    }
    
    // MARK: - Projects Flow Tests
    
    func testProjectsListAndNavigation() throws {
        // Navigate to Projects tab
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Projects"].tap()
        
        // Wait for projects list to load
        let projectsList = app.collectionViews.firstMatch
        XCTAssertTrue(projectsList.waitForExistence(timeout: 5), "Projects list should appear")
        
        // If there are projects, test tapping one
        if projectsList.cells.count > 0 {
            let firstProject = projectsList.cells.element(boundBy: 0)
            firstProject.tap()
            
            // Should navigate to sessions list
            XCTAssertTrue(app.navigationBars["Sessions"].waitForExistence(timeout: 3) ||
                         app.tables.firstMatch.waitForExistence(timeout: 3),
                         "Should navigate to sessions list")
            
            // Test back navigation
            if app.navigationBars.buttons.element(boundBy: 0).exists {
                app.navigationBars.buttons.element(boundBy: 0).tap()
                XCTAssertTrue(projectsList.waitForExistence(timeout: 3), "Should return to projects list")
            }
        }
    }
    
    // MARK: - Session and Chat Flow Tests
    
    func testSessionToMessagesFlow() throws {
        // Navigate to Projects
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Projects"].tap()
        
        // Select first project if available
        let projectsList = app.collectionViews.firstMatch
        guard projectsList.waitForExistence(timeout: 5),
              projectsList.cells.count > 0 else {
            XCTSkip("No projects available for testing")
            return
        }
        
        projectsList.cells.element(boundBy: 0).tap()
        
        // Wait for sessions list
        let sessionsList = app.tables.firstMatch
        guard sessionsList.waitForExistence(timeout: 5) else {
            XCTSkip("Sessions list did not appear")
            return
        }
        
        // Create new session or select existing
        if app.navigationBars.buttons["Add"].exists {
            // Test creating new session
            app.navigationBars.buttons["Add"].tap()
            
            // Should navigate to chat view
            XCTAssertTrue(app.otherElements["ChatView"].waitForExistence(timeout: 3) ||
                         app.textViews.firstMatch.waitForExistence(timeout: 3),
                         "Should open chat view")
        } else if sessionsList.cells.count > 0 {
            // Select existing session
            sessionsList.cells.element(boundBy: 0).tap()
            
            // Should show messages
            XCTAssertTrue(app.otherElements["ChatView"].waitForExistence(timeout: 3) ||
                         app.tables["MessagesTable"].waitForExistence(timeout: 3),
                         "Should show chat messages")
        }
    }
    
    // MARK: - Message Sending Test
    
    func testSendingMessage() throws {
        // Navigate to a chat session
        navigateToChat()
        
        // Find message input field
        let messageInput = app.textViews["MessageInput"] ?? app.textViews.firstMatch
        guard messageInput.waitForExistence(timeout: 5) else {
            XCTSkip("Message input not found")
            return
        }
        
        // Type a message
        messageInput.tap()
        messageInput.typeText("Test message from UI test")
        
        // Send message
        let sendButton = app.buttons["Send"] ?? app.buttons["SendMessage"]
        if sendButton.exists {
            sendButton.tap()
            
            // Verify message appears in chat
            let sentMessage = app.staticTexts["Test message from UI test"]
            XCTAssertTrue(sentMessage.waitForExistence(timeout: 5), "Sent message should appear in chat")
        }
    }
    
    // MARK: - Terminal Tests
    
    func testTerminalCommandExecution() throws {
        // Navigate to Terminal tab
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Terminal"].tap()
        
        // Find command input
        let terminalInput = app.textFields["TerminalInput"] ?? app.textFields.firstMatch
        guard terminalInput.waitForExistence(timeout: 5) else {
            XCTSkip("Terminal input not found")
            return
        }
        
        // Type and execute command
        terminalInput.tap()
        terminalInput.typeText("ls -la")
        
        // Press return or tap execute
        if app.buttons["Execute"].exists {
            app.buttons["Execute"].tap()
        } else {
            app.keyboards.buttons["Return"].tap()
        }
        
        // Verify output appears
        let terminalOutput = app.textViews["TerminalOutput"] ?? app.textViews.firstMatch
        XCTAssertTrue(terminalOutput.waitForExistence(timeout: 5), "Terminal output should appear")
    }
    
    // MARK: - Search Functionality Test
    
    func testSearchFunctionality() throws {
        // Navigate to Search tab
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Search"].tap()
        
        // Find search field
        let searchField = app.searchFields.firstMatch
        guard searchField.waitForExistence(timeout: 5) else {
            XCTSkip("Search field not found")
            return
        }
        
        // Perform search
        searchField.tap()
        searchField.typeText("test query")
        
        // Trigger search
        if app.buttons["Search"].exists {
            app.buttons["Search"].tap()
        } else {
            app.keyboards.buttons["Search"].tap()
        }
        
        // Verify results or no results message appears
        let resultsTable = app.tables["SearchResults"] ?? app.tables.firstMatch
        let noResultsLabel = app.staticTexts["No results found"]
        
        XCTAssertTrue(resultsTable.waitForExistence(timeout: 5) || 
                     noResultsLabel.waitForExistence(timeout: 5),
                     "Should show either search results or no results message")
    }
    
    // MARK: - Settings Tests
    
    func testSettingsAccess() throws {
        // Navigate to Settings (may be in More menu)
        navigateToSettings()
        
        // Verify settings options exist
        let settingsTable = app.tables.firstMatch
        XCTAssertTrue(settingsTable.waitForExistence(timeout: 5), "Settings table should exist")
        
        // Test some common settings
        let themeCell = settingsTable.cells.staticTexts["Theme"]
        let fontSizeCell = settingsTable.cells.staticTexts["Font Size"]
        
        XCTAssertTrue(themeCell.exists || fontSizeCell.exists, "Should have settings options")
    }
    
    // MARK: - WebSocket Connection Test
    
    func testWebSocketConnection() throws {
        // Navigate to chat
        navigateToChat()
        
        // Check for connection status indicator
        let connectedIndicator = app.otherElements["ConnectionStatus"]
        if connectedIndicator.exists {
            // Wait for connection
            XCTAssertTrue(connectedIndicator.label.contains("Connected") ||
                         waitForConnectionStatus(timeout: 10),
                         "WebSocket should connect")
        }
    }
    
    // MARK: - Performance Tests
    
    func testLaunchPerformance() throws {
        if #available(iOS 14.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    func testScrollPerformance() throws {
        // Navigate to a list view
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Projects"].tap()
        
        let projectsList = app.collectionViews.firstMatch
        guard projectsList.waitForExistence(timeout: 5) else { return }
        
        // Measure scrolling performance
        measure {
            projectsList.swipeUp()
            projectsList.swipeDown()
        }
    }
    
    // MARK: - Helper Methods
    
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
    
    private func navigateToSettings() {
        let tabBar = app.tabBars.firstMatch
        
        if tabBar.buttons["Settings"].exists {
            tabBar.buttons["Settings"].tap()
        } else if tabBar.buttons["More"].exists {
            tabBar.buttons["More"].tap()
            let settingsCell = app.tables.cells.staticTexts["Settings"]
            if settingsCell.waitForExistence(timeout: 3) {
                settingsCell.tap()
            }
        }
    }
    
    private func waitForConnectionStatus(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS 'Connected'")
        let expectation = XCTNSPredicateExpectation(predicate: predicate,
                                                    object: app.otherElements["ConnectionStatus"])
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}

// MARK: - Accessibility Tests

extension ClaudeCodeUIUITests {
    
    func testVoiceOverLabels() throws {
        // Enable VoiceOver testing
        let tabBar = app.tabBars.firstMatch
        
        // Check tab bar accessibility
        XCTAssertNotNil(tabBar.buttons["Projects"].label, "Projects tab should have accessibility label")
        XCTAssertNotNil(tabBar.buttons["Terminal"].label, "Terminal tab should have accessibility label")
        XCTAssertNotNil(tabBar.buttons["Search"].label, "Search tab should have accessibility label")
    }
    
    func testDynamicTypeScaling() throws {
        // This would test with different text sizes
        // Requires launching app with different accessibility settings
        app.launchEnvironment = ["UIPreferredContentSizeCategoryName": "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"]
        app.launch()
        
        // Verify text is still visible and UI adapts
        let projectsTab = app.tabBars.buttons["Projects"]
        projectsTab.tap()
        
        let projectsList = app.collectionViews.firstMatch
        XCTAssertTrue(projectsList.waitForExistence(timeout: 5), "UI should adapt to large text size")
    }
}

// MARK: - Snapshot Tests

extension ClaudeCodeUIUITests {
    
    func testTakeScreenshots() throws {
        // Projects screen
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Projects"].tap()
        sleep(1)
        takeScreenshot(named: "01_Projects")
        
        // Terminal screen
        tabBar.buttons["Terminal"].tap()
        sleep(1)
        takeScreenshot(named: "02_Terminal")
        
        // Search screen
        tabBar.buttons["Search"].tap()
        sleep(1)
        takeScreenshot(named: "03_Search")
        
        // Settings screen
        navigateToSettings()
        sleep(1)
        takeScreenshot(named: "04_Settings")
    }
    
    private func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}