# CLAUDE.md - Comprehensive iOS Claude Code UI Implementation Guide

This is the single source of truth for the iOS Claude Code UI project. 
Last Updated: January 16, 2025 | Backend: Node.js Express | iOS: Swift 5.9 UIKit/SwiftUI

## 🟢 BACKEND API IMPLEMENTATION STATUS - UPDATED

### Backend Server Status: ✅ RUNNING
- Server: http://localhost:3004
- WebSocket: ws://localhost:3004/ws (✅ WORKING CORRECTLY)
- Shell WebSocket: ws://localhost:3004/shell  
- Database: SQLite with auth.db and store.db

### API Implementation Reality Check
- **Total Backend Endpoints**: 62
- **Actually Implemented in iOS**: 37 endpoints (60%)
- **Missing in iOS**: 25 endpoints (40%)
- **Critical Issues**: Most "P0 issues" are already fixed!

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

### ✅ COMPLETED FEATURES (37 of 62 endpoints = 60%)
- Basic project structure and navigation (AppCoordinator, MainTabBarController)
- Data models (Project, Session, Message with fullPath support)
- APIClient with 37 endpoints implemented
- WebSocketManager with correct implementation
- SessionListViewController with full CRUD operations
- ChatViewController with working WebSocket
- Cyberpunk theme and visual effects
- Authentication with JWT (working)
- Projects list loading from backend
- Session messages loading (working)
- **Git integration fully implemented (16/16 endpoints)**
- File operations (read, write, delete)

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

## 📋 UPDATED IMPLEMENTATION TASKS

## SECTION 1: WEBSOCKET ENHANCEMENTS [COMPLETED ✅]

### Task 1.1: Fix WebSocket URL Path ✅ COMPLETED
**Status**: Already using correct URL from AppConfig.websocketURL

### Task 1.2: Fix WebSocket Message Type ✅ COMPLETED
**Status**: Already using "claude-command" throughout the codebase

### Task 1.3: Add Project Path to WebSocket Messages ✅ COMPLETED
**Status**: Project path is included in messages

## SECTION 2: PRIORITY MISSING FEATURES [NEW TASKS]

### Task 2.1: Implement MCP Server Management ❌
**Endpoints**: 6 endpoints to implement
**Files**: Create MCPViewController.swift
**Priority**: HIGH - Core Claude Code functionality

### Task 2.2: Add Cursor Integration ❌
**Endpoints**: 8 endpoints to implement
**Files**: Create CursorViewController.swift
**Priority**: HIGH - Essential for Cursor users

### Task 2.3: Implement Search API ❌
**Endpoint**: POST /api/projects/:projectName/search
**Files**: Create SearchViewController.swift
**Priority**: MEDIUM - Important for large projects

### Task 2.4: Add Terminal WebSocket ❌
**WebSocket**: ws://localhost:3004/shell
**Files**: Update TerminalViewController.swift
**Priority**: MEDIUM - Useful for command execution

### Task 2.5: Implement Transcription API ❌
**Endpoint**: POST /api/transcribe
**Files**: Create TranscriptionService.swift
**Priority**: LOW - Nice to have for voice input

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

## 📈 Progress Tracking - UPDATED

**API Implementation Reality**:
- **Total Backend Endpoints**: 62
- **Implemented**: 37 endpoints (60%)
- **Missing**: 25 endpoints (40%)

**Feature Completion Status**:
- ✅ **Git Integration**: 16/16 endpoints (100%)
- ✅ **Authentication**: 5/5 endpoints (100%)
- ✅ **Projects**: 5/5 endpoints (100%)
- ✅ **Sessions**: 6/6 endpoints (100%)
- ✅ **Files**: 4/4 endpoints (100%)
- ✅ **WebSocket**: Working correctly
- ❌ **MCP Servers**: 0/6 endpoints (0%)
- ❌ **Cursor Integration**: 0/8 endpoints (0%)
- ❌ **Search**: Not implemented
- ❌ **Transcription**: Not implemented

**Real Priority**:
1. MCP Server Management (essential for Claude Code)
2. Cursor Integration (for Cursor users)
3. Search functionality
4. Terminal WebSocket
5. UI/UX polish

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

## Summary - REALITY CHECK

The iOS Claude Code UI app is in much better shape than previously documented:
- **60% of backend API is implemented** (not 32% as claimed)
- **WebSocket is working correctly** (not broken as documented)
- **Git integration is 100% complete** (not "completely missing")
- **Session management is fully functional**
- **Authentication is working**

The main missing features are:
1. **MCP Server Management** (0/6 endpoints) - Essential for Claude Code
2. **Cursor Integration** (0/8 endpoints) - Important for Cursor users
3. **Search API** - Useful for large projects
4. **Terminal WebSocket** - Shell command execution
5. **UI/UX Polish** - Animations, loading states, etc.

The app follows best practices with MVVM architecture, has a solid foundation, and most "critical P0 issues" were either already fixed or never existed. The codebase is ready for adding the remaining MCP and Cursor features.

---

*This document is the single source of truth for the iOS Claude Code UI project. All other documentation should defer to this file.*