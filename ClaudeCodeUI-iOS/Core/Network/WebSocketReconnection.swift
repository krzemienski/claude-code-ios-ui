//
//  WebSocketReconnection.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025/01/05.
//

import Foundation
import Combine

/// Advanced WebSocket reconnection manager with exponential backoff
class WebSocketReconnectionManager {
    
    // MARK: - Properties
    private let webSocketManager: WebSocketManager
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 10
    private var baseDelay: TimeInterval = 1.0
    private let maxDelay: TimeInterval = 60.0
    private let jitterRange: ClosedRange<Double> = 0.8...1.2
    
    private var cancellables = Set<AnyCancellable>()
    private let reconnectSubject = PassthroughSubject<ReconnectStatus, Never>()
    
    var reconnectStatusPublisher: AnyPublisher<ReconnectStatus, Never> {
        reconnectSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Reconnect Status
    enum ReconnectStatus {
        case attempting(attempt: Int, delay: TimeInterval)
        case connected
        case failed(error: Error)
        case maxAttemptsReached
    }
    
    // MARK: - Initialization
    init(webSocketManager: WebSocketManager) {
        self.webSocketManager = webSocketManager
        observeConnectionStatus()
    }
    
    // MARK: - Connection Observation
    private func observeConnectionStatus() {
        webSocketManager.connectionStatePublisher
            .sink { [weak self] state in
                switch state {
                case .disconnected:
                    self?.handleDisconnection()
                case .connected:
                    self?.handleSuccessfulConnection()
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Reconnection Logic
    private func handleDisconnection() {
        guard reconnectAttempts < maxReconnectAttempts else {
            reconnectSubject.send(.maxAttemptsReached)
            Logger.shared.error("Max reconnection attempts reached")
            return
        }
        
        scheduleReconnect()
    }
    
    private func handleSuccessfulConnection() {
        reconnectAttempts = 0
        baseDelay = 1.0
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        reconnectSubject.send(.connected)
        Logger.shared.info("WebSocket reconnected successfully")
    }
    
    private func scheduleReconnect() {
        reconnectAttempts += 1
        
        // Calculate delay with exponential backoff and jitter
        let exponentialDelay = min(baseDelay * pow(2, Double(reconnectAttempts - 1)), maxDelay)
        let jitter = Double.random(in: jitterRange)
        let finalDelay = exponentialDelay * jitter
        
        reconnectSubject.send(.attempting(attempt: reconnectAttempts, delay: finalDelay))
        Logger.shared.info("Scheduling reconnect attempt \(reconnectAttempts) in \(finalDelay) seconds")
        
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: finalDelay, repeats: false) { [weak self] _ in
            self?.attemptReconnect()
        }
    }
    
    private func attemptReconnect() {
        Logger.shared.info("Attempting WebSocket reconnection (attempt \(reconnectAttempts))")
        webSocketManager.connect()
    }
    
    // MARK: - Manual Control
    func resetReconnection() {
        reconnectAttempts = 0
        baseDelay = 1.0
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    func forceReconnect() {
        resetReconnection()
        attemptReconnect()
    }
    
    deinit {
        reconnectTimer?.invalidate()
    }
}

// MARK: - Network Reachability Monitor
import Network

class NetworkReachabilityMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.claudecodeui.networkmonitor")
    private let reachabilitySubject = CurrentValueSubject<Bool, Never>(true)
    
    var isReachablePublisher: AnyPublisher<Bool, Never> {
        reachabilitySubject.eraseToAnyPublisher()
    }
    
    var isReachable: Bool {
        reachabilitySubject.value
    }
    
    init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            let isReachable = path.status == .satisfied
            self?.reachabilitySubject.send(isReachable)
            
            if isReachable {
                Logger.shared.info("Network is reachable via \(path.availableInterfaces)")
            } else {
                Logger.shared.warning("Network is not reachable")
            }
        }
        
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - Enhanced WebSocket Manager Extension
extension WebSocketManager {
    private static var reconnectionManagerKey: UInt8 = 0
    private static var reachabilityMonitorKey: UInt8 = 0
    
    var reconnectionManager: WebSocketReconnectionManager {
        get {
            if let manager = objc_getAssociatedObject(self, &Self.reconnectionManagerKey) as? WebSocketReconnectionManager {
                return manager
            }
            let manager = WebSocketReconnectionManager(webSocketManager: self)
            objc_setAssociatedObject(self, &Self.reconnectionManagerKey, manager, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return manager
        }
    }
    
    var reachabilityMonitor: NetworkReachabilityMonitor {
        get {
            if let monitor = objc_getAssociatedObject(self, &Self.reachabilityMonitorKey) as? NetworkReachabilityMonitor {
                return monitor
            }
            let monitor = NetworkReachabilityMonitor()
            objc_setAssociatedObject(self, &Self.reachabilityMonitorKey, monitor, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            setupReachabilityObserver(monitor)
            return monitor
        }
    }
    
    private func setupReachabilityObserver(_ monitor: NetworkReachabilityMonitor) {
        var cancellable: AnyCancellable?
        cancellable = monitor.isReachablePublisher
            .removeDuplicates()
            .sink { [weak self] isReachable in
                if isReachable && self?.connectionState == .disconnected {
                    Logger.shared.info("Network became reachable, attempting reconnection")
                    self?.reconnectionManager.forceReconnect()
                }
            }
        
        // Store the cancellable
        objc_setAssociatedObject(self, "reachabilityObserver", cancellable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    /// Enable smart reconnection with network monitoring
    func enableSmartReconnection() {
        _ = reconnectionManager // Initialize if needed
        _ = reachabilityMonitor // Initialize if needed
        Logger.shared.info("Smart reconnection enabled with network monitoring")
    }
}