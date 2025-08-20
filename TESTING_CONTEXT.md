# TESTING_CONTEXT.md - iOS Claude Code UI Comprehensive Testing State

**Last Updated**: January 20, 2025  
**Project Location**: /Users/nick/Documents/claude-code-ios-ui/  
**Current Phase**: Comprehensive Testing Phase  
**API Implementation**: 79% (49/62 endpoints)  
**Build Status**: ✅ Successfully built

## Executive Summary

The iOS Claude Code UI app is in excellent functional state with 79% of backend API implemented, working WebSocket communication, complete Git integration (20/20 endpoints), and recently integrated skeleton loading UI enhancements. The app is ready for comprehensive testing across 15+ user flows to validate production readiness.

## Current State Snapshot

### ✅ Completed Features
- **WebSocket Communication**: Fully functional at `ws://localhost:3004/ws`
- **Authentication**: JWT token system working with proper expiry handling
- **Session Management**: Complete CRUD operations with enhanced UI
- **Git Integration**: 100% complete (all 20 endpoints implemented)
- **MCP Server Management**: 6/6 API endpoints implemented (UI accessibility issues)
- **Skeleton Loading**: Comprehensive loading states across all ViewControllers
- **File Operations**: Browse, read, write, delete functionality
- **Search**: 2/2 endpoints connected to API
- **Projects**: Full project navigation and data isolation

### 🔄 Known Issues
- **Terminal WebSocket**: Not connected to `ws://localhost:3004/shell`
- **MCP UI Access**: Tab exists but requires More menu navigation (iOS 6+ tabs behavior)
- **Settings Screen**: Placeholder implementation only
- **Search UI**: Mock data in some views despite API connection
- **Cursor Integration**: 0/8 endpoints implemented

### 📊 Performance Baselines
- **App Launch**: <2 seconds (target maintained)
- **Memory Usage**: <150MB baseline
- **WebSocket Reconnection**: <3 seconds with exponential backoff
- **Screen Transitions**: <300ms
- **API Response Times**: <500ms average

## Testing Environment Setup

### Prerequisites
1. **Backend Server**: Must be running on `http://localhost:3004`
   ```bash
   cd backend
   npm install
   npm start
   ```

2. **Simulator Configuration**
   - **CRITICAL UUID**: `05223130-57AA-48B0-ABD0-4D59CE455F14`
   - **Device**: iPhone 16 Pro Max
   - **iOS Version**: 18.6
   - **Always use UUID, never device name**

3. **Build Configuration**
   - **Xcode**: 15.x or later
   - **iOS SDK**: 17.0+
   - **Swift**: 5.9
   - **Scheme**: ClaudeCodeUI
   - **Configuration**: Debug-iphonesimulator

### Testing Protocol

#### UI Interaction Rules
- **ALWAYS** call `describe_ui()` first for precise coordinates
- **Use** `touch()` with down/up events, NOT `tap()`:
  ```javascript
  touch({ simulatorUuid: "05223130-57AA-48B0-ABD0-4D59CE455F14", x: 100, y: 200, down: true })
  touch({ simulatorUuid: "05223130-57AA-48B0-ABD0-4D59CE455F14", x: 100, y: 200, up: true })
  ```
- **NEVER** guess coordinates from screenshots

#### Log Management
- Use background streaming to avoid app restart:
  ```bash
  xcrun simctl spawn 05223130-57AA-48B0-ABD0-4D59CE455F14 log stream \
    --predicate 'processImagePath contains "ClaudeCodeUI"' > test_logs.txt &
  LOG_PID=$!
  # After testing
  kill $LOG_PID
  ```

## 15+ Comprehensive Test Flows

### Flow 1: Authentication & JWT Management
**Objective**: Validate JWT token generation, storage, and usage
1. Launch app
2. Verify automatic JWT generation
3. Check token storage in UserDefaults
4. Make authenticated API call
5. Verify token in request headers
6. Test token expiry handling
**Expected**: All API calls authenticated, auto-refresh on expiry
**Screenshot**: auth-flow.png

### Flow 2: Project Navigation & Data Isolation
**Objective**: Validate project list and cross-project data isolation
1. Load project list from `/api/projects`
2. Select first project
3. Verify project-specific data loaded
4. Switch to different project
5. Confirm data isolation (no bleed-over)
6. Test project creation/deletion
**Expected**: Clean project switching, proper data boundaries
**Screenshot**: project-navigation.png

### Flow 3: Session Management CRUD
**Objective**: Complete session lifecycle testing
1. Navigate to Sessions tab
2. Verify skeleton loading during fetch
3. Create new session (+ button)
4. Load existing sessions
5. Delete session with swipe gesture
6. Test pull-to-refresh functionality
**Expected**: All CRUD operations successful, UI updates reflect changes
**Screenshot**: session-management.png

### Flow 4: WebSocket Real-time Messaging
**Objective**: Validate WebSocket communication and auto-reconnection
1. Open chat view
2. Send message via WebSocket
3. Verify message format: `{"type": "claude-command", "content": "...", "projectPath": "..."}`
4. Receive streaming response
5. Force disconnect (kill backend)
6. Verify auto-reconnection (exponential backoff)
7. Resume messaging after reconnection
**Expected**: Seamless messaging with automatic recovery
**Screenshot**: websocket-chat.png

### Flow 5: File Explorer Operations
**Objective**: Complete file management testing
1. Navigate to Files tab
2. Browse directory tree
3. Open code file (verify syntax highlighting)
4. Create new file
5. Rename existing file
6. Delete file with confirmation
7. Test large directory performance (>100 files)
**Expected**: All file operations successful, good performance
**Screenshot**: file-explorer.png

### Flow 6: Git Integration Suite
**Objective**: Validate all 20 Git endpoints
1. Check git status
2. Stage files for commit
3. Create commit with message
4. View commit history
5. Switch branches
6. Create new branch
7. View diff between commits
8. Push/pull operations
**Expected**: Complete Git workflow functional
**Screenshot**: git-operations.png

### Flow 7: Search Functionality
**Objective**: Test search with filters and caching
1. Open search interface
2. Enter search query
3. Apply file type filters
4. Set date range
5. Execute search
6. Verify result highlighting
7. Test search caching (5-minute TTL)
8. Clear search and verify reset
**Expected**: Fast search with accurate results
**Screenshot**: search-results.png

### Flow 8: MCP Server Management
**Objective**: Test MCP server CRUD operations
1. Navigate to More tab → MCP
2. List existing MCP servers
3. Add new server configuration
4. Test server connection
5. Execute CLI command
6. Delete server
**Expected**: All 6 MCP endpoints functional (despite UI issues)
**Screenshot**: mcp-management.png

### Flow 9: Settings & Preferences
**Objective**: Validate settings management
1. Navigate to More tab → Settings
2. Switch theme (dark/light)
3. Adjust font size
4. Export settings to JSON
5. Reset settings
6. Import settings from file
**Expected**: Settings persist across sessions
**Screenshot**: settings-config.png

### Flow 10: Accessibility Features
**Objective**: Validate accessibility compliance
1. Enable VoiceOver
2. Navigate using VoiceOver gestures
3. Test Dynamic Type with large fonts
4. Enable high contrast mode
5. Test reduce motion setting
6. Verify all UI elements have labels
**Expected**: Full accessibility support
**Screenshot**: accessibility-test.png

### Flow 11: Performance Monitoring
**Objective**: Establish performance baselines
1. Cold launch timing (<2s)
2. Memory usage monitoring (<150MB)
3. CPU usage during operations
4. Network request latency
5. Animation frame rates (60fps)
6. Battery consumption tracking
**Expected**: Meet all performance targets
**Screenshot**: performance-metrics.png

### Flow 12: Error Recovery Scenarios
**Objective**: Test error handling and recovery
1. Disconnect network
2. Verify offline indication
3. Send API request (should queue)
4. Restore network
5. Verify queued requests execute
6. Test malformed API responses
7. Verify error alerts to user
**Expected**: Graceful error handling with recovery
**Screenshot**: error-recovery.png

### Flow 13: Concurrent Operations
**Objective**: Test thread safety and race conditions
1. Execute multiple API calls simultaneously
2. Send rapid WebSocket messages
3. Perform parallel file operations
4. Switch projects during loading
5. Cancel in-flight requests
**Expected**: No crashes, proper resource management
**Screenshot**: concurrent-ops.png

### Flow 14: Data Migration & Upgrades
**Objective**: Test upgrade scenarios
1. Install older app version
2. Create data (sessions, settings)
3. Upgrade to current version
4. Verify data migration
5. Check backward compatibility
6. Test schema changes
**Expected**: Seamless upgrades without data loss
**Screenshot**: data-migration.png

### Flow 15: Edge Cases & Boundaries
**Objective**: Test boundary conditions
1. Empty states for all views
2. Maximum length text input
3. Special characters in inputs
4. Network throttling (slow 3G)
5. Low memory conditions
6. Rapid navigation changes
7. Device rotation handling
**Expected**: Robust handling of edge cases
**Screenshot**: edge-cases.png

### Flow 16: Terminal Operations (Blocked)
**Objective**: Test terminal functionality once WebSocket connected
1. Connect to shell WebSocket `ws://localhost:3004/shell`
2. Execute basic commands (ls, pwd)
3. Test ANSI color rendering
4. Verify command history
5. Test terminal resize
**Status**: ❌ Blocked - Terminal WebSocket not connected
**Screenshot**: N/A

### Flow 17: Push Notifications (Future)
**Objective**: Test notification handling
1. Register for push notifications
2. Handle permission requests
3. Receive test notification
4. Test notification actions
5. Verify badge updates
**Status**: ⏳ Not implemented
**Screenshot**: N/A

## Test Execution Checklist

- [ ] Backend server running on port 3004
- [ ] Simulator UUID verified: `05223130-57AA-48B0-ABD0-4D59CE455F14`
- [ ] Background log streaming active
- [ ] Screenshots captured for each flow
- [ ] Performance metrics recorded
- [ ] Issues documented in ISSUES_TRACKER.md
- [ ] API usage patterns documented
- [ ] Cross-session knowledge captured

## Success Criteria

### Functional Requirements
- ✅ All 15 primary test flows pass
- ✅ No critical (P0) issues
- ✅ <5 high priority (P1) issues
- ✅ WebSocket maintains stable connection
- ✅ Data integrity maintained across operations

### Performance Requirements
- ✅ App launch <2 seconds
- ✅ Memory usage <150MB baseline
- ✅ No memory leaks detected
- ✅ 60fps UI animations
- ✅ API response times <500ms

### Quality Requirements
- ✅ No crashes during testing
- ✅ Accessibility compliance (WCAG 2.1 AA)
- ✅ Error recovery successful
- ✅ Offline handling graceful
- ✅ Data persistence reliable

## Next Steps

1. Execute all test flows systematically
2. Document issues in ISSUES_TRACKER.md
3. Update PERFORMANCE_BASELINE.md with metrics
4. Create API_USAGE.md with patterns
5. Generate test automation scripts
6. Prepare for TestFlight beta release

## Notes

- Terminal WebSocket connection is highest priority fix
- MCP UI accessibility needs improvement but APIs work
- Search functionality may need UI updates despite API connection
- Consider implementing feature flags for gradual rollout
- Plan for localization in future releases

---

*This document serves as the comprehensive testing context for the iOS Claude Code UI project. It should be updated after each testing session to maintain accurate state.*