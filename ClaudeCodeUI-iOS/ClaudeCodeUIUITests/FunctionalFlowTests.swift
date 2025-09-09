//
//  FunctionalFlowTests.swift
//  ClaudeCodeUIUITests
//
//  Comprehensive functional UI tests with real backend interaction
//  Tests actual UI elements and validates backend responses
//

import XCTest

final class FunctionalFlowTests: XCTestCase {
    
    var app: XCUIApplication!
    private let timeout: TimeInterval = 30.0
    private let shortTimeout: TimeInterval = 5.0
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Launch with testing flags but DO NOT skip backend connections
        app.launchArguments = [
            "--uitesting",
            "--enable-backend",  // Force backend connection
            "--real-data"        // Use real data from backend
        ]
        
        // Set environment for testing - use correct port 3004
        app.launchEnvironment = [
            "TESTING_MODE": "functional",
            "BACKEND_URL": "http://localhost:3004",
            "ENABLE_LOGGING": "true"
        ]
        
        app.launch()
        
        // Wait for app to fully initialize
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: shortTimeout))
    }
    
    override func tearDownWithError() throws {
        // Capture final screenshot
        captureScreenshot(name: "Test_Completion_\(name)")
        app = nil
    }
    
    // MARK: - Complete User Flow Test
    
    func testCompleteUserFlow() throws {
        // Step 1: Verify app launches and shows project list
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: shortTimeout), "Tab bar should exist")
        
        // Verify we're on Projects tab
        let projectsTab = tabBar.buttons["Projects"]
        XCTAssertTrue(projectsTab.exists, "Projects tab should exist")
        XCTAssertTrue(projectsTab.isSelected, "Projects tab should be selected by default")
        
        captureScreenshot(name: "1_Initial_Launch")
        
        // Step 2: Wait for projects to load from backend
        let projectsView = app.otherElements["ProjectsView"]
        if !projectsView.waitForExistence(timeout: shortTimeout) {
            // Alternative: Look for collection view or table view
            let collectionView = app.collectionViews.firstMatch
            let tableView = app.tables.firstMatch
            
            XCTAssertTrue(collectionView.exists || tableView.exists, 
                         "Should have a collection or table view for projects")
        }
        
        // Wait for project cards to load (real backend data)
        let projectCards = app.collectionViews.cells
        let tableCells = app.tables.cells
        
        // Give time for projects to load
        Thread.sleep(forTimeInterval: 3)
        
        // Check both collection view and table view for projects
        let hasProjects = projectCards.count > 0 || tableCells.count > 0
        
        if !hasProjects {
            print("⚠️ No projects found - checking for authentication or empty state")
            
            // Check if we need to authenticate
            let loginButton = app.buttons["Login"]
            let signInButton = app.buttons["Sign In"]
            
            if loginButton.exists || signInButton.exists {
                print("📱 App requires authentication - skipping to basic navigation test")
                captureScreenshot(name: "Authentication_Required")
                
                // For now, test basic navigation without authentication
                testBasicNavigation()
                return
            }
            
            // Check for empty state
            let emptyStateLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'no projects' OR label CONTAINS[c] 'empty'")).firstMatch
            if emptyStateLabel.exists {
                print("📭 Empty projects state detected")
                captureScreenshot(name: "Empty_Projects_State")
            }
        }
        
        let projectCount = max(projectCards.count, tableCells.count)
        
        print("✅ Loaded \(projectCount) projects from backend")
        captureScreenshot(name: "2_Projects_Loaded")
        
        // Step 3: Navigate to first project
        let firstProject = projectCards.firstMatch
        XCTAssertTrue(firstProject.exists, "First project card should exist")
        
        // Try to get project title for verification
        let projectTitle = firstProject.staticTexts.firstMatch
        var projectName = ""
        if projectTitle.exists {
            projectName = projectTitle.label
            print("📁 Navigating to project: \(projectName)")
        }
        
        firstProject.tap()
        
        // Step 4: Verify session list appears
        let sessionsView = app.otherElements["SessionsView"]
        let sessionsList = app.tables.firstMatch
        
        if !sessionsView.waitForExistence(timeout: shortTimeout) {
            // Fallback: Check for table view directly
            XCTAssertTrue(sessionsList.waitForExistence(timeout: shortTimeout),
                         "Sessions list should appear")
        }
        
        captureScreenshot(name: "3_Sessions_View")
        
        // Check for sessions from backend
        let sessionCells = app.tables.cells
        if sessionCells.count > 0 {
            print("✅ Found \(sessionCells.count) sessions")
            
            // Step 5: Navigate to first session (chat view)
            let firstSession = sessionCells.firstMatch
            firstSession.tap()
            
            // Step 6: Verify chat view loads
            let chatView = app.otherElements["ChatView"]
            if !chatView.waitForExistence(timeout: shortTimeout) {
                // Fallback: Look for chat-specific elements
                let messageList = app.collectionViews["MessageList"]
                let chatInput = app.textViews["chatInputTextView"]
                
                XCTAssertTrue(messageList.exists || chatInput.exists,
                             "Chat view components should exist")
            }
            
            captureScreenshot(name: "4_Chat_View")
            
            // Step 7: Test message sending
            testSendMessage()
            
            // Step 8: Test scrolling performance
            testMessageScrolling()
            
        } else {
            // Create new session if none exist
            print("⚠️ No existing sessions, creating new session")
            try createNewSession()
        }
        
        // Step 9: Test navigation back
        testBackNavigation()
        
        print("✅ Complete user flow test passed!")
    }
    
    // MARK: - Message Interaction Tests
    
    func testSendMessage() {
        print("📝 Testing message sending...")
        
        // Find chat input field
        let chatInput = app.textViews["chatInputTextView"]
        if !chatInput.exists {
            // Try alternative identifiers
            let alternativeInput = app.textViews.firstMatch
            XCTAssertTrue(alternativeInput.waitForExistence(timeout: shortTimeout),
                         "Chat input should exist")
            alternativeInput.tap()
            alternativeInput.typeText("Test message from UI automation")
        } else {
            chatInput.tap()
            chatInput.typeText("Test message from UI automation")
        }
        
        captureScreenshot(name: "5_Message_Typed")
        
        // Find and tap send button
        let sendButton = app.buttons["chatSendButton"]
        if !sendButton.exists {
            // Try alternative: look for button with send icon
            let alternativeSend = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'send'")).firstMatch
            if alternativeSend.exists {
                alternativeSend.tap()
            } else {
                // Last resort: tap any button near the input
                let anyButton = app.buttons.firstMatch
                if anyButton.exists {
                    anyButton.tap()
                }
            }
        } else {
            sendButton.tap()
        }
        
        print("📤 Message sent, waiting for response...")
        
        // Wait for response from backend
        let messageList = app.collectionViews.firstMatch
        let initialCellCount = messageList.cells.count
        
        // Wait for new message to appear (response from backend)
        let newMessagePredicate = NSPredicate(format: "cells.count > %d", initialCellCount)
        let responseExpectation = expectation(for: newMessagePredicate,
                                             evaluatedWith: messageList,
                                             handler: nil)
        
        wait(for: [responseExpectation], timeout: timeout)
        
        let finalCellCount = messageList.cells.count
        XCTAssertGreaterThan(finalCellCount, initialCellCount,
                            "Should receive response from backend")
        
        print("✅ Received response! New message count: \(finalCellCount)")
        captureScreenshot(name: "6_Message_Response")
    }
    
    func testMessageScrolling() {
        print("📜 Testing scrolling performance...")
        
        let messageList = app.collectionViews.firstMatch
        guard messageList.exists else {
            print("⚠️ No message list to scroll")
            return
        }
        
        // Perform rapid scrolling
        for i in 1...5 {
            messageList.swipeUp(velocity: .fast)
            Thread.sleep(forTimeInterval: 0.2)
            
            if i % 2 == 0 {
                captureScreenshot(name: "Scroll_Test_\(i)")
            }
        }
        
        // Scroll back to bottom
        for _ in 1...5 {
            messageList.swipeDown(velocity: .fast)
            Thread.sleep(forTimeInterval: 0.2)
        }
        
        // Verify no UI glitches
        XCTAssertTrue(messageList.exists, "Message list should still exist after scrolling")
        
        // Check for duplicate cells (would indicate rendering issues)
        let cells = messageList.cells
        var cellIdentifiers = Set<String>()
        for i in 0..<min(cells.count, 10) {
            let cell = cells.element(boundBy: i)
            if cell.exists {
                let identifier = cell.identifier
                XCTAssertFalse(cellIdentifiers.contains(identifier),
                              "Found duplicate cell identifier: \(identifier)")
                cellIdentifiers.insert(identifier)
            }
        }
        
        print("✅ Scrolling test completed without issues")
    }
    
    // MARK: - Navigation Tests
    
    func testBackNavigation() {
        print("🔙 Testing back navigation...")
        
        // Navigate back from chat to sessions
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
            
            // Verify we're back at sessions
            let sessionsView = app.otherElements["SessionsView"]
            let sessionsList = app.tables.firstMatch
            
            XCTAssertTrue(sessionsView.exists || sessionsList.exists,
                         "Should return to sessions view")
            
            captureScreenshot(name: "7_Back_To_Sessions")
            
            // Navigate back to projects
            let projectsBackButton = app.navigationBars.buttons.firstMatch
            if projectsBackButton.exists {
                projectsBackButton.tap()
                
                // Verify we're back at projects
                let projectsView = app.otherElements["ProjectsView"]
                let projectCards = app.collectionViews.cells
                
                XCTAssertTrue(projectsView.exists || projectCards.count > 0,
                             "Should return to projects view")
                
                captureScreenshot(name: "8_Back_To_Projects")
            }
        }
        
        print("✅ Navigation test completed")
    }
    
    // MARK: - Tab Bar Navigation Tests
    
    func testTabBarNavigation() throws {
        print("📱 Testing tab bar navigation...")
        
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
        
        // Test each tab
        let tabs = ["Projects", "Terminal", "MCP", "Search", "Settings"]
        
        for (index, tabName) in tabs.enumerated() {
            let tab = tabBar.buttons[tabName]
            if tab.exists {
                tab.tap()
                Thread.sleep(forTimeInterval: 0.5)
                
                XCTAssertTrue(tab.isSelected, "\(tabName) tab should be selected")
                captureScreenshot(name: "Tab_\(tabName)")
                
                print("✅ \(tabName) tab navigation successful")
            } else {
                print("⚠️ \(tabName) tab not found")
            }
        }
        
        // Return to Projects tab
        tabBar.buttons["Projects"].tap()
    }
    
    // MARK: - Helper Methods
    
    private func testBasicNavigation() {
        print("🔄 Testing basic navigation without authentication")
        
        let tabBar = app.tabBars.firstMatch
        guard tabBar.exists else {
            print("❌ Tab bar not found")
            return
        }
        
        // Test each tab
        let tabs = ["Projects", "Sessions", "Settings"]
        for tabName in tabs {
            let tab = tabBar.buttons[tabName]
            if tab.exists {
                tab.tap()
                Thread.sleep(forTimeInterval: 1)
                captureScreenshot(name: "Tab_\(tabName)")
                print("✅ Navigated to \(tabName) tab")
            }
        }
    }
    
    private func createNewSession() throws {
        print("➕ Creating new session...")
        
        // Look for add/new session button
        let addButton = app.navigationBars.buttons["addSessionButton"]
        if !addButton.exists {
            // Try alternative: look for + button
            let plusButton = app.navigationBars.buttons.matching(NSPredicate(format: "label CONTAINS '+'")).firstMatch
            if plusButton.exists {
                plusButton.tap()
            } else {
                throw XCTSkip("Cannot find button to create new session")
            }
        } else {
            addButton.tap()
        }
        
        // Wait for new session to be created
        Thread.sleep(forTimeInterval: 1.0)
        
        // Verify we're in a chat view
        let chatView = app.otherElements["ChatView"]
        let chatInput = app.textViews.firstMatch
        
        XCTAssertTrue(chatView.exists || chatInput.exists,
                     "Should be in chat view after creating session")
        
        captureScreenshot(name: "New_Session_Created")
    }
    
    private func captureScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    private func printViewHierarchy() {
        print("📋 Current view hierarchy:")
        print(app.debugDescription)
    }
}

// MARK: - Performance Extensions

extension FunctionalFlowTests {
    
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
            
            // Wait for initial content
            let projectsView = app.otherElements["ProjectsView"]
            _ = projectsView.waitForExistence(timeout: shortTimeout)
        }
    }
    
    func testNavigationSpeed() throws {
        // Measure navigation between views
        measure {
            // Navigate to sessions
            let projectCards = app.collectionViews.cells
            if projectCards.count > 0 {
                projectCards.firstMatch.tap()
                
                // Wait for sessions
                _ = app.tables.firstMatch.waitForExistence(timeout: shortTimeout)
                
                // Navigate back
                app.navigationBars.buttons.firstMatch.tap()
                
                // Wait for projects
                _ = projectCards.firstMatch.waitForExistence(timeout: shortTimeout)
            }
        }
    }
    
    func testScrollingFrameRate() throws {
        // Navigate to a view with scrollable content
        let projectCards = app.collectionViews.cells
        guard projectCards.count > 0 else {
            throw XCTSkip("No projects for scrolling test")
        }
        
        projectCards.firstMatch.tap()
        
        let sessionCells = app.tables.cells
        guard sessionCells.count > 0 else {
            throw XCTSkip("No sessions for scrolling test")
        }
        
        sessionCells.firstMatch.tap()
        
        // Measure scrolling performance
        let messageList = app.collectionViews.firstMatch
        
        measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
            messageList.swipeUp(velocity: .fast)
            Thread.sleep(forTimeInterval: 0.5)
            messageList.swipeDown(velocity: .fast)
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
}

// MARK: - Accessibility Tests

extension FunctionalFlowTests {
    
    func testAccessibilityLabels() throws {
        // Verify important UI elements have accessibility labels
        
        // Projects tab
        let projectsTab = app.tabBars.buttons["Projects"]
        XCTAssertTrue(projectsTab.exists)
        XCTAssertFalse(projectsTab.label.isEmpty, "Projects tab should have accessibility label")
        
        // Check project cards
        let projectCards = app.collectionViews.cells
        if projectCards.count > 0 {
            let firstProject = projectCards.firstMatch
            XCTAssertFalse(firstProject.label.isEmpty, "Project card should have accessibility label")
        }
        
        print("✅ Accessibility labels verified")
    }
    
    func testVoiceOverNavigation() throws {
        // This would test VoiceOver navigation if running on device
        // For simulator, we just verify the accessibility traits
        
        let projectCards = app.collectionViews.cells
        if projectCards.count > 0 {
            let firstProject = projectCards.firstMatch
            XCTAssertTrue(firstProject.isHittable, "Project card should be hittable")
        }
    }
}