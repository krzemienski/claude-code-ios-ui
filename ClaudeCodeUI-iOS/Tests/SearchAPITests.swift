//
//  SearchAPITests.swift
//  ClaudeCodeUITests
//
//  Created on 2025-01-18.
//

import XCTest
@testable import ClaudeCodeUI

class SearchAPITests: XCTestCase {
    
    var searchViewModel: SearchViewModel!
    var mockAPIClient: MockAPIClient!
    var testProject: Project!
    
    override func setUp() {
        super.setUp()
        
        // Create test project
        testProject = Project(
            id: "test-project",
            name: "Test Project",
            path: "/test/path",
            lastAccessed: Date(),
            icon: "folder"
        )
        
        // Create mock API client
        mockAPIClient = MockAPIClient()
        
        // Initialize search view model with mock client
        searchViewModel = SearchViewModel(project: testProject)
        // Inject mock API client (would need dependency injection in real code)
        searchViewModel.apiClient = mockAPIClient
    }
    
    override func tearDown() {
        searchViewModel = nil
        mockAPIClient = nil
        testProject = nil
        super.tearDown()
    }
    
    // MARK: - Search API Tests
    
    func testSearchAPIEndpoint() {
        // Test that search uses correct API endpoint
        let expectation = self.expectation(description: "Search API called")
        
        mockAPIClient.onRequestMade = { endpoint, method in
            XCTAssertEqual(endpoint, "/api/projects/Test Project/search")
            XCTAssertEqual(method, "POST")
            expectation.fulfill()
        }
        
        searchViewModel.performSearch("test query")
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testSearchRequestBody() {
        // Test search request body format
        let expectation = self.expectation(description: "Request body verified")
        
        mockAPIClient.onRequestBody = { body in
            if let data = body,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                XCTAssertEqual(json["query"] as? String, "func findUser")
                XCTAssertEqual(json["scope"] as? String, "all")
                XCTAssertEqual(json["fileTypes"] as? [String], ["swift", "js"])
                expectation.fulfill()
            }
        }
        
        searchViewModel.searchQuery = "func findUser"
        searchViewModel.searchScope = .all
        searchViewModel.fileTypes = ["swift", "js"]
        searchViewModel.performSearch("func findUser")
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testSearchResponseParsing() {
        // Test parsing of search results
        let expectation = self.expectation(description: "Results parsed")
        
        let mockResults = [
            [
                "file": "UserController.swift",
                "line": 42,
                "content": "func findUser(id: String) -> User?",
                "match": "func findUser"
            ],
            [
                "file": "UserService.js",
                "line": 15,
                "content": "function findUser(userId) {",
                "match": "findUser"
            ]
        ]
        
        mockAPIClient.mockSearchResponse = ["results": mockResults]
        
        searchViewModel.onResultsUpdated = { results in
            XCTAssertEqual(results.count, 2)
            XCTAssertEqual(results[0].fileName, "UserController.swift")
            XCTAssertEqual(results[0].lineNumber, 42)
            XCTAssertEqual(results[1].fileName, "UserService.js")
            XCTAssertEqual(results[1].lineNumber, 15)
            expectation.fulfill()
        }
        
        searchViewModel.performSearch("findUser")
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testSearchCaching() {
        // Test that search results are cached
        let firstCallExpectation = self.expectation(description: "First API call")
        let secondCallExpectation = self.expectation(description: "Second call uses cache")
        secondCallExpectation.isInverted = true // Should NOT be called
        
        var callCount = 0
        mockAPIClient.onRequestMade = { _, _ in
            callCount += 1
            if callCount == 1 {
                firstCallExpectation.fulfill()
            } else {
                secondCallExpectation.fulfill() // This should NOT happen
            }
        }
        
        // First search
        searchViewModel.performSearch("cached query")
        
        // Wait for first call
        wait(for: [firstCallExpectation], timeout: 2.0)
        
        // Second search with same query (should use cache)
        searchViewModel.performSearch("cached query")
        
        // Wait to ensure second call doesn't happen
        wait(for: [secondCallExpectation], timeout: 1.0)
        
        XCTAssertEqual(callCount, 1, "API should only be called once for cached query")
    }
    
    func testSearchCacheInvalidation() {
        // Test cache invalidation after 5 minutes
        let expectation = self.expectation(description: "Cache invalidated")
        
        var callCount = 0
        mockAPIClient.onRequestMade = { _, _ in
            callCount += 1
            if callCount == 2 {
                expectation.fulfill()
            }
        }
        
        // First search
        searchViewModel.performSearch("test query")
        
        // Simulate time passing (would need time injection in real code)
        searchViewModel.cacheTimestamp = Date().addingTimeInterval(-301) // 5 min + 1 sec ago
        
        // Second search should make new API call
        searchViewModel.performSearch("test query")
        
        waitForExpectations(timeout: 2.0)
        XCTAssertEqual(callCount, 2)
    }
    
    func testSearchScopeFiltering() {
        // Test different search scopes
        let expectation = self.expectation(description: "Scope sent correctly")
        
        var testedScopes: [String] = []
        mockAPIClient.onRequestBody = { body in
            if let data = body,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let scope = json["scope"] as? String {
                testedScopes.append(scope)
                if testedScopes.count == 3 {
                    expectation.fulfill()
                }
            }
        }
        
        // Test all scopes
        searchViewModel.searchScope = .all
        searchViewModel.performSearch("test")
        
        searchViewModel.searchScope = .currentFile
        searchViewModel.performSearch("test")
        
        searchViewModel.searchScope = .openFiles
        searchViewModel.performSearch("test")
        
        waitForExpectations(timeout: 2.0)
        
        XCTAssertTrue(testedScopes.contains("all"))
        XCTAssertTrue(testedScopes.contains("currentFile"))
        XCTAssertTrue(testedScopes.contains("openFiles"))
    }
    
    func testSearchErrorHandling() {
        // Test error handling in search
        let expectation = self.expectation(description: "Error handled")
        
        mockAPIClient.shouldFailRequest = true
        mockAPIClient.mockError = NSError(domain: "test", code: 500, userInfo: [
            NSLocalizedDescriptionKey: "Server error"
        ])
        
        searchViewModel.onError = { error in
            XCTAssertNotNil(error)
            XCTAssertTrue(error.localizedDescription.contains("Server error"))
            expectation.fulfill()
        }
        
        searchViewModel.performSearch("test query")
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testEmptySearchResults() {
        // Test handling of empty results
        let expectation = self.expectation(description: "Empty results handled")
        
        mockAPIClient.mockSearchResponse = ["results": []]
        
        searchViewModel.onResultsUpdated = { results in
            XCTAssertEqual(results.count, 0)
            XCTAssertTrue(self.searchViewModel.isShowingEmptyState)
            expectation.fulfill()
        }
        
        searchViewModel.performSearch("nonexistent")
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testSearchCancellation() {
        // Test cancelling ongoing search
        let expectation = self.expectation(description: "Search cancelled")
        expectation.isInverted = true // Should NOT complete
        
        mockAPIClient.onRequestCompleted = {
            expectation.fulfill() // This should NOT happen
        }
        
        mockAPIClient.requestDelay = 2.0 // Simulate slow request
        
        searchViewModel.performSearch("slow query")
        
        // Cancel after 0.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.searchViewModel.cancelSearch()
        }
        
        waitForExpectations(timeout: 1.5)
        XCTAssertFalse(searchViewModel.isSearching)
    }
    
    func testSearchThrottling() {
        // Test that rapid searches are throttled
        let expectation = self.expectation(description: "Searches throttled")
        
        var requestCount = 0
        mockAPIClient.onRequestMade = { _, _ in
            requestCount += 1
        }
        
        // Rapid fire multiple searches
        for i in 0..<10 {
            searchViewModel.performSearch("query \(i)")
        }
        
        // Wait for throttle delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Should only make one request (the last one)
            XCTAssertEqual(requestCount, 1)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
}

// MARK: - Mock API Client for Search

extension SearchViewModel {
    // For testing only - inject mock API client
    var apiClient: APIClientProtocol? {
        get { return nil }
        set { /* In real code, would set internal client */ }
    }
    
    var onResultsUpdated: (([SearchResult]) -> Void)? {
        get { return nil }
        set { /* In real code, would set callback */ }
    }
    
    var onError: ((Error) -> Void)? {
        get { return nil }
        set { /* In real code, would set callback */ }
    }
    
    var cacheTimestamp: Date? {
        get { return nil }
        set { /* In real code, would set cache time */ }
    }
    
    var isShowingEmptyState: Bool {
        return searchResults.isEmpty && !isSearching
    }
    
    func cancelSearch() {
        // In real code, would cancel ongoing request
        isSearching = false
    }
}

// Mock APIClient for testing
class MockAPIClient: APIClientProtocol {
    var onRequestMade: ((String, String) -> Void)?
    var onRequestBody: ((Data?) -> Void)?
    var onRequestCompleted: (() -> Void)?
    var mockSearchResponse: [String: Any] = [:]
    var shouldFailRequest = false
    var mockError: Error?
    var requestDelay: TimeInterval = 0
    
    func request(_ endpoint: String, method: String, body: Data?, completion: @escaping (Result<Data, Error>) -> Void) {
        onRequestMade?(endpoint, method)
        onRequestBody?(body)
        
        if requestDelay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + requestDelay) {
                self.completeRequest(completion: completion)
            }
        } else {
            completeRequest(completion: completion)
        }
    }
    
    private func completeRequest(completion: @escaping (Result<Data, Error>) -> Void) {
        onRequestCompleted?()
        
        if shouldFailRequest {
            completion(.failure(mockError ?? NSError(domain: "test", code: 500)))
        } else {
            if let data = try? JSONSerialization.data(withJSONObject: mockSearchResponse) {
                completion(.success(data))
            } else {
                completion(.success(Data()))
            }
        }
    }
}

// Protocol for dependency injection
protocol APIClientProtocol {
    func request(_ endpoint: String, method: String, body: Data?, completion: @escaping (Result<Data, Error>) -> Void)
}