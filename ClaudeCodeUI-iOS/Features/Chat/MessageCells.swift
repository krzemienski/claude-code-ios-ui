//
//  MessageCells.swift
//  ClaudeCodeUI
//
//  Created by Claude on 2025-01-21.
//

import UIKit

// MARK: - Base Message Cell

class BaseMessageCell: UITableViewCell {
    static let identifier = "BaseMessageCell"
    
    let containerView = UIView()
    let bubbleView = UIView()
    let contentStackView = UIStackView()
    let timeLabel = UILabel()
    let statusImageView = UIImageView()
    
    var isUserMessage = false
    var bubbleLeadingConstraint: NSLayoutConstraint?
    var bubbleTrailingConstraint: NSLayoutConstraint?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Clear all content
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        timeLabel.text = nil
        statusImageView.image = nil
        
        // Reset constraints
        bubbleLeadingConstraint?.isActive = false
        bubbleTrailingConstraint?.isActive = false
        
        // Clear any animations
        layer.removeAllAnimations()
        bubbleView.layer.removeAllAnimations()
    }
    
    func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        // Container setup
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // Bubble setup
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.layer.cornerRadius = 16
        containerView.addSubview(bubbleView)
        
        // Content stack setup
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = 8
        contentStackView.alignment = .fill
        bubbleView.addSubview(contentStackView)
        
        // Time label setup
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = .systemFont(ofSize: 11, weight: .regular)
        timeLabel.textColor = CyberpunkTheme.secondaryText
        
        // Status image setup
        statusImageView.translatesAutoresizingMaskIntoConstraints = false
        statusImageView.contentMode = .scaleAspectFit
        statusImageView.tintColor = CyberpunkTheme.primaryCyan
        
        setupConstraints()
    }
    
    func setupConstraints() {
        // Container constraints
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
        
        // Bubble constraints (will be updated based on user/assistant)
        bubbleLeadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16)
        bubbleTrailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        
        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: containerView.topAnchor),
            bubbleView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: UIScreen.main.bounds.width * 0.75)
        ])
        
        // Content stack constraints
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 12),
            contentStackView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            contentStackView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            contentStackView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with message: EnhancedChatMessage) {
        isUserMessage = message.isUser
        
        // Update bubble alignment
        if isUserMessage {
            bubbleLeadingConstraint?.isActive = false
            bubbleTrailingConstraint?.isActive = true
            bubbleView.backgroundColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.2)
            bubbleView.layer.borderWidth = 1
            bubbleView.layer.borderColor = CyberpunkTheme.primaryCyan.cgColor
        } else {
            bubbleTrailingConstraint?.isActive = false
            bubbleLeadingConstraint?.isActive = true
            bubbleView.backgroundColor = CyberpunkTheme.surface
            bubbleView.layer.borderWidth = 1
            bubbleView.layer.borderColor = CyberpunkTheme.border.cgColor
        }
        
        // Set time
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        timeLabel.text = formatter.string(from: message.timestamp)
        
        // Set status for user messages
        if isUserMessage {
            statusImageView.isHidden = false
            updateStatusIcon(message.status)
        } else {
            statusImageView.isHidden = true
        }
    }
    
    func updateStatusIcon(_ status: MessageStatus) {
        switch status {
        case .sending:
            statusImageView.image = UIImage(systemName: "clock")
            statusImageView.tintColor = CyberpunkTheme.secondaryText
        case .sent:
            statusImageView.image = UIImage(systemName: "checkmark")
            statusImageView.tintColor = CyberpunkTheme.primaryCyan
        case .delivered:
            statusImageView.image = UIImage(systemName: "checkmark.circle")
            statusImageView.tintColor = CyberpunkTheme.primaryCyan
        case .read:
            statusImageView.image = UIImage(systemName: "checkmark.circle.fill")
            statusImageView.tintColor = CyberpunkTheme.primaryCyan
        case .failed:
            statusImageView.image = UIImage(systemName: "exclamationmark.circle")
            statusImageView.tintColor = CyberpunkTheme.accentPink
        }
    }
}

// MARK: - Text Message Cell

class TextMessageCell: BaseMessageCell {
    static let textIdentifier = "TextMessageCell"
    
    private let contentLabel = UILabel()
    
    override func setupUI() {
        super.setupUI()
        
        contentLabel.numberOfLines = 0
        contentLabel.font = CyberpunkTheme.bodyFont
        contentLabel.textColor = CyberpunkTheme.primaryText
        contentStackView.addArrangedSubview(contentLabel)
        
        // Add time and status in a horizontal stack
        let bottomStack = UIStackView(arrangedSubviews: [timeLabel, statusImageView])
        bottomStack.axis = .horizontal
        bottomStack.spacing = 4
        bottomStack.alignment = .center
        contentStackView.addArrangedSubview(bottomStack)
    }
    
    override func configure(with message: EnhancedChatMessage) {
        super.configure(with: message)
        contentLabel.text = message.content
    }
}

// MARK: - Tool Use Message Cell

class ToolUseMessageCell: BaseMessageCell {
    static let toolUseIdentifier = "ToolUseMessageCell"
    
    private let headerView = UIView()
    private let toolIconLabel = UILabel()
    private let toolNameLabel = UILabel()
    private let parametersTextView = UITextView()
    private let resultTextView = UITextView()
    
    override func setupUI() {
        super.setupUI()
        
        // Header with tool icon and name
        headerView.backgroundColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.1)
        headerView.layer.cornerRadius = 8
        
        toolIconLabel.text = "🔧"
        toolIconLabel.font = .systemFont(ofSize: 20)
        
        toolNameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        toolNameLabel.textColor = CyberpunkTheme.primaryCyan
        
        let headerStack = UIStackView(arrangedSubviews: [toolIconLabel, toolNameLabel])
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headerStack)
        
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
            headerStack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 8),
            headerStack.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -8),
            headerStack.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
        ])
        
        contentStackView.addArrangedSubview(headerView)
        
        // Parameters view
        parametersTextView.isEditable = false
        parametersTextView.isScrollEnabled = false
        parametersTextView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        parametersTextView.textColor = CyberpunkTheme.primaryText
        parametersTextView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        parametersTextView.layer.cornerRadius = 4
        parametersTextView.textContainerInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        contentStackView.addArrangedSubview(parametersTextView)
        
        // Result view
        resultTextView.isEditable = false
        resultTextView.isScrollEnabled = false
        resultTextView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        resultTextView.textColor = CyberpunkTheme.primaryText
        resultTextView.font = .systemFont(ofSize: 13)
        resultTextView.layer.cornerRadius = 4
        resultTextView.layer.borderWidth = 1
        resultTextView.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.3).cgColor
        resultTextView.textContainerInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        contentStackView.addArrangedSubview(resultTextView)
        
        // Time label
        contentStackView.addArrangedSubview(timeLabel)
    }
    
    override func configure(with message: EnhancedChatMessage) {
        super.configure(with: message)
        
        if let toolData = message.toolUseData {
            toolNameLabel.text = toolData.name
            
            // Show parameters if available
            if let params = toolData.parameters, !params.isEmpty {
                let paramsText = params.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
                parametersTextView.text = paramsText
                parametersTextView.isHidden = false
            } else {
                parametersTextView.isHidden = true
            }
            
            // Show result if available
            if let result = toolData.result {
                resultTextView.text = "✅ " + result
                resultTextView.isHidden = false
            } else {
                resultTextView.isHidden = true
            }
        } else {
            // Parse from content if toolData not available
            toolNameLabel.text = "Tool Usage"
            parametersTextView.text = message.content
            parametersTextView.isHidden = false
            resultTextView.isHidden = true
        }
        
        // Update border color for tool messages
        bubbleView.layer.borderColor = CyberpunkTheme.primaryCyan.cgColor
    }
}

// MARK: - Thinking Message Cell

class ThinkingMessageCell: BaseMessageCell {
    static let thinkingIdentifier = "ThinkingMessageCell"
    
    private let thinkingLabel = UILabel()
    private let contentLabel = UILabel()
    
    override func setupUI() {
        super.setupUI()
        
        // Thinking indicator
        thinkingLabel.text = "💭 Thinking..."
        thinkingLabel.font = .systemFont(ofSize: 12, weight: .medium)
        thinkingLabel.textColor = CyberpunkTheme.secondaryText
        contentStackView.addArrangedSubview(thinkingLabel)
        
        // Content
        contentLabel.numberOfLines = 0
        contentLabel.font = .italicSystemFont(ofSize: 14)
        contentLabel.textColor = CyberpunkTheme.secondaryText
        contentLabel.alpha = 0.8
        contentStackView.addArrangedSubview(contentLabel)
        
        // Time
        contentStackView.addArrangedSubview(timeLabel)
    }
    
    override func configure(with message: EnhancedChatMessage) {
        super.configure(with: message)
        contentLabel.text = message.content
        
        // Custom styling for thinking messages
        bubbleView.backgroundColor = CyberpunkTheme.surface.withAlphaComponent(0.5)
        bubbleView.layer.borderWidth = 1
        bubbleView.layer.borderColor = CyberpunkTheme.accentPink.cgColor
    }
}

// MARK: - Code Message Cell

class CodeMessageCell: BaseMessageCell {
    static let codeIdentifier = "CodeMessageCell"
    
    private let languageLabel = UILabel()
    private let codeTextView = UITextView()
    private let copyButton = UIButton(type: .system)
    
    override func setupUI() {
        super.setupUI()
        
        // Language label
        languageLabel.font = .systemFont(ofSize: 11, weight: .medium)
        languageLabel.textColor = UIColor.systemOrange
        contentStackView.addArrangedSubview(languageLabel)
        
        // Code view
        codeTextView.isEditable = false
        codeTextView.isScrollEnabled = false
        codeTextView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        codeTextView.textColor = CyberpunkTheme.primaryCyan
        codeTextView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        codeTextView.layer.cornerRadius = 8
        codeTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        codeTextView.autocorrectionType = .no
        codeTextView.autocapitalizationType = .none
        contentStackView.addArrangedSubview(codeTextView)
        
        // Copy button
        copyButton.setTitle("Copy Code", for: .normal)
        copyButton.titleLabel?.font = .systemFont(ofSize: 12)
        copyButton.tintColor = CyberpunkTheme.primaryCyan
        copyButton.addTarget(self, action: #selector(copyCode), for: .touchUpInside)
        contentStackView.addArrangedSubview(copyButton)
        
        // Time
        contentStackView.addArrangedSubview(timeLabel)
    }
    
    override func configure(with message: EnhancedChatMessage) {
        super.configure(with: message)
        
        // Extract code and language from content
        let content = message.content
        if let codeContent = message.codeContent {
            codeTextView.text = codeContent
            languageLabel.text = message.codeLanguage ?? "Code"
        } else {
            // Try to extract from markdown code blocks
            let pattern = "```(\\w*)\\n([\\s\\S]*?)```"
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)) {
                
                if let langRange = Range(match.range(at: 1), in: content) {
                    let lang = String(content[langRange])
                    languageLabel.text = lang.isEmpty ? "Code" : lang.uppercased()
                }
                
                if let codeRange = Range(match.range(at: 2), in: content) {
                    codeTextView.text = String(content[codeRange])
                }
            } else {
                codeTextView.text = content
                languageLabel.text = "Code"
            }
        }
        
        // Update border color for code messages
        bubbleView.layer.borderColor = UIColor.systemOrange.cgColor
    }
    
    @objc private func copyCode() {
        UIPasteboard.general.string = codeTextView.text
        
        // Animate button to show copy success
        UIView.animate(withDuration: 0.1, animations: {
            self.copyButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            self.copyButton.setTitle("Copied!", for: .normal)
            UIView.animate(withDuration: 0.1) {
                self.copyButton.transform = .identity
            }
            
            // Reset after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.copyButton.setTitle("Copy Code", for: .normal)
            }
        }
    }
}

// MARK: - Error Message Cell

class ErrorMessageCell: BaseMessageCell {
    static let errorIdentifier = "ErrorMessageCell"
    
    private let errorIconLabel = UILabel()
    private let errorLabel = UILabel()
    
    override func setupUI() {
        super.setupUI()
        
        // Error icon
        errorIconLabel.text = "❌"
        errorIconLabel.font = .systemFont(ofSize: 20)
        
        // Error text
        errorLabel.numberOfLines = 0
        errorLabel.font = CyberpunkTheme.bodyFont
        errorLabel.textColor = CyberpunkTheme.accentPink
        
        let errorStack = UIStackView(arrangedSubviews: [errorIconLabel, errorLabel])
        errorStack.axis = .horizontal
        errorStack.spacing = 8
        errorStack.alignment = .top
        contentStackView.addArrangedSubview(errorStack)
        
        // Time
        contentStackView.addArrangedSubview(timeLabel)
    }
    
    override func configure(with message: EnhancedChatMessage) {
        super.configure(with: message)
        errorLabel.text = message.content
        
        // Error styling
        bubbleView.backgroundColor = CyberpunkTheme.accentPink.withAlphaComponent(0.1)
        bubbleView.layer.borderColor = CyberpunkTheme.accentPink.cgColor
    }
}

// MARK: - System Message Cell

class SystemMessageCell: UITableViewCell {
    static let identifier = "SystemMessageCell"
    
    private let messageLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.numberOfLines = 0
        messageLabel.font = .systemFont(ofSize: 12, weight: .medium)
        messageLabel.textColor = CyberpunkTheme.secondaryText
        messageLabel.textAlignment = .center
        contentView.addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with message: EnhancedChatMessage) {
        messageLabel.text = message.content
    }
}