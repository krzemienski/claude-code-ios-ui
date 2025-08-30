# Known Issues and TODOs - Claude Code iOS UI

## Critical Issues from ChatViewController

### P0 - CRITICAL Issues

1. **CM-CHAT-01**: Message Status State Machine
   - Status stuck on 'sending', never updates to 'delivered' or 'read'
   - Need to track messageId and update on WebSocket response
   - Implementation: Use messageStatusTimers dict, update on WS response

2. **CM-CHAT-03**: Message Persistence with SwiftData
   - Messages not saved, lost on app restart
   - Need MessageEntity SwiftData model
   - Save messages on receive/send, load in viewDidLoad
   - Limit to last 100 messages for memory optimization

3. **CM-CHAT-05**: Connection Status UI
   - Connection status view not reflecting WebSocket state
   - Should show "Connecting...", "Connected", "Disconnected", "Reconnecting..."
   - Listen to WebSocketManagerDelegate callbacks

## Git Status Issues

### Modified Files Needing Review
- `.claude-flow/metrics/` - Performance metrics tracking
- `Core/Data/SwiftDataContainer.swift` - Data persistence layer
- `Core/Network/StarscreamWebSocketManager.swift` - WebSocket implementation
- `Core/Services/AuthenticationManager.swift` - Auth handling
- Chat feature files extensively modified

### Deleted Files (may need restoration)
- ChatInputHandler.swift (original)
- ChatTableViewHandler.swift (original)
- ChatWebSocketCoordinator.swift
- ChatViewModel.swift (original)
- Various test files marked for deletion

### Untracked Files
- Multiple disabled files (.disabled extension)
- New directories: App/Resources/, Derived/, Scripts/, UIComponents/
- Documentation files in docs/
- Build and test result logs

## Architecture Concerns

1. **Component Integration**
   - ChatComponentsIntegrator needs proper initialization
   - 9 refactored components need coordination
   - Potential circular dependencies

2. **Memory Management**
   - Message limit of 100 in memory
   - Batch loading of 50 messages
   - Need proper cleanup on dealloc

3. **WebSocket Reliability**
   - Reconnection logic needs testing
   - Message queue for offline support
   - Status synchronization issues

4. **Testing Coverage**
   - Many test files disabled or deleted
   - Need to restore and update test suite
   - UI test scenarios defined but not implemented

## Performance Optimizations Needed

1. **Scroll Performance**
   - Target 60 FPS with 100+ messages
   - Memory usage under 100MB
   - Implement message cell recycling

2. **Large Data Sets**
   - Initial load under 3 seconds
   - Pagination for 1000+ sessions
   - Search optimization

3. **Network Efficiency**
   - Message batching
   - Delta updates for streaming
   - Compression support