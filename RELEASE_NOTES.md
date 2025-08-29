# Claude Code iOS - Release Notes

## Version 1.0.0 - Initial Release
**Release Date**: January 29, 2025  
**Build**: 1  
**Minimum iOS**: 17.0  

### 🎉 What's New

Welcome to Claude Code for iOS! This is the first public release of the native iOS client for Claude Code, bringing AI-powered development assistance to your iPhone and iPad.

### ✨ Key Features

#### 💬 Real-Time AI Chat
- WebSocket-based communication for instant responses
- Stream Claude's responses as they're generated
- Message status indicators (sending, delivered, read)
- Auto-reconnection with exponential backoff
- Offline message queuing

#### 📁 Project Management
- Create, rename, and delete projects
- Session management with full CRUD operations
- Message history with search
- Project-isolated data storage

#### 🔧 Git Integration (20 Operations)
- Complete Git workflow support
- Status, commit, push, pull, fetch
- Branch management and checkout
- Diff viewing and commit history
- Stash operations
- Generate AI-powered commit messages

#### 💻 Terminal Access
- Full ANSI color support (256 colors)
- Command execution via shell WebSocket
- Command history navigation
- Terminal resize support
- Real-time output streaming

#### 📂 File Explorer
- Browse project files and directories
- Syntax highlighting for code files
- File operations (create, rename, delete)
- Quick file preview
- Search within files

#### 🔍 Search Functionality
- Full-text search across projects
- File type filtering
- Search history
- Real-time search results

#### 🖥️ MCP Server Management
- Add and configure MCP servers
- Test server connections
- Execute CLI commands
- Server health monitoring

#### 🎨 Cyberpunk UI Theme
- Neon cyan (#00D9FF) and pink (#FF006E) accents
- Dark mode optimized
- Glow effects and animations
- Skeleton loading states
- Pull-to-refresh with haptic feedback
- Swipe actions for quick operations

### 🔒 Security & Privacy

- **Secure Token Storage**: JWT tokens stored in iOS Keychain
- **Encrypted Communication**: Support for HTTPS/WSS
- **Biometric Authentication**: Face ID/Touch ID support
- **No Data Collection**: Your code and conversations stay private
- **Local Storage**: SwiftData for offline access

### 📱 Device Support

- **iPhone**: 12, 13, 14, 15, 16 series
- **iPad**: All iPads running iOS 17+
- **Orientation**: Portrait and landscape
- **Accessibility**: VoiceOver support, Dynamic Type

### 🚀 Performance

- App launch: <2 seconds
- Memory usage: <150MB baseline
- 60fps scrolling and animations
- WebSocket reconnection: <3 seconds
- Optimized for 5G and WiFi

### 🐛 Known Issues

- Offline mode has limited functionality
- Large files (>10MB) may cause slowdowns
- Some Git operations require backend to be configured
- Widget extension not yet available

### 📝 Requirements

- iOS 17.0 or later
- iPhone 12 or newer recommended
- Active internet connection for AI features
- Claude Code backend server (local or remote)

### 🔮 Coming Soon

- **v1.1**: Cursor IDE integration
- **v1.2**: Push notifications
- **v1.3**: Widget extension
- **v1.4**: CloudKit sync
- **v2.0**: iPad-optimized UI

### 💡 Tips

1. **Quick Project Switch**: Swipe between projects in the tab bar
2. **Command Shortcuts**: Use up/down arrows in terminal for history
3. **Message Retry**: Tap failed messages to retry sending
4. **Quick Actions**: Long-press project tiles for options
5. **Haptic Feedback**: Can be disabled in Settings

### 🙏 Acknowledgments

Special thanks to:
- The Claude AI team at Anthropic
- Open source contributors
- Beta testers and early adopters
- The iOS development community

### 📮 Feedback

We'd love to hear from you! Please report bugs or suggest features:
- Email: support@claudecode.com
- GitHub: github.com/claudecode/ios
- Twitter: @ClaudeCodeApp

### 📜 Legal

- [Privacy Policy](https://claudecode.com/privacy)
- [Terms of Service](https://claudecode.com/terms)
- [Open Source Licenses](https://claudecode.com/licenses)

---

## Version History

### Beta Releases

#### v0.9.0 - Beta 3 (January 21, 2025)
- Fixed chat message status indicators
- Resolved assistant response filtering
- Improved WebSocket stability
- Added comprehensive logging

#### v0.8.0 - Beta 2 (January 17, 2025)
- Terminal WebSocket implementation
- ANSI color parser
- Search API integration
- MCP server UI fixes

#### v0.7.0 - Beta 1 (January 10, 2025)
- Initial TestFlight release
- Core functionality implemented
- Basic UI complete

---

*Claude Code iOS is developed with ❤️ for the developer community*