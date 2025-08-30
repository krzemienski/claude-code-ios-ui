//
//  ChatInputBar.swift
//  ClaudeCodeUI
//
//  Base class and protocol for chat input bar components
//

import UIKit

// MARK: - ChatInputBarDelegate

/// Protocol for handling chat input bar events
@MainActor
protocol ChatInputBarDelegate: AnyObject {
    func chatInputBarDidTapSend(_ inputBar: ChatInputBar)
    func chatInputBarDidTapAttachment(_ inputBar: ChatInputBar)
    func chatInputBar(_ inputBar: ChatInputBar, didChangeHeight height: CGFloat)
}

// MARK: - ChatInputBar

/// Base class for chat input bar implementation
@MainActor
class ChatInputBar: UIView {
    
    // MARK: - Properties
    
    weak var delegate: ChatInputBarDelegate?
    
    // UI Components (to be overridden by subclasses)
    var textView: UITextView {
        fatalError("Subclass must override textView")
    }
    
    var sendButton: UIButton {
        fatalError("Subclass must override sendButton")
    }
    
    var attachmentButton: UIButton {
        fatalError("Subclass must override attachmentButton")
    }
    
    var characterCountLabel: UILabel {
        fatalError("Subclass must override characterCountLabel")
    }
    
    var connectionIndicator: UIView {
        fatalError("Subclass must override connectionIndicator")
    }
    
    // Configuration properties
    var maxTextLength: Int = 5000
    var placeholder: String = "Type a message..."
    
    // State properties
    var sendButtonEnabled: Bool = false {
        didSet {
            sendButton.isEnabled = sendButtonEnabled
            sendButton.alpha = sendButtonEnabled ? 1.0 : 0.5
        }
    }
    
    var isShiftPressed: Bool = false
    
    // MARK: - Methods
    
    /// Update the height of the input bar based on content
    func updateHeight() {
        // Base implementation - can be overridden
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        let newHeight = min(max(size.height + 20, 60), 150) // Min 60, Max 150
        
        if frame.height != newHeight {
            frame.size.height = newHeight
            delegate?.chatInputBar(self, didChangeHeight: newHeight)
        }
    }
    
    /// Clear the input text
    func clearText() {
        textView.text = ""
        sendButtonEnabled = false
        updateHeight()
    }
    
    /// Set placeholder text
    func setPlaceholder(_ text: String) {
        // To be implemented by subclasses if needed
    }
    
    /// Focus the text input
    func focusTextInput() {
        textView.becomeFirstResponder()
    }
    
    /// Dismiss keyboard
    func dismissKeyboard() {
        textView.resignFirstResponder()
    }
    
    /// Handle send button tap - to be overridden by subclasses
    func handleSendButtonTapped() {
        delegate?.chatInputBarDidTapSend(self)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let chatInputBarHeightDidChange = Notification.Name("chatInputBarHeightDidChange")
}