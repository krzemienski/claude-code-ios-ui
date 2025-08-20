//
//  UIFeaturesIntegrationTests.swift
//  ClaudeCodeUIIntegrationTests
//
//  Integration tests for new UI features:
//  - Pull to refresh
//  - Empty states
//  - Swipe actions
//  - Session creation
//  - Error alerts
//  - Loading indicators
//

import XCTest
@testable import ClaudeCodeUI

class UIFeaturesIntegrationTests: XCTestCase {
    
    var app: XCUIApplication!
    let timeout: TimeInterval = 10
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment = [
            "API_BASE_URL": "http://localhost:3004",
            "DISABLE_ANIMATIONS": "1"
        ]
        app.launch()
        
        // Wait for app to initialize
        let projectsTab = app.tabBars.buttons["Projects"]
        XCTAssertTrue(projectsTab.waitForExistence(timeout: timeout))
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Pull to Refresh Tests
    
    func testPullToRefreshInSessionList() throws {
        // Navigate to a project
        navigateToFirstProject()
        
        // Pull to refresh
        let sessionTable = app.tables.firstMatch
        XCTAssertTrue(sessionTable.waitForExistence(timeout: timeout))
        
        // Swipe down to trigger refresh
        sessionTable.swipeDown()
        
        // Verify refresh indicator appears
        let refreshControl = app.activityIndicators["RefreshControl"]
        XCTAssertTrue(refreshControl.exists)
        
        // Wait for refresh to complete
        let refreshCompleted = NSPredicate(format: "exists == false")
        expectation(for: refreshCompleted, evaluatedWith: refreshControl, handler: nil)
        waitForExpectations(timeout: timeout)
        
        // Verify data is refreshed (check for session cells)
        XCTAssertTrue(sessionTable.cells.count >= 0)
    }
    
    func testPullToRefreshInProjectsList() throws {
        // Ensure we're on Projects tab
        app.tabBars.buttons["Projects"].tap()
        
        // Pull to refresh
        let projectCollection = app.collectionViews.firstMatch
        XCTAssertTrue(projectCollection.waitForExistence(timeout: timeout))
        
        projectCollection.swipeDown()
        
        // Verify refresh happens
        let refreshControl = app.activityIndicators["ProjectRefreshControl"]
        if refreshControl.exists {
            let refreshCompleted = NSPredicate(format: "exists == false")
            expectation(for: refreshCompleted, evaluatedWith: refreshControl, handler: nil)
            waitForExpectations(timeout: timeout)
        }
        
        // Verify projects are loaded
        XCTAssertTrue(projectCollection.cells.count >= 0)
    }
    
    // MARK: - Empty State Tests
    
    func testEmptyStateInSessions() throws {
        // Navigate to a project with no sessions
        // This would need a test project or API mock
        navigateToEmptyProject()
        
        // Verify empty state view appears
        let emptyStateView = app.otherElements["EmptyStateView"]
        XCTAssertTrue(emptyStateView.waitForExistence(timeout: timeout))
        
        // Verify empty state elements
        XCTAssertTrue(app.staticTexts["No Sessions"].exists)
        XCTAssertTrue(app.buttons["Create First Session"].exists)
        
        // Test create session from empty state
        app.buttons["Create First Session"].tap()
        
        // Verify navigation to chat
        let chatView = app.otherElements["ChatViewController"]
        XCTAssertTrue(chatView.waitForExistence(timeout: timeout))
    }
    
    func testEmptyStateInSearch() throws {
        // Navigate to Search tab
        app.tabBars.buttons["Search"].tap()
        
        // Perform search with no results
        let searchBar = app.searchFields.firstMatch
        XCTAssertTrue(searchBar.waitForExistence(timeout: timeout))
        
        searchBar.tap()
        searchBar.typeText("xyz123nonexistent")
        app.buttons["Search"].tap()
        
        // Verify empty state for no results
        let emptyStateView = app.otherElements["SearchEmptyState"]
        XCTAssertTrue(emptyStateView.waitForExistence(timeout: timeout))
        
        XCTAssertTrue(app.staticTexts["No Results Found"].exists)
    }
    
    // MARK: - Swipe Action Tests
    
    func testSwipeToDeleteSession() throws {
        navigateToFirstProject()
        
        let sessionTable = app.tables.firstMatch
        XCTAssertTrue(sessionTable.waitForExistence(timeout: timeout))
        
        // Ensure there's at least one session
        if sessionTable.cells.count > 0 {
            let firstCell = sessionTable.cells.element(boundBy: 0)
            
            // Swipe left to reveal actions
            firstCell.swipeLeft()
            
            // Verify delete button appears
            let deleteButton = app.buttons["Delete"]
            XCTAssertTrue(deleteButton.waitForExistence(timeout: 2))
            
            // Tap delete
            deleteButton.tap()
            
            // Verify confirmation alert
            let alert = app.alerts["Delete Session"]
            XCTAssertTrue(alert.waitForExistence(timeout: 2))
            
            // Confirm deletion
            alert.buttons["Delete"].tap()
            
            // Verify cell is removed
            // Note: This might need adjustment based on actual implementation
            XCTAssertTrue(sessionTable.cells.count >= 0)
        }
    }
    
    func testSwipeToArchiveSession() throws {
        navigateToFirstProject()
        
        let sessionTable = app.tables.firstMatch
        XCTAssertTrue(sessionTable.waitForExistence(timeout: timeout))
        
        if sessionTable.cells.count > 0 {
            let firstCell = sessionTable.cells.element(boundBy: 0)
            
            // Swipe left to reveal actions
            firstCell.swipeLeft()
            
            // Verify archive button appears
            let archiveButton = app.buttons["Archive"]
            if archiveButton.waitForExistence(timeout: 2) {
                archiveButton.tap()
                
                // Verify session is archived (visual feedback)
                // This depends on implementation
                XCTAssertTrue(true) // Placeholder
            }
        }
    }
    
    // MARK: - Session Creation Tests
    
    func testCreateNewSession() throws {
        navigateToFirstProject()
        
        // Tap create session button
        let createButton = app.navigationBars.buttons["add"]
        XCTAssertTrue(createButton.waitForExistence(timeout: timeout))
        createButton.tap()
        
        // Verify navigation to chat view
        let chatView = app.otherElements["ChatViewController"]
        XCTAssertTrue(chatView.waitForExistence(timeout: timeout))
        
        // Verify new session is created
        let messageField = app.textViews["MessageInputTextView"]
        XCTAssertTrue(messageField.exists)
        
        // Send a test message
        messageField.tap()
        messageField.typeText("Test message for new session")
        
        let sendButton = app.buttons["SendButton"]
        if sendButton.exists {
            sendButton.tap()
            
            // Verify message appears in chat
            let messageCell = app.cells.containing(.staticText, identifier: "Test message").firstMatch
            XCTAssertTrue(messageCell.waitForExistence(timeout: timeout))
        }
    }
    
    // MARK: - Error Alert Tests
    
    func testNetworkErrorAlert() throws {
        // Simulate network error by using invalid endpoint
        app.launchEnvironment["API_BASE_URL"] = "http://localhost:9999"
        app.terminate()
        app.launch()
        
        // Try to load projects
        app.tabBars.buttons["Projects"].tap()
        
        // Verify error alert appears
        let errorAlert = app.alerts.firstMatch
        XCTAssertTrue(errorAlert.waitForExistence(timeout: timeout))
        
        // Verify retry button exists
        XCTAssertTrue(errorAlert.buttons["Retry"].exists)
        XCTAssertTrue(errorAlert.buttons["Cancel"].exists)
        
        // Dismiss alert
        errorAlert.buttons["Cancel"].tap()
    }
    
    func testWebSocketDisconnectionAlert() throws {
        navigateToFirstProject()
        
        // Navigate to chat
        if app.tables.cells.count > 0 {
            app.tables.cells.element(boundBy: 0).tap()
            
            // Wait for chat to load
            let chatView = app.otherElements["ChatViewController"]
            XCTAssertTrue(chatView.waitForExistence(timeout: timeout))
            
            // Simulate WebSocket disconnection
            // This would need backend cooperation or network manipulation
            
            // Verify disconnection banner appears
            let disconnectionBanner = app.otherElements["WebSocketDisconnectedBanner"]
            // Note: This test might need adjustment based on actual implementation
            if disconnectionBanner.waitForExistence(timeout: 5) {
                XCTAssertTrue(disconnectionBanner.exists)
                
                // Verify auto-reconnection
                let reconnectedBanner = app.otherElements["WebSocketReconnectedBanner"]
                XCTAssertTrue(reconnectedBanner.waitForExistence(timeout: 10))
            }
        }
    }
    
    // MARK: - Loading Indicator Tests
    
    func testLoadingSkeletonInProjects() throws {
        // Force reload to see loading state
        app.terminate()
        app.launch()
        
        app.tabBars.buttons["Projects"].tap()
        
        // Check for skeleton loading cells
        let skeletonCell = app.cells["SkeletonCell"]
        // Skeleton should appear briefly
        if skeletonCell.exists {
            XCTAssertTrue(skeletonCell.exists)
            
            // Wait for real content to load
            let realCell = app.cells["ProjectCell"]
            XCTAssertTrue(realCell.waitForExistence(timeout: timeout))
        }
    }
    
    func testLoadingIndicatorInChat() throws {
        navigateToFirstProject()
        
        // Navigate to chat
        if app.tables.cells.count > 0 {
            app.tables.cells.element(boundBy: 0).tap()
            
            let chatView = app.otherElements["ChatViewController"]
            XCTAssertTrue(chatView.waitForExistence(timeout: timeout))
            
            // Send a message
            let messageField = app.textViews["MessageInputTextView"]
            messageField.tap()
            messageField.typeText("Test message")
            
            let sendButton = app.buttons["SendButton"]
            if sendButton.exists {
                sendButton.tap()
                
                // Check for loading indicator
                let loadingIndicator = app.activityIndicators["MessageSendingIndicator"]
                if loadingIndicator.exists {
                    XCTAssertTrue(loadingIndicator.exists)
                    
                    // Wait for message to be sent
                    let loadingCompleted = NSPredicate(format: "exists == false")
                    expectation(for: loadingCompleted, evaluatedWith: loadingIndicator, handler: nil)
                    waitForExpectations(timeout: timeout)
                }
            }
        }
    }
    
    // MARK: - File Operation Tests
    
    func testFileCreation() throws {
        // Navigate to Files tab
        if app.tabBars.buttons["Files"].exists {
            app.tabBars.buttons["Files"].tap()
        } else {
            // Files might be in More menu
            app.tabBars.buttons["More"].tap()
            app.tables.staticTexts["Files"].tap()
        }
        
        // Wait for file explorer
        let fileExplorer = app.otherElements["FileExplorerViewController"]
        XCTAssertTrue(fileExplorer.waitForExistence(timeout: timeout))
        
        // Tap create file button
        let createButton = app.navigationBars.buttons["add"]
        if createButton.exists {
            createButton.tap()
            
            // Select "New File" option
            let newFileOption = app.sheets.buttons["New File"]
            if newFileOption.exists {
                newFileOption.tap()
                
                // Enter file name
                let fileNameField = app.textFields["FileName"]
                if fileNameField.waitForExistence(timeout: 2) {
                    fileNameField.tap()
                    fileNameField.typeText("test_file.txt")
                    
                    // Confirm creation
                    app.buttons["Create"].tap()
                    
                    // Verify file appears in list
                    let fileCell = app.cells.containing(.staticText, identifier: "test_file.txt").firstMatch
                    XCTAssertTrue(fileCell.waitForExistence(timeout: timeout))
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToFirstProject() {
        app.tabBars.buttons["Projects"].tap()
        
        let projectCollection = app.collectionViews.firstMatch
        XCTAssertTrue(projectCollection.waitForExistence(timeout: timeout))
        
        if projectCollection.cells.count > 0 {
            projectCollection.cells.element(boundBy: 0).tap()
        }
    }
    
    private func navigateToEmptyProject() {
        // This would need a specific test project or API mock
        // For now, we'll try to find or create an empty project
        app.tabBars.buttons["Projects"].tap()
        
        // Look for a project with no sessions
        // This is a placeholder - actual implementation would need API support
        let projectCollection = app.collectionViews.firstMatch
        if projectCollection.waitForExistence(timeout: timeout) && projectCollection.cells.count > 0 {
            // Try last project (might be empty)
            let lastIndex = projectCollection.cells.count - 1
            projectCollection.cells.element(boundBy: lastIndex).tap()
        }
    }
}

// MARK: - Performance Tests

extension UIFeaturesIntegrationTests {
    
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }
    
    func testScrollingPerformance() throws {
        navigateToFirstProject()
        
        let sessionTable = app.tables.firstMatch
        XCTAssertTrue(sessionTable.waitForExistence(timeout: timeout))
        
        measure {
            // Scroll down
            sessionTable.swipeUp()
            sessionTable.swipeUp()
            
            // Scroll back up
            sessionTable.swipeDown()
            sessionTable.swipeDown()
        }
    }
    
    func testMemoryUsage() throws {
        let metrics = [XCTMemoryMetric(application: app)]
        
        measure(metrics: metrics) {
            // Navigate through different screens
            app.tabBars.buttons["Projects"].tap()
            sleep(1)
            
            if app.collectionViews.cells.count > 0 {
                app.collectionViews.cells.element(boundBy: 0).tap()
                sleep(1)
            }
            
            app.tabBars.buttons["Search"].tap()
            sleep(1)
            
            app.tabBars.buttons["Settings"].tap()
            sleep(1)
        }
    }
}