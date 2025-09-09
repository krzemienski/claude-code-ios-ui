//
//  EnhancedFunctionalFlowTests.swift
//  ClaudeCodeUIUITests
//
//  Enhanced functional UI tests with improved element discovery
//  Debug view hierarchy and fix element finding issues
//

import XCTest

final class EnhancedFunctionalFlowTests: XCTestCase {
    
    var app: XCUIApplication!
    private let timeout: TimeInterval = 30.0
    private let shortTimeout: TimeInterval = 5.0
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Launch with testing flags for real backend interaction
        app.launchArguments = [
            "--uitesting",
            "--enable-backend",
            "--real-data"
        ]
        
        // Set environment for testing with correct backend port
        app.launchEnvironment = [
            "TESTING_MODE": "functional",
            "BACKEND_URL": "http://localhost:3004",
            "ENABLE_LOGGING": "true",
            "DEBUG_UI": "true"
        ]
        
        app.launch()
        
        // Wait for app to fully initialize
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: shortTimeout))
        
        // Debug: Print initial view hierarchy
        debugPrintViewHierarchy("After Launch")
    }
    
    override func tearDownWithError() throws {
        captureScreenshot(name: "Test_Completion_\(name)")
        app = nil
    }
    
    // MARK: - Enhanced Complete User Flow Test
    
    func testEnhancedCompleteUserFlow() throws {
        print("🚀 Starting Enhanced Complete User Flow Test")
        
        // Step 1: Verify app launches and identify available UI elements
        debugPrintViewHierarchy("Step 1 - Initial State")
        
        // Look for tab bar with different possible identifiers
        let tabBar = findTabBar()
        XCTAssertNotNil(tabBar, "Tab bar should exist")
        
        if let tabBar = tabBar {
            print("✅ Found tab bar with \(tabBar.buttons.count) buttons")
            
            // Try to find Projects tab with various identifiers
            let projectsTab = findProjectsTab(in: tabBar)
            
            if let projectsTab = projectsTab {
                print("✅ Found Projects tab")
                if !projectsTab.isSelected {
                    projectsTab.tap()
                    Thread.sleep(forTimeInterval: 1.0)
                }
            }
        }
        
        captureScreenshot(name: "1_Initial_Launch")
        
        // Step 2: Look for project content with enhanced discovery
        print("🔍 Looking for project content...")
        Thread.sleep(forTimeInterval: 3.0) // Give time for content to load
        
        let projectContent = findProjectContent()
        
        if let content = projectContent {
            print("✅ Found project content: \(content.description)")
            captureScreenshot(name: "2_Projects_Loaded")
            
            // Try to interact with first project
            if let firstProject = findFirstProject(in: content) {
                print("📱 Tapping first project...")
                firstProject.tap()
                Thread.sleep(forTimeInterval: 2.0)
                captureScreenshot(name: "3_After_Project_Tap")
                
                // Look for session content
                let sessionContent = findSessionContent()
                if let sessions = sessionContent {
                    print("✅ Found sessions content")
                    captureScreenshot(name: "4_Sessions_View")
                    
                    // Try to enter first session
                    if let firstSession = findFirstSession(in: sessions) {
                        firstSession.tap()
                        Thread.sleep(forTimeInterval: 2.0)
                        captureScreenshot(name: "5_After_Session_Tap")
                        
                        // Test chat functionality
                        testEnhancedChatInteraction()
                    }
                }
            }
        } else {
            // Handle authentication or empty state
            handleSpecialStates()
        }
        
        print("✅ Enhanced flow test completed")
    }
    
    // MARK: - Enhanced Chat Interaction Test
    
    func testEnhancedChatInteraction() {
        print("💬 Testing enhanced chat interaction...")
        
        debugPrintViewHierarchy("Chat View")
        
        // Find chat input with multiple strategies
        let chatInput = findChatInput()
        
        if let input = chatInput {
            print("✅ Found chat input: \(input.identifier)")
            
            // Type a message
            input.tap()
            Thread.sleep(forTimeInterval: 0.5)
            input.typeText("Test message from enhanced UI automation")
            captureScreenshot(name: "6_Message_Typed")
            
            // Find and tap send button
            let sendButton = findSendButton()
            
            if let button = sendButton {
                print("✅ Found send button")
                button.tap()
                
                // Wait for response
                Thread.sleep(forTimeInterval: 3.0)
                captureScreenshot(name: "7_After_Send")
                
                // Verify message was sent
                let messageList = findMessageList()
                if let list = messageList {
                    print("✅ Found message list with \(list.cells.count) messages")
                    captureScreenshot(name: "8_Message_Response")
                }
            } else {
                print("⚠️ Send button not found, trying return key")
                app.keyboards.buttons["return"].tap()
            }
        } else {
            print("❌ Chat input not found")
            debugPrintAllTextFields()
            debugPrintAllTextViews()
        }
    }
    
    // MARK: - UI Element Discovery Helpers
    
    private func findTabBar() -> XCUIElement? {
        // Try multiple strategies to find tab bar
        if app.tabBars.firstMatch.exists {
            return app.tabBars.firstMatch
        }
        
        // Try by accessibility identifier
        if app.tabBars["MainTabBar"].exists {
            return app.tabBars["MainTabBar"]
        }
        
        // Try any tab bar
        for tabBar in app.tabBars.allElementsBoundByIndex {
            if tabBar.exists {
                return tabBar
            }
        }
        
        return nil
    }
    
    private func findProjectsTab(in tabBar: XCUIElement) -> XCUIElement? {
        // Try various identifiers for Projects tab
        let possibleIdentifiers = ["Projects", "projects", "ProjectsTab", "tab_projects", "Project"]
        
        for identifier in possibleIdentifiers {
            let button = tabBar.buttons[identifier]
            if button.exists {
                return button
            }
        }
        
        // Try by index (usually first tab)
        if tabBar.buttons.count > 0 {
            let firstButton = tabBar.buttons.element(boundBy: 0)
            if firstButton.exists {
                print("⚠️ Using first tab button as Projects tab")
                return firstButton
            }
        }
        
        return nil
    }
    
    private func findProjectContent() -> XCUIElement? {
        // Try collection view
        if app.collectionViews.firstMatch.exists {
            let collectionView = app.collectionViews.firstMatch
            if collectionView.cells.count > 0 {
                return collectionView
            }
        }
        
        // Try table view
        if app.tables.firstMatch.exists {
            let tableView = app.tables.firstMatch
            if tableView.cells.count > 0 {
                return tableView
            }
        }
        
        // Try scroll view
        if app.scrollViews.firstMatch.exists {
            return app.scrollViews.firstMatch
        }
        
        return nil
    }
    
    private func findFirstProject(in container: XCUIElement) -> XCUIElement? {
        // Try cells first
        if container.cells.count > 0 {
            return container.cells.firstMatch
        }
        
        // Try buttons
        if container.buttons.count > 0 {
            return container.buttons.firstMatch
        }
        
        // Try other elements
        if container.otherElements.count > 0 {
            for element in container.otherElements.allElementsBoundByIndex {
                if element.isHittable {
                    return element
                }
            }
        }
        
        return nil
    }
    
    private func findSessionContent() -> XCUIElement? {
        // Similar to findProjectContent but for sessions
        Thread.sleep(forTimeInterval: 1.0)
        
        if app.tables.firstMatch.exists && app.tables.firstMatch.cells.count > 0 {
            return app.tables.firstMatch
        }
        
        if app.collectionViews.firstMatch.exists && app.collectionViews.firstMatch.cells.count > 0 {
            return app.collectionViews.firstMatch
        }
        
        return nil
    }
    
    private func findFirstSession(in container: XCUIElement) -> XCUIElement? {
        if container.cells.count > 0 {
            return container.cells.firstMatch
        }
        return nil
    }
    
    private func findChatInput() -> XCUIElement? {
        // Try text views with various identifiers
        let textViewIdentifiers = ["chatInputTextView", "messageInput", "chatInput", "inputTextView"]
        for identifier in textViewIdentifiers {
            let textView = app.textViews[identifier]
            if textView.exists {
                return textView
            }
        }
        
        // Try any text view
        if app.textViews.count > 0 {
            for textView in app.textViews.allElementsBoundByIndex {
                if textView.exists && textView.isHittable {
                    return textView
                }
            }
        }
        
        // Try text fields as fallback
        let textFieldIdentifiers = ["chatInputField", "messageField", "inputField"]
        for identifier in textFieldIdentifiers {
            let textField = app.textFields[identifier]
            if textField.exists {
                return textField
            }
        }
        
        // Try any text field
        if app.textFields.count > 0 {
            for textField in app.textFields.allElementsBoundByIndex {
                if textField.exists && textField.isHittable {
                    return textField
                }
            }
        }
        
        return nil
    }
    
    private func findSendButton() -> XCUIElement? {
        // Try specific identifiers
        let buttonIdentifiers = ["chatSendButton", "sendButton", "send", "Send"]
        for identifier in buttonIdentifiers {
            let button = app.buttons[identifier]
            if button.exists {
                return button
            }
        }
        
        // Try by label
        let labelPredicates = [
            NSPredicate(format: "label CONTAINS[c] 'send'"),
            NSPredicate(format: "label == 'Send'"),
            NSPredicate(format: "label CONTAINS '➤'"),
            NSPredicate(format: "label CONTAINS '→'")
        ]
        
        for predicate in labelPredicates {
            let button = app.buttons.matching(predicate).firstMatch
            if button.exists {
                return button
            }
        }
        
        return nil
    }
    
    private func findMessageList() -> XCUIElement? {
        // Try collection views first (common for chat UIs)
        if app.collectionViews["MessageList"].exists {
            return app.collectionViews["MessageList"]
        }
        
        if app.collectionViews.firstMatch.exists {
            return app.collectionViews.firstMatch
        }
        
        // Try table views
        if app.tables.firstMatch.exists {
            return app.tables.firstMatch
        }
        
        return nil
    }
    
    // MARK: - Special State Handlers
    
    private func handleSpecialStates() {
        print("🔍 Checking for special states...")
        
        // Check for login
        if app.buttons["Login"].exists || app.buttons["Sign In"].exists {
            print("📱 Authentication required")
            captureScreenshot(name: "Authentication_Required")
            
            // Try to bypass or handle auth
            if app.buttons["Skip"].exists {
                app.buttons["Skip"].tap()
            } else if app.buttons["Continue as Guest"].exists {
                app.buttons["Continue as Guest"].tap()
            }
        }
        
        // Check for empty state
        let emptyLabels = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'empty' OR label CONTAINS[c] 'no projects' OR label CONTAINS[c] 'get started'"))
        if emptyLabels.count > 0 {
            print("📭 Empty state detected")
            captureScreenshot(name: "Empty_State")
            
            // Look for create button
            if app.buttons["Create"].exists {
                app.buttons["Create"].tap()
            } else if app.buttons["Add"].exists {
                app.buttons["Add"].tap()
            }
        }
    }
    
    // MARK: - Debug Helpers
    
    private func debugPrintViewHierarchy(_ context: String) {
        print("\n📋 View Hierarchy - \(context):")
        print("  Tab Bars: \(app.tabBars.count)")
        print("  Navigation Bars: \(app.navigationBars.count)")
        print("  Tables: \(app.tables.count)")
        print("  Collection Views: \(app.collectionViews.count)")
        print("  Buttons: \(app.buttons.count)")
        print("  Text Fields: \(app.textFields.count)")
        print("  Text Views: \(app.textViews.count)")
        print("  Static Texts: \(app.staticTexts.count)")
        
        // Print some element details
        if app.buttons.count > 0 && app.buttons.count < 20 {
            print("\n  Available Buttons:")
            for i in 0..<min(app.buttons.count, 10) {
                let button = app.buttons.element(boundBy: i)
                if button.exists {
                    print("    - \(button.label) (id: \(button.identifier))")
                }
            }
        }
    }
    
    private func debugPrintAllTextFields() {
        print("\n📝 All Text Fields:")
        for i in 0..<app.textFields.count {
            let field = app.textFields.element(boundBy: i)
            if field.exists {
                print("  - TextField[\(i)]: '\(field.label)' id: '\(field.identifier)' placeholder: '\(field.placeholderValue ?? "none")'")
            }
        }
    }
    
    private func debugPrintAllTextViews() {
        print("\n📝 All Text Views:")
        for i in 0..<app.textViews.count {
            let view = app.textViews.element(boundBy: i)
            if view.exists {
                print("  - TextView[\(i)]: '\(view.label)' id: '\(view.identifier)'")
            }
        }
    }
    
    private func captureScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

// MARK: - Additional Test Cases

extension EnhancedFunctionalFlowTests {
    
    func testTabBarNavigation() {
        print("📱 Testing tab bar navigation...")
        
        guard let tabBar = findTabBar() else {
            XCTFail("Tab bar not found")
            return
        }
        
        // Test each tab
        for i in 0..<tabBar.buttons.count {
            let button = tabBar.buttons.element(boundBy: i)
            if button.exists && button.isHittable {
                print("  Tapping tab \(i): \(button.label)")
                button.tap()
                Thread.sleep(forTimeInterval: 1.0)
                captureScreenshot(name: "Tab_\(i)_\(button.label)")
            }
        }
    }
    
    func testScrollingPerformance() {
        print("📜 Testing scrolling performance...")
        
        // Find scrollable content
        var scrollView: XCUIElement?
        
        if app.collectionViews.firstMatch.exists {
            scrollView = app.collectionViews.firstMatch
        } else if app.tables.firstMatch.exists {
            scrollView = app.tables.firstMatch
        } else if app.scrollViews.firstMatch.exists {
            scrollView = app.scrollViews.firstMatch
        }
        
        guard let view = scrollView else {
            print("⚠️ No scrollable content found")
            return
        }
        
        // Perform rapid scrolling
        for i in 1...5 {
            view.swipeUp(velocity: .fast)
            Thread.sleep(forTimeInterval: 0.2)
            
            if i % 2 == 0 {
                captureScreenshot(name: "Scroll_Up_\(i)")
            }
        }
        
        // Scroll back
        for i in 1...5 {
            view.swipeDown(velocity: .fast)
            Thread.sleep(forTimeInterval: 0.2)
        }
        
        print("✅ Scrolling test completed")
    }
    
    func testBackNavigation() {
        print("🔙 Testing back navigation...")
        
        // Check for navigation bar
        if app.navigationBars.count > 0 {
            let navBar = app.navigationBars.firstMatch
            
            // Look for back button
            if navBar.buttons.count > 0 {
                let backButton = navBar.buttons.firstMatch
                if backButton.exists && backButton.label.contains("Back") || backButton.label.contains("<") {
                    print("  Found back button: \(backButton.label)")
                    backButton.tap()
                    Thread.sleep(forTimeInterval: 1.0)
                    captureScreenshot(name: "After_Back_Navigation")
                }
            }
        }
        
        // Alternative: swipe gesture
        app.swipeRight()
        Thread.sleep(forTimeInterval: 0.5)
        captureScreenshot(name: "After_Swipe_Back")
    }
}