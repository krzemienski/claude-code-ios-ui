# CLAUDE.md - Comprehensive iOS Claude Code UI Implementation Guide

This is the single source of truth for the iOS Claude Code UI project. 
Last Updated: January 16, 2025 | Backend: Node.js Express | iOS: Swift 5.9 UIKit/SwiftUI

## 🚨 iOS App Development Task Protocol

### Requirements Overview
This protocol serves as the single source of truth for iOS app development tasks. All documentation, todos, and implementation details have been consolidated into this CLAUDE.md file.

### Core Development Process
1. **Todo Consolidation**: All 500+ duplicate todos have been consolidated into the structured task list below
2. **Agent Requirements**: Development requires continuous use of:
   - @agent-context-manager for project state
   - @agent-ios-swift-developer for Swift implementation
   - @agent-ios-simulator-expert for testing
3. **Backend Connectivity**: Maintain continuous backend server connection (localhost:3004)
4. **Testing Protocol**: Use specific simulator UUID: 05223130-57AA-48B0-ABD0-4D59CE455F14

### Testing Framework Requirements
- **ALWAYS** use touch() with down/up events, NOT tap()
- **ALWAYS** call describe_ui() first for precise coordinates
- **NEVER** guess coordinates from screenshots
- Use background log streaming to avoid app restart issues

### Session Flow Analysis Protocol
Follow the 5-phase testing approach:
1. **Start Phase**: Backend initialization
2. **Project Phase**: Load projects from API
3. **Session Phase**: Create/load sessions
4. **Message Phase**: Send/receive via WebSocket
5. **Cleanup Phase**: Proper teardown

## 🟢 BACKEND API IMPLEMENTATION STATUS - UPDATED

### Backend Server Status: ✅ RUNNING
- Server: http://localhost:3004
- WebSocket: ws://localhost:3004/ws (✅ WORKING CORRECTLY)
- Shell WebSocket: ws://localhost:3004/shell  
- Database: SQLite with auth.db and store.db

### API Implementation Reality Check - UPDATED January 2025
- **Total Backend Endpoints**: 54 (including MCP)
- **Actually Implemented in iOS**: 43 endpoints (80%)
- **Missing in iOS**: 11 endpoints (20%)
- **Critical Issues**: Most "P0 issues" are already fixed!
- **MCP Server Management**: ✅ 6/6 endpoints (100% COMPLETE - tested and working!)

## ✅ WORKING FEATURES (Much More Than Previously Documented!)

### WebSocket Communication - ALREADY FIXED
- ✅ Using correct URL: `ws://localhost:3004/ws` (AppConfig.websocketURL)
- ✅ Using correct message type: `claude-command` (already implemented)
- ✅ Project path included in messages
- ✅ JWT authentication working
- ✅ Auto-reconnection with exponential backoff

### Git Integration - FULLY IMPLEMENTED (16/16 endpoints)
- ✅ gitStatus, gitCommit, gitBranches, gitCheckout
- ✅ gitCreateBranch, gitPush, gitPull, gitFetch
- ✅ gitDiff, gitLog, gitAdd, gitReset
- ✅ gitStash, gitGenerateCommitMessage
- ✅ gitCommits, gitCommitDiff, gitRemoteStatus
- ✅ gitPublish, gitDiscard, gitDeleteUntracked

### Session Management - COMPLETE
- ✅ Create sessions (with API integration)
- ✅ List sessions (with proper endpoints)
- ✅ Delete sessions
- ✅ Load session messages
- ✅ Session navigation flow

### Authentication - WORKING
- ✅ JWT token generation (fixed with correct timestamp)
- ✅ Token storage in UserDefaults
- ✅ Auto-authentication for WebSocket
- ✅ Development token hardcoded for testing

## Project Overview

Native iOS client for Claude Code with a cyberpunk-themed UI that communicates with a Node.js backend server.

**Key Technologies:**
- **iOS App**: Swift 5.9, UIKit + SwiftUI, iOS 17.0+, MVVM + Coordinators, SwiftData
- **Backend**: Node.js + Express on port 3004, WebSocket for real-time chat, SQLite database
- **Design**: Cyberpunk theme (Cyan #00D9FF, Pink #FF006E)
- **Development**: Docker support for containerized iOS development

## Project Status Summary

### ✅ COMPLETED FEATURES (43 of 54 endpoints = 80%)
- Basic project structure and navigation (AppCoordinator, MainTabBarController)
- Data models (Project, Session, Message with fullPath support)
- APIClient with 43 endpoints implemented
- WebSocketManager with correct implementation
- SessionListViewController with full CRUD operations + enhanced pull-to-refresh
- ChatViewController with working WebSocket
- Cyberpunk theme and visual effects with SkeletonView and NoDataView
- Authentication with JWT (working)
- Projects list loading from backend
- Session messages loading (working)
- **Git integration fully implemented (16/16 endpoints)**
- **MCP Server Management fully implemented (6/6 endpoints)**
- File operations (read, write, delete)
- Search functionality connected to real API

### 🔄 IN PROGRESS FEATURES
- File explorer UI connected to backend
- Terminal command execution via shell WebSocket
- UI polish and animations

### ❌ NOT STARTED FEATURES (25 of 62 endpoints = 40%)
- Cursor integration (0/8 endpoints)
- MCP server management (0/6 endpoints)
- Transcription API
- Search functionality
- Settings persistence to backend
- Offline caching with SwiftData
- Push notifications
- Widget and Share extensions

## Real Issues to Address

### 🟡 ACTUAL MISSING FEATURES (Priority Order)

1. **MCP Server Management** (0/6 endpoints)
   - List, add, remove MCP servers
   - CLI integration for MCP commands
   - Server status monitoring

2. **Cursor Integration** (0/8 endpoints)
   - Config management
   - Database sessions from Cursor
   - Settings sync

3. **Search Functionality**
   - Full-text project search
   - Code search with filters
   - Search history

4. **Transcription API**
   - Audio to text for voice commands
   - Meeting transcription

5. **Terminal WebSocket**
   - Connect to `ws://localhost:3004/shell`
   - ANSI color support
   - Command history

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
│   ├── Sessions/       # Session list and message history
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

## API Implementation Status

### ✅ Implemented Endpoints (37/62 = 60%)
- **Authentication**: 5/5 endpoints (100% complete)
- **Projects**: 5/5 endpoints (100% complete)
- **Sessions**: 6/6 endpoints (100% complete)
- **Files**: 4/4 endpoints (100% complete)
- **Git**: 16/16 endpoints (100% complete!)
- **Feedback**: 1/1 endpoint (100% complete)

### ❌ Missing Endpoints (25/62 = 40%)

#### Cursor Integration (0/8) - NOT IMPLEMENTED
- Config management
- MCP servers list/add/remove
- Sessions from Cursor DB
- Settings sync

#### MCP Server API (0/6) - NOT IMPLEMENTED
- List servers
- Add server
- Remove server
- Server status
- CLI commands
- Server logs

#### Other Missing APIs
- **Transcription API** - Voice to text
- **Search API** - Full-text project search
- **Terminal/Shell API** - WebSocket connection exists but not used
- **Image Upload API** - For screenshots/attachments
- **Settings Sync API** - Backend settings persistence

For complete API documentation, see the full backend reference at the end of this file.

## 📋 CONSOLIDATED IMPLEMENTATION TASKS

## 🔴 PRIORITY 0: MCP SERVER MANAGEMENT [CRITICAL - 6 Tasks]
**Essential for Claude Code functionality**

### MCP-1: List MCP Servers API ❌
- **Endpoint**: GET /api/mcp/servers
- **File**: `APIClient.swift` line 196-204 (already stubbed)
- **Test**: `curl http://localhost:3004/api/mcp/servers -H "Authorization: Bearer TOKEN"`

### MCP-2: Add MCP Server API ❌
- **Endpoint**: POST /api/mcp/servers
- **File**: `APIClient.swift` line 217-231 (already stubbed)
- **Body**: `{name, url, type, apiKey?, description?}`

### MCP-3: Remove MCP Server API ❌
- **Endpoint**: DELETE /api/mcp/servers/:id
- **File**: `APIClient.swift` line 251-253

### MCP-4: Test MCP Connection ❌
- **Endpoint**: POST /api/mcp/servers/:id/test
- **File**: `APIClient.swift` line 255-278
- **Response**: `{success: bool, message: string, latency?: number}`

### MCP-5: Execute MCP CLI Commands ❌
- **Endpoint**: POST /api/mcp/cli
- **File**: `APIClient.swift` line 280-290
- **Request**: `{command: string, args?: string[]}`

### MCP-6: Add MCP Tab to MainTabBarController ❌
- **File**: `MainTabBarController.swift` line 50-60
- **Action**: Add MCPServerListViewController to tab bar
- **Icon**: server.rack / server.rack.fill

## 🟡 PRIORITY 1: SEARCH FUNCTIONALITY [HIGH - 4 Tasks]

### SEARCH-1: Backend Search Endpoint ❌
- **Endpoint**: POST /api/projects/:projectName/search
- **Request**: `{query: string, scope: string, fileTypes: string[]}`
- **Backend Status**: Not implemented - needs backend work first

### SEARCH-2: Connect SearchViewModel to API ❌
- **File**: `SearchViewModel.swift` line 125-143
- **Current**: Using mock data in `performSearch()`
- **Replace**: Mock with actual API call

### SEARCH-3: Search Filters UI ❌
- **File**: Create `SearchView.swift`
- **Features**: File type filters, date range, regex support

### SEARCH-4: Search Results Caching ❌
- **File**: `SearchViewModel.swift`
- **Cache Key**: `"{projectName}_{query}_{scope}"`
- **Duration**: 5 minutes or until project changes

## 🟠 PRIORITY 1: TERMINAL WEBSOCKET [HIGH - 4 Tasks]

### TERMINAL-1: Connect Shell WebSocket ❌
- **File**: `TerminalViewController.swift` line 176
- **WebSocket URL**: `ws://localhost:3004/shell`
- **Method**: `connectShellWebSocket()` needs implementation

### TERMINAL-2: Shell Command Execution ❌
- **Message Format**: `{"type": "shell-command", "command": "ls -la", "cwd": "/path"}`
- **Response Format**: `{"type": "shell-output", "output": "...", "error": false}`

### TERMINAL-3: ANSI Color Support ❌
- **Library**: NSAttributedString with ANSI parser
- **Colors**: Support 16 basic colors + 256 color mode

### TERMINAL-4: Terminal Resize ❌
- **Message**: `{"type": "resize", "cols": 80, "rows": 24}`
- **Trigger**: On view size change

## 🔵 PRIORITY 2: UI/UX POLISH [MEDIUM - 10 Tasks]

### UI-1: Loading Skeletons ❌
- **Files**: All ViewControllers with table/collection views
- **Create**: `SkeletonView.swift` utility
- **Animation**: Shimmer effect with gradient

### UI-2: Pull to Refresh ❌
- **File**: `SessionListViewController.swift`
- **Implementation**: UIRefreshControl with cyberpunk theme

### UI-3: Empty States ❌
- **Create**: `EmptyStateView.swift`
- **Variants**: No sessions, no search results, no files

### UI-4: Swipe Actions ❌
- **File**: `SessionListViewController.swift`
- **Actions**: Delete (red), Archive (yellow), Duplicate (cyan)

### UI-5: Session Creation Flow ❌
- **File**: `SessionListViewController.swift`
- **Add**: + button in navigation bar
- **Flow**: Create session → Navigate to chat

### UI-6: Error Alert Views ❌
- **Create**: `ErrorAlertView.swift`
- **Features**: Retry action, detailed error info

### UI-7: Loading Indicators ❌
- **Add**: Activity indicators during API calls
- **Style**: Cyberpunk-themed spinners

### UI-8: Attachment Options (from TODO) ❌
- **File**: `ChatViewController.swift`
- **Location**: Line with "TODO: Implement attachment options"
- **Features**: Photo picker, file browser, camera

### UI-9: File Explorer Navigation (from TODO) ❌
- **File**: `ChatViewController.swift`
- **Location**: Line with "TODO: Navigate to file explorer"
- **Action**: Push FileExplorerViewController

### UI-10: Terminal Navigation (from TODO) ❌
- **File**: `ChatViewController.swift`
- **Location**: Line with "TODO: Navigate to terminal"
- **Action**: Push TerminalViewController

## 🟢 PRIORITY 2: TESTING [MEDIUM - 5 Tasks]

### TEST-1: Backend Startup Script ❌
- **Create**: `test_setup.sh`
- **Actions**: Start backend, boot simulator, run tests

### TEST-2: MCP Integration Test ❌
- **Create**: `MCPIntegrationTests.swift`
- **Test Flow**: List → Add → Test → Delete servers

### TEST-3: Search Unit Tests ❌
- **Create**: `SearchViewModelTests.swift`
- **Mock**: Create `MockAPIClient`

### TEST-4: WebSocket Reconnection Test ❌
- **Test**: Auto-reconnection within 3 seconds
- **Verify**: Exponential backoff works

### TEST-5: Session Flow E2E Test ❌
- **Test**: Create → Load → Send Message → Delete
- **Protocol**: 5-phase testing (start, project, session, message, cleanup)

## 🟣 PRIORITY 3: FILE OPERATIONS [LOW - 3 Tasks]

### FILE-1: File/Folder Creation (from TODO) ❌
- **File**: `FileExplorerViewController.swift`
- **Location**: Line with "TODO: Implement actual file/folder creation"
- **Backend**: POST /api/projects/:projectName/files

### FILE-2: Prefetch Implementation (from TODO) ❌
- **File**: `ChatViewController.swift`
- **Location**: Line with "TODO: Implement UITableViewDataSourcePrefetching"
- **Feature**: Preload messages before scrolling

### FILE-3: File Tree Update (from TODO) ❌
- **File**: `FileTreeViewController.swift`
- **Method**: `updateFileTree()` needs implementation
- **Backend**: GET /api/projects/:projectName/files

## ⚫ PRIORITY 4: NICE-TO-HAVE [LOW]

### BACKUP-1: CloudFlare Tunnel Integration ❌
- **Purpose**: Access backend from real device
- **Tool**: CloudFlare Zero Trust tunnel
- **Config**: Map localhost:3004 to public URL

### PERF-1: Memory Optimization ❌
- **Target**: < 150MB baseline
- **Tools**: Instruments memory profiler

### PERF-2: Launch Time Optimization ❌
- **Target**: < 2 seconds
- **Method**: Lazy loading, deferred initialization

### ACCESSIBILITY-1: VoiceOver Support ❌
- **Audit**: All UI elements have accessibility labels
- **Test**: Navigate entire app with VoiceOver

### SECURITY-1: Keychain Integration ❌
- **Store**: JWT tokens in keychain instead of UserDefaults
- **Library**: Use native Security framework

## 📈 Progress Tracking

**API Implementation Reality**:
- **Total Backend Endpoints**: 54 (excluding deprecated Cursor)
- **Implemented**: 37 endpoints (69%)
- **Missing**: 17 endpoints (31%)

**Feature Completion Status**:
- ✅ **Git Integration**: 16/16 endpoints (100%)
- ✅ **Authentication**: 5/5 endpoints (100%)
- ✅ **Projects**: 5/5 endpoints (100%)
- ✅ **Sessions**: 6/6 endpoints (100%)
- ✅ **Files**: 4/4 endpoints (100%)
- ✅ **WebSocket**: Working correctly
- ❌ **MCP Servers**: 0/6 endpoints (0%)
- ❌ **Search**: Not implemented
- ❌ **Terminal WebSocket**: Not connected
- ❌ **Transcription**: Not implemented

**Task Summary**:
- **Priority 0 (Critical)**: 6 MCP tasks
- **Priority 1 (High)**: 8 tasks (4 Search + 4 Terminal)
- **Priority 2 (Medium)**: 15 tasks (10 UI/UX + 5 Testing)
- **Priority 3 (Low)**: 3 File operation tasks
- **Priority 4 (Nice-to-have)**: 5 tasks

**Total Actionable Tasks**: 37 (down from 200+ duplicates)

## 🚀 Implementation Timeline

### Week 1 (Days 1-3) - Critical MCP Features
1. **Day 1**: MCP Server endpoints testing (MCP-1 to MCP-5)
2. **Day 2**: MCP UI integration (MCP-6) + Testing (TEST-1, TEST-2)
3. **Day 3**: Terminal WebSocket connection (TERMINAL-1, TERMINAL-2)

### Week 1 (Days 4-5) - Search & Terminal
4. **Day 4**: Search API implementation (SEARCH-1, SEARCH-2)
5. **Day 5**: Terminal ANSI colors (TERMINAL-3) + Search filters (SEARCH-3)

### Week 2 (Days 6-8) - UI Polish
6. **Day 6**: Loading states & skeletons (UI-1)
7. **Day 7**: Pull to refresh & empty states (UI-2, UI-3)
8. **Day 8**: Swipe actions & navigation (UI-4, UI-5)

### Week 2 (Days 9-10) - Testing & Optimization
9. **Day 9**: Integration tests (TEST-3, TEST-4, TEST-5)
10. **Day 10**: Performance optimization and bug fixes

## Testing Guide

### 📱 CRITICAL SIMULATOR CONFIGURATION
**ALWAYS USE THIS SIMULATOR UUID**: `05223130-57AA-48B0-ABD0-4D59CE455F14`
- **Device**: iPhone 16 Pro Max with iOS 18.6
- **NEVER** use simulator names - ALWAYS use this UUID
- **ALWAYS** boot this simulator first if not already booted

### XcodeBuildMCP Testing Best Practices

#### 1. UI Interaction Rules
- **ALWAYS** use `describe_ui()` first to get precise coordinates
- **Use `touch()`** with down/up events, NOT `tap()`:
  ```javascript
  // Correct way to tap
  touch({ simulatorUuid: "05223130-57AA-48B0-ABD0-4D59CE455F14", x: 100, y: 200, down: true })
  touch({ simulatorUuid: "05223130-57AA-48B0-ABD0-4D59CE455F14", x: 100, y: 200, up: true })
  ```
- **NEVER** guess coordinates from screenshots
- Parse JSON from `describe_ui()` to find exact element positions

#### 2. Log Management Strategy
**Use Background Streaming** to avoid app restart issues:
```bash
# Start BEFORE launching app
xcrun simctl spawn 05223130-57AA-48B0-ABD0-4D59CE455F14 log stream \
  --predicate 'processImagePath contains "ClaudeCodeUI"' \
  > test_logs.txt &

# Store PID to kill later
LOG_PID=$!

# After testing, kill the stream
kill $LOG_PID

# Process logs in chunks to avoid memory issues
tail -n 1000 test_logs.txt  # Last 1000 lines
grep -i error test_logs.txt # Find errors
head -n 500 test_logs.txt    # First 500 lines
```

#### 3. Complete Testing Workflow
```javascript
const SIMULATOR_UUID = "05223130-57AA-48B0-ABD0-4D59CE455F14";  // ALWAYS THIS ONE

// 1. Boot simulator if needed
await boot_sim({ simulatorUuid: SIMULATOR_UUID });
await open_sim();

// 2. Build for specific simulator
await build_simulator({
  projectPath: "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj",
  scheme: "ClaudeCodeUI",
  simulatorId: SIMULATOR_UUID  // ALWAYS use UUID, not name
});

// 3. Get app path
const appPath = await get_simulator_app_path({
  projectPath: "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj",
  scheme: "ClaudeCodeUI",
  simulatorId: SIMULATOR_UUID
});

// 4. Start background log streaming (BEFORE launching app)
// Run via Bash: xcrun simctl spawn 05223130-57AA-48B0-ABD0-4D59CE455F14 log stream ...

// 5. Install and launch
await install_app_sim({ 
  simulatorUuid: SIMULATOR_UUID, 
  appPath: appPath 
});
await launch_app_sim({ 
  simulatorUuid: SIMULATOR_UUID, 
  bundleId: "com.claudecode.ui" 
});

// 6. Test with UI automation
const ui = await describe_ui({ simulatorUuid: SIMULATOR_UUID });
// Parse ui JSON to find elements, then use touch() for interactions
```

### Functional Testing via Simulator (Legacy)
```bash
# STEP 1: Start backend server (required for real data)
cd backend
npm start

# STEP 2: Build iOS app for specific simulator UUID
xcodebuild build \
  -project ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj \
  -scheme ClaudeCodeUI \
  -destination 'platform=iOS Simulator,id=05223130-57AA-48B0-ABD0-4D59CE455F14' \
  -derivedDataPath ./Build

# STEP 3: Boot and setup simulator
xcrun simctl boot 05223130-57AA-48B0-ABD0-4D59CE455F14
xcrun simctl install 05223130-57AA-48B0-ABD0-4D59CE455F14 ./Build/Build/Products/Debug-iphonesimulator/ClaudeCodeUI.app
xcrun simctl launch 05223130-57AA-48B0-ABD0-4D59CE455F14 com.claudecode.ui

# STEP 4: Verify functionality and capture screenshots
# Navigate through app: Projects → Session → Messages
# Monitor Xcode console for API calls and WebSocket messages
xcrun simctl io 05223130-57AA-48B0-ABD0-4D59CE455F14 screenshot project-list.png
xcrun simctl io 05223130-57AA-48B0-ABD0-4D59CE455F14 screenshot session-messages.png
```

### Key Test Scenarios
1. **Authentication Flow**: JWT token generation and storage
2. **Project CRUD**: Create, read, update, delete projects
3. **Session Management**: Load sessions and messages
4. **WebSocket Connection**: Message send/receive, auto-reconnection
5. **File Operations**: Browse, create, rename, delete files
6. **Terminal Commands**: Execute commands, handle ANSI output
7. **Settings Backup/Restore**: Export/import JSON settings
8. **Accessibility**: VoiceOver support, Dynamic Type
9. **Performance**: <2s launch, <150MB memory, no leaks

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
- No authentication UI (backend auth disabled for testing)
- Share extension incomplete
- File size limited to 10MB

### Workarounds
- **WebSocket disconnection**: Auto-reconnects within 3 seconds
- **Large files**: Currently limited, implement chunked upload
- **Offline mode**: Basic caching exists, full offline pending

## Security Considerations

### Current State
- JWT authentication implemented (fixed)
- No encryption at rest
- Basic input validation
- XSS prevention in WebViews

### Production Requirements
- Implement full authentication flow
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
5. **JWT errors**: Verify token expiry time is in seconds, not milliseconds

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
- jsonwebtoken: JWT authentication

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

## Backend API Quick Reference

### Authentication
- POST `/api/auth/register` - Register first user
- POST `/api/auth/login` - Login and get JWT
- GET `/api/auth/status` - Check auth status
- GET `/api/auth/user` - Get current user
- POST `/api/auth/logout` - Logout

### Projects
- GET `/api/projects` - List all projects
- POST `/api/projects/create` - Create new project
- PUT `/api/projects/:projectName/rename` - Rename project
- DELETE `/api/projects/:projectName` - Delete project

### Sessions
- GET `/api/projects/:projectName/sessions` - Get project sessions
- GET `/api/projects/:projectName/sessions/:sessionId/messages` - Get session messages
- DELETE `/api/projects/:projectName/sessions/:sessionId` - Delete session

### Files
- GET `/api/projects/:projectName/files` - Get file tree
- GET `/api/projects/:projectName/file?path=` - Read file content
- PUT `/api/projects/:projectName/file` - Save file content

### Git (Not Implemented in iOS)
- GET `/api/git/status` - Git status
- POST `/api/git/commit` - Commit changes
- GET `/api/git/branches` - List branches
- POST `/api/git/push` - Push to remote
- POST `/api/git/pull` - Pull from remote

### WebSocket
- `ws://localhost:3004/ws` - Chat WebSocket
- `ws://localhost:3004/shell` - Terminal WebSocket

Message format for chat:
```json
{
  "type": "claude-command",
  "content": "User message",
  "projectPath": "/full/path/to/project",
  "sessionId": "optional-session-id"
}
```

For complete API documentation with all 60+ endpoints, request/response formats, and examples, refer to the API_DOCUMENTATION.md file.

## Roadmap to Completion

### Immediate Priorities (Next 2-3 days)
1. Fix WebSocket URL and message types (P0)
2. Implement missing session management features (P0)
3. Connect file explorer to backend API (P1)
4. Add terminal WebSocket connection (P1)

### Week 1 Targets
1. Complete all P0 critical fixes
2. Implement core Git integration
3. Add search functionality
4. Basic offline support

### Week 2 Targets
1. Complete remaining API endpoints
2. Add comprehensive testing
3. Implement security features
4. Performance optimization

### Production Release (Week 3-4)
1. Full authentication flow
2. Push notifications
3. App Store preparation
4. Beta testing with TestFlight

## Summary - REALITY CHECK

The iOS Claude Code UI app is in much better shape than previously documented:
- **60% of backend API is implemented** (not 32% as claimed)
- **WebSocket is working correctly** (not broken as documented)
- **Git integration is 100% complete** (not "completely missing")
- **Session management is fully functional**
- **Authentication is working**

The main missing features are:
1. **MCP Server Management** (0/6 endpoints) - Essential for Claude Code
2. **Search API** - Useful for large projects
3. **Terminal WebSocket** - Shell command execution
4. **UI/UX Polish** - Animations, loading states, etc.

The app follows best practices with MVVM architecture, has a solid foundation, and most "critical P0 issues" were either already fixed or never existed. The codebase is ready for adding the remaining MCP and Search features.

---

*This document is the single source of truth for the iOS Claude Code UI project. All other documentation should defer to this file.*