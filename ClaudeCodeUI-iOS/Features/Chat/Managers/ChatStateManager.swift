//
//  ChatStateManager.swift
//  ClaudeCodeUI
//
//  Component 6: State management and coordination
//

import Foundation
import Combine

// MARK: - ChatStateManager

/// Manages chat state transitions and UI state coordination
final class ChatStateManager: ObservableObject {
    
    // MARK: - State
    
    enum State {
        case idle
        case loading
        case ready
        case error(Error)
        case typing
        case sending
        case receiving
    }
    
    // MARK: - Published Properties
    
    @Published private(set) var currentState: State = .idle
    @Published private(set) var isTypingIndicatorVisible = false
    @Published private(set) var isInputEnabled = true
    @Published private(set) var isRefreshing = false
    @Published private(set) var hasMoreMessages = false
    @Published private(set) var connectionState: ConnectionState = .disconnected
    
    // MARK: - Properties
    
    private var stateHistory: [State] = []
    private let maxHistorySize = 10
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Connection State
    
    enum ConnectionState {
        case connected
        case connecting
        case disconnected
        case reconnecting
    }
    
    // MARK: - Initialization
    
    init() {
        setupStateObservers()
    }
    
    // MARK: - Public Methods
    
    /// Update the current state
    func updateState(_ newState: State) {
        // Store previous state
        stateHistory.append(currentState)
        if stateHistory.count > maxHistorySize {
            stateHistory.removeFirst()
        }
        
        // Update current state
        currentState = newState
        
        // Update related UI states
        updateUIStates(for: newState)
    }
    
    /// Show typing indicator
    func showTypingIndicator() {
        isTypingIndicatorVisible = true
        updateState(.typing)
    }
    
    /// Hide typing indicator
    func hideTypingIndicator() {
        isTypingIndicatorVisible = false
        if currentState == .typing {
            updateState(.ready)
        }
    }
    
    /// Enable input
    func enableInput() {
        isInputEnabled = true
    }
    
    /// Disable input
    func disableInput() {
        isInputEnabled = false
    }
    
    /// Start refreshing
    func startRefreshing() {
        isRefreshing = true
        updateState(.loading)
    }
    
    /// Stop refreshing
    func stopRefreshing() {
        isRefreshing = false
        updateState(.ready)
    }
    
    /// Update connection state
    func updateConnectionState(_ state: ConnectionState) {
        connectionState = state
        
        switch state {
        case .connected:
            enableInput()
            updateState(.ready)
        case .connecting, .reconnecting:
            disableInput()
            updateState(.loading)
        case .disconnected:
            disableInput()
            updateState(.idle)
        }
    }
    
    /// Check if can send message
    func canSendMessage() -> Bool {
        switch currentState {
        case .ready, .idle:
            return isInputEnabled && connectionState == .connected
        default:
            return false
        }
    }
    
    /// Reset to initial state
    func reset() {
        currentState = .idle
        isTypingIndicatorVisible = false
        isInputEnabled = true
        isRefreshing = false
        hasMoreMessages = false
        connectionState = .disconnected
        stateHistory.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func setupStateObservers() {
        // Observe state changes
        $currentState
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    private func updateUIStates(for state: State) {
        switch state {
        case .idle:
            isInputEnabled = true
            isTypingIndicatorVisible = false
            
        case .loading:
            isInputEnabled = false
            isTypingIndicatorVisible = false
            
        case .ready:
            isInputEnabled = connectionState == .connected
            isTypingIndicatorVisible = false
            
        case .error:
            isInputEnabled = false
            isTypingIndicatorVisible = false
            
        case .typing:
            isInputEnabled = true
            isTypingIndicatorVisible = true
            
        case .sending:
            isInputEnabled = false
            isTypingIndicatorVisible = false
            
        case .receiving:
            isInputEnabled = true
            isTypingIndicatorVisible = true
        }
    }
    
    private func handleStateChange(_ state: State) {
        print("📊 State changed to: \(state)")
        
        // Log state transitions for debugging
        if let previousState = stateHistory.last {
            print("  Previous state: \(previousState)")
        }
    }
    
    // MARK: - State Validation
    
    /// Validate state transition
    func canTransition(from: State, to: State) -> Bool {
        // Define valid state transitions
        switch (from, to) {
        case (.idle, .loading), (.idle, .ready):
            return true
        case (.loading, .ready), (.loading, .error), (.loading, .idle):
            return true
        case (.ready, .typing), (.ready, .sending), (.ready, .loading):
            return true
        case (.typing, .ready), (.typing, .sending):
            return true
        case (.sending, .ready), (.sending, .receiving), (.sending, .error):
            return true
        case (.receiving, .ready), (.receiving, .typing):
            return true
        case (.error, .idle), (.error, .loading):
            return true
        default:
            return false
        }
    }
}

// MARK: - State Extensions

extension ChatStateManager.State: Equatable {
    static func == (lhs: ChatStateManager.State, rhs: ChatStateManager.State) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.ready, .ready),
             (.typing, .typing), (.sending, .sending), (.receiving, .receiving):
            return true
        case (.error(let e1), .error(let e2)):
            return (e1 as NSError) == (e2 as NSError)
        default:
            return false
        }
    }
}