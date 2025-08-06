# macOS Claude Code - iOS Project Handoff Guide

## 📚 Complete Code Review Instructions

This document provides comprehensive instructions for macOS Claude Code to understand and test the iOS Claude Code UI project.

## 🎯 Project Overview

**Project**: Native iOS Client for Claude Code
**Architecture**: MVVM with Coordinators
**Language**: Swift 5.9
**Minimum iOS**: 17.0
**UI Framework**: UIKit + SwiftUI (hybrid)
**Persistence**: SwiftData
**Design System**: Cyberpunk Theme (Cyan #00D9FF, Pink #FF006E)
**Backend**: Express.js on port 3004

## 📖 Sequential Code Reading Instructions

Execute these Read commands in order to understand the complete codebase:

### Core Configuration (Read First)
```
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Core/Config/AppConfig.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Core/Config/Environment.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Core/Config/Logger.swift
```

### Navigation Architecture
```
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Core/Navigation/AppCoordinator.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Core/Navigation/NavigationController.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Core/Navigation/TabBarController.swift
```

### Design System
```
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Design/Theme/CyberpunkTheme.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Design/Theme/ColorPalette.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Design/Theme/Typography.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Design/Effects/GlowEffects.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Design/Effects/AnimationEffects.swift
```

### Network Layer
```
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Core/Network/APIClient.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Core/Network/WebSocketManager.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Core/Network/NetworkMonitor.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Core/Network/APIEndpoints.swift
```

### Data Models
```
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Models/Project.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Models/ChatMessage.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Models/FileNode.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Models/TerminalCommand.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Models/Settings.swift
```

### Feature: Projects
```
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Features/Projects/ProjectsViewController.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Features/Projects/ProjectsViewModel.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Features/Projects/ProjectCell.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Features/Projects/CreateProjectViewController.swift
```

### Feature: Chat
```
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Features/Chat/ChatViewController.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Features/Chat/ChatViewModel.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Features/Chat/MessageCell.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Features/Chat/ChatInputView.swift
```

### Feature: File Explorer
```
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Features/FileExplorer/FileExplorerViewController.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Features/FileExplorer/FileExplorerViewModel.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Features/FileExplorer/FileCell.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Features/FileExplorer/CodeEditorViewController.swift
```

### Feature: Terminal
```
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Features/Terminal/TerminalViewController.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Features/Terminal/TerminalViewModel.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Features/Terminal/TerminalView.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Features/Terminal/ANSIParser.swift
```

### Feature: Settings
```
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Features/Settings/SettingsViewController.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Features/Settings/SettingsViewModel.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Features/Settings/ThemeSettingsViewController.swift
```

### Advanced Features
```
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Features/Onboarding/OnboardingViewController.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Features/AppTour/AppTourManager.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Features/Feedback/FeedbackViewController.swift
```

### Core Services
```
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Core/Services/SettingsExportManager.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Core/Services/DataManager.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Core/Services/CacheManager.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Core/Services/WebSocketReconnection.swift
```

### Accessibility
```
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Core/Accessibility/AccessibilityManager.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Core/Accessibility/VoiceOverSupport.swift
```

### Main Entry Point
```
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/AppDelegate.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/SceneDelegate.swift
Read /home/nick/claudecode-ios/ClaudeCodeUI-iOS/Info.plist
```

## 🏗️ Architecture Understanding

### MVVM + Coordinator Pattern
- **Views**: UIViewController subclasses handle UI
- **ViewModels**: Business logic and data transformation
- **Models**: SwiftData entities and data structures
- **Coordinators**: Navigation flow management
- **Services**: Reusable business logic

### Key Design Patterns
1. **Singleton**: AppConfig, Logger, AppTourManager
2. **Observer**: Combine publishers for reactive updates
3. **Delegate**: UITableViewDelegate, UITextFieldDelegate
4. **Factory**: ViewControllerFactory for dependency injection
5. **Repository**: DataManager for data access

### Dependency Flow
```
AppDelegate → SceneDelegate → AppCoordinator → TabBarController → Feature VCs
                                    ↓
                              NavigationController → Child VCs
```

## 🔌 Backend Integration

### API Endpoints
- `GET /api/health` - Health check
- `GET /api/projects` - List projects
- `POST /api/projects` - Create project
- `PUT /api/projects/:id` - Update project
- `DELETE /api/projects/:id` - Delete project
- `POST /api/chat/message` - Send chat message
- `WS /api/chat/ws` - WebSocket for real-time chat
- `GET /api/files/:projectId` - Get file tree
- `POST /api/terminal/execute` - Execute command
- `POST /api/feedback` - Submit feedback
- `GET /api/settings` - Get settings
- `POST /api/settings` - Update settings

### WebSocket Protocol
```javascript
// Connection
ws://localhost:3004/api/chat/ws

// Message Format
{
  "type": "message|typing|status",
  "content": "...",
  "userId": "...",
  "timestamp": "..."
}
```

## 🧪 Testing Workflow

### Phase 1: Setup (Tasks 1-20)
1. Install all prerequisites
2. Clone repository
3. Setup backend server
4. Configure environment
5. Open Xcode project

### Phase 2: Basic Testing (Tasks 21-50)
1. Build and run app
2. Test onboarding flow
3. Create first project
4. Basic navigation test
5. Theme verification

### Phase 3: Feature Testing (Tasks 51-150)
1. Projects CRUD operations
2. Chat messaging with WebSocket
3. File Explorer navigation
4. Terminal command execution
5. Settings management
6. Feedback submission
7. App tour completion
8. Accessibility testing

### Phase 4: Advanced Testing (Tasks 151-190)
1. Performance profiling
2. Memory leak detection
3. Network failure scenarios
4. Stress testing
5. iPad compatibility
6. Dark mode verification

## 🐛 Known Issues & Limitations

### Current Limitations
1. Widget extension not yet implemented
2. Siri shortcuts pending
3. Push notifications not configured
4. Share extension incomplete
5. No authentication (direct connection only)

### Workarounds
- **WebSocket disconnection**: App auto-reconnects within 3 seconds
- **Large file handling**: Currently limited to 10MB
- **Offline mode**: Basic caching implemented, full offline pending

## 🚀 Performance Optimization Opportunities

### Suggested Improvements
1. Implement lazy loading for project list
2. Add image caching for avatars
3. Optimize file tree rendering for large directories
4. Implement virtual scrolling for chat history
5. Add prefetching for file content
6. Optimize WebSocket message batching
7. Implement diff-based updates

### Memory Management
- Use weak references in closures
- Implement proper cleanup in deinit
- Monitor retain cycles with Instruments
- Use autoreleasepool for batch operations

## 🔒 Security Considerations

### Current Implementation
- No authentication (localhost only)
- No data encryption at rest
- Basic input validation
- XSS prevention in WebViews

### Recommended Enhancements
1. Add JWT authentication
2. Implement keychain storage
3. Add certificate pinning
4. Encrypt sensitive data
5. Add jailbreak detection
6. Implement rate limiting

## 📝 Testing Checklist

Before marking testing complete:
- [ ] All 190 test tasks passed
- [ ] No memory leaks detected
- [ ] Performance benchmarks met
- [ ] Accessibility audit passed
- [ ] All UI elements have labels
- [ ] Network errors handled gracefully
- [ ] Data persists across launches
- [ ] WebSocket reconnects properly
- [ ] Settings backup/restore works
- [ ] No crashes in 1-hour test

## 🎯 Next Steps

1. Complete remaining Phase 7 features (widgets, Siri, notifications)
2. Implement authentication system
3. Add comprehensive unit tests
4. Setup CI/CD pipeline
5. Prepare for App Store submission
6. Create user documentation
7. Implement analytics
8. Add crash reporting

## 📞 Support & Resources

- **Documentation**: See README.md
- **Testing Guide**: See TESTING.md
- **API Reference**: See API.md
- **Backend Setup**: See backend/README.md
- **Design System**: See Design/README.md

## 🏁 Conclusion

This iOS Claude Code UI project implements a complete native iOS client with:
- Modern Swift architecture (MVVM + Coordinators)
- Cyberpunk-themed UI with custom effects
- Real-time WebSocket communication
- Comprehensive file and terminal features
- Full accessibility support
- Settings backup/restore
- Advanced onboarding and tour system

The codebase is ready for testing on macOS with the iOS Simulator. Follow the numbered tasks in TESTING.md for comprehensive validation.

---

**Project Version**: 1.0.0-alpha
**Swift Version**: 5.9
**Target iOS**: 17.0+
**Last Updated**: January 2025