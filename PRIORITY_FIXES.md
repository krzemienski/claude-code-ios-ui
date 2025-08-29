# Priority Implementation Fixes

## 1. MCP Server UI Tab Visibility Fix (P0 - CRITICAL)

### Issue Analysis
The MCP tab is configured in `MainTabBarController.swift` but may not be visible due to iOS tab bar behavior with 5+ tabs.

### Root Cause
```swift
// MainTabBarController.swift lines 116-117
viewControllers = [projectsNav, terminalNav, searchNav, mcpNav, settingsNav]
// 5 tabs: iOS shows first 4 + "More" tab
// MCP tab at index 3 should be visible, Settings at index 4 goes to "More"
```

### Solution Options

#### Option A: Reorder Tabs (Recommended)
```swift
// Move Settings to More menu, keep MCP visible
viewControllers = [projectsNav, terminalNav, mcpNav, searchNav, settingsNav]
// Or reduce to 4 main tabs
viewControllers = [projectsNav, terminalNav, mcpNav, settingsNav]
```

#### Option B: Custom Tab Bar
- Implement custom tab bar controller with horizontal scrolling
- Allow all 5 tabs to be directly accessible

### Files to Modify
1. **MainTabBarController.swift**
   - Line 117: Reorder viewControllers array
   - Lines 219-225: Update switch methods
   - Test tab accessibility

2. **AppCoordinator.swift** (if exists)
   - Update navigation logic for reordered tabs

### Testing Plan
- Build and run in simulator
- Verify all tabs are accessible
- Test tab switching functionality
- Confirm MCP features work correctly

## 2. Search Mock Data Replacement (P1 - HIGH)

### Current Implementation Issue
```swift
// SearchViewController.swift lines 132-140
private func executeSearch(query: String) {
    // TODO: Replace with actual API call when backend implements search endpoint
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
        self?.searchResults = self?.generateMockResults(for: query) ?? []
        // ...
    }
}
```

### Backend Dependency
**Missing Endpoint**: `POST /api/projects/:projectName/search`

**Expected Request**:
```json
{
  "query": "search term",
  "scope": "files|content|both",
  "fileTypes": ["swift", "js", "json"],
  "caseSensitive": false,
  "regex": false
}
```

**Expected Response**:
```json
{
  "results": [
    {
      "fileName": "ViewController.swift",
      "filePath": "/project/ViewController.swift",
      "lineNumber": 42,
      "lineContent": "class ViewController: UIViewController {",
      "matchHighlights": [{"start": 6, "length": 14}]
    }
  ],
  "totalMatches": 15,
  "searchTime": "0.123s"
}
```

### Implementation Steps

1. **Add API Method to APIClient.swift**
```swift
func searchInProject(
    projectName: String,
    query: String,
    scope: String = "both",
    fileTypes: [String] = [],
    completion: @escaping (Result<SearchResponse, APIError>) -> Void
) {
    let endpoint = "/api/projects/\(projectName)/search"
    let parameters: [String: Any] = [
        "query": query,
        "scope": scope,
        "fileTypes": fileTypes
    ]
    // Implementation...
}
```

2. **Create Search Models**
```swift
struct SearchResponse: Codable {
    let results: [SearchResult]
    let totalMatches: Int
    let searchTime: String
}

struct SearchResult: Codable {
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
```

3. **Replace Mock Implementation**
```swift
private func executeSearch(query: String) {
    guard let currentProject = getCurrentProject() else {
        // Handle no project selected
        return
    }
    
    APIClient.shared.searchInProject(
        projectName: currentProject.name,
        query: query
    ) { [weak self] result in
        DispatchQueue.main.async {
            switch result {
            case .success(let response):
                self?.searchResults = response.results.map { self?.convertToViewResult($0) }
                self?.updateUI()
            case .failure(let error):
                self?.showError(error.localizedDescription)
            }
            self?.isSearching = false
            self?.activityIndicator.stopAnimating()
        }
    }
}
```

### Files to Modify
1. **SearchViewController.swift**
   - Replace executeSearch method (lines 128-140)
   - Add error handling
   - Add loading states

2. **APIClient.swift**
   - Add searchInProject method
   - Add search models

3. **SearchModels.swift** (new file)
   - Define search data models

## 3. Terminal WebSocket Status Verification (P2 - MEDIUM)

### Current Status: ✅ IMPLEMENTED
The terminal WebSocket is fully implemented with `ShellWebSocketManager.swift`. All core functionality is working:

- ✅ WebSocket connection to `ws://192.168.0.43:3004/shell`
- ✅ ANSI color parsing with 256 colors support
- ✅ Command history with persistence
- ✅ Terminal resize handling
- ✅ Auto-reconnection with exponential backoff

### Minor Enhancements Needed

1. **Connection Status Indicator**
```swift
// Add to TerminalViewController.swift
private lazy var connectionStatusView: UIView = {
    let view = UIView()
    view.backgroundColor = isShellConnected ? .green : .red
    view.layer.cornerRadius = 4
    // Add to navigation bar
    return view
}()
```

2. **Enhanced Command Auto-completion**
```swift
// Enhance handleTabCompletion method (line 834)
@objc private func handleTabCompletion() {
    guard let currentText = commandTextField.text, !currentText.isEmpty else { return }
    
    // Send completion request to backend
    shellWebSocketManager.requestCompletion(currentText) { [weak self] completions in
        self?.showCompletions(completions)
    }
}
```

### Testing Requirements
- Verify WebSocket connection stability
- Test command execution with various commands
- Test ANSI color rendering
- Test auto-reconnection after network interruption

## 4. Cursor Integration Placeholder (P3 - LOW PRIORITY)

### Current Status: ❌ NOT IMPLEMENTED (0/8 endpoints)

Since Cursor integration is complex and requires significant backend work, create placeholder implementations for future development.

### Minimal Implementation

1. **Create Basic Models**
```swift
// CursorModels.swift
struct CursorConfig: Codable {
    let enabled: Bool
    let databasePath: String?
    let syncInterval: TimeInterval
}

struct CursorSession: Codable {
    let id: String
    let name: String
    let lastModified: Date
    let fileCount: Int
}
```

2. **Create Placeholder View Controller**
```swift
// CursorViewController.swift
class CursorViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlaceholderUI()
    }
    
    private func setupPlaceholderUI() {
        // Show "Coming Soon" message
        // Add basic configuration options
        // Show integration status
    }
}
```

3. **Add to Tab Bar (Optional)**
```swift
// Only if needed for demo purposes
// Add 6th tab or replace existing tab temporarily
```

## Implementation Priority Order

### Week 1 (Critical Fixes)
1. **Day 1**: Fix MCP tab visibility - test and verify access
2. **Day 2**: Coordinate with backend team for search endpoint
3. **Day 3**: Implement search API integration (when backend ready)
4. **Day 4**: Add terminal connection status indicator
5. **Day 5**: Testing and bug fixes

### Week 2 (Enhancements)
1. **Day 1-2**: Search filters and advanced features
2. **Day 3**: Terminal auto-completion enhancements  
3. **Day 4**: UI polish and loading states
4. **Day 5**: Performance testing and optimization

### Optional Week 3 (Cursor Integration)
1. Create Cursor data models and placeholder UI
2. Plan backend integration architecture
3. Implement basic configuration management

## Dependencies and Blockers

### External Dependencies
1. **Backend Search Endpoint**: Required for P1 fix
2. **Backend Team Coordination**: For Cursor integration planning
3. **Testing Infrastructure**: Real device testing for WebSocket reliability

### Internal Dependencies
1. **Project Context**: Need current project selection for search
2. **Error Handling**: Consistent error handling across features
3. **UI Consistency**: Maintain cyberpunk theme across new features

### Risk Mitigation
1. **Search API**: Implement with mock fallback until backend ready
2. **WebSocket**: Add comprehensive offline mode
3. **Cursor Integration**: Start with read-only features, expand later

## Success Criteria

### P0 Success (MCP Tab)
- ✅ MCP tab is visible and accessible
- ✅ MCP server list loads from backend
- ✅ Add/remove server functionality works
- ✅ Server connection testing works

### P1 Success (Search)
- ✅ Search uses real backend data
- ✅ Search results display correctly
- ✅ Search performance <1 second
- ✅ Error handling for failed searches

### P2 Success (Terminal)
- ✅ WebSocket connection stable (>99% uptime)
- ✅ Command execution reliable
- ✅ ANSI colors render correctly
- ✅ Auto-reconnection works after network loss

### P3 Success (Cursor - Optional)
- ✅ Basic models and placeholder UI created
- ✅ Configuration management implemented
- ✅ Integration architecture documented

This priority-based approach ensures the most critical user-facing issues are resolved first while maintaining a clear path for future enhancements.