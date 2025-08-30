# ClaudeCodeUI-iOS Project Overview

## Purpose
iOS application for Claude Code, featuring a cyberpunk-themed UI with chat interface, terminal, MCP integration, and project management capabilities. Built with UIKit/SwiftUI hybrid architecture.

## Tech Stack
- **Platform**: iOS 17.0+
- **Languages**: Swift 5.9+
- **Architecture**: UIKit (primary) + SwiftUI (components)
- **Dependencies**: Starscream 4.0.6 (WebSocket)
- **Build System**: Xcode 16.0 / Tuist / Swift Package Manager
- **Data**: SwiftData for persistence

## Project Structure
```
ClaudeCodeUI-iOS/
├── App/             # App entry point, AppDelegate, SceneDelegate
├── Core/            # Core services (Navigation, Network, Data, Auth)
├── Features/        # Feature modules (Chat, Terminal, Projects, Settings)
├── UI/              # Reusable UI components
├── UIComponents/    # Additional UI components
├── Design/          # Design system, themes, colors
├── Models/          # Data models
├── Resources/       # Assets, strings, fonts
└── Tests/           # Unit, UI, and integration tests
```

## Key Components
- **MainTabBarController**: 5-tab navigation (Projects, Terminal, MCP, Search, Settings)
- **ChatViewController**: Main chat interface with streaming support
- **CyberpunkLoadingIndicator**: Custom animated loading component
- **ChatMessageCell**: Message display with markdown support
- **StarscreamWebSocketManager**: WebSocket communication layer

## Design System
- **Theme**: Cyberpunk aesthetic with neon colors
- **Primary Colors**: Cyan (#00FFFF), Pink (#FF00FF), Dark backgrounds
- **Typography**: System fonts with custom weights
- **Animations**: Glitch effects, neon glows, smooth transitions