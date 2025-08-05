//
//  MessageBubble.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import UIKit

// MARK: - Message Bubble Configuration
struct MessageBubbleConfiguration {
    let role: MessageRole
    let showAvatar: Bool
    let showTimestamp: Bool
    let maxWidth: CGFloat
    
    static let `default` = MessageBubbleConfiguration(
        role: .user,
        showAvatar: true,
        showTimestamp: true,
        maxWidth: UIScreen.main.bounds.width * 0.8
    )
}

// MARK: - Message Bubble
class MessageBubble: UIView {
    
    // MARK: - Properties
    private var configuration: MessageBubbleConfiguration = .default
    
    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        return view
    }()
    
    private let avatarView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        return view
    }()
    
    private let avatarLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    private let timestampLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = CyberpunkTheme.textTertiary
        return label
    }()
    
    private let codeBlockView: UIView = {
        let view = UIView()
        view.backgroundColor = CyberpunkTheme.background
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1
        view.layer.borderColor = CyberpunkTheme.surfaceSecondary.cgColor
        view.isHidden = true
        return view
    }()
    
    private let codeLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        label.textColor = CyberpunkTheme.textPrimary
        label.numberOfLines = 0
        return label
    }()
    
    private let copyCodeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        button.tintColor = CyberpunkTheme.primaryCyan
        return button
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Add subviews
        addSubview(avatarView)
        addSubview(containerView)
        containerView.addSubview(contentLabel)
        containerView.addSubview(timestampLabel)
        containerView.addSubview(codeBlockView)
        
        avatarView.addSubview(avatarLabel)
        codeBlockView.addSubview(codeLabel)
        codeBlockView.addSubview(copyCodeButton)
        
        // Configure constraints
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarLabel.translatesAutoresizingMaskIntoConstraints = false
        codeBlockView.translatesAutoresizingMaskIntoConstraints = false
        codeLabel.translatesAutoresizingMaskIntoConstraints = false
        copyCodeButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Avatar
            avatarView.widthAnchor.constraint(equalToConstant: 40),
            avatarView.heightAnchor.constraint(equalToConstant: 40),
            avatarView.topAnchor.constraint(equalTo: topAnchor),
            
            // Avatar label
            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            
            // Container
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Content label
            contentLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            contentLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            contentLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Code block
            codeBlockView.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 8),
            codeBlockView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            codeBlockView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Code label
            codeLabel.topAnchor.constraint(equalTo: codeBlockView.topAnchor, constant: 12),
            codeLabel.leadingAnchor.constraint(equalTo: codeBlockView.leadingAnchor, constant: 12),
            codeLabel.trailingAnchor.constraint(equalTo: codeBlockView.trailingAnchor, constant: -12),
            codeLabel.bottomAnchor.constraint(equalTo: codeBlockView.bottomAnchor, constant: -12),
            
            // Copy button
            copyCodeButton.topAnchor.constraint(equalTo: codeBlockView.topAnchor, constant: 8),
            copyCodeButton.trailingAnchor.constraint(equalTo: codeBlockView.trailingAnchor, constant: -8),
            copyCodeButton.widthAnchor.constraint(equalToConstant: 24),
            copyCodeButton.heightAnchor.constraint(equalToConstant: 24),
            
            // Timestamp
            timestampLabel.topAnchor.constraint(equalTo: codeBlockView.bottomAnchor, constant: 8),
            timestampLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            timestampLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            timestampLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])
        
        // Add copy action
        copyCodeButton.addTarget(self, action: #selector(copyCode), for: .touchUpInside)
    }
    
    // MARK: - Configuration
    func configure(with message: Message, configuration: MessageBubbleConfiguration) {
        self.configuration = configuration
        
        // Configure based on role
        switch message.role {
        case .user:
            configureForUser()
        case .assistant:
            configureForAssistant()
        case .system:
            configureForSystem()
        }
        
        // Set content
        contentLabel.text = message.content
        
        // Handle code blocks
        if let codeContent = extractCodeBlock(from: message.content) {
            codeBlockView.isHidden = false
            codeLabel.text = codeContent
            
            // Update content label to show non-code content
            contentLabel.text = message.content.replacingOccurrences(of: "```\(codeContent)```", with: "")
        } else {
            codeBlockView.isHidden = true
        }
        
        // Set timestamp
        if configuration.showTimestamp {
            timestampLabel.text = formatTimestamp(message.timestamp)
            timestampLabel.isHidden = false
        } else {
            timestampLabel.isHidden = true
        }
        
        // Avatar visibility
        avatarView.isHidden = !configuration.showAvatar
        
        // Update layout constraints based on role
        updateLayoutForRole(message.role)
    }
    
    private func configureForUser() {
        containerView.backgroundColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.2)
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = CyberpunkTheme.primaryCyan.cgColor
        
        contentLabel.textColor = CyberpunkTheme.textPrimary
        
        avatarView.backgroundColor = CyberpunkTheme.primaryCyan
        avatarLabel.text = "You"
        avatarLabel.textColor = CyberpunkTheme.background
    }
    
    private func configureForAssistant() {
        containerView.backgroundColor = CyberpunkTheme.surfacePrimary
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = CyberpunkTheme.accentPink.cgColor
        
        contentLabel.textColor = CyberpunkTheme.textPrimary
        
        avatarView.backgroundColor = CyberpunkTheme.accentPink
        avatarLabel.text = "C"
        avatarLabel.textColor = CyberpunkTheme.background
    }
    
    private func configureForSystem() {
        containerView.backgroundColor = CyberpunkTheme.surfaceSecondary
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = CyberpunkTheme.warning.cgColor
        
        contentLabel.textColor = CyberpunkTheme.textSecondary
        
        avatarView.backgroundColor = CyberpunkTheme.warning
        avatarLabel.text = "S"
        avatarLabel.textColor = CyberpunkTheme.background
    }
    
    private func updateLayoutForRole(_ role: MessageRole) {
        // Remove existing constraints
        avatarView.removeFromSuperview()
        containerView.removeFromSuperview()
        
        addSubview(avatarView)
        addSubview(containerView)
        
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        if role == .user {
            // Right-aligned for user
            NSLayoutConstraint.activate([
                avatarView.trailingAnchor.constraint(equalTo: trailingAnchor),
                containerView.trailingAnchor.constraint(equalTo: avatarView.leadingAnchor, constant: -8),
                containerView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
                containerView.widthAnchor.constraint(lessThanOrEqualToConstant: configuration.maxWidth)
            ])
        } else {
            // Left-aligned for assistant/system
            NSLayoutConstraint.activate([
                avatarView.leadingAnchor.constraint(equalTo: leadingAnchor),
                containerView.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 8),
                containerView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
                containerView.widthAnchor.constraint(lessThanOrEqualToConstant: configuration.maxWidth)
            ])
        }
    }
    
    // MARK: - Helpers
    private func extractCodeBlock(from text: String) -> String? {
        let pattern = "```([\\s\\S]*?)```"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let matches = regex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        if let match = matches?.first, match.numberOfRanges > 1 {
            let range = match.range(at: 1)
            if let swiftRange = Range(range, in: text) {
                return String(text[swiftRange])
            }
        }
        
        return nil
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Actions
    @objc private func copyCode() {
        guard let code = codeLabel.text else { return }
        
        UIPasteboard.general.string = code
        
        // Animate copy button
        UIView.animate(withDuration: 0.2, animations: {
            self.copyCodeButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.copyCodeButton.transform = .identity
            }
        }
        
        // Show feedback
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(.success)
    }
}