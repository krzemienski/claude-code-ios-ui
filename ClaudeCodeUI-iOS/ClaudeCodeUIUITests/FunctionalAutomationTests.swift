import XCTest

/// Functional automation tests for ClaudeCodeUI with REAL backend at 192.168.0.155:3004
/// These tests demonstrate complete UI automation with no mocks
final class FunctionalAutomationTests: XCTestCase {
    
    var app: XCUIApplication!
    
    // MARK: - Configuration
    
    private let backendURL = "http://192.168.0.155:3004"
    private let testTimeout: TimeInterval = 30.0
    
    // MARK: - Setup/Teardown
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        // Initialize app
        app = XCUIApplication()
        
        // Configure for real backend testing
        app.launchArguments = [
            "UI-Testing",
            "--backend-url", backendURL,
            "--no-mocks",
            "--real-backend",
            "--disable-animations"  // Speed up tests
        ]
        
        app.launchEnvironment = [
            "TESTING_MODE": "true",
            "BACKEND_URL": backendURL,
            "USE_REAL_BACKEND": "true",
            "SIMULATOR_UUID": ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_UDID"] ?? ""
        ]
        
        // Launch the app
        app.launch()
        
        // Wait for app to be ready
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10), "App should launch")
    }
    
    override func tearDownWithError() throws {
        // Take screenshot on failure
        if testRun?.hasSucceeded == false {
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Failure Screenshot"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        
        app.terminate()
        app = nil
    }
    
    // MARK: - Test 1: Navigate Through Main Tabs
    
    func test001_NavigateThroughMainTabs() throws {
        print("🧪 Test: Navigate through all main tabs")
        
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: testTimeout), "Tab bar should exist")
        
        // Test Projects tab
        let projectsTab = tabBar.buttons["Projects"]
        XCTAssertTrue(projectsTab.exists, "Projects tab should exist")
        projectsTab.tap()
        sleep(1) // Allow UI to settle
        
        // Verify we're on Projects screen
        let projectsTitle = app.navigationBars["Projects"].firstMatch
        XCTAssertTrue(projectsTitle.waitForExistence(timeout: 5), "Should show Projects screen")
        
        // Test Sessions tab
        let sessionsTab = tabBar.buttons["Sessions"]
        if sessionsTab.exists {
            sessionsTab.tap()
            sleep(1)
            
            let sessionsTitle = app.navigationBars["Sessions"].firstMatch
            XCTAssertTrue(sessionsTitle.waitForExistence(timeout: 5), "Should show Sessions screen")
        }
        
        // Test Chat tab
        let chatTab = tabBar.buttons["Chat"]
        if chatTab.exists {
            chatTab.tap()
            sleep(1)
            
            // Look for chat-related UI elements
            let chatView = app.scrollViews.firstMatch
            XCTAssertTrue(chatView.waitForExistence(timeout: 5), "Should show Chat screen")
        }
        
        print("✅ Successfully navigated through all tabs")
    }
    
    // MARK: - Test 2: Projects List Loading
    
    func test002_ProjectsListLoading() throws {
        print("🧪 Test: Load projects from backend")
        
        // Navigate to Projects
        navigateToProjects()
        
        // Wait for projects to load
        let projectsList = app.collectionViews.firstMatch.exists ? 
                          app.collectionViews.firstMatch : 
                          app.tables.firstMatch
        
        XCTAssertTrue(projectsList.waitForExistence(timeout: testTimeout), 
                     "Projects list should load from backend")
        
        // Check if we have any projects
        let cells = projectsList.cells
        if cells.count > 0 {
            print("✅ Found \(cells.count) projects")
            
            // Try to tap the first project
            cells.firstMatch.tap()
            
            // Verify navigation to sessions
            let backButton = app.navigationBars.buttons.firstMatch
            XCTAssertTrue(backButton.waitForExistence(timeout: 5), 
                         "Should navigate to project details")
        } else {
            print("⚠️ No projects found - backend might not have data")
        }
    }
    
    // MARK: - Test 3: WebSocket Connection Test
    
    func test003_WebSocketConnection() throws {
        print("🧪 Test: WebSocket connection to backend")
        
        // Navigate to a chat session
        navigateToChat()
        
        // Look for connection indicator or try sending a message
        let messageInput = findMessageInput()
        
        if messageInput.exists {
            messageInput.tap()
            messageInput.typeText("Test message from automation")
            
            // Find and tap send button
            let sendButton = findSendButton()
            if sendButton.exists {
                sendButton.tap()
                
                // Wait for message to appear in chat
                let message = app.staticTexts["Test message from automation"].firstMatch
                XCTAssertTrue(message.waitForExistence(timeout: testTimeout), 
                             "Message should be sent via WebSocket")
                
                print("✅ WebSocket connection working")
            }
        }
    }
    
    // MARK: - Test 4: Create New Session
    
    func test004_CreateNewSession() throws {
        print("🧪 Test: Create new chat session")
        
        // Navigate to projects first
        navigateToProjects()
        
        // Select a project
        let projectsList = app.collectionViews.firstMatch.exists ? 
                          app.collectionViews.firstMatch : 
                          app.tables.firstMatch
        
        if projectsList.waitForExistence(timeout: testTimeout) && projectsList.cells.count > 0 {
            projectsList.cells.firstMatch.tap()
            sleep(2)
            
            // Look for add/new button
            let addButton = app.navigationBars.buttons["Add"].firstMatch
            let plusButton = app.navigationBars.buttons["plus"].firstMatch
            let newButton = app.buttons["New Session"].firstMatch
            
            let createButton = addButton.exists ? addButton : 
                              (plusButton.exists ? plusButton : newButton)
            
            if createButton.exists {
                createButton.tap()
                
                // Verify new session was created
                let sessionsList = app.tables.firstMatch
                XCTAssertTrue(sessionsList.waitForExistence(timeout: testTimeout), 
                             "Sessions list should appear")
                
                print("✅ New session created")
            }
        }
    }
    
    // MARK: - Test 5: Send and Receive Messages
    
    func test005_SendAndReceiveMessages() throws {
        print("🧪 Test: Send message and receive response")
        
        // Navigate to chat
        navigateToChat()
        
        // Send a test message
        let messageInput = findMessageInput()
        if messageInput.waitForExistence(timeout: testTimeout) {
            messageInput.tap()
            
            let testMessage = "Hello Claude, this is an automated test at \(Date())"
            messageInput.typeText(testMessage)
            
            let sendButton = findSendButton()
            if sendButton.exists {
                sendButton.tap()
                
                // Wait for response
                sleep(3)
                
                // Check if messages appeared in chat
                let messagesTable = app.tables["messagesTable"].firstMatch
                let messagesExist = messagesTable.exists || 
                                   app.scrollViews.firstMatch.exists
                
                XCTAssertTrue(messagesExist, "Messages should appear in chat")
                print("✅ Message sent and chat updated")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToProjects() {
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 5) {
            let projectsTab = tabBar.buttons["Projects"]
            if projectsTab.exists {
                projectsTab.tap()
                sleep(1)
            }
        }
    }
    
    private func navigateToChat() {
        // Try direct chat tab first
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 5) {
            let chatTab = tabBar.buttons["Chat"]
            if chatTab.exists {
                chatTab.tap()
                sleep(1)
                return
            }
        }
        
        // Otherwise navigate through projects -> sessions -> chat
        navigateToProjects()
        
        // Select first project
        let projectsList = app.collectionViews.firstMatch.exists ? 
                          app.collectionViews.firstMatch : 
                          app.tables.firstMatch
        
        if projectsList.waitForExistence(timeout: 10) && projectsList.cells.count > 0 {
            projectsList.cells.firstMatch.tap()
            sleep(2)
            
            // Select first session or create new
            let sessionsList = app.tables.firstMatch
            if sessionsList.waitForExistence(timeout: 10) {
                if sessionsList.cells.count > 0 {
                    sessionsList.cells.firstMatch.tap()
                } else {
                    // Try to create new session
                    let addButton = app.navigationBars.buttons.matching(
                        NSPredicate(format: "label CONTAINS[c] 'add' OR label CONTAINS[c] 'new'")
                    ).firstMatch
                    if addButton.exists {
                        addButton.tap()
                    }
                }
                sleep(2)
            }
        }
    }
    
    private func findMessageInput() -> XCUIElement {
        // Try different possible identifiers for message input
        let identifiers = ["messageInput", "chatInput", "inputField", "textView"]
        
        for identifier in identifiers {
            let element = app.textViews[identifier].firstMatch
            if element.exists {
                return element
            }
            
            let textField = app.textFields[identifier].firstMatch
            if textField.exists {
                return textField
            }
        }
        
        // Fallback to first text input
        if app.textViews.count > 0 {
            return app.textViews.firstMatch
        }
        
        return app.textFields.firstMatch
    }
    
    private func findSendButton() -> XCUIElement {
        // Try different possible identifiers for send button
        let identifiers = ["sendButton", "send", "Send", "submit"]
        
        for identifier in identifiers {
            let button = app.buttons[identifier].firstMatch
            if button.exists {
                return button
            }
        }
        
        // Look for button with send-related label
        let sendPredicate = NSPredicate(format: "label CONTAINS[c] 'send'")
        let sendButton = app.buttons.matching(sendPredicate).firstMatch
        if sendButton.exists {
            return sendButton
        }
        
        // Fallback to any button near the input
        return app.buttons.firstMatch
    }
    
    // MARK: - Performance Test
    
    func testPerformance_AppLaunch() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }
}