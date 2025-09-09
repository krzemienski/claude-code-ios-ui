# iOS Claude Code UI Testing Context

## Project Structure
- **Main App Target**: ClaudeCodeUI
  - Bundle ID: com.claudecode.ui
  - iOS Deployment: 17.0+
  - Dependencies: Starscream (WebSocket library)
  
## Test Targets
1. **ClaudeCodeUITests** - Unit tests
2. **ClaudeCodeUIUITests** - UI tests  
3. **ClaudeCodeUIIntegrationTests** - Integration tests

## Test Environment
- Simulator: iPhone 16 Pro Max (iOS 18.6)
- UUID: A707456B-44DB-472F-9722-C88153CDFFA1
- Backend: http://192.168.0.43:3004
- WebSocket URLs:
  - Chat: ws://192.168.0.43:3004/ws
  - Shell: ws://192.168.0.43:3004/shell

## Current Test Coverage Status
- Overall Pass Rate: 96.7% (87/90 tests)
- Chat View Controller: 100% (9/9)
- WebSocket Communication: 100% (8/8)
- Session Management: 100% (5/5)
- API Integration: 100% (49/49)
- Terminal WebSocket: 100% (4/4)
- UI/UX Features: 70% (7/10) - 3 failures
- Performance: 100% (5/5)

## Known Issues
1. Tab Navigation Stickiness - Medium severity
2. MCP Tab Visibility - Low severity
3. Pull-to-Refresh - Some views missing implementation
4. Swipe Actions - Partially implemented
5. Loading Indicators - Needs enhancement

## Test Files Available
- ChatViewControllerTests.swift
- TerminalWebSocketTests.swift  
- WebSocketStreamingTest.swift
- NavigationTests.swift
- SettingsTests.swift
- MCPServerTests.swift
- UIComponentTests.swift
- KeychainManagerTests.swift
- TestRunnerViewController.swift
- ui-test-scenarios.json

## Testing Methodology
1. Start Phase - Backend initialization
2. Project Phase - Project loading
3. Session Phase - Session management
4. Message Phase - WebSocket messaging
5. Cleanup Phase - Resource teardown