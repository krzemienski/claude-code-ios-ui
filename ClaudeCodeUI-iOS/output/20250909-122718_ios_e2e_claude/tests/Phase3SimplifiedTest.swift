import XCTest

// MARK: - Phase 3 Simplified Persistence Test
// Focus: Core message persistence validation

class Phase3SimplifiedTest: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-TESTING", "PHASE-3-PERSISTENCE"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
    }
    
    // MARK: - Core Persistence Test
    
    func test_message_persistence_across_app_lifecycle() throws {
        // Step 1: Navigate to Chat
        let tabBar = app.tabBars["MainTabBar"]
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should exist")
        
        // Navigate to Projects
        let projectsTab = tabBar.buttons["ProjectsTab"]
        if projectsTab.exists {
            projectsTab.tap()
        }
        
        // Select first project
        let projectsList = app.collectionViews.firstMatch
        if projectsList.waitForExistence(timeout: 3) {
            let firstProject = projectsList.cells.firstMatch
            if firstProject.exists {
                firstProject.tap()
            }
        }
        
        // Navigate to Sessions
        let sessionsTab = tabBar.buttons["SessionsTab"]
        if sessionsTab.exists {
            sessionsTab.tap()
        }
        
        // Select or create session
        let sessionsList = app.tables["SessionsTableView"]
        if sessionsList.waitForExistence(timeout: 3) {
            if sessionsList.cells.count > 0 {
                sessionsList.cells.firstMatch.tap()
            } else {
                // Create new session
                let addButton = app.navigationBars.buttons["Add"]
                if addButton.exists {
                    addButton.tap()
                }
            }
        }
        
        // Step 2: Send test message
        let messageInput = app.textViews["MessageInputTextView"]
        XCTAssertTrue(messageInput.waitForExistence(timeout: 5), "Message input should exist")
        
        messageInput.tap()
        messageInput.typeText("Test persistence message at \(Date())")
        
        let sendButton = app.buttons["SendButton"]
        if sendButton.exists && sendButton.isEnabled {
            sendButton.tap()
        }
        
        // Wait for message to appear
        Thread.sleep(forTimeInterval: 2)
        
        // Step 3: Capture message content
        let messages = app.collectionViews["ChatCollectionView"]
        let messageCount = messages.cells.count
        XCTAssertGreaterThan(messageCount, 0, "Should have at least one message")
        
        // Step 4: Background the app
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 2)
        
        // Step 5: Reactivate the app
        app.activate()
        Thread.sleep(forTimeInterval: 2)
        
        // Step 6: Verify message still exists
        let messagesAfterBackground = app.collectionViews["ChatCollectionView"]
        let messageCountAfterBackground = messagesAfterBackground.cells.count
        XCTAssertEqual(messageCountAfterBackground, messageCount, "Messages should persist after backgrounding")
        
        // Step 7: Force terminate and relaunch
        app.terminate()
        Thread.sleep(forTimeInterval: 1)
        
        app = XCUIApplication()
        app.launchArguments = ["UI-TESTING", "PHASE-3-PERSISTENCE"]
        app.launch()
        
        // Step 8: Navigate back to the same session
        // Navigate to Sessions tab directly
        let tabBarAfterRelaunch = app.tabBars["MainTabBar"]
        XCTAssertTrue(tabBarAfterRelaunch.waitForExistence(timeout: 5), "Tab bar should exist after relaunch")
        
        let sessionsTabAfterRelaunch = tabBarAfterRelaunch.buttons["SessionsTab"]
        if sessionsTabAfterRelaunch.exists {
            sessionsTabAfterRelaunch.tap()
        }
        
        // Select the same session (should be the most recent)
        let sessionsListAfterRelaunch = app.tables["SessionsTableView"]
        if sessionsListAfterRelaunch.waitForExistence(timeout: 3) {
            if sessionsListAfterRelaunch.cells.count > 0 {
                sessionsListAfterRelaunch.cells.firstMatch.tap()
            }
        }
        
        // Step 9: Verify messages persisted
        let messagesAfterRelaunch = app.collectionViews["ChatCollectionView"]
        if messagesAfterRelaunch.waitForExistence(timeout: 5) {
            let finalMessageCount = messagesAfterRelaunch.cells.count
            XCTAssertGreaterThan(finalMessageCount, 0, "Messages should persist after app relaunch")
            
            // This assertion might fail initially (TDD approach)
            // The app needs to implement proper Core Data persistence
            XCTAssertEqual(finalMessageCount, messageCount, "All messages should be restored after relaunch")
        }
        
        print("✅ Phase 3 Persistence Test Complete")
        print("📊 Messages before termination: \(messageCount)")
        print("📊 Messages after relaunch: \(messagesAfterRelaunch.cells.count)")
    }
}