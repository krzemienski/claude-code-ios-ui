import XCTest

class MessageInteractionTests: XCTestCase {
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
    
    // MARK: - Message Sending Tests
    
    func testSendMessage() {
        // Navigate to chat
        navigateToFirstProject()
        
        // Find message input field
        let messageInput = findMessageInput()
        XCTAssertNotNil(messageInput, "Message input field should exist")
        
        guard let input = messageInput else { return }
        
        // Count initial messages
        let messageList = findMessageList()
        let initialMessageCount = messageList?.cells.count ?? 0
        
        // Type and send message
        input.tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        let testMessage = "Test message from UI automation at \(Date())"
        input.typeText(testMessage)
        
        // Find and tap send button
        let sendButton = findSendButton()
        XCTAssertNotNil(sendButton, "Send button should exist")
        sendButton?.tap()
        
        // Wait for message to appear
        Thread.sleep(forTimeInterval: 2)
        
        // Verify message was added
        if let list = messageList {
            let newMessageCount = list.cells.count
            XCTAssertGreaterThan(newMessageCount, initialMessageCount, "New message should be added")
            
            // Look for our sent message
            let lastMessage = list.cells.element(boundBy: newMessageCount - 1)
            if lastMessage.exists {
                let messageText = lastMessage.staticTexts.firstMatch
                if messageText.exists {
                    print("Sent message visible: \(messageText.label.contains("Test message"))")
                }
            }
        }
        
        captureScreenshot(name: "Message_Sent")
    }
    
    func testStreamingResponse() {
        // Navigate and send a message
        navigateToFirstProject()
        
        let messageInput = findMessageInput()
        guard let input = messageInput else {
            XCTFail("No message input found")
            return
        }
        
        // Send a question that should trigger a response
        input.tap()
        input.typeText("Hello, can you help me with Swift?")
        
        findSendButton()?.tap()
        
        // Wait for streaming response
        let messageList = findMessageList()
        guard let list = messageList else {
            XCTFail("No message list found")
            return
        }
        
        // Create expectation for response
        let responseExpectation = XCTestExpectation(description: "Waiting for AI response")
        
        // Monitor for new messages
        var checkCount = 0
        let maxChecks = 30 // 30 seconds max
        let initialCount = list.cells.count
        
        while checkCount < maxChecks {
            Thread.sleep(forTimeInterval: 1)
            
            let currentCount = list.cells.count
            if currentCount > initialCount {
                // Check if last message is from assistant
                let lastMessage = list.cells.element(boundBy: currentCount - 1)
                if lastMessage.exists {
                    // Look for streaming indicator or assistant message
                    let hasStreamingIndicator = lastMessage.activityIndicators.count > 0
                    let hasText = lastMessage.staticTexts.count > 0
                    
                    if hasStreamingIndicator {
                        print("Streaming response detected")
                        responseExpectation.fulfill()
                        break
                    } else if hasText && currentCount > initialCount + 1 {
                        print("Assistant response received")
                        responseExpectation.fulfill()
                        break
                    }
                }
            }
            
            checkCount += 1
        }
        
        wait(for: [responseExpectation], timeout: 35)
        captureScreenshot(name: "Streaming_Response")
    }
    
    func testMessageInputValidation() {
        navigateToFirstProject()
        
        let messageInput = findMessageInput()
        guard let input = messageInput else {
            XCTFail("No message input found")
            return
        }
        
        let sendButton = findSendButton()
        
        // Test empty message
        input.tap()
        input.typeText("")
        sendButton?.tap()
        
        // Should not send empty message
        Thread.sleep(forTimeInterval: 1)
        
        // Test whitespace only
        input.tap()
        input.typeText("   ")
        sendButton?.tap()
        
        Thread.sleep(forTimeInterval: 1)
        
        // Test very long message
        input.tap()
        let longMessage = String(repeating: "Test ", count: 200)
        input.typeText(longMessage)
        
        // Should handle long message appropriately
        sendButton?.tap()
        
        Thread.sleep(forTimeInterval: 2)
        captureScreenshot(name: "Message_Validation")
    }
    
    func testMessageListScrolling() {
        navigateToFirstProject()
        
        let messageList = findMessageList()
        guard let list = messageList else {
            XCTFail("No message list found")
            return
        }
        
        // Send multiple messages to ensure scrollable content
        let messageInput = findMessageInput()
        let sendButton = findSendButton()
        
        for i in 1...5 {
            messageInput?.tap()
            messageInput?.typeText("Test message #\(i)")
            sendButton?.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        Thread.sleep(forTimeInterval: 2)
        
        // Test scrolling
        list.swipeUp()
        Thread.sleep(forTimeInterval: 0.5)
        list.swipeUp()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Scroll back down
        list.swipeDown()
        Thread.sleep(forTimeInterval: 0.5)
        list.swipeDown()
        
        captureScreenshot(name: "Message_List_Scrolled")
    }
    
    // MARK: - High Volume Tests
    
    func testHighVolumeScrolling() {
        navigateToFirstProject()
        
        let messageList = findMessageList()
        guard let list = messageList else {
            XCTFail("No message list found")
            return
        }
        
        // Rapid scroll test
        for i in 0..<10 {
            list.swipeUp(velocity: .fast)
            if i % 3 == 0 {
                captureScreenshot(name: "Rapid_Scroll_Up_\(i)")
            }
        }
        
        Thread.sleep(forTimeInterval: 1)
        
        for i in 0..<10 {
            list.swipeDown(velocity: .fast)
            if i % 3 == 0 {
                captureScreenshot(name: "Rapid_Scroll_Down_\(i)")
            }
        }
        
        // Check for duplicate messages
        let visibleCells = list.cells.allElementsBoundByIndex
        var messageIdentifiers = Set<String>()
        
        for cell in visibleCells where cell.exists {
            // Create unique identifier from cell content
            let texts = cell.staticTexts.allElementsBoundByIndex
            var cellIdentifier = ""
            
            for text in texts where text.exists {
                cellIdentifier += text.label
            }
            
            if !cellIdentifier.isEmpty {
                XCTAssertFalse(messageIdentifiers.contains(cellIdentifier), 
                              "Duplicate message found: \(cellIdentifier.prefix(50))")
                messageIdentifiers.insert(cellIdentifier)
            }
        }
        
        print("Verified \(messageIdentifiers.count) unique messages after rapid scrolling")
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
        // Try specific identifier
        var messageList = app.collectionViews["messageList"]
        if messageList.exists {
            return messageList
        }
        
        // Try any collection view
        messageList = app.collectionViews.firstMatch
        if messageList.exists {
            return messageList
        }
        
        // Try scroll view with messages
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            return scrollView
        }
        
        return nil
    }
    
    private func findMessageInput() -> XCUIElement? {
        // Try specific identifier
        var input = app.textFields["messageInput"]
        if input.exists {
            return input
        }
        
        // Try text view
        input = app.textViews["messageInput"]
        if input.exists {
            return input
        }
        
        // Try any text field
        input = app.textFields.firstMatch
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
        
        // Try paper plane icon
        button = app.buttons.matching(identifier: "paperplane").firstMatch
        if button.exists {
            return button
        }
        
        // Try arrow up icon
        button = app.buttons.matching(identifier: "arrow.up").firstMatch
        if button.exists {
            return button
        }
        
        // Last resort: any button near the input field
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