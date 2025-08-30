# Build and Test Configuration - Claude Code iOS UI

## Build System Details

### Tuist Configuration
- **Project.swift**: Defines 4 targets (app + 3 test targets)
- **Bundle ID**: com.claudecode.ui
- **Deployment Target**: iOS 17.0
- **Source Paths**: App/**, Core/**, Features/**, Design/**, Models/**, UIComponents/**, UI/**
- **Resources**: All storyboards, XIBs, assets, localization files

### SPM Configuration (Package.swift)
- **Swift Tools Version**: 5.9
- **Platform**: iOS 17.0
- **Dependencies**: Starscream WebSocket (v4.0.6)
- **Library Product**: ClaudeCodeUI
- **Excluded Paths**: Build files, Docker files, test directories

## Test Configuration

### Test Targets
1. **ClaudeCodeUITests** - Unit tests
2. **ClaudeCodeUIUITests** - UI automation tests  
3. **ClaudeCodeUIIntegrationTests** - Integration tests

### Test Scenarios (from ui-test-scenarios.json)
- **Navigation Flow Tests** (HIGH priority): App launch, project navigation, deep links
- **Chat Interface Tests** (HIGH priority): Message display, input, streaming, errors
- **SwiftUI Component Tests** (MEDIUM): Lists, settings, loading states
- **Accessibility Tests** (HIGH): VoiceOver, Dynamic Type, color contrast
- **Performance Tests** (MEDIUM): Scroll performance, large data sets, memory
- **Edge Cases** (LOW): Network interruptions, concurrent updates

### Test Requirements
- **Coverage**: 90% unit tests, 70% integration tests
- **Performance**: 60 FPS scroll, <3s load time, <100MB memory
- **Accessibility**: WCAG AA compliance, VoiceOver support
- **Devices**: iPhone 15 Pro/Max, iPhone SE, iPad Pro, iPad mini
- **iOS Versions**: 17.0, 17.5, 18.0

## Build Scripts and Tools

### Available Scripts
- `build-linux.sh` - Linux build support
- `compile-check.sh` - Compilation validation
- `run_integration_tests.sh` - Integration test runner
- Various Ruby scripts for Xcode fixes (fix_project.rb, remove_duplicates.rb)

### Build Commands
```bash
# Tuist commands
tuist generate  # Generate Xcode project
tuist build     # Build project
tuist test      # Run tests

# SPM commands  
swift build     # Build with SPM
swift test      # Run SPM tests

# Xcode commands
xcodebuild -scheme ClaudeCodeUI -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## CI/CD Configuration
- **Framework**: XCUITest
- **CI Integration**: GitHub Actions
- **Reporting**: Allure
- **Artifacts**: Screenshots, videos, performance metrics

## Current Build Status
- Multiple build logs present (build_output.txt, build_debug.log, build_validation.log)
- DerivedData and .build directories contain build artifacts
- Xcode workspace and project files recently modified