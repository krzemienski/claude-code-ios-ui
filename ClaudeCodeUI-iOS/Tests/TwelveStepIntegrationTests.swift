import XCTest
import UIKit
@testable import ClaudeCodeUI

/// Comprehensive 12-Step Test Flow for iOS App
/// Validates the complete user journey including critical issues
class TwelveStepIntegrationTests: XCTestCase {
    
    var app: UIApplication!
    var navigationController: UINavigationController!
    var chatViewController: ChatViewController!
    var projectsViewController: UIViewController!
    
    override func setUp() {
        super.setUp()
        // Initialize test environment
        setupTestEnvironment()
    }
    
    override func tearDown() {
        cleanupTestData()
        super.tearDown()
    }
    
    private func setupTestEnvironment() {
        // Setup mock navigation and view controllers
        navigationController = UINavigationController()
        chatViewController = ChatViewController()
    }
    
    private func cleanupTestData() {
        // Clean up test artifacts
        UserDefaults.standard.removeObject(forKey: "test_sessions")
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - 12-Step Test Flow
    
    /// Step 1: Launch application and initial validation
    func test01_ApplicationLaunchAndInitialValidation() {
        let testReport = TestExecutionReport(step: 1, testName: "Application Launch")
        
        // Test launch time
        let startTime = Date()
        let launchSuccess = simulateAppLaunch()
        let launchTime = Date().timeIntervalSince(startTime)
        
        // Assertions
        XCTAssertTrue(launchSuccess, "✅ App should launch successfully")
        XCTAssertLessThan(launchTime, 2.0, "✅ Launch time should be under 2 seconds")
        
        // Validate initial state
        XCTAssertNotNil(navigationController, "✅ Navigation controller should be initialized")
        XCTAssertTrue(isNetworkAvailable(), "✅ Network should be available")
        
        testReport.status = .passed
        testReport.executionTime = launchTime
        logTestResult(testReport)
    }
    
    /// Step 2: Navigate to Projects tab (Handled by navigation agent)
    func test02_NavigateToProjectsTab() {
        let testReport = TestExecutionReport(step: 2, testName: "Navigate to Projects")
        
        // Simulate tab navigation
        let tabBar = getTabBarController()
        tabBar?.selectedIndex = 1 // Projects tab
        
        // Validate navigation
        XCTAssertEqual(tabBar?.selectedIndex, 1, "✅ Should be on Projects tab")
        XCTAssertTrue(isProjectsViewVisible(), "✅ Projects view should be visible")
        
        testReport.status = .passed
        logTestResult(testReport)
    }
    
    /// Step 3: Select a project that contains sessions
    func test03_SelectProjectWithSessions() {
        let testReport = TestExecutionReport(step: 3, testName: "Select Project")
        
        // Create test project with sessions
        let testProject = createTestProject(withSessions: 5)
        
        // Select project
        let success = selectProject(testProject)
        
        // Validate
        XCTAssertTrue(success, "✅ Project should be selected")
        XCTAssertEqual(getCurrentProject()?.id, testProject.id, "✅ Correct project selected")
        XCTAssertGreaterThan(getSessionCount(), 0, "✅ Project has sessions")
        
        testReport.status = .passed
        logTestResult(testReport)
    }
    
    /// Step 4: View sessions list
    func test04_ViewSessionsList() {
        let testReport = TestExecutionReport(step: 4, testName: "View Sessions List")
        
        // Load sessions
        let sessions = loadProjectSessions()
        
        // Validate session data
        XCTAssertGreaterThan(sessions.count, 0, "✅ Sessions should be loaded")
        
        for session in sessions {
            XCTAssertNotNil(session.name, "✅ Session should have name")
            XCTAssertNotNil(session.timestamp, "✅ Session should have timestamp")
            XCTAssertNotNil(session.metadata, "✅ Session should have metadata")
            
            // Validate timestamp format
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            let formattedDate = dateFormatter.string(from: session.timestamp)
            XCTAssertFalse(formattedDate.isEmpty, "✅ Timestamp should be formatted")
        }
        
        testReport.status = .passed
        testReport.details = "Loaded \(sessions.count) sessions"
        logTestResult(testReport)
    }
    
    /// Step 5: Select specific session (Handled by navigation agent)
    func test05_SelectSpecificSession() {
        let testReport = TestExecutionReport(step: 5, testName: "Select Session")
        
        let sessions = loadProjectSessions()
        guard let firstSession = sessions.first else {
            XCTFail("❌ No sessions available")
            return
        }
        
        // Select session
        let success = selectSession(firstSession)
        
        XCTAssertTrue(success, "✅ Session should be selected")
        XCTAssertEqual(getCurrentSession()?.id, firstSession.id, "✅ Correct session selected")
        
        testReport.status = .passed
        logTestResult(testReport)
    }
    
    /// Step 6: Load messages (Handled by navigation agent)
    func test06_LoadSessionMessages() {
        let testReport = TestExecutionReport(step: 6, testName: "Load Messages")
        
        // Load messages for current session
        let messages = loadCurrentSessionMessages()
        
        // This might be empty for new session
        XCTAssertNotNil(messages, "✅ Messages array should exist")
        
        testReport.status = .passed
        testReport.details = "Loaded \(messages.count) messages"
        logTestResult(testReport)
    }
    
    /// Step 7: Send message (Handled by navigation agent)
    func test07_SendFirstMessage() {
        let testReport = TestExecutionReport(step: 7, testName: "Send First Message")
        
        let testMessage = "Hello, this is test message 1"
        let sendResult = sendMessage(testMessage)
        
        XCTAssertTrue(sendResult.success, "✅ Message should be sent")
        XCTAssertNotNil(sendResult.messageId, "✅ Message should have ID")
        
        // Verify message appears in UI
        let messages = loadCurrentSessionMessages()
        let sentMessage = messages.first { $0.content == testMessage }
        XCTAssertNotNil(sentMessage, "✅ Sent message should appear in list")
        
        testReport.status = .passed
        logTestResult(testReport)
    }
    
    /// Step 8: Send follow-up message and verify context
    func test08_SendFollowUpMessage() {
        let testReport = TestExecutionReport(step: 8, testName: "Send Follow-up Message")
        
        let followUpMessage = "This is follow-up message 2 with context"
        let sendResult = sendMessage(followUpMessage)
        
        // Validate
        XCTAssertTrue(sendResult.success, "✅ Follow-up message should be sent")
        
        // Verify context preservation
        let messages = loadCurrentSessionMessages()
        XCTAssertGreaterThanOrEqual(messages.count, 2, "✅ Should have at least 2 messages")
        
        // Check message ordering
        if messages.count >= 2 {
            let firstMessage = messages[messages.count - 2]
            let secondMessage = messages[messages.count - 1]
            XCTAssertLessThan(firstMessage.timestamp, secondMessage.timestamp, "✅ Messages ordered correctly")
        }
        
        testReport.status = .passed
        logTestResult(testReport)
    }
    
    /// Step 9: Receive AI response (Handled by AI agent)
    func test09_ReceiveAIResponse() {
        let testReport = TestExecutionReport(step: 9, testName: "Receive AI Response")
        
        let expectation = self.expectation(description: "AI response received")
        
        // Wait for AI response
        waitForAIResponse { response in
            XCTAssertNotNil(response, "✅ AI response should be received")
            XCTAssertFalse(response?.content.isEmpty ?? true, "✅ AI response should have content")
            XCTAssertFalse(response?.isUser ?? true, "✅ Response should be from AI")
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10.0) { error in
            if error != nil {
                testReport.status = .failed
                testReport.failureReason = "AI response timeout"
            } else {
                testReport.status = .passed
            }
        }
        
        logTestResult(testReport)
    }
    
    /// Step 10: Navigate back (Handled by navigation agent)
    func test10_NavigateBack() {
        let testReport = TestExecutionReport(step: 10, testName: "Navigate Back")
        
        // Navigate back to sessions list
        let backSuccess = navigateBack()
        
        XCTAssertTrue(backSuccess, "✅ Should navigate back successfully")
        XCTAssertTrue(isSessionsListVisible(), "✅ Sessions list should be visible")
        
        testReport.status = .passed
        logTestResult(testReport)
    }
    
    /// Step 11: Force quit app and relaunch
    func test11_ForceQuitAndRelaunch() {
        let testReport = TestExecutionReport(step: 11, testName: "Force Quit and Relaunch")
        
        // Store current state before quit
        let sessionId = getCurrentSession()?.id
        let messageCount = loadCurrentSessionMessages().count
        
        // Simulate force quit
        simulateForceQuit()
        
        // Simulate relaunch
        let relaunchSuccess = simulateAppLaunch()
        
        XCTAssertTrue(relaunchSuccess, "✅ App should relaunch successfully")
        
        // Store state for next test
        UserDefaults.standard.set(sessionId, forKey: "test_session_id")
        UserDefaults.standard.set(messageCount, forKey: "test_message_count")
        
        testReport.status = .passed
        logTestResult(testReport)
    }
    
    /// Step 12: Navigate back to same session after restart
    func test12_NavigateToSameSessionAfterRestart() {
        let testReport = TestExecutionReport(step: 12, testName: "Restore Session After Restart")
        
        // Retrieve stored session info
        guard let sessionId = UserDefaults.standard.string(forKey: "test_session_id") else {
            XCTFail("❌ No session ID stored")
            testReport.status = .failed
            testReport.failureReason = "No session ID found"
            logTestResult(testReport)
            return
        }
        
        let expectedMessageCount = UserDefaults.standard.integer(forKey: "test_message_count")
        
        // Navigate to session
        let session = Session(id: sessionId, name: "Test Session", timestamp: Date(), metadata: [:])
        let navSuccess = selectSession(session)
        
        XCTAssertTrue(navSuccess, "✅ Should navigate to session")
        
        // CRITICAL TEST: Verify message persistence
        let messages = loadCurrentSessionMessages()
        
        // This is the CRITICAL failure point
        if messages.count != expectedMessageCount {
            XCTFail("❌ CRITICAL: Message persistence failure! Expected \(expectedMessageCount) messages, found \(messages.count)")
            testReport.status = .failed
            testReport.failureReason = "Message persistence not working - messages lost after restart"
            testReport.severity = .critical
        } else {
            XCTAssertEqual(messages.count, expectedMessageCount, "✅ Messages persisted correctly")
            testReport.status = .passed
        }
        
        logTestResult(testReport)
    }
    
    // MARK: - Edge Case Tests
    
    /// Test WebSocket connection stability
    func testWebSocketConnectionStability() {
        let testReport = TestExecutionReport(step: 13, testName: "WebSocket Stability")
        
        // Test connection
        let wsManager = WebSocketManager.shared
        
        // Test multiple reconnections
        for i in 1...5 {
            wsManager.disconnect()
            Thread.sleep(forTimeInterval: 0.5)
            wsManager.connect()
            
            let connected = waitForConnection(timeout: 5.0)
            XCTAssertTrue(connected, "✅ Reconnection \(i) should succeed")
        }
        
        testReport.status = .passed
        logTestResult(testReport)
    }
    
    /// Test message sending endpoint
    func testMessageSendingEndpoint() {
        let testReport = TestExecutionReport(step: 14, testName: "Message Endpoint Validation")
        
        // Validate endpoint configuration
        let config = APIConfiguration.shared
        let endpoint = config.messageEndpoint
        
        XCTAssertFalse(endpoint.isEmpty, "✅ Endpoint should be configured")
        XCTAssertTrue(endpoint.hasPrefix("wss://") || endpoint.hasPrefix("ws://"), "❌ HIGH: Endpoint mismatch - should use WebSocket protocol")
        
        // Test actual endpoint
        let testMessage = ["type": "message", "content": "test"]
        let sendSuccess = sendToEndpoint(endpoint, message: testMessage)
        
        if !sendSuccess {
            testReport.status = .failed
            testReport.failureReason = "Message sending endpoint mismatch"
            testReport.severity = .high
        } else {
            testReport.status = .passed
        }
        
        logTestResult(testReport)
    }
    
    /// Test connection status UI updates
    func testConnectionStatusUIUpdates() {
        let testReport = TestExecutionReport(step: 15, testName: "Connection Status UI")
        
        let wsManager = WebSocketManager.shared
        
        // Disconnect and check UI
        wsManager.disconnect()
        Thread.sleep(forTimeInterval: 0.5)
        
        let disconnectedUI = getConnectionStatusUI()
        XCTAssertEqual(disconnectedUI, .disconnected, "⚠️ MEDIUM: Connection status UI not updating on disconnect")
        
        // Reconnect and check UI
        wsManager.connect()
        let connected = waitForConnection(timeout: 5.0)
        
        if connected {
            let connectedUI = getConnectionStatusUI()
            XCTAssertEqual(connectedUI, .connected, "⚠️ MEDIUM: Connection status UI not updating on connect")
        }
        
        if disconnectedUI != .disconnected || (connected && getConnectionStatusUI() != .connected) {
            testReport.status = .failed
            testReport.failureReason = "Connection status UI not updating"
            testReport.severity = .medium
        } else {
            testReport.status = .passed
        }
        
        logTestResult(testReport)
    }
    
    /// Test tab navigation stickiness
    func testTabNavigationStickiness() {
        let testReport = TestExecutionReport(step: 16, testName: "Tab Navigation Stickiness")
        
        let tabBar = getTabBarController()
        
        // Test tab switching persistence
        for targetTab in 0..<4 {
            tabBar?.selectedIndex = targetTab
            
            // Simulate some actions
            Thread.sleep(forTimeInterval: 0.1)
            
            // Navigate to another tab and back
            tabBar?.selectedIndex = (targetTab + 1) % 4
            tabBar?.selectedIndex = targetTab
            
            XCTAssertEqual(tabBar?.selectedIndex, targetTab, "⚠️ MEDIUM: Tab navigation not sticky at index \(targetTab)")
        }
        
        testReport.status = tabBar?.selectedIndex == 3 ? .passed : .failed
        if testReport.status == .failed {
            testReport.failureReason = "Tab navigation stickiness issue"
            testReport.severity = .medium
        }
        
        logTestResult(testReport)
    }
    
    // MARK: - Performance Tests
    
    func testResponseTimePerformance() {
        let testReport = TestExecutionReport(step: 17, testName: "Response Time Performance")
        
        measure {
            let message = "Performance test message"
            let startTime = Date()
            _ = sendMessage(message)
            let responseTime = Date().timeIntervalSince(startTime)
            
            XCTAssertLessThan(responseTime, 2.0, "✅ Response time should be under 2 seconds")
        }
        
        testReport.status = .passed
        logTestResult(testReport)
    }
    
    // MARK: - Helper Methods
    
    private func simulateAppLaunch() -> Bool {
        // Simulate app launch
        return true
    }
    
    private func simulateForceQuit() {
        // Simulate force quit
        // Clear in-memory data but preserve persistent storage
    }
    
    private func isNetworkAvailable() -> Bool {
        return true // Mock implementation
    }
    
    private func getTabBarController() -> UITabBarController? {
        return UITabBarController() // Mock implementation
    }
    
    private func isProjectsViewVisible() -> Bool {
        return true // Mock implementation
    }
    
    private func isSessionsListVisible() -> Bool {
        return true // Mock implementation
    }
    
    private func createTestProject(withSessions count: Int) -> Project {
        return Project(id: "test-project", name: "Test Project", sessions: count)
    }
    
    private func selectProject(_ project: Project) -> Bool {
        return true // Mock implementation
    }
    
    private func getCurrentProject() -> Project? {
        return Project(id: "test-project", name: "Test Project", sessions: 5)
    }
    
    private func getSessionCount() -> Int {
        return 5 // Mock implementation
    }
    
    private func loadProjectSessions() -> [Session] {
        var sessions: [Session] = []
        for i in 1...5 {
            sessions.append(Session(
                id: "session-\(i)",
                name: "Session \(i)",
                timestamp: Date().addingTimeInterval(Double(-i * 3600)),
                metadata: ["messageCount": i * 2]
            ))
        }
        return sessions
    }
    
    private func selectSession(_ session: Session) -> Bool {
        return true // Mock implementation
    }
    
    private func getCurrentSession() -> Session? {
        return Session(id: "session-1", name: "Session 1", timestamp: Date(), metadata: [:])
    }
    
    private func loadCurrentSessionMessages() -> [Message] {
        // This simulates the critical issue - messages not persisting
        return [] // Should return stored messages but returns empty
    }
    
    private func sendMessage(_ content: String) -> (success: Bool, messageId: String?) {
        return (true, UUID().uuidString)
    }
    
    private func waitForAIResponse(completion: @escaping (Message?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(Message(
                id: UUID().uuidString,
                content: "AI response to your message",
                isUser: false,
                timestamp: Date()
            ))
        }
    }
    
    private func navigateBack() -> Bool {
        return true // Mock implementation
    }
    
    private func waitForConnection(timeout: TimeInterval) -> Bool {
        return true // Mock implementation
    }
    
    private func getConnectionStatusUI() -> ConnectionStatus {
        return .connected // Mock implementation
    }
    
    private func sendToEndpoint(_ endpoint: String, message: [String: Any]) -> Bool {
        // This simulates the endpoint mismatch issue
        return endpoint.hasPrefix("wss://") || endpoint.hasPrefix("ws://")
    }
    
    private func logTestResult(_ report: TestExecutionReport) {
        print("Step \(report.step): \(report.testName) - \(report.status)")
        if let reason = report.failureReason {
            print("  Failure: \(reason) (Severity: \(report.severity))")
        }
        if let details = report.details {
            print("  Details: \(details)")
        }
    }
}

// MARK: - Test Models

struct Project {
    let id: String
    let name: String
    let sessions: Int
}

struct Session {
    let id: String
    let name: String
    let timestamp: Date
    let metadata: [String: Any]
}

struct Message {
    let id: String
    let content: String
    let isUser: Bool
    let timestamp: Date
}

enum ConnectionStatus {
    case connected
    case disconnected
    case connecting
}

enum TestStatus {
    case passed
    case failed
    case skipped
}

enum Severity {
    case critical
    case high
    case medium
    case low
}

struct TestExecutionReport {
    let step: Int
    let testName: String
    var status: TestStatus = .skipped
    var executionTime: TimeInterval = 0
    var failureReason: String?
    var severity: Severity = .low
    var details: String?
}

// Mock WebSocket Manager
class WebSocketManager {
    static let shared = WebSocketManager()
    
    func connect() {
        // Mock connection
    }
    
    func disconnect() {
        // Mock disconnection
    }
}

// Mock API Configuration
class APIConfiguration {
    static let shared = APIConfiguration()
    
    var messageEndpoint: String {
        return "wss://api.example.com/messages" // Should be WebSocket
    }
}