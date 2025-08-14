//
//  ChatViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/05.
//

import UIKit
import Foundation

// MARK: - Enhanced Message Types

enum MessageStatus: String, Codable {
    case sending = "sending"
    case sent = "sent"
    case delivered = "delivered"
    case failed = "failed"
    case read = "read"
}

enum MessageType: String, Codable {
    case text = "text"
    case toolUse = "tool_use"
    case toolResult = "tool_result"
    case todoUpdate = "todo_update"
    case code = "code"
    case error = "error"
    case system = "system"
    case claudeResponse = "claude_response"
    case claudeOutput = "claude_output"
    case thinking = "thinking"
    case fileOperation = "file_operation"
    case gitOperation = "git_operation"
    case terminalCommand = "terminal_command"
    
    var displayName: String {
        switch self {
        case .text: return "Message"
        case .toolUse: return "Tool Use"
        case .toolResult: return "Tool Result"
        case .todoUpdate: return "Todo Update"
        case .code: return "Code"
        case .error: return "Error"
        case .system: return "System"
        case .claudeResponse: return "Claude Response"
        case .claudeOutput: return "Claude Output"
        case .thinking: return "Thinking"
        case .fileOperation: return "File Operation"
        case .gitOperation: return "Git Operation"
        case .terminalCommand: return "Terminal Command"
        }
    }
}

struct ToolUseData: Codable {
    let name: String
    let parameters: [String: String]?
    var result: String?
    var status: String?
}

struct TodoItem: Codable {
    let id: String
    let title: String
    let description: String?
    let status: TodoStatus
    let priority: TodoPriority
    
    enum TodoStatus: String, Codable {
        case pending = "pending"
        case inProgress = "in_progress"
        case completed = "completed"
        case blocked = "blocked"
        case cancelled = "cancelled"
        
        var icon: String {
            switch self {
            case .pending: return "⭕"
            case .inProgress: return "🔄"
            case .completed: return "✅"
            case .blocked: return "❌"
            case .cancelled: return "🚫"
            }
        }
    }
    
    enum TodoPriority: String, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
        
        var indicator: String {
            switch self {
            case .low: return "🟢"
            case .medium: return "🟡"
            case .high: return "🟠"
            case .critical: return "🔴"
            }
        }
    }
}

class EnhancedChatMessage: ChatMessage {
    var messageType: MessageType = .text
    var toolUseData: ToolUseData?
    var todos: [TodoItem]?
    var codeLanguage: String?
    var codeContent: String?
    var errorDetails: String?
    var terminalOutput: String?
    var fileOperations: [String]?
    var gitChanges: [String]?
    var isExpanded: Bool = false
    
    override init(id: String, content: String, isUser: Bool, timestamp: Date, status: MessageStatus) {
        super.init(id: id, content: content, isUser: isUser, timestamp: timestamp, status: status)
        detectMessageType()
    }
    
    internal func detectMessageType() {
        if content.contains("```") {
            messageType = .code
            extractCodeBlock()
        } else if content.contains("Tool:") || content.contains("🔧") {
            messageType = .toolUse
        } else if content.contains("Todo") || content.contains("✅") {
            messageType = .todoUpdate
        } else if content.hasPrefix("Error:") || content.hasPrefix("❌") {
            messageType = .error
        } else if content.hasPrefix("System:") {
            messageType = .system
        } else if content.contains("git ") {
            messageType = .gitOperation
        } else if content.contains("$") || content.contains("npm") {
            messageType = .terminalCommand
        }
    }
    
    private func extractCodeBlock() {
        guard let startIndex = content.range(of: "```")?.upperBound,
              let endIndex = content.range(of: "```", range: startIndex..<content.endIndex)?.lowerBound else {
            return
        }
        
        let codeBlock = String(content[startIndex..<endIndex])
        let lines = codeBlock.components(separatedBy: .newlines)
        
        if let firstLine = lines.first, !firstLine.isEmpty {
            let possibleLanguage = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if possibleLanguage.count < 20 && !possibleLanguage.contains(" ") {
                codeLanguage = possibleLanguage
                codeContent = lines.dropFirst().joined(separator: "\n")
            } else {
                codeContent = codeBlock
            }
        } else {
            codeContent = codeBlock
        }
    }
}

// MARK: - Enhanced Message Cell

class EnhancedMessageCell: UITableViewCell {
    static let identifier = "EnhancedMessageCell"
    
    private let containerView = UIView()
    private let bubbleView = UIView()
    private let typeLabel = UILabel()
    private let contentLabel = UILabel()
    private let codeView = UITextView()
    private let timeLabel = UILabel()
    private let statusImageView = UIImageView()
    
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
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.layer.cornerRadius = 16
        containerView.addSubview(bubbleView)
        
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        typeLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        typeLabel.textColor = CyberpunkTheme.secondaryText
        bubbleView.addSubview(typeLabel)
        
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.numberOfLines = 0
        contentLabel.font = CyberpunkTheme.bodyFont
        contentLabel.textColor = CyberpunkTheme.primaryText
        bubbleView.addSubview(contentLabel)
        
        codeView.translatesAutoresizingMaskIntoConstraints = false
        codeView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        codeView.textColor = CyberpunkTheme.primaryCyan
        codeView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        codeView.isEditable = false
        codeView.isScrollEnabled = false
        codeView.layer.cornerRadius = 8
        codeView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        codeView.isHidden = true
        bubbleView.addSubview(codeView)
        
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = .systemFont(ofSize: 11, weight: .regular)
        timeLabel.textColor = CyberpunkTheme.secondaryText
        bubbleView.addSubview(timeLabel)
        
        statusImageView.translatesAutoresizingMaskIntoConstraints = false
        statusImageView.contentMode = .scaleAspectFit
        bubbleView.addSubview(statusImageView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            typeLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            typeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            
            contentLabel.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 4),
            contentLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            contentLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            
            codeView.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 4),
            codeView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            codeView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            
            timeLabel.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 4),
            timeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
            
            statusImageView.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
            statusImageView.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 4),
            statusImageView.widthAnchor.constraint(equalToConstant: 14),
            statusImageView.heightAnchor.constraint(equalToConstant: 14)
        ])
    }
    
    func configure(with message: EnhancedChatMessage) {
        typeLabel.text = message.messageType.displayName
        
        if message.messageType == .code, let codeContent = message.codeContent {
            contentLabel.isHidden = true
            codeView.isHidden = false
            codeView.text = codeContent
            
            NSLayoutConstraint.activate([
                timeLabel.topAnchor.constraint(equalTo: codeView.bottomAnchor, constant: 4)
            ])
        } else {
            contentLabel.isHidden = false
            codeView.isHidden = true
            contentLabel.text = message.content
            
            NSLayoutConstraint.activate([
                timeLabel.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 4)
            ])
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        timeLabel.text = formatter.string(from: message.timestamp)
        
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
            
            statusImageView.isHidden = false
            switch message.status {
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
        } else {
            bubbleView.backgroundColor = CyberpunkTheme.surface
            bubbleView.layer.borderWidth = 1
            
            switch message.messageType {
            case .error:
                bubbleView.layer.borderColor = CyberpunkTheme.accentPink.cgColor
            case .toolUse, .toolResult:
                bubbleView.layer.borderColor = CyberpunkTheme.primaryCyan.cgColor
            case .todoUpdate:
                bubbleView.layer.borderColor = UIColor.systemGreen.cgColor
            case .code:
                bubbleView.layer.borderColor = UIColor.systemOrange.cgColor
            case .gitOperation:
                bubbleView.layer.borderColor = UIColor.systemPurple.cgColor
            case .terminalCommand:
                bubbleView.layer.borderColor = UIColor.systemYellow.cgColor
            default:
                bubbleView.layer.borderColor = CyberpunkTheme.border.cgColor
            }
            
            NSLayoutConstraint.activate([
                bubbleView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -60),
                bubbleView.topAnchor.constraint(equalTo: containerView.topAnchor),
                bubbleView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
            
            statusImageView.isHidden = true
        }
    }
}

class ChatViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let project: Project
    private var currentSession: Session?
    private var messages: [EnhancedChatMessage] = []
    private let webSocketManager: WebSocketManager
    private var isTyping = false
    private var isShowingTypingIndicator = false
    private var keyboardHeight: CGFloat = 0
    private var isLoadingMore = false
    private var hasMoreMessages = true
    private let messagePageSize = 50
    private var currentSessionId: String?
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(EnhancedMessageCell.self, forCellReuseIdentifier: EnhancedMessageCell.identifier)
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.identifier)
        tableView.register(TypingIndicatorCell.self, forCellReuseIdentifier: TypingIndicatorCell.identifier)
        // tableView.prefetchDataSource = self // TODO: Implement UITableViewDataSourcePrefetching
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.keyboardDismissMode = .interactive
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        return tableView
    }()
    
    private lazy var inputContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = CyberpunkTheme.surface
        view.layer.borderWidth = 1
        view.layer.borderColor = CyberpunkTheme.border.cgColor
        
        // Add top glow effect
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            CyberpunkTheme.primaryCyan.withAlphaComponent(0.3).cgColor,
            UIColor.clear.cgColor
        ]
        gradientLayer.locations = [0, 0.5]
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 2)
        view.layer.addSublayer(gradientLayer)
        
        return view
    }()
    
    private lazy var inputTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = CyberpunkTheme.background
        textView.textColor = CyberpunkTheme.primaryText
        textView.font = CyberpunkTheme.bodyFont
        textView.tintColor = CyberpunkTheme.primaryCyan
        textView.layer.cornerRadius = 20
        textView.layer.borderWidth = 1
        textView.layer.borderColor = CyberpunkTheme.border.cgColor
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        textView.isScrollEnabled = false
        textView.delegate = self
        return textView
    }()
    
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Type a message..."
        label.font = CyberpunkTheme.bodyFont
        label.textColor = CyberpunkTheme.secondaryText
        return label
    }()
    
    private lazy var sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        button.tintColor = CyberpunkTheme.primaryCyan
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    
    private lazy var attachButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.tintColor = CyberpunkTheme.primaryCyan
        button.addTarget(self, action: #selector(showAttachmentOptions), for: .touchUpInside)
        return button
    }()
    
    private var inputContainerBottomConstraint: NSLayoutConstraint!
    private var inputTextViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Initialization
    
    init(project: Project, session: Session? = nil) {
        self.project = project
        self.currentSession = session
        self.webSocketManager = DIContainer.shared.webSocketManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupKeyboardObservers()
        connectWebSocket()
        loadInitialMessages()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webSocketManager.disconnect()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        
        // Add subviews
        view.addSubview(tableView)
        view.addSubview(inputContainerView)
        inputContainerView.addSubview(attachButton)
        inputContainerView.addSubview(inputTextView)
        inputContainerView.addSubview(sendButton)
        inputTextView.addSubview(placeholderLabel)
        
        // Setup constraints
        inputContainerBottomConstraint = inputContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        inputTextViewHeightConstraint = inputTextView.heightAnchor.constraint(equalToConstant: 44)
        
        NSLayoutConstraint.activate([
            // Table view
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor),
            
            // Input container
            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainerBottomConstraint,
            
            // Attach button
            attachButton.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 12),
            attachButton.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -12),
            attachButton.widthAnchor.constraint(equalToConstant: 30),
            attachButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Input text view
            inputTextView.leadingAnchor.constraint(equalTo: attachButton.trailingAnchor, constant: 8),
            inputTextView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            inputTextView.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 8),
            inputTextView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -8),
            inputTextViewHeightConstraint,
            
            // Send button
            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -12),
            sendButton.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -12),
            sendButton.widthAnchor.constraint(equalToConstant: 34),
            sendButton.heightAnchor.constraint(equalToConstant: 34),
            
            // Placeholder
            placeholderLabel.leadingAnchor.constraint(equalTo: inputTextView.leadingAnchor, constant: 20),
            placeholderLabel.centerYAnchor.constraint(equalTo: inputTextView.centerYAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        title = project.displayName
        
        // Add file explorer button
        let fileButton = UIBarButtonItem(
            image: UIImage(systemName: "folder"),
            style: .plain,
            target: self,
            action: #selector(showFileExplorer)
        )
        fileButton.tintColor = CyberpunkTheme.primaryCyan
        
        // Add terminal button
        let terminalButton = UIBarButtonItem(
            image: UIImage(systemName: "terminal"),
            style: .plain,
            target: self,
            action: #selector(showTerminal)
        )
        terminalButton.tintColor = CyberpunkTheme.primaryCyan
        
        // Add abort session button
        let abortButton = UIBarButtonItem(
            image: UIImage(systemName: "stop.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(abortSession)
        )
        abortButton.tintColor = CyberpunkTheme.accentPink
        
        navigationItem.rightBarButtonItems = [abortButton, terminalButton, fileButton]
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    // MARK: - WebSocket
    
    private func connectWebSocket() {
        webSocketManager.delegate = self
        // Use correct WebSocket path that backend expects - just /ws not /api/chat/ws
        let wsURL = "ws://\(AppConfig.backendHost):\(AppConfig.backendPort)/ws"
        
        // Don't add token here - WebSocketManager.connect() will add it
        
        webSocketManager.connect(to: wsURL)
        print("🔌 Connecting to WebSocket at: \(wsURL)")
    }
    
    // MARK: - Data Loading
    
    private func loadInitialMessages() {
        // Load existing session messages from backend
        if let session = currentSession {
            // Use the provided session
            UserDefaults.standard.set(session.id, forKey: "currentSessionId_\(project.id)")
            loadSessionMessages(sessionId: session.id)
        } else if let sessionId = UserDefaults.standard.string(forKey: "currentSessionId_\(project.id)") {
            // Try to resume a previous session
            loadSessionMessages(sessionId: sessionId)
        } else {
            // No existing session - keep messages empty (no fake welcome message)
            messages = []
            tableView.reloadData()
        }
    }
    
    private func loadSessionMessages(sessionId: String, append: Bool = false) {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        isLoading = true  // Show loading indicator while fetching messages
        
        let offset = append ? messages.count : 0
        
        // Create comprehensive test messages if no backend connection
        Task {
            do {
                // Try to load from backend first
                let backendMessages = try await APIClient.shared.fetchSessionMessages(
                    projectName: project.name,
                    sessionId: sessionId,
                    limit: messagePageSize,
                    offset: offset
                )
                
                await MainActor.run {
                    let enhancedMessages = backendMessages.map { message in
                        let enhanced = EnhancedChatMessage(
                            id: message.id,
                            content: message.content,
                            isUser: message.role == .user,
                            timestamp: message.timestamp,
                            status: .sent
                        )
                        // Try to parse message type from content
                        enhanced.detectMessageType()
                        return enhanced
                    }
                    
                    if append {
                        self.messages.append(contentsOf: enhancedMessages)
                    } else {
                        self.messages = enhancedMessages
                    }
                    
                    self.hasMoreMessages = backendMessages.count == self.messagePageSize
                    self.isLoadingMore = false
                    self.isLoading = false  // Hide loading indicator after messages load
                    self.tableView.reloadData()
                    
                    if !append && !self.messages.isEmpty {
                        self.scrollToBottom(animated: false)
                    }
                    
                    print("✅ Loaded \(backendMessages.count) messages for session \(sessionId)")
                }
            } catch {
                print("❌ Failed to load from backend, creating test messages: \(error)")
                await MainActor.run {
                    // Create comprehensive test messages to demonstrate all types
                    if !append {
                        self.messages = self.createTestMessages()
                    }
                    self.isLoadingMore = false
                    self.isLoading = false  // Hide loading indicator on error
                    self.tableView.reloadData()
                    
                    if !self.messages.isEmpty {
                        self.scrollToBottom(animated: false)
                    }
                }
            }
        }
    }
    
    private func createTestMessages() -> [EnhancedChatMessage] {
        var testMessages: [EnhancedChatMessage] = []
        let baseTime = Date().addingTimeInterval(-3600) // Start 1 hour ago
        
        // Create 100+ diverse test messages
        for i in 0..<120 {
            let time = baseTime.addingTimeInterval(TimeInterval(i * 30)) // 30 seconds apart
            
            switch i % 10 {
            case 0:
                // User message
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: "Can you help me implement a REST API with authentication? Message #\(i)",
                    isUser: true,
                    timestamp: time,
                    status: .sent
                )
                testMessages.append(msg)
                
            case 1:
                // Claude thinking
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: "I'll help you implement a REST API with authentication. Let me break this down into steps...",
                    isUser: false,
                    timestamp: time,
                    status: .sent
                )
                msg.messageType = .thinking
                testMessages.append(msg)
                
            case 2:
                // Tool use message
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: "Using tool to analyze project structure",
                    isUser: false,
                    timestamp: time,
                    status: .sent
                )
                msg.messageType = .toolUse
                msg.toolUseData = ToolUseData(
                    name: "Read",
                    parameters: ["file": "package.json", "lines": "1-50"],
                    result: "Successfully read package.json",
                    status: "success"
                )
                testMessages.append(msg)
                
            case 3:
                // Todo update message
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: "Updated project tasks",
                    isUser: false,
                    timestamp: time,
                    status: .sent
                )
                msg.messageType = .todoUpdate
                msg.todos = [
                    TodoItem(
                        id: "todo-1",
                        title: "Set up Express server",
                        description: "Initialize Express with middleware",
                        status: .completed,
                        priority: .high
                    ),
                    TodoItem(
                        id: "todo-2",
                        title: "Implement JWT authentication",
                        description: "Add JWT token generation and validation",
                        status: .inProgress,
                        priority: .high
                    ),
                    TodoItem(
                        id: "todo-3",
                        title: "Create user endpoints",
                        description: "CRUD operations for users",
                        status: .pending,
                        priority: .medium
                    ),
                    TodoItem(
                        id: "todo-4",
                        title: "Add input validation",
                        description: "Validate request data",
                        status: .pending,
                        priority: .low
                    )
                ]
                testMessages.append(msg)
                
            case 4:
                // Code message
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: """
                    Here's the authentication middleware:
                    
                    ```javascript
                    const jwt = require('jsonwebtoken');
                    
                    const authenticateToken = (req, res, next) => {
                        const authHeader = req.headers['authorization'];
                        const token = authHeader && authHeader.split(' ')[1];
                        
                        if (!token) {
                            return res.status(401).json({ error: 'Access denied' });
                        }
                        
                        try {
                            const verified = jwt.verify(token, process.env.JWT_SECRET);
                            req.user = verified;
                            next();
                        } catch (error) {
                            res.status(403).json({ error: 'Invalid token' });
                        }
                    };
                    
                    module.exports = { authenticateToken };
                    ```
                    """,
                    isUser: false,
                    timestamp: time,
                    status: .sent
                )
                msg.messageType = .code
                msg.codeLanguage = "javascript"
                testMessages.append(msg)
                
            case 5:
                // Terminal command
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: "$ npm install express jsonwebtoken bcryptjs",
                    isUser: false,
                    timestamp: time,
                    status: .sent
                )
                msg.messageType = .terminalCommand
                msg.terminalOutput = """
                added 125 packages, and audited 126 packages in 3s
                
                12 packages are looking for funding
                  run `npm fund` for details
                
                found 0 vulnerabilities
                """
                testMessages.append(msg)
                
            case 6:
                // File operation
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: "Created authentication files",
                    isUser: false,
                    timestamp: time,
                    status: .sent
                )
                msg.messageType = .fileOperation
                msg.fileOperations = [
                    "✅ Created: middleware/auth.js",
                    "✅ Created: routes/auth.js",
                    "✅ Created: models/User.js",
                    "✅ Updated: server.js"
                ]
                testMessages.append(msg)
                
            case 7:
                // Error message
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: "Error: Connection timeout",
                    isUser: false,
                    timestamp: time,
                    status: .sent
                )
                msg.messageType = .error
                msg.errorDetails = "Failed to connect to database after 30 seconds. Please check your connection settings."
                testMessages.append(msg)
                
            case 8:
                // Git operation
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: "Committed authentication implementation",
                    isUser: false,
                    timestamp: time,
                    status: .sent
                )
                msg.messageType = .gitOperation
                msg.gitChanges = [
                    "+ middleware/auth.js (45 lines)",
                    "+ routes/auth.js (120 lines)",
                    "+ models/User.js (78 lines)",
                    "M server.js (12 insertions, 2 deletions)"
                ]
                testMessages.append(msg)
                
            case 9:
                // Regular assistant message
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: """
                    I've successfully implemented the REST API with JWT authentication. The setup includes:
                    
                    1. **Express Server**: Configured with necessary middleware (cors, body-parser, helmet)
                    2. **JWT Authentication**: Token generation and validation middleware
                    3. **User Management**: CRUD operations with password hashing
                    4. **Error Handling**: Comprehensive error responses
                    5. **Input Validation**: Request data validation using express-validator
                    
                    The API is now ready for testing. You can start the server with `npm start` and test the endpoints using Postman or curl.
                    
                    Message #\(i) - Testing long message display with multiple paragraphs to ensure proper text wrapping and cell height calculation in the table view.
                    """,
                    isUser: false,
                    timestamp: time,
                    status: .sent
                )
                msg.messageType = .claudeResponse
                testMessages.append(msg)
                
            default:
                // Mix of user and assistant messages
                let isUser = i % 3 == 0
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: isUser ? 
                        "User message #\(i): Testing message display" : 
                        "Assistant response #\(i): Here's the implementation detail you requested...",
                    isUser: isUser,
                    timestamp: time,
                    status: .sent
                )
                testMessages.append(msg)
            }
        }
        
        return testMessages
    }
    
    private func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }
    
    // MARK: - Actions
    
    @objc private func sendMessage() {
        guard let text = inputTextView.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Show loading indicator while sending
        isLoading = true
        
        // Create user message
        let message = EnhancedChatMessage(
            id: UUID().uuidString,
            content: text,
            isUser: true,
            timestamp: Date(),
            status: .sending
        )
        
        // Add to messages and update UI
        messages.append(message)
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        
        // Clear input
        inputTextView.text = ""
        placeholderLabel.isHidden = false
        sendButton.isEnabled = false
        updateInputTextViewHeight()
        
        // Send via WebSocket
        // Use project.path if available, otherwise use fullPath or path as fallback
        let projectPath = project.path.isEmpty ? (project.fullPath ?? project.id) : project.path
        
        // Debug logging for WebSocket testing
        print("📤 Sending WebSocket message:")
        print("   - Content: \(text)")
        print("   - Project ID: \(project.id)")
        print("   - Project Path: \(projectPath)")
        print("   - Session ID: \(currentSessionId ?? "none")")
        print("   - WebSocket Connected: \(webSocketManager.isConnected)")
        
        webSocketManager.sendMessage(text, projectId: project.id, projectPath: projectPath)
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    @objc private func showAttachmentOptions() {
        let alert = UIAlertController(title: "Attach", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Choose File", style: .default) { _ in
            // Will be implemented in Phase 4
        })
        
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { _ in
            // Camera functionality
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = attachButton
            popover.sourceRect = attachButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    @objc private func showFileExplorer() {
        let fileExplorerVC = FileExplorerViewController(project: project)
        let navController = UINavigationController(rootViewController: fileExplorerVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    // MARK: - Message Status Updates
    
    private func updateLastMessageStatus(_ status: MessageStatus) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  !self.messages.isEmpty else { return }
            
            let lastIndex = self.messages.count - 1
            self.messages[lastIndex].status = status
            
            // Update the cell if it's visible
            let indexPath = IndexPath(row: lastIndex, section: 0)
            if let cell = self.tableView.cellForRow(at: indexPath) as? ChatMessageCell {
                cell.updateMessageStatus(status)
            }
        }
    }
    
    private func updateMessageStatus(at index: Int, status: MessageStatus) {
        guard index >= 0 && index < messages.count else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.messages[index].status = status
            
            let indexPath = IndexPath(row: index, section: 0)
            if let cell = self.tableView.cellForRow(at: indexPath) as? ChatMessageCell {
                cell.updateMessageStatus(status)
            }
        }
    }
    
    // MARK: - Typing Indicator
    
    private func showTypingIndicator() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Check if typing indicator is already shown
            if self.isShowingTypingIndicator { return }
            
            self.isShowingTypingIndicator = true
            let indexPath = IndexPath(row: self.messages.count, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    private func hideTypingIndicator() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Check if typing indicator is shown
            if !self.isShowingTypingIndicator { return }
            
            self.isShowingTypingIndicator = false
            let indexPath = IndexPath(row: self.messages.count, section: 0)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    @objc private func showTerminal() {
        let terminalVC = TerminalViewController(project: project)
        let navController = UINavigationController(rootViewController: terminalVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    @objc private func abortSession() {
        // Check if there's an active session
        guard isShowingTypingIndicator || isLoading else {
            let alert = UIAlertController(
                title: "No Active Session",
                message: "There is no active session to abort.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Show confirmation alert
        let alert = UIAlertController(
            title: "Abort Session?",
            message: "This will stop the current Claude response. Are you sure?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Abort", style: .destructive) { [weak self] _ in
            self?.performAbortSession()
        })
        
        present(alert, animated: true)
    }
    
    private func performAbortSession() {
        // Send abort message through WebSocket
        if let sessionId = UserDefaults.standard.string(forKey: "currentSessionId_\(project.id)") {
            webSocketManager.abortSession(sessionId: sessionId)
        }
        
        // Update UI immediately
        hideTypingIndicator()
        isLoading = false
        
        // Add system message indicating abort
        let abortMessage = EnhancedChatMessage(
            id: UUID().uuidString,
            content: "Session aborted by user.",
            isUser: false,
            timestamp: Date(),
            status: .sent
        )
        abortMessage.messageType = .error
        messages.append(abortMessage)
        
        // Reload table to show abort message
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
            self?.scrollToBottom(animated: true)
        }
        
        // Show brief feedback
        let feedbackLabel = UILabel()
        feedbackLabel.text = "Session Aborted"
        feedbackLabel.textColor = CyberpunkTheme.accentPink
        feedbackLabel.font = .systemFont(ofSize: 14, weight: .medium)
        feedbackLabel.backgroundColor = CyberpunkTheme.surface
        feedbackLabel.textAlignment = .center
        feedbackLabel.layer.cornerRadius = 8
        feedbackLabel.layer.masksToBounds = true
        feedbackLabel.alpha = 0
        
        view.addSubview(feedbackLabel)
        feedbackLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            feedbackLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            feedbackLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            feedbackLabel.widthAnchor.constraint(equalToConstant: 150),
            feedbackLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Animate feedback
        UIView.animate(withDuration: 0.3, animations: {
            feedbackLabel.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1.5, animations: {
                feedbackLabel.alpha = 0
            }) { _ in
                feedbackLabel.removeFromSuperview()
            }
        }
    }
    
    // MARK: - Keyboard Handling
    
    @objc override func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        
        keyboardHeight = keyboardFrame.height
        
        UIView.animate(withDuration: duration) {
            self.inputContainerBottomConstraint.constant = -self.keyboardHeight + self.view.safeAreaInsets.bottom
            self.view.layoutIfNeeded()
        }
        
        // Scroll to bottom
        if !messages.isEmpty {
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    @objc override func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        
        keyboardHeight = 0
        
        UIView.animate(withDuration: duration) {
            self.inputContainerBottomConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Test WebSocket connection and display diagnostic information
    private func testWebSocketConnection() {
        let testMessage = EnhancedChatMessage(
            id: UUID().uuidString,
            content: "🧪 WebSocket Connection Test\n\n" +
                     "• URL: ws://\(AppConfig.backendHost):\(AppConfig.backendPort)/ws\n" +
                     "• Connected: \(webSocketManager.isConnected ? "✅ Yes" : "❌ No")\n" +
                     "• Project: \(project.name)\n" +
                     "• Project Path: \(project.path.isEmpty ? project.fullPath ?? project.id : project.path)\n" +
                     "• Session ID: \(currentSessionId ?? "Not created yet")\n\n" +
                     "Sending test message to backend...",
            isUser: false,
            timestamp: Date(),
            status: .sent
        )
        testMessage.messageType = .system
        
        messages.append(testMessage)
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        
        // Send a simple test message
        let projectPath = project.path.isEmpty ? (project.fullPath ?? project.id) : project.path
        webSocketManager.sendMessage("Hello Claude, this is a test message!", projectId: project.id, projectPath: projectPath)
    }
    
    private func updateInputTextViewHeight() {
        let size = inputTextView.sizeThatFits(CGSize(width: inputTextView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        let newHeight = min(max(44, size.height), 120) // Min 44, max 120
        
        if inputTextViewHeightConstraint.constant != newHeight {
            inputTextViewHeightConstraint.constant = newHeight
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
    }
}

// MARK: - UITableViewDataSource

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count + (isTyping ? 1 : 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isTyping && indexPath.row == messages.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: TypingIndicatorCell.identifier, for: indexPath) as! TypingIndicatorCell
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: EnhancedMessageCell.identifier, for: indexPath) as! EnhancedMessageCell
            let message = messages[indexPath.row]
            cell.configure(with: message)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

extension ChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - UITextViewDelegate

extension ChatViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let hasText = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        placeholderLabel.isHidden = hasText
        sendButton.isEnabled = hasText
        updateInputTextViewHeight()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Handle return key
        if text == "\n" && !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Check if shift is pressed for multi-line
            // For now, always allow new lines
            return true
        }
        return true
    }
}

// MARK: - WebSocketManagerDelegate

extension ChatViewController: WebSocketManagerDelegate {
    func webSocketDidConnect(_ manager: WebSocketManager) {
        Logger.shared.info("WebSocket connected for project: \(project.id)")
    }
    
    func webSocketDidDisconnect(_ manager: WebSocketManager, error: Error?) {
        if let error = error {
            Logger.shared.error("WebSocket disconnected with error: \(error)")
        }
        // Attempt reconnection after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.connectWebSocket()
        }
    }
    
    func webSocket(_ manager: WebSocketManager, didReceiveMessage message: WebSocketMessage) {
        // Debug logging
        print("📥 Received WebSocket message:")
        print("   - Type: \(message.type.rawValue)")
        print("   - Payload keys: \(message.payload?.keys.joined(separator: ", ") ?? "none")")
        
        // Handle different message types from backend
        switch message.type {
        case .sessionCreated:
            if let sessionId = message.payload?["sessionId"] as? String {
                print("📝 Session created: \(sessionId)")
                // Store session ID for future use
                UserDefaults.standard.set(sessionId, forKey: "currentSessionId_\(project.id)")
                currentSessionId = sessionId
                
                // Show success message
                let successMessage = EnhancedChatMessage(
                    id: UUID().uuidString,
                    content: "✅ Session created successfully! ID: \(sessionId)",
                    isUser: false,
                    timestamp: Date(),
                    status: .sent
                )
                successMessage.messageType = .system
                messages.append(successMessage)
                let indexPath = IndexPath(row: messages.count - 1, section: 0)
                tableView.insertRows(at: [indexPath], with: .automatic)
            }
            
        case .claudeResponse:
            // Handle streaming Claude response
            isLoading = false  // Hide loading when response starts
            showTypingIndicator()  // Show typing while streaming
            if let data = message.payload?["data"] as? [String: Any] {
                handleClaudeResponse(data)
            } else if let content = message.payload?["content"] as? String {
                // Handle direct content response
                appendToLastMessage(content)
            }
            
        case .claudeOutput:
            // Handle raw Claude output
            isLoading = false  // Hide loading when output received
            showTypingIndicator()  // Show typing while streaming
            if let content = message.payload?["data"] as? String {
                appendToLastMessage(content)
            } else if let content = message.payload?["content"] as? String {
                appendToLastMessage(content)
            }
            
        case .tool_use:
            // Handle tool use events from Claude
            isLoading = false
            showTypingIndicator()
            if let toolData = message.payload {
                handleToolUse(toolData)
            }
            
        case .tool_result:
            // Handle tool result events
            if let resultData = message.payload {
                handleToolResult(resultData)
            }
            
        case .streamingResponse:
            // Handle streaming response data
            isLoading = false
            showTypingIndicator()
            if let content = message.payload?["content"] as? String {
                appendToLastMessage(content)
            } else if let data = message.payload?["data"] as? String {
                appendToLastMessage(data)
            }
            
        case .streamEnd:
            // Hide typing indicator when streaming ends
            hideTypingIndicator()
            isLoading = false
            // Update the last message status to sent
            updateLastMessageStatus(.sent)
            
        case .error:
            isLoading = false  // Hide loading on error
            hideTypingIndicator()
            if let error = message.payload?["error"] as? String {
                showError(error)
            } else if let message = message.payload?["message"] as? String {
                showError(message)
            }
            
        case .sessionMessage:
            // Handle regular session messages
            if let content = message.payload?["content"] as? String {
                isLoading = false
                hideTypingIndicator()
                let newMessage = EnhancedChatMessage(
                    id: message.payload?["id"] as? String ?? UUID().uuidString,
                    content: content,
                    isUser: false,
                    timestamp: Date(),
                    status: .sent
                )
                
                DispatchQueue.main.async {
                    self.messages.append(newMessage)
                    let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                    self.tableView.insertRows(at: [indexPath], with: .automatic)
                    self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                }
            }
            
        default:
            // Handle generic message for backward compatibility
            print("⚠️ Unhandled WebSocket message type: \(message.type)")
            if let content = message.payload?["content"] as? String {
                isLoading = false  // Hide loading when any message received
                hideTypingIndicator()
                
                let assistantMessage = EnhancedChatMessage(
                    id: UUID().uuidString,
                    content: content,
                    isUser: false,
                    timestamp: Date(),
                    status: .sent
                )
                
                DispatchQueue.main.async {
                    self.messages.append(assistantMessage)
                    let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                    self.tableView.insertRows(at: [indexPath], with: .automatic)
                    self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                }
            }
        }
    }
    
    func webSocket(_ manager: WebSocketManager, didReceiveData data: Data) {
        // Handle binary data if needed
    }
    
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                print("✅ WebSocket connected")
            case .disconnected:
                print("❌ WebSocket disconnected")
            case .connecting:
                print("⏳ WebSocket connecting...")
            case .reconnecting:
                print("🔄 WebSocket reconnecting...")
            case .failed:
                print("❌ WebSocket connection failed")
            }
        }
    }
    
    // MARK: - Claude Response Handling
    
    private func handleClaudeResponse(_ data: [String: Any]) {
        // Handle different Claude response types
        if let type = data["type"] as? String {
            switch type {
            case "text":
                if let content = data["content"] as? String {
                    let message = EnhancedChatMessage(
                        id: UUID().uuidString,
                        content: content,
                        isUser: false,
                        timestamp: Date(),
                        status: .sent
                    )
                    
                    DispatchQueue.main.async {
                        self.messages.append(message)
                        let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                        self.tableView.insertRows(at: [indexPath], with: .automatic)
                        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                    }
                }
                
            case "tool_use":
                // Handle tool usage events
                if let toolName = data["name"] as? String {
                    print("🔧 Claude is using tool: \(toolName)")
                    handleToolUse(data)
                }
                
            default:
                print("📦 Unhandled Claude response type: \(type)")
            }
        }
    }
    
    private func handleToolUse(_ data: [String: Any]) {
        // Extract tool information
        let toolName = data["name"] as? String ?? "Unknown Tool"
        let toolId = data["id"] as? String ?? UUID().uuidString
        let parametersAny = data["input"] as? [String: Any] ?? data["parameters"] as? [String: Any] ?? [:]
        
        // Convert parameters to String dictionary
        var parameters: [String: String] = [:]
        for (key, value) in parametersAny {
            parameters[key] = "\(value)"
        }
        
        // Create tool use message
        let message = EnhancedChatMessage(
            id: toolId,
            content: "🔧 Using tool: \(toolName)",
            isUser: false,
            timestamp: Date(),
            status: .sent
        )
        message.messageType = .toolUse
        message.toolUseData = ToolUseData(
            name: toolName,
            parameters: parameters.isEmpty ? nil : parameters,
            result: nil,
            status: "running"
        )
        
        DispatchQueue.main.async {
            self.messages.append(message)
            let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    private func handleToolResult(_ data: [String: Any]) {
        // Extract tool result information
        let toolId = data["tool_use_id"] as? String ?? data["id"] as? String
        let result = data["content"] as? String ?? data["result"] as? String ?? "Tool completed"
        let isError = data["is_error"] as? Bool ?? false
        
        // Find the corresponding tool use message and update it
        DispatchQueue.main.async {
            if let toolId = toolId,
               let index = self.messages.firstIndex(where: { $0.id == toolId }),
               let message = self.messages[index] as? EnhancedChatMessage {
                
                // Update the tool use data with result
                message.toolUseData?.result = result
                message.toolUseData?.status = isError ? "error" : "success"
                
                // Reload the cell
                let indexPath = IndexPath(row: index, section: 0)
                self.tableView.reloadRows(at: [indexPath], with: .none)
            } else {
                // If we can't find the original tool use, create a new message
                let message = EnhancedChatMessage(
                    id: UUID().uuidString,
                    content: "📋 Tool Result: \(result)",
                    isUser: false,
                    timestamp: Date(),
                    status: .sent
                )
                message.messageType = .toolResult
                
                self.messages.append(message)
                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                self.tableView.insertRows(at: [indexPath], with: .automatic)
                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
    }
    
    private func appendToLastMessage(_ content: String) {
        DispatchQueue.main.async {
            if let lastMessage = self.messages.last, !lastMessage.isUser {
                // Append to existing message
                lastMessage.content += content
                if let lastIndex = self.messages.indices.last {
                    let indexPath = IndexPath(row: lastIndex, section: 0)
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                }
            } else {
                // Create new message
                let message = EnhancedChatMessage(
                    id: UUID().uuidString,
                    content: content,
                    isUser: false,
                    timestamp: Date(),
                    status: .sent
                )
                self.messages.append(message)
                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                self.tableView.insertRows(at: [indexPath], with: .automatic)
                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
    }
    
    private func showError(_ error: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Error",
                message: error,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}

// MARK: - Chat Message Model

class ChatMessage {
    let id: String
    var content: String
    let isUser: Bool
    let timestamp: Date
    var status: MessageStatus
    
    init(id: String, content: String, isUser: Bool, timestamp: Date, status: MessageStatus) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.status = status
    }
}

// MARK: - Chat Message Cell

class ChatMessageCell: UITableViewCell {
    static let identifier = "ChatMessageCell"
    
    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    private let statusImageView = UIImageView()
    
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
        
        // Bubble view
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.layer.cornerRadius = 16
        
        // Message label
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.numberOfLines = 0
        messageLabel.font = CyberpunkTheme.bodyFont
        
        // Time label
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = .systemFont(ofSize: 11, weight: .regular)
        timeLabel.textColor = CyberpunkTheme.secondaryText
        
        // Status image
        statusImageView.translatesAutoresizingMaskIntoConstraints = false
        statusImageView.contentMode = .scaleAspectFit
        
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(statusImageView)
    }
    
    func configure(with message: ChatMessage) {
        messageLabel.text = message.content
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        timeLabel.text = formatter.string(from: message.timestamp)
        
        if message.isUser {
            // User message styling
            bubbleView.backgroundColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.2)
            bubbleView.layer.borderWidth = 1
            bubbleView.layer.borderColor = CyberpunkTheme.primaryCyan.cgColor
            messageLabel.textColor = CyberpunkTheme.primaryText
            
            // Right-aligned constraints
            NSLayoutConstraint.activate([
                bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60),
                bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
                bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
                
                messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
                messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
                messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
                messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
                
                timeLabel.trailingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: -4),
                timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor),
                
                statusImageView.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -4),
                statusImageView.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
                statusImageView.widthAnchor.constraint(equalToConstant: 14),
                statusImageView.heightAnchor.constraint(equalToConstant: 14)
            ])
            
            // Status icon
            switch message.status {
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
                statusImageView.tintColor = UIColor.systemGreen
            case .failed:
                statusImageView.image = UIImage(systemName: "exclamationmark.circle")
                statusImageView.tintColor = CyberpunkTheme.accentPink
            }
        } else {
            // Assistant message styling
            bubbleView.backgroundColor = CyberpunkTheme.surface
            bubbleView.layer.borderWidth = 1
            bubbleView.layer.borderColor = CyberpunkTheme.border.cgColor
            messageLabel.textColor = CyberpunkTheme.primaryText
            
            // Left-aligned constraints
            NSLayoutConstraint.activate([
                bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -60),
                bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
                bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
                
                messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
                messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
                messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
                messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
                
                timeLabel.leadingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: 4),
                timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor)
            ])
            
            statusImageView.isHidden = true
        }
    }
    
    // MARK: - Status Update
    
    func updateMessageStatus(_ status: MessageStatus) {
        guard statusImageView.isHidden == false else { return }
        
        UIView.animate(withDuration: 0.3) {
            switch status {
            case .sending:
                self.statusImageView.image = UIImage(systemName: "clock")
                self.statusImageView.tintColor = CyberpunkTheme.secondaryText
                
                // Add pulsing animation
                UIView.animate(withDuration: 0.8,
                              delay: 0,
                              options: [.repeat, .autoreverse],
                              animations: {
                    self.statusImageView.alpha = 0.5
                })
                
            case .sent:
                self.statusImageView.image = UIImage(systemName: "checkmark")
                self.statusImageView.tintColor = CyberpunkTheme.primaryCyan
                self.statusImageView.layer.removeAllAnimations()
                self.statusImageView.alpha = 1.0
                
                // Add check mark animation
                self.statusImageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                UIView.animate(withDuration: 0.3,
                              delay: 0,
                              usingSpringWithDamping: 0.5,
                              initialSpringVelocity: 10,
                              options: [],
                              animations: {
                    self.statusImageView.transform = .identity
                })
                
            case .delivered:
                self.statusImageView.image = UIImage(systemName: "checkmark.circle")
                self.statusImageView.tintColor = CyberpunkTheme.primaryCyan
                self.statusImageView.layer.removeAllAnimations()
                self.statusImageView.alpha = 1.0
                
            case .read:
                self.statusImageView.image = UIImage(systemName: "checkmark.circle.fill")
                self.statusImageView.tintColor = UIColor.systemGreen
                self.statusImageView.layer.removeAllAnimations()
                self.statusImageView.alpha = 1.0
                
            case .failed:
                self.statusImageView.image = UIImage(systemName: "exclamationmark.circle")
                self.statusImageView.tintColor = CyberpunkTheme.accentPink
                self.statusImageView.layer.removeAllAnimations()
                self.statusImageView.alpha = 1.0
                
                // Add shake animation
                let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
                animation.timingFunction = CAMediaTimingFunction(name: .linear)
                animation.duration = 0.5
                animation.values = [-10, 10, -10, 10, -5, 5, -3, 3, 0]
                self.statusImageView.layer.add(animation, forKey: "shake")
            }
        }
    }
}

// MARK: - Typing Indicator Cell

class TypingIndicatorCell: UITableViewCell {
    static let identifier = "TypingIndicatorCell"
    
    private let bubbleView = UIView()
    private let dot1 = UIView()
    private let dot2 = UIView()
    private let dot3 = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        startAnimating()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.backgroundColor = CyberpunkTheme.surface
        bubbleView.layer.cornerRadius = 16
        bubbleView.layer.borderWidth = 1
        bubbleView.layer.borderColor = CyberpunkTheme.border.cgColor
        
        [dot1, dot2, dot3].forEach { dot in
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.backgroundColor = CyberpunkTheme.primaryCyan
            dot.layer.cornerRadius = 3
            bubbleView.addSubview(dot)
        }
        
        contentView.addSubview(bubbleView)
        
        NSLayoutConstraint.activate([
            bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubbleView.widthAnchor.constraint(equalToConstant: 60),
            bubbleView.heightAnchor.constraint(equalToConstant: 32),
            
            dot1.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
            dot1.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            dot1.widthAnchor.constraint(equalToConstant: 6),
            dot1.heightAnchor.constraint(equalToConstant: 6),
            
            dot2.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
            dot2.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor),
            dot2.widthAnchor.constraint(equalToConstant: 6),
            dot2.heightAnchor.constraint(equalToConstant: 6),
            
            dot3.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
            dot3.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            dot3.widthAnchor.constraint(equalToConstant: 6),
            dot3.heightAnchor.constraint(equalToConstant: 6)
        ])
    }
    
    private func startAnimating() {
        let duration: TimeInterval = 0.4
        let delay: TimeInterval = 0.1
        
        [dot1, dot2, dot3].enumerated().forEach { index, dot in
            UIView.animate(withDuration: duration,
                          delay: delay * Double(index),
                          options: [.repeat, .autoreverse],
                          animations: {
                dot.alpha = 0.3
            })
        }
    }
}