//
//  EnhancedMessageCell.swift
//  ClaudeCodeUI
//
//  Enhanced message cell with support for all message types
//

import UIKit

class EnhancedMessageCell: UITableViewCell {
    static let identifier = "EnhancedMessageCell"
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let bubbleView = UIView()
    private let headerView = UIView()
    private let typeIconView = UIImageView()
    private let typeLabel = UILabel()
    private let timeLabel = UILabel()
    private let statusImageView = UIImageView()
    
    // Content views
    private let textLabel = UILabel()
    private let codeContainerView = UIView()
    private let codeLanguageLabel = UILabel()
    private let codeTextView = UITextView()
    private let copyCodeButton = UIButton(type: .system)
    
    // Tool use views
    private let toolContainerView = UIStackView()
    private let toolNameLabel = UILabel()
    private let toolParametersLabel = UILabel()
    private let toolResultLabel = UILabel()
    private let toolExpandButton = UIButton(type: .system)
    
    // Todo views
    private let todoContainerView = UIStackView()
    private var todoItemViews: [TodoItemView] = []
    
    // Error view
    private let errorDetailLabel = UILabel()
    
    // Terminal output view
    private let terminalOutputView = UITextView()
    
    // Expansion state
    private var isExpanded = false
    private var message: EnhancedChatMessage?
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        // Container setup
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // Bubble view
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.layer.cornerRadius = 16
        containerView.addSubview(bubbleView)
        
        // Header view
        headerView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(headerView)
        
        // Type icon
        typeIconView.translatesAutoresizingMaskIntoConstraints = false
        typeIconView.contentMode = .scaleAspectFit
        typeIconView.tintColor = CyberpunkTheme.primaryCyan
        headerView.addSubview(typeIconView)
        
        // Type label
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        typeLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        typeLabel.textColor = CyberpunkTheme.secondaryText
        headerView.addSubview(typeLabel)
        
        // Time label
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = .systemFont(ofSize: 11, weight: .regular)
        timeLabel.textColor = CyberpunkTheme.secondaryText
        headerView.addSubview(timeLabel)
        
        // Status icon
        statusImageView.translatesAutoresizingMaskIntoConstraints = false
        statusImageView.contentMode = .scaleAspectFit
        headerView.addSubview(statusImageView)
        
        // Text label
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.numberOfLines = 0
        textLabel.font = CyberpunkTheme.bodyFont
        textLabel.textColor = CyberpunkTheme.primaryText
        bubbleView.addSubview(textLabel)
        
        // Code container
        setupCodeViews()
        
        // Tool use container
        setupToolViews()
        
        // Todo container
        setupTodoViews()
        
        // Error detail
        errorDetailLabel.translatesAutoresizingMaskIntoConstraints = false
        errorDetailLabel.numberOfLines = 0
        errorDetailLabel.font = .systemFont(ofSize: 13, weight: .regular)
        errorDetailLabel.textColor = CyberpunkTheme.accentPink
        bubbleView.addSubview(errorDetailLabel)
        
        // Terminal output
        terminalOutputView.translatesAutoresizingMaskIntoConstraints = false
        terminalOutputView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        terminalOutputView.textColor = UIColor.systemGreen
        terminalOutputView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        terminalOutputView.isEditable = false
        terminalOutputView.isScrollEnabled = false
        terminalOutputView.layer.cornerRadius = 8
        terminalOutputView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        bubbleView.addSubview(terminalOutputView)
        
        setupConstraints()
    }
    
    private func setupCodeViews() {
        codeContainerView.translatesAutoresizingMaskIntoConstraints = false
        codeContainerView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        codeContainerView.layer.cornerRadius = 8
        codeContainerView.layer.borderWidth = 1
        codeContainerView.layer.borderColor = CyberpunkTheme.border.cgColor
        bubbleView.addSubview(codeContainerView)
        
        // Language label
        codeLanguageLabel.translatesAutoresizingMaskIntoConstraints = false
        codeLanguageLabel.font = .monospacedSystemFont(ofSize: 11, weight: .medium)
        codeLanguageLabel.textColor = CyberpunkTheme.primaryCyan
        codeContainerView.addSubview(codeLanguageLabel)
        
        // Code text view
        codeTextView.translatesAutoresizingMaskIntoConstraints = false
        codeTextView.backgroundColor = .clear
        codeTextView.textColor = CyberpunkTheme.primaryText
        codeTextView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        codeTextView.isEditable = false
        codeTextView.isScrollEnabled = false
        codeTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        codeContainerView.addSubview(codeTextView)
        
        // Copy button
        copyCodeButton.translatesAutoresizingMaskIntoConstraints = false
        copyCodeButton.setTitle("Copy", for: .normal)
        copyCodeButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        copyCodeButton.tintColor = CyberpunkTheme.primaryCyan
        copyCodeButton.addTarget(self, action: #selector(copyCode), for: .touchUpInside)
        codeContainerView.addSubview(copyCodeButton)
    }
    
    private func setupToolViews() {
        toolContainerView.translatesAutoresizingMaskIntoConstraints = false
        toolContainerView.axis = .vertical
        toolContainerView.spacing = 8
        toolContainerView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        toolContainerView.layer.cornerRadius = 8
        toolContainerView.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        toolContainerView.isLayoutMarginsRelativeArrangement = true
        bubbleView.addSubview(toolContainerView)
        
        // Tool name
        toolNameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        toolNameLabel.textColor = CyberpunkTheme.primaryCyan
        toolContainerView.addArrangedSubview(toolNameLabel)
        
        // Tool parameters
        toolParametersLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        toolParametersLabel.textColor = CyberpunkTheme.secondaryText
        toolParametersLabel.numberOfLines = 0
        toolContainerView.addArrangedSubview(toolParametersLabel)
        
        // Tool result
        toolResultLabel.font = .systemFont(ofSize: 13, weight: .regular)
        toolResultLabel.textColor = CyberpunkTheme.primaryText
        toolResultLabel.numberOfLines = 0
        toolContainerView.addArrangedSubview(toolResultLabel)
        
        // Expand button
        toolExpandButton.setTitle("Show Details", for: .normal)
        toolExpandButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        toolExpandButton.addTarget(self, action: #selector(toggleToolExpansion), for: .touchUpInside)
        toolContainerView.addArrangedSubview(toolExpandButton)
    }
    
    private func setupTodoViews() {
        todoContainerView.translatesAutoresizingMaskIntoConstraints = false
        todoContainerView.axis = .vertical
        todoContainerView.spacing = 4
        todoContainerView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        todoContainerView.layer.cornerRadius = 8
        todoContainerView.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        todoContainerView.isLayoutMarginsRelativeArrangement = true
        bubbleView.addSubview(todoContainerView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            // Header
            headerView.topAnchor.constraint(equalTo: bubbleView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            headerView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            headerView.heightAnchor.constraint(equalToConstant: 24),
            
            // Type icon
            typeIconView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            typeIconView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            typeIconView.widthAnchor.constraint(equalToConstant: 16),
            typeIconView.heightAnchor.constraint(equalToConstant: 16),
            
            // Type label
            typeLabel.leadingAnchor.constraint(equalTo: typeIconView.trailingAnchor, constant: 4),
            typeLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            // Time label
            timeLabel.trailingAnchor.constraint(equalTo: statusImageView.leadingAnchor, constant: -4),
            timeLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            // Status icon
            statusImageView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            statusImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            statusImageView.widthAnchor.constraint(equalToConstant: 14),
            statusImageView.heightAnchor.constraint(equalToConstant: 14)
        ])
    }
    
    // MARK: - Configuration
    func configure(with message: EnhancedChatMessage) {
        self.message = message
        self.isExpanded = message.isExpanded
        
        // Reset visibility
        hideAllContentViews()
        
        // Configure header
        typeIconView.image = message.messageType.icon
        typeLabel.text = message.messageType.displayName
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        timeLabel.text = formatter.string(from: message.timestamp)
        
        // Configure status for user messages
        if message.isUser {
            statusImageView.isHidden = false
            switch message.status {
            case .sending:
                statusImageView.image = UIImage(systemName: "clock")
                statusImageView.tintColor = CyberpunkTheme.secondaryText
            case .sent:
                statusImageView.image = UIImage(systemName: "checkmark")
                statusImageView.tintColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.7)
            case .delivered:
                statusImageView.image = UIImage(systemName: "checkmark.circle.fill")
                statusImageView.tintColor = CyberpunkTheme.primaryCyan
            case .read:
                statusImageView.image = UIImage(systemName: "eye.fill")
                statusImageView.tintColor = CyberpunkTheme.success
            case .failed:
                statusImageView.image = UIImage(systemName: "exclamationmark.circle")
                statusImageView.tintColor = CyberpunkTheme.accentPink
            }
        } else {
            statusImageView.isHidden = true
        }
        
        // Configure bubble styling
        if message.isUser {
            bubbleView.backgroundColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.2)
            bubbleView.layer.borderWidth = 1
            bubbleView.layer.borderColor = CyberpunkTheme.primaryCyan.cgColor
            
            NSLayoutConstraint.activate([
                bubbleView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
                bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 60),
                bubbleView.topAnchor.constraint(equalTo: containerView.topAnchor),
                bubbleView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        } else {
            bubbleView.backgroundColor = CyberpunkTheme.surface
            bubbleView.layer.borderWidth = 1
            bubbleView.layer.borderColor = message.messageType.accentColor.cgColor
            
            NSLayoutConstraint.activate([
                bubbleView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -60),
                bubbleView.topAnchor.constraint(equalTo: containerView.topAnchor),
                bubbleView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        }
        
        // Configure content based on message type
        switch message.messageType {
        case .text, .claudeResponse, .claudeOutput:
            configureTextContent(message)
        case .code:
            configureCodeContent(message)
        case .toolUse:
            configureToolContent(message)
        case .todoUpdate:
            configureTodoContent(message)
        case .error:
            configureErrorContent(message)
        case .terminalCommand:
            configureTerminalContent(message)
        default:
            configureTextContent(message)
        }
    }
    
    private func hideAllContentViews() {
        textLabel.isHidden = true
        codeContainerView.isHidden = true
        toolContainerView.isHidden = true
        todoContainerView.isHidden = true
        errorDetailLabel.isHidden = true
        terminalOutputView.isHidden = true
    }
    
    private func configureTextContent(_ message: EnhancedChatMessage) {
        textLabel.isHidden = false
        textLabel.text = message.content
        
        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            textLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            textLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            textLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12)
        ])
    }
    
    private func configureCodeContent(_ message: EnhancedChatMessage) {
        codeContainerView.isHidden = false
        
        codeLanguageLabel.text = message.codeLanguage ?? "Code"
        codeTextView.text = message.codeContent ?? message.content
        
        // Apply syntax highlighting if language is known
        if let language = message.codeLanguage {
            applySyntaxHighlighting(to: codeTextView, language: language)
        }
        
        NSLayoutConstraint.activate([
            codeContainerView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            codeContainerView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            codeContainerView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            codeContainerView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12),
            
            codeLanguageLabel.topAnchor.constraint(equalTo: codeContainerView.topAnchor, constant: 8),
            codeLanguageLabel.leadingAnchor.constraint(equalTo: codeContainerView.leadingAnchor, constant: 12),
            
            copyCodeButton.topAnchor.constraint(equalTo: codeContainerView.topAnchor, constant: 8),
            copyCodeButton.trailingAnchor.constraint(equalTo: codeContainerView.trailingAnchor, constant: -12),
            
            codeTextView.topAnchor.constraint(equalTo: codeLanguageLabel.bottomAnchor, constant: 4),
            codeTextView.leadingAnchor.constraint(equalTo: codeContainerView.leadingAnchor),
            codeTextView.trailingAnchor.constraint(equalTo: codeContainerView.trailingAnchor),
            codeTextView.bottomAnchor.constraint(equalTo: codeContainerView.bottomAnchor)
        ])
    }
    
    private func configureToolContent(_ message: EnhancedChatMessage) {
        toolContainerView.isHidden = false
        
        if let toolData = message.toolUseData {
            toolNameLabel.text = "🔧 \(toolData.name)"
            
            if let params = toolData.parameters {
                let paramsText = params.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
                toolParametersLabel.text = paramsText
                toolParametersLabel.isHidden = !isExpanded
            } else {
                toolParametersLabel.isHidden = true
            }
            
            if let result = toolData.result {
                toolResultLabel.text = "Result: \(result)"
                toolResultLabel.isHidden = !isExpanded
            } else {
                toolResultLabel.isHidden = true
            }
            
            toolExpandButton.setTitle(isExpanded ? "Hide Details" : "Show Details", for: .normal)
        }
        
        NSLayoutConstraint.activate([
            toolContainerView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            toolContainerView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            toolContainerView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            toolContainerView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12)
        ])
    }
    
    private func configureTodoContent(_ message: EnhancedChatMessage) {
        todoContainerView.isHidden = false
        
        // Clear existing todo views
        todoItemViews.forEach { $0.removeFromSuperview() }
        todoItemViews.removeAll()
        
        // Add todo items
        if let todos = message.todos {
            for todo in todos {
                let todoView = TodoItemView()
                todoView.configure(with: todo)
                todoContainerView.addArrangedSubview(todoView)
                todoItemViews.append(todoView)
            }
        }
        
        NSLayoutConstraint.activate([
            todoContainerView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            todoContainerView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            todoContainerView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            todoContainerView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12)
        ])
    }
    
    private func configureErrorContent(_ message: EnhancedChatMessage) {
        errorDetailLabel.isHidden = false
        errorDetailLabel.text = message.errorDetails ?? message.content
        
        NSLayoutConstraint.activate([
            errorDetailLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            errorDetailLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            errorDetailLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            errorDetailLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12)
        ])
    }
    
    private func configureTerminalContent(_ message: EnhancedChatMessage) {
        terminalOutputView.isHidden = false
        terminalOutputView.text = message.terminalOutput ?? message.content
        
        NSLayoutConstraint.activate([
            terminalOutputView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            terminalOutputView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            terminalOutputView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            terminalOutputView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12),
            terminalOutputView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
    }
    
    // MARK: - Actions
    @objc private func copyCode() {
        guard let code = message?.codeContent ?? message?.content else { return }
        UIPasteboard.general.string = code
        
        // Show feedback
        copyCodeButton.setTitle("Copied!", for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.copyCodeButton.setTitle("Copy", for: .normal)
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    @objc private func toggleToolExpansion() {
        isExpanded.toggle()
        message?.isExpanded = isExpanded
        
        if let message = message {
            configure(with: message)
        }
        
        // Notify table view to update height
        if let tableView = superview as? UITableView {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    // MARK: - Syntax Highlighting
    private func applySyntaxHighlighting(to textView: UITextView, language: String) {
        guard let text = textView.text else { return }
        
        let attributedString = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: text.count)
        
        // Base attributes
        attributedString.addAttribute(.font, value: UIFont.monospacedSystemFont(ofSize: 13, weight: .regular), range: fullRange)
        attributedString.addAttribute(.foregroundColor, value: CyberpunkTheme.primaryText, range: fullRange)
        
        // Language-specific highlighting
        switch language.lowercased() {
        case "swift", "javascript", "js", "typescript", "ts", "python", "java", "c", "cpp":
            highlightKeywords(in: attributedString, language: language)
            highlightStrings(in: attributedString)
            highlightComments(in: attributedString)
            highlightNumbers(in: attributedString)
        default:
            break
        }
        
        textView.attributedText = attributedString
    }
    
    private func highlightKeywords(in attributedString: NSMutableAttributedString, language: String) {
        let keywords: [String]
        
        switch language.lowercased() {
        case "swift":
            keywords = ["func", "var", "let", "class", "struct", "enum", "protocol", "if", "else", "for", "while", "return", "import", "private", "public", "internal", "static", "override", "init"]
        case "javascript", "js", "typescript", "ts":
            keywords = ["function", "var", "let", "const", "class", "if", "else", "for", "while", "return", "import", "export", "async", "await", "new", "this"]
        case "python":
            keywords = ["def", "class", "if", "else", "elif", "for", "while", "return", "import", "from", "as", "try", "except", "finally", "with"]
        default:
            keywords = []
        }
        
        for keyword in keywords {
            let pattern = "\\b\(keyword)\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: attributedString.string, options: [], range: NSRange(location: 0, length: attributedString.length))
                for match in matches {
                    attributedString.addAttribute(.foregroundColor, value: CyberpunkTheme.primaryCyan, range: match.range)
                    attributedString.addAttribute(.font, value: UIFont.monospacedSystemFont(ofSize: 13, weight: .semibold), range: match.range)
                }
            }
        }
    }
    
    private func highlightStrings(in attributedString: NSMutableAttributedString) {
        let patterns = ["\"[^\"]*\"", "'[^']*'"]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: attributedString.string, options: [], range: NSRange(location: 0, length: attributedString.length))
                for match in matches {
                    attributedString.addAttribute(.foregroundColor, value: UIColor.systemGreen, range: match.range)
                }
            }
        }
    }
    
    private func highlightComments(in attributedString: NSMutableAttributedString) {
        let patterns = ["//.*$", "/\\*[\\s\\S]*?\\*/", "#.*$"]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) {
                let matches = regex.matches(in: attributedString.string, options: [], range: NSRange(location: 0, length: attributedString.length))
                for match in matches {
                    attributedString.addAttribute(.foregroundColor, value: CyberpunkTheme.secondaryText, range: match.range)
                    attributedString.addAttribute(.font, value: UIFont.monospacedSystemFont(ofSize: 13, weight: .regular).withTraits(.traitItalic), range: match.range)
                }
            }
        }
    }
    
    private func highlightNumbers(in attributedString: NSMutableAttributedString) {
        let pattern = "\\b\\d+\\b"
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let matches = regex.matches(in: attributedString.string, options: [], range: NSRange(location: 0, length: attributedString.length))
            for match in matches {
                attributedString.addAttribute(.foregroundColor, value: UIColor.systemOrange, range: match.range)
            }
        }
    }
    
    // MARK: - Status Updates
    
    func updateStatus(_ status: MessageStatus) {
        // Update status icon
        statusImageView.isHidden = false
        
        // Store current status for the message
        message?.status = status
        
        switch status {
        case .sending:
            statusImageView.image = UIImage(systemName: "clock")
            statusImageView.tintColor = CyberpunkTheme.secondaryText
            
            // Add subtle pulsing animation for sending state
            UIView.animate(withDuration: 0.8,
                          delay: 0,
                          options: [.repeat, .autoreverse],
                          animations: {
                self.statusImageView.alpha = 0.5
            })
        case .sent:
            statusImageView.image = UIImage(systemName: "checkmark")
            statusImageView.tintColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.7)
            statusImageView.layer.removeAllAnimations()
            statusImageView.alpha = 1.0
            
            // Add brief scale animation for sent confirmation
            UIView.animate(withDuration: 0.2, animations: {
                self.statusImageView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    self.statusImageView.transform = .identity
                }
            }
        case .delivered:
            statusImageView.image = UIImage(systemName: "checkmark.circle.fill")
            statusImageView.tintColor = CyberpunkTheme.primaryCyan
            statusImageView.layer.removeAllAnimations()
            statusImageView.alpha = 1.0
            
            // Add pulse animation for delivered confirmation
            UIView.animate(withDuration: 0.3, animations: {
                self.statusImageView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            }) { _ in
                UIView.animate(withDuration: 0.2) {
                    self.statusImageView.transform = .identity
                }
            }
        case .read:
            statusImageView.image = UIImage(systemName: "eye.fill")
            statusImageView.tintColor = CyberpunkTheme.success
            statusImageView.layer.removeAllAnimations()
            statusImageView.alpha = 1.0
        case .failed:
            statusImageView.image = UIImage(systemName: "exclamationmark.circle")
            statusImageView.tintColor = CyberpunkTheme.accentPink
            statusImageView.layer.removeAllAnimations()
            statusImageView.alpha = 1.0
            
            // Add shake animation for failed state
            let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
            animation.timingFunction = CAMediaTimingFunction(name: .linear)
            animation.duration = 0.5
            animation.values = [-10, 10, -10, 10, -5, 5, -3, 3, 0]
            statusImageView.layer.add(animation, forKey: "shake")
        }
    }
}

// MARK: - Todo Item View
class TodoItemView: UIView {
    private let statusIcon = UILabel()
    private let priorityIcon = UILabel()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.05)
        layer.cornerRadius = 6
        
        statusIcon.translatesAutoresizingMaskIntoConstraints = false
        priorityIcon.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(statusIcon)
        addSubview(priorityIcon)
        addSubview(titleLabel)
        addSubview(descriptionLabel)
        
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = CyberpunkTheme.primaryText
        titleLabel.numberOfLines = 0
        
        descriptionLabel.font = .systemFont(ofSize: 12, weight: .regular)
        descriptionLabel.textColor = CyberpunkTheme.secondaryText
        descriptionLabel.numberOfLines = 0
        
        NSLayoutConstraint.activate([
            statusIcon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            statusIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            priorityIcon.leadingAnchor.constraint(equalTo: statusIcon.trailingAnchor, constant: 4),
            priorityIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: priorityIcon.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            descriptionLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6)
        ])
    }
    
    func configure(with todo: TodoItem) {
        statusIcon.text = todo.status.icon
        priorityIcon.text = todo.priority.indicator
        titleLabel.text = todo.title
        descriptionLabel.text = todo.description
        descriptionLabel.isHidden = todo.description == nil
    }
}

// MARK: - UIFont Extension for Traits
extension UIFont {
    func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: 0)
    }
}