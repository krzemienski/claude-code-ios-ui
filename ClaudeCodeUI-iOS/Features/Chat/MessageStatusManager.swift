//
//  MessageStatusManager.swift
//  ClaudeCodeUI
//
//  Created by Context Manager on 2025-01-21.
//  Implements CM-Chat-01: Real-time message status indicators
//

import Foundation
import UIKit

/// Manages message status tracking and updates with real-time indicators
class MessageStatusManager {
    
    // MARK: - Properties
    
    private var statusTimers: [String: Timer] = [:]
    private var statusTransitions: [String: [MessageStatus]] = [:]
    private let statusQueue = DispatchQueue(label: "com.claudecode.messageStatus", qos: .userInteractive)
    
    // Status transition delays
    private let sendingToSentDelay: TimeInterval = 0.5
    private let sentToDeliveredDelay: TimeInterval = 1.5
    private let timeoutDelay: TimeInterval = 30.0
    
    // MARK: - Singleton
    
    static let shared = MessageStatusManager()
    
    private init() {}
    
    // MARK: - Status Management
    
    /// Track a new message with initial sending status
    func trackMessage(_ messageId: String, initialStatus: MessageStatus = .sending) {
        statusQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Clear any existing timer
            self.cancelTimer(for: messageId)
            
            // Track status transitions
            self.statusTransitions[messageId] = [initialStatus]
            
            // Start status progression timer
            if initialStatus == .sending {
                self.startStatusProgression(for: messageId)
            }
            
            print("📊 [StatusManager] Tracking message \(messageId) with status: \(initialStatus)")
        }
    }
    
    /// Update message status with animation support
    func updateStatus(for messageId: String, to newStatus: MessageStatus, completion: ((Bool) -> Void)? = nil) {
        statusQueue.async { [weak self] in
            guard let self = self else { 
                DispatchQueue.main.async {
                    completion?(false)
                }
                return 
            }
            
            // Get current status
            let currentStatus = self.statusTransitions[messageId]?.last ?? .sending
            
            // Validate transition
            guard self.isValidTransition(from: currentStatus, to: newStatus) else {
                print("⚠️ [StatusManager] Invalid transition from \(currentStatus) to \(newStatus)")
                DispatchQueue.main.async {
                    completion?(false)
                }
                return
            }
            
            // Record transition
            if self.statusTransitions[messageId] != nil {
                self.statusTransitions[messageId]?.append(newStatus)
            } else {
                self.statusTransitions[messageId] = [newStatus]
            }
            
            // Cancel timer if status is terminal
            if newStatus == .delivered || newStatus == .failed || newStatus == .read {
                self.cancelTimer(for: messageId)
            }
            
            print("✅ [StatusManager] Updated \(messageId) from \(currentStatus) to \(newStatus)")
            
            DispatchQueue.main.async {
                completion?(true)
            }
        }
    }
    
    /// Get current status for a message
    func currentStatus(for messageId: String) -> MessageStatus {
        return statusQueue.sync {
            return statusTransitions[messageId]?.last ?? .sending
        }
    }
    
    /// Mark message as delivered when response received
    func markAsDelivered(_ messageId: String) {
        updateStatus(for: messageId, to: .delivered) { success in
            if success {
                print("✅ [StatusManager] Message \(messageId) marked as delivered")
            }
        }
    }
    
    /// Mark message as failed
    func markAsFailed(_ messageId: String, error: Error? = nil) {
        updateStatus(for: messageId, to: .failed) { success in
            if success {
                let errorMessage = error?.localizedDescription ?? "Unknown error"
                print("❌ [StatusManager] Message \(messageId) failed: \(errorMessage)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func startStatusProgression(for messageId: String) {
        // Progress from sending → sent → (wait for response)
        let timer = Timer.scheduledTimer(withTimeInterval: sendingToSentDelay, repeats: false) { [weak self] _ in
            self?.updateStatus(for: messageId, to: .sent) { _ in
                // Set timeout for delivery
                self?.startDeliveryTimeout(for: messageId)
            }
        }
        
        statusTimers[messageId] = timer
    }
    
    private func startDeliveryTimeout(for messageId: String) {
        let timer = Timer.scheduledTimer(withTimeInterval: timeoutDelay, repeats: false) { [weak self] _ in
            self?.markAsFailed(messageId, error: NSError(domain: "MessageTimeout", code: -1, 
                                                         userInfo: [NSLocalizedDescriptionKey: "Message delivery timeout"]))
        }
        
        statusTimers[messageId] = timer
    }
    
    private func cancelTimer(for messageId: String) {
        statusTimers[messageId]?.invalidate()
        statusTimers[messageId] = nil
    }
    
    private func isValidTransition(from: MessageStatus, to: MessageStatus) -> Bool {
        switch (from, to) {
        case (.sending, .sent),
             (.sending, .failed),
             (.sent, .delivered),
             (.sent, .failed),
             (.delivered, .read),
             (_, .failed):  // Can always transition to failed
            return true
        default:
            return false
        }
    }
    
    /// Clean up old message tracking data
    func cleanup(olderThan date: Date) {
        statusQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Clean up completed messages older than date
            let messagesToRemove = self.statusTransitions.compactMap { (messageId, transitions) -> String? in
                guard let lastStatus = transitions.last,
                      lastStatus == .delivered || lastStatus == .failed || lastStatus == .read else {
                    return nil
                }
                return messageId
            }
            
            for messageId in messagesToRemove {
                self.statusTransitions.removeValue(forKey: messageId)
                self.cancelTimer(for: messageId)
            }
            
            print("🧹 [StatusManager] Cleaned up \(messagesToRemove.count) old messages")
        }
    }
}

// MARK: - Status Icon Helper

extension MessageStatus {
    var icon: String {
        switch self {
        case .sending:
            return "⏳"
        case .sent:
            return "✓"
        case .delivered:
            return "✓✓"
        case .read:
            return "👁"
        case .failed:
            return "❌"
        }
    }
    
    var color: UIColor {
        switch self {
        case .sending:
            return .systemGray
        case .sent:
            return CyberpunkTheme.primaryCyan.withAlphaComponent(0.6)
        case .delivered:
            return CyberpunkTheme.primaryCyan
        case .read:
            return CyberpunkTheme.success
        case .failed:
            return CyberpunkTheme.accentPink
        }
    }
}