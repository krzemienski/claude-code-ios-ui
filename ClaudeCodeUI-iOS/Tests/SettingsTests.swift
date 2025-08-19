//
//  SettingsTests.swift
//  ClaudeCodeUITests
//
//  Created on 2025-01-18.
//

import XCTest
@testable import ClaudeCodeUI

class SettingsTests: XCTestCase {
    
    var settingsVC: SettingsViewController!
    var mockAPIClient: MockSettingsAPIClient!
    var userDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        
        // Use separate UserDefaults for testing
        userDefaults = UserDefaults(suiteName: "com.claudecode.ui.tests")!
        userDefaults.removePersistentDomain(forName: "com.claudecode.ui.tests")
        
        // Create mock API client
        mockAPIClient = MockSettingsAPIClient()
        
        // Initialize settings view controller
        settingsVC = SettingsViewController()
        settingsVC.apiClient = mockAPIClient
        
        // Load view
        _ = settingsVC.view
    }
    
    override func tearDown() {
        settingsVC = nil
        mockAPIClient = nil
        userDefaults.removePersistentDomain(forName: "com.claudecode.ui.tests")
        userDefaults = nil
        super.tearDown()
    }
    
    // MARK: - Backend URL Tests
    
    func testBackendURLDisplay() {
        // Test that backend URL is displayed correctly
        settingsVC.viewWillAppear(false)
        
        let tableView = settingsVC.tableView!
        let cell = settingsVC.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        
        XCTAssertEqual(cell.textLabel?.text, "Backend URL")
        XCTAssertEqual(cell.detailTextLabel?.text, AppConfig.backendURL)
    }
    
    func testBackendURLUpdate() {
        // Test updating backend URL
        let newURL = "http://192.168.1.100:3004"
        
        AppConfig.updateBackendURL(newURL)
        settingsVC.viewWillAppear(false)
        
        let tableView = settingsVC.tableView!
        let cell = settingsVC.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        
        XCTAssertEqual(cell.detailTextLabel?.text, newURL)
        
        // Reset to default
        AppConfig.resetBackendURL()
    }
    
    func testBackendConnectionTest() {
        // Test backend connection test
        let expectation = self.expectation(description: "Connection tested")
        
        mockAPIClient.mockConnectionTestResponse = [
            "projects": [
                ["id": "1", "name": "Project 1"],
                ["id": "2", "name": "Project 2"]
            ]
        ]
        mockAPIClient.shouldSucceed = true
        
        mockAPIClient.onConnectionTested = { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        // Trigger connection test
        settingsVC.tableView(settingsVC.tableView, didSelectRowAt: IndexPath(row: 1, section: 0))
        
        waitForExpectations(timeout: 3.0)
    }
    
    func testBackendConnectionFailure() {
        // Test failed backend connection
        let expectation = self.expectation(description: "Connection failed")
        
        mockAPIClient.shouldSucceed = false
        mockAPIClient.mockError = NSError(domain: "test", code: -1009, userInfo: [
            NSLocalizedDescriptionKey: "The Internet connection appears to be offline."
        ])
        
        mockAPIClient.onConnectionTested = { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }
        
        // Trigger connection test
        settingsVC.tableView(settingsVC.tableView, didSelectRowAt: IndexPath(row: 1, section: 0))
        
        waitForExpectations(timeout: 3.0)
    }
    
    // MARK: - Settings Persistence Tests
    
    func testSettingsPersistence() {
        // Test that settings persist across app launches
        let testURL = "http://test.local:3004"
        let testHaptic = false
        let testDebug = true
        
        // Save settings
        AppConfig.updateBackendURL(testURL)
        AppConfig.enableHapticFeedback = testHaptic
        AppConfig.isDebugMode = testDebug
        
        // Simulate app restart by creating new instance
        let newSettingsVC = SettingsViewController()
        _ = newSettingsVC.view
        newSettingsVC.viewWillAppear(false)
        
        // Verify settings persisted
        XCTAssertEqual(AppConfig.backendURL, testURL)
        XCTAssertEqual(AppConfig.enableHapticFeedback, testHaptic)
        XCTAssertEqual(AppConfig.isDebugMode, testDebug)
        
        // Reset to defaults
        AppConfig.resetBackendURL()
        AppConfig.enableHapticFeedback = true
        AppConfig.isDebugMode = false
    }
    
    // MARK: - Table View Tests
    
    func testTableViewSections() {
        // Test that all sections are present
        let sectionCount = settingsVC.numberOfSections(in: settingsVC.tableView)
        XCTAssertEqual(sectionCount, 5) // Connection, MCP, Display, Developer, About
        
        // Test section titles
        XCTAssertEqual(settingsVC.tableView(settingsVC.tableView, titleForHeaderInSection: 0), "CONNECTION")
        XCTAssertEqual(settingsVC.tableView(settingsVC.tableView, titleForHeaderInSection: 1), "MCP SERVERS")
        XCTAssertEqual(settingsVC.tableView(settingsVC.tableView, titleForHeaderInSection: 2), "DISPLAY")
        XCTAssertEqual(settingsVC.tableView(settingsVC.tableView, titleForHeaderInSection: 3), "DEVELOPER")
        XCTAssertEqual(settingsVC.tableView(settingsVC.tableView, titleForHeaderInSection: 4), "ABOUT")
    }
    
    func testTableViewRows() {
        // Test row counts per section
        XCTAssertEqual(settingsVC.tableView(settingsVC.tableView, numberOfRowsInSection: 0), 2) // Connection
        XCTAssertEqual(settingsVC.tableView(settingsVC.tableView, numberOfRowsInSection: 1), 1) // MCP
        XCTAssertEqual(settingsVC.tableView(settingsVC.tableView, numberOfRowsInSection: 2), 2) // Display
        XCTAssertEqual(settingsVC.tableView(settingsVC.tableView, numberOfRowsInSection: 3), 2) // Developer
        XCTAssertEqual(settingsVC.tableView(settingsVC.tableView, numberOfRowsInSection: 4), 2) // About
    }
    
    // MARK: - Navigation Tests
    
    func testMCPServerNavigation() {
        // Test navigation to MCP servers
        let expectation = self.expectation(description: "MCP navigation")
        
        // Create navigation controller for testing
        let navController = UINavigationController(rootViewController: settingsVC)
        
        // Tap MCP servers row
        settingsVC.tableView(settingsVC.tableView, didSelectRowAt: IndexPath(row: 0, section: 1))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(navController.viewControllers.last is MCPServerListViewController)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testTestRunnerPresentation() {
        // Test that test runner is presented
        let expectation = self.expectation(description: "Test runner presented")
        
        // Mock TestRunnerViewController presentation
        TestRunnerViewController.onPresented = {
            expectation.fulfill()
        }
        
        // Tap Integration Tests row
        settingsVC.tableView(settingsVC.tableView, didSelectRowAt: IndexPath(row: 0, section: 3))
        
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - Display Settings Tests
    
    func testThemeDisplay() {
        // Test theme setting display
        let cell = settingsVC.tableView(settingsVC.tableView, cellForRowAt: IndexPath(row: 0, section: 2))
        
        XCTAssertEqual(cell.textLabel?.text, "Theme")
        XCTAssertEqual(cell.detailTextLabel?.text, "Cyberpunk")
    }
    
    func testHapticFeedbackToggle() {
        // Test haptic feedback display
        AppConfig.enableHapticFeedback = true
        settingsVC.viewWillAppear(false)
        
        var cell = settingsVC.tableView(settingsVC.tableView, cellForRowAt: IndexPath(row: 1, section: 2))
        XCTAssertEqual(cell.detailTextLabel?.text, "On")
        
        AppConfig.enableHapticFeedback = false
        settingsVC.viewWillAppear(false)
        
        cell = settingsVC.tableView(settingsVC.tableView, cellForRowAt: IndexPath(row: 1, section: 2))
        XCTAssertEqual(cell.detailTextLabel?.text, "Off")
        
        // Reset
        AppConfig.enableHapticFeedback = true
    }
    
    // MARK: - Developer Settings Tests
    
    func testDebugModeDisplay() {
        // Test debug mode display
        AppConfig.isDebugMode = true
        settingsVC.viewWillAppear(false)
        
        var cell = settingsVC.tableView(settingsVC.tableView, cellForRowAt: IndexPath(row: 1, section: 3))
        XCTAssertEqual(cell.detailTextLabel?.text, "On")
        
        AppConfig.isDebugMode = false
        settingsVC.viewWillAppear(false)
        
        cell = settingsVC.tableView(settingsVC.tableView, cellForRowAt: IndexPath(row: 1, section: 3))
        XCTAssertEqual(cell.detailTextLabel?.text, "Off")
    }
    
    // MARK: - About Section Tests
    
    func testVersionDisplay() {
        // Test version display
        let cell = settingsVC.tableView(settingsVC.tableView, cellForRowAt: IndexPath(row: 0, section: 4))
        
        XCTAssertEqual(cell.textLabel?.text, "Version")
        XCTAssertNotNil(cell.detailTextLabel?.text)
        XCTAssertFalse(cell.detailTextLabel?.text?.isEmpty ?? true)
    }
    
    func testBuildDisplay() {
        // Test build number display
        let cell = settingsVC.tableView(settingsVC.tableView, cellForRowAt: IndexPath(row: 1, section: 4))
        
        XCTAssertEqual(cell.textLabel?.text, "Build")
        XCTAssertNotNil(cell.detailTextLabel?.text)
        XCTAssertFalse(cell.detailTextLabel?.text?.isEmpty ?? true)
    }
    
    // MARK: - Cell Configuration Tests
    
    func testActionableCells() {
        // Test that actionable cells have disclosure indicators
        let testConnectionCell = settingsVC.tableView(settingsVC.tableView, cellForRowAt: IndexPath(row: 1, section: 0))
        XCTAssertEqual(testConnectionCell.accessoryType, .disclosureIndicator)
        
        let mcpCell = settingsVC.tableView(settingsVC.tableView, cellForRowAt: IndexPath(row: 0, section: 1))
        XCTAssertEqual(mcpCell.accessoryType, .disclosureIndicator)
        
        let integrationTestCell = settingsVC.tableView(settingsVC.tableView, cellForRowAt: IndexPath(row: 0, section: 3))
        XCTAssertEqual(integrationTestCell.accessoryType, .disclosureIndicator)
    }
    
    func testNonActionableCells() {
        // Test that non-actionable cells have no disclosure indicators
        let themeCell = settingsVC.tableView(settingsVC.tableView, cellForRowAt: IndexPath(row: 0, section: 2))
        XCTAssertEqual(themeCell.accessoryType, .none)
        
        let versionCell = settingsVC.tableView(settingsVC.tableView, cellForRowAt: IndexPath(row: 0, section: 4))
        XCTAssertEqual(versionCell.accessoryType, .none)
    }
}

// MARK: - Mock Settings API Client

class MockSettingsAPIClient: SettingsAPIClientProtocol {
    var mockConnectionTestResponse: [String: Any] = [:]
    var shouldSucceed = true
    var mockError: Error?
    var onConnectionTested: ((Bool) -> Void)?
    
    func testConnection(completion: @escaping (Bool, String?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.shouldSucceed {
                completion(true, "Found \(self.mockConnectionTestResponse["projects"]?.count ?? 0) project(s)")
            } else {
                completion(false, self.mockError?.localizedDescription ?? "Connection failed")
            }
            self.onConnectionTested?(self.shouldSucceed)
        }
    }
}

// Protocol for dependency injection
protocol SettingsAPIClientProtocol {
    func testConnection(completion: @escaping (Bool, String?) -> Void)
}

// Extension for testing
extension SettingsViewController {
    var apiClient: SettingsAPIClientProtocol? {
        get { return nil }
        set { /* In real code, would set internal client */ }
    }
}

// Mock TestRunnerViewController for testing
extension TestRunnerViewController {
    static var onPresented: (() -> Void)?
    
    static func present(from viewController: UIViewController) {
        // In real code, would present the view controller
        onPresented?()
    }
}

// Stub for TestRunnerViewController
class TestRunnerViewController: UIViewController {
    // Basic implementation for testing
}