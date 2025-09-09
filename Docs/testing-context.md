# ClaudeCodeUI iOS Testing Context Document
## Generated: 2025-08-30

## 🎯 Project Overview

### Project Structure
- **Framework**: Tuist-based iOS project
- **Minimum iOS Version**: 17.0
- **Main Target**: ClaudeCodeUI
- **Bundle ID**: com.claudecode.ui
- **External Dependencies**: Starscream (WebSocket library)

### Tuist Targets
1. **ClaudeCodeUI** (Main App)
   - Product: iOS App
   - Sources: App/, Core/, Features/, Design/, Models/, UIComponents/, UI/
   
2. **ClaudeCodeUITests** (Unit Tests)
   - Product: Unit Tests
   - Bundle ID: com.claudecode.ui.tests
   
3. **ClaudeCodeUIUITests** (UI Tests)
   - Product: UI Tests
   - Bundle ID: com.claudecode.ui.uitests
   
4. **ClaudeCodeUIIntegrationTests** (Integration Tests)
   - Product: Unit Tests (Integration)
   - Bundle ID: com.claudecode.ui.integrationtests

## 📁 Core Architecture

### Feature Modules
1. **Chat** - Real-time messaging with WebSocket streaming
2. **Sessions** - Session management and persistence
3. **Authentication** - User authentication and security
4. **Projects** - Project management
5. **FileExplorer** - File browsing and management
6. **Terminal** - Terminal integration
7. **Search** - Search functionality
8. **Settings** - App configuration
9. **MCP** - Model Context Protocol integration
10. **Git** - Git integration
11. **Analytics** - Analytics tracking
12. **Security** - Security features
13. **Feedback** - User feedback
14. **Onboarding** - User onboarding
15. **AppTour** - App tour/tutorial

### Core Components
- **Network Layer**: WebSocket managers (Starscream-based)
- **Data Layer**: Models, persistence, caching
- **UI Layer**: UIKit + SwiftUI hybrid
- **Navigation**: Coordinator pattern
- **Services**: Business logic and API integration

## 🧪 Testing Infrastructure

### Existing Test Coverage

#### Unit Tests (ClaudeCodeUITests/)
- SearchViewControllerTests.swift

#### Integration Tests (ClaudeCodeUIIntegrationTests/)
- WebSocketReconnectionTests.swift
- DataPersistenceIntegrationTests.swift
- WebSocketIntegrationTests.swift
- UIFlowIntegrationTests.swift
- UIFeaturesIntegrationTests.swift
- EdgeCaseIntegrationTests.swift
- MasterTestRunner.swift
- PerformanceIntegrationTests.swift
- Enhanced5PhaseIntegrationTests.swift
- APIIntegrationTests.swift
- SessionFlowE2ETests.swift
- AuthenticationIntegrationTests.swift

#### UI Tests (ClaudeCodeUIUITests/)
- WebSocketTests.swift

### Critical Components Requiring Testing

#### 🔴 High Priority (Core Functionality)
1. **WebSocket Communication**
   - WebSocketManager.swift
   - StarscreamWebSocketManager.swift
   - ShellWebSocketManager.swift
   - WebSocketAdapter.swift
   - WebSocketReconnection.swift
   - StreamingMessageHandler.swift

2. **Chat Feature**
   - ChatViewController.swift
   - ChatViewModel.swift
   - ChatStateManager.swift
   - ChatMessageProcessor.swift
   - MessageStatusManager.swift
   - ChatInputHandler.swift
   - ChatAttachmentHandler.swift

3. **Session Management**
   - Session persistence
   - Session switching
   - Session state recovery

#### 🟡 Medium Priority (Supporting Features)
1. **UI Components**
   - MessageCells
   - TypingIndicator
   - InputBar
   - EmptyStates
   - Loading components

2. **Navigation**
   - Tab bar navigation
   - Screen transitions
   - Deep linking

3. **Data Persistence**
   - Cache management
   - User preferences
   - Message history

#### 🟢 Low Priority (Nice to Have)
1. **Analytics**
2. **App Tour**
3. **Feedback System**

## 📊 Test Categories

### 1. Unit Tests
- **Purpose**: Test individual components in isolation
- **Coverage Target**: 80%
- **Focus Areas**: ViewModels, Managers, Processors, Utilities

### 2. Integration Tests
- **Purpose**: Test component interactions
- **Coverage Target**: 70%
- **Focus Areas**: WebSocket + UI, Data persistence, Session flows

### 3. UI Tests
- **Purpose**: Test user interactions
- **Coverage Target**: 60%
- **Focus Areas**: Critical user journeys, Chat flow, Settings

### 4. Performance Tests
- **Purpose**: Measure app performance
- **Metrics**: Memory usage, CPU usage, Network latency
- **Benchmarks**: App launch < 2s, Message send < 100ms

### 5. Edge Case Tests
- **Purpose**: Test error handling and recovery
- **Scenarios**: Network failures, Invalid data, Concurrent operations

## 🔧 Testing Dependencies

### Required Tools
- XCTest Framework
- XCUITest for UI Testing
- Mock/Stub implementations for:
  - WebSocket connections
  - Network responses
  - File system operations
  - User defaults

### Test Data Requirements
- Sample messages (various types)
- Mock session data
- Test user credentials
- Sample file structures
- Mock API responses

## 📈 Testing Execution Plan

### Phase 1: Foundation (Days 1-2)
- Set up test environment
- Create mock implementations
- Establish test data fixtures

### Phase 2: Core Features (Days 3-5)
- WebSocket manager tests
- Chat feature tests
- Session management tests

### Phase 3: Integration (Days 6-7)
- End-to-end flows
- Data persistence
- Error recovery

### Phase 4: UI & Performance (Days 8-9)
- UI automation tests
- Performance benchmarks
- Memory leak detection

### Phase 5: Validation (Day 10)
- Full regression suite
- Coverage analysis
- Issue remediation

## 🚦 Success Criteria

### Minimum Requirements
- ✅ All existing tests passing
- ✅ 80% unit test coverage
- ✅ Critical user journeys tested
- ✅ No memory leaks
- ✅ Performance benchmarks met

### Quality Gates
- No critical bugs
- < 5 high priority bugs
- < 10 medium priority bugs
- All edge cases handled gracefully

## 📝 Notes

### Known Issues
- Terminal WebSocket tests are currently disabled
- Some test files in Tests/ directory may be duplicates

### Architecture Considerations
- Hybrid UIKit/SwiftUI architecture requires special testing approaches
- WebSocket streaming needs careful mocking
- Coordinator pattern affects navigation testing

### External Dependencies
- Starscream WebSocket library needs mocking for unit tests
- Network calls should be stubbed in integration tests

## 🔄 Coordination Protocol

### Agent Communication
1. **Context Manager** (this agent) maintains overall state
2. **Test Developer** creates/updates test implementations
3. **Test Runner** executes tests and reports results
4. **Issue Tracker** logs and categorizes failures
5. **Reviewer** validates test quality and coverage

### Information Flow
1. Context updates → All agents
2. Test results → Context Manager & Issue Tracker
3. Issues → Context Manager & Test Developer
4. Coverage reports → Context Manager & Reviewer

### Synchronization Points
- After each test phase completion
- When critical issues are found
- Before moving to next priority level
- At daily progress checkpoints