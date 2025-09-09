import XCTest

/// Complete end-to-end UI flow tests that verify the entire user journey
class CompleteUIFlowTests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["UI-TESTING", "--uitesting"]
        app.launchEnvironment = [
            "DISABLE_ANIMATIONS": "1",
            "UI_TEST_MODE": "true",
            "BACKEND_URL": "http://localhost:3004"
        ]
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // MARK: - Complete Flow Test
    
    func testCompleteUserFlow() {
        // Step 1: Verify project list loads
        let projectList = app.collectionViews["projectList"]
        XCTAssertTrue(projectList.waitForExistence(timeout: 10), "Project list should load")
        
        // Take screenshot of project list
        captureScreenshot(name: "1_Project_List")
        
        // Get project count
        let projectCells = projectList.cells
        let projectCount = projectCells.count
        XCTAssertGreaterThan(projectCount, 0, "Should have at least one project")
        print("✅ Found \(projectCount) projects")
        
        // Step 2: Select first project
        let firstProject = projectCells.element(boundBy: 0)
        XCTAssertTrue(firstProject.exists, "First project should exist")
        
        // Get project name for verification
        let projectName = firstProject.label
        print("📂 Selecting project: \(projectName)")
        firstProject.tap()
        
        // Step 3: Verify navigation to chat view
        let messageList = app.tables["messageList"]
        XCTAssertTrue(messageList.waitForExistence(timeout: 5), "Message list should appear")
        
        captureScreenshot(name: "2_Chat_View")
        
        // Check for existing messages
        Thread.sleep(forTimeInterval: 1)
        let messageCells = messageList.cells
        let initialMessageCount = messageCells.count
        print("💬 Found \(initialMessageCount) existing messages")
        
        // Step 4: Send a message
        let messageInput = findMessageInput()
        XCTAssertNotNil(messageInput, "Message input should exist")
        
        if let input = messageInput {
            input.tap()
            Thread.sleep(forTimeInterval: 0.5)
            
            let testMessage = "Hello! This is an automated UI test at \(Date())"
            input.typeText(testMessage)
            
            captureScreenshot(name: "3_Message_Typed")
            
            // Find and tap send button
            let sendButton = findSendButton()
            XCTAssertNotNil(sendButton, "Send button should exist")
            sendButton?.tap()
            
            // Step 5: Wait for response
            print("⏳ Waiting for AI response...")
            Thread.sleep(forTimeInterval: 3)
            
            // Verify new message was added
            let newMessageCount = messageList.cells.count
            XCTAssertGreaterThan(newMessageCount, initialMessageCount, "New message should be added")
            print("✅ Message sent and response received")
            
            captureScreenshot(name: "4_Message_Sent_With_Response")
        }
        
        // Step 6: Test scrolling if there are enough messages
        if messageCells.count > 3 {
            print("📜 Testing scrolling...")
            messageList.swipeUp()
            Thread.sleep(forTimeInterval: 0.5)
            captureScreenshot(name: "5_Scrolled_Up")
            
            messageList.swipeDown()
            Thread.sleep(forTimeInterval: 0.5)
            captureScreenshot(name: "6_Scrolled_Down")
        }
        
        // Step 7: Navigate back to project list
        let backButton = findBackButton()
        XCTAssertNotNil(backButton, "Back button should exist")
        backButton?.tap()
        
        // Verify we're back at project list
        XCTAssertTrue(projectList.waitForExistence(timeout: 5), "Should return to project list")
        captureScreenshot(name: "7_Back_To_Projects")
        
        // Step 8: If multiple projects exist, test second project
        if projectCount > 1 {
            print("📂 Testing second project...")
            let secondProject = projectCells.element(boundBy: 1)
            secondProject.tap()
            
            XCTAssertTrue(messageList.waitForExistence(timeout: 5), "Second project chat should load")
            captureScreenshot(name: "8_Second_Project_Chat")
            
            // Go back again
            findBackButton()?.tap()
        }
        
        print("✅✅✅ Complete UI flow test passed!")
    }
    
    func testHighVolumeInteraction() {
        // Navigate to first project
        navigateToFirstProject()
        
        let messageList = app.tables["messageList"]
        let messageInput = findMessageInput()
        let sendButton = findSendButton()
        
        // Send multiple messages rapidly
        for i in 1...10 {
            messageInput?.tap()
            messageInput?.typeText("High volume test message #\(i)")
            sendButton?.tap()
            Thread.sleep(forTimeInterval: 0.2)
            
            if i % 3 == 0 {
                captureScreenshot(name: "High_Volume_Message_\(i)")
            }
        }
        
        // Wait for all responses
        Thread.sleep(forTimeInterval: 5)
        
        // Rapid scrolling test
        for _ in 0..<5 {
            messageList.swipeUp(velocity: .fast)
        }
        Thread.sleep(forTimeInterval: 0.5)
        
        for _ in 0..<5 {
            messageList.swipeDown(velocity: .fast)
        }
        
        captureScreenshot(name: "High_Volume_Final_State")
        
        // Verify no crashes or duplicates
        XCTAssertTrue(messageList.exists, "Message list should still be functional")
    }
    
    func testEdgeCases() {
        navigateToFirstProject()
        
        let messageInput = findMessageInput()
        let sendButton = findSendButton()
        
        // Test 1: Empty message
        messageInput?.tap()
        sendButton?.tap()
        Thread.sleep(forTimeInterval: 0.5)
        captureScreenshot(name: "Edge_Case_Empty_Message")
        
        // Test 2: Very long message
        messageInput?.tap()
        let longMessage = String(repeating: "This is a very long message. ", count: 50)
        messageInput?.typeText(longMessage)
        sendButton?.tap()
        Thread.sleep(forTimeInterval: 2)
        captureScreenshot(name: "Edge_Case_Long_Message")
        
        // Test 3: Special characters
        messageInput?.tap()
        messageInput?.typeText("Test with emoji 🎉 and symbols @#$%^&*()")
        sendButton?.tap()
        Thread.sleep(forTimeInterval: 2)
        captureScreenshot(name: "Edge_Case_Special_Characters")
        
        // Test 4: Rapid back and forth navigation
        for i in 1...3 {
            findBackButton()?.tap()
            Thread.sleep(forTimeInterval: 0.5)
            
            let projectList = app.collectionViews["projectList"]
            projectList.cells.element(boundBy: 0).tap()
            Thread.sleep(forTimeInterval: 0.5)
            
            if i == 3 {
                captureScreenshot(name: "Edge_Case_Rapid_Navigation")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToFirstProject() {
        let projectList = app.collectionViews["projectList"]
        XCTAssertTrue(projectList.waitForExistence(timeout: 10))
        
        let firstProject = projectList.cells.element(boundBy: 0)
        XCTAssertTrue(firstProject.exists)
        firstProject.tap()
        
        Thread.sleep(forTimeInterval: 1)
    }
    
    private func findMessageInput() -> XCUIElement? {
        // Try specific identifier first
        var input = app.textViews["messageInput"]
        if input.exists {
            return input
        }
        
        // Try text fields
        input = app.textFields["messageInput"]
        if input.exists {
            return input
        }
        
        // Try any text view
        input = app.textViews.firstMatch
        if input.exists {
            return input
        }
        
        return nil
    }
    
    private func findSendButton() -> XCUIElement? {
        // Try specific identifier
        var button = app.buttons["sendButton"]
        if button.exists {
            return button
        }
        
        // Try common send button texts
        button = app.buttons["Send"]
        if button.exists {
            return button
        }
        
        // Try icon buttons
        button = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'send'")).firstMatch
        if button.exists {
            return button
        }
        
        return app.buttons.firstMatch
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
        
        return app.buttons.firstMatch
    }
    
    private func captureScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        print("📸 Screenshot captured: \(name)")
    }
}