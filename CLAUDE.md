# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Native iOS client for Claude Code with a cyberpunk-themed UI that communicates with a Node.js backend server.

**Key Technologies:**
- **iOS App**: Swift 5.9, UIKit + SwiftUI, iOS 17.0+, MVVM + Coordinators, SwiftData
- **Backend**: Node.js + Express on port 3004, WebSocket for real-time chat, SQLite database
- **Design**: Cyberpunk theme (Cyan #00D9FF, Pink #FF006E)
- **Development**: Docker support for containerized iOS development

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
```javascript
// Health & Status
GET  /api/health           // Server health check

// Projects
GET  /api/projects         // List all projects
POST /api/projects         // Create new project
PUT  /api/projects/:id     // Update project
DELETE /api/projects/:id   // Delete project

// Chat
POST /api/chat/message     // Send message
WS   /api/chat/ws         // WebSocket connection

// Files
GET  /api/files/:projectId // Get file tree
POST /api/files/create     // Create file
PUT  /api/files/rename     // Rename file
DELETE /api/files/delete   // Delete file

// Terminal
POST /api/terminal/execute // Execute command

// Settings
GET  /api/settings         // Get settings
POST /api/settings         // Update settings
POST /api/settings/export  // Export settings
POST /api/settings/import  // Import settings
```

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

## iOS Messaging Implementation Tasks

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