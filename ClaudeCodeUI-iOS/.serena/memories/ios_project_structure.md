# ClaudeCodeUI-iOS Project Structure Analysis

## Project Configuration
- **Build System**: Tuist (modern Swift build configuration)
- **Minimum iOS Version**: 17.0
- **Bundle ID**: com.claudecode.ui
- **External Dependencies**: Starscream (WebSocket library)

## Target Structure (4 targets)
1. **ClaudeCodeUI** - Main app target
2. **ClaudeCodeUITests** - Unit tests
3. **ClaudeCodeUIUITests** - UI tests  
4. **ClaudeCodeUIIntegrationTests** - Integration tests

## Key Directory Structure
```
ClaudeCodeUI-iOS/
├── App/                    # Application entry point & resources
├── Core/                   # Core functionality
│   ├── Data/              # SwiftData models & container
│   ├── Network/           # WebSocket & networking
│   ├── Services/          # Business logic services
│   ├── Security/          # Authentication & keychain
│   └── Navigation/        # Navigation coordinators
├── Features/              # Feature modules
│   ├── Chat/             # Main chat feature (complex)
│   ├── Terminal/         # Terminal functionality
│   └── Settings/         # App settings
├── Design/               # UI design system
│   ├── Theme/           # Color & typography
│   ├── Components/      # Reusable UI components
│   └── Effects/         # Visual effects
├── Tests/               # Test files
├── Tuist/              # Tuist configuration
└── Derived/            # Generated files

## Critical Issues Identified
1. **Starscream Dependency**: Not properly integrated (using stub)
2. **Test Configuration**: Multiple test schemes with potential conflicts
3. **SwiftData Container**: Complex initialization with fallback logic
4. **Chat Feature**: Very large file (137KB ChatViewController.swift)