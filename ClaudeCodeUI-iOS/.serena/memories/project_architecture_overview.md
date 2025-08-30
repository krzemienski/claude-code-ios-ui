# Claude Code iOS UI - Project Architecture Overview

## Project Structure
- **Root**: `/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/`
- **Build System**: Tuist (Project.swift, Workspace.swift) + SPM (Package.swift)
- **iOS Target**: iOS 17.0 minimum
- **Dependencies**: Starscream WebSocket library (v4.0.6)

## Core Architecture Components

### 1. Data Layer (SwiftData)
- **Location**: `Core/Data/SwiftDataContainer.swift`
- **Models**: Project, Session, Message, Settings
- **Key Features**:
  - Singleton pattern with @MainActor
  - In-memory fallback support
  - CRUD operations for all entities
  - Async/await support
  - Session-based message storage

### 2. Network Layer
- **WebSocket Management**: 
  - `Core/Network/StarscreamWebSocketManager.swift` (primary)
  - `Core/Network/WebSocketManager.swift` (protocol)
  - WebSocketProtocol abstraction
- **API Client**: `Core/Network/APIClient.swift`
- **Reconnection**: `Core/Network/WebSocketReconnection.swift`

### 3. Chat Feature Architecture
- **Main Controller**: `Features/Chat/ChatViewController.swift`
- **Refactored Components** (9 modules):
  - ChatComponentsIntegrator (orchestrator)
  - ChatInputHandler
  - ChatTableViewHandler  
  - StreamingMessageHandler
  - ChatStateManager
  - ChatViewModel
  - ChatMessageCell
  - ChatDateHeaderView
  - ChatInputBarAdapter

### 4. Navigation
- **Coordinator**: `Core/Navigation/AppCoordinator.swift`
- **Tab Bar**: `Core/Navigation/MainTabBarController.swift`
- **5 Main Tabs**: Projects, Chat, Terminal, Settings, MCP

## Build Configuration
- **Targets**: 
  - ClaudeCodeUI (main app)
  - ClaudeCodeUITests (unit tests)
  - ClaudeCodeUIUITests (UI tests)
  - ClaudeCodeUIIntegrationTests
- **Source Directories**: App, Core, Features, Design, Models, UIComponents, UI
- **Resources**: Storyboards, XIBs, Assets, Localization files

## Testing Infrastructure
- **Test Scenarios**: Documented in `Tests/ui-test-scenarios.json`
- **Test Categories**: Navigation, Chat, SwiftUI, Accessibility, Performance, Edge Cases
- **Coverage Requirements**: 90% unit, 70% integration
- **XCUITest framework with GitHub Actions CI**