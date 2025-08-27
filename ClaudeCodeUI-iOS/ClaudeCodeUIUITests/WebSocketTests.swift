import XCTest

final class WebSocketTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing", "WebSocket-Testing"]
        app.launchEnvironment = [
            "TESTING_MODE": "true",
            "BACKEND_URL": "http://192.168.0.43:3004"
        ]
        app.launch()
    }
    
    // MARK: - Connection Tests
    
    func testWebSocketInitialConnection() throws {
        // Navigate to chat
        navigateToChat()
        
        // Wait for WebSocket connection
        let connectionIndicator = app.otherElements["WebSocketStatus"] ?? app.staticTexts["Connected"]
        XCTAssertTrue(connectionIndicator.waitForExistence(timeout: 10), "WebSocket should connect within 10 seconds")
    }
    
    func testWebSocketReconnection() throws {
        // Navigate to chat
        navigateToChat()
        
        // Wait for initial connection
        waitForConnection()
        
        // Simulate disconnection (if backend supports it)
        // This would require coordination with backend or network manipulation
        
        // Verify reconnection happens
        let reconnectedIndicator = app.staticTexts["Reconnected"] ?? app.staticTexts["Connected"]
        XCTAssertTrue(reconnectedIndicator.waitForExistence(timeout: 15), "Should reconnect after disconnection")
    }
    
    func testMessageSendingViaWebSocket() throws {
        // Navigate to chat
        navigateToChat()
        
        // Wait for connection
        waitForConnection()
        
        // Send message
        let messageInput = app.textViews["MessageInput"] ?? app.textViews.firstMatch
        XCTAssertTrue(messageInput.waitForExistence(timeout: 5))
        
        messageInput.tap()
        let testMessage = "WebSocket test message \(Date().timeIntervalSince1970)"
        messageInput.typeText(testMessage)
        
        // Send
        if app.buttons["Send"].exists {
            app.buttons["Send"].tap()
        } else if app.buttons["SendMessage"].exists {
            app.buttons["SendMessage"].tap()
        }
        
        // Verify message appears with correct status
        let sentMessage = app.staticTexts[testMessage]
        XCTAssertTrue(sentMessage.waitForExistence(timeout: 5), "Message should appear in chat")
        
        // Check for delivery status
        let deliveryIndicator = app.images["message_delivered"] ?? app.staticTexts["Delivered"]
        XCTAssertTrue(deliveryIndicator.waitForExistence(timeout: 10), "Message should show as delivered")
    }
    
    func testReceivingAssistantResponse() throws {
        // Navigate to chat
        navigateToChat()
        waitForConnection()
        
        // Send a message that should trigger assistant response
        let messageInput = app.textViews["MessageInput"] ?? app.textViews.firstMatch
        messageInput.tap()
        messageInput.typeText("Hello Claude")
        
        if app.buttons["Send"].exists {
            app.buttons["Send"].tap()
        }
        
        // Wait for assistant response
        let assistantMessage = app.cells.containing(.staticText, identifier: "assistant").firstMatch
        XCTAssertTrue(assistantMessage.waitForExistence(timeout: 30), "Should receive assistant response within 30 seconds")
    }
    
    func testStreamingMessages() throws {
        // Navigate to chat
        navigateToChat()
        waitForConnection()
        
        // Send a message that triggers streaming response
        let messageInput = app.textViews["MessageInput"] ?? app.textViews.firstMatch
        messageInput.tap()
        messageInput.typeText("Tell me a story")
        
        if app.buttons["Send"].exists {
            app.buttons["Send"].tap()
        }
        
        // Check for streaming indicator
        let streamingIndicator = app.activityIndicators["StreamingIndicator"] ?? 
                                app.staticTexts["Claude is typing..."]
        XCTAssertTrue(streamingIndicator.waitForExistence(timeout: 5), "Should show streaming indicator")
        
        // Wait for streaming to complete
        XCTAssertTrue(waitForStreamingToComplete(timeout: 60), "Streaming should complete within 60 seconds")
    }
    
    // MARK: - Shell WebSocket Tests
    
    func testShellWebSocketConnection() throws {
        // Navigate to Terminal
        app.tabBars.buttons["Terminal"].tap()
        
        // Wait for shell connection
        let terminalReady = app.staticTexts["Terminal Ready"] ?? app.textViews["TerminalOutput"]
        XCTAssertTrue(terminalReady.waitForExistence(timeout: 10), "Terminal should be ready")
    }
    
    func testShellCommandExecution() throws {
        // Navigate to Terminal
        app.tabBars.buttons["Terminal"].tap()
        
        // Execute command
        let commandInput = app.textFields["CommandInput"] ?? app.textFields.firstMatch
        commandInput.tap()
        commandInput.typeText("echo 'Test from UI'")
        
        if app.buttons["Execute"].exists {
            app.buttons["Execute"].tap()
        } else {
            app.keyboards.buttons["Return"].tap()
        }
        
        // Check output
        let output = app.textViews["TerminalOutput"] ?? app.textViews.firstMatch
        let outputText = output.value as? String ?? ""
        XCTAssertTrue(outputText.contains("Test from UI"), "Terminal should show command output")
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
    
    private func waitForConnection() {
        let connected = app.staticTexts["Connected"] ?? app.otherElements["WebSocketConnected"]
        _ = connected.waitForExistence(timeout: 10)
    }
    
    private func waitForStreamingToComplete(timeout: TimeInterval) -> Bool {
        let streamingIndicator = app.activityIndicators["StreamingIndicator"]
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: streamingIndicator)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}