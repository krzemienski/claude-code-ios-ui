# iOS Claude Code UI - Missing Features Implementation Plan

Based on analysis of the project at `/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS`, here are the identified missing features and their implementation priorities.

## Current Project Status

### ✅ Working Features
- **Tab Bar Structure**: 5 tabs configured (Projects, Terminal, Search, MCP, Settings)
- **Terminal WebSocket**: Fully implemented with `ShellWebSocketManager.swift`
- **ANSI Color Support**: Complete with `TerminalOutputParser` and `ANSIColorParser`
- **MCP Server Management**: Complete SwiftUI implementation with `MCPServerListViewController`
- **Search UI**: Basic implementation with `SearchViewController`
- **Authentication & API**: JWT auth, 79% of backend endpoints implemented

### 🔴 Priority Issues Identified

## 1. MCP Server UI Accessibility (CRITICAL - P0)

**Issue**: MCP tab appears to be configured but may not be visible due to iOS tab bar limitations
**Root Cause**: With 5 tabs, iOS creates a "More" menu for tabs beyond the 4th position

### Implementation Steps:

1. **Verify Tab Visibility**
   - **File**: `MainTabBarController.swift` (lines 116-117)
   - **Current**: 5 tabs configured: `[projectsNav, terminalNav, searchNav, mcpNav, settingsNav]`
   - **Issue**: MCP tab at index 3 should be visible, but may be in "More" menu
   - **Fix**: Reorder tabs or reduce to 4 main tabs

2. **Test MCP Tab Access**
   - **Location**: Tab bar index 3 (MCP Servers)
   - **Expected**: Direct access to MCP server management
   - **Current Status**: SwiftUI implementation complete in `MCPServerListViewController.swift`

3. **Backend Integration Verification**
   - **APIs**: All 6 MCP endpoints implemented in APIClient
   - **Missing**: Real data connection testing
   - **Fix**: Verify API calls in `MCPServerViewModel`

## 2. Search Functionality Mock Data (HIGH - P1)

**Issue**: Search is using mock data instead of real API
**Location**: `SearchViewController.swift` lines 132-140

### Implementation Steps:

1. **Replace Mock Data**
   ```swift
   // Current (lines 134-139):
   DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
       self?.searchResults = self?.generateMockResults(for: query) ?? []
   
   // Replace with:
   APIClient.shared.searchInProject(query: query, projectName: currentProject) { result in
       // Handle real API response
   }
   ```

2. **Add Missing Backend Endpoint**
   - **Endpoint**: `POST /api/projects/:projectName/search`
   - **Status**: Not implemented in backend
   - **Dependency**: Backend team needs to implement search endpoint

3. **Implement Search Filters**
   - **Create**: `SearchFiltersView.swift`
   - **Features**: File type filters, date range, regex support
   - **Integration**: Connect to search API with filter parameters

## 3. Terminal WebSocket Improvements (MEDIUM - P2)

**Current Status**: ✅ Fully implemented and working
**Evidence**: Complete `ShellWebSocketManager.swift` with all features:
- WebSocket connection to `ws://192.168.0.43:3004/shell`
- ANSI color parsing with 256 colors support
- Command history with persistence
- Terminal resize handling
- Auto-reconnection with exponential backoff

### Remaining Enhancements:

1. **Command Auto-completion**
   - **Location**: `TerminalViewController.swift` line 834
   - **Current**: Basic implementation for common commands
   - **Enhancement**: File path completion via backend API

2. **Better Error Handling**
   - **Enhancement**: Distinguish between network and command errors
   - **UI**: Show connection status indicator

## 4. Cursor Integration (LOW - P3)

**Status**: 🔴 Not implemented (0/8 endpoints)
**Evidence**: Only comments found in APIClient, no actual implementation

### Missing Components:

1. **API Endpoints** (8 missing):
   - `GET /api/cursor/config`
   - `POST /api/cursor/config`
   - `GET /api/cursor/sessions`
   - `GET /api/cursor/session/:id`
   - `POST /api/cursor/session/import`
   - `GET /api/cursor/database`
   - `POST /api/cursor/sync`
   - `GET /api/cursor/settings`

2. **Data Models**:
   - **Create**: `CursorModels.swift`
   - **Models**: CursorConfig, CursorSession, CursorDatabase, CursorSettings

3. **View Controllers**:
   - **Create**: `CursorTabViewController.swift`
   - **Features**: Config management, session import, database sync

4. **Backend Dependencies**:
   - **Requirement**: Backend must implement Cursor DB integration
   - **Complexity**: High - requires Cursor IDE database access

## Implementation Timeline

### Week 1: Critical Fixes
1. **Day 1-2**: Fix MCP tab visibility issue
   - Test current tab bar behavior
   - Implement tab reordering if needed
   - Verify MCP API integration

2. **Day 3-4**: Replace search mock data
   - Coordinate with backend for search endpoint
   - Implement real API integration
   - Add error handling

3. **Day 5**: Terminal enhancements
   - Add command auto-completion
   - Improve connection status UI

### Week 2: Search & UI Polish
1. **Day 1-3**: Complete search functionality
   - Implement search filters UI
   - Add search result caching
   - Test search performance

2. **Day 4-5**: UI improvements
   - Add loading states and error handling
   - Implement pull-to-refresh
   - Polish animations and transitions

### Week 3-4: Cursor Integration (Optional)
1. **Week 3**: Backend coordination
   - Define Cursor integration requirements
   - Implement backend endpoints
   - Create data models

2. **Week 4**: iOS implementation
   - Create Cursor view controllers
   - Implement sync functionality
   - Add configuration management

## Dependencies & Risks

### External Dependencies:
1. **Backend Search Endpoint**: Required for search functionality
2. **Cursor IDE Access**: Complex integration requiring Cursor DB access
3. **Testing Infrastructure**: Need real device testing for WebSocket reliability

### Technical Risks:
1. **iOS Tab Bar Limitation**: May require UI redesign for >4 tabs
2. **WebSocket Stability**: Network reliability in production environment
3. **Cursor Integration Complexity**: May require significant backend architecture changes

### Mitigation Strategies:
1. **Tab Bar**: Implement custom tab bar or use navigation drawer pattern
2. **WebSocket**: Implement robust offline mode and queue management
3. **Cursor**: Start with read-only integration, expand to full sync later

## Testing Requirements

### Critical Test Cases:
1. **MCP Tab Access**: Verify tab is accessible and functional
2. **Search Integration**: Test with real backend data
3. **Terminal WebSocket**: Test connection reliability and command execution
4. **Cross-Tab Navigation**: Ensure all features work after tab fixes

### Performance Targets:
- App launch: <2 seconds
- Search response: <1 second
- Terminal command: <500ms response
- WebSocket reconnection: <3 seconds

## Success Metrics

### Week 1 Goals:
- ✅ MCP tab fully accessible and functional
- ✅ Search using real backend data
- ✅ Terminal WebSocket 99%+ reliability

### Week 2 Goals:
- ✅ Complete search functionality with filters
- ✅ Polished UI with proper loading states
- ✅ Performance targets met

### Optional Week 3-4 Goals:
- ✅ Cursor integration MVP (read-only)
- ✅ Configuration management
- ✅ Session import functionality

## Next Steps

1. **Immediate Action**: Test MCP tab accessibility in iOS simulator
2. **Backend Coordination**: Request search endpoint implementation
3. **Priority Assessment**: Confirm Cursor integration is required for MVP
4. **Resource Allocation**: Assign developers based on priority levels

This implementation plan provides a clear roadmap for addressing the missing features while maintaining the existing functionality and following iOS development best practices.