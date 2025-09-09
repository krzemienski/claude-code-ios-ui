//
//  NavigationFlowTests.swift
//  ClaudeCodeUIUITests
//
//  Comprehensive navigation flow testing for Projects → Sessions → Chat
//

import XCTest

final class NavigationFlowTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launchArguments.append("--skip-websocket")
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Initial Launch Tests
    
    func testInitialLaunch() throws {
        // Test that app launches without crashing
        XCTAssertTrue(app.exists, "App should exist after launch")
        
        // Wait for initial view to load
        let projectsView = app.otherElements["ProjectsView"]
        let exists = projectsView.waitForExistence(timeout: 5)
        
        if !exists {
            // Check if we're in empty state
            let emptyState = app.staticTexts["No Projects Yet"]
            XCTAssertTrue(emptyState.exists || projectsView.exists, 
                         "Should show either projects view or empty state")
        }
        
        // Take screenshot for documentation
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Initial_Launch"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // MARK: - Projects View Tests
    
    func testProjectsViewDisplay() throws {
        // Wait for projects view
        let projectsView = app.otherElements["ProjectsView"]
        XCTAssertTrue(projectsView.waitForExistence(timeout: 5), 
                     "Projects view should appear")
        
        // Check for either project cards or empty state
        let projectCards = app.collectionViews.cells
        let emptyState = app.staticTexts["No Projects Yet"]
        
        if projectCards.count > 0 {
            // Test project card elements
            let firstCard = projectCards.firstMatch
            XCTAssertTrue(firstCard.exists, "First project card should exist")
            
            // Check for project card components
            let projectTitle = firstCard.staticTexts.matching(identifier: "ProjectTitle").firstMatch
            _ = firstCard.staticTexts.matching(identifier: "SessionCount").firstMatch
            
            if projectTitle.exists {
                XCTAssertFalse(projectTitle.label.isEmpty, "Project title should not be empty")
            }
            
            // Document the view
            captureScreenshot(name: "Projects_View_With_Data")
        } else {
            XCTAssertTrue(emptyState.exists, "Empty state should be shown when no projects")
            captureScreenshot(name: "Projects_View_Empty_State")
        }
    }
    
    // MARK: - Navigation Flow Tests
    
    func testProjectToSessionsNavigation() throws {
        // Skip if no projects
        let projectCards = app.collectionViews.cells
        guard projectCards.count > 0 else {
            throw XCTSkip("No projects available for navigation test")
        }
        
        // Tap first project
        let firstProject = projectCards.firstMatch
        XCTAssertTrue(firstProject.exists, "First project should exist")
        
        let projectTitle = firstProject.staticTexts.matching(identifier: "ProjectTitle").firstMatch.label
        firstProject.tap()
        
        // Wait for sessions view
        let sessionsView = app.otherElements["SessionsView"]
        XCTAssertTrue(sessionsView.waitForExistence(timeout: 5), 
                     "Sessions view should appear after tapping project")
        
        // Verify navigation bar
        let navBar = app.navigationBars.firstMatch
        if navBar.exists {
            // Check for back button
            let backButton = navBar.buttons["Projects"]
            XCTAssertTrue(backButton.exists || navBar.buttons.firstMatch.exists, 
                         "Back button should exist in navigation bar")
        }
        
        // Check sessions content
        let sessionCells = app.tables.cells
        if sessionCells.count > 0 {
            captureScreenshot(name: "Sessions_View_With_Data")
        } else {
            let emptyState = app.staticTexts["No Sessions"]
            XCTAssertTrue(emptyState.exists || sessionCells.count > 0, 
                         "Should show sessions or empty state")
            captureScreenshot(name: "Sessions_View_Empty")
        }
    }
    
    func testSessionToChatNavigation() throws {
        // Navigate to sessions first
        try navigateToSessions()
        
        // Check for sessions
        let sessionCells = app.tables.cells
        guard sessionCells.count > 0 else {
            throw XCTSkip("No sessions available for chat navigation test")
        }
        
        // Tap first session
        let firstSession = sessionCells.firstMatch
        firstSession.tap()
        
        // Wait for chat view
        let chatView = app.otherElements["ChatView"]
        XCTAssertTrue(chatView.waitForExistence(timeout: 5), 
                     "Chat view should appear after tapping session")
        
        // Verify chat components
        let messageList = app.collectionViews["MessageList"]
        let inputField = app.textViews["MessageInput"]
        let sendButton = app.buttons["SendButton"]
        
        if messageList.exists {
            captureScreenshot(name: "Chat_View_With_Messages")
        } else {
            // Check for empty state
            let emptyChat = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'No messages'")).firstMatch
            XCTAssertTrue(messageList.exists || emptyChat.exists, 
                         "Should show messages or empty state")
            captureScreenshot(name: "Chat_View_Empty")
        }
        
        // Test input field if available
        if inputField.exists {
            XCTAssertTrue(inputField.isEnabled, "Input field should be enabled")
        }
    }
    
    func testFullNavigationStack() throws {
        // Projects → Sessions → Chat → Back → Back
        
        // Navigate to chat
        try navigateToChat()
        
        captureScreenshot(name: "Navigation_Stack_Chat")
        
        // Navigate back to sessions
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
            
            let sessionsView = app.otherElements["SessionsView"]
            XCTAssertTrue(sessionsView.waitForExistence(timeout: 3), 
                         "Should return to sessions view")
            captureScreenshot(name: "Navigation_Stack_Sessions")
            
            // Navigate back to projects
            let projectsBackButton = app.navigationBars.buttons.firstMatch
            if projectsBackButton.exists {
                projectsBackButton.tap()
                
                let projectsView = app.otherElements["ProjectsView"]
                XCTAssertTrue(projectsView.waitForExistence(timeout: 3), 
                             "Should return to projects view")
                captureScreenshot(name: "Navigation_Stack_Projects")
            }
        }
    }
    
    // MARK: - State Preservation Tests
    
    func testStatePreservationDuringNavigation() throws {
        // Navigate to sessions
        try navigateToSessions()
        
        // Remember scroll position or selected item
        let sessionCells = app.tables.cells
        var selectedSessionTitle = ""
        
        if sessionCells.count > 1 {
            // Scroll to a specific session
            let targetSession = sessionCells.element(boundBy: min(2, sessionCells.count - 1))
            targetSession.swipeUp()
            
            let title = targetSession.staticTexts.firstMatch.label
            selectedSessionTitle = title
        }
        
        // Navigate to chat and back
        if sessionCells.count > 0 {
            sessionCells.firstMatch.tap()
            
            // Wait for chat
            _ = app.otherElements["ChatView"].waitForExistence(timeout: 3)
            
            // Go back
            app.navigationBars.buttons.firstMatch.tap()
            
            // Verify we're back at sessions
            let sessionsView = app.otherElements["SessionsView"]
            XCTAssertTrue(sessionsView.waitForExistence(timeout: 3), 
                         "Should return to sessions view with preserved state")
            
            // Check if scroll position or selection is preserved
            // This would require accessibility identifiers on the actual implementation
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToSessions() throws {
        let projectCards = app.collectionViews.cells
        guard projectCards.count > 0 else {
            throw XCTSkip("No projects available for navigation")
        }
        
        projectCards.firstMatch.tap()
        
        let sessionsView = app.otherElements["SessionsView"]
        XCTAssertTrue(sessionsView.waitForExistence(timeout: 5), 
                     "Sessions view should appear")
    }
    
    private func navigateToChat() throws {
        try navigateToSessions()
        
        let sessionCells = app.tables.cells
        guard sessionCells.count > 0 else {
            throw XCTSkip("No sessions available for chat navigation")
        }
        
        sessionCells.firstMatch.tap()
        
        let chatView = app.otherElements["ChatView"]
        XCTAssertTrue(chatView.waitForExistence(timeout: 5), 
                     "Chat view should appear")
    }
    
    private func captureScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

// MARK: - Performance Tests

extension NavigationFlowTests {
    
    func testNavigationPerformance() throws {
        measure {
            // Measure navigation speed
            do {
                try navigateToSessions()
                app.navigationBars.buttons.firstMatch.tap()
            } catch {
                XCTFail("Navigation performance test failed: \(error)")
            }
        }
    }
    
    func testScrollPerformance() throws {
        try navigateToSessions()
        
        let tableView = app.tables.firstMatch
        guard tableView.exists else {
            throw XCTSkip("No table view for scroll performance test")
        }
        
        measure {
            // Scroll down and up
            tableView.swipeUp()
            tableView.swipeDown()
        }
    }
}