# Agent 004: UI Navigation & Flow Implementation Report

## Current Navigation Structure Analysis

### 1. MainTabBarController.swift
- **Location**: `/Core/Navigation/MainTabBarController.swift`
- **Status**: ✅ Properly configured
- **Key Features**:
  - 5 tabs: Projects, Terminal, MCP, Search, Settings
  - Projects tab is first (index 0)
  - Has `openChatForProject` method that pushes SessionListViewController
  - Proper navigation controller setup for each tab

### 2. ProjectsViewController.swift
- **Location**: `/Features/Projects/ProjectsViewController.swift`
- **Status**: ⚠️ Needs accessibility identifier fixes
- **Current Issues**:
  - Collection view identifier is "projectList" but tests expect "projectsTableView"
  - Project cells have identifiers like "project_{id}" but tests expect "firstProjectCell"
  - Missing proper navigation callback setup

### 3. SessionListViewController.swift
- **Location**: `/Features/Sessions/SessionListViewController.swift`
- **Status**: ⚠️ Needs accessibility identifiers
- **Issues**:
  - Missing "sessionsTableView" identifier
  - Missing "newSessionButton" identifier (currently "addSessionButton")
  - Table view needs proper setup

### 4. ChatViewController.swift
- **Location**: `/Features/Chat/ChatViewController.swift`
- **Status**: ⚠️ Needs major fixes
- **Issues**:
  - Input field identifier is "messageInput" but tests expect "chatInputField"
  - Send button identifier is "chatSendButton" but tests expect "sendButton"
  - Table view identifier is "messageList" but tests expect "messageTableView"

## Required Fixes for Phase 3 Test Flow

### Navigation Flow Issues:
1. **Launch → Projects**: ✅ Working (Projects tab is first)
2. **Select Project → Sessions**: ⚠️ Needs verification of push navigation
3. **Select/Create Session → Chat**: ❌ Need to implement proper navigation
4. **Send Messages → Display**: ❌ WebSocket delegate not properly connected
5. **Background/Restore → State**: ❌ No state restoration implemented

## Implementation Plan

### Step 1: Fix Accessibility Identifiers
```swift
// ProjectsViewController.swift
collectionView.accessibilityIdentifier = "projectsTableView" // Change from "projectList"

// Add to first project cell configuration
if indexPath.item == 0 {
    cell.accessibilityIdentifier = "firstProjectCell"
}

// SessionListViewController.swift
tableView.accessibilityIdentifier = "sessionsTableView"
navigationItem.rightBarButtonItem?.accessibilityIdentifier = "newSessionButton"

// ChatViewController.swift
inputTextView.accessibilityIdentifier = "chatInputField"
sendButton.accessibilityIdentifier = "sendButton"
tableView.accessibilityIdentifier = "messageTableView"
```

### Step 2: Fix Navigation Flow
```swift
// MainTabBarController.swift - openChatForProject method
private func openChatForProject(_ project: Project) {
    currentProject = project
    
    // Navigate to session list within the Projects tab
    if let projectsNav = viewControllers?[0] as? UINavigationController {
        let sessionListVC = SessionListViewController(project: project)
        sessionListVC.onSessionSelected = { [weak self] session in
            let chatVC = ChatViewController(project: project, session: session)
            projectsNav.pushViewController(chatVC, animated: true)
        }
        projectsNav.pushViewController(sessionListVC, animated: true)
    }
}
```

### Step 3: Add Session Selection Handler
```swift
// SessionListViewController.swift
var onSessionSelected: ((Session) -> Void)?

func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let session = filteredSessions[indexPath.row]
    onSessionSelected?(session)
}
```

### Step 4: Fix WebSocket Connection
```swift
// ChatViewController.swift - viewDidLoad
override func viewDidLoad() {
    super.viewDidLoad()
    // ... existing setup ...
    
    // CRITICAL: Set delegate BEFORE connecting
    self.webSocketManager.delegate = self
    
    if let session = currentSession {
        connectToSession(session)
    }
}
```

### Step 5: Add State Restoration
```swift
// ChatViewController.swift
override func encodeRestorableState(with coder: NSCoder) {
    super.encodeRestorableState(with: coder)
    coder.encode(currentSession?.id, forKey: "sessionId")
    coder.encode(project.id, forKey: "projectId")
}

override func decodeRestorableState(with coder: NSCoder) {
    super.decodeRestorableState(with: coder)
    // Restore session and project
}
```

## Priority Actions

### P0 - Critical (Must Fix Now):
1. ✅ Fix all accessibility identifiers
2. ✅ Ensure navigation from Projects → Sessions → Chat works
3. ✅ Connect WebSocket delegate properly
4. ✅ Make sure messages display in table view

### P1 - High (Fix Next):
1. ⏳ Add state restoration
2. ⏳ Fix message status updates
3. ⏳ Add proper error handling

### P2 - Medium (Nice to Have):
1. ⏳ Add loading indicators
2. ⏳ Add empty states
3. ⏳ Add pull-to-refresh

## Test Validation Commands

After each fix, run:
```bash
/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/Scripts/validate_compilation.sh
```

## Implementation Status

- [ ] Fix ProjectsViewController identifiers
- [ ] Fix SessionListViewController identifiers  
- [ ] Fix ChatViewController identifiers
- [ ] Add session selection handler
- [ ] Fix WebSocket delegate connection
- [ ] Add state restoration
- [ ] Validate with test script

## Notes

The main issue is that the UI tests expect specific accessibility identifiers that don't match what's currently in the code. Additionally, the navigation flow from Sessions to Chat is not properly implemented with callbacks.

The WebSocket delegate connection is critical - without it, messages won't display even if they're received.