# Mock Data Removal Coordination - iOS Claude Code UI

## Context Management Summary
**Coordinator**: context-manager agent  
**Target**: Remove ALL mock data from iOS app, ensure real backend integration only  
**Status**: Initial assessment complete, ready for ios-swift-developer agent execution

## 📊 Current State Assessment

### Mock Data Locations Identified
1. **ChatViewController.swift** (PRIMARY)
   - Lines 669-683: Mock fallback logic in `loadMessages()`
   - Lines 687-799: `createTestMessages()` function generating 120+ fake messages
   - **Issue**: Falls back to mock data when backend fails

2. **ChatViewController_Part2.swift** (DUPLICATE)
   - Line 15: Duplicate `createTestMessages()` function
   - **Issue**: Redundant mock data generator

3. **AppConstants.swift**
   - Line 153: `mockDataEnabled = false` (already disabled, good)
   - No action needed here

4. **APIClient.swift**
   - Lines 53-62: Hardcoded development JWT token
   - **Status**: ACCEPTABLE for development testing
   - No removal needed, this is required for auth

### WebSocket Configuration Status ✅
- **URL**: Correctly configured as `ws://localhost:3004/ws`
- **Location**: AppConfig.swift line 20
- **Message Type**: Using `claude-command` (correct)
- **Authentication**: JWT token properly included
- **URL Fix**: StarscreamWebSocketManager already fixes `/api/chat/ws` → `/ws`

### Backend Integration Status
- **Implemented**: 37 of 62 endpoints (60%)
- **Working Features**:
  - ✅ Authentication (5/5 endpoints)
  - ✅ Projects (5/5 endpoints)
  - ✅ Sessions (6/6 endpoints)
  - ✅ Files (4/4 endpoints)
  - ✅ Git (16/16 endpoints)
  - ✅ WebSocket connection

## 🎯 Required Actions for ios-swift-developer

### Priority 1: Remove Mock Data Functions
1. **ChatViewController.swift**
   - DELETE lines 687-799 (entire `createTestMessages()` function)
   - MODIFY lines 669-683: Remove mock fallback, add proper error handling

2. **ChatViewController_Part2.swift**
   - DELETE entire file if only contains duplicate mock function
   - OR remove the `createTestMessages()` function from it

### Priority 2: Replace Mock Fallback with Error State
In `ChatViewController.swift` `loadMessages()` method:
```swift
// CURRENT (lines 669-683) - MUST CHANGE
} catch {
    print("❌ Failed to load from backend, creating test messages: \(error)")
    await MainActor.run {
        if !append {
            self.messages = self.createTestMessages() // ❌ REMOVE THIS
        }
        // ...
    }
}

// REPLACE WITH:
} catch {
    print("❌ Failed to load from backend: \(error)")
    await MainActor.run {
        self.messages = [] // Keep empty, no fake data
        self.isLoadingMore = false
        self.isLoading = false
        
        // Show error state UI
        self.showErrorState(error: error)
    }
}
```

### Priority 3: Add Error State UI
Create proper error state handling:
```swift
private func showErrorState(error: Error) {
    // Add error view or alert
    let alert = UIAlertController(
        title: "Connection Error",
        message: "Failed to connect to backend server. Please ensure the server is running on port 3004.",
        preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
        self.loadMessages()
    })
    alert.addAction(UIAlertAction(title: "OK", style: .cancel))
    self.present(alert, animated: true)
}
```

### Priority 4: Verify Real-Time Streaming
Ensure WebSocket shows real JSON streaming:
1. Test WebSocket connection to `ws://localhost:3004/ws`
2. Verify message format uses `type: "claude-command"`
3. Include `projectPath` in all messages
4. Display streaming JSON chunks in UI (not just final message)

## 📝 Verification Checklist

### Before Changes
- [ ] Backend server running on http://localhost:3004
- [ ] WebSocket accessible at ws://localhost:3004/ws
- [ ] Note current mock data behavior for comparison

### After Changes
- [ ] NO `createTestMessages()` functions remain
- [ ] NO mock data fallback in error handlers
- [ ] Empty message list when backend unavailable
- [ ] Error alert/view shown when connection fails
- [ ] Real-time JSON streaming visible in chat
- [ ] All messages come from actual backend

## 🔍 Search Commands for Verification

```bash
# Find any remaining mock/test data
grep -r "createTest\|mockData\|fakeData\|testData\|dummyData" ClaudeCodeUI-iOS/

# Verify WebSocket URL usage
grep -r "ws://localhost:3004" ClaudeCodeUI-iOS/

# Check for fallback patterns
grep -r "creating test messages\|fallback\|dummy" ClaudeCodeUI-iOS/
```

## 📊 Success Criteria

1. **No Mock Data**: Zero fake messages or data anywhere
2. **Real Backend Only**: All data from localhost:3004
3. **Proper Error States**: Clear user feedback when backend unavailable
4. **Live Streaming**: JSON chunks visible during Claude responses
5. **Clean Codebase**: No test data generation code remains

## 🚨 Critical Requirements

- **ABSOLUTE**: No mock data anywhere in the app
- **REQUIRED**: Real-time streaming must be visible
- **MANDATORY**: Proper error handling instead of fake data
- **ESSENTIAL**: All features work with real backend only

## Next Steps for ios-swift-developer

1. Remove all mock data functions (Priority 1)
2. Implement proper error handling (Priority 2)
3. Add error state UI components (Priority 3)
4. Test WebSocket streaming (Priority 4)
5. Verify with search commands
6. Run app and confirm no fake data appears

---

**Context maintained by**: context-manager agent  
**Last updated**: Current session  
**Ready for**: ios-swift-developer agent execution