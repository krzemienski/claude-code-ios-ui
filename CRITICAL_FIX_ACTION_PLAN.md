# Critical Fix Action Plan - Claude Code iOS App
**Priority**: 🔴 URGENT - Production Blockers
**Generated**: January 21, 2025 5:05 AM PST
**Estimated Fix Time**: 2-3 days for all critical issues

## 🔴 DAY 1: Critical WebSocket Fixes (8 hours)

### Fix #1: Chat WebSocket Message Sending (3 hours)
**File**: `WebSocketManager.swift`
**Issue**: Messages fail with ❌ error immediately

```swift
// CURRENT (BROKEN):
let message = [
    "type": "claude-command",
    "content": messageText,
    "projectPath": projectPath
]

// FIX:
let message = [
    "type": "claude-command",
    "content": messageText,
    "projectPath": projectPath,
    "sessionId": currentSessionId,  // Add session ID
    "timestamp": Date().timeIntervalSince1970  // Add timestamp
]

// Also verify JWT token is included in connection:
var request = URLRequest(url: wsURL)
request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
```

**Testing**:
1. Send test message "Hello Claude"
2. Verify no ❌ error appears
3. Check backend logs for message receipt
4. Verify response displays in chat

### Fix #2: Terminal WebSocket Command Execution (3 hours)
**File**: `ShellWebSocketManager.swift`
**Issue**: Commands echo but don't execute

```swift
// CURRENT (BROKEN):
func sendCommand(_ command: String) {
    terminalOutput.append("$ \(command)")  // Just echoing
}

// FIX:
func sendCommand(_ command: String) {
    let message = [
        "type": "shell-command",
        "command": command,
        "cwd": currentDirectory
    ]
    
    if let data = try? JSONSerialization.data(withJSONObject: message) {
        webSocket?.send(.data(data))
    }
}

// Handle shell output response:
func handleShellOutput(_ data: Data) {
    if let response = try? JSONDecoder().decode(ShellResponse.self, from: data) {
        if response.type == "shell-output" {
            terminalOutput.append(response.output)
            if response.error {
                // Handle error output differently
            }
        }
    }
}
```

**Testing**:
1. Type "1" to accept trust dialog
2. Verify dialog dismisses
3. Type "ls" command
4. Verify actual directory listing appears
5. Type "pwd" and verify path output

### Fix #3: Terminal Trust Dialog Dismissal (2 hours)
**File**: `TerminalViewController.swift`
**Issue**: Dialog persists after accepting

```swift
// CURRENT (BROKEN):
func handleTrustResponse(_ response: String) {
    if response == "1" {
        // Not dismissing dialog
    }
}

// FIX:
func handleTrustResponse(_ response: String) {
    if response == "1" {
        trustDialogView.removeFromSuperview()
        trustDialogActive = false
        shellWebSocket.setTrusted(true)
        
        // Clear the echoed "$ 1" from terminal
        if let lastLine = terminalOutput.last, lastLine == "$ 1" {
            terminalOutput.removeLast()
        }
    }
}
```

## 🔴 DAY 2: Tab Navigation & UI Fixes (8 hours)

### Fix #4: Tab Bar View Controller Assignment (4 hours)
**File**: `MainTabBarController.swift`
**Issue**: Wrong controllers assigned to tabs

```swift
// CURRENT (BROKEN):
viewControllers = [
    projectsNav,     // Index 0 ✅
    terminalNav,     // Index 1 ✅
    searchNav,       // Index 2 - Shows in MCP position
    mcpNav,          // Index 3 - Shows in Settings position
    settingsNav      // Index 4 - Not accessible
]

// FIX:
viewControllers = [
    projectsNav,     // Index 0 - Projects ✅
    terminalNav,     // Index 1 - Terminal ✅
    searchNav,       // Index 2 - Search (needs implementation)
    mcpNav,          // Index 3 - MCP (needs implementation)
    settingsNav      // Index 4 - Settings
]

// Also fix tab bar items:
projectsNav.tabBarItem = UITabBarItem(title: "Projects", image: UIImage(systemName: "folder"), tag: 0)
terminalNav.tabBarItem = UITabBarItem(title: "Terminal", image: UIImage(systemName: "terminal"), tag: 1)
searchNav.tabBarItem = UITabBarItem(title: "Search", image: UIImage(systemName: "magnifyingglass"), tag: 2)
mcpNav.tabBarItem = UITabBarItem(title: "MCP", image: UIImage(systemName: "server.rack"), tag: 3)
settingsNav.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), tag: 4)
```

### Fix #5: Search Feature Implementation (2 hours)
**File**: `SearchViewController.swift`
**Issue**: Empty view with just heading

```swift
// ADD:
class SearchViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Search"
        setupSearchBar()
        setupTableView()
    }
    
    func performSearch(_ query: String) {
        APIClient.shared.searchProjects(query: query) { result in
            switch result {
            case .success(let results):
                self.displayResults(results)
            case .failure(let error):
                self.showError(error)
            }
        }
    }
}
```

### Fix #6: MCP Server Management UI (2 hours)
**File**: `MCPServersViewController.swift`
**Issue**: Empty view with just heading

```swift
// ADD:
class MCPServersViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var servers: [MCPServer] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "MCP Servers"
        setupTableView()
        loadServers()
        
        // Add button for new server
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addServer)
        )
    }
    
    func loadServers() {
        APIClient.shared.getMCPServers { result in
            switch result {
            case .success(let servers):
                self.servers = servers
                self.tableView.reloadData()
            case .failure(let error):
                self.showError(error)
            }
        }
    }
}
```

## 🟡 DAY 3: Error Handling & Polish (8 hours)

### Fix #7: WebSocket Reconnection Logic (3 hours)
**Files**: `WebSocketManager.swift`, `ShellWebSocketManager.swift`

```swift
// ADD to both managers:
private var reconnectTimer: Timer?
private var reconnectAttempts = 0
private let maxReconnectAttempts = 5

func handleDisconnection() {
    guard reconnectAttempts < maxReconnectAttempts else {
        showPermanentError()
        return
    }
    
    reconnectAttempts += 1
    let delay = Double(reconnectAttempts) * 2.0 // Exponential backoff
    
    reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
        self.connect()
    }
}

func handleSuccessfulConnection() {
    reconnectAttempts = 0
    reconnectTimer?.invalidate()
    updateUIForConnected()
}
```

### Fix #8: Error Handling UI (2 hours)
**File**: Create `ErrorBannerView.swift`

```swift
class ErrorBannerView: UIView {
    enum ErrorType {
        case disconnected
        case messageFailure
        case networkError
    }
    
    func showError(_ type: ErrorType, message: String) {
        // Animated banner that slides down
        // Shows error with retry button
        // Auto-dismisses after successful retry
    }
}
```

### Fix #9: Loading States (2 hours)
**Files**: All ViewControllers

```swift
// ADD to each ViewController:
private let loadingIndicator = CyberpunkLoadingIndicator()

func showLoading() {
    view.addSubview(loadingIndicator)
    loadingIndicator.startAnimating()
}

func hideLoading() {
    loadingIndicator.stopAnimating()
    loadingIndicator.removeFromSuperview()
}
```

### Fix #10: Message Status Updates (1 hour)
**File**: `ChatViewController.swift`

```swift
// FIX status indicator updates:
func updateMessageStatus(_ messageId: String, status: MessageStatus) {
    if let index = messages.firstIndex(where: { $0.id == messageId }) {
        messages[index].status = status
        
        // Update specific cell, not entire table
        let indexPath = IndexPath(row: index, section: 0)
        if let cell = tableView.cellForRow(at: indexPath) as? MessageCell {
            cell.updateStatus(status)
        }
    }
}
```

## Testing Checklist After Fixes

### WebSocket Testing
- [ ] Send 10 messages rapidly - all should succeed
- [ ] Execute 5 terminal commands - all should run
- [ ] Kill backend and verify reconnection works
- [ ] Test with poor network conditions

### Navigation Testing
- [ ] Tap each tab 10 times - correct content shows
- [ ] Navigate deep and use back buttons
- [ ] Rotate device - state preserved
- [ ] Background/foreground app - state preserved

### Error Recovery Testing
- [ ] Turn off WiFi - error banner appears
- [ ] Turn on WiFi - auto-reconnects
- [ ] Send message while offline - queued
- [ ] Come online - queued messages sent

### Performance Testing
- [ ] Memory stays under 150MB
- [ ] No memory leaks after 10 min use
- [ ] 60 FPS maintained during scrolling
- [ ] Launch time under 2 seconds

## Implementation Order

1. **Hour 0-3**: Fix Chat WebSocket (Fix #1)
2. **Hour 3-6**: Fix Terminal WebSocket (Fix #2)
3. **Hour 6-8**: Fix Trust Dialog (Fix #3)
4. **Hour 8-12**: Fix Tab Navigation (Fix #4)
5. **Hour 12-14**: Implement Search (Fix #5)
6. **Hour 14-16**: Implement MCP UI (Fix #6)
7. **Hour 16-19**: Add Reconnection (Fix #7)
8. **Hour 19-21**: Add Error UI (Fix #8)
9. **Hour 21-23**: Add Loading States (Fix #9)
10. **Hour 23-24**: Fix Message Status (Fix #10)

## Success Criteria
- All messages send without errors
- All terminal commands execute properly
- All tabs show correct content
- Search returns real results
- MCP servers can be managed
- Errors show helpful messages
- Auto-reconnection works
- Loading states appear during operations
- App doesn't crash under any condition
- Memory usage stays within limits

## Files to Modify
1. `WebSocketManager.swift` - Fix message format
2. `ShellWebSocketManager.swift` - Fix command execution
3. `TerminalViewController.swift` - Fix trust dialog
4. `MainTabBarController.swift` - Fix tab assignment
5. `SearchViewController.swift` - Implement search
6. `MCPServersViewController.swift` - Implement MCP UI
7. `ChatViewController.swift` - Fix status updates
8. Create `ErrorBannerView.swift` - Error handling
9. Create `CyberpunkLoadingIndicator.swift` - Loading states
10. Update all ViewControllers - Add loading/error handling

---
*This action plan addresses all critical issues found during production testing.*
*Estimated total time: 24 hours of focused development work.*