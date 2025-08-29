# iOS Claude Code UI

<div align="center">

![Claude Code Logo](assets/logo.png)

**AI-Powered iOS Development Assistant**  
*Native iOS client for Claude Code with a cyberpunk-themed UI*

[![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org)
[![API Coverage](https://img.shields.io/badge/API%20Coverage-79%25-green)](API_DOCUMENTATION.md)
[![Test Coverage](https://img.shields.io/badge/Tests-96.7%25%20Pass-success)](TESTING_REPORT.md)
[![License](https://img.shields.io/badge/License-MIT-purple)](LICENSE)

[Features](#features) • [Installation](#installation) • [Documentation](#documentation) • [Contributing](#contributing)

</div>

---

## 🚀 Production Status

**✅ PRODUCTION READY** - Version 1.0.0 (January 21, 2025)

The app has achieved production readiness with **96.7% test pass rate** across 90 test cases. All critical features are functioning correctly.

### Key Metrics
- **API Implementation**: 79% (49/62 endpoints implemented)
- **Test Coverage**: 96.7% (87/90 tests passing)
- **Performance**: ✅ All targets met (<2s launch, <150MB memory)
- **Security**: ✅ JWT authentication, input validation
- **UI/UX**: All 5 tabs functional with cyberpunk theme

---

## ✨ Features

### Core Functionality
- 💬 **Real-time AI Chat** - WebSocket-based Claude integration
- 📁 **Project Management** - Create, organize, and manage coding projects
- 🔧 **Git Integration** - 20+ Git operations with visual diff
- 💻 **Terminal Access** - Full ANSI color support
- 📂 **File Explorer** - Browse and edit with syntax highlighting
- 🔍 **Search** - Full-text search across projects
- 🖥️ **MCP Servers** - Manage Model Context Protocol servers

### UI/UX
- 🎨 **Cyberpunk Theme** - Neon aesthetics with dark mode
- ⚡ **Lightning Fast** - <2s launch, 60fps animations
- 📱 **Responsive Design** - iPhone and iPad optimized
- ♿ **Accessibility** - VoiceOver and Dynamic Type support

### Security
- 🔒 **Keychain Storage** - Secure credential management
- 🔐 **JWT Authentication** - Token-based security
- 🛡️ **Data Protection** - Encrypted at rest

---

## 📱 Screenshots

<div align="center">
<img src="assets/screenshot1.png" width="250"> <img src="assets/screenshot2.png" width="250"> <img src="assets/screenshot3.png" width="250">
</div>

---

## 🛠 Installation

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ device or simulator
- Node.js 18+ (for backend)
- macOS Ventura or later

### Quick Start

1. **Clone the repository**
```bash
git clone https://github.com/claudecode/ios.git
cd claude-code-ios-ui
```

2. **Start the backend server**
```bash
cd backend
npm install
npm start  # Runs on http://localhost:3004
```

3. **Open the iOS project**
```bash
open ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj
```

4. **Build and run**
- Select your target device/simulator
- Press `Cmd+R` to build and run

### Configuration

For production deployment, update `AppConfig.swift`:
```swift
static var backendURL = "https://your-api.com"
static let websocketURL = "wss://your-api.com/ws"
```

See [Production Configuration](PRODUCTION_CONFIG.md) for detailed deployment instructions.

---

## 📚 Documentation

- **[CLAUDE.md](CLAUDE.md)** - Comprehensive implementation guide (1700+ lines)
- **[API_DOCUMENTATION.md](API_DOCUMENTATION.md)** - Complete API reference (62 endpoints)
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Production deployment instructions
- **[TESTING_REPORT.md](TESTING_REPORT.md)** - Test results and coverage
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and release notes

---

## 🏗 Architecture

```
ClaudeCodeUI-iOS/
├── Core/                    # Core services and utilities
│   ├── Config/             # App configuration
│   ├── Network/            # API client, WebSocket
│   ├── Security/           # Keychain, authentication
│   └── Navigation/         # Coordinators
├── Features/               # Feature modules (MVVM)
│   ├── Chat/              # AI chat interface
│   ├── Projects/          # Project management
│   ├── Terminal/          # Terminal emulator
│   └── Git/               # Git operations
├── Design/                 # UI/UX components
│   ├── Theme/             # Cyberpunk theme
│   └── Effects/           # Animations
└── Resources/             # Assets, Info.plist
```

**Design Patterns**:
- MVVM + Coordinators
- Dependency Injection
- Protocol-Oriented Programming
- Result Types for Error Handling

---

## 🧪 Testing

Run tests with:
```bash
# Unit tests
xcodebuild test -scheme ClaudeCodeUI -destination 'platform=iOS Simulator,name=iPhone 16'

# UI tests
xcodebuild test -scheme ClaudeCodeUIUITests -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Coverage**: 
- Unit Tests: 27 test files
- Integration: WebSocket, API, Session flow
- UI Tests: Navigation, interactions

---

## 🚀 Deployment

### TestFlight Beta
1. Archive the app in Xcode
2. Upload to App Store Connect
3. Submit for TestFlight review

### App Store Release
See [Production Configuration](PRODUCTION_CONFIG.md) for complete deployment guide.

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Workflow
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

### Code Style
- SwiftLint rules enforced
- Follow Swift API Design Guidelines
- Document public APIs

---

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Anthropic](https://anthropic.com) - Claude AI
- [Starscream](https://github.com/daltoniam/Starscream) - WebSocket library
- Beta testers and contributors

---

## 📮 Support

- **Email**: support@claudecode.com
- **Issues**: [GitHub Issues](https://github.com/claudecode/ios/issues)
- **Twitter**: [@ClaudeCodeApp](https://twitter.com/ClaudeCodeApp)

---

<div align="center">
<strong>Built with ❤️ for the developer community</strong>

[⬆ Back to top](#claude-code-ios)
</div>