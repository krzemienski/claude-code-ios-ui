//
//  HapticFeedback.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-16.
//  Centralized haptic feedback manager for consistent user experience
//

import UIKit
import CoreHaptics

// MARK: - Haptic Feedback Manager

final class HapticFeedback {
    
    // Singleton instance
    static let shared = HapticFeedback()
    
    // Core Haptics engine for advanced haptics
    private var hapticEngine: CHHapticEngine?
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    private init() {
        setupHapticEngine()
        prepareGenerators()
    }
    
    // MARK: - Setup
    
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            
            // Handle engine reset
            hapticEngine?.resetHandler = { [weak self] in
                do {
                    try self?.hapticEngine?.start()
                } catch {
                    print("Failed to restart haptic engine: \(error)")
                }
            }
            
            // Handle engine stopped
            hapticEngine?.stoppedHandler = { reason in
                print("Haptic engine stopped: \(reason)")
            }
        } catch {
            print("Failed to create haptic engine: \(error)")
        }
    }
    
    private func prepareGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }
    
    // MARK: - Impact Feedback
    
    enum ImpactStyle {
        case light
        case medium
        case heavy
        case soft // Custom soft impact
        case rigid // Custom rigid impact
    }
    
    func impact(_ style: ImpactStyle) {
        switch style {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.impactOccurred()
        case .soft:
            impactLight.impactOccurred(intensity: 0.5)
        case .rigid:
            impactHeavy.impactOccurred(intensity: 0.8)
        }
    }
    
    // MARK: - Selection Feedback
    
    func selection() {
        selectionFeedback.selectionChanged()
    }
    
    // MARK: - Notification Feedback
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationFeedback.notificationOccurred(type)
    }
    
    // MARK: - Custom Haptic Patterns
    
    func playCustomPattern(_ pattern: HapticPattern) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = hapticEngine else { return }
        
        do {
            let pattern = try createHapticPattern(pattern)
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play custom haptic: \(error)")
        }
    }
    
    private func createHapticPattern(_ pattern: HapticPattern) throws -> CHHapticPattern {
        var events: [CHHapticEvent] = []
        
        switch pattern {
        case .success:
            // Quick double tap for success
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0
            ))
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                ],
                relativeTime: 0.1
            ))
            
        case .error:
            // Strong buzz for error
            events.append(CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0,
                duration: 0.3
            ))
            
        case .warning:
            // Three quick taps for warning
            for i in 0..<3 {
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ],
                    relativeTime: Double(i) * 0.15
                ))
            }
            
        case .heartbeat:
            // Double tap like heartbeat
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0
            ))
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0.15
            ))
            
        case .bounce:
            // Bouncing effect
            let intensities: [Float] = [1.0, 0.6, 0.3, 0.1]
            for (index, intensity) in intensities.enumerated() {
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: Double(index) * 0.2
                ))
            }
        }
        
        return try CHHapticPattern(events: events, parameters: [])
    }
    
    // MARK: - Context-Specific Haptics
    
    func buttonTap() {
        impact(.light)
    }
    
    func toggleSwitch() {
        impact(.medium)
    }
    
    func sliderChange() {
        selection()
    }
    
    func refreshPull() {
        impact(.medium)
    }
    
    func refreshRelease() {
        playCustomPattern(.bounce)
    }
    
    func messageReceived() {
        impact(.light)
    }
    
    func messageSent() {
        playCustomPattern(.success)
    }
    
    func error() {
        notification(.error)
        playCustomPattern(.error)
    }
    
    func success() {
        notification(.success)
        playCustomPattern(.success)
    }
    
    func warning() {
        // UINotificationFeedbackGenerator doesn't have .warning, using custom pattern only
        playCustomPattern(.warning)
    }
    
    func longPressStarted() {
        impact(.heavy)
    }
    
    func dragStarted() {
        impact(.light)
    }
    
    func dragEnded() {
        impact(.medium)
    }
    
    func swipeAction() {
        impact(.light)
    }
}

// MARK: - Haptic Pattern Enum

enum HapticPattern {
    case success
    case error
    case warning
    case heartbeat
    case bounce
}

// MARK: - UIView Extension for Haptic Feedback

extension UIView {
    
    func addHapticFeedback(style: HapticFeedback.ImpactStyle = .light) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleHapticTap))
        tapGesture.cancelsTouchesInView = false
        self.addGestureRecognizer(tapGesture)
        self.tag = style.rawValue
    }
    
    @objc private func handleHapticTap() {
        if let style = HapticFeedback.ImpactStyle(rawValue: self.tag) {
            HapticFeedback.shared.impact(style)
        }
    }
}

extension HapticFeedback.ImpactStyle {
    var rawValue: Int {
        switch self {
        case .light: return 1000
        case .medium: return 1001
        case .heavy: return 1002
        case .soft: return 1003
        case .rigid: return 1004
        }
    }
    
    init?(rawValue: Int) {
        switch rawValue {
        case 1000: self = .light
        case 1001: self = .medium
        case 1002: self = .heavy
        case 1003: self = .soft
        case 1004: self = .rigid
        default: return nil
        }
    }
}

// MARK: - SwiftUI Haptic Modifier

import SwiftUI

struct HapticModifier: ViewModifier {
    let style: HapticFeedback.ImpactStyle
    let trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .onChange(of: trigger) { _ in
                HapticFeedback.shared.impact(style)
            }
    }
}

extension View {
    func hapticFeedback(_ style: HapticFeedback.ImpactStyle = .light, trigger: Bool) -> some View {
        modifier(HapticModifier(style: style, trigger: trigger))
    }
}

// MARK: - Haptic Button Style

struct HapticButtonStyle: ButtonStyle {
    let hapticStyle: HapticFeedback.ImpactStyle
    
    init(hapticStyle: HapticFeedback.ImpactStyle = .light) {
        self.hapticStyle = hapticStyle
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .onChange(of: configuration.isPressed) { pressed in
                if pressed {
                    HapticFeedback.shared.impact(hapticStyle)
                }
            }
    }
}