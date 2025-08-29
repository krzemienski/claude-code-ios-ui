# iOS Claude Code UI - Testing Plan for Missing Features

## Testing Environment Setup

### Prerequisites
- iOS Simulator: iPhone 16 Pro Max with iOS 18.6
- Backend Server: Running on `http://192.168.0.43:3004`
- WebSocket Server: `ws://192.168.0.43:3004/ws` and `ws://192.168.0.43:3004/shell`
- Test Project: Sample project with various file types

### Test Device Configuration
```bash
# Build for specific simulator
xcodebuild build \
  -project ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj \
  -scheme ClaudeCodeUI \
  -destination 'platform=iOS Simulator,id=A707456B-44DB-472F-9722-C88153CDFFA1'
```

## 1. MCP Tab Visibility Testing (P0 - CRITICAL)

### Test Cases

#### TC-MCP-01: Tab Bar Configuration
**Objective**: Verify MCP tab is directly accessible
**Steps**:
1. Launch app in simulator
2. Check tab bar at bottom of screen
3. Count visible tabs
4. Verify MCP tab is at index 2

**Expected Result**: 
- 4 tabs visible: Projects, Terminal, MCP, Search
- Settings tab in "More" menu (tab 5)
- MCP tab directly accessible without "More" navigation

**Pass Criteria**: ✅ MCP tab visible and tappable

#### TC-MCP-02: MCP Tab Functionality
**Objective**: Verify MCP server management works
**Steps**:
1. Tap MCP tab
2. Verify MCP server list loads
3. Tap "+" button to add server
4. Fill server details form
5. Test server connection

**Expected Result**:
- MCP list view displays
- Add server form works
- Connection test provides feedback
- Server appears in list after adding

**Pass Criteria**: ✅ Full MCP functionality accessible

#### TC-MCP-03: Backend API Integration
**Objective**: Verify MCP APIs are connected
**Steps**:
1. Monitor network requests in debug console
2. Add a test MCP server
3. Verify API calls to `/api/mcp/servers`
4. Test server connection API call

**Expected Result**:
- GET `/api/mcp/servers` called on load
- POST `/api/mcp/servers` called on add
- POST `/api/mcp/servers/:id/test` called on connection test

**Pass Criteria**: ✅ All MCP API endpoints working

## 2. Search Functionality Testing (P1 - HIGH)

### Test Cases

#### TC-SEARCH-01: Mock Data Replacement
**Objective**: Verify search uses real backend data
**Prerequisites**: Backend search endpoint implemented
**Steps**:
1. Navigate to Search tab
2. Enter search query "ViewController"
3. Monitor network requests
4. Verify results are from backend, not mock

**Expected Result**:
- API call to `/api/projects/:name/search`
- Real search results displayed
- No mock data in results

**Pass Criteria**: ✅ Search uses backend API

#### TC-SEARCH-02: Search Error Handling
**Objective**: Test graceful degradation when backend unavailable
**Steps**:
1. Disconnect backend server
2. Perform search query
3. Verify fallback behavior
4. Check error messaging

**Expected Result**:
- Graceful fallback to mock data or cached results
- User-friendly error message
- App doesn't crash

**Pass Criteria**: ✅ Robust error handling

#### TC-SEARCH-03: Search Performance
**Objective**: Verify search response times
**Steps**:
1. Search for common term
2. Measure response time
3. Test with large result sets
4. Verify UI responsiveness

**Expected Result**:
- Search response < 1 second
- UI remains responsive during search
- Loading indicator works correctly

**Pass Criteria**: ✅ Performance targets met

#### TC-SEARCH-04: Search Result Navigation
**Objective**: Test tapping search results
**Steps**:
1. Perform search with results
2. Tap on search result
3. Verify navigation to file/location
4. Test back navigation

**Expected Result**:
- Navigation to selected file
- Proper back button functionality
- Context preserved

**Pass Criteria**: ✅ Result navigation works

## 3. Terminal WebSocket Verification (P2 - MEDIUM)

### Test Cases

#### TC-TERM-01: WebSocket Connection
**Objective**: Verify stable WebSocket connection
**Steps**:
1. Navigate to Terminal tab
2. Check connection status
3. Monitor connection logs
4. Verify auto-reconnection

**Expected Result**:
- Connection to `ws://192.168.0.43:3004/shell`
- Connection status indicator shows connected
- Auto-reconnection on network interruption

**Pass Criteria**: ✅ Stable WebSocket connection

#### TC-TERM-02: Command Execution
**Objective**: Test command execution and output
**Test Commands**:
```bash
pwd
ls -la
echo "Hello World"
cd /tmp
whoami
```

**Steps**:
1. Enter each command in terminal
2. Verify output appears correctly
3. Check ANSI color rendering
4. Test command history (up/down arrows)

**Expected Result**:
- All commands execute correctly
- Output displays with proper formatting
- ANSI colors render correctly
- Command history works

**Pass Criteria**: ✅ All test commands work

#### TC-TERM-03: ANSI Color Testing
**Objective**: Verify ANSI escape sequence handling
**Test Command**:
```bash
echo -e "\033[31mRed\033[32mGreen\033[33mYellow\033[34mBlue\033[35mMagenta\033[36mCyan\033[0mReset"
```

**Expected Result**:
- Each color segment renders in correct color
- Reset sequence clears formatting
- No garbled text or escape sequences visible

**Pass Criteria**: ✅ ANSI colors render correctly

#### TC-TERM-04: Terminal Resize
**Objective**: Test terminal resize functionality
**Steps**:
1. Rotate device/change window size
2. Verify terminal adjusts
3. Check resize message sent to backend
4. Verify output formatting

**Expected Result**:
- Terminal adjusts to new size
- No text cutoff or formatting issues
- Backend receives resize messages

**Pass Criteria**: ✅ Resize handling works

## 4. Integration Testing

### Test Cases

#### TC-INT-01: Cross-Tab Navigation
**Objective**: Verify navigation between features
**Steps**:
1. Start in Projects tab
2. Navigate through all tabs
3. Test deep linking between features
4. Verify state preservation

**Expected Result**:
- Smooth navigation between all tabs
- No crashes or memory issues
- State preserved when switching tabs

**Pass Criteria**: ✅ Seamless cross-tab experience

#### TC-INT-02: Authentication Flow
**Objective**: Test authentication across features
**Steps**:
1. Clear authentication tokens
2. Try accessing MCP servers
3. Try performing search
4. Try using terminal
5. Verify authentication prompts

**Expected Result**:
- Proper authentication required
- Consistent auth handling across features
- JWT tokens work correctly

**Pass Criteria**: ✅ Authentication works consistently

#### TC-INT-03: Offline Behavior
**Objective**: Test app behavior when offline
**Steps**:
1. Disconnect network
2. Try each major feature
3. Reconnect network
4. Verify sync/recovery

**Expected Result**:
- Graceful offline handling
- Cached data when available
- Proper sync on reconnection

**Pass Criteria**: ✅ Robust offline support

## 5. Performance Testing

### Test Cases

#### TC-PERF-01: App Launch Time
**Objective**: Verify app launch performance
**Steps**:
1. Force quit app
2. Launch app
3. Measure time to usable UI
4. Test cold vs warm start

**Target**: < 2 seconds to usable UI
**Pass Criteria**: ✅ Launch time under target

#### TC-PERF-02: Memory Usage
**Objective**: Monitor memory consumption
**Steps**:
1. Use Instruments to profile memory
2. Navigate through all features
3. Perform search operations
4. Use terminal extensively
5. Check for memory leaks

**Target**: < 150MB baseline memory usage
**Pass Criteria**: ✅ No memory leaks, usage under target

#### TC-PERF-03: WebSocket Performance
**Objective**: Test WebSocket reliability
**Steps**:
1. Send multiple terminal commands rapidly
2. Test during network transitions
3. Measure reconnection time
4. Test concurrent WebSocket usage

**Target**: 
- Command response < 500ms
- Reconnection < 3 seconds
- No message loss

**Pass Criteria**: ✅ Performance targets met

## 6. User Acceptance Testing

### Test Scenarios

#### Scenario 1: Developer Workflow
1. Open project
2. Search for specific code pattern
3. Navigate to file from search results
4. Use terminal to run commands
5. Check MCP server status

#### Scenario 2: Configuration Management
1. Add new MCP server
2. Test server connection
3. Remove server
4. Configure search preferences
5. Customize terminal settings

#### Scenario 3: Error Recovery
1. Disconnect network during operations
2. Force close app during WebSocket communication
3. Send invalid commands to terminal
4. Search for non-existent content
5. Add invalid MCP server configuration

## Testing Timeline

### Phase 1 (Days 1-2): Core Functionality
- TC-MCP-01 through TC-MCP-03
- TC-SEARCH-01 and TC-SEARCH-02
- TC-TERM-01 and TC-TERM-02

### Phase 2 (Days 3-4): Advanced Features
- TC-SEARCH-03 and TC-SEARCH-04
- TC-TERM-03 and TC-TERM-04
- TC-INT-01 and TC-INT-02

### Phase 3 (Day 5): Performance & Polish
- TC-PERF-01 through TC-PERF-03
- TC-INT-03
- User Acceptance Testing

## Bug Reporting Template

```markdown
**Bug ID**: BUG-[FEATURE]-[NUMBER]
**Feature**: MCP/Search/Terminal/Integration
**Severity**: Critical/High/Medium/Low
**Environment**: iOS 18.6, iPhone 16 Pro Max Simulator

**Steps to Reproduce**:
1. 
2. 
3. 

**Expected Result**:

**Actual Result**:

**Screenshots/Logs**:

**Workaround**:

**Fix Priority**: P0/P1/P2/P3
```

## Success Criteria Summary

### Must Pass (P0)
- ✅ MCP tab directly accessible and functional
- ✅ All critical APIs working
- ✅ No crashes during basic workflows

### Should Pass (P1)
- ✅ Search uses real backend data
- ✅ Terminal WebSocket stable and responsive
- ✅ Performance targets met

### Nice to Have (P2)
- ✅ Advanced search features working
- ✅ Enhanced terminal features
- ✅ Comprehensive error handling

This testing plan ensures all missing features are properly validated before release, with clear pass/fail criteria and comprehensive coverage of both functional and non-functional requirements.