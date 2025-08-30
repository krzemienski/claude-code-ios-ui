# UI Component Architecture Diagram

## System Architecture Overview

```mermaid
graph TB
    subgraph "App Root"
        AppDelegate[AppDelegate]
        SceneDelegate[SceneDelegate]
        AppDelegate --> SceneDelegate
    end
    
    subgraph "Navigation Layer"
        TabBarController[UITabBarController]
        NavCoordinator[NavigationCoordinator]
        SceneDelegate --> TabBarController
        TabBarController --> NavCoordinator
    end
    
    subgraph "View Controllers"
        ProjectsVC[ProjectsViewController<br/>UIKit]
        SessionsView[SessionListView<br/>SwiftUI]
        ChatVC[ChatViewController<br/>UIKit/SwiftUI Hybrid]
        SettingsView[SettingsView<br/>SwiftUI]
        MCPVC[MCPServerListView<br/>SwiftUI]
        
        TabBarController --> ProjectsVC
        TabBarController --> SessionsView
        TabBarController --> ChatVC
        TabBarController --> SettingsView
        TabBarController --> MCPVC
    end
    
    subgraph "Chat Module Architecture"
        ChatVC --> ChatVM[ChatViewModel<br/>@MainActor]
        ChatVC --> TableHandler[ChatTableViewHandler]
        ChatVC --> InputHandler[ChatInputHandler]
        ChatVC --> StreamHandler[StreamingMessageHandler]
        
        TableHandler --> MessageCell[ChatMessageCell]
        InputHandler --> InputBar[ChatInputBarAdapter]
        StreamHandler --> WebSocket[WebSocketManager]
        
        ChatVM --> APIClient[APIClient]
        ChatVM --> DataContainer[SwiftDataContainer]
    end
    
    subgraph "UI Components"
        MessageCell --> BubbleView[MessageBubble]
        MessageCell --> Avatar[AvatarView]
        MessageCell --> Timestamp[TimestampLabel]
        MessageCell --> Status[StatusIndicator]
        
        InputBar --> TextView[UITextView]
        InputBar --> SendBtn[SendButton]
        InputBar --> AttachBtn[AttachmentButton]
    end
    
    subgraph "SwiftUI Components"
        SessionsView --> SessionVM[SessionListViewModel<br/>@StateObject]
        SessionVM --> SessionCard[SessionCardView]
        SessionCard --> LoadingView[LoadingStateView]
        SessionCard --> EmptyView[EmptyStateView]
        
        SettingsView --> SettingsVM[SettingsViewModel<br/>@StateObject]
        SettingsVM --> SettingRow[SettingRowView]
        SettingRow --> Toggle[ToggleView]
    end
    
    subgraph "Shared Components"
        CyberpunkTheme[CyberpunkTheme]
        LoadingIndicator[CyberpunkLoadingIndicator]
        ErrorAlert[ErrorAlertView]
        ContextMenu[ContextMenuView]
        
        ProjectsVC --> CyberpunkTheme
        ChatVC --> CyberpunkTheme
        SessionsView --> LoadingIndicator
        ChatVC --> LoadingIndicator
        ChatVC --> ErrorAlert
        MessageCell --> ContextMenu
    end
    
    subgraph "Data Flow"
        WebSocket --> StreamHandler
        StreamHandler --> ChatVM
        ChatVM --> ChatVC
        ChatVC --> TableHandler
        TableHandler --> MessageCell
        
        InputBar --> InputHandler
        InputHandler --> ChatVM
        ChatVM --> WebSocket
    end
```

## Component Hierarchy

### 1. Root Level
```
UIApplication
└── SceneDelegate
    └── UITabBarController (Root)
        ├── Tab 1: Projects (UINavigationController)
        ├── Tab 2: Sessions (UINavigationController)
        ├── Tab 3: Chat (UINavigationController)
        ├── Tab 4: Settings (UINavigationController)
        └── Tab 5: MCP (UINavigationController)
```

### 2. Projects Module
```
ProjectsViewController (UIKit)
├── UICollectionView
│   └── ProjectCollectionViewCell
│       ├── ProjectCardView
│       ├── ProjectImageView
│       └── ProjectMetadataView
├── SearchBar
├── FilterView
└── LoadingStateManager
```

### 3. Sessions Module (SwiftUI)
```
SessionListView
├── @StateObject: SessionListViewModel
├── NavigationStack
│   ├── SearchBar
│   ├── SortPicker
│   └── LazyVStack
│       └── ForEach(sessions)
│           └── SessionRowView
│               ├── SessionTitleView
│               ├── SessionMetadataView
│               └── SessionActionButtons
├── LoadingStateView
└── EmptyStateView
```

### 4. Chat Module (Hybrid)
```
ChatViewController (UIKit Base)
├── ChatViewModel (@MainActor)
│   ├── WebSocketManager
│   ├── APIClient
│   └── SwiftDataContainer
├── UITableView
│   ├── ChatTableViewHandler
│   │   └── ChatMessageCell
│   │       ├── MessageBubbleView
│   │       ├── AvatarImageView
│   │       ├── TimestampLabel
│   │       ├── StatusImageView
│   │       └── RetryButton
│   └── ChatDateHeaderView
├── ChatInputBarAdapter
│   ├── UITextView
│   ├── SendButton
│   ├── AttachmentButton
│   └── VoiceInputButton
└── StreamingMessageHandler
    └── WebSocketConnection
```

### 5. Settings Module (SwiftUI)
```
SettingsView
├── @StateObject: SettingsViewModel
├── Form
│   ├── Section: Account
│   │   ├── ProfileRow
│   │   └── APIKeyRow
│   ├── Section: Appearance
│   │   ├── ThemeToggle
│   │   └── TextSizeSlider
│   ├── Section: Privacy
│   │   ├── BiometricToggle
│   │   └── DataSharingToggle
│   └── Section: About
│       ├── VersionRow
│       └── SupportRow
└── NavigationDestinations
    ├── ProfileEditView
    └── APIKeyManagementView
```

## Data Flow Architecture

### Message Flow (User → Assistant)
```
1. User Input
   ├── InputTextView.text
   └── SendButton.tap
       ↓
2. InputHandler.sendMessage()
   ├── Validate input
   └── Create ChatMessage
       ↓
3. ChatViewModel.sendMessage()
   ├── Add to messages array
   ├── Update UI state
   └── Send via WebSocket
       ↓
4. WebSocketManager.send()
   ├── Serialize message
   └── Transmit to server
       ↓
5. StreamingMessageHandler
   ├── Receive chunks
   ├── Update message
   └── Notify ViewModel
       ↓
6. ChatTableViewHandler
   ├── Update cell
   └── Smooth scroll
```

### State Management
```
ChatViewModel (Source of Truth)
├── @Published messages: [ChatMessage]
├── @Published isLoading: Bool
├── @Published connectionStatus: ConnectionStatus
└── @Published error: Error?
    ↓
ChatViewController (UI Layer)
├── Observes ViewModel changes
├── Updates TableView
├── Updates InputBar state
└── Shows loading/error states
```

## SwiftUI-UIKit Integration Points

### 1. UIHostingController Usage
```swift
// Embedding SwiftUI in UIKit
let sessionListView = SessionListView(project: project)
let hostingController = UIHostingController(rootView: sessionListView)
navigationController?.pushViewController(hostingController, animated: true)
```

### 2. UIViewControllerRepresentable
```swift
// Embedding UIKit in SwiftUI
struct ChatViewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ChatViewController
    func updateUIViewController(_ uiViewController: ChatViewController, context: Context)
}
```

### 3. Combine Integration
```swift
// ViewModel publishing to both UIKit and SwiftUI
@MainActor
class SharedViewModel: ObservableObject {
    @Published var state: AppState
    
    // UIKit subscription
    var cancellables = Set<AnyCancellable>()
    
    // SwiftUI automatic observation
    // via @StateObject or @ObservedObject
}
```

## Component Communication

### Event Bus Pattern
```
NotificationCenter
├── MessageSentNotification
├── SessionChangedNotification
├── ThemeChangedNotification
└── ConnectionStatusNotification
```

### Delegate Pattern
```
ChatMessageCellDelegate
├── didTapRetry(message:)
├── didTapAvatar(user:)
└── didLongPress(message:)

ChatInputBarDelegate
├── didSendMessage(text:)
├── didChangeText()
└── didTapAttachment()
```

### Closure-Based Callbacks
```swift
StreamingMessageHandler.onMessageUpdate = { [weak self] message in
    self?.updateMessage(message)
}
```

## Performance Optimization Points

### 1. Cell Reuse
- ChatMessageCell with prepareForReuse()
- Cached height calculations
- Async image loading

### 2. Lazy Loading
- LazyVStack in SwiftUI views
- Pagination in SessionListView
- On-demand resource loading

### 3. State Management
- @MainActor for UI updates
- Background queues for data processing
- Combine debouncing for search

### 4. Memory Management
- Weak references in delegates
- Proper cleanup in deinit
- Image cache with size limits

---

*Architecture documented by SwiftUI Expert Agent*
*Version: 1.0.0*
*Last Updated: 2025-01-30*