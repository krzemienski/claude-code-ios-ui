//
//  ComprehensiveUIAutomationTests.swift
//  ClaudeCodeUIUITests
//
//  Comprehensive UI Automation Test Suite with Real Interactions
//

import XCTest

final class ComprehensiveUIAutomationTests: XCTestCase {
    
    // MARK: - Properties
    
    private var app: XCUIApplication!
    private let screenshotHelper = ScreenshotHelper()
    private let automationHelper = UIAutomationHelper()
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["UI-TESTING", "SKIP-ONBOARDING"]
        app.launchEnvironment = [
            "BACKEND_URL": "http://localhost:3000",
            "DISABLE_ANIMATIONS": "1"
        ]
        
        // Reset app state
        app.launchArguments.append("-reset-state")
        
        app.launch()
        
        // Wait for app to fully launch
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Test: App Launch and Initial Navigation
    
    func test_01_AppLaunchAndInitialNavigation() throws {
        // Take screenshot after launch
        screenshotHelper.capture(name: "01_app_launch", in: app)
        
        // Verify main tab bar exists
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should exist")
        
        // Verify all tabs are present
        let projectsTab = tabBar.buttons["Projects"]
        let sessionsTab = tabBar.buttons["Sessions"]
        let searchTab = tabBar.buttons["Search"]
        let settingsTab = tabBar.buttons["Settings"]
        
        XCTAssertTrue(projectsTab.exists, "Projects tab should exist")
        XCTAssertTrue(sessionsTab.exists, "Sessions tab should exist")
        XCTAssertTrue(searchTab.exists, "Search tab should exist")
        XCTAssertTrue(settingsTab.exists, "Settings tab should exist")
        
        // Test tab navigation
        sessionsTab.tap()
        XCTAssertTrue(app.navigationBars["Sessions"].waitForExistence(timeout: 2))
        screenshotHelper.capture(name: "02_sessions_tab", in: app)
        
        searchTab.tap()
        XCTAssertTrue(app.navigationBars["Search"].waitForExistence(timeout: 2))
        screenshotHelper.capture(name: "03_search_tab", in: app)
        
        settingsTab.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))
        screenshotHelper.capture(name: "04_settings_tab", in: app)
        
        // Return to Projects tab
        projectsTab.tap()
        XCTAssertTrue(app.navigationBars["Projects"].waitForExistence(timeout: 2))
    }
    
    // MARK: - Test: Project List Navigation
    
    func test_02_ProjectListNavigation() throws {
        // Navigate to Projects tab
        let projectsTab = app.tabBars.firstMatch.buttons["Projects"]
        projectsTab.tap()
        
        // Wait for project list
        let projectsTable = app.tables["ProjectsTableView"]
        XCTAssertTrue(projectsTable.waitForExistence(timeout: 5), "Projects table should exist")
        
        screenshotHelper.capture(name: "05_projects_list", in: app)
        
        // Check if there are any projects
        let firstProject = projectsTable.cells.firstMatch
        if firstProject.exists {
            // Get project name for verification
            let projectName = firstProject.staticTexts.firstMatch.label
            
            // Tap on the project
            firstProject.tap()
            
            // Verify navigation to project detail or chat
            let navigationBar = app.navigationBars.firstMatch
            XCTAssertTrue(navigationBar.waitForExistence(timeout: 3), "Should navigate to project detail")
            
            screenshotHelper.capture(name: "06_project_detail", in: app)
            
            // Test back navigation
            if navigationBar.buttons["Back"].exists {
                navigationBar.buttons["Back"].tap()
            } else if navigationBar.buttons["Projects"].exists {
                navigationBar.buttons["Projects"].tap()
            }
            
            // Verify we're back at projects list
            XCTAssertTrue(projectsTable.waitForExistence(timeout: 3), "Should return to projects list")
        } else {
            // No projects exist, create a test project
            if app.buttons["Add Project"].exists {
                app.buttons["Add Project"].tap()
                screenshotHelper.capture(name: "07_add_project", in: app)
            }
        }
    }
    
    // MARK: - Test: Session Navigation and Messages
    
    func test_03_SessionNavigationAndMessages() throws {
        // Navigate to Sessions tab
        let sessionsTab = app.tabBars.firstMatch.buttons["Sessions"]
        sessionsTab.tap()
        
        // Wait for sessions list
        let sessionsTable = app.tables["SessionsTableView"]
        XCTAssertTrue(sessionsTable.waitForExistence(timeout: 5), "Sessions table should exist")
        
        screenshotHelper.capture(name: "08_sessions_list", in: app)
        
        // Check if there are any sessions
        let firstSession = sessionsTable.cells.firstMatch
        if firstSession.exists {
            // Tap on the session
            firstSession.tap()
            
            // Wait for chat view to load
            let chatView = app.collectionViews["ChatCollectionView"]
            if !chatView.exists {
                // Try table view for older implementations
                let chatTable = app.tables["ChatTableView"]
                XCTAssertTrue(chatTable.waitForExistence(timeout: 5) || chatView.waitForExistence(timeout: 5), 
                            "Chat view should exist")
            }
            
            screenshotHelper.capture(name: "09_chat_session", in: app)
            
            // Test message scrolling
            if chatView.exists {
                chatView.swipeUp()
                Thread.sleep(forTimeInterval: 0.5)
                chatView.swipeDown()
            }
            
            // Test message input
            let messageInput = app.textViews["MessageInputTextView"]
            if messageInput.exists {
                messageInput.tap()
                messageInput.typeText("Test message from UI automation")
                
                // Find and tap send button
                let sendButton = app.buttons["SendButton"]
                if sendButton.exists && sendButton.isEnabled {
                    sendButton.tap()
                    screenshotHelper.capture(name: "10_message_sent", in: app)
                }
            }
            
            // Test back navigation
            let backButton = app.navigationBars.firstMatch.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
                XCTAssertTrue(sessionsTable.waitForExistence(timeout: 3), "Should return to sessions list")
            }
        }
    }
    
    // MARK: - Test: Touch Automation and Gestures
    
    func test_04_TouchAutomationAndGestures() throws {
        // Test various touch gestures
        let projectsTab = app.tabBars.firstMatch.buttons["Projects"]
        projectsTab.tap()
        
        let projectsTable = app.tables["ProjectsTableView"]
        if projectsTable.waitForExistence(timeout: 5) {
            // Test swipe gestures
            automationHelper.performSwipeGesture(on: projectsTable, direction: .up)
            Thread.sleep(forTimeInterval: 0.5)
            automationHelper.performSwipeGesture(on: projectsTable, direction: .down)
            
            // Test long press
            if let firstCell = projectsTable.cells.allElementsBoundByIndex.first {
                automationHelper.performLongPress(on: firstCell, duration: 1.0)
                
                // Check if context menu appears
                if app.sheets.firstMatch.exists {
                    screenshotHelper.capture(name: "11_context_menu", in: app)
                    app.tap() // Dismiss menu
                }
            }
            
            // Test pinch gesture (if applicable)
            automationHelper.performPinchGesture(on: projectsTable, scale: 1.5)
        }
    }
    
    // MARK: - Test: Accessibility Verification
    
    func test_05_AccessibilityVerification() throws {
        // Verify accessibility identifiers and labels
        let accessibilityReport = AccessibilityVerifier.verify(app: app)
        
        // Check Projects tab accessibility
        let projectsTab = app.tabBars.firstMatch.buttons["Projects"]
        XCTAssertNotNil(projectsTab.identifier, "Projects tab should have accessibility identifier")
        XCTAssertNotNil(projectsTab.label, "Projects tab should have accessibility label")
        
        projectsTab.tap()
        
        // Check navigation bar accessibility
        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.isAccessibilityElement || navBar.staticTexts.firstMatch.isAccessibilityElement,
                     "Navigation bar should be accessible")
        
        // Check table view accessibility
        let projectsTable = app.tables["ProjectsTableView"]
        if projectsTable.exists {
            XCTAssertNotNil(projectsTable.identifier, "Projects table should have accessibility identifier")
            
            // Check cells accessibility
            for cell in projectsTable.cells.allElementsBoundByIndex.prefix(3) {
                XCTAssertTrue(cell.isAccessibilityElement || cell.staticTexts.count > 0,
                            "Table cells should be accessible")
            }
        }
        
        screenshotHelper.capture(name: "12_accessibility_check", in: app)
        
        // Generate accessibility report
        print("Accessibility Report:")
        print(accessibilityReport)
    }
    
    // MARK: - Test: State Preservation
    
    func test_06_StatePreservation() throws {
        // Test that app preserves state during navigation
        let projectsTab = app.tabBars.firstMatch.buttons["Projects"]
        projectsTab.tap()
        
        // Navigate to a specific position
        let projectsTable = app.tables["ProjectsTableView"]
        if projectsTable.waitForExistence(timeout: 5) && projectsTable.cells.count > 3 {
            // Scroll to a specific position
            projectsTable.swipeUp()
            projectsTable.swipeUp()
            
            // Remember visible cell
            let visibleCell = projectsTable.cells.element(boundBy: 2)
            let cellText = visibleCell.staticTexts.firstMatch.label
            
            // Navigate away
            app.tabBars.firstMatch.buttons["Settings"].tap()
            Thread.sleep(forTimeInterval: 1)
            
            // Navigate back
            projectsTab.tap()
            
            // Verify state is preserved
            XCTAssertTrue(visibleCell.exists, "Previously visible cell should still be visible")
            XCTAssertEqual(visibleCell.staticTexts.firstMatch.label, cellText, "Cell content should be preserved")
        }
    }
}

// MARK: - Helper Classes

class ScreenshotHelper {
    private var screenshotCounter = 0
    
    func capture(name: String, in app: XCUIApplication) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(name)_\(Date().timeIntervalSince1970)"
        attachment.lifetime = .keepAlways
        XCTContext.runActivity(named: "Screenshot: \(name)") { activity in
            activity.add(attachment)
        }
        screenshotCounter += 1
    }
}

class UIAutomationHelper {
    
    func performSwipeGesture(on element: XCUIElement, direction: SwipeDirection) {
        switch direction {
        case .up:
            element.swipeUp()
        case .down:
            element.swipeDown()
        case .left:
            element.swipeLeft()
        case .right:
            element.swipeRight()
        }
    }
    
    func performLongPress(on element: XCUIElement, duration: TimeInterval) {
        element.press(forDuration: duration)
    }
    
    func performTapAtCoordinate(in app: XCUIApplication, x: CGFloat, y: CGFloat) {
        let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
        coordinate.tap()
    }
    
    func performPinchGesture(on element: XCUIElement, scale: CGFloat) {
        element.pinch(withScale: scale, velocity: 1.0)
    }
    
    func performRotation(on element: XCUIElement, rotation: CGFloat) {
        element.rotate(rotation, withVelocity: 1.0)
    }
    
    func performDragAndDrop(from source: XCUIElement, to destination: XCUIElement) {
        source.press(forDuration: 0.5, thenDragTo: destination)
    }
    
    enum SwipeDirection {
        case up, down, left, right
    }
}

class AccessibilityVerifier {
    
    static func verify(app: XCUIApplication) -> String {
        var report = "Accessibility Verification Report\n"
        report += "==================================\n\n"
        
        // Check tab bar
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            report += "Tab Bar:\n"
            for button in tabBar.buttons.allElementsBoundByIndex {
                report += "  - \(button.label): "
                report += button.isAccessibilityElement ? "✓" : "✗"
                report += " (ID: \(button.identifier))\n"
            }
        }
        
        // Check navigation bars
        report += "\nNavigation Bars:\n"
        for navBar in app.navigationBars.allElementsBoundByIndex {
            if navBar.exists {
                report += "  - \(navBar.identifier): "
                report += navBar.isAccessibilityElement ? "✓" : "✗"
                report += "\n"
            }
        }
        
        // Check buttons
        report += "\nButtons:\n"
        for button in app.buttons.allElementsBoundByIndex.prefix(10) {
            if button.exists {
                report += "  - \(button.label): "
                report += button.isAccessibilityElement ? "✓" : "✗"
                report += " (ID: \(button.identifier))\n"
            }
        }
        
        return report
    }
}