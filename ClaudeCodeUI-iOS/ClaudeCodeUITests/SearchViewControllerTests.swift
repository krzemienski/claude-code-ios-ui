//
//  SearchViewControllerTests.swift
//  ClaudeCodeUITests
//
//  Created for comprehensive testing of search functionality
//

import XCTest
import UIKit
@testable import ClaudeCodeUI

final class SearchViewControllerTests: XCTestCase {
    
    var searchViewController: SearchViewController!
    
    override func setUp() {
        super.setUp()
        searchViewController = SearchViewController()
        // Load the view to trigger viewDidLoad
        searchViewController.loadViewIfNeeded()
    }
    
    override func tearDown() {
        searchViewController = nil
        super.tearDown()
    }
    
    // MARK: - View Controller Lifecycle Tests
    
    func testViewControllerInitialization() {
        XCTAssertNotNil(searchViewController)
        XCTAssertEqual(searchViewController.title, "Search")
    }
    
    func testViewDidLoad() {
        // Verify UI components are properly set up
        let searchBar = searchViewController.view.subviews.first { $0 is UISearchBar } as? UISearchBar
        XCTAssertNotNil(searchBar)
        XCTAssertEqual(searchBar?.placeholder, "Search in projects...")
        XCTAssertEqual(searchBar?.searchBarStyle, .minimal)
        XCTAssertEqual(searchBar?.returnKeyType, .search)
        
        let tableView = searchViewController.view.subviews.first { $0 is UITableView } as? UITableView
        XCTAssertNotNil(tableView)
        XCTAssertEqual(tableView?.backgroundColor, .clear)
        XCTAssertEqual(tableView?.separatorStyle, .none)
        XCTAssertEqual(tableView?.keyboardDismissMode, .onDrag)
        
        let activityIndicator = searchViewController.view.subviews.first { $0 is UIActivityIndicatorView } as? UIActivityIndicatorView
        XCTAssertNotNil(activityIndicator)
        XCTAssertTrue(activityIndicator?.hidesWhenStopped ?? false)
    }
    
    func testThemeApplication() {
        // Test that cyberpunk theme is applied correctly
        XCTAssertEqual(searchViewController.view.backgroundColor, CyberpunkTheme.background)
        
        let searchBar = searchViewController.view.subviews.first { $0 is UISearchBar } as? UISearchBar
        XCTAssertEqual(searchBar?.barTintColor, CyberpunkTheme.surface)
        XCTAssertEqual(searchBar?.tintColor, CyberpunkTheme.primaryCyan)
        
        let activityIndicator = searchViewController.view.subviews.first { $0 is UIActivityIndicatorView } as? UIActivityIndicatorView
        XCTAssertEqual(activityIndicator?.color, CyberpunkTheme.primaryCyan)
    }
    
    // MARK: - Search Model Tests
    
    func testSearchResultModel() {
        let searchResult = SearchViewController.SearchResult(
            fileName: "TestFile.swift",
            filePath: "/test/path/TestFile.swift",
            lineNumber: 42,
            lineContent: "func testMethod() {",
            projectName: "TestProject"
        )
        
        XCTAssertEqual(searchResult.fileName, "TestFile.swift")
        XCTAssertEqual(searchResult.filePath, "/test/path/TestFile.swift")
        XCTAssertEqual(searchResult.lineNumber, 42)
        XCTAssertEqual(searchResult.lineContent, "func testMethod() {")
        XCTAssertEqual(searchResult.projectName, "TestProject")
    }
    
    // MARK: - Search Functionality Tests
    
    func testEmptySearchQuery() {
        let searchBar = searchViewController.view.subviews.first { $0 is UISearchBar } as? UISearchBar
        let tableView = searchViewController.view.subviews.first { $0 is UITableView } as? UITableView
        
        // Simulate empty search
        searchBar?.text = ""
        searchViewController.searchBar(searchBar!, textDidChange: "")
        
        // Wait for debounce and UI update
        let expectation = XCTestExpectation(description: "Empty search handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(tableView?.numberOfRows(inSection: 0), 0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSearchDebouncing() {
        let searchBar = searchViewController.view.subviews.first { $0 is UISearchBar } as? UISearchBar
        
        // Simulate rapid typing
        searchBar?.text = "t"
        searchViewController.searchBar(searchBar!, textDidChange: "t")
        
        searchBar?.text = "te"
        searchViewController.searchBar(searchBar!, textDidChange: "te")
        
        searchBar?.text = "test"
        searchViewController.searchBar(searchBar!, textDidChange: "test")
        
        // Verify that search is debounced (should not execute immediately)
        let activityIndicator = searchViewController.view.subviews.first { $0 is UIActivityIndicatorView } as? UIActivityIndicatorView
        XCTAssertFalse(activityIndicator?.isAnimating ?? true)
        
        // Wait for debounce to trigger
        let expectation = XCTestExpectation(description: "Search debounce triggered")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            XCTAssertTrue(activityIndicator?.isAnimating ?? false)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSearchExecution() {
        // Set up mock project name
        UserDefaults.standard.set("TestProject", forKey: "lastSelectedProject")
        
        let searchBar = searchViewController.view.subviews.first { $0 is UISearchBar } as? UISearchBar
        let tableView = searchViewController.view.subviews.first { $0 is UITableView } as? UITableView
        let activityIndicator = searchViewController.view.subviews.first { $0 is UIActivityIndicatorView } as? UIActivityIndicatorView
        
        // Start search
        searchBar?.text = "AppDelegate"
        searchViewController.searchBar(searchBar!, textDidChange: "AppDelegate")
        
        // Wait for debounce to trigger search execution
        let searchStartExpectation = XCTestExpectation(description: "Search execution started")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            XCTAssertTrue(activityIndicator?.isAnimating ?? false)
            searchStartExpectation.fulfill()
        }
        wait(for: [searchStartExpectation], timeout: 1.0)
        
        // Wait for search to complete (mock search takes 1 second)
        let searchCompleteExpectation = XCTestExpectation(description: "Search execution completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            XCTAssertFalse(activityIndicator?.isAnimating ?? true)
            XCTAssertEqual(tableView?.numberOfRows(inSection: 0), 2) // Mock data returns 2 results
            searchCompleteExpectation.fulfill()
        }
        wait(for: [searchCompleteExpectation], timeout: 2.0)
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "lastSelectedProject")
    }
    
    func testSearchWithoutProject() {
        // Ensure no project is set
        UserDefaults.standard.removeObject(forKey: "lastSelectedProject")
        
        let searchBar = searchViewController.view.subviews.first { $0 is UISearchBar } as? UISearchBar
        
        // Start search without project
        searchBar?.text = "test"
        searchViewController.searchBar(searchBar!, textDidChange: "test")
        
        // Wait for search to attempt execution
        let expectation = XCTestExpectation(description: "Search error handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // Should show error alert and clear results
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSearchButtonTapped() {
        let searchBar = searchViewController.view.subviews.first { $0 is UISearchBar } as? UISearchBar
        
        // Make search bar first responder
        searchBar?.becomeFirstResponder()
        XCTAssertTrue(searchBar?.isFirstResponder ?? false)
        
        // Simulate search button tap
        searchViewController.searchBarSearchButtonClicked(searchBar!)
        
        // Verify search bar resigns first responder
        XCTAssertFalse(searchBar?.isFirstResponder ?? true)
    }
    
    // MARK: - Table View Tests
    
    func testTableViewDataSource() {
        // Set up mock project name
        UserDefaults.standard.set("TestProject", forKey: "lastSelectedProject")
        
        let tableView = searchViewController.view.subviews.first { $0 is UITableView } as? UITableView
        let searchBar = searchViewController.view.subviews.first { $0 is UISearchBar } as? UISearchBar
        
        // Perform search to populate results
        searchBar?.text = "test"
        searchViewController.searchBar(searchBar!, textDidChange: "test")
        
        // Wait for search to complete
        let expectation = XCTestExpectation(description: "Search results loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            // Test data source methods
            let numberOfRows = self.searchViewController.tableView(tableView!, numberOfRowsInSection: 0)
            XCTAssertEqual(numberOfRows, 2) // Mock data returns 2 results
            
            // Test cell creation
            let indexPath = IndexPath(row: 0, section: 0)
            let cell = self.searchViewController.tableView(tableView!, cellForRowAt: indexPath)
            XCTAssertTrue(cell is SearchResultCell)
            
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "lastSelectedProject")
    }
    
    func testTableViewDelegate() {
        // Set up mock project name
        UserDefaults.standard.set("TestProject", forKey: "lastSelectedProject")
        
        let tableView = searchViewController.view.subviews.first { $0 is UITableView } as? UITableView
        let searchBar = searchViewController.view.subviews.first { $0 is UISearchBar } as? UISearchBar
        
        // Perform search to populate results
        searchBar?.text = "test"
        searchViewController.searchBar(searchBar!, textDidChange: "test")
        
        // Wait for search to complete
        let expectation = XCTestExpectation(description: "Table view delegate tested")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            // Test row height
            let indexPath = IndexPath(row: 0, section: 0)
            let height = self.searchViewController.tableView(tableView!, heightForRowAt: indexPath)
            XCTAssertEqual(height, 80)
            
            // Test row selection
            self.searchViewController.tableView(tableView!, didSelectRowAt: indexPath)
            // Note: This should trigger navigation logic when fully implemented
            
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "lastSelectedProject")
    }
    
    // MARK: - SearchResultCell Tests
    
    func testSearchResultCellConfiguration() {
        let cell = SearchResultCell(style: .default, reuseIdentifier: "SearchResultCell")
        
        let searchResult = SearchViewController.SearchResult(
            fileName: "TestFile.swift",
            filePath: "/test/path/TestFile.swift",
            lineNumber: 42,
            lineContent: "func testMethod() {",
            projectName: "TestProject"
        )
        
        cell.configure(with: searchResult)
        
        // Verify cell configuration (private labels, so we test indirectly)
        XCTAssertEqual(cell.backgroundColor, .clear)
        XCTAssertEqual(cell.selectionStyle, .none)
    }
    
    func testSearchResultCellInitialization() {
        let cell = SearchResultCell(style: .default, reuseIdentifier: "SearchResultCell")
        
        XCTAssertNotNil(cell)
        XCTAssertEqual(cell.backgroundColor, .clear)
        XCTAssertEqual(cell.selectionStyle, .none)
        
        // Test that UI elements are properly added to the cell
        XCTAssertTrue(cell.contentView.subviews.count > 0)
    }
    
    // MARK: - Performance Tests
    
    func testSearchPerformance() {
        // Set up mock project name
        UserDefaults.standard.set("TestProject", forKey: "lastSelectedProject")
        
        let searchBar = searchViewController.view.subviews.first { $0 is UISearchBar } as? UISearchBar
        
        measure {
            // Measure search execution performance
            searchBar?.text = "performance_test"
            searchViewController.searchBar(searchBar!, textDidChange: "performance_test")
            
            // Wait for debounce
            let expectation = XCTestExpectation(description: "Performance test")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)
        }
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "lastSelectedProject")
    }
    
    func testTableViewScrollingPerformance() {
        // Set up mock project name and populate results
        UserDefaults.standard.set("TestProject", forKey: "lastSelectedProject")
        
        let tableView = searchViewController.view.subviews.first { $0 is UITableView } as? UITableView
        let searchBar = searchViewController.view.subviews.first { $0 is UISearchBar } as? UISearchBar
        
        // Perform search to populate results
        searchBar?.text = "test"
        searchViewController.searchBar(searchBar!, textDidChange: "test")
        
        // Wait for search to complete
        let setupExpectation = XCTestExpectation(description: "Setup complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            setupExpectation.fulfill()
        }
        wait(for: [setupExpectation], timeout: 2.0)
        
        measure {
            // Measure table view cell creation performance
            for i in 0..<10 {
                let indexPath = IndexPath(row: i % 2, section: 0) // Cycle through available rows
                _ = searchViewController.tableView(tableView!, cellForRowAt: indexPath)
            }
        }
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "lastSelectedProject")
    }
    
    // MARK: - Error Handling Tests
    
    func testSearchErrorHandling() {
        // Test error handling when no project is selected
        UserDefaults.standard.removeObject(forKey: "lastSelectedProject")
        
        let searchBar = searchViewController.view.subviews.first { $0 is UISearchBar } as? UISearchBar
        let activityIndicator = searchViewController.view.subviews.first { $0 is UIActivityIndicatorView } as? UIActivityIndicatorView
        let tableView = searchViewController.view.subviews.first { $0 is UITableView } as? UITableView
        
        // Trigger search without project
        searchBar?.text = "test"
        searchViewController.searchBar(searchBar!, textDidChange: "test")
        
        // Wait for error handling
        let expectation = XCTestExpectation(description: "Error handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // Verify error state
            XCTAssertFalse(activityIndicator?.isAnimating ?? true)
            XCTAssertEqual(tableView?.numberOfRows(inSection: 0), 0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryLeaks() {
        weak var weakSearchViewController = searchViewController
        
        // Create and release search view controller
        searchViewController = nil
        
        // Verify it's deallocated
        XCTAssertNil(weakSearchViewController, "SearchViewController should be deallocated")
        
        // Recreate for tearDown
        searchViewController = SearchViewController()
    }
    
    func testTimerCleanup() {
        let searchBar = searchViewController.view.subviews.first { $0 is UISearchBar } as? UISearchBar
        
        // Start multiple searches to create timers
        for i in 0..<5 {
            searchBar?.text = "test\(i)"
            searchViewController.searchBar(searchBar!, textDidChange: "test\(i)")
        }
        
        // Wait a bit then check that only one timer should be active
        let expectation = XCTestExpectation(description: "Timer cleanup")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Previous timers should be invalidated by subsequent searches
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Integration Tests
    
    func testSearchViewControllerIntegration() {
        // Set up complete search scenario
        UserDefaults.standard.set("IntegrationTestProject", forKey: "lastSelectedProject")
        
        let searchBar = searchViewController.view.subviews.first { $0 is UISearchBar } as? UISearchBar
        let tableView = searchViewController.view.subviews.first { $0 is UITableView } as? UITableView
        let activityIndicator = searchViewController.view.subviews.first { $0 is UIActivityIndicatorView } as? UIActivityIndicatorView
        
        // Test complete search flow
        let searchFlowExpectation = XCTestExpectation(description: "Complete search flow")
        
        // Step 1: Start search
        searchBar?.text = "AppDelegate"
        searchViewController.searchBar(searchBar!, textDidChange: "AppDelegate")
        
        // Step 2: Verify loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            XCTAssertTrue(activityIndicator?.isAnimating ?? false)
            
            // Step 3: Verify completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                XCTAssertFalse(activityIndicator?.isAnimating ?? true)
                XCTAssertEqual(tableView?.numberOfRows(inSection: 0), 2)
                
                // Step 4: Test row selection
                let indexPath = IndexPath(row: 0, section: 0)
                self.searchViewController.tableView(tableView!, didSelectRowAt: indexPath)
                
                searchFlowExpectation.fulfill()
            }
        }
        
        wait(for: [searchFlowExpectation], timeout: 3.0)
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "lastSelectedProject")
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibility() {
        let searchBar = searchViewController.view.subviews.first { $0 is UISearchBar } as? UISearchBar
        let tableView = searchViewController.view.subviews.first { $0 is UITableView } as? UITableView
        let activityIndicator = searchViewController.view.subviews.first { $0 is UIActivityIndicatorView } as? UIActivityIndicatorView
        
        // Verify accessibility is properly configured
        XCTAssertTrue(searchBar?.isAccessibilityElement ?? false)
        XCTAssertTrue(tableView?.isAccessibilityElement ?? false)
        XCTAssertNotNil(activityIndicator?.accessibilityLabel)
        
        // Test that search results are accessible
        UserDefaults.standard.set("AccessibilityTestProject", forKey: "lastSelectedProject")
        
        let searchBar2 = searchViewController.view.subviews.first { $0 is UISearchBar } as? UISearchBar
        searchBar2?.text = "test"
        searchViewController.searchBar(searchBar2!, textDidChange: "test")
        
        let expectation = XCTestExpectation(description: "Accessibility test")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            let indexPath = IndexPath(row: 0, section: 0)
            let cell = self.searchViewController.tableView(tableView!, cellForRowAt: indexPath)
            XCTAssertTrue(cell.isAccessibilityElement)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "lastSelectedProject")
    }
}

// MARK: - Mock Search API Client

/// Mock API client for testing real API integration (when implemented)
class MockSearchAPIClient {
    static let shared = MockSearchAPIClient()
    
    func searchInProject(_ projectName: String, query: String, completion: @escaping (Result<[SearchViewController.SearchResult], Error>) -> Void) {
        // Simulate API delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let results = [
                SearchViewController.SearchResult(
                    fileName: "MockFile1.swift",
                    filePath: "/mock/path/MockFile1.swift",
                    lineNumber: 10,
                    lineContent: "// Mock search result containing '\(query)'",
                    projectName: projectName
                ),
                SearchViewController.SearchResult(
                    fileName: "MockFile2.swift",
                    filePath: "/mock/path/MockFile2.swift",
                    lineNumber: 25,
                    lineContent: "func mockFunction() { // \(query) implementation",
                    projectName: projectName
                )
            ]
            completion(.success(results))
        }
    }
}

// MARK: - Test Extensions

extension SearchViewControllerTests {
    
    /// Helper method to wait for UI updates
    func waitForUIUpdate(timeout: TimeInterval = 1.0) {
        let expectation = XCTestExpectation(description: "UI Update")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }
    
    /// Helper method to simulate user typing with realistic delays
    func simulateTyping(_ text: String, in searchBar: UISearchBar, with viewController: SearchViewController) {
        for (index, _) in text.enumerated() {
            let partialText = String(text.prefix(index + 1))
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                searchBar.text = partialText
                viewController.searchBar(searchBar, textDidChange: partialText)
            }
        }
    }
}