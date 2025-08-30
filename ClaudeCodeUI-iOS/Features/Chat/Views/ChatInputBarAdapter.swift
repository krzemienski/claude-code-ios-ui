//
//  ChatInputBarAdapter.swift
//  ClaudeCodeUI
//
//  Adapter to make ChatViewController's input UI work with ChatInputBar protocol
//

import UIKit

/// Adapts the existing ChatViewController input UI to work as a ChatInputBar
class ChatInputBarAdapter: ChatInputBar {
    
    // Adapted UI Components from ChatViewController
    private let containerView: UIView
    private let inputTextView: UITextView
    private let sendBtn: UIButton
    private let attachBtn: UIButton
    private let placeholderLabel: UILabel
    
    // ChatInputBar protocol requirements - override with computed properties
    override var textView: UITextView {
        get { return inputTextView }
        set { /* Read-only override */ }
    }
    
    override var sendButton: UIButton {
        get { return sendBtn }
        set { /* Read-only override */ }
    }
    
    override var attachmentButton: UIButton {
        get { return attachBtn }
        set { /* Read-only override */ }
    }
    
    // Additional components (created as needed) 
    private let _characterCountLabel = UILabel()
    private let _connectionIndicator = UIView()
    
    override var characterCountLabel: UILabel {
        get { return _characterCountLabel }
        set { /* Read-only override */ }
    }
    
    override var connectionIndicator: UIView {
        get { return _connectionIndicator }
        set { /* Read-only override */ }
    }
    
    // Initialize with existing UI components from ChatViewController
    init(containerView: UIView,
         inputTextView: UITextView,
         sendButton: UIButton,
         attachButton: UIButton,
         placeholderLabel: UILabel) {
        
        self.containerView = containerView
        self.inputTextView = inputTextView
        self.sendBtn = sendButton
        self.attachBtn = attachButton
        self.placeholderLabel = placeholderLabel
        
        super.init(frame: containerView.bounds)
        
        // Setup additional components
        setupCharacterCountLabel()
        setupConnectionIndicator()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCharacterCountLabel() {
        characterCountLabel.font = .systemFont(ofSize: 11)
        characterCountLabel.textColor = .secondaryLabel
        characterCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(characterCountLabel)
        
        NSLayoutConstraint.activate([
            characterCountLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
            characterCountLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12)
        ])
    }
    
    private func setupConnectionIndicator() {
        connectionIndicator.backgroundColor = .systemGreen
        connectionIndicator.layer.cornerRadius = 3
        connectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(connectionIndicator)
        
        NSLayoutConstraint.activate([
            connectionIndicator.widthAnchor.constraint(equalToConstant: 6),
            connectionIndicator.heightAnchor.constraint(equalToConstant: 6),
            connectionIndicator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            connectionIndicator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12)
        ])
    }
    
    override func updateHeight() {
        // Calculate and update height based on text content
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .infinity))
        let newHeight = min(size.height, 120) // Max 5 lines approximately
        
        if let heightConstraint = containerView.constraints.first(where: { $0.firstAttribute == .height }) {
            let totalHeight = newHeight + 16 // Adding padding
            if heightConstraint.constant != totalHeight {
                delegate?.chatInputBar(self, didChangeHeight: totalHeight)
            }
        }
    }
    
    override func handleSendButtonTapped() {
        delegate?.chatInputBarDidTapSend(self)
    }
}