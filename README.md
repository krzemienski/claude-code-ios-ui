# 🚀 Claude Code iOS UI

<div align="center">
  <img src="docs/images/logo.png" alt="Claude Code iOS" width="200" />
  
  [![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
  [![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue.svg)](https://developer.apple.com/ios/)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
  [![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen.svg)](https://github.com)
  
  **Native iOS client for Claude Code with cyberpunk-themed UI**
</div>

## ✨ Features

### 🎨 Cyberpunk Design System
- Dark theme with neon cyan (#00D9FF) and pink (#FF006E) accents
- Custom glow effects and animations
- Scanline and matrix rain visual effects
- Fully responsive design for iPhone and iPad

### 💬 Real-time Chat Interface
- WebSocket-based messaging
- Markdown rendering with syntax highlighting
- File attachments and image preview
- Typing indicators and message status
- Smart reconnection with exponential backoff

### 📁 Advanced File Explorer
- Tree-view navigation with breadcrumbs
- Syntax highlighting for 20+ languages
- File operations (create, rename, delete, move)
- Search functionality
- Recent files quick access

### 🖥️ Integrated Terminal
- Command execution with ANSI color support
- Command history and auto-completion
- Output copying and sharing
- Custom themes and font sizes

### 🎯 Project Management
- Create and manage multiple projects
- Project status tracking
- Pull-to-refresh synchronization
- Grid and list view options
- Batch operations support

### ⚙️ Settings & Customization
- Theme customization
- Font size adjustment
- Haptic feedback controls
- Settings export/import
- Automatic backups
- Data persistence with SwiftData

### 🎓 User Experience
- 6-page onboarding flow
- Interactive app tour with spotlight effects
- Comprehensive feedback system
- Full accessibility support (VoiceOver, Dynamic Type)
- Offline mode with intelligent caching

## 📱 Screenshots

<div align="center">
  <img src="docs/images/projects.png" width="250" alt="Projects" />
  <img src="docs/images/chat.png" width="250" alt="Chat" />
  <img src="docs/images/terminal.png" width="250" alt="Terminal" />
</div>

## 🛠️ Tech Stack

- **Language**: Swift 5.9
- **UI Framework**: UIKit + SwiftUI (hybrid)
- **Minimum iOS**: 17.0
- **Architecture**: MVVM with Coordinators
- **Persistence**: SwiftData
- **Networking**: URLSession + WebSocket
- **Backend**: Node.js + Express + SQLite

## 🚀 Quick Start

### Prerequisites

- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- Node.js 18.0+
- iOS Simulator or device with iOS 17.0+

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/claude-code-ios-ui.git
   cd claude-code-ios-ui
   ```

2. **Setup the backend**
   ```bash
   cd backend
   npm install
   cp .env.example .env
   npm start
   ```
   The backend will start on `http://localhost:3004`

3. **Open the iOS project**
   ```bash
   cd ..
   open ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj
   ```

4. **Configure and run**
   - Select your target device (iPhone 15 Pro recommended)
   - Build and run (Cmd+R)
   - The app will connect to the local backend automatically

## 📖 Documentation

- [Testing Guide](TESTING.md) - Comprehensive testing procedures (190+ test cases)
- [Handoff Guide](HANDOFF.md) - Complete code review instructions
- [API Documentation](docs/API.md) - Backend API reference
- [Design System](docs/DESIGN.md) - UI/UX guidelines

## 🏗️ Architecture

```
ClaudeCodeUI-iOS/
├── Core/
│   ├── Config/          # App configuration
│   ├── Navigation/      # Coordinators
│   ├── Network/         # API & WebSocket
│   ├── Services/        # Business logic
│   └── Accessibility/   # A11y support
├── Features/
│   ├── Projects/        # Project management
│   ├── Chat/           # Chat interface
│   ├── FileExplorer/   # File browser
│   ├── Terminal/       # Terminal emulator
│   ├── Settings/       # App settings
│   └── Onboarding/     # First launch
├── Models/             # Data models
├── Design/             # Theme & effects
└── Resources/          # Assets & configs
```

## 🧪 Testing

Run the comprehensive test suite:

```bash
# Backend tests
cd backend
npm test

# iOS tests (in Xcode)
Cmd+U
```

See [TESTING.md](TESTING.md) for detailed testing procedures.

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 Roadmap

### Phase 8: iOS Extensions
- [ ] Today Widget
- [ ] Lock Screen Widgets
- [ ] Siri Shortcuts
- [ ] Share Extension

### Phase 9: Advanced Features
- [ ] Push Notifications
- [ ] CloudKit Sync
- [ ] Multi-window support (iPad)
- [ ] External keyboard shortcuts

### Phase 10: Production
- [ ] Authentication system
- [ ] End-to-end encryption
- [ ] App Store preparation
- [ ] Analytics integration

## 🐛 Known Issues

- Widget extension not yet implemented
- Push notifications pending configuration
- Share extension incomplete
- No authentication (localhost only)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [ClaudeCodeUI](https://github.com/siteboon/claudecodeui) - The backend server is based on this excellent project
- Claude AI for development assistance
- The Swift community for excellent libraries
- Cyberpunk 2077 for design inspiration
- All contributors and testers

### Backend Attribution

The backend server (`backend/server.js`) is adapted from the [ClaudeCodeUI](https://github.com/siteboon/claudecodeui) project, which provides a comprehensive Node.js/Express backend for Claude Code integration. We've extended it with iOS-specific compatibility while maintaining all the original features including:
- Real file system operations (no mocks)
- WebSocket support for real-time updates
- SQLite database for data persistence
- Terminal command execution
- Claude CLI integration
- Project management from ~/.claude/projects

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/claude-code-ios-ui/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/claude-code-ios-ui/discussions)
- **Email**: support@example.com

## 🌟 Star History

[![Star History Chart](https://api.star-history.com/svg?repos=yourusername/claude-code-ios-ui&type=Date)](https://star-history.com/#yourusername/claude-code-ios-ui&Date)

---

<div align="center">
  Made with ❤️ and ☕ by the Claude Code team
  
  <a href="https://twitter.com/claudecode">Twitter</a> •
  <a href="https://discord.gg/claudecode">Discord</a> •
  <a href="https://claudecode.ai">Website</a>
</div>