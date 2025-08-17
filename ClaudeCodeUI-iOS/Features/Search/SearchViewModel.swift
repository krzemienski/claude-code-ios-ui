//
//  SearchViewModel.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-16.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Search Models

struct SearchResult: Identifiable {
    let id = UUID()
    let fileName: String
    let filePath: String
    let fileType: String
    let matchCount: Int
    let matches: [SearchMatch]
    let matchPreview: String?
    
    var fileIcon: String {
        switch fileType.lowercased() {
        case "swift": return "swift"
        case "m", "h": return "c.circle"
        case "js", "jsx": return "curlybraces"
        case "ts", "tsx": return "t.circle"
        case "json": return "doc.text"
        case "md": return "doc.richtext"
        case "xml": return "chevron.left.slash.chevron.right"
        case "yaml", "yml": return "doc.plaintext"
        case "html": return "globe"
        case "css", "scss": return "paintbrush"
        case "py": return "chevron.left.forwardslash.chevron.right"
        default: return "doc"
        }
    }
}

struct SearchMatch: Identifiable {
    let id = UUID()
    let lineNumber: Int
    let columnNumber: Int
    let lineContent: String
    let contextBefore: String?
    let contextAfter: String?
}

// MARK: - View Model

@MainActor
class SearchViewModel: ObservableObject {
    @Published var results: [SearchResult] = []
    @Published var isSearching = false
    @Published var searchTime: Double = 0
    @Published var errorMessage: String?
    @Published var recentSearches: [String] = []
    
    private var searchTask: Task<Void, Never>?
    private let maxRecentSearches = 10
    private let userDefaults = UserDefaults.standard
    private let recentSearchesKey = "recentSearches"
    
    // Current project context (would be injected in production)
    private var currentProjectPath: String = ""
    private var currentProjectName: String = ""
    
    init() {
        loadRecentSearches()
    }
    
    // MARK: - Public Methods
    
    func search(query: String, scope: SearchScope, fileTypes: [FileType]) {
        // Cancel any existing search
        searchTask?.cancel()
        
        // Start new search
        isSearching = true
        errorMessage = nil
        
        let startTime = Date()
        
        searchTask = Task {
            do {
                // Add to recent searches
                addToRecentSearches(query)
                
                // Perform search
                let searchResults = try await performSearch(
                    query: query,
                    scope: scope,
                    fileTypes: fileTypes
                )
                
                // Update results if not cancelled
                if !Task.isCancelled {
                    self.results = searchResults
                    self.searchTime = Date().timeIntervalSince(startTime)
                    self.isSearching = false
                }
            } catch {
                if !Task.isCancelled {
                    self.errorMessage = error.localizedDescription
                    self.isSearching = false
                }
            }
        }
    }
    
    func clearResults() {
        results = []
        searchTime = 0
        errorMessage = nil
    }
    
    func cancelSearch() {
        searchTask?.cancel()
        isSearching = false
    }
    
    // MARK: - Private Methods
    
    private func performSearch(query: String, scope: SearchScope, fileTypes: [FileType]) async throws -> [SearchResult] {
        // Check if cancelled
        if Task.isCancelled {
            return []
        }
        
        // Ensure we have a project name
        guard !currentProjectName.isEmpty else {
            // If no project name, use mock data as fallback
            print("⚠️ No project name set, using mock data")
            return generateMockResults(query: query, scope: scope)
        }
        
        // Create the search request
        let searchRequest: [String: Any] = [
            "query": query,
            "scope": scope.rawValue,
            "fileTypes": fileTypes.map { $0.rawValue }
        ]
        
        // Call the backend API
        let endpoint = "/api/projects/\(currentProjectName)/search"
        
        do {
            // Using APIClient's generic request method
            let response = try await withCheckedThrowingContinuation { continuation in
                APIClient.shared.request(
                    endpoint: endpoint,
                    method: "POST",
                    body: searchRequest
                ) { (result: Result<[String: Any], Error>) in
                    continuation.resume(with: result)
                }
            }
            
            // Parse the response
            if let searchResults = response["results"] as? [[String: Any]] {
                return parseSearchResults(from: searchResults)
            } else {
                // If no results in response, return empty array
                return []
            }
        } catch {
            print("❌ Search API error: \(error)")
            // On error, could fallback to mock data or rethrow
            throw error
        }
    }
    
    private func parseSearchResults(from data: [[String: Any]]) -> [SearchResult] {
        return data.compactMap { item in
            guard let fileName = item["fileName"] as? String,
                  let filePath = item["filePath"] as? String,
                  let fileType = item["fileType"] as? String else {
                return nil
            }
            
            let matchCount = item["matchCount"] as? Int ?? 0
            let matchPreview = item["matchPreview"] as? String
            
            // Parse matches if available
            var matches: [SearchMatch] = []
            if let matchesData = item["matches"] as? [[String: Any]] {
                matches = matchesData.compactMap { matchItem in
                    guard let lineNumber = matchItem["lineNumber"] as? Int,
                          let lineContent = matchItem["lineContent"] as? String else {
                        return nil
                    }
                    
                    return SearchMatch(
                        lineNumber: lineNumber,
                        columnNumber: matchItem["columnNumber"] as? Int ?? 0,
                        lineContent: lineContent,
                        contextBefore: matchItem["contextBefore"] as? String,
                        contextAfter: matchItem["contextAfter"] as? String
                    )
                }
            }
            
            return SearchResult(
                fileName: fileName,
                filePath: filePath,
                fileType: fileType,
                matchCount: matchCount,
                matches: matches,
                matchPreview: matchPreview
            )
        }
    }
    
    /// Sets the current project context for search
    public func setProjectContext(name: String, path: String) {
        currentProjectName = name
        currentProjectPath = path
    }
    
    private func generateMockResults(query: String, scope: SearchScope) -> [SearchResult] {
        // Generate realistic mock search results
        let mockFiles = [
            ("ChatViewController.swift", "Features/Chat/", "swift"),
            ("APIClient.swift", "Core/Network/", "swift"),
            ("Project.swift", "Core/Data/Models/", "swift"),
            ("WebSocketManager.swift", "Core/Network/", "swift"),
            ("package.json", "", "json"),
            ("README.md", "", "md"),
            ("styles.css", "Design/", "css")
        ]
        
        var results: [SearchResult] = []
        
        for (fileName, path, type) in mockFiles {
            // Randomly decide if this file has matches
            if Bool.random() {
                let matchCount = Int.random(in: 1...5)
                var matches: [SearchMatch] = []
                
                for i in 0..<matchCount {
                    let lineNum = Int.random(in: 10...200)
                    matches.append(SearchMatch(
                        lineNumber: lineNum,
                        columnNumber: Int.random(in: 1...80),
                        lineContent: "    func handle\(query.capitalized)() { // Found '\(query)' here",
                        contextBefore: i == 0 ? "    // Previous line of context" : nil,
                        contextAfter: i == 0 ? "    // Next line of context" : nil
                    ))
                }
                
                results.append(SearchResult(
                    fileName: fileName,
                    filePath: path + fileName,
                    fileType: type,
                    matchCount: matchCount,
                    matches: matches,
                    matchPreview: matches.first?.lineContent
                ))
            }
        }
        
        return results
    }
    
    private func loadRecentSearches() {
        if let searches = userDefaults.stringArray(forKey: recentSearchesKey) {
            recentSearches = searches
        }
    }
    
    private func addToRecentSearches(_ query: String) {
        // Remove if already exists
        recentSearches.removeAll { $0 == query }
        
        // Add to beginning
        recentSearches.insert(query, at: 0)
        
        // Limit to max count
        if recentSearches.count > maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(maxRecentSearches))
        }
        
        // Save to UserDefaults
        userDefaults.set(recentSearches, forKey: recentSearchesKey)
    }
}

// MARK: - UIKit Bridge

class SearchViewController: UIViewController {
    private var hostingController: UIHostingController<SearchView>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup SwiftUI view
        let searchView = SearchView()
        hostingController = UIHostingController(rootView: searchView)
        
        if let hostingController = hostingController {
            addChild(hostingController)
            view.addSubview(hostingController.view)
            
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            
            hostingController.didMove(toParent: self)
        }
        
        // Customize navigation
        title = "Search"
        navigationItem.largeTitleDisplayMode = .never
    }
}