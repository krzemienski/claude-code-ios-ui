import XCTest

/// Unified functional test suite that coordinates all functional tests
/// This suite ensures proper test execution order and dependencies
class FunctionalTestSuite: XCTestCase {
    
    /// Configure the default test suite with all functional tests
    override class var defaultTestSuite: XCTestSuite {
        let suite = XCTestSuite(name: "Functional Tests")
        
        // Phase 1: Core Unit Tests
        let unitTestPhase = XCTestSuite(name: "Unit Tests")
        unitTestPhase.addTest(ChatViewModelTests.defaultTestSuite)
        unitTestPhase.addTest(WebSocketMessageParserTests.defaultTestSuite)
        suite.addTest(unitTestPhase)
        
        // Phase 2: Integration Tests (in dependency order)
        // NOTE: Integration tests are in a separate target and cannot be referenced here
        // They should be run separately from the ClaudeCodeUIIntegrationTests target
        
        // Phase 3: Message Persistence Tests (available in this target)
        let persistencePhase = XCTestSuite(name: "Persistence Tests")
        persistencePhase.addTest(MessagePersistenceIntegrationTests.defaultTestSuite)
        suite.addTest(persistencePhase)
        
        return suite
    }
    
    /// Pre-test setup to ensure backend is running
    override class func setUp() {
        super.setUp()
        
        // Verify backend is accessible
        let backendURL = URL(string: "http://192.168.0.155:3004/health")!
        let semaphore = DispatchSemaphore(value: 0)
        var backendAvailable = false
        
        let task = URLSession.shared.dataTask(with: backendURL) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                backendAvailable = true
            }
            semaphore.signal()
        }
        task.resume()
        
        _ = semaphore.wait(timeout: .now() + 5)
        
        if !backendAvailable {
            XCTFail("Backend is not running at http://192.168.0.155:3004. Please start the backend before running tests.")
        }
    }
    
    /// Post-test cleanup
    override class func tearDown() {
        super.tearDown()
        
        // Clean up any test data
        cleanupTestData()
    }
    
    /// Clean up test data from backend
    private class func cleanupTestData() {
        // Implementation for cleaning test data
        // This would typically involve API calls to reset test state
    }
}

/// Test suite runner for command line execution
class FunctionalTestRunner {
    
    static func runAllTests() -> Bool {
        let suite = FunctionalTestSuite.defaultTestSuite
        let runner = XCTestSuiteRun(test: suite)
        
        suite.run()
        
        let passCount = runner.totalFailureCount == 0
        
        print("===============================================")
        print("Functional Test Results:")
        print("===============================================")
        print("Total Tests: \(runner.testCaseCount)")
        print("Passed: \(runner.testCaseCount - runner.totalFailureCount)")
        print("Failed: \(runner.totalFailureCount)")
        print("Execution Time: \(runner.testDuration)s")
        print("===============================================")
        
        return passCount
    }
}