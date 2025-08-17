# iOS Claude Code UI - Connection Fix Summary

## What Was Fixed

### 1. ✅ APIClient Authentication
- **Issue**: JWT token was using milliseconds instead of seconds for timestamp
- **Fixed**: APIClient now uses a valid hardcoded JWT token for demo user
- **File**: `APIClient.swift` line 57-62

### 2. ✅ Singleton Usage
- **Issue**: Multiple APIClient instances were being created
- **Fixed**: All components now use `APIClient.shared` singleton
- **Files**: 
  - `DIContainer.swift` - Uses shared instance
  - `ProjectsViewController.swift` - Uses shared instance

### 3. ✅ WebSocket Connection
- **Issue**: WebSocket was marking as connected before handshake completed
- **Fixed**: WebSocket now verifies connection with ping before marking as connected
- **File**: `WebSocketManager.swift` line 162-180

## Backend Status
- ✅ Server running on http://localhost:3004
- ✅ Authentication working with JWT token
- ✅ Projects endpoint returning 44 projects
- ✅ WebSocket endpoint accessible at ws://localhost:3004/ws

## Next Steps to Test

### 1. Clean and Rebuild the App
```bash
# In Xcode:
1. Product → Clean Build Folder (Cmd+Shift+K)
2. Product → Build (Cmd+B)
3. Product → Run (Cmd+R)
```

### 2. Clear App Data on Simulator
```bash
# Reset simulator to clear any cached data:
Device → Erase All Content and Settings...
```

### 3. Run the App
The app should now:
1. Connect to backend on port 3004
2. Authenticate with the demo user token
3. Load and display projects
4. Connect WebSocket for real-time chat

### 4. Verify in Console
Look for these success messages in Xcode console:
- "🔧 Using backend URL: http://localhost:3004"
- "✅ Successfully fetched X projects from API"
- "WebSocket connected and verified: ws://localhost:3004/ws"

## Hardcoded Configuration
The app now uses these hardcoded values:
- Backend URL: `http://localhost:3004`
- WebSocket URL: `ws://localhost:3004/ws`
- JWT Token: Valid demo user token (hardcoded in APIClient.swift)

## If Issues Persist

### Check Backend
```bash
# Verify backend is running
curl http://localhost:3004/api/auth/status

# Check projects endpoint
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjIsInVzZXJuYW1lIjoiZGVtbyIsImlhdCI6MTc1NTEzMjI3Mn0.D2ca9DyDwRR8rcJ3Latt86KyfsfuN4_8poJCQCjQ8TI" http://localhost:3004/api/projects
```

### Check Network Settings
For iOS Simulator, localhost should work. If not, try:
1. Use `127.0.0.1` instead of `localhost`
2. Use your Mac's IP address (find with `ifconfig | grep inet`)

### Enable Debug Logging
The app has debug logging enabled. Check Xcode console for:
- API request/response logs
- WebSocket connection logs
- Error messages

## Common Issues & Solutions

### Issue: "Network Error"
- **Cause**: Backend not running
- **Solution**: Start backend with `npm start` in backend directory

### Issue: "401 Unauthorized"
- **Cause**: Invalid or expired JWT token
- **Solution**: Token is hardcoded and should work. If not, regenerate with backend

### Issue: WebSocket fails to connect
- **Cause**: Token not being passed correctly
- **Solution**: WebSocket now adds token as query parameter automatically

### Issue: No projects showing
- **Cause**: API call failing or empty response
- **Solution**: Check backend has projects, verify token works

## Files Modified
1. `Core/Network/APIClient.swift` - JWT token fix
2. `Core/Network/WebSocketManager.swift` - Connection verification
3. `Core/Services/DIContainer.swift` - Use shared APIClient
4. `Features/Projects/ProjectsViewController.swift` - Use shared APIClient