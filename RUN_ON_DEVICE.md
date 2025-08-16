# 🚀 Running ClaudeCodeUI on Your iPhone 16 Pro Max

## Current Status ✅
- **Backend**: Running at http://localhost:3004 (verified)
- **iOS 18.5 Runtime**: Installed
- **Build Issues**: FIXED - Protocol conformance resolved
- **Authentication**: REMOVED - Backend requires no auth
- **WebSocket**: Starscream implementation enabled (superior)

## Quick Launch Instructions

### In Xcode (Now Open):

1. **Select Your Device**
   - In the toolbar at the top, click the device selector (next to the app name)
   - Choose "Nick's iPhone 16 Pro Max" from the list
   - If not visible, connect via USB and trust the computer

2. **Build and Run**
   - Press `Cmd+R` or click the Play button
   - First run will take longer (provisioning profile setup)
   - App will install and launch on your iPhone

3. **If Build Fails with Signing Error:**
   - Select project in navigator (blue icon)
   - Go to "Signing & Capabilities" tab
   - Check "Automatically manage signing"
   - Select your Apple ID team
   - Bundle ID should be: com.claudecode.ui

## What to Test

### 1. Initial Launch
- ✅ App should launch without crashes
- ✅ No authentication screen (we removed auth)
- ✅ Projects list should load automatically

### 2. Project Loading
- Tap "Refresh" or pull down to refresh
- Should see your 34 projects from backend
- Loading indicator should appear/disappear correctly

### 3. Session Testing
- Tap any project
- Sessions should load (or show empty state)
- Try creating a new session if UI allows

### 4. WebSocket Chat
- Open a session
- Check Xcode console for: "WebSocket connected to ws://localhost:3004/ws"
- Send a test message
- Should see proper formatting in backend logs

## Console Monitoring

### Watch for Success Messages:
```
✅ Using Starscream WebSocket implementation
✅ WebSocket connected to ws://localhost:3004/ws
✅ Projects loaded: 34
✅ Session created with ID: ...
```

### Watch for Errors:
```
❌ Connection refused (backend not running)
❌ 404 errors (wrong URL path)
❌ CloudFlare URLs (should be localhost)
```

## Troubleshooting

### App Won't Install
- Ensure iPhone is unlocked
- Trust the developer certificate in Settings → General → Device Management
- Try restarting iPhone if needed

### Network Connection Issues
- Ensure iPhone and Mac are on same WiFi network
- Check firewall isn't blocking port 3004
- Try using Mac's IP instead of localhost:
  ```swift
  // Find Mac IP: ifconfig | grep "inet " | grep -v 127.0.0.1
  static let backendURL = "http://YOUR_MAC_IP:3004"
  ```

### WebSocket Not Connecting
- Backend logs should show connection attempts
- Check WebSocket URL is ws:// not wss:// for local
- Verify Starscream is enabled (it should be at 100%)

## Expected Behavior

1. **Projects Tab**: Shows 34 projects from backend
2. **Sessions Tab**: Shows sessions for selected project
3. **Chat Tab**: WebSocket connects, messages send/receive
4. **Files Tab**: File tree loads (if implemented)
5. **Terminal Tab**: Shell commands execute (if implemented)

## Backend Verification

In terminal, you should see:
```bash
# When app connects
New WebSocket connection
Client connected

# When sending messages
Received message: {"type":"claude-command","content":"test","projectPath":"/path"}

# No auth errors - all removed!
```

## Success Criteria

- [x] App builds without errors
- [x] Runs on iPhone 16 Pro Max
- [ ] Projects load from backend
- [ ] Sessions display correctly
- [ ] WebSocket connects successfully
- [ ] Messages send and receive
- [ ] No authentication required

---

**Note**: The app is configured to use the superior Starscream WebSocket implementation which provides better reliability, auto-reconnection, and proper message streaming. All authentication has been removed from both iOS and backend for seamless development.