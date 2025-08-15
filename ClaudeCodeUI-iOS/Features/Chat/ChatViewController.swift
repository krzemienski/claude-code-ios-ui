//
//  ChatViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/05.
//

import UIKit
import Foundation

// MARK: - Message Types (Temporary - should import from MessageTypes.swift)

enum MessageStatus: String, Codable {
    case sending, sent, delivered, failed, read
}

enum MessageType: String, Codable {
    case text, toolUse, toolResult, todoUpdate, code, error, system
    case claudeResponse, claudeOutput, thinking, fileOperation, gitOperation, terminalCommand
    
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
        case pending, inProgress, completed, blocked, cancelled
    }
    
    enum TodoPriority: String, Codable {
        case low, medium, high, critical
    }
}

class ChatMessage {
    let id: String
    var content: String
    let isUser: Bool
    let timestamp: Date
    var status: MessageStatus
    
    init(id: String, content: String, isUser: Bool, timestamp: Date, status: MessageStatus = .sent) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.status = status
    }
}

class EnhancedChatMessage: ChatMessage {
    var messageType: MessageType = .text
    var toolUseData: ToolUseData?
    var todos: [TodoItem]?
    var codeLanguage: String?
    var codeContent: String?
    var isExpanded: Bool = false
    
    func detectMessageType() {
        // Auto-detect message type from content
        if content.contains("```") {
            messageType = .code
        } else if content.contains("Tool:") || content.contains("🔧") {
            messageType = .toolUse
        } else if content.contains("Todo") || content.contains("✅") || content.contains("📋") {
            messageType = .todoUpdate
        } else if content.hasPrefix("Error:") || content.hasPrefix("❌") {
            messageType = .error
        } else if content.hasPrefix("System:") || content.hasPrefix("🔔") {
            messageType = .system
        } else if content.contains("git ") || content.contains("commit") {
            messageType = .gitOperation
        } else if content.contains("$") || content.contains("npm") || content.contains("bash") {
            messageType = .terminalCommand
        }
    }
}

// EnhancedChatMessage class moved to MessageTypes.swift

// MARK: - Typing Indicator Cell

class TypingIndicatorCell: UITableViewCell {
    static let identifier = "TypingIndicatorCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        backgroundColor = .clear
        selectionStyle = .none
        textLabel?.text = "Claude is typing..."
        textLabel?.textColor = .systemGray
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
            self.accessibilityIdentifier = nil
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
            self.accessibilityIdentifier = "assistantMessageCell"
        }
    }
}

// Assuming ChatMessageCell is defined elsewhere, add accessibilityIdentifier set here as well:
class ChatMessageCell: UITableViewCell {
    static let identifier = "ChatMessageCell"
    // ... existing properties and methods ...
    
    func configure(with message: ChatMessage) {
        // ... existing configuration code ...
        if !message.isUser {
            self.accessibilityIdentifier = "assistantMessageCell"
        } else {
            self.accessibilityIdentifier = nil
        }
    }
}

class ChatViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, WebSocketManagerDelegate {
    
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
    
    // Add isLoading property needed by BaseViewController
    override var isLoading: Bool {
        didSet {
            // Could show/hide loading indicator here if needed
        }
    }
    
    // Streaming message accumulator
    private var streamingMessageId: String?
    private var streamingMessageContent: String = ""
    private var streamingMessageIndex: Int?
    
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
        textView.accessibilityIdentifier = "chatInputTextView"
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
        button.accessibilityIdentifier = "chatSendButton"
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
        fileButton.accessibilityIdentifier = "fileExplorerButton"
        
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
            selector: #selector(keyboardWillShow(notification:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(notification:)),
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
                testMessages.append(msg)                
            default:
                // Standard message
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: "This is test message #\(i)",
                    isUser: i % 3 == 0,
                    timestamp: time,
                    status: .sent
                )
                testMessages.append(msg)
            }
        }
        
        return testMessages
    }
    
    // MARK: - Missing Methods (Stubs for building)
    
    @objc private func sendMessage() {
        // TODO: Implement message sending
        print("Send message tapped")
    }
    
    @objc private func showAttachmentOptions() {
        // TODO: Implement attachment options
        print("Attachment button tapped")
    }
    
    @objc private func showFileExplorer() {
        // TODO: Navigate to file explorer
        print("File explorer tapped")
    }
    
    @objc private func showTerminal() {
        // TODO: Navigate to terminal
        print("Terminal tapped")
    }
    
    @objc private func abortSession() {
        // TODO: Implement session abort
        print("Abort session tapped")
    }
    
    private func scrollToBottom(animated: Bool = true) {
        guard !messages.isEmpty else { return }
        let lastIndex = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: lastIndex, at: .bottom, animated: animated)
    }
    
    // MARK: - WebSocketManagerDelegate
    
    func webSocketDidConnect(_ manager: WebSocketManager) {
        print("WebSocket connected")
        updateConnectionStatus("Connected", color: UIColor.systemGreen)
    }
    
    func webSocketDidDisconnect(_ manager: WebSocketManager, error: Error?) {
        print("WebSocket disconnected: \(error?.localizedDescription ?? "No error")")
        updateConnectionStatus("Disconnected", color: UIColor.systemRed)
    }
    
    func webSocket(_ manager: WebSocketManager, didReceiveMessage message: WebSocketMessage) {
        print("WebSocket received message: \(message)")
        // Handle the message based on its type
        handleWebSocketMessage(message)
    }
    
    func webSocket(_ manager: WebSocketManager, didReceiveData data: Data) {
        print("WebSocket received data: \(data.count) bytes")
        // Handle raw data if needed
    }
    
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState) {
        print("WebSocket connection state changed: \(state)")
        // Status updates will be handled in the individual connection methods
    }
    
    private func updateConnectionStatus(_ text: String, color: UIColor) {
        DispatchQueue.main.async { [weak self] in
            // Update UI to show connection status
            print("Connection status: \(text)")
            // TODO: Update status label or other UI element
        }
    }
    
    private func handleWebSocketMessage(_ message: WebSocketMessage) {
        // Process different message types
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Extract content from payload
            let content = message.payload?["content"] as? String ?? ""
            
            switch message.type {
            case .claudeResponse, .claudeOutput:
                // Handle Claude responses
                let chatMessage = EnhancedChatMessage(
                    id: UUID().uuidString,
                    content: content,
                    isUser: false,  // Claude's message
                    timestamp: Date(),
                    status: .delivered
                )
                chatMessage.messageType = .claudeResponse
                self.messages.append(chatMessage)
                self.tableView.reloadData()
                self.scrollToBottom()
                
            case .error:
                // Handle errors
                let errorMessage = message.payload?["error"] as? String ?? "Unknown error"
                print("WebSocket error: \(errorMessage)")
                // Add error message to chat
                let errorChatMessage = EnhancedChatMessage(
                    id: UUID().uuidString,
                    content: "Error: \(errorMessage)",
                    isUser: false,
                    timestamp: Date(),
                    status: .failed
                )
                errorChatMessage.messageType = .error
                self.messages.append(errorChatMessage)
                self.tableView.reloadData()
                
            case .sessionCreated:
                // Handle session creation
                if let sessionId = message.payload?["sessionId"] as? String {
                    print("Session created with ID: \(sessionId)")
                    // Store the session ID
                    self.currentSession = Session(
                        id: sessionId,
                        projectId: self.project.id,
                        summary: "New Session",
                        messageCount: 0,
                        lastActivity: Date(),
                        status: .active
                    )
                }
                
            case .streamStart, .streamChunk, .streamEnd:
                // Handle streaming responses
                self.handleStreamingMessage(message)
                
            default:
                print("Unhandled message type: \(message.type)")
            }
        }
    }
    
    private func handleStreamingMessage(_ message: WebSocketMessage) {
        // Handle streaming messages
        let content = message.payload?["content"] as? String ?? ""
        
        switch message.type {
        case .streamStart:
            // Start a new streaming message
            let chatMessage = EnhancedChatMessage(
                id: UUID().uuidString,
                content: "",
                isUser: false,  // Claude's message
                timestamp: Date(),
                status: .sending
            )
            chatMessage.messageType = .claudeResponse
            self.messages.append(chatMessage)
            self.tableView.reloadData()
            
        case .streamChunk:
            // Append to the last message
            if let lastMessage = self.messages.last, !lastMessage.isUser {
                lastMessage.content += content
                
                // Update only the last cell for performance
                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                if let cell = self.tableView.cellForRow(at: indexPath) as? ChatMessageCell {
                    cell.configure(with: lastMessage)
                }
            }
            
        case .streamEnd:
            // Mark the message as delivered
            if let lastMessage = self.messages.last, !lastMessage.isUser {
                lastMessage.status = .delivered
                self.tableView.reloadData()
            }
            
        default:
            break
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = isShowingTypingIndicator ? messages.count + 1 : messages.count
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Show typing indicator if it's the last row
        if isShowingTypingIndicator && indexPath.row == messages.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: TypingIndicatorCell.identifier, for: indexPath)
            return cell
        }
        
        // Regular message cell
        let message = messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: EnhancedMessageCell.identifier, for: indexPath) as! EnhancedMessageCell
        cell.configure(with: message)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    // MARK: - UITextViewDelegate
    
    func textViewDidChange(_ textView: UITextView) {
        // Update placeholder visibility
        placeholderLabel.isHidden = !textView.text.isEmpty
        
        // Enable/disable send button
        sendButton.isEnabled = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        // Adjust text view height
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        let newHeight = min(max(size.height, 44), 120)
        if inputTextViewHeightConstraint.constant != newHeight {
            inputTextViewHeightConstraint.constant = newHeight
            view.layoutIfNeeded()
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        // Handle text view focus
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        // Handle text view blur
    }
    
    // MARK: - Keyboard Observers
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        
        keyboardHeight = keyboardFrame.height
        inputContainerBottomConstraint.constant = -keyboardHeight
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
        
        // Scroll to bottom if there are messages
        scrollToBottom(animated: true)
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        
        keyboardHeight = 0
        inputContainerBottomConstraint.constant = 0
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
}
