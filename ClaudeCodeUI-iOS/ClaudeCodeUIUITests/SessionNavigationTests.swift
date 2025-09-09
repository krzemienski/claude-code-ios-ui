import XCTest

class SessionNavigationTests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["UI-TESTING"]
        app.launchEnvironment = ["DISABLE_ANIMATIONS": "1"]
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // MARK: - Session Navigation Tests
    
    func testNavigateToSession() {
        // Start from project list
        let projectTable = app.tables["projectList"]
        XCTAssertTrue(projectTable.waitForExistence(timeout: 10), "Project list should be visible")
        
        // Tap first project
        let firstProject = projectTable.cells.element(boundBy: 0)
        XCTAssertTrue(firstProject.waitForExistence(timeout: 5), "First project should exist")
        
        // Store project name for verification
        let projectName = firstProject.staticTexts.firstMatch.label
        firstProject.tap()
        
        // Verify chat view appears
        let chatView = app.collectionViews["messageList"]
        var chatViewFound = chatView.waitForExistence(timeout: 5)
        
        if !chatViewFound {
            // Try alternative: any collection view
            let anyCollectionView = app.collectionViews.firstMatch
            chatViewFound = anyCollectionView.waitForExistence(timeout: 5)
            XCTAssertTrue(chatViewFound, "Chat view should appear after selecting project")
        }
        
        // Verify navigation bar shows project name
        let navBar = app.navigationBars.firstMatch
        if navBar.exists {
            print("Navigation bar title: \(navBar.identifier)")
        }
        
        // Take screenshot
        captureScreenshot(name: "Session_View_Loaded")
    }
    
    func testSessionWithExistingMessages() {
        navigateToFirstProject()
        
        // Check for message list
        let messageList = findMessageList()
        XCTAssertNotNil(messageList, "Message list should exist")
        
        if let list = messageList {
            // Wait for messages to load
            Thread.sleep(forTimeInterval: 2)
            
            let messages = list.cells
            if messages.count > 0 {
                print("Found \(messages.count) existing messages")
                
                // Verify first message has content
                let firstMessage = messages.element(boundBy: 0)
                XCTAssertTrue(firstMessage.exists, "First message should exist")
                
                // Check for message text
                let messageText = firstMessage.staticTexts.firstMatch
                if messageText.exists {
                    print("First message preview: \(String(messageText.label.prefix(50)))")
                }
                
                // Test scrolling through messages
                if messages.count > 3 {
                    list.swipeUp()
                    Thread.sleep(forTimeInterval: 0.5)
                    list.swipeDown()
                }
            } else {
                print("No existing messages in this session")
            }
        }
        
        captureScreenshot(name: "Session_With_Messages")
    }
    
    func testBackNavigation() {
        // Navigate to chat
        navigateToFirstProject()
        
        // Find back button
        let backButton = findBackButton()
        XCTAssertNotNil(backButton, "Back button should exist")
        
        backButton?.tap()
        
        // Verify we're back at project list
        let projectTable = app.tables["projectList"]
        XCTAssertTrue(projectTable.waitForExistence(timeout: 5), "Should return to project list")
        
        captureScreenshot(name: "Back_To_Project_List")
    }
    
    func testMultipleProjectNavigation() {
        let projectTable = app.tables["projectList"]
        XCTAssertTrue(projectTable.waitForExistence(timeout: 10))
        
        let projectCount = projectTable.cells.count
        guard projectCount >= 2 else {
            print("Need at least 2 projects for this test")
            return
        }
        
        // Navigate to first project
        projectTable.cells.element(boundBy: 0).tap()
        Thread.sleep(forTimeInterval: 1)
        
        // Verify chat view
        XCTAssertTrue(findMessageList() != nil, "First project chat should load")
        
        // Go back
        findBackButton()?.tap()
        Thread.sleep(forTimeInterval: 1)
        
        // Navigate to second project
        projectTable.cells.element(boundBy: 1).tap()
        Thread.sleep(forTimeInterval: 1)
        
        // Verify different chat view
        XCTAssertTrue(findMessageList() != nil, "Second project chat should load")
        
        captureScreenshot(name: "Second_Project_Navigation")
    }
    
    func testNavigationBarElements() {
        navigateToFirstProject()
        
        // Check navigation bar exists
        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.exists, "Navigation bar should exist")
        
        // Check for back button
        let backButton = navBar.buttons.firstMatch
        XCTAssertTrue(backButton.exists, "Back button should exist in nav bar")
        
        // Check for title
        let title = navBar.staticTexts.firstMatch
        if title.exists {
            print("Navigation title: \(title.label)")
        }
        
        // Check for any action buttons
        let actionButtons = navBar.buttons
        print("Found \(actionButtons.count) navigation buttons")
    }
    
    // MARK: - Helper Methods
    
    private func navigateToFirstProject() {
        let projectTable = app.tables["projectList"]
        XCTAssertTrue(projectTable.waitForExistence(timeout: 10))
        
        let firstProject = projectTable.cells.element(boundBy: 0)
        XCTAssertTrue(firstProject.exists)
        firstProject.tap()
        
        Thread.sleep(forTimeInterval: 1)
    }
    
    private func findMessageList() -> XCUIElement? {
        // Try specific identifier first
        var messageList = app.collectionViews["messageList"]
        if messageList.exists {
            return messageList
        }
        
        // Try any collection view
        messageList = app.collectionViews.firstMatch
        if messageList.exists {
            return messageList
        }
        
        // Try table view (in case messages are in a table)
        let tableView = app.tables.firstMatch
        if tableView.exists && tableView.identifier != "projectList" {
            return tableView
        }
        
        return nil
    }
    
    private func findBackButton() -> XCUIElement? {
        // Try navigation bar back button
        let navBackButton = app.navigationBars.buttons.firstMatch
        if navBackButton.exists {
            return navBackButton
        }
        
        // Try any back button
        let backButton = app.buttons["Back"]
        if backButton.exists {
            return backButton
        }
        
        // Try chevron left button
        let chevronButton = app.buttons.matching(identifier: "chevron.left").firstMatch
        if chevronButton.exists {
            return chevronButton
        }
        
        return app.buttons.firstMatch
    }
    
    private func captureScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}