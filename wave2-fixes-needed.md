# Wave 2 - Code Fixes Required
## Based on Testing Results - January 21, 2025

---

## 🔴 CRITICAL FIXES

### 1. WebSocketManager.swift - Critical Reconnection Bug Fix
**File:** `/ClaudeCodeUI-iOS/Core/Network/WebSocketManager.swift`  
**Function:** `handleError(_ error: Error)` around line 700+  
**Issue:** Reconnection logic fails during connection phase due to incorrect state check

**ROOT CAUSE IDENTIFIED:**
The `handleError` function checks `wasConnected` (which uses `isConnected` property) before attempting reconnection. However, `isConnected` only returns true when `connectionState == .connected`. During the initial connection ping that fails, the state is still `.connecting`, so reconnection is never attempted.

**Required Changes:**
```swift
// FIX: Update handleError function to check connection state properly
private func handleError(_ error: Error) {
    stopPingTimer()
    
    let wasConnectedOrConnecting = connectionState == .connected || connectionState == .connecting  // FIX HERE
    let previousState = connectionState
    connectionState = .disconnected
    
    // Only notify delegate if we were actually connected or connecting
    if previousState != .disconnected && previousState != .failed {
        delegate?.webSocketDidDisconnect(self as WebSocketProtocol, error: error)
    }
    
    // Attempt reconnection if:
    // 1. We were connected OR connecting (FIXED)
    // 2. Auto-reconnect is enabled
    // 3. This was NOT an intentional disconnect
    // 4. We're not already reconnecting
    if wasConnectedOrConnecting && enableAutoReconnect && !intentionalDisconnect && previousState != .reconnecting {
        attemptReconnection()
    }
}

// NOTE: Exponential backoff is already implemented correctly in attemptReconnection()
// The delay calculation is: min(reconnectDelay * pow(2.0, Double(reconnectAttempts - 1)), maxReconnectDelay)
// This gives: 1s, 2s, 4s, 8s, 16s, up to maxReconnectDelay (30s)
```

---

### 2. ChatViewController.swift - Manual Retry UI
**File:** `/ClaudeCodeUI-iOS/Features/Chat/ChatViewController.swift`  
**Location:** Message cell configuration  
**Issue:** No manual retry option for failed messages

**Required Changes:**
```swift
// Add to message cell configuration
if message.status == .failed {
    cell.retryButton.isHidden = false
    cell.retryButton.addTarget(self, action: #selector(retryMessage(_:)), for: .touchUpInside)
    cell.retryButton.tag = indexPath.row
}

@objc private func retryMessage(_ sender: UIButton) {
    let message = messages[sender.tag]
    // Retry logic
    message.status = .sending
    tableView.reloadRows(at: [IndexPath(row: sender.tag, section: 0)], with: .none)
    webSocketManager.sendMessage(message.content)
}
```

---

### 3. Memory Optimization
**Multiple Files Affected:**

#### ChatViewController.swift
- Implement view recycling properly
- Release unused resources in `viewDidDisappear`
- Limit message history cache

#### WebSocketManager.swift
- Clear message buffers when disconnected
- Implement message queue size limits

#### SwiftDataContainer.swift
- Add memory warning observers
- Implement cache cleanup on memory pressure

**Memory Reduction Strategy:**
```swift
// Add to AppDelegate or SceneDelegate
NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleMemoryWarning),
    name: UIApplication.didReceiveMemoryWarningNotification,
    object: nil
)

@objc private func handleMemoryWarning() {
    // Clear caches
    URLCache.shared.removeAllCachedResponses()
    // Clear message history beyond last 100
    // Clear image caches
}
```

---

## 🟡 MEDIUM PRIORITY FIXES

### 4. Connection Status Indicator Visual Updates
**File:** `/ClaudeCodeUI-iOS/Features/Chat/ChatViewController.swift`  
**Location:** Navigation bar setup

**Required Changes:**
```swift
private func updateConnectionStatus(_ isConnected: Bool) {
    DispatchQueue.main.async { [weak self] in
        let statusView = self?.navigationItem.rightBarButtonItem?.customView as? UIView
        
        UIView.animate(withDuration: 0.3) {
            if isConnected {
                statusView?.backgroundColor = .systemGreen
                statusView?.layer.removeAllAnimations()
            } else {
                statusView?.backgroundColor = .systemRed
                // Add pulsing animation
                let pulse = CABasicAnimation(keyPath: "opacity")
                pulse.fromValue = 1.0
                pulse.toValue = 0.3
                pulse.duration = 1.0
                pulse.repeatCount = .infinity
                pulse.autoreverses = true
                statusView?.layer.add(pulse, forKey: "pulse")
            }
        }
    }
}
```

---

### 5. Pull-to-Refresh Visual Feedback
**File:** `/ClaudeCodeUI-iOS/Features/Chat/ChatViewController.swift`  
**Location:** Pull-to-refresh setup

**Required Changes:**
```swift
// Add UIRefreshControl
private lazy var refreshControl: UIRefreshControl = {
    let control = UIRefreshControl()
    control.tintColor = .systemPink
    control.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
    return control
}()

override func viewDidLoad() {
    super.viewDidLoad()
    tableView.refreshControl = refreshControl
}

@objc private func handleRefresh() {
    // Haptic feedback for physical devices
    if #available(iOS 13.0, *) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    // Visual feedback for simulator
    #if targetEnvironment(simulator)
    showRefreshAnimation()
    #endif
    
    // Reload messages
    loadMessages {
        self.refreshControl.endRefreshing()
    }
}
```

---

## 🟢 ENHANCEMENTS

### 6. Server Availability Detection
**File:** `/ClaudeCodeUI-iOS/Core/Network/WebSocketManager.swift`  
**Enhancement:** Add server ping to detect when server comes back online

```swift
private var serverCheckTimer: Timer?

private func startServerAvailabilityCheck() {
    serverCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
        self?.checkServerAvailability()
    }
}

private func checkServerAvailability() {
    let url = URL(string: "http://192.168.0.43:3004")!
    let task = URLSession.shared.dataTask(with: url) { [weak self] _, response, error in
        if error == nil, let httpResponse = response as? HTTPURLResponse, 
           httpResponse.statusCode == 200 {
            self?.serverCheckTimer?.invalidate()
            self?.connect(to: self?.currentURL)
        }
    }
    task.resume()
}
```

---

## Testing Checklist After Fixes

- [ ] Memory usage stays below 150MB baseline
- [ ] Exponential backoff works (1s, 2s, 4s, 8s, 16s, 32s)
- [ ] Manual retry button appears on failed messages
- [ ] Connection indicator shows clear states (green/yellow/red)
- [ ] Pull-to-refresh shows visual feedback
- [ ] App reconnects automatically when server available
- [ ] Messages retry with proper status updates
- [ ] No memory leaks during extended usage
- [ ] Haptic feedback works on physical device
- [ ] All animations are smooth (60fps)

---

## Files to Modify Summary

1. **WebSocketManager.swift** - Reconnection logic
2. **ChatViewController.swift** - UI updates, retry button, status indicator
3. **MessageTableViewCell.swift** - Add retry button UI
4. **AppDelegate.swift** - Memory warning handling
5. **SwiftDataContainer.swift** - Cache management

---

**Priority Order:**
1. Fix exponential backoff (prevents app from reconnecting)
2. Reduce memory usage (2x over target)
3. Add manual retry UI (user control)
4. Update connection status visuals (user feedback)
5. Add pull-to-refresh feedback (UX improvement)