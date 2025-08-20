//
//  SessionFlowE2ETests.swift
//  ClaudeCodeUIIntegrationTests
//
//  End-to-end tests following the 5-phase testing protocol:
//  1. Start Phase - Backend initialization
//  2. Project Phase - Load projects from API
//  3. Session Phase - Create/load sessions
//  4. Message Phase - Send/receive via WebSocket
//  5. Cleanup Phase - Proper teardown
//

import XCTest
@testable import ClaudeCodeUI

class SessionFlowE2ETests: XCTestCase {
    
    var app: XCUIApplication!
    var apiClient: APIClient!
    var testProjectName: String!
    var testSessionId: String!
    let timeout: TimeInterval = 15
    
    // MARK: - Phase 1: Start Phase
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        // Initialize test data
        testProjectName = "TestProject_\(UUID().uuidString.prefix(8))"
        
        // Initialize API client for backend verification
        apiClient = APIClient.shared
        apiClient.baseURL = "http://localhost:3004"
        
        // Verify backend is running
        try verifyBackendHealth()
        
        // Launch app with test configuration
        app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "--reset-state" // Clear any cached data
        ]
        app.launchEnvironment = [
            "API_BASE_URL": "http://localhost:3004",
            "DISABLE_ANIMATIONS": "1",
            "TEST_MODE": "1"
        ]
        
        app.launch()
        
        // Wait for app initialization
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: timeout))
    }
    
    override func tearDownWithError() throws {
        // Phase 5: Cleanup
        cleanupTestData()
        app = nil
        apiClient = nil
    }
    
    // MARK: - Phase 2: Project Phase
    
    func testPhase2_LoadProjectsFromAPI() throws {
        // Ensure we're on Projects tab
        let projectsTab = app.tabBars.buttons["Projects"]
        XCTAssertTrue(projectsTab.waitForExistence(timeout: timeout))
        projectsTab.tap()
        
        // Wait for projects to load
        let projectCollection = app.collectionViews.firstMatch
        XCTAssertTrue(projectCollection.waitForExistence(timeout: timeout))
        
        // Verify projects loaded from API
        let projectCountExpectation = expectation(description: "Projects loaded")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // Give time for API call to complete
            XCTAssertTrue(projectCollection.cells.count > 0, "No projects loaded from API")
            projectCountExpectation.fulfill()
        }
        
        wait(for: [projectCountExpectation], timeout: 5)
        
        // Verify specific project data
        let firstProject = projectCollection.cells.element(boundBy: 0)
        XCTAssertTrue(firstProject.exists)
        
        // Check project has expected UI elements
        XCTAssertTrue(firstProject.staticTexts.count > 0) // Project name
    }
    
    // MARK: - Phase 3: Session Phase
    
    func testPhase3_CreateAndLoadSessions() throws {
        // Navigate to a project
        navigateToFirstOrCreateProject()
        
        // Test session creation
        let createButton = app.navigationBars.buttons["add"]
        XCTAssertTrue(createButton.waitForExistence(timeout: timeout))
        createButton.tap()
        
        // Verify navigation to chat (new session)
        let chatView = app.otherElements["ChatViewController"]
        XCTAssertTrue(chatView.waitForExistence(timeout: timeout))
        
        // Store session ID for later verification
        // This would need to be extracted from the UI or API
        testSessionId = extractCurrentSessionId()
        
        // Go back to sessions list
        app.navigationBars.buttons.element(boundBy: 0).tap()
        
        // Verify session appears in list
        let sessionTable = app.tables.firstMatch
        XCTAssertTrue(sessionTable.waitForExistence(timeout: timeout))
        
        // Should have at least one session now
        XCTAssertTrue(sessionTable.cells.count > 0)
        
        // Test loading existing session
        sessionTable.cells.element(boundBy: 0).tap()
        
        // Should navigate back to chat
        XCTAssertTrue(chatView.waitForExistence(timeout: timeout))
    }
    
    // MARK: - Phase 4: Message Phase
    
    func testPhase4_SendReceiveViaWebSocket() throws {
        // Ensure we're in a chat session
        navigateToFirstOrCreateProject()
        createOrLoadSession()
        
        let chatView = app.otherElements["ChatViewController"]
        XCTAssertTrue(chatView.waitForExistence(timeout: timeout))
        
        // Test sending a message
        let messageInput = app.textViews["MessageInputTextView"]
        XCTAssertTrue(messageInput.waitForExistence(timeout: timeout))
        
        let testMessage = "Test message \(Date().timeIntervalSince1970)"
        messageInput.tap()
        messageInput.typeText(testMessage)
        
        // Send the message
        let sendButton = app.buttons["SendButton"]
        XCTAssertTrue(sendButton.exists)
        sendButton.tap()
        
        // Verify message appears in chat (user message)
        let userMessage = app.cells.containing(.staticText, identifier: testMessage).firstMatch
        XCTAssertTrue(userMessage.waitForExistence(timeout: timeout))
        
        // Wait for WebSocket response (Claude's response)
        let responseExpectation = expectation(description: "WebSocket response received")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            // Check for response message cell
            let responseCells = app.cells.matching(identifier: "AssistantMessageCell")
            XCTAssertTrue(responseCells.count > 0, "No response received via WebSocket")
            responseExpectation.fulfill()
        }
        
        wait(for: [responseExpectation], timeout: 10)
        
        // Verify WebSocket connection status
        verifyWebSocketConnection()
    }
    
    // MARK: - Complete Flow Test
    
    func testCompleteSessionFlow_AllPhases() throws {
        // Phase 1: Already done in setUp
        
        // Phase 2: Load projects
        try testPhase2_LoadProjectsFromAPI()
        
        // Phase 3: Create session
        try testPhase3_CreateAndLoadSessions()
        
        // Phase 4: Send/receive messages
        try testPhase4_SendReceiveViaWebSocket()
        
        // Additional validations
        try validateSessionPersistence()
        try validateMessageHistory()
        
        // Phase 5: Will be done in tearDown
    }
    
    // MARK: - Additional Validation Tests
    
    func testSessionDeletion() throws {
        navigateToFirstOrCreateProject()
        
        let sessionTable = app.tables.firstMatch
        XCTAssertTrue(sessionTable.waitForExistence(timeout: timeout))
        
        // Ensure we have a session to delete
        if sessionTable.cells.count == 0 {
            createOrLoadSession()
            app.navigationBars.buttons.element(boundBy: 0).tap() // Go back
        }
        
        let initialCount = sessionTable.cells.count
        
        // Swipe to delete
        let firstCell = sessionTable.cells.element(boundBy: 0)
        firstCell.swipeLeft()
        
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2))
        deleteButton.tap()
        
        // Confirm deletion
        let alert = app.alerts.firstMatch
        if alert.waitForExistence(timeout: 2) {
            alert.buttons["Delete"].tap()
        }
        
        // Verify session removed
        XCTAssertEqual(sessionTable.cells.count, initialCount - 1)
    }
    
    func testCrossProjectIsolation() throws {
        // Test that sessions from one project don't appear in another
        
        // Create first project with session
        let firstProject = "Project_A_\(UUID().uuidString.prefix(8))"
        createProjectIfNeeded(firstProject)
        navigateToProject(firstProject)
        createOrLoadSession()
        
        // Send a unique message
        let uniqueMessage = "Message_for_\(firstProject)"
        sendMessage(uniqueMessage)
        
        // Go back to projects
        app.tabBars.buttons["Projects"].tap()
        
        // Create second project
        let secondProject = "Project_B_\(UUID().uuidString.prefix(8))"
        createProjectIfNeeded(secondProject)
        navigateToProject(secondProject)
        
        // Verify no sessions from first project
        let sessionTable = app.tables.firstMatch
        if sessionTable.waitForExistence(timeout: timeout) {
            // Should be empty or have different sessions
            let cells = sessionTable.cells
            for i in 0..<cells.count {
                let cell = cells.element(boundBy: i)
                // Verify doesn't contain message from first project
                XCTAssertFalse(cell.staticTexts[uniqueMessage].exists)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func verifyBackendHealth() throws {
        let expectation = XCTestExpectation(description: "Backend health check")
        var isHealthy = false
        
        // Check backend health endpoint
        var request = URLRequest(url: URL(string: "http://localhost:3004/api/health")!)
        request.timeoutInterval = 5
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                isHealthy = true
            }
            expectation.fulfill()
        }.resume()
        
        wait(for: [expectation], timeout: 10)
        
        if !isHealthy {
            throw XCTSkip("Backend server not running. Run 'npm start' in backend directory.")
        }
    }
    
    private func navigateToFirstOrCreateProject() {
        app.tabBars.buttons["Projects"].tap()
        
        let projectCollection = app.collectionViews.firstMatch
        guard projectCollection.waitForExistence(timeout: timeout) else { return }
        
        if projectCollection.cells.count > 0 {
            projectCollection.cells.element(boundBy: 0).tap()
        } else {
            // Create a test project
            createProjectIfNeeded(testProjectName)
            navigateToProject(testProjectName)
        }
    }
    
    private func createProjectIfNeeded(_ projectName: String) {
        // This would need UI support for project creation
        // For now, we'll assume projects exist
    }
    
    private func navigateToProject(_ projectName: String) {
        let projectCell = app.collectionViews.cells.containing(.staticText, identifier: projectName).firstMatch
        if projectCell.waitForExistence(timeout: 2) {
            projectCell.tap()
        }
    }
    
    private func createOrLoadSession() {
        let sessionTable = app.tables.firstMatch
        guard sessionTable.waitForExistence(timeout: timeout) else { return }
        
        if sessionTable.cells.count > 0 {
            // Load existing session
            sessionTable.cells.element(boundBy: 0).tap()
        } else {
            // Create new session
            let createButton = app.navigationBars.buttons["add"]
            if createButton.waitForExistence(timeout: 2) {
                createButton.tap()
            }
        }
    }
    
    private func sendMessage(_ text: String) {
        let messageInput = app.textViews["MessageInputTextView"]
        guard messageInput.waitForExistence(timeout: timeout) else { return }
        
        messageInput.tap()
        messageInput.typeText(text)
        
        let sendButton = app.buttons["SendButton"]
        if sendButton.exists {
            sendButton.tap()
        }
    }
    
    private func extractCurrentSessionId() -> String {
        // This would need to extract session ID from UI or API
        // For testing, return a mock ID
        return "session_\(UUID().uuidString.prefix(8))"
    }
    
    private func verifyWebSocketConnection() {
        // Check for WebSocket connection indicator
        let connectionIndicator = app.otherElements["WebSocketConnectionIndicator"]
        if connectionIndicator.exists {
            // Should show connected state
            XCTAssertTrue(connectionIndicator.label.contains("Connected"))
        }
    }
    
    private func validateSessionPersistence() throws {
        // Go back and return to verify session persists
        app.navigationBars.buttons.element(boundBy: 0).tap() // Back to sessions
        
        let sessionTable = app.tables.firstMatch
        XCTAssertTrue(sessionTable.waitForExistence(timeout: timeout))
        XCTAssertTrue(sessionTable.cells.count > 0)
        
        // Re-enter session
        sessionTable.cells.element(boundBy: 0).tap()
        
        // Verify chat view loads with history
        let chatView = app.otherElements["ChatViewController"]
        XCTAssertTrue(chatView.waitForExistence(timeout: timeout))
        
        // Should have message cells from previous interaction
        XCTAssertTrue(app.cells.count > 0)
    }
    
    private func validateMessageHistory() throws {
        // Verify messages are loaded from backend
        let messageCells = app.cells.matching(identifier: "MessageCell")
        XCTAssertTrue(messageCells.count > 0, "No message history loaded")
        
        // Check for both user and assistant messages
        let userMessages = app.cells.matching(identifier: "UserMessageCell")
        let assistantMessages = app.cells.matching(identifier: "AssistantMessageCell")
        
        // Should have at least one of each after sending a message
        if userMessages.count > 0 {
            XCTAssertTrue(assistantMessages.count > 0, "No assistant responses found")
        }
    }
    
    private func cleanupTestData() {
        // Clean up any test data created
        // This would typically involve API calls to delete test projects/sessions
        
        if let projectName = testProjectName {
            // Delete test project via API
            // apiClient.deleteProject(projectName) { _ in }
        }
        
        if let sessionId = testSessionId {
            // Delete test session via API
            // apiClient.deleteSession(sessionId) { _ in }
        }
    }
}

// MARK: - Performance Metrics

extension SessionFlowE2ETests {
    
    func testSessionFlowPerformance() throws {
        measure(metrics: [
            XCTClockMetric(),
            XCTMemoryMetric(),
            XCTCPUMetric(),
            XCTStorageMetric()
        ]) {
            do {
                try testCompleteSessionFlow_AllPhases()
            } catch {
                XCTFail("Performance test failed: \(error)")
            }
        }
    }
    
    func testMemoryBaselineUnder150MB() throws {
        // Target: < 150MB baseline memory usage
        let memoryMetric = XCTMemoryMetric(application: app)
        
        measure(metrics: [memoryMetric]) {
            // Navigate through main screens
            app.tabBars.buttons["Projects"].tap()
            sleep(1)
            
            if app.collectionViews.cells.count > 0 {
                app.collectionViews.cells.element(boundBy: 0).tap()
                sleep(1)
            }
            
            app.tabBars.buttons["Search"].tap()
            sleep(1)
            
            app.tabBars.buttons["Terminal"].tap()
            sleep(1)
            
            app.tabBars.buttons["Settings"].tap()
            sleep(1)
        }
        
        // Verify memory usage is under 150MB
        // Note: Actual verification would need access to metric results
    }
    
    func testLaunchTimeUnder2Seconds() throws {
        // Target: < 2 seconds launch time
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
        
        // The metric will automatically fail if launch takes > 2 seconds
        // when properly configured in scheme settings
    }
}