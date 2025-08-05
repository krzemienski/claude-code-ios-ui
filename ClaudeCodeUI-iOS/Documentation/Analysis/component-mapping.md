# React to iOS Component Mapping - ClaudeCodeUI

## Main Components

### Layout Components
| React Component | iOS Equivalent | Notes |
|----------------|----------------|-------|
| Sidebar.jsx | UISplitViewController + UINavigationController | Projects list and navigation |
| MobileNav.jsx | UITabBarController | Bottom navigation for mobile |
| MainContent.jsx | UIViewController container | Main content area |

### Core Features
| React Component | iOS Equivalent | Notes |
|----------------|----------------|-------|
| ChatInterface.jsx | ChatViewController | Main chat UI with messages |
| Shell.jsx | TerminalViewController | Terminal emulator |
| GitPanel.jsx | GitViewController | Git operations panel |
| TodoList.jsx | TodoViewController | Task management |
| ImageViewer.jsx | UIImageView + zoom | Image display with gestures |

### UI Components
| React Component | iOS Equivalent | Notes |
|----------------|----------------|-------|
| button.jsx | UIButton / SwiftUI Button | Styled with Claude Code theme |
| input.jsx | UITextField / SwiftUI TextField | Text input with theme |
| badge.jsx | UILabel with styling | Status badges |
| scroll-area.jsx | UIScrollView | Scrollable content areas |

### Special Components
| React Component | iOS Equivalent | Notes |
|----------------|----------------|-------|
| ClaudeLogo.jsx | UIImageView or custom CALayer | Animated logo |
| ClaudeStatus.jsx | Custom status view | Connection status indicator |
| MicButton.jsx | UIButton with AVAudioSession | Voice input |
| DarkModeToggle.jsx | UISwitch | Theme switcher |
| ProtectedRoute.jsx | Navigation guard pattern | Auth check |
| LoginForm.jsx | LoginViewController | Authentication UI |

### Settings & Controls
| React Component | iOS Equivalent | Notes |
|----------------|----------------|-------|
| QuickSettingsPanel.jsx | UITableViewController | Settings list |
| ToolsSettings.jsx | Custom settings view | Tool permissions UI |

## Key UI Patterns to Implement

### 1. Projects Sidebar
- iOS: Use UISplitViewController for iPad, UINavigationController for iPhone
- Show project cards with gradient blocks
- Implement pull-to-refresh

### 2. Chat Interface
- Message bubbles with sender distinction (Claude: cyan border, User: pink border)
- Streaming text updates
- Code syntax highlighting using NSAttributedString
- Image attachments support

### 3. Terminal/Shell
- Use a custom terminal view or library
- ANSI color code support
- Command history with up/down arrows
- Text selection and copy

### 4. File Explorer
- UITableView with expandable sections
- File icons based on type
- Preview functionality
- Swipe actions for file operations

### 5. Authentication
- Face ID integration with LocalAuthentication framework
- Keychain storage for credentials
- Session persistence

## Claude Code Design System Elements

### Colors
- Primary: Cyan (#00D9FF)
- Accent: Pink (#FF006E)
- Gradients: Blue (#0066FF) to Purple (#9933FF)
- Background: Dark (#0A0A0F)
- Surface: Dark blue-gray (#1A1A2E)

### Typography
- Use SF Pro Display/Text
- Large titles for headers
- Regular weight for body text
- Monospace for code

### Effects
- Cyan glow on active elements
- Grid pattern backgrounds
- Gradient blocks as decorative elements
- Smooth animations (0.3s duration)