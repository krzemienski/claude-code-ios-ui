# 🔧 Quick Fix Reference Card - Claude Code iOS

## 🔴 CRITICAL FIXES (Must Fix First)

### 1. Chat WebSocket (`WebSocketManager.swift`)
```swift
// ❌ BROKEN
["type": "claude-command", "content": text]

// ✅ FIX  
["type": "claude-command", "content": text, "projectPath": path, "sessionId": id]
```

### 2. Terminal WebSocket (`ShellWebSocketManager.swift`)
```swift
// ❌ BROKEN
terminalOutput.append("$ \(command)")  // Just echoing

// ✅ FIX
webSocket.send(["type": "shell-command", "command": cmd, "cwd": dir])
```

### 3. Tab Bar (`MainTabBarController.swift`)
```swift
// ❌ BROKEN ORDER
[projects, terminal, search, mcp, settings]  // Index mismatch

// ✅ FIX - Verify indices match tab bar items
viewControllers[2] = searchNav   // Not mcpNav!
viewControllers[3] = mcpNav      // Not settingsNav!
viewControllers[4] = settingsNav // Was missing!
```

## 🟡 TEST COMMANDS

### Quick Terminal Test
```bash
# After fixing terminal WebSocket:
1          # Accept trust dialog
ls         # Should list files
pwd        # Should show path
echo test  # Should echo "test"
```

### Quick Chat Test
```javascript
// Send this exact message:
"Test message from fix validation"
// Should NOT show ❌ error
// Should get Claude response
```

### Quick Tab Test
```
Tap each tab in order:
1. Projects → Should show project list
2. Terminal → Should show terminal
3. Search → Should show search (not "MCP Servers")
4. MCP → Should show MCP servers (not "Search")  
5. Settings → Should show settings
```

## 🟢 FILE LOCATIONS

| Component | File | Line # |
|-----------|------|--------|
| Chat WebSocket | `WebSocketManager.swift` | ~150-200 |
| Terminal WebSocket | `ShellWebSocketManager.swift` | ~100-150 |
| Tab Bar Setup | `MainTabBarController.swift` | ~50-100 |
| Trust Dialog | `TerminalViewController.swift` | ~200-250 |
| Search UI | `SearchViewController.swift` | Whole file |
| MCP UI | `MCPServersViewController.swift` | Whole file |

## 🔵 BACKEND ENDPOINTS

### WebSocket URLs (Correct)
- Chat: `ws://192.168.0.43:3004/ws`
- Shell: `ws://192.168.0.43:3004/shell`

### Message Formats
```json
// Chat Message
{
  "type": "claude-command",
  "content": "user message",
  "projectPath": "/full/path",
  "sessionId": "session-uuid"
}

// Terminal Command
{
  "type": "shell-command",
  "command": "ls -la",
  "cwd": "/current/directory"
}
```

## ⚡ VALIDATION CHECKLIST

After each fix, verify:

- [ ] **Chat**: Send "Hello" → No ❌ error
- [ ] **Terminal**: Type "ls" → See file list
- [ ] **Tab 3**: Shows "Search" not "MCP Servers"
- [ ] **Tab 4**: Shows "MCP Servers" not "Search"
- [ ] **Tab 5**: Shows "Settings" (accessible)
- [ ] **Trust Dialog**: Disappears after typing "1"
- [ ] **Reconnection**: Kill backend, restart, auto-reconnects
- [ ] **Memory**: Stays under 150MB
- [ ] **No Crashes**: Tap everything rapidly
- [ ] **Error Recovery**: Airplane mode on/off

## 📱 TEST DEVICE

**ALWAYS USE THIS SIMULATOR**:
- Device: iPhone 16 Pro Max
- UUID: `A707456B-44DB-472F-9722-C88153CDFFA1`
- iOS: 18.6

## 🎯 SUCCESS CRITERIA

The app is fixed when:
1. Can send messages without errors ✅
2. Can execute terminal commands ✅
3. All 5 tabs show correct content ✅
4. Search returns results ✅
5. MCP servers are manageable ✅
6. Auto-reconnection works ✅
7. No crashes in 10 minutes ✅
8. Memory < 150MB ✅

## 🚨 COMMON MISTAKES

1. **Don't** change WebSocket URLs - they're correct!
2. **Don't** modify JWT token - it works!
3. **Don't** skip adding sessionId to chat messages
4. **Don't** forget to test all 5 tabs after fixing
5. **Don't** assume echo means execution in terminal

## 💡 DEBUGGING TIPS

```swift
// Add to WebSocketManager
print("📤 Sending: \(message)")
print("📥 Received: \(response)")

// Add to ShellWebSocketManager  
print("🖥️ Command: \(command)")
print("📟 Output: \(output)")

// Add to MainTabBarController
print("🔄 Tab \(index): \(viewController)")
```

---
**Time Estimate**: 3 days (24 hours) total
**Priority**: Fix in order listed (1→2→3)
**Testing**: After each fix, run validation checklist

*Keep this card visible while fixing!*