//
//  BasicFunctionalTests.swift
//  ClaudeCodeUIUITests
//
//  Created by UI Automation Agent on 2025-09-07.
//

import XCTest

final class BasicFunctionalTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Set environment for testing with real backend
        app.launchEnvironment = [
            "BACKEND_URL": "http://localhost:3004",
            "UI_TESTING": "true"
        ]
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Basic Launch Test
    
    func testAppLaunchesSuccessfully() throws {
        // Test that app launches without crashing
        XCTAssertTrue(app.exists, "App should exist")
        
        // Take screenshot of launch state
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "App_Launch"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // Wait for initial UI to appear
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should appear")
    }
    
    // MARK: - Tab Bar Test
    
    func testTabBarExists() throws {
        // Verify tab bar is present
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
        
        // Check for expected tabs
        let projectsTab = tabBar.buttons["Projects"]
        let terminalTab = tabBar.buttons["Terminal"]
        let mcpTab = tabBar.buttons["MCP"]
        let searchTab = tabBar.buttons["Search"]
        let settingsTab = tabBar.buttons["Settings"]
        
        XCTAssertTrue(projectsTab.exists, "Projects tab should exist")
        XCTAssertTrue(terminalTab.exists, "Terminal tab should exist")
        XCTAssertTrue(mcpTab.exists, "MCP tab should exist")
        XCTAssertTrue(searchTab.exists, "Search tab should exist")
        XCTAssertTrue(settingsTab.exists, "Settings tab should exist")
    }
    
    // MARK: - Basic Navigation Test
    
    func testBasicTabNavigation() throws {
        let tabBar = app.tabBars.firstMatch
        
        // Test Settings tab navigation
        let settingsTab = tabBar.buttons["Settings"]
        if settingsTab.exists && settingsTab.isHittable {
            settingsTab.tap()
            
            // Take screenshot
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Settings_Tab"
            attachment.lifetime = .keepAlways
            add(attachment)
            
            // Small delay to ensure UI updates
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        // Return to Projects tab
        let projectsTab = tabBar.buttons["Projects"]
        if projectsTab.exists && projectsTab.isHittable {
            projectsTab.tap()
            
            // Take screenshot
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Projects_Tab"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
    
    // MARK: - Backend Connection Test
    
    func testBackendHealthCheck() throws {
        // This test verifies the app can connect to backend
        // The actual connection is established in the app
        
        // Wait for any loading indicators to disappear
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            // Wait for loading to complete
            let loadingDisappeared = NSPredicate(format: "exists == false")
            let expectation = expectation(for: loadingDisappeared, evaluatedWith: loadingIndicator, handler: nil)
            wait(for: [expectation], timeout: 10)
        }
        
        // Check if projects view is displayed (indicates successful backend connection)
        let projectsExist = app.staticTexts["Projects"].exists ||
                          app.navigationBars["Projects"].exists ||
                          app.collectionViews.firstMatch.exists
        
        XCTAssertTrue(projectsExist, "Projects view should be visible after backend connection")
    }
    
    // MARK: - UI Elements Test
    
    func testMainUIElementsExist() throws {
        // Check for main UI components
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
        
        // Check for navigation elements
        let navBarExists = app.navigationBars.firstMatch.waitForExistence(timeout: 3)
        if navBarExists {
            print("✅ Navigation bar found")
        }
        
        // Check for collection/table views (depending on which tab is active)
        let hasContentView = app.collectionViews.firstMatch.exists ||
                            app.tables.firstMatch.exists
        
        if hasContentView {
            print("✅ Content view found")
        }
        
        // Take final screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Main_UI_Elements"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}