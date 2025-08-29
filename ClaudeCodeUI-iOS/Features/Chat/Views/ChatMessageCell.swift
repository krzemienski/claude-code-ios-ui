//
//  ChatMessageCell.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-30.
//  Custom table view cell for chat messages with cyberpunk theme
//

import UIKit

// MARK: - ChatMessageCell

/// Custom cell for displaying chat messages with cyberpunk styling
final class ChatMessageCell: UITableViewCell {
    
    // MARK: - UI Components
    
    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private let timestampLabel = UILabel()
    private let statusImageView = UIImageView()
    private let avatarImageView = UIImageView()
    private let retryButton = UIButton(type: .system)
    private let codeBlockView = UIView()
    private let codeTextView = UITextView()
    
    // MARK: - Properties
    
    weak var delegate: ChatMessageCellDelegate?
    private var message: ChatMessage?
    
    // Configuration
    private let bubbleInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    private let maxBubbleWidth: CGFloat = UIScreen.main.bounds.width * 0.75
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        setupBubbleView()
        setupMessageLabel()
        setupTimestampLabel()
        setupStatusImageView()
        setupAvatarImageView()
        setupRetryButton()
        setupCodeBlockView()
        setupGestures()
    }
    
    private func setupBubbleView() {
        bubbleView.layer.cornerRadius = 18
        bubbleView.layer.shadowColor = UIColor.black.cgColor
        bubbleView.layer.shadowOffset = CGSize(width: 0, height: 2)
        bubbleView.layer.shadowOpacity = 0.1
        bubbleView.layer.shadowRadius = 4
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(bubbleView)
    }
    
    private func setupMessageLabel() {
        messageLabel.numberOfLines = 0
        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        bubbleView.addSubview(messageLabel)
    }
    
    private func setupTimestampLabel() {
        timestampLabel.font = .preferredFont(forTextStyle: .caption2)
        timestampLabel.textColor = .secondaryLabel
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(timestampLabel)
    }
    
    private func setupStatusImageView() {
        statusImageView.contentMode = .scaleAspectFit
        statusImageView.tintColor = .secondaryLabel
        statusImageView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(statusImageView)
    }
    
    private func setupAvatarImageView() {
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 16
        avatarImageView.clipsToBounds = true
        avatarImageView.backgroundColor = .systemGray5
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(avatarImageView)
    }
    
    private func setupRetryButton() {
        retryButton.setTitle("Retry", for: .normal)
        retryButton.titleLabel?.font = .preferredFont(forTextStyle: .caption1)
        retryButton.tintColor = CyberpunkTheme.accentPink
        retryButton.isHidden = true
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(retryButton)
    }
    
    private func setupCodeBlockView() {
        codeBlockView.backgroundColor = CyberpunkTheme.surface
        codeBlockView.layer.cornerRadius = 8
        codeBlockView.layer.borderWidth = 1
        codeBlockView.layer.borderColor = CyberpunkTheme.border.cgColor
        codeBlockView.isHidden = true
        codeBlockView.translatesAutoresizingMaskIntoConstraints = false
        
        codeTextView.isEditable = false
        codeTextView.isScrollEnabled = false
        codeTextView.backgroundColor = .clear
        codeTextView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        codeTextView.textColor = CyberpunkTheme.textPrimary
        codeTextView.translatesAutoresizingMaskIntoConstraints = false
        
        codeBlockView.addSubview(codeTextView)
        contentView.addSubview(codeBlockView)
    }
    
    private func setupGestures() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        bubbleView.addGestureRecognizer(longPressGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        bubbleView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Configuration
    
    func configure(with message: ChatMessage) {
        self.message = message
        
        // Apply theme based on role
        applyTheme(for: message.role)
        
        // Set message content
        if let attributedContent = parseMarkdown(message.content) {
            messageLabel.attributedText = attributedContent
        } else {
            messageLabel.text = message.content
        }
        
        // Set timestamp
        timestampLabel.text = formatTimestamp(message.timestamp)
        
        // Set status
        updateStatus(message.status)
        
        // Handle code blocks
        handleCodeBlocks(in: message.content)
        
        // Update constraints based on role
        updateConstraints(for: message.role)
        
        // Show/hide retry button for failed messages
        retryButton.isHidden = message.status != .failed
    }
    
    private func applyTheme(for role: ChatMessage.Role) {
        switch role {
        case .user:
            bubbleView.backgroundColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.1)
            bubbleView.layer.borderWidth = 1
            bubbleView.layer.borderColor = CyberpunkTheme.primaryCyan.cgColor
            messageLabel.textColor = CyberpunkTheme.textPrimary
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
            avatarImageView.tintColor = CyberpunkTheme.primaryCyan
            
        case .assistant:
            bubbleView.backgroundColor = CyberpunkTheme.surface
            bubbleView.layer.borderWidth = 1
            bubbleView.layer.borderColor = CyberpunkTheme.accentPink.cgColor
            messageLabel.textColor = CyberpunkTheme.textPrimary
            avatarImageView.image = UIImage(systemName: "cpu")
            avatarImageView.tintColor = CyberpunkTheme.accentPink
            
        case .system:
            bubbleView.backgroundColor = CyberpunkTheme.warning.withAlphaComponent(0.1)
            bubbleView.layer.borderWidth = 1
            bubbleView.layer.borderColor = CyberpunkTheme.warning.cgColor
            messageLabel.textColor = CyberpunkTheme.textSecondary
            avatarImageView.image = UIImage(systemName: "gear")
            avatarImageView.tintColor = CyberpunkTheme.warning
        }
        
        // Add glow effect
        addGlowEffect(to: bubbleView, color: bubbleView.layer.borderColor ?? CyberpunkTheme.primaryCyan.cgColor)
    }
    
    private func updateStatus(_ status: ChatMessage.Status) {
        switch status {
        case .sending:
            statusImageView.image = UIImage(systemName: "clock")
            statusImageView.tintColor = .systemGray
            
        case .delivered:
            statusImageView.image = UIImage(systemName: "checkmark")
            statusImageView.tintColor = .systemGray
            
        case .read:
            statusImageView.image = UIImage(systemName: "checkmark.circle.fill")
            statusImageView.tintColor = CyberpunkTheme.primaryCyan
            
        case .failed:
            statusImageView.image = UIImage(systemName: "exclamationmark.triangle.fill")
            statusImageView.tintColor = CyberpunkTheme.error
        }
    }
    
    private func updateConstraints(for role: ChatMessage.Role) {
        // Remove existing constraints
        bubbleView.removeFromSuperview()
        contentView.addSubview(bubbleView)
        
        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: maxBubbleWidth),
            
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: bubbleInsets.top),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: bubbleInsets.left),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -bubbleInsets.right),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -bubbleInsets.bottom)
        ])
        
        // Position based on role
        if role == .user {
            NSLayoutConstraint.activate([
                bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                avatarImageView.trailingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: -8),
                avatarImageView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
                avatarImageView.widthAnchor.constraint(equalToConstant: 32),
                avatarImageView.heightAnchor.constraint(equalToConstant: 32)
            ])
        } else {
            NSLayoutConstraint.activate([
                bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 56),
                avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                avatarImageView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
                avatarImageView.widthAnchor.constraint(equalToConstant: 32),
                avatarImageView.heightAnchor.constraint(equalToConstant: 32)
            ])
        }
        
        // Position timestamp and status
        NSLayoutConstraint.activate([
            timestampLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 4),
            timestampLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor),
            
            statusImageView.centerYAnchor.constraint(equalTo: timestampLabel.centerYAnchor),
            statusImageView.leadingAnchor.constraint(equalTo: timestampLabel.trailingAnchor, constant: 4),
            statusImageView.widthAnchor.constraint(equalToConstant: 16),
            statusImageView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
    
    // MARK: - Markdown Parsing
    
    private func parseMarkdown(_ text: String) -> NSAttributedString? {
        let attributed = NSMutableAttributedString(string: text)
        let range = NSRange(location: 0, length: text.count)
        
        // Bold
        let boldRegex = try? NSRegularExpression(pattern: "\\*\\*(.*?)\\*\\*")
        boldRegex?.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let matchRange = match?.range else { return }
            attributed.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 16), range: matchRange)
        }
        
        // Italic
        let italicRegex = try? NSRegularExpression(pattern: "\\*(.*?)\\*")
        italicRegex?.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let matchRange = match?.range else { return }
            attributed.addAttribute(.font, value: UIFont.italicSystemFont(ofSize: 16), range: matchRange)
        }
        
        // Code inline
        let codeRegex = try? NSRegularExpression(pattern: "`(.*?)`")
        codeRegex?.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let matchRange = match?.range else { return }
            attributed.addAttribute(.font, value: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular), range: matchRange)
            attributed.addAttribute(.backgroundColor, value: CyberpunkTheme.surface, range: matchRange)
        }
        
        return attributed
    }
    
    private func handleCodeBlocks(in text: String) {
        // Simple code block detection
        if text.contains("```") {
            codeBlockView.isHidden = false
            // Extract code block content
            let components = text.components(separatedBy: "```")
            if components.count > 1 {
                codeTextView.text = components[1]
            }
        } else {
            codeBlockView.isHidden = true
        }
    }
    
    // MARK: - Helpers
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "'Yesterday' h:mm a"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }
        
        return formatter.string(from: date)
    }
    
    private func addGlowEffect(to view: UIView, color: CGColor) {
        view.layer.shadowColor = color
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.layer.shadowOpacity = 0.3
        view.layer.shadowRadius = 8
    }
    
    // MARK: - Actions
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let message = message else { return }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        delegate?.chatMessageCell(self, didLongPress: message)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let message = message else { return }
        
        // Check if tap is on a link or code block
        let location = gesture.location(in: messageLabel)
        
        // Handle link taps
        if let url = detectURL(at: location) {
            delegate?.chatMessageCell(self, didTapLink: url)
        }
        
        // Handle code block taps
        if !codeBlockView.isHidden {
            if let code = codeTextView.text {
                delegate?.chatMessageCell(self, didTapCodeBlock: code)
            }
        }
    }
    
    @objc private func retryTapped() {
        guard let message = message else { return }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Notify delegate to retry
        delegate?.chatMessageCell(self, didTapRetry: message)
    }
    
    private func detectURL(at point: CGPoint) -> URL? {
        // Simple URL detection - would need proper implementation
        // This is a placeholder
        return nil
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        message = nil
        messageLabel.text = nil
        messageLabel.attributedText = nil
        timestampLabel.text = nil
        statusImageView.image = nil
        avatarImageView.image = nil
        retryButton.isHidden = true
        codeBlockView.isHidden = true
        codeTextView.text = nil
        
        // Remove glow effect
        bubbleView.layer.shadowOpacity = 0
    }
}

// MARK: - ChatMessageCellDelegate Extension

extension ChatMessageCellDelegate {
    func chatMessageCell(_ cell: ChatMessageCell, didTapRetry message: ChatMessage) {
        // Default implementation - retry the message
        // Can be overridden by conforming types
    }
}