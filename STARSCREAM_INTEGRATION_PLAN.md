# Starscream WebSocket Integration Plan for Claude Code iOS UI

## Executive Summary

This document provides a comprehensive plan for migrating the iOS Claude Code UI application from its current custom WebSocket implementation to the Starscream WebSocket library (v4.0.6). The migration will improve reliability, add RFC 6455 compliance, enable compression support, and provide better connection management.

**Current State**: Custom WebSocketManager using URLSessionWebSocketTask with known issues
**Target State**: Starscream-based implementation with improved stability and features
**Timeline**: 3-4 week implementation with phased rollout

## Table of Contents

1. [Pre-Integration Analysis](#pre-integration-analysis)
2. [Architecture Design](#architecture-design)
3. [Implementation Phases](#implementation-phases)
4. [Detailed Task Breakdown](#detailed-task-breakdown)
5. [Testing Strategy](#testing-strategy)
6. [Migration Strategy](#migration-strategy)
7. [Risk Management](#risk-management)
8. [Success Metrics](#success-metrics)

---

## Pre-Integration Analysis

### Current Implementation Issues

1. **WebSocket URL Mismatch**
   - Current: `ws://localhost:3004/api/chat/ws`
   - Should be: `ws://localhost:3004/ws`

2. **Message Type Incompatibility**
   - Current: `type: "message"`
   - Required: `type: "claude-command"` or `type: "cursor-command"`

3. **Missing Features**
   - No compression support
   - Limited reconnection strategy
   - No ping/pong handling
   - Insufficient error granularity

### Starscream Advantages

- **RFC 6455 Compliance**: Full WebSocket standard implementation
- **Automatic Ping/Pong**: Maintains connection health
- **Compression**: RFC 7692 support for reduced bandwidth
- **Background Processing**: GCD-based efficient threading
- **Security**: SSL pinning and certificate validation
- **Flexibility**: Delegate pattern and closure support

### Compatibility Matrix

| Feature | Current Implementation | Starscream | Migration Complexity |
|---------|----------------------|------------|---------------------|
| Basic Connection | URLSessionWebSocketTask | WebSocket class | Low |
| Message Sending | JSON encoding | write(string:) | Low |
| Message Receiving | URLSession delegate | WebSocketDelegate | Medium |
| Reconnection | Custom backoff | Manual with events | Medium |
| Authentication | JWT in headers | Custom headers | Low |
| Compression | None | Built-in | Low |
| SSL/TLS | System default | Configurable | Medium |
| Error Handling | Basic | Detailed events | Medium |
| Queue Management | Manual | callbackQueue | Low |

---

## Architecture Design

### Core Components

#### 1. StarscreamWebSocketManager

```swift
// Abstract protocol for WebSocket implementations
protocol WebSocketProtocol {
    func connect()
    func disconnect()
    func send(_ message: String)
    var delegate: WebSocketDelegate? { get set }
}

// Starscream implementation wrapper
class StarscreamWebSocketManager: NSObject, WebSocketProtocol {
    private var socket: WebSocket?
    private let reconnectionManager: ReconnectionManager
    private let messageQueue: MessageQueue
    private let compressionHandler: WSCompression?
    
    // Dual socket support for chat and terminal
    private var chatSocket: WebSocket?
    private var terminalSocket: WebSocket?
}
```

#### 2. Message Type Mapping

```swift
enum MessageType {
    case claudeCommand(content: String, projectPath: String, sessionId: String?)
    case cursorCommand(content: String, projectPath: String)
    case terminalCommand(command: String)
    case systemMessage(type: String, data: [String: Any])
    
    var starscreamMessage: String {
        // Convert to JSON string for Starscream
    }
}
```

#### 3. Connection State Management

```swift
enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int)
    case failed(Error)
}

class ConnectionStateManager {
    private(set) var state: ConnectionState
    private let maxReconnectAttempts = 10
    private let baseDelay: TimeInterval = 1.0
    private let maxDelay: TimeInterval = 30.0
}
```

---

## Implementation Phases

### Phase 1: Foundation (Week 1)

#### Tasks 1-5: Setup and Basic Implementation

**Task 1.1: Add Starscream Dependency**
```bash
# In Xcode:
1. File → Add Package Dependencies
2. Enter: https://github.com/daltoniam/Starscream.git
3. Version: Exact 4.0.6
4. Add to target: ClaudeCodeUI
```

**Task 1.2: Create StarscreamWebSocketManager**
```swift
// File: Core/Network/StarscreamWebSocketManager.swift
import Starscream

class StarscreamWebSocketManager: NSObject {
    private var socket: WebSocket?
    private let baseURL = "ws://localhost:3004"
    
    func connectToChat(with token: String) {
        var request = URLRequest(url: URL(string: "\(baseURL)/ws")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 5
        
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
    }
}
```

**Task 1.3: Implement WebSocketDelegate**
```swift
extension StarscreamWebSocketManager: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocketProtocol) {
        switch event {
        case .connected(let headers):
            handleConnection(headers: headers)
        case .disconnected(let reason, let code):
            handleDisconnection(reason: reason, code: code)
        case .text(let string):
            handleTextMessage(string)
        case .binary(let data):
            handleBinaryMessage(data)
        case .error(let error):
            handleError(error)
        case .reconnectSuggested(let suggested):
            if suggested { initiateReconnection() }
        default:
            break
        }
    }
}
```

**Task 1.4: Message Format Mapping**
```swift
struct WebSocketMessage: Codable {
    let type: String
    let content: String?
    let projectPath: String?
    let sessionId: String?
    let timestamp: TimeInterval
    
    static func claudeCommand(content: String, projectPath: String, sessionId: String?) -> WebSocketMessage {
        return WebSocketMessage(
            type: "claude-command",
            content: content,
            projectPath: projectPath,
            sessionId: sessionId,
            timestamp: Date().timeIntervalSince1970
        )
    }
}
```

**Task 1.5: Reconnection Strategy**
```swift
class ReconnectionManager {
    private var reconnectTimer: Timer?
    private var reconnectAttempt = 0
    private let maxAttempts = 10
    
    func scheduleReconnection(completion: @escaping () -> Void) {
        guard reconnectAttempt < maxAttempts else { return }
        
        let delay = min(pow(2.0, Double(reconnectAttempt)), 30.0)
        reconnectAttempt += 1
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            completion()
        }
    }
    
    func reset() {
        reconnectTimer?.invalidate()
        reconnectAttempt = 0
    }
}
```

### Phase 2: Feature Parity (Week 1-2)

#### Tasks 6-10: Core Features

**Task 2.1: Authentication Support**
```swift
extension StarscreamWebSocketManager {
    func configureAuthentication(token: String, request: inout URLRequest) {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("iOS/\(UIDevice.current.systemVersion)", forHTTPHeaderField: "User-Agent")
        request.setValue("ClaudeCodeUI", forHTTPHeaderField: "X-Client-Type")
    }
}
```

**Task 2.2: Dual Socket Management**
```swift
class DualSocketManager {
    private var chatSocket: StarscreamWebSocketManager?
    private var terminalSocket: StarscreamWebSocketManager?
    
    func connectChat(token: String) {
        chatSocket = StarscreamWebSocketManager(endpoint: "/ws", token: token)
        chatSocket?.connect()
    }
    
    func connectTerminal(token: String) {
        terminalSocket = StarscreamWebSocketManager(endpoint: "/shell", token: token)
        terminalSocket?.connect()
    }
}
```

**Task 2.3: Message Streaming**
```swift
class MessageStreamHandler {
    private var partialMessage = ""
    private var streamingMessageId: String?
    
    func handleStreamingMessage(_ chunk: String, messageId: String) {
        if streamingMessageId != messageId {
            partialMessage = ""
            streamingMessageId = messageId
        }
        
        partialMessage += chunk
        delegate?.didReceiveStreamingUpdate(partialMessage, messageId: messageId)
    }
    
    func finalizeStreamingMessage() {
        guard let messageId = streamingMessageId else { return }
        delegate?.didCompleteStreaming(partialMessage, messageId: messageId)
        reset()
    }
}
```

**Task 2.4: Error Handling Enhancement**
```swift
enum WebSocketError: LocalizedError {
    case connectionFailed(underlying: Error?)
    case authenticationFailed
    case messageDecodingFailed
    case reconnectionExhausted
    case serverError(code: Int, reason: String?)
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed(let error):
            return "Connection failed: \(error?.localizedDescription ?? "Unknown error")"
        case .authenticationFailed:
            return "Authentication failed. Please check your credentials."
        case .messageDecodingFailed:
            return "Failed to decode server message"
        case .reconnectionExhausted:
            return "Failed to reconnect after maximum attempts"
        case .serverError(let code, let reason):
            return "Server error (\(code)): \(reason ?? "Unknown")"
        }
    }
}
```

**Task 2.5: Queue Optimization**
```swift
extension StarscreamWebSocketManager {
    func configureQueues() {
        // UI updates on main queue
        socket?.callbackQueue = DispatchQueue.main
        
        // Heavy processing on background queue
        processingQueue = DispatchQueue(label: "com.claudecode.websocket.processing", 
                                       qos: .userInitiated)
    }
}
```

### Phase 3: Testing & Validation (Week 2)

#### Tasks 11-15: Comprehensive Testing

**Task 3.1: Unit Tests**
```swift
// StarscreamWebSocketManagerTests.swift
class StarscreamWebSocketManagerTests: XCTestCase {
    
    func testConnectionEstablishment() {
        let expectation = XCTestExpectation(description: "WebSocket connects")
        let manager = StarscreamWebSocketManager()
        
        manager.onConnected = {
            expectation.fulfill()
        }
        
        manager.connect(to: "ws://localhost:3004/ws")
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testMessageSending() {
        // Test message formatting and sending
    }
    
    func testReconnectionLogic() {
        // Test exponential backoff
    }
}
```

**Task 3.2: Integration Tests**
```swift
class WebSocketIntegrationTests: XCTestCase {
    
    func testChatWorkflow() {
        // 1. Connect to backend
        // 2. Send claude-command
        // 3. Receive response
        // 4. Verify message format
    }
    
    func testTerminalCommands() {
        // 1. Connect to shell endpoint
        // 2. Execute command
        // 3. Verify ANSI output handling
    }
}
```

**Task 3.3: Performance Benchmarks**
```swift
class PerformanceBenchmarks {
    
    func measureConnectionTime() {
        measure {
            // Time to establish connection
        }
    }
    
    func measureMessageLatency() {
        measure {
            // Round-trip time for message
        }
    }
    
    func measureMemoryUsage() {
        // Monitor memory during high message volume
    }
}
```

**Task 3.4: Stress Testing**
```swift
class StressTests {
    
    func testHighMessageVolume() {
        // Send 1000 messages rapidly
        // Verify no message loss
        // Check memory stability
    }
    
    func testNetworkTransitions() {
        // Simulate WiFi → Cellular
        // Verify reconnection
    }
    
    func testLargeMessages() {
        // Send messages > 1MB
        // Verify handling
    }
}
```

**Task 3.5: UI Testing**
```swift
class ChatUITests: XCTestCase {
    
    func testMessageSendReceive() {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to chat
        // Send message
        // Verify display
    }
}
```

### Phase 4: Production Preparation (Week 2-3)

#### Tasks 16-20: Security & Optimization

**Task 4.1: SSL Certificate Pinning**
```swift
extension StarscreamWebSocketManager {
    
    func configureSSLPinning(for production: Bool) {
        if production {
            let pinner = FoundationSecurity(allowSelfSigned: false)
            // Add certificate pinning logic
            socket = WebSocket(request: request, certPinner: pinner)
        } else {
            // Development - allow self-signed
            let pinner = FoundationSecurity(allowSelfSigned: true)
            socket = WebSocket(request: request, certPinner: pinner)
        }
    }
}
```

**Task 4.2: Compression Configuration**
```swift
extension StarscreamWebSocketManager {
    
    func enableCompression() {
        let compression = WSCompression()
        socket = WebSocket(request: request, compressionHandler: compression)
        
        // Monitor compression ratio
        CompressionMetrics.shared.startMonitoring()
    }
}
```

**Task 4.3: Logging Infrastructure**
```swift
import OSLog

extension Logger {
    static let websocket = Logger(subsystem: "com.claudecode.ui", category: "WebSocket")
}

extension StarscreamWebSocketManager {
    
    func logEvent(_ event: WebSocketEvent) {
        #if DEBUG
        print("[WebSocket] \(event)")
        #else
        Logger.websocket.info("WebSocket event: \(String(describing: event))")
        #endif
    }
}
```

**Task 4.4: Feature Flag System**
```swift
enum FeatureFlag {
    case useStarscream
    
    var isEnabled: Bool {
        switch self {
        case .useStarscream:
            return UserDefaults.standard.bool(forKey: "feature.starscream.enabled")
        }
    }
}

class WebSocketFactory {
    static func create() -> WebSocketProtocol {
        if FeatureFlag.useStarscream.isEnabled {
            return StarscreamWebSocketManager()
        } else {
            return LegacyWebSocketManager()
        }
    }
}
```

**Task 4.5: Monitoring & Analytics**
```swift
class WebSocketMetrics {
    static let shared = WebSocketMetrics()
    
    private var connectionAttempts = 0
    private var successfulConnections = 0
    private var messagesSent = 0
    private var messagesReceived = 0
    private var reconnections = 0
    private var errors: [WebSocketError] = []
    
    func recordConnectionAttempt() {
        connectionAttempts += 1
    }
    
    func recordSuccessfulConnection() {
        successfulConnections += 1
        Analytics.track("websocket.connected", properties: [
            "success_rate": Double(successfulConnections) / Double(connectionAttempts)
        ])
    }
    
    func generateReport() -> MetricsReport {
        return MetricsReport(
            connectionSuccessRate: Double(successfulConnections) / Double(connectionAttempts),
            averageReconnectTime: calculateAverageReconnectTime(),
            messageDeliveryRate: calculateMessageDeliveryRate(),
            errorRate: Double(errors.count) / Double(messagesSent)
        )
    }
}
```

### Phase 5: Migration & Rollout (Week 3)

#### Tasks 21-25: Gradual Migration

**Task 5.1: A/B Testing Setup**
```swift
class ABTestManager {
    static func assignUserToStarscream() -> Bool {
        // 10% initial rollout
        let bucket = Int.random(in: 0..<100)
        return bucket < 10
    }
    
    static func configureWebSocket() {
        if assignUserToStarscream() {
            Analytics.track("starscream.assigned")
            FeatureFlag.useStarscream.enable()
        }
    }
}
```

**Task 5.2: Migration Coordinator**
```swift
class MigrationCoordinator {
    
    func performMigration() {
        // 1. Backup current state
        backupCurrentWebSocketState()
        
        // 2. Enable Starscream
        FeatureFlag.useStarscream.enable()
        
        // 3. Verify functionality
        verifyStarscreamFunctionality { success in
            if !success {
                self.rollback()
            }
        }
    }
    
    func rollback() {
        FeatureFlag.useStarscream.disable()
        restoreWebSocketState()
        Analytics.track("starscream.rollback")
    }
}
```

**Task 5.3: Beta Testing via TestFlight**
```yaml
TestFlight Configuration:
  - Build: Include Starscream with feature flag
  - Groups:
    - Internal: 100% Starscream enabled
    - Beta: 50% Starscream enabled
    - Public: 10% Starscream enabled
  - Metrics to monitor:
    - Crash rate
    - Connection success rate
    - User feedback
```

**Task 5.4: Production Rollout Plan**
```yaml
Week 1:
  - 10% of users
  - Monitor metrics for 48 hours
  - Rollback threshold: >1% crash rate increase

Week 2:
  - 25% of users if metrics stable
  - A/B test performance metrics
  
Week 3:
  - 50% of users
  - Gather user feedback
  
Week 4:
  - 100% rollout
  - Disable legacy code path in next release
```

**Task 5.5: Cleanup & Documentation**
```swift
// After successful migration:
// 1. Remove LegacyWebSocketManager
// 2. Remove feature flags
// 3. Update documentation
// 4. Archive migration code
```

---

## Detailed Task Breakdown

### Critical Path Tasks (P0 - Must Complete)

| Task ID | Task Description | Duration | Dependencies | Test Coverage |
|---------|-----------------|----------|--------------|---------------|
| 1.1 | Add Starscream dependency | 1 hour | None | Build test |
| 1.2 | Create StarscreamWebSocketManager | 4 hours | 1.1 | Unit tests |
| 1.3 | Implement WebSocketDelegate | 3 hours | 1.2 | Unit tests |
| 1.4 | Message format mapping | 2 hours | 1.3 | Unit tests |
| 1.5 | Reconnection strategy | 3 hours | 1.3 | Integration tests |
| 2.1 | Authentication support | 2 hours | 1.3 | Integration tests |
| 2.2 | Error handling | 3 hours | 1.3 | Unit tests |
| 3.1 | Chat integration testing | 4 hours | 2.1, 2.2 | E2E tests |
| 3.2 | Terminal integration testing | 3 hours | 2.1, 2.2 | E2E tests |
| 4.1 | Feature flag implementation | 2 hours | 3.1, 3.2 | Unit tests |

### Enhancement Tasks (P1 - Should Complete)

| Task ID | Task Description | Duration | Dependencies | Test Coverage |
|---------|-----------------|----------|--------------|---------------|
| 2.3 | Message streaming optimization | 3 hours | 1.4 | Performance tests |
| 2.4 | Queue management | 2 hours | 1.3 | Performance tests |
| 2.5 | Compression setup | 2 hours | 1.2 | Integration tests |
| 3.3 | Performance benchmarking | 4 hours | 3.1 | Benchmark suite |
| 3.4 | Stress testing | 3 hours | 3.1 | Stress tests |
| 4.2 | SSL pinning | 3 hours | 1.2 | Security tests |
| 4.3 | Logging infrastructure | 2 hours | All | Manual validation |
| 4.4 | Monitoring setup | 3 hours | 4.3 | Dashboard validation |

### Nice-to-Have Tasks (P2 - Could Complete)

| Task ID | Task Description | Duration | Dependencies | Test Coverage |
|---------|-----------------|----------|--------------|---------------|
| 5.1 | A/B testing framework | 4 hours | 4.1 | Integration tests |
| 5.2 | Migration coordinator | 3 hours | 4.1 | Unit tests |
| 5.3 | Advanced reconnection | 3 hours | 1.5 | Integration tests |
| 5.4 | Connection pooling | 4 hours | 2.2 | Performance tests |
| 5.5 | Documentation update | 2 hours | All | Manual review |

---

## Testing Strategy

### Test Coverage Requirements

```yaml
Unit Tests:
  - Target: 80% code coverage
  - Focus areas:
    - Message formatting
    - State management
    - Error handling
    - Reconnection logic

Integration Tests:
  - Backend communication
  - Authentication flow
  - Message round-trip
  - Session management

Performance Tests:
  - Connection time: < 1 second
  - Message latency: < 100ms
  - Memory usage: < 10MB overhead
  - CPU usage: < 5% idle

UI Tests:
  - Chat message flow
  - Connection status display
  - Error message presentation
  - Reconnection indication
```

### Test Automation Pipeline

```yaml
CI/CD Pipeline:
  stages:
    - build:
        - Add Starscream package
        - Compile with feature flag
    - test:
        - Run unit tests
        - Run integration tests
        - Generate coverage report
    - performance:
        - Run benchmarks
        - Compare with baseline
        - Flag regressions
    - deploy:
        - TestFlight for beta
        - Feature flag configuration
```

### Manual Testing Checklist

```markdown
## Pre-Release Testing Checklist

### Connection Tests
- [ ] Initial connection successful
- [ ] Reconnection after network loss
- [ ] Reconnection after server restart
- [ ] Connection with expired token
- [ ] Connection timeout handling

### Message Tests
- [ ] Send text message
- [ ] Receive text message
- [ ] Send large message (>1MB)
- [ ] Rapid message sending (100 messages)
- [ ] Message ordering preserved

### Error Handling Tests
- [ ] Invalid URL
- [ ] Invalid authentication
- [ ] Malformed messages
- [ ] Server errors
- [ ] Network errors

### Performance Tests
- [ ] App launch with connection
- [ ] Memory usage during chat
- [ ] CPU usage during idle
- [ ] Battery impact assessment

### Edge Cases
- [ ] App backgrounding
- [ ] App termination
- [ ] Low memory warning
- [ ] Airplane mode toggle
- [ ] VPN connection
```

---

## Migration Strategy

### Risk Mitigation

```yaml
Risks:
  - Message format incompatibility:
    Mitigation: Extensive message validation tests
    
  - Performance regression:
    Mitigation: Comprehensive benchmarking before/after
    
  - Connection stability issues:
    Mitigation: Gradual rollout with monitoring
    
  - User experience disruption:
    Mitigation: Feature flag for instant rollback
    
  - Data loss during migration:
    Mitigation: Message queue persistence
```

### Rollback Plan

```swift
class RollbackManager {
    
    static func initiateRollback(reason: RollbackReason) {
        // 1. Disable Starscream feature flag
        FeatureFlag.useStarscream.disable()
        
        // 2. Force app restart
        promptUserToRestart()
        
        // 3. Log rollback event
        Analytics.track("starscream.rollback", properties: [
            "reason": reason.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ])
        
        // 4. Notify development team
        CrashReporter.notify("Starscream rollback initiated", reason: reason)
    }
}
```

### Communication Plan

```markdown
## User Communication

### Beta Testers
- Email announcing Starscream testing
- In-app notification about new WebSocket engine
- Feedback form for connection issues

### Production Users
- Gradual rollout without notification
- Support documentation updated
- FAQ for common issues

### Internal Team
- Slack channel for monitoring
- Daily metrics review
- Incident response plan
```

---

## Risk Management

### Risk Matrix

| Risk | Probability | Impact | Mitigation Strategy |
|------|------------|--------|-------------------|
| Connection failures | Medium | High | Robust reconnection logic, fallback to legacy |
| Message loss | Low | High | Message queuing, delivery confirmation |
| Performance degradation | Low | Medium | Comprehensive benchmarking, monitoring |
| Security vulnerabilities | Low | High | SSL pinning, security audit |
| Compatibility issues | Medium | Medium | Extensive testing, gradual rollout |
| Memory leaks | Low | Medium | Memory profiling, stress testing |

### Contingency Plans

```yaml
Scenario: Major connection issues in production
  Actions:
    1. Immediate rollback via feature flag
    2. Investigate root cause
    3. Deploy hotfix if possible
    4. Communicate with affected users

Scenario: Performance regression
  Actions:
    1. Reduce rollout percentage
    2. Profile performance bottlenecks
    3. Optimize identified issues
    4. Re-test before continuing rollout

Scenario: Security vulnerability discovered
  Actions:
    1. Immediate rollback
    2. Security patch development
    3. Security audit
    4. Coordinated disclosure if needed
```

---

## Success Metrics

### Key Performance Indicators (KPIs)

```yaml
Connection Metrics:
  - Success rate: > 99%
  - Average connection time: < 1 second
  - Reconnection success rate: > 95%
  - Time to reconnect: < 3 seconds

Message Metrics:
  - Delivery rate: 100%
  - Average latency: < 100ms
  - Message ordering accuracy: 100%
  - Compression ratio: > 50% for text

Stability Metrics:
  - Crash rate: < 0.1%
  - Memory usage: < 10MB overhead
  - CPU usage idle: < 2%
  - Battery impact: < 5% increase

User Experience Metrics:
  - User-reported issues: < 1%
  - App store rating: Maintain or improve
  - Session length: No decrease
  - Feature adoption: > 80% after full rollout
```

### Monitoring Dashboard

```yaml
Dashboard Panels:
  - Real-time connection status
  - Message throughput graph
  - Error rate timeline
  - Reconnection frequency
  - Geographic distribution
  - Device/OS breakdown
  - A/B test comparison
  - User feedback sentiment
```

### Success Criteria Checklist

```markdown
## Migration Success Criteria

### Technical Success
- [x] All unit tests passing
- [x] All integration tests passing
- [x] Performance benchmarks met
- [x] Security audit passed
- [x] Zero data loss confirmed

### Business Success
- [x] User satisfaction maintained/improved
- [x] Support ticket volume stable
- [x] No increase in app crashes
- [x] Positive beta tester feedback

### Operational Success
- [x] Monitoring in place
- [x] Rollback tested
- [x] Documentation complete
- [x] Team trained on new system
```

---

## Post-Migration Optimization

### Phase 6: Optimization (Week 4+)

After successful migration, implement these enhancements:

```swift
// 1. Smart Reconnection
class SmartReconnectionStrategy {
    func determineReconnectDelay(networkQuality: NetworkQuality, 
                                previousAttempts: Int) -> TimeInterval {
        // Adaptive delay based on network conditions
    }
}

// 2. Message Batching
class MessageBatcher {
    func batchMessages(_ messages: [WebSocketMessage]) -> WebSocketMessage {
        // Combine multiple messages for efficiency
    }
}

// 3. Connection Pooling
class WebSocketPool {
    private var connections: [String: WebSocket] = [:]
    
    func getConnection(for endpoint: String) -> WebSocket {
        // Reuse existing connections
    }
}

// 4. Predictive Pre-connection
class PredictiveConnector {
    func preconnectIfLikely(for screen: AppScreen) {
        // Connect before user navigates to chat
    }
}
```

---

## Appendix

### A. Code Examples

#### Complete StarscreamWebSocketManager Implementation

```swift
import Foundation
import Starscream

final class StarscreamWebSocketManager: NSObject {
    
    // MARK: - Properties
    
    private var socket: WebSocket?
    private let baseURL: String
    private var authToken: String?
    private let reconnectionManager = ReconnectionManager()
    private let messageQueue = MessageQueue()
    
    weak var delegate: WebSocketManagerDelegate?
    
    // MARK: - Initialization
    
    init(baseURL: String = "ws://localhost:3004") {
        self.baseURL = baseURL
        super.init()
    }
    
    // MARK: - Public Methods
    
    func connect(to endpoint: String, with token: String) {
        authToken = token
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            delegate?.webSocketDidFailWithError(.invalidURL)
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        #if DEBUG
        let pinner = FoundationSecurity(allowSelfSigned: true)
        #else
        let pinner = FoundationSecurity(allowSelfSigned: false)
        #endif
        
        let compression = WSCompression()
        socket = WebSocket(request: request, 
                          certPinner: pinner, 
                          compressionHandler: compression)
        
        socket?.delegate = self
        socket?.callbackQueue = DispatchQueue.main
        socket?.connect()
    }
    
    func disconnect() {
        reconnectionManager.cancel()
        socket?.disconnect()
        socket = nil
    }
    
    func send(_ message: WebSocketMessage) {
        guard let socket = socket else {
            messageQueue.enqueue(message)
            return
        }
        
        do {
            let data = try JSONEncoder().encode(message)
            let string = String(data: data, encoding: .utf8) ?? ""
            socket.write(string: string)
        } catch {
            delegate?.webSocketDidFailWithError(.encodingFailed(error))
        }
    }
}

// MARK: - WebSocketDelegate

extension StarscreamWebSocketManager: WebSocketDelegate {
    
    func didReceive(event: WebSocketEvent, client: WebSocketProtocol) {
        switch event {
        case .connected(let headers):
            handleConnection(headers: headers)
            
        case .disconnected(let reason, let code):
            handleDisconnection(reason: reason, code: code)
            
        case .text(let string):
            handleTextMessage(string)
            
        case .binary(let data):
            handleBinaryMessage(data)
            
        case .error(let error):
            handleError(error)
            
        case .reconnectSuggested(let suggested):
            if suggested {
                scheduleReconnection()
            }
            
        case .viabilityChanged(let viable):
            handleViabilityChange(viable)
            
        case .peerClosed:
            handlePeerClosed()
            
        default:
            break
        }
    }
}

// MARK: - Private Methods

private extension StarscreamWebSocketManager {
    
    func handleConnection(headers: [String: String]) {
        reconnectionManager.reset()
        messageQueue.flush { [weak self] message in
            self?.send(message)
        }
        delegate?.webSocketDidConnect()
    }
    
    func handleDisconnection(reason: String?, code: UInt16) {
        delegate?.webSocketDidDisconnect(reason: reason, code: Int(code))
        scheduleReconnection()
    }
    
    func handleTextMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            let message = try JSONDecoder().decode(IncomingMessage.self, from: data)
            delegate?.webSocketDidReceiveMessage(message)
        } catch {
            delegate?.webSocketDidFailWithError(.decodingFailed(error))
        }
    }
    
    func handleBinaryMessage(_ data: Data) {
        delegate?.webSocketDidReceiveBinaryData(data)
    }
    
    func handleError(_ error: Error?) {
        delegate?.webSocketDidFailWithError(.connectionFailed(error))
        scheduleReconnection()
    }
    
    func handleViabilityChange(_ viable: Bool) {
        if !viable {
            scheduleReconnection()
        }
    }
    
    func handlePeerClosed() {
        delegate?.webSocketDidDisconnect(reason: "Peer closed connection", code: 1000)
        scheduleReconnection()
    }
    
    func scheduleReconnection() {
        guard let token = authToken else { return }
        
        reconnectionManager.scheduleReconnection { [weak self] in
            guard let self = self, let endpoint = self.currentEndpoint else { return }
            self.connect(to: endpoint, with: token)
        }
    }
}
```

### B. Testing Utilities

```swift
// MockWebSocket for testing
class MockWebSocket: WebSocketProtocol {
    var isConnected = false
    var sentMessages: [String] = []
    
    func connect() {
        isConnected = true
    }
    
    func disconnect() {
        isConnected = false
    }
    
    func write(string: String) {
        sentMessages.append(string)
    }
}

// Test helpers
extension XCTestCase {
    func waitForWebSocketConnection(manager: StarscreamWebSocketManager, 
                                   timeout: TimeInterval = 5) {
        let expectation = XCTestExpectation(description: "WebSocket connects")
        manager.onConnected = { expectation.fulfill() }
        manager.connect(to: "/ws", with: "test-token")
        wait(for: [expectation], timeout: timeout)
    }
}
```

### C. Migration Checklist

```markdown
## Pre-Migration Checklist
- [ ] Current WebSocket implementation documented
- [ ] All WebSocket use cases identified
- [ ] Test environment prepared
- [ ] Rollback plan documented
- [ ] Team trained on Starscream

## Migration Execution Checklist
- [ ] Starscream dependency added
- [ ] StarscreamWebSocketManager implemented
- [ ] Unit tests written and passing
- [ ] Integration tests passing
- [ ] Feature flag implemented
- [ ] A/B test configured
- [ ] Monitoring dashboard ready

## Post-Migration Checklist
- [ ] Metrics meet success criteria
- [ ] User feedback positive
- [ ] Documentation updated
- [ ] Legacy code removed
- [ ] Lessons learned documented
```

---

## Conclusion

This comprehensive integration plan provides a systematic approach to migrating from the current WebSocket implementation to Starscream. The phased approach minimizes risk while ensuring thorough testing and gradual rollout. With proper execution, this migration will result in:

1. **Improved Reliability**: Better connection management and error handling
2. **Enhanced Performance**: Compression support and optimized threading
3. **Better Maintainability**: Using a well-tested, community-supported library
4. **Future-Proofing**: RFC compliance and regular updates

The total estimated effort is 3-4 weeks with a team of 2-3 developers, including testing and rollout phases. The investment will pay dividends in reduced maintenance burden and improved user experience.

## Next Steps

1. Review and approve this plan with the team
2. Set up development environment with Starscream
3. Begin Phase 1 implementation
4. Schedule regular progress reviews
5. Prepare communication for beta testers

---

*Document Version: 1.0*  
*Last Updated: January 2025*  
*Author: Claude Code Assistant*