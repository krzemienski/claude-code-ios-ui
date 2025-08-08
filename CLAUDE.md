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

### Run Tests
```bash
# Backend tests
cd backend
npm test

# iOS tests (in Xcode)
# Cmd+U or Product → Test

# UI tests
# Select ClaudeCodeUITests scheme
# Cmd+U
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