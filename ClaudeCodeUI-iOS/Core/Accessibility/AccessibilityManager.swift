//
//  AccessibilityManager.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025/01/05.
//

import UIKit

/// Comprehensive accessibility manager for Claude Code UI
class AccessibilityManager {
    
    // MARK: - Singleton
    static let shared = AccessibilityManager()
    
    // MARK: - Properties
    private var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }
    
    private var isReduceMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    private var isDarkerSystemColorsEnabled: Bool {
        UIAccessibility.isDarkerSystemColorsEnabled
    }
    
    // MARK: - Initialization
    private init() {
        setupNotifications()
    }
    
    // MARK: - Setup
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(voiceOverStatusChanged),
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reduceMotionStatusChanged),
            name: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil
        )
    }
    
    // MARK: - Notification Handlers
    @objc private func voiceOverStatusChanged() {
        Logger.shared.info("VoiceOver status changed: \(isVoiceOverRunning)")
        updateAccessibilitySettings()
    }
    
    @objc private func reduceMotionStatusChanged() {
        Logger.shared.info("Reduce Motion status changed: \(isReduceMotionEnabled)")
        updateAnimationSettings()
    }
    
    // MARK: - Configuration
    private func updateAccessibilitySettings() {
        if isVoiceOverRunning {
            // Enhance contrast for VoiceOver users
            UIView.appearance().tintColor = CyberpunkTheme.primaryCyan
        }
    }
    
    private func updateAnimationSettings() {
        if isReduceMotionEnabled {
            // Disable complex animations
            UIView.setAnimationsEnabled(false)
            CATransaction.setDisableActions(true)
        } else {
            UIView.setAnimationsEnabled(true)
            CATransaction.setDisableActions(false)
        }
    }
    
    // MARK: - Public Methods
    
    /// Configure accessibility for a view
    func configureAccessibility(for view: UIView, label: String? = nil, hint: String? = nil, traits: UIAccessibilityTraits = .none) {
        view.isAccessibilityElement = true
        view.accessibilityLabel = label
        view.accessibilityHint = hint
        view.accessibilityTraits = traits
    }
    
    /// Configure accessibility for a button
    func configureButton(_ button: UIButton, label: String, hint: String? = nil) {
        button.isAccessibilityElement = true
        button.accessibilityLabel = label
        button.accessibilityHint = hint
        button.accessibilityTraits = .button
    }
    
    /// Configure accessibility for a text field
    func configureTextField(_ textField: UITextField, label: String, placeholder: String? = nil) {
        textField.isAccessibilityElement = true
        textField.accessibilityLabel = label
        textField.accessibilityHint = placeholder
        textField.accessibilityTraits = .searchField
    }
    
    /// Announce a message to VoiceOver
    func announce(_ message: String, delay: TimeInterval = 0.1) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
    
    /// Focus on a specific element
    func focus(on element: Any?) {
        UIAccessibility.post(notification: .screenChanged, argument: element)
    }
    
    /// Check if animations should be reduced
    func shouldReduceAnimations() -> Bool {
        return isReduceMotionEnabled
    }
}

// MARK: - UIView Extension
extension UIView {
    
    /// Apply Claude Code accessibility settings
    func applyClaudeCodeAccessibility(label: String? = nil, hint: String? = nil, traits: UIAccessibilityTraits = .none) {
        AccessibilityManager.shared.configureAccessibility(for: self, label: label, hint: hint, traits: traits)
    }
    
    /// Add accessibility action
    func addAccessibilityAction(name: String, handler: @escaping () -> Bool) {
        let action = UIAccessibilityCustomAction(name: name) { _ in
            return handler()
        }
        
        if var existingActions = self.accessibilityCustomActions {
            existingActions.append(action)
            self.accessibilityCustomActions = existingActions
        } else {
            self.accessibilityCustomActions = [action]
        }
    }
}

// MARK: - Accessibility Helpers
struct AccessibilityIdentifiers {
    // Projects
    static let projectsCollectionView = "projects.collection"
    static let projectCard = "project.card"
    static let createProjectButton = "project.create"
    
    // Chat
    static let chatMessageList = "chat.messages"
    static let chatInputField = "chat.input"
    static let chatSendButton = "chat.send"
    static let chatFileButton = "chat.file"
    static let chatTerminalButton = "chat.terminal"
    
    // File Explorer
    static let fileTree = "files.tree"
    static let filePreview = "files.preview"
    static let fileSearchField = "files.search"
    
    // Terminal
    static let terminalOutput = "terminal.output"
    static let terminalInput = "terminal.input"
    static let terminalHistoryButton = "terminal.history"
    
    // Settings
    static let settingsTable = "settings.table"
    static let settingsThemeToggle = "settings.theme"
    static let settingsBackendURL = "settings.backend"
}

// MARK: - Accessibility Announcements
extension AccessibilityManager {
    
    func announceProjectLoaded(_ projectName: String) {
        announce("Loaded project: \(projectName)")
    }
    
    func announceMessageReceived() {
        announce("New message from Claude")
    }
    
    func announceFileOpened(_ fileName: String) {
        announce("Opened file: \(fileName)")
    }
    
    func announceCommandExecuted(_ command: String) {
        announce("Executed command: \(command)")
    }
    
    func announceError(_ error: String) {
        announce("Error: \(error)")
    }
    
    func announceSuccess(_ message: String) {
        announce("Success: \(message)")
    }
}

// MARK: - Dynamic Type Support
extension UIFont {
    
    /// Get Claude Code font with dynamic type support
    static func claudeCodeFont(style: UIFont.TextStyle, weight: UIFont.Weight = .regular) -> UIFont {
        let metrics = UIFontMetrics(forTextStyle: style)
        let baseSize: CGFloat
        
        switch style {
        case .largeTitle:
            baseSize = 34
        case .title1:
            baseSize = 28
        case .title2:
            baseSize = 22
        case .title3:
            baseSize = 20
        case .headline:
            baseSize = 17
        case .body:
            baseSize = 17
        case .callout:
            baseSize = 16
        case .subheadline:
            baseSize = 15
        case .footnote:
            baseSize = 13
        case .caption1:
            baseSize = 12
        case .caption2:
            baseSize = 11
        default:
            baseSize = 17
        }
        
        let font = UIFont.systemFont(ofSize: baseSize, weight: weight)
        return metrics.scaledFont(for: font)
    }
}

// MARK: - Color Contrast
extension UIColor {
    
    /// Get high contrast version for accessibility
    func highContrastVariant() -> UIColor {
        if UIAccessibility.isDarkerSystemColorsEnabled {
            // Return higher contrast version
            var hue: CGFloat = 0
            var saturation: CGFloat = 0
            var brightness: CGFloat = 0
            var alpha: CGFloat = 0
            
            self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            
            // Increase brightness for better contrast
            brightness = min(1.0, brightness * 1.2)
            saturation = min(1.0, saturation * 1.1)
            
            return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        }
        return self
    }
}