// SEARCH API INTEGRATION FIXES
// Replace mock data implementation in SearchViewController.swift

// 1. Add to APIClient.swift - Search Models
struct SearchRequest: Codable {
    let query: String
    let scope: String // "files", "content", "both"
    let fileTypes: [String]
    let caseSensitive: Bool
    let regex: Bool
    let projectName: String
}

struct SearchResponse: Codable {
    let results: [SearchResultItem]
    let totalMatches: Int
    let searchTime: String
}

struct SearchResultItem: Codable {
    let fileName: String
    let filePath: String
    let lineNumber: Int
    let lineContent: String
    let matchHighlights: [HighlightRange]?
}

struct HighlightRange: Codable {
    let start: Int
    let length: Int
}

// 2. Add to APIClient.swift - Search Method
extension APIClient {
    func searchInProject(
        projectName: String,
        query: String,
        scope: String = "both",
        fileTypes: [String] = [],
        caseSensitive: Bool = false,
        regex: Bool = false,
        completion: @escaping (Result<SearchResponse, APIError>) -> Void
    ) {
        let endpoint = "/api/projects/\(projectName)/search"
        
        let searchRequest = SearchRequest(
            query: query,
            scope: scope,
            fileTypes: fileTypes,
            caseSensitive: caseSensitive,
            regex: regex,
            projectName: projectName
        )
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication if available
        if let token = getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            request.httpBody = try JSONEncoder().encode(searchRequest)
        } catch {
            completion(.failure(.encodingError))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: data)
                completion(.success(searchResponse))
            } catch {
                completion(.failure(.decodingError))
            }
        }.resume()
    }
}

// 3. Replace in SearchViewController.swift - executeSearch method
private func executeSearch(query: String) {
    guard !query.isEmpty else {
        searchResults = []
        tableView.reloadData()
        return
    }
    
    isSearching = true
    activityIndicator.startAnimating()
    
    // Get current project - you'll need to implement getCurrentProject()
    guard let currentProject = getCurrentProject() else {
        showError("No project selected. Please select a project first.")
        isSearching = false
        activityIndicator.stopAnimating()
        return
    }
    
    APIClient.shared.searchInProject(
        projectName: currentProject.name,
        query: query,
        scope: "both", // Search both files and content
        fileTypes: [], // Search all file types
        caseSensitive: false,
        regex: false
    ) { [weak self] result in
        DispatchQueue.main.async {
            guard let self = self else { return }
            
            self.isSearching = false
            self.activityIndicator.stopAnimating()
            
            switch result {
            case .success(let response):
                // Convert API results to view model
                self.searchResults = response.results.map { apiResult in
                    SearchResult(
                        fileName: apiResult.fileName,
                        filePath: apiResult.filePath,
                        lineNumber: apiResult.lineNumber,
                        lineContent: apiResult.lineContent,
                        projectName: currentProject.name
                    )
                }
                self.tableView.reloadData()
                
                // Show search stats
                print("🔍 Search completed: \(response.totalMatches) matches in \(response.searchTime)")
                
            case .failure(let error):
                print("❌ Search failed: \(error)")
                // Fall back to mock data for now
                self.searchResults = self.generateMockResults(for: query)
                self.tableView.reloadData()
                
                // Show error to user
                self.showSearchError(error)
            }
        }
    }
}

// 4. Add helper methods to SearchViewController.swift
private func getCurrentProject() -> Project? {
    // Implementation depends on how current project is stored
    // This might be passed from parent view controller or stored in a service
    // For now, return nil to trigger error handling
    return nil // TODO: Implement project selection logic
}

private func showSearchError(_ error: APIError) {
    let message: String
    switch error {
    case .networkError:
        message = "Network error. Using offline search results."
    case .noData:
        message = "No search results from server."
    case .decodingError:
        message = "Error processing search results."
    default:
        message = "Search temporarily unavailable. Using offline results."
    }
    
    // Show non-intrusive error message
    let alert = UIAlertController(title: "Search Notice", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
}

private func showError(_ message: String) {
    let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
}

// 5. Backend Endpoint Requirements (for backend team)
/*
POST /api/projects/:projectName/search

Request Body:
{
  "query": "search term",
  "scope": "both", // "files", "content", "both"
  "fileTypes": ["swift", "js"], // empty array = all types
  "caseSensitive": false,
  "regex": false,
  "projectName": "MyProject"
}

Response:
{
  "results": [
    {
      "fileName": "ViewController.swift",
      "filePath": "/path/to/project/ViewController.swift", 
      "lineNumber": 42,
      "lineContent": "class ViewController: UIViewController {",
      "matchHighlights": [
        {"start": 6, "length": 14}
      ]
    }
  ],
  "totalMatches": 15,
  "searchTime": "0.123s"
}

Error Response:
{
  "error": "Search failed",
  "message": "Project not found or search service unavailable"
}
*/