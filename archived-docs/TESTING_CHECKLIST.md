# iOS ClaudeCodeUI Testing Checklist

## Pre-Test Setup ✅
- [x] Backend server running at http://localhost:3004
- [x] AppConfig.swift URLs fixed to localhost:3004
- [x] Starscream WebSocket enabled (100% rollout)
- [x] JWT authentication fixed (using seconds not milliseconds)
- [x] WebSocket message types corrected (claude-command, cursor-command)
- [ ] iOS 18.5 runtime installed in Xcode (downloading...)

## Build & Deploy
Once runtime is installed:
```bash
# Build for your iPhone 16 Pro Max
xcodebuild build \
  -project ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj \
  -scheme ClaudeCodeUI \
  -destination 'platform=iOS,name=Nick's iPhone 16 Pro Max'

# Or build for iPad m2
xcodebuild build \
  -project ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj \
  -scheme ClaudeCodeUI \
  -destination 'platform=iOS,name=Nick's iPad m2'
```

## Critical Features to Test

### 1. Project Loading ⏸️
- [ ] Launch app
- [ ] Projects should auto-load from backend
- [ ] Verify loading indicator appears/disappears
- [ ] Check error handling if backend is down

### 2. Session Management ⏸️
- [ ] Select a project
- [ ] Sessions should load for that project
- [ ] Create new session (if UI exists)
- [ ] Delete session (swipe to delete)

### 3. WebSocket Connection ⏸️
- [ ] Open ChatViewController
- [ ] Check Xcode console for "WebSocket connected"
- [ ] Verify URL is ws://localhost:3004/ws (not /api/chat/ws)
- [ ] Test auto-reconnection by stopping/starting backend

### 4. Message Sending ⏸️
- [ ] Type a message
- [ ] Send it
- [ ] Verify it appears in chat
- [ ] Check backend logs for received message
- [ ] Verify message type is "claude-command"

### 5. Message Receiving ⏸️
- [ ] Backend should respond to messages
- [ ] Responses should appear in chat
- [ ] Streaming responses should work
- [ ] Check for proper message formatting

### 6. File Explorer ⏸️
- [ ] Navigate to file explorer tab
- [ ] Files should load from project
- [ ] Test file preview
- [ ] Test file operations (if implemented)

### 7. Terminal ⏸️
- [ ] Open terminal tab
- [ ] Should connect to ws://localhost:3004/shell
- [ ] Test command execution
- [ ] Verify ANSI color support

### 8. Settings ⏸️
- [ ] Open settings
- [ ] Verify theme switching works
- [ ] Test backup/restore (if implemented)
- [ ] Check about page info

## Console Logs to Watch For

### Success Indicators ✅
```
✅ WebSocket connected to ws://localhost:3004/ws
✅ Projects loaded successfully: [...]
✅ Session created with ID: ...
✅ Message sent with type: claude-command
✅ Using Starscream WebSocket implementation
```

### Error Indicators ❌
```
❌ WebSocket connection failed (wrong URL)
❌ 404 on /api/chat/ws (old URL path)
❌ Unknown message type: message (should be claude-command)
❌ JWT authentication failed (timestamp issue)
❌ CloudFlare tunnel URL (should be localhost)
```

## Backend Verification Commands

```bash
# Check backend is running
curl http://localhost:3004/api/health

# Test projects endpoint
curl http://localhost:3004/api/projects

# Check WebSocket (in separate terminal)
npm install -g wscat
wscat -c ws://localhost:3004/ws

# Monitor backend logs
# In backend directory, logs should show connections
```

## Screenshot Capture Points
1. Projects list loaded
2. Sessions list for a project
3. Chat with messages
4. WebSocket connected console log
5. Any error states

## Performance Benchmarks
- App launch: Should be <2 seconds
- Project load: Should be <1 second
- WebSocket connect: Should be <500ms
- Message send/receive: Should be instant
- Memory usage: Should stay under 150MB

## Known Issues to Verify Fixed
- [x] JWT uses seconds not milliseconds
- [x] Session messages endpoint format corrected
- [x] WebSocket URL path is /ws not /api/chat/ws
- [x] Message type is claude-command not message
- [x] Project path included in messages
- [x] Starscream implementation active

## Post-Test Actions
1. Document any remaining issues
2. Capture screenshots of working features
3. Note performance metrics
4. Create bug report for any failures
5. Celebrate successful connection! 🎉

---

**Status**: Waiting for iOS 18.5 runtime download to complete...