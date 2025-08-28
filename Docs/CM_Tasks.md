# Context Manager Task Breakdown for iOS Claude Code UI
Generated: January 2025 | Backend: http://192.168.0.43:3004
Total Endpoints: 52 (after removing Search/Cursor)

## 📊 Current State Summary

### ✅ Working Features
- Projects tab: List loading, navigation
- Terminal tab: WebSocket connection, ANSI colors  
- MCP Servers tab: API endpoints implemented
- Settings tab: Basic UI present
- WebSocket: Connection to ws://192.168.0.43:3004/ws
- Authentication: JWT token generation

### 🔴 Critical Issues
- Chat: Message status indicators broken
- Chat: Assistant responses filtered incorrectly
- Chat: No message persistence
- MCP: Server list UI not showing data
- Terminal: Command execution needs verification
- Missing APIs: Transcription, Settings sync

### 📱 Tab Configuration (After Search/Cursor Removal)
1. Projects (index 0) ✅
2. Terminal (index 1) ⚠️ 
3. MCP Servers (index 2) ⚠️
4. Settings (index 3) ⚠️

---

## 🔴 PHASE 1: CRITICAL CHAT FIXES [P0 - Must Fix Today]

### CM-CHAT-01: Fix Message Status Indicators
**File:** `Features/Chat/ChatViewController.swift` (lines 74-76)
**Current:** Per-message status tracking exists but not updating correctly
**TODO Embed:**
```swift
// TODO[CM-CHAT-01]: Fix message status state machine
// ISSUE: Status stuck on 'sending', never updates to 'delivered' or 'read'
// ACCEPTANCE: Status changes: sending → delivered (on WS response) → read (on view)
// PRIORITY: P0 - CRITICAL
// BACKEND: Check for status field in WebSocket response
// IMPLEMENTATION:
//   1. Track messageId in messageStatusTimers dict
//   2. On WebSocket response with matching ID, update to 'delivered'
//   3. On message visible in viewport, update to 'read'
//   4. Clear timer on status change
```

### CM-CHAT-02: Fix Assistant Response Filtering
**File:** `Features/Chat/ChatViewController.swift` (lines 1402-1421)
**Current:** Messages incorrectly filtered as UUID-only
**TODO Embed:**
```swift
// TODO[CM-CHAT-02]: Fix assistant message filtering logic
// ISSUE: Claude responses filtered out as "UUID-only" metadata
// ACCEPTANCE: All assistant messages with content display
// PRIORITY: P0 - CRITICAL
// FIX: Check message.role == "assistant" AND message.content != nil
// WARNING: Don't filter based on UUID pattern in content
```

### CM-CHAT-03: Add Message Persistence
**File:** `Features/Chat/ChatViewController.swift` + New SwiftData model
**Current:** Messages lost on app restart
**TODO Embed:**
```swift
// TODO[CM-CHAT-03]: Implement message persistence with SwiftData
// ISSUE: Messages not saved, lost on app restart
// ACCEPTANCE: Messages persist using SwiftData, reload on launch
// PRIORITY: P0 - CRITICAL
// IMPLEMENTATION:
//   1. Create MessageEntity SwiftData model
//   2. Save messages on receive/send
//   3. Load messages in viewDidLoad
//   4. Limit to last 100 messages for memory
```

### CM-CHAT-04: Fix WebSocket Reconnection
**File:** `Core/Network/WebSocketManager.swift`
**Current:** Reconnection exists but not exponential backoff
**TODO Embed:**
```swift
// TODO[CM-CHAT-04]: Implement exponential backoff for reconnection
// ISSUE: Fixed 3-second reconnect, needs exponential backoff
// ACCEPTANCE: 1s, 2s, 4s, 8s, 16s, max 30s retry intervals
// PRIORITY: P0 - CRITICAL
// NOTES: Reset backoff on successful connection
```

### CM-CHAT-05: Add Connection Status UI
**File:** `Features/Chat/ChatViewController.swift` (lines 41-44)
**Current:** Connection status view exists but not updating
**TODO Embed:**
```swift
// TODO[CM-CHAT-05]: Update connection status UI dynamically
// ISSUE: Connection status view not reflecting WebSocket state
// ACCEPTANCE: Shows "Connecting...", "Connected", "Disconnected", "Reconnecting..."
// PRIORITY: P0 - CRITICAL
// IMPLEMENTATION: Listen to WebSocketManagerDelegate callbacks
```

---

## 🟡 PHASE 2: TERMINAL VERIFICATION [P1 - High Priority]

### CM-TERM-01: Verify Shell WebSocket Connection
**File:** `Features/Terminal/TerminalViewController.swift`
**Current:** ShellWebSocketManager implemented
**TODO Embed:**
```swift
// TODO[CM-TERM-01]: Verify shell WebSocket connection
// ACCEPTANCE: Connects to ws://192.168.0.43:3004/shell
// PRIORITY: P1
// TEST: Log connection success/failure
// VERIFY: URL uses 192.168.0.43 not localhost
```

### CM-TERM-02: Test Command Execution
**File:** `Core/Network/ShellWebSocketManager.swift`
**Current:** Command format implemented
**TODO Embed:**
```swift
// TODO[CM-TERM-02]: Test command execution flow
// ACCEPTANCE: Commands execute, output displays with ANSI colors
// PRIORITY: P1
// TEST COMMANDS: "ls -la", "pwd", "echo test"
// MESSAGE FORMAT: {"type": "shell-command", "command": "ls", "cwd": "/"}
```

### CM-TERM-03: Validate ANSI Parser
**File:** `Features/Terminal/Utilities/ANSIColorParser.swift`
**Current:** Full ANSI support claimed
**TODO Embed:**
```swift
// TODO[CM-TERM-03]: Validate ANSI color parsing
// ACCEPTANCE: 16 colors, 256 colors, true color all render
// PRIORITY: P1
// TEST: "\033[31mRed\033[0m", "\033[38;5;214mOrange\033[0m"
```

### CM-TERM-04: Add Command History
**File:** `Features/Terminal/TerminalViewController.swift`
**Current:** Not implemented
**TODO Embed:**
```swift
// TODO[CM-TERM-04]: Implement command history
// ACCEPTANCE: Up/down arrows navigate history
// PRIORITY: P1
// STORAGE: UserDefaults with 100 command limit
```

---

## 🟠 PHASE 3: MCP SERVER MANAGEMENT [P1 - High Priority]

### CM-MCP-01: Fix Server List Loading
**File:** `Features/MCP/MCPServerListViewController.swift`
**Current:** UI exists but not showing data
**TODO Embed:**
```swift
// TODO[CM-MCP-01]: Connect server list to backend API
// ISSUE: Table view not populating with MCP servers
// ACCEPTANCE: Shows all servers from GET /api/mcp/servers
// PRIORITY: P1
// DEBUG: Check APIClient.getMCPServers() response
```

### CM-MCP-02: Implement Add Server Form
**File:** `Features/MCP/MCPServerFormViewController.swift` (create)
**Current:** Not implemented
**TODO Embed:**
```swift
// TODO[CM-MCP-02]: Create MCP server add/edit form
// ACCEPTANCE: Form with name, URL, API key fields
// PRIORITY: P1
// ENDPOINT: POST /api/mcp/servers
// VALIDATION: Required fields, URL format
```

### CM-MCP-03: Add Connection Test UI
**File:** `Features/MCP/MCPServerViewModel.swift`
**Current:** API exists, UI missing
**TODO Embed:**
```swift
// TODO[CM-MCP-03]: Add test connection button
// ACCEPTANCE: Button shows success/failure alert
// PRIORITY: P1  
// ENDPOINT: POST /api/mcp/servers/:id/test
// UI: Activity indicator during test
```

### CM-MCP-04: Fix Tab Visibility
**File:** `Core/Navigation/MainTabBarController.swift`
**Current:** Tab at index 2 after Search removal
**TODO Embed:**
```swift
// TODO[CM-MCP-04]: Verify MCP tab shows at index 2
// ACCEPTANCE: MCP Servers tab visible and accessible
// PRIORITY: P1
// NOTE: Was index 4, now index 2 after removing Search/Cursor
```

---

## 🔵 PHASE 4: MISSING API ENDPOINTS [P2 - Medium Priority]

### CM-API-01: Add Transcription Endpoint
**File:** `Core/Network/APIClient.swift`
**Current:** Not implemented
**TODO Embed:**
```swift
// TODO[CM-API-01]: Implement transcription endpoint
// ENDPOINT: POST /api/transcribe
// REQUEST: {audio: Data, format: String}
// RESPONSE: {text: String, confidence: Float}
// PRIORITY: P2
func transcribeAudio(audioData: Data, format: String) async throws -> TranscriptionResponse {
    // Implementation needed
}
```

### CM-API-02: Add Settings GET Endpoint
**File:** `Core/Network/APIClient.swift`
**Current:** Not implemented  
**TODO Embed:**
```swift
// TODO[CM-API-02]: Implement settings GET endpoint
// ENDPOINT: GET /api/settings
// RESPONSE: {theme: String, fontSize: Int, ...}
// PRIORITY: P2
func getSettings() async throws -> SettingsResponse {
    // Implementation needed
}
```

### CM-API-03: Add Settings POST Endpoint
**File:** `Core/Network/APIClient.swift`
**Current:** Not implemented
**TODO Embed:**
```swift
// TODO[CM-API-03]: Implement settings POST endpoint
// ENDPOINT: POST /api/settings
// REQUEST: {theme: String, fontSize: Int, ...}
// PRIORITY: P2
func updateSettings(_ settings: SettingsRequest) async throws {
    // Implementation needed
}
```

---

## 🟢 PHASE 5: UI/UX POLISH [P3 - Low Priority]

### CM-UI-01: Loading Skeletons
**File:** `Features/Projects/SkeletonCollectionViewCell.swift`
**Current:** Implemented
**TODO Embed:**
```swift
// TODO[CM-UI-01]: Verify skeleton loading states
// ACCEPTANCE: Skeletons show during data load
// PRIORITY: P3
// CHECK: ProjectsViewController, SessionListViewController
```

### CM-UI-02: Pull-to-Refresh
**File:** `Features/Sessions/SessionListViewController.swift`
**Current:** Partial implementation
**TODO Embed:**
```swift
// TODO[CM-UI-02]: Complete pull-to-refresh
// ACCEPTANCE: Cyberpunk-themed refresh with haptic feedback
// PRIORITY: P3
// IMPLEMENTATION: UIRefreshControl with custom tint
```

### CM-UI-03: Empty States
**File:** `Design/Components/NoDataView.swift`
**Current:** Exists for some views
**TODO Embed:**
```swift
// TODO[CM-UI-03]: Add empty states to all lists
// ACCEPTANCE: Custom empty views for no data scenarios
// PRIORITY: P3
// VIEWS: Sessions, Messages, MCP Servers, Files
```

### CM-UI-04: Swipe Actions
**File:** `Features/Sessions/SessionListViewController.swift`
**Current:** Not implemented
**TODO Embed:**
```swift
// TODO[CM-UI-04]: Add swipe actions
// ACCEPTANCE: Delete (red), Archive (yellow)
// PRIORITY: P3
// IMPLEMENTATION: UITableViewRowAction or UISwipeActionsConfiguration
```

---

## 📋 PHASE 6: XCUITESTS CREATION [P4 - Testing]

### CM-TEST-01: Create XCUITest Target
**File:** `ClaudeCodeUITests/` (new directory)
**Current:** Not created
**TODO Embed:**
```swift
// TODO[CM-TEST-01]: Create XCUITest target
// ACCEPTANCE: Test target with proper configuration
// PRIORITY: P4
// SETUP: Add UI Testing Bundle target in Xcode
```

### CM-TEST-02: App Launch Test
**File:** `ClaudeCodeUITests/LaunchTests.swift` (create)
**TODO Embed:**
```swift
// TODO[CM-TEST-02]: Test app launches successfully
// ACCEPTANCE: App launches, shows Projects tab
// PRIORITY: P4
class LaunchTests: XCTestCase {
    func testAppLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssert(app.tabBars.buttons["Projects"].exists)
    }
}
```

### CM-TEST-03: Chat Flow Test
**File:** `ClaudeCodeUITests/ChatFlowTests.swift` (create)
**TODO Embed:**
```swift
// TODO[CM-TEST-03]: Test Projects → Sessions → Chat flow
// ACCEPTANCE: Navigate through full flow
// PRIORITY: P4
// STEPS:
//   1. Tap project
//   2. Tap/create session
//   3. Send message
//   4. Verify response
```

### CM-TEST-04: Message Send/Receive Test
**File:** `ClaudeCodeUITests/MessageTests.swift` (create)
**TODO Embed:**
```swift
// TODO[CM-TEST-04]: Test message sending
// ACCEPTANCE: Message sends, response received
// PRIORITY: P4
// BACKEND: Requires backend running
// IDENTIFIER: assistantMessageCell for responses
```

### CM-TEST-05: Terminal Command Test
**File:** `ClaudeCodeUITests/TerminalTests.swift` (create)
**TODO Embed:**
```swift
// TODO[CM-TEST-05]: Test terminal commands
// ACCEPTANCE: Execute "ls", see output
// PRIORITY: P4
// TAB: Navigate to Terminal tab first
```

---

## 📊 Task Summary by Priority

### P0 - Critical (Must Fix Today) - 5 Tasks
- [ ] CM-CHAT-01: Fix message status indicators
- [ ] CM-CHAT-02: Fix assistant response filtering
- [ ] CM-CHAT-03: Add message persistence
- [ ] CM-CHAT-04: Fix WebSocket reconnection
- [ ] CM-CHAT-05: Add connection status UI

### P1 - High Priority (This Week) - 8 Tasks
- [ ] CM-TERM-01: Verify shell WebSocket
- [ ] CM-TERM-02: Test command execution
- [ ] CM-TERM-03: Validate ANSI parser
- [ ] CM-TERM-04: Add command history
- [ ] CM-MCP-01: Fix server list loading
- [ ] CM-MCP-02: Implement add server form
- [ ] CM-MCP-03: Add connection test UI
- [ ] CM-MCP-04: Fix tab visibility

### P2 - Medium Priority (Next Week) - 3 Tasks
- [ ] CM-API-01: Add transcription endpoint
- [ ] CM-API-02: Add settings GET endpoint
- [ ] CM-API-03: Add settings POST endpoint

### P3 - Low Priority (Polish) - 4 Tasks
- [ ] CM-UI-01: Verify loading skeletons
- [ ] CM-UI-02: Complete pull-to-refresh
- [ ] CM-UI-03: Add empty states
- [ ] CM-UI-04: Add swipe actions

### P4 - Testing (Validation) - 5 Tasks
- [ ] CM-TEST-01: Create XCUITest target
- [ ] CM-TEST-02: App launch test
- [ ] CM-TEST-03: Chat flow test
- [ ] CM-TEST-04: Message send/receive test
- [ ] CM-TEST-05: Terminal command test

---

## 🚀 Implementation Order

### Day 1: Critical Chat Fixes (P0)
1. Fix message status indicators (CM-CHAT-01)
2. Fix assistant response filtering (CM-CHAT-02)
3. Add message persistence (CM-CHAT-03)
4. Fix WebSocket reconnection (CM-CHAT-04)
5. Add connection status UI (CM-CHAT-05)

### Day 2: Terminal Integration (P1)
1. Verify shell WebSocket (CM-TERM-01)
2. Test command execution (CM-TERM-02)
3. Validate ANSI parser (CM-TERM-03)
4. Add command history (CM-TERM-04)

### Day 3: MCP Server Management (P1)
1. Fix server list loading (CM-MCP-01)
2. Implement add server form (CM-MCP-02)
3. Add connection test UI (CM-MCP-03)
4. Fix tab visibility (CM-MCP-04)

### Day 4: Missing APIs & UI Polish (P2-P3)
1. Add transcription endpoint (CM-API-01)
2. Add settings endpoints (CM-API-02, CM-API-03)
3. Complete UI polish tasks (CM-UI-01 to CM-UI-04)

### Day 5: Testing Suite (P4)
1. Create XCUITest target (CM-TEST-01)
2. Implement all test cases (CM-TEST-02 to CM-TEST-05)

---

## 📝 Backend Dependency Matrix

### WebSocket Endpoints
- **Chat:** ws://192.168.0.43:3004/ws ✅ (needs fixes)
- **Shell:** ws://192.168.0.43:3004/shell ⚠️ (needs verification)

### REST API Endpoints (52 Total)
#### Working (49):
- Authentication: 5/5 ✅
- Projects: 5/5 ✅
- Sessions: 6/6 ✅
- Files: 4/4 ✅
- Git: 20/20 ✅
- MCP: 6/6 ✅
- Feedback: 1/1 ✅
- Image: 1/1 ✅

#### Missing (3):
- Transcription: 0/1 ❌
- Settings GET: 0/1 ❌
- Settings POST: 0/1 ❌

---

## 🔧 Development Setup Requirements

### Backend Server
```bash
cd backend
npm start
# Running at http://192.168.0.43:3004
```

### iOS Simulator
- **UUID:** A707456B-44DB-472F-9722-C88153CDFFA1
- **Device:** iPhone 16 Pro Max
- **iOS:** 18.6

### Testing Commands
```bash
# Build for simulator
xcodebuild build \
  -project ClaudeCodeUI.xcodeproj \
  -scheme ClaudeCodeUI \
  -destination 'platform=iOS Simulator,id=A707456B-44DB-472F-9722-C88153CDFFA1'

# Run XCUITests
xcodebuild test \
  -project ClaudeCodeUI.xcodeproj \
  -scheme ClaudeCodeUITests \
  -destination 'platform=iOS Simulator,id=A707456B-44DB-472F-9722-C88153CDFFA1'
```

---

## ✅ Success Criteria

### Chat Feature Complete When:
- Messages show correct status (sending → delivered → read)
- All assistant responses display without filtering
- Messages persist across app restarts
- WebSocket reconnects with exponential backoff
- Connection status shows in UI

### Terminal Feature Complete When:
- Shell WebSocket connects successfully
- Commands execute and show output
- ANSI colors render correctly
- Command history works with arrow keys

### MCP Feature Complete When:
- Server list loads from backend
- Can add/edit/delete servers
- Connection testing works
- Tab is visible and accessible

### Testing Complete When:
- XCUITest target created
- All 5 test cases pass
- Can run tests in CI/CD

---

## 📌 Notes for iOS Developer

1. **Use specific simulator UUID:** A707456B-44DB-472F-9722-C88153CDFFA1
2. **Backend must be running:** http://192.168.0.43:3004
3. **Test with real backend:** Don't use mock data
4. **Check console logs:** Enable verbose logging for debugging
5. **Preserve existing code:** Don't delete working features
6. **Follow TODO format:** CM-XXX-## for tracking
7. **Test incrementally:** Verify each fix before moving on
8. **Use XCUITest identifiers:** Add accessibilityIdentifier to UI elements

---

*Generated by Context Manager Agent*
*Total Tasks: 25 (5 P0, 8 P1, 3 P2, 4 P3, 5 P4)*
*Estimated Completion: 5 days with focused effort*