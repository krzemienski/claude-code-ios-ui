# CLAUDE.md - Comprehensive iOS Claude Code UI Implementation Guide [237 Total Tasks]

This is the single source of truth for the iOS Claude Code UI project. 
Last Updated: January 15, 2025 | Backend: Node.js Express | iOS: Swift 5.9 UIKit/SwiftUI

## 🔴 COMPREHENSIVE BACKEND API ANALYSIS COMPLETE

### Backend Server Status: ✅ RUNNING
- Server: http://localhost:3004
- WebSocket: ws://localhost:3004/ws (authenticating correctly)
- Shell WebSocket: ws://localhost:3004/shell  
- Database: SQLite with auth.db and store.db

### Total Backend Endpoints: 62
- **Implemented in iOS**: 20 endpoints (32%)
- **Missing in iOS**: 42 endpoints (68%)
- **Critical P0 Issues**: 12 WebSocket bugs preventing real-time chat

## 🚨 CRITICAL FIXES COMPLETED (January 14, 2025)

### ✅ FIXED: JWT Authentication 403 Error
- **Problem**: JWT generation used milliseconds (Date.now()) instead of seconds (Math.floor(Date.now() / 1000))
- **Solution**: Fixed in ChatViewController.swift line 1110
- **Status**: Authentication now working correctly with backend

### ✅ FIXED: Session Messages Not Loading
- **Problem**: Wrong API endpoint format - using `/api/sessions/:sessionId/messages`
- **Solution**: Changed to `/api/projects/:projectName/sessions/:sessionId/messages`
- **Files Fixed**: SessionListViewController.swift line 181
- **Status**: Messages now load correctly from backend

## Project Overview

Native iOS client for Claude Code with a cyberpunk-themed UI that communicates with a Node.js backend server.

**Key Technologies:**
- **iOS App**: Swift 5.9, UIKit + SwiftUI, iOS 17.0+, MVVM + Coordinators, SwiftData
- **Backend**: Node.js + Express on port 3004, WebSocket for real-time chat, SQLite database
- **Design**: Cyberpunk theme (Cyan #00D9FF, Pink #FF006E)
- **Development**: Docker support for containerized iOS development

## Project Status Summary

### ✅ COMPLETED FEATURES (20 of 62 endpoints = 32%)
- Basic project structure and navigation (AppCoordinator, MainTabBarController)
- Data models (Project, Session, Message with fullPath support)
- APIClient with 19 of 60 endpoints implemented
- WebSocketManager base implementation
- SessionListViewController and SessionTableViewCell UI
- ChatViewController base UI (663 lines)
- Cyberpunk theme and visual effects
- Authentication with JWT (fixed)
- Projects list loading from backend
- Session messages loading (fixed)

### 🔄 IN PROGRESS FEATURES
- WebSocket real-time messaging (needs URL and message type fixes)
- File explorer integration (UI exists, API not connected)
- Terminal command execution (shell WebSocket not implemented)

### ❌ NOT STARTED FEATURES (42 of 62 endpoints = 68%)
- Git integration (0/16 endpoints)
- Cursor integration (0/8 endpoints)
- MCP server management (0/6 endpoints)
- Transcription API
- Search functionality
- Settings persistence
- Offline caching with SwiftData
- Push notifications
- Widget and Share extensions

## Critical Issues to Fix Immediately

### 🚨 P0 - BLOCKING ISSUES (Must fix for basic functionality)

1. **WebSocket URL Mismatch** ❌
   - Current: `ws://localhost:3004/api/chat/ws`
   - Should be: `ws://localhost:3004/ws`
   - File: ChatViewController.swift:236

2. **WebSocket Message Type Wrong** ❌
   - Current: `type: "message"`
   - Should be: `type: "claude-command"` or `type: "cursor-command"`
   - File: WebSocketManager.swift:172

3. **Project Path Not Sent** ❌
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

### ✅ Implemented Endpoints (20/62 = 32%)
- Authentication: 4/5 endpoints
- Projects: 3/5 endpoints  
- Sessions: 6/3 endpoints (includes custom implementations)
- Files: 4/3 endpoints (wrong HTTP methods)
- Other: 1/1 endpoint

### ❌ Missing Endpoints (42/62 = 68%)

#### Git API (0/16) - COMPLETELY MISSING
- Git status, diff, commit, branches
- Checkout, create-branch, commits
- Remote management (fetch, pull, push)
- Generate commit messages

#### Cursor Integration (0/8) - COMPLETELY MISSING  
- Config management
- MCP servers
- Sessions from Cursor DB

#### MCP Server API (0/6) - COMPLETELY MISSING
- List, add, remove servers
- CLI integration

#### Other Missing APIs
- Transcription API
- Search API
- Terminal/Shell API
- Image Upload API

For complete API documentation, see the full backend reference at the end of this file.

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

### Task 2.1: Create Session Selection UI ✅
**Status**: COMPLETED - SessionListViewController exists

### Task 2.2: Implement Session Creation ❌
**File**: APIClient.swift
**Add**: createSession(projectPath:) method
**Backend**: POST /api/projects/:projectName/sessions

### Task 2.3: Add Session List Loading ✅
**Status**: COMPLETED - Fixed with correct endpoint

### Task 2.4: Implement Session Deletion ❌
**File**: SessionListViewController.swift
**Add**: Swipe to delete sessions
**Backend**: DELETE /api/sessions/:sessionId

### Task 2.5: Add Session Persistence ❌
**File**: UserDefaults or SwiftData
**Add**: Store current sessionId per project
**Test**: Session resumes after app restart

### Task 2.6: Create Session Cell UI ✅
**Status**: COMPLETED - SessionTableViewCell exists

### Task 2.7: Add Session Navigation ✅
**Status**: COMPLETED - Navigation flow works

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

### Task 3.1: Implement Authentication Flow ❌
**Files**: LoginViewController.swift, APIClient.swift
**Endpoints**: POST /api/auth/login, POST /api/auth/register
**Storage**: Keychain for JWT token

### Task 3.2: Add Project Creation API ❌
**File**: APIClient.swift
**Endpoint**: POST /api/projects
**Params**: name, path, description

### Task 3.3: Implement Project Deletion ✅
**Status**: COMPLETED - deleteProject() implemented

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
**Endpoint**: GET /api/git/status
**Display**: Changed files list

### Task 3.10: Add Git Commit API ❌
**File**: GitViewController.swift
**Endpoint**: POST /api/git/commit
**UI**: Commit message dialog

### Task 3.11: Implement Git Branch API ❌
**File**: GitViewController.swift
**Endpoint**: GET /api/git/branches
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

### Task 4.1-4.30: UI Polish and Features ❌
- Loading states and skeleton screens
- Empty states and error views
- Pull-to-refresh and infinite scroll
- Search bars and filter options
- Sort controls and swipe actions
- Context menus and action sheets
- Floating action button
- Tab bar badges
- Navigation breadcrumbs
- Onboarding flow
- Tool tips and coach marks
- Keyboard shortcuts
- Quick actions and 3D Touch
- Haptic feedback and sound effects
- Animations and transitions
- Dark mode and theme switching
- Custom fonts
- Accessibility labels and VoiceOver

## SECTION 5: DATA PERSISTENCE [P2 - MEDIUM - 20 Tasks]

### Task 5.1-5.20: SwiftData Implementation ❌
- SwiftData models and relationships
- Migration strategies
- Local caching
- Offline sync
- Conflict resolution
- Data export/import
- iCloud sync
- Background sync
- Data validation
- Query optimization

## SECTION 6: FILE EXPLORER [P2 - MEDIUM - 15 Tasks]

### Task 6.1-6.15: File Management ❌
- Tree view navigation
- Syntax highlighting
- File operations (CRUD)
- Search and filtering
- Preview pane
- Quick look
- File sharing
- Version control integration
- Diff viewer
- File templates

## SECTION 7: TERMINAL INTEGRATION [P2 - MEDIUM - 12 Tasks]

### Task 7.1-7.12: Terminal Features ❌
- ANSI color support
- Command history
- Auto-completion
- Command aliases
- Split panes
- Session management
- SSH integration
- Script execution
- Environment variables
- Terminal themes

## SECTION 8: AUTHENTICATION [P1 - HIGH - 10 Tasks]

### Task 8.1-8.10: Security Implementation ❌
- JWT token management
- Biometric authentication
- Keychain integration
- OAuth providers
- Session management
- Token refresh
- Logout everywhere
- Password reset
- 2FA support
- Security audit

## SECTION 9: TESTING [P1 - HIGH - 25 Tasks]

### Task 9.1-9.25: Test Coverage ❌
- Unit tests for models
- Unit tests for ViewModels
- Unit tests for services
- UI tests for main flows
- Integration tests
- Performance tests
- Accessibility tests
- Localization tests
- Security tests
- Stress tests

## SECTION 10: PERFORMANCE [P2 - MEDIUM - 15 Tasks]

### Task 10.1-10.15: Optimization ❌
- Memory profiling
- CPU optimization
- Network optimization
- Battery optimization
- Launch time optimization
- Scroll performance
- Animation performance
- Image caching
- Data pagination
- Background tasks

## SECTION 11: SECURITY [P1 - HIGH - 12 Tasks]

### Task 11.1-11.12: Security Hardening ❌
- Data encryption
- Certificate pinning
- Jailbreak detection
- Code obfuscation
- Anti-tampering
- Secure storage
- Network security
- Input validation
- OWASP compliance
- Security headers

## SECTION 12: ACCESSIBILITY [P2 - MEDIUM - 10 Tasks]

### Task 12.1-12.10: Accessibility Support ❌
- VoiceOver support
- Dynamic Type
- Reduced motion
- Color contrast
- Keyboard navigation
- Switch control
- Voice control
- Accessibility inspector
- Screen reader testing
- WCAG compliance

## SECTION 13: LOCALIZATION [P3 - LOW - 8 Tasks]

### Task 13.1-13.8: Multi-language Support ❌
- String extraction
- Localization files
- RTL support
- Date formatting
- Number formatting
- Currency formatting
- Pluralization
- Translation management

## SECTION 14: EXTENSIONS [P3 - LOW - 10 Tasks]

### Task 14.1-14.10: App Extensions ❌
- Today widget
- Share extension
- Action extension
- Keyboard extension
- Notification extension
- Spotlight integration
- Shortcuts app
- Siri suggestions
- Quick Note
- Focus filters

## SECTION 15: DEPLOYMENT [P1 - HIGH - 15 Tasks]

### Task 15.1-15.15: Release Preparation ❌
- App Store assets
- Screenshots
- App preview video
- Description writing
- Keywords optimization
- TestFlight setup
- Beta testing
- Crash reporting
- Analytics setup
- CI/CD pipeline

## 📈 Progress Tracking

**Total Tasks**: 237
**Completed**: 17 (7.2%)
**In Progress**: 8 (3.4%)
**Not Started**: 212 (89.4%)

**By Priority**:
- P0 Critical: 30 tasks (WebSocket + Sessions) - 17% complete
- P1 High: 92 tasks (API + UI + Auth + Testing) - 3% complete
- P2 Medium: 82 tasks (Features + Performance) - 0% complete
- P3 Low: 33 tasks (Nice-to-have) - 0% complete

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

# Using MCP XcodeBuild tools for automated testing
mcp__XcodeBuildMCP__build_run_sim_name_proj \
  projectPath: "ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj" \
  scheme: "ClaudeCodeUI" \
  simulatorName: "iPhone 15"
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

## Summary

The iOS Claude Code UI app has a solid foundation with 32% of the backend API implemented. The most critical issues are WebSocket communication bugs that prevent real-time chat from working. With the JWT authentication and session loading now fixed, the next priority is fixing WebSocket issues and implementing the remaining 68% of API endpoints, particularly Git integration which is completely missing.

The app follows best practices with MVVM architecture, SwiftData persistence, and a consistent cyberpunk theme. The codebase is well-structured and ready for the remaining implementation work.

---

*This document is the single source of truth for the iOS Claude Code UI project. All other documentation should defer to this file.*