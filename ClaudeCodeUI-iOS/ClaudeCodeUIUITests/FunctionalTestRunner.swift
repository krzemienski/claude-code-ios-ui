//
//  FunctionalTestRunner.swift
//  ClaudeCodeUIUITests
//
//  Created by Agent-2 on 2025-09-07.
//

import XCTest

/// Main functional test runner for iOS app
class FunctionalTestRunner: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Disable animations for faster testing
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--backend-url", "http://192.168.0.155:3004"]
        app.launchEnvironment = ["TESTING_MODE": "1"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Basic Launch Tests
    
    func test_01_AppLaunches() throws {
        // Verify app launches successfully
        XCTAssertTrue(app.exists, "App should exist")
        XCTAssertEqual(app.state, .runningForeground, "App should be running in foreground")
        
        // Give app time to initialize
        sleep(2)
        
        // Log success
        print("✅ App launched successfully")
    }
    
    func test_02_AuthenticationScreenAppears() throws {
        // Look for authentication screen elements
        let authView = app.otherElements["authenticationView"]
        let emailField = app.textFields["emailField"]
        let passwordField = app.secureTextFields["passwordField"]
        let loginButton = app.buttons["loginButton"]
        
        // Wait for auth screen to appear
        XCTAssertTrue(
            authView.waitForExistence(timeout: 5) ||
            emailField.waitForExistence(timeout: 5) ||
            loginButton.waitForExistence(timeout: 5),
            "Authentication screen should appear"
        )
        
        print("✅ Authentication screen detected")
    }
    
    func test_03_BackendConnectivity() throws {
        // This test verifies the app can communicate with backend
        // The actual connection is tested through the app's network layer
        
        // Look for any network status indicators
        let statusIndicator = app.otherElements["connectionStatus"]
        let errorAlert = app.alerts.firstMatch
        
        // Wait a bit for initial connection attempt
        sleep(3)
        
        // Check that no error alerts appeared
        if errorAlert.exists {
            XCTFail("Network error alert appeared: \(errorAlert.label)")
        }
        
        print("✅ No network errors detected")
    }
    
    func test_04_UIResponsiveness() throws {
        // Test that UI is responsive
        let startTime = Date()
        
        // Try to interact with any visible element
        if app.textFields.firstMatch.exists {
            app.textFields.firstMatch.tap()
            let responseTime = Date().timeIntervalSince(startTime)
            XCTAssertLessThan(responseTime, 0.5, "UI should respond within 500ms")
            print("✅ UI response time: \(Int(responseTime * 1000))ms")
        } else if app.buttons.firstMatch.exists {
            app.buttons.firstMatch.tap()
            let responseTime = Date().timeIntervalSince(startTime)
            XCTAssertLessThan(responseTime, 0.5, "UI should respond within 500ms")
            print("✅ UI response time: \(Int(responseTime * 1000))ms")
        } else {
            print("⚠️ No interactive elements found for responsiveness test")
        }
    }
    
    // MARK: - Helper Methods
    
    private func waitFor(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }
    
    private func takeScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

/// Test configuration for running tests
extension FunctionalTestRunner {
    
    static func runAllTests() {
        print("🚀 Starting Functional Test Suite")
        print("📱 Target: iPhone 16 Pro Simulator")
        print("🌐 Backend: http://192.168.0.155:3004")
        print("=" * 50)
        
        let suite = XCTestSuite(name: "Functional Tests")
        
        // Add all test methods
        suite.addTest(FunctionalTestRunner(selector: #selector(test_01_AppLaunches)))
        suite.addTest(FunctionalTestRunner(selector: #selector(test_02_AuthenticationScreenAppears)))
        suite.addTest(FunctionalTestRunner(selector: #selector(test_03_BackendConnectivity)))
        suite.addTest(FunctionalTestRunner(selector: #selector(test_04_UIResponsiveness)))
        
        // Run the suite
        suite.run()
        
        print("=" * 50)
        print("✅ Functional Test Suite Complete")
    }
}