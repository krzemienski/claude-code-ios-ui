# Critical Integration Issues - Claude Code iOS UI

## Analysis Date: 2025-01-14

### 1. WebSocket URL Mismatch ❌
**Issue**: iOS app connects to wrong WebSocket endpoint
- **iOS sends to**: `ws://localhost:3004/api/chat/ws` (ChatViewController.swift:236)
- **Backend expects**: `ws://localhost:3004/ws` (index.js:459)
- **Fix needed**: Update iOS WebSocket URL in ChatViewController

### 2. WebSocket Message Type Mismatch ❌
**Issue**: iOS sends wrong message type
- **iOS sends**: `type: "message"` (WebSocketManager.swift:172)
- **Backend expects**: `type: "claude-command"` or `type: "cursor-command"` (index.js:477-486)
- **Fix needed**: Update WebSocketManager to send correct message type

### 3. No Session Management in iOS App ❌
**Issue**: iOS app doesn't create or manage sessions
- **Backend structure**: Projects → Sessions → Messages (JSONL files)
- **iOS structure**: Projects → Messages (no session layer)
- **Missing**: Session creation, session ID tracking, session selection UI
- **Fix needed**: Implement full session management in iOS app

### 4. API Endpoint Mismatch ✅ (Actually Correct)
**Initially thought incorrect, but verified correct**:
- iOS sends POST to `/api/projects` (APIClient.swift:240)
- Backend receives at `/api/projects` (index.js:213)
- This is working correctly

### 5. Authentication Token Not Persisting ⚠️
**Issue**: Auth token configuration happens but may not persist correctly
- **ProjectsViewController**: Lines 290-295 set auth token from settings
- **Fix needed**: Verify token persistence and usage in all API calls

### 6. Missing Session API Endpoints in iOS ❌
**Issue**: iOS has endpoint definitions but no implementation
- **Defined**: getSessions, createSession, deleteSession (APIClient.swift:248-258)
- **Not used**: No UI or logic to create/select sessions
- **Fix needed**: Implement session selection UI and management

### 7. Project Path Handling ❌
**Issue**: iOS app sends projectId, backend expects projectPath
- **iOS sends**: `projectId: "some-uuid"` 
- **Backend expects**: `projectPath: "/path/to/project"`
- **Fix needed**: Send project.path instead of project.id

### 8. WebSocket Reconnection ⚠️
**Issue**: Reconnection happens but to wrong URL
- ChatViewController:433 attempts reconnection
- Still uses wrong URL path
- **Fix needed**: Update reconnection URL

## Summary of Required Fixes

1. **Immediate fixes** (for basic functionality):
   - Update WebSocket URL from `/api/chat/ws` to `/ws`
   - Change message type from `"message"` to `"claude-command"`
   - Send project path instead of project ID

2. **Major fixes** (for proper functionality):
   - Implement full session management UI
   - Add session selection/creation screens
   - Update data models to include sessions
   - Fix WebSocket message payload structure

3. **Enhancement fixes**:
   - Ensure auth token persistence
   - Add session history display
   - Implement proper error handling
   - Add loading states for async operations