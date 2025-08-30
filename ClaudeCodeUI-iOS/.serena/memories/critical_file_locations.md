# Critical File Locations - Claude Code iOS UI

## Chat Feature Files
```
Features/Chat/
├── ChatViewController.swift (Main controller, needs refactoring)
├── ViewModels/ChatViewModel.swift (MVVM view model)
├── Handlers/
│   ├── ChatInputHandler.swift (Input management)
│   ├── ChatTableViewHandler.swift (Table view management)
│   └── StreamingMessageHandler.swift (WebSocket streaming)
├── Managers/
│   └── ChatStateManager.swift (State management)
├── Views/
│   ├── ChatMessageCell.swift (Message display)
│   ├── ChatDateHeaderView.swift (Date headers)
│   └── ChatInputBarAdapter.swift (Input bar)
└── Coordinators/
    └── ChatComponentsIntegrator.swift (Component orchestration)
```

## Core Infrastructure
```
Core/
├── Data/
│   └── SwiftDataContainer.swift (Data persistence)
├── Network/
│   ├── StarscreamWebSocketManager.swift (WebSocket implementation)
│   ├── WebSocketManager.swift (Protocol definition)
│   └── WebSocketReconnection.swift (Reconnection logic)
├── Services/
│   ├── AuthenticationManager.swift (Auth handling)
│   ├── MessagePersistenceService.swift (Message storage)
│   └── OfflineManager.swift (Offline support)
└── Navigation/
    ├── AppCoordinator.swift (App navigation)
    └── MainTabBarController.swift (Tab bar)
```

## Configuration Files
```
Root/
├── Project.swift (Tuist project config)
├── Workspace.swift (Tuist workspace)
├── Package.swift (SPM dependencies)
└── Tuist.swift (Tuist settings)
```

## Test Files
```
Tests/
├── ui-test-scenarios.json (Test scenarios documentation)
├── ClaudeCodeUITests/ (Unit tests)
├── MCPServerTests.swift
├── NavigationTests.swift
├── SettingsTests.swift
├── TerminalWebSocketTests.swift
└── WebSocketStreamingTest.swift
```

## Disabled/Backup Files (from git status)
- ChatViewController_New.swift.disabled
- ChatViewController_Refactored.swift.disabled
- ChatComponentsIntegrator.swift.disabled
- ChatViewController+Setup.swift.disabled
- TerminalWebSocketTests.swift.disabled