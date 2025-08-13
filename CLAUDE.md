# CLAUDE.md - Comprehensive iOS Claude Code UI Implementation Guide [237 Total Tasks]

This file provides comprehensive guidance for implementing and fixing the iOS Claude Code UI application.
Last Analysis: 2025-01-14 | Backend: Node.js Express | iOS: Swift 5.9 UIKit/SwiftUI

## Project Overview

Native iOS client for Claude Code with a cyberpunk-themed UI that communicates with a Node.js backend server.

**Key Technologies:**
- **iOS App**: Swift 5.9, UIKit + SwiftUI, iOS 17.0+, MVVM + Coordinators, SwiftData
- **Backend**: Node.js + Express on port 3004, WebSocket for real-time chat, SQLite database
- **Design**: Cyberpunk theme (Cyan #00D9FF, Pink #FF006E)
- **Development**: Docker support for containerized iOS development

## Project Status Summary

### ✅ COMPLETED FEATURES
- Basic project structure and navigation (AppCoordinator, MainTabBarController)
- Data models (Project, Session, Message with fullPath support)
- APIClient with partial endpoint implementation
- WebSocketManager base implementation
- SessionListViewController and SessionTableViewCell UI
- ChatViewController base UI
- Cyberpunk theme and visual effects
- Authentication status checking
- Projects list loading from backend

### 🔄 IN PROGRESS FEATURES
- WebSocket real-time messaging (wrong endpoint URL)
- Session management (UI exists but not functional)
- Chat message display and sending
- File explorer integration
- Terminal command execution

### ❌ NOT STARTED FEATURES
- Full authentication flow
- Settings persistence
- Offline caching with SwiftData
- Push notifications
- Widget extension
- Share extension
- App shortcuts
- Spotlight integration

## Critical Issues to Fix Immediately

### 🚨 P0 - BLOCKING ISSUES (Must fix for basic functionality)

1. **WebSocket URL Mismatch**
   - Current: `ws://localhost:3004/api/chat/ws`
   - Should be: `ws://localhost:3004/ws`
   - File: ChatViewController.swift:236

2. **WebSocket Message Type Wrong**
   - Current: `type: "message"`
   - Should be: `type: "claude-command"` or `type: "cursor-command"`
   - File: WebSocketManager.swift:172

3. **Project Path Not Sent**
   - Current: Sends projectId
   - Should send: project.path
   - Files: ChatViewController.swift, WebSocketManager.swift

## Essential Commands

### Backend Server
```bash
# Start backend server (required for app functionality)
cd backend
npm install
npm start  # Runs on http://localhost:3004

# Development mode with auto-reload
npm run dev
```

### iOS Development
```bash
# Open Xcode project
open ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj

# Build in Xcode
# Cmd+B - Build
# Cmd+R - Run on simulator
# Cmd+U - Run tests
# Cmd+Shift+K - Clean build

# Docker-based Swift validation
docker-compose -f docker-compose-swift.yml up -d
docker exec -it ios-swift-validator swift build
```

### Docker Commands (for containerized development)
```bash
# Start macOS Docker container (requires KVM)
docker-compose up -d

# Swift validation container
docker-compose -f docker-compose-swift.yml up -d
./validate-swift.sh

# Build iOS app in Docker
./docker-build.sh
```

## Project Architecture

### iOS App Structure
```
ClaudeCodeUI-iOS/
├── Core/
│   ├── Config/          # AppConfig singleton, environment settings
│   ├── Navigation/      # AppCoordinator manages navigation flow
│   ├── Network/         # APIClient + WebSocketManager for backend communication
│   ├── Services/        # Business logic, caching, data management
│   └── Accessibility/   # VoiceOver support and accessibility features
├── Features/
│   ├── Projects/        # Project list and management (MVVM)
│   ├── Chat/           # Real-time messaging with WebSocket
│   ├── FileExplorer/   # File browsing with syntax highlighting
│   ├── Terminal/       # Command execution with ANSI support
│   ├── Settings/       # Theme, fonts, backup/restore
│   └── Onboarding/     # 6-page onboarding flow
├── Design/
│   ├── Theme/          # CyberpunkTheme with neon colors
│   └── Effects/        # Glow effects, animations, scanlines
└── Models/             # SwiftData entities (Project, ChatMessage, etc.)
```

### Key Design Patterns
- **MVVM + Coordinators**: ViewControllers → ViewModels → Models, with Coordinators managing navigation
- **Dependency Injection**: DIContainer provides services to ViewControllers
- **WebSocket Communication**: Real-time messaging with auto-reconnection
- **SwiftData Persistence**: Local data storage with automatic migrations

### Backend API Endpoints

For complete API documentation including all endpoints, request/response formats, and WebSocket protocols, see [API_DOCUMENTATION.md](./API_DOCUMENTATION.md).

**Key API Categories**:
- **Authentication**: User registration, login, JWT tokens
- **Projects**: Create, list, rename, delete projects
- **Sessions**: Get sessions, messages, manage chat history
- **Files**: File tree, read/write content
- **Git**: Status, commits, branches, remotes
- **Cursor Integration**: Config, MCP servers, sessions
- **WebSocket**: Real-time chat (`ws://localhost:3004/ws`)
- **Shell**: Terminal commands via WebSocket

## WebSocket Protocol
```javascript
// Connection
ws://localhost:3004/api/chat/ws

// Message format
{
  "type": "message|typing|status|error",
  "content": "...",
  "userId": "...",
  "timestamp": "ISO-8601",
  "metadata": {}
}

// Auto-reconnection with exponential backoff
// Max retries: 10, Max delay: 30s
```

## Testing Guide

### Functional Testing via Simulator
```bash
# STEP 1: Start backend server (required for real data)
cd backend
npm start

# STEP 2: Build iOS app
xcodebuild build \
  -project ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj \
  -scheme ClaudeCodeUI \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
  -derivedDataPath ./Build

# STEP 3: Boot and setup simulator
xcrun simctl boot "iPhone 15"
xcrun simctl install booted ./Build/Build/Products/Debug-iphonesimulator/ClaudeCodeUI.app
xcrun simctl launch booted com.claudecode.ui

# STEP 4: Verify functionality and capture screenshots
# Navigate through app: Projects → Session → Messages
# Monitor Xcode console for API calls and WebSocket messages
xcrun simctl io booted screenshot project-list.png
xcrun simctl io booted screenshot session-messages.png

# STEP 5: Test real-time messaging
# Send a message in chat view
# Verify WebSocket communication in console
# Screenshot the active chat with responses

# Using MCP XcodeBuild tools for automated testing
mcp__XcodeBuildMCP__build_run_sim_name_proj \
  projectPath: "ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj" \
  scheme: "ClaudeCodeUI" \
  simulatorName: "iPhone 15"

# Get simulator UI for touch interactions
mcp__XcodeBuildMCP__ui_describe_all \
  udid: "[simulator-uuid]"

# Touch specific elements
mcp__XcodeBuildMCP__ui_tap \
  udid: "[simulator-uuid]" \
  x: 100 \
  y: 200
```

### Key Test Scenarios
1. **Onboarding Flow**: 6-page flow, skip/complete options
2. **Project CRUD**: Create, read, update, delete projects
3. **WebSocket Connection**: Message send/receive, auto-reconnection
4. **File Operations**: Browse, create, rename, delete files
5. **Terminal Commands**: Execute commands, handle ANSI output
6. **Settings Backup/Restore**: Export/import JSON settings
7. **Accessibility**: VoiceOver support, Dynamic Type
8. **Performance**: <2s launch, <150MB memory, no leaks

## Common Development Tasks

### Add New Feature
1. Create feature folder in `Features/`
2. Implement ViewController + ViewModel (MVVM pattern)
3. Register in AppCoordinator for navigation
4. Add to MainTabBarController if needed
5. Update backend API if required
6. Add tests for new functionality

### Modify Theme
Edit `Design/Theme/CyberpunkTheme.swift`:
- Primary colors: cyan (#00D9FF), pink (#FF006E)
- Glow effects in `Design/Effects/GlowEffects.swift`
- Animations in `Design/Effects/AnimationEffects.swift`

### Debug WebSocket
1. Check backend logs for connection status
2. Monitor WebSocketManager logs in Xcode console
3. Verify reconnection strategy (exponential backoff)
4. Test with Charles Proxy for network inspection

### Handle Network Errors
All network calls use Result types:
```swift
APIClient.shared.request(.endpoint) { result in
    switch result {
    case .success(let data):
        // Handle success
    case .failure(let error):
        // Show error alert or retry
    }
}
```

## Performance Optimization

### Current Benchmarks
- App launch: <2 seconds
- Memory usage: <150MB baseline
- WebSocket reconnect: <3 seconds
- Screen transitions: <300ms

### Optimization Opportunities
- Implement lazy loading for large project lists
- Add image caching for avatars/thumbnails
- Use virtual scrolling for chat history
- Batch WebSocket messages
- Implement diff-based updates

## Known Issues & Workarounds

### Current Limitations
- Widget extension not implemented
- Push notifications not configured
- No authentication (localhost only)
- Share extension incomplete
- File size limited to 10MB

### Workarounds
- **WebSocket disconnection**: Auto-reconnects within 3 seconds
- **Large files**: Currently limited, implement chunked upload
- **Offline mode**: Basic caching exists, full offline pending

## Security Considerations

### Current State
- No authentication (localhost development only)
- No encryption at rest
- Basic input validation
- XSS prevention in WebViews

### Production Requirements
- Implement JWT authentication
- Add Keychain storage for sensitive data
- Enable certificate pinning
- Encrypt database with SQLCipher
- Add jailbreak detection

## Debugging Tips

### Console Logs
- **Xcode Console**: App lifecycle, errors, API calls
- **Backend Terminal**: Server requests, WebSocket events
- **Safari Web Inspector**: For WebView debugging
- **Instruments**: Memory leaks, performance profiling

### Common Issues
1. **Backend not reachable**: Ensure server running on port 3004
2. **WebSocket fails**: Check CORS settings in backend
3. **Build errors**: Clean build folder (Cmd+Shift+K)
4. **Simulator issues**: Reset simulator (Device → Erase All Content)

## Dependencies

### iOS (via Swift Package Manager)
- No external dependencies currently (uses native frameworks)

### Backend (package.json)
- express: Web framework
- ws: WebSocket support
- sqlite3: Database
- multer: File uploads
- helmet: Security headers
- cors: Cross-origin support

## 📋 COMPREHENSIVE IMPLEMENTATION TASKS (237 Total)

## SECTION 1: WEBSOCKET FIXES [P0 - CRITICAL - 12 Tasks]

### Task 1.1: Fix WebSocket URL Path ❌
**File**: ChatViewController.swift:236
**Current**: `ws://localhost:3004/api/chat/ws`
**Fix**: Change to `ws://localhost:3004/ws`
**Test**: Console should show "WebSocket connected" without 404 errors

### Task 1.2: Fix WebSocket Message Type ❌
**File**: WebSocketManager.swift:172
**Current**: `"type": "message"`
**Fix**: Change to `"type": "claude-command"` for Claude, `"type": "cursor-command"` for Cursor
**Test**: Backend should accept messages without "Unknown message type" errors

### Task 1.3: Add Project Path to WebSocket Messages ❌
**File**: WebSocketManager.swift:sendMessage method
**Current**: Sends projectId
**Fix**: Add `"projectPath": project.path` to message payload
**Test**: Backend should receive and process project path correctly

### Task 1.4: Implement Session ID Tracking ❌
**File**: WebSocketManager.swift
**Add**: Store sessionId from "session-created" response
**Test**: Verify sessionId persists across messages

### Task 1.5: Handle Claude Response Types ❌
**File**: ChatViewController.swift:547-579
**Add**: Handle "claude-output", "claude-response", "tool_use" message types
**Test**: Claude responses display correctly in chat

### Task 1.6: Fix WebSocket Reconnection URL ❌
**File**: ChatViewController.swift:472
**Current**: Reconnects to wrong URL
**Fix**: Use correct `/ws` path in reconnection

### Task 1.7: Add WebSocket Authentication ❌
**File**: ChatViewController.swift:239-241
**Current**: Token added as query param
**Fix**: Ensure token is properly formatted and sent

### Task 1.8: Implement Message Streaming ❌
**File**: ChatViewController.swift:581-605
**Add**: Proper streaming support for partial messages
**Test**: Long responses stream in real-time

### Task 1.9: Add Terminal WebSocket Connection ❌
**File**: TerminalViewController.swift
**Add**: Connect to `ws://localhost:3004/shell` for terminal
**Test**: Terminal commands execute and return output

### Task 1.10: Fix Message Status Updates ❌
**File**: ChatMessageCell.swift:727-737
**Add**: Update message status from sending → sent → delivered
**Test**: Status icons update correctly

### Task 1.11: Add Abort Session Support ❌
**File**: WebSocketManager.swift
**Add**: Send "abort-session" message type
**Test**: Can stop Claude mid-response

### Task 1.12: Implement Typing Indicators ❌
**File**: ChatViewController.swift:768-841
**Current**: UI exists but not triggered
**Fix**: Show typing when receiving streamed responses

## SECTION 2: SESSION MANAGEMENT [P0 - CRITICAL - 18 Tasks]

### Task 2.1: Create Session Selection UI ❌
**Files**: Create SessionListViewController.swift
**Implementation**: Table view with session cells
**Navigation**: Projects → Sessions → Chat

### Task 2.2: Implement Session Creation ❌
**File**: APIClient.swift
**Add**: createSession(projectPath:) method
**Backend**: POST /api/projects/:projectName/sessions

### Task 2.3: Add Session List Loading ❌
**File**: SessionListViewController.swift
**Add**: fetchSessions from backend
**Backend**: GET /api/projects/:projectName/sessions

### Task 2.4: Implement Session Deletion ❌
**File**: SessionListViewController.swift
**Add**: Swipe to delete sessions
**Backend**: DELETE /api/sessions/:sessionId

### Task 2.5: Add Session Persistence ❌
**File**: UserDefaults or SwiftData
**Add**: Store current sessionId per project
**Test**: Session resumes after app restart

### Task 2.6: Create Session Cell UI ❌
**File**: SessionTableViewCell.swift
**Design**: Summary, message count, last activity
**Theme**: Cyberpunk styling

### Task 2.7: Add Session Navigation ❌
**File**: ProjectDetailViewController.swift
**Add**: "View Sessions" button
**Navigation**: Push to SessionListViewController

### Task 2.8: Implement Session Sorting ❌
**File**: SessionListViewController.swift
**Add**: Sort by lastActivity, messageCount
**UI**: Segmented control for sort options

### Task 2.9: Add Session Search ❌
**File**: SessionListViewController.swift
**Add**: UISearchController for filtering
**Search**: By summary text

### Task 2.10: Implement Session Pagination ❌
**File**: SessionListViewController.swift
**Add**: Load more on scroll
**Backend**: Use limit/offset parameters

### Task 2.11: Add Pull to Refresh ❌
**File**: SessionListViewController.swift
**Add**: UIRefreshControl
**Action**: Reload sessions from backend

### Task 2.12: Create New Session Flow ❌
**File**: SessionListViewController.swift
**Add**: + button in navigation bar
**Flow**: Create session → Navigate to chat

### Task 2.13: Add Session Status Display ❌
**File**: SessionTableViewCell.swift
**Show**: Active/inactive/archived status
**Visual**: Different colors/icons per status

### Task 2.14: Implement Session Archiving ❌
**File**: SessionListViewController.swift
**Add**: Archive action in swipe menu
**Backend**: Update session status

### Task 2.15: Add Session Export ❌
**File**: SessionDetailViewController.swift
**Add**: Export session as JSON/Markdown
**Share**: Via UIActivityViewController

### Task 2.16: Create Session Summary Generation ❌
**File**: Session.swift
**Add**: Auto-generate summary from messages
**Backend**: Use Claude to summarize

### Task 2.17: Add Session Continuation ❌
**File**: ChatViewController.swift
**Feature**: Continue previous session
**Load**: Previous messages and context

### Task 2.18: Implement Session Metrics ❌
**File**: SessionDetailViewController.swift
**Show**: Token count, duration, cost estimate
**Charts**: Message frequency over time

## SECTION 3: API IMPLEMENTATION [P1 - HIGH - 25 Tasks]

### Phase 1: Data Models & API Foundation
- [ ] **Task 1.1**: Create Swift data models
  - [ ] Create Models/Session.swift with id, summary, messageCount, lastActivity, cwd
  - [ ] Create Models/Message.swift with id, sessionId, content, role, timestamp, metadata
  - [ ] Update Models/Project.swift to include path and fullPath from API
  - [ ] **CHECKPOINT**: Compile project (Cmd+B) - verify no build errors
  - [ ] **GIT COMMIT**: "feat: Add Session and Message data models"

- [ ] **Task 1.2**: Update APIClient with session endpoints
  - [ ] Add fetchSessions(projectName:limit:offset:) method
  - [ ] Add fetchSessionMessages(projectName:sessionId:limit:offset:) method
  - [ ] Implement proper error handling and retry logic
  - [ ] **CHECKPOINT**: Compile and run on simulator (Cmd+R)
  - [ ] **TEST**: Call API methods in viewDidLoad to verify backend connectivity
  - [ ] **GIT COMMIT**: "feat: Add session and message API endpoints to APIClient"

### Phase 2: WebSocket Integration
- [ ] **Task 2.1**: Update WebSocketManager message types
  - [ ] Align message types with backend (claude-command, cursor-command, abort-session)
  - [ ] Update WebSocketMessageType enum with correct backend types
  - [ ] **CHECKPOINT**: Compile project - verify enum changes don't break existing code
  
- [ ] **Task 2.2**: Fix WebSocket message handling
  - [ ] Update sendMessage to include projectPath and sessionId parameters
  - [ ] Handle session-created responses and store sessionId
  - [ ] Parse claude-output and claude-response message types
  - [ ] Implement streaming response handling
  - [ ] **CHECKPOINT**: Run on simulator, test WebSocket connection to ws://localhost:3004/ws
  - [ ] **TEST**: Send test message and verify response in console
  - [ ] **GIT COMMIT**: "fix: Update WebSocketManager for backend compatibility"

### Phase 3: Session List UI
- [ ] **Task 3.1**: Create SessionListViewController
  - [ ] Create Features/Sessions/SessionListViewController.swift
  - [ ] Create Features/Sessions/SessionTableViewCell.swift
  - [ ] Design cell with summary label, message count badge, timestamp
  - [ ] **CHECKPOINT**: Compile and verify UI layout in Interface Builder
  
- [ ] **Task 3.2**: Implement session list functionality
  - [ ] Add table view data source and delegate methods
  - [ ] Implement fetchSessions API call on viewDidLoad
  - [ ] Add pull-to-refresh functionality
  - [ ] Implement pagination with infinite scrolling
  - [ ] **CHECKPOINT**: Run on simulator, verify sessions load from backend
  - [ ] **TEST**: Pull to refresh, scroll to load more
  - [ ] **GIT COMMIT**: "feat: Add SessionListViewController with pagination"

### Phase 4: Chat Interface
- [ ] **Task 4.1**: Create ChatViewController
  - [ ] Create Features/Chat/ChatViewController.swift
  - [ ] Create Features/Chat/ChatMessageCell.swift
  - [ ] Design message bubbles with role-based styling
  - [ ] **CHECKPOINT**: Compile and preview UI in simulator
  
- [ ] **Task 4.2**: Implement chat functionality
  - [ ] Add message input bar with send button
  - [ ] Load message history on viewDidLoad
  - [ ] Implement message sending via WebSocket
  - [ ] Handle incoming messages and update UI
  - [ ] Add auto-scroll to bottom for new messages
  - [ ] **CHECKPOINT**: Run on simulator, test full chat flow
  - [ ] **TEST**: Send message, receive response, verify real-time updates
  - [ ] **GIT COMMIT**: "feat: Implement ChatViewController with real-time messaging"

### Phase 5: Project Detail Integration
- [ ] **Task 5.1**: Update ProjectDetailViewController
  - [ ] Add project path label to display full directory path
  - [ ] Add "View Sessions" button
  - [ ] Implement navigation to SessionListViewController
  - [ ] **CHECKPOINT**: Run on simulator, verify navigation flow
  - [ ] **TEST**: Navigate from project → sessions → chat
  - [ ] **GIT COMMIT**: "feat: Add session navigation to ProjectDetailViewController"

### Phase 6: UI Polish & Theme
- [ ] **Task 6.1**: Apply cyberpunk theme
  - [ ] Style chat bubbles: user (cyan #00D9FF), assistant (pink #FF006E)
  - [ ] Add glow effects to active elements
  - [ ] Implement smooth message animations
  - [ ] **CHECKPOINT**: Run on simulator, verify visual styling
  - [ ] **GIT COMMIT**: "style: Apply cyberpunk theme to chat interface"

### Phase 7: Data Persistence
- [ ] **Task 7.1**: Implement caching
  - [ ] Store sessionId in UserDefaults per project
  - [ ] Cache session list for offline viewing
  - [ ] Store recent messages in SwiftData
  - [ ] **CHECKPOINT**: Run on simulator, test offline mode
  - [ ] **TEST**: Kill backend, verify cached data displays
  - [ ] **GIT COMMIT**: "feat: Add offline caching for sessions and messages"

### Phase 8: Functional Testing & Validation
- [ ] **Task 8.1**: Build and Run on Simulator
  - [ ] Start backend server: `cd backend && npm start`
  - [ ] Build app: `xcodebuild build -project ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj -scheme ClaudeCodeUI -destination 'platform=iOS Simulator,name=iPhone 15'`
  - [ ] Boot simulator: `xcrun simctl boot "iPhone 15"`
  - [ ] Install app: `xcrun simctl install booted Build/Products/Debug-iphonesimulator/ClaudeCodeUI.app`
  - [ ] Launch app: `xcrun simctl launch booted com.claudecode.ui`
  - [ ] **VERIFICATION**: App launches successfully on simulator
  
- [ ] **Task 8.2**: Test Project & Session Navigation
  - [ ] Navigate to Projects list in running simulator
  - [ ] Verify project paths are displayed correctly from backend API
  - [ ] Touch a project to view details
  - [ ] Verify full project path is shown in detail view
  - [ ] Touch "View Sessions" to navigate to session list
  - [ ] **SCREENSHOT**: Capture session list showing all sessions with summaries
  - [ ] Check Xcode console logs to verify API calls succeeded
  
- [ ] **Task 8.3**: Test Message Display in Sessions
  - [ ] Touch a session from the list in simulator
  - [ ] Verify navigation to ChatViewController
  - [ ] Confirm all messages from that session are displayed
  - [ ] Check message bubbles show correct role (user/assistant)
  - [ ] Verify timestamps are displayed correctly
  - [ ] Swipe to scroll through message history to confirm pagination works
  - [ ] **SCREENSHOT**: Capture chat view showing session messages
  - [ ] Check console logs: messages should match backend data
  
- [ ] **Task 8.4**: Test Real-time Messaging
  - [ ] Touch the message input field to activate keyboard
  - [ ] Type a message in the input field
  - [ ] Touch send button to send message
  - [ ] Verify WebSocket sends claude-command with correct sessionId
  - [ ] Monitor console for WebSocket responses (claude-output, claude-response)
  - [ ] Confirm new messages appear in chat immediately
  - [ ] Verify typing indicators work during response
  - [ ] **SCREENSHOT**: Capture active chat with real-time messages
  - [ ] **LOG CHECK**: Console shows WebSocket message flow
  
- [ ] **Task 8.5**: Verify Data Accuracy
  - [ ] Compare displayed sessions with backend API response
  - [ ] Cross-check message content with backend database
  - [ ] Verify sessionId persistence in UserDefaults
  - [ ] Test app restart: session should resume correctly
  - [ ] **GIT COMMIT**: "test: Verify functional messaging features via simulator"

### Phase 9: Screenshots & Documentation
- [ ] **Task 9.1**: Capture screenshots
  - [ ] Screenshot 1: Projects list showing project paths
  - [ ] Screenshot 2: Project detail with full path displayed
  - [ ] Screenshot 3: Sessions list with summaries and message counts
  - [ ] Screenshot 4: Active chat with messages
  - [ ] Screenshot 5: Real-time messaging demonstration
  - [ ] Screenshot 6: Error states and loading indicators
  - [ ] **GIT COMMIT**: "docs: Add screenshots of messaging functionality"

### Phase 10: Final Integration
- [ ] **Task 10.1**: Final validation
  - [ ] Run full test suite (Cmd+U)
  - [ ] Check memory leaks with Instruments
  - [ ] Verify performance metrics
  - [ ] **GIT PUSH**: Push all commits to repository
  - [ ] **FINAL TEST**: Clean build, fresh install, complete user flow

## Implementation Commands for Agent

### Build & Run Commands
```bash
# Open Xcode project (for GUI development)
open ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj

# Command-line build with xcodebuild
xcodebuild build \
  -project ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj \
  -scheme ClaudeCodeUI \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
  -derivedDataPath ./Build

# Clean build
xcodebuild clean \
  -project ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj \
  -scheme ClaudeCodeUI

# Build and run on simulator
xcodebuild build-for-testing \
  -project ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj \
  -scheme ClaudeCodeUI \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Install and launch on simulator
xcrun simctl boot "iPhone 15"
xcrun simctl install "iPhone 15" ./Build/Products/Debug-iphonesimulator/ClaudeCodeUI.app
xcrun simctl launch "iPhone 15" com.claudecode.ui

# Run tests with xcodebuild
xcodebuild test \
  -project ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj \
  -scheme ClaudeCodeUI \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES

# Analyze build (static analysis)
xcodebuild analyze \
  -project ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj \
  -scheme ClaudeCodeUI

# Using MCP XcodeBuild tools (if configured)
mcp__XcodeBuildMCP__build_sim_name_proj \
  projectPath: "ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj" \
  scheme: "ClaudeCodeUI" \
  simulatorName: "iPhone 15"

# Xcode GUI shortcuts (when using Xcode.app)
# Cmd+B - Build/Compile (use after each major change)
# Cmd+R - Run on simulator (test functionality)
# Cmd+U - Run tests
# Cmd+Shift+K - Clean build folder

# Git commands (run from project root)
git add .
git commit -m "commit message"
git push origin main
```

### Testing Checklist
1. After each phase, compile (Cmd+B) to catch errors early
2. Run on simulator (Cmd+R) to test functionality
3. Commit working code before moving to next phase
4. Test with backend running: cd backend && npm start
5. Use Xcode console to monitor WebSocket messages
6. Check memory usage in Xcode debug navigator

### Task 3.1: Implement Authentication Flow ❌
**Files**: LoginViewController.swift, APIClient.swift
**Endpoints**: POST /api/auth/login, POST /api/auth/register
**Storage**: Keychain for JWT token

### Task 3.2: Add Project Creation API ❌
**File**: APIClient.swift
**Endpoint**: POST /api/projects
**Params**: name, path, description

### Task 3.3: Implement Project Deletion ❌
**File**: ProjectsViewController.swift
**Endpoint**: DELETE /api/projects/:projectName
**UI**: Swipe to delete with confirmation

### Task 3.4: Add File Tree API ❌
**File**: FileExplorerViewController.swift
**Endpoint**: GET /api/projects/:projectName/files
**Display**: Hierarchical file tree

### Task 3.5: Implement File Read API ❌
**File**: FileViewerViewController.swift
**Endpoint**: GET /api/projects/:projectName/files/content
**Feature**: Syntax highlighting

### Task 3.6: Add File Write API ❌
**File**: FileEditorViewController.swift
**Endpoint**: PUT /api/projects/:projectName/files/content
**Save**: Auto-save with debouncing

### Task 3.7: Implement File Creation ❌
**File**: FileExplorerViewController.swift
**Endpoint**: POST /api/projects/:projectName/files
**UI**: New file dialog

### Task 3.8: Add File Deletion ❌
**File**: FileExplorerViewController.swift
**Endpoint**: DELETE /api/projects/:projectName/files
**Confirm**: Alert before deletion

### Task 3.9: Implement Git Status API ❌
**File**: GitViewController.swift
**Endpoint**: GET /api/projects/:projectName/git/status
**Display**: Changed files list

### Task 3.10: Add Git Commit API ❌
**File**: GitViewController.swift
**Endpoint**: POST /api/projects/:projectName/git/commit
**UI**: Commit message dialog

### Task 3.11: Implement Git Branch API ❌
**File**: GitViewController.swift
**Endpoint**: GET /api/projects/:projectName/git/branches
**Feature**: Branch switching

### Task 3.12: Add Git Push/Pull ❌
**File**: GitViewController.swift
**Endpoints**: POST /git/push, POST /git/pull
**Auth**: Git credentials storage

### Task 3.13: Implement Search API ❌
**File**: SearchViewController.swift
**Endpoint**: POST /api/projects/:projectName/search
**Feature**: Full-text search in project

### Task 3.14: Add Settings Sync API ❌
**File**: SettingsViewController.swift
**Endpoint**: GET/PUT /api/settings
**Sync**: User preferences to backend

### Task 3.15: Implement MCP Server API ❌
**File**: MCPViewController.swift
**Endpoint**: GET /api/mcp/servers
**Display**: Available MCP servers

### Task 3.16: Add Cursor Integration API ❌
**File**: CursorViewController.swift
**Endpoints**: /api/cursor/config, /api/cursor/sessions
**Feature**: Cursor AI integration

### Task 3.17: Implement Analytics API ❌
**File**: AnalyticsService.swift
**Endpoint**: POST /api/analytics/events
**Track**: User actions and metrics

### Task 3.18: Add Backup/Restore API ❌
**File**: BackupViewController.swift
**Endpoints**: POST /api/backup, POST /api/restore
**Feature**: Full project backup

### Task 3.19: Implement Export API ❌
**File**: ExportViewController.swift
**Endpoint**: POST /api/export
**Formats**: ZIP, TAR, Git bundle

### Task 3.20: Add Import API ❌
**File**: ImportViewController.swift
**Endpoint**: POST /api/import
**Sources**: GitHub, GitLab, local

### Task 3.21: Implement Collaboration API ❌
**File**: CollaborationViewController.swift
**Endpoint**: GET/POST /api/collaborators
**Feature**: Multi-user support

### Task 3.22: Add Notifications API ❌
**File**: NotificationService.swift
**Endpoint**: GET /api/notifications
**Push**: APNs integration

### Task 3.23: Implement Templates API ❌
**File**: TemplatesViewController.swift
**Endpoint**: GET /api/templates
**Feature**: Project templates

### Task 3.24: Add Plugins API ❌
**File**: PluginsViewController.swift
**Endpoint**: GET /api/plugins
**Feature**: Extension system

### Task 3.25: Implement Health Check API ❌
**File**: HealthService.swift
**Endpoint**: GET /api/health
**Monitor**: Backend status

## SECTION 4: UI/UX IMPROVEMENTS [P1 - HIGH - 30 Tasks]

### Task 4.1: Add Loading States ❌
### Task 4.2: Implement Skeleton Screens ❌
### Task 4.3: Add Empty States ❌
### Task 4.4: Create Error Views ❌
### Task 4.5: Add Pull-to-Refresh ❌
### Task 4.6: Implement Infinite Scroll ❌
### Task 4.7: Add Search Bars ❌
### Task 4.8: Create Filter Options ❌
### Task 4.9: Add Sort Controls ❌
### Task 4.10: Implement Swipe Actions ❌
### Task 4.11: Add Context Menus ❌
### Task 4.12: Create Action Sheets ❌
### Task 4.13: Add Floating Action Button ❌
### Task 4.14: Implement Tab Bar Badges ❌
### Task 4.15: Add Navigation Breadcrumbs ❌
### Task 4.16: Create Onboarding Flow ❌
### Task 4.17: Add Tool Tips ❌
### Task 4.18: Implement Coach Marks ❌
### Task 4.19: Add Keyboard Shortcuts ❌
### Task 4.20: Create Quick Actions ❌
### Task 4.21: Add 3D Touch Support ❌
### Task 4.22: Implement Haptic Feedback ❌
### Task 4.23: Add Sound Effects ❌
### Task 4.24: Create Animations ❌
### Task 4.25: Add Transitions ❌
### Task 4.26: Implement Dark Mode ❌
### Task 4.27: Add Theme Switching ❌
### Task 4.28: Create Custom Fonts ❌
### Task 4.29: Add Accessibility Labels ❌
### Task 4.30: Implement VoiceOver ❌

## SECTION 5: DATA PERSISTENCE [P2 - MEDIUM - 20 Tasks]

### Task 5.1-5.20: SwiftData Models, Migrations, Caching, Sync

## SECTION 6: FILE EXPLORER [P2 - MEDIUM - 15 Tasks]

### Task 6.1-6.15: Tree View, Syntax Highlighting, File Operations

## SECTION 7: TERMINAL INTEGRATION [P2 - MEDIUM - 12 Tasks]

### Task 7.1-7.12: ANSI Parsing, Command History, Auto-complete

## SECTION 8: AUTHENTICATION [P1 - HIGH - 10 Tasks]

### Task 8.1-8.10: JWT, Biometrics, Keychain, OAuth

## SECTION 9: TESTING [P1 - HIGH - 25 Tasks]

### Task 9.1-9.25: Unit Tests, UI Tests, Integration Tests

## SECTION 10: PERFORMANCE [P2 - MEDIUM - 15 Tasks]

### Task 10.1-10.15: Profiling, Optimization, Memory Management

## SECTION 11: SECURITY [P1 - HIGH - 12 Tasks]

### Task 11.1-11.12: Encryption, Certificate Pinning, Jailbreak Detection

## SECTION 12: ACCESSIBILITY [P2 - MEDIUM - 10 Tasks]

### Task 12.1-12.10: VoiceOver, Dynamic Type, Reduced Motion

## SECTION 13: LOCALIZATION [P3 - LOW - 8 Tasks]

### Task 13.1-13.8: String Files, RTL Support, Date Formatting

## SECTION 14: EXTENSIONS [P3 - LOW - 10 Tasks]

### Task 14.1-14.10: Widget, Share Extension, Shortcuts

## SECTION 15: DEPLOYMENT [P1 - HIGH - 15 Tasks]

### Task 15.1-15.15: App Store, TestFlight, CI/CD

## 📈 Progress Tracking

**Total Tasks**: 237
**Completed**: 15 (6.3%)
**In Progress**: 8 (3.4%)
**Not Started**: 214 (90.3%)

**By Priority**:
- P0 Critical: 30 tasks (WebSocket + Sessions)
- P1 High: 92 tasks (API + UI + Auth + Testing)
- P2 Medium: 82 tasks (Features + Performance)
- P3 Low: 33 tasks (Nice-to-have)

## Code Style Guidelines

### Swift
- Use Swift 5.9 features (async/await, actors)
- Follow MVC/MVVM patterns consistently
- Weak self in closures to prevent retain cycles
- Mark classes final when not inherited
- Use SwiftLint rules (if configured)

### JavaScript (Backend)
- ES6+ syntax with async/await
- Express middleware pattern
- Error-first callbacks
- Consistent error handling with try/catch