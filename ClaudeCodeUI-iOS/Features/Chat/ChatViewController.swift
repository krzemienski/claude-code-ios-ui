//
//  ChatViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/05.
//

import UIKit
import Foundation
import PhotosUI

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
        // Strip leading emoji indicators first for better detection
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "^[❌✅🔧📋🔔💭🎯📊]\\s*", with: "", options: .regularExpression)
        
        if content.contains("```") {
            messageType = .code
        } else if cleanContent.contains("Using tool:") || cleanContent.contains("Tool:") || content.contains("🔧") {
            messageType = .toolUse
        } else if cleanContent.contains("Result:") && (cleanContent.contains("executed") || cleanContent.contains("successfully")) {
            messageType = .toolResult
        } else if cleanContent.contains("Todo") || cleanContent.contains("Task") || content.contains("📋") {
            messageType = .todoUpdate
        } else if cleanContent.hasPrefix("Error:") || cleanContent.hasPrefix("Failed:") || cleanContent.hasPrefix("❌") {
            messageType = .error
        } else if cleanContent.hasPrefix("System:") || content.contains("🔔") {
            messageType = .system
        } else if content.contains("git ") || content.contains("commit") {
            messageType = .gitOperation
        } else if content.contains("$") || content.contains("npm") || content.contains("bash") {
            messageType = .terminalCommand
        } else if cleanContent.contains("[assistant message]") {
            messageType = .claudeResponse
        } else {
            messageType = .text
        }
    }
}

// EnhancedChatMessage class moved to MessageTypes.swift

// MARK: - Typing Indicator Cell

class TypingIndicatorCell: UITableViewCell {
    static let identifier = "TypingIndicatorCell"
    
    // TODO: Add when TypingIndicatorView is added to project
    // private let typingIndicator = TypingIndicatorView()
    // private let typingIndicator = UIView() // Placeholder
    
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
        
        // TODO: Re-enable when TypingIndicatorView is added to project
        // contentView.addSubview(typingIndicator)
        // typingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // NSLayoutConstraint.activate([
        //     typingIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
        //     typingIndicator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
        //     typingIndicator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        // ])
    }
    
    func startAnimating() {
        // typingIndicator.show()
        // typingIndicator.isHidden = false
    }
    
    func stopAnimating() {
        // typingIndicator.hide()
        // typingIndicator.isHidden = true
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

class ChatViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching, UITextViewDelegate, WebSocketManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    
    // MARK: - Properties
    
    // Debug mode - shows raw JSON responses inline
    private let showRawJSON = false // Set to false in production
    
    private let project: Project
    private var currentSession: Session?
    private var messages: [EnhancedChatMessage] = []
    private let webSocketManager: any WebSocketProtocol
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
    
    // Streaming message handler
    private let streamingHandler = StreamingMessageHandler()
    private var activeStreamingMessageId: String?
    
    // MARK: - UI Components
    
    // Typing indicator for showing when Claude is responding
    // TODO: Fix TypingIndicatorView import issue - file exists but not imported
    // private let typingIndicator = TypingIndicatorView()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.prefetchDataSource = self
        
        // Register all message cell types
        tableView.register(TextMessageCell.self, forCellReuseIdentifier: TextMessageCell.identifier)
        tableView.register(ToolUseMessageCell.self, forCellReuseIdentifier: ToolUseMessageCell.identifier)
        tableView.register(ThinkingMessageCell.self, forCellReuseIdentifier: ThinkingMessageCell.identifier)
        tableView.register(CodeMessageCell.self, forCellReuseIdentifier: CodeMessageCell.identifier)
        tableView.register(ErrorMessageCell.self, forCellReuseIdentifier: ErrorMessageCell.identifier)
        tableView.register(SystemMessageCell.self, forCellReuseIdentifier: SystemMessageCell.identifier)
        tableView.register(TypingIndicatorCell.self, forCellReuseIdentifier: TypingIndicatorCell.identifier)
        
        // Legacy cells for backward compatibility
        tableView.register(EnhancedMessageCell.self, forCellReuseIdentifier: EnhancedMessageCell.identifier)
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.identifier)
        
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
    
    // Removed setupConnectionStatusView() - we now use messages to show connection status
    // private func setupConnectionStatusView() {
    //     // Moved to message-based status display
    // }
    
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
        // Use correct WebSocket path from AppConfig
        let wsURL = AppConfig.websocketURL
        
        // Connect with token parameter (WebSocketProtocol requires both parameters)
        let token = UserDefaults.standard.string(forKey: "authToken")
        webSocketManager.connect(to: wsURL, with: token)
        print("🔌 Connecting to WebSocket at: \(wsURL)")
    }
    
    // MARK: - Data Loading
    
    private func loadInitialMessages() {
        // Load existing session messages from backend
        print("📱 loadInitialMessages called for project: \(project.name)")
        if let session = currentSession {
            // Use the provided session
            print("✅ Using provided session: \(session.id)")
            print("📋 Session created: \(session.createdAt)")
            UserDefaults.standard.set(session.id, forKey: "currentSessionId_\(project.id)")
            showChatSkeletonLoading()  // Show skeleton while loading
            loadSessionMessages(sessionId: session.id)
        } else if let sessionId = UserDefaults.standard.string(forKey: "currentSessionId_\(project.id)") {
            // Try to resume a previous session
            print("🔄 Resuming previous session: \(sessionId)")
            showChatSkeletonLoading()  // Show skeleton while loading
            loadSessionMessages(sessionId: sessionId)
        } else {
            // No existing session - keep messages empty (no fake welcome message)
            print("⚠️ No session available - starting with empty messages")
            messages = []
            hideChatSkeletonLoading()  // Hide skeleton if no session
            tableView.reloadData()
        }
    }
    
    private func loadSessionMessages(sessionId: String, append: Bool = false) {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        isLoading = true  // Show loading indicator while fetching messages
        
        let offset = append ? messages.count : 0
        
        Task {
            // First try to load from cache if not appending
            if !append && ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == nil {
                let cachedMessages = await MessagePersistenceService.shared.loadMessages(for: sessionId)
                if !cachedMessages.isEmpty {
                    await MainActor.run {
                        print("📱 Loaded \(cachedMessages.count) cached messages")
                        self.messages = cachedMessages.map { message in
                            let enhanced = EnhancedChatMessage(
                                id: message.id,
                                content: message.content,
                                isUser: message.role == .user,
                                timestamp: message.timestamp,
                                status: .delivered
                            )
                            enhanced.detectMessageType()
                            return enhanced
                        }
                        self.hideChatSkeletonLoading()
                        self.tableView.reloadData()
                        if !self.messages.isEmpty {
                            self.scrollToBottom(animated: false)
                        }
                    }
                }
            }
            
            do {
                // Try to load from backend first
                let backendMessages = try await APIClient.shared.fetchSessionMessages(
                    projectName: project.name,
                    sessionId: sessionId,
                    limit: messagePageSize,
                    offset: offset
                )
                
                await MainActor.run {
                    print("🔍 Processing \(backendMessages.count) backend messages")
                    for (index, msg) in backendMessages.prefix(3).enumerated() {
                        print("  Message \(index): role=\(msg.role), content=\(String(msg.content.prefix(50)))...")
                    }
                    
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
                    
                    // Hide skeleton loading after messages are loaded
                    self.hideChatSkeletonLoading()
                    
                    print("📊 Total messages in view: \(self.messages.count)")
                    print("🔄 Reloading table view...")
                    self.tableView.reloadData()
                    
                    if !append && !self.messages.isEmpty {
                        print("⬇️ Scrolling to bottom")
                        self.scrollToBottom(animated: false)
                    }
                    
                    // Save to cache for offline access
                    if !append && !backendMessages.isEmpty {
                        Task {
                            await MessagePersistenceService.shared.saveMessages(backendMessages, for: sessionId)
                            print("💾 Saved \(backendMessages.count) messages to cache")
                        }
                    }
                    
                    print("✅ Successfully loaded \(backendMessages.count) messages for session \(sessionId)")
                }
            } catch {
                print("❌ Failed to load messages from backend: \(error)")
                print("📋 Error details: \(String(describing: error))")
                
                // Log more detailed error information
                if let urlError = error as? URLError {
                    print("🔗 URL Error code: \(urlError.code), description: \(urlError.localizedDescription)")
                } else if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .dataCorrupted(let context):
                        print("🔴 Data corrupted: \(context.debugDescription)")
                        print("📍 Coding path: \(context.codingPath)")
                    case .keyNotFound(let key, let context):
                        print("🔴 Key not found: \(key)")
                        print("📋 Context: \(context.debugDescription)")
                        print("📍 Coding path: \(context.codingPath)")
                    case .typeMismatch(let type, let context):
                        print("🔴 Type mismatch, expected: \(type)")
                        print("📋 Context: \(context.debugDescription)")
                        print("📍 Coding path: \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        print("🔴 Value not found for type: \(type)")
                        print("📋 Context: \(context.debugDescription)")
                        print("📍 Coding path: \(context.codingPath)")
                    @unknown default:
                        print("🔴 Unknown decoding error")
                    }
                }
                
                await MainActor.run {
                    // Don't show error message in the chat if there are simply no messages
                    // Check if the error is due to missing data vs actual failure
                    let errorDesc = error.localizedDescription.lowercased()
                    let isDataMissing = errorDesc.contains("missing") || 
                                       errorDesc.contains("no such file") || 
                                       errorDesc.contains("enoent") ||
                                       errorDesc.contains("couldn't be read") ||
                                       errorDesc.contains("could not find") ||
                                       errorDesc.contains("not found")
                    
                    // Also check for network errors that should be reported
                    let isNetworkError = errorDesc.contains("connection") ||
                                        errorDesc.contains("timeout") ||
                                        errorDesc.contains("network") ||
                                        errorDesc.contains("offline")
                    
                    if isDataMissing && !isNetworkError {
                        // No messages exist yet, this is normal for a new or empty session
                        print("ℹ️ No messages found for session (likely new or empty session)")
                        self.messages = []
                    } else if isNetworkError {
                        // Show network error message
                        let errorMessage = EnhancedChatMessage(
                            id: UUID().uuidString,
                            content: "⚠️ Could not connect to server.\n\nPlease check your connection and try again.",
                            isUser: false,
                            timestamp: Date(),
                            status: .delivered
                        )
                        errorMessage.messageType = .system
                        
                        if !append {
                            self.messages = [errorMessage]
                        }
                    } else {
                        // For other errors, just log them but don't show in chat
                        print("⚠️ Error loading messages but not showing to user: \(error)")
                        self.messages = []
                    }
                    
                    self.isLoadingMore = false
                    self.isLoading = false
                    
                    // Hide skeleton loading even on error
                    self.hideChatSkeletonLoading()
                    
                    self.tableView.reloadData()
                    
                    if !self.messages.isEmpty {
                        self.scrollToBottom(animated: false)
                    }
                }
            }
        }
    }
    
    // REMOVED: createTestMessages() function - no longer using mock data
    
    // MARK: - Skeleton Loading
    
    private func showChatSkeletonLoading() {
        // Hide real content during loading
        tableView.alpha = 0
        
        // Create skeleton cells
        let skeletonCount = 5
        var skeletonViews: [UIView] = []
        
        for i in 0..<skeletonCount {
            let skeletonCell = UIView()
            skeletonCell.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(skeletonCell)
            
            // Alternate between user and assistant messages
            let isUser = i % 2 == 1
            
            // Create message bubble skeleton
            let bubbleView = UIView()
            bubbleView.translatesAutoresizingMaskIntoConstraints = false
            bubbleView.backgroundColor = isUser ? 
                CyberpunkTheme.primaryCyan.withAlphaComponent(0.1) : 
                CyberpunkTheme.surface
            bubbleView.layer.cornerRadius = 16
            skeletonCell.addSubview(bubbleView)
            
            // Add shimmer gradient layer
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [
                UIColor.clear.cgColor,
                CyberpunkTheme.primaryCyan.withAlphaComponent(0.1).cgColor,
                UIColor.clear.cgColor
            ]
            gradientLayer.locations = [0, 0.5, 1]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
            gradientLayer.frame = CGRect(x: -view.bounds.width, y: 0, width: view.bounds.width * 3, height: 60)
            bubbleView.layer.addSublayer(gradientLayer)
            
            // Animate shimmer
            let animation = CABasicAnimation(keyPath: "position.x")
            animation.fromValue = -view.bounds.width
            animation.toValue = view.bounds.width * 2
            animation.duration = 1.5
            animation.repeatCount = .infinity
            gradientLayer.add(animation, forKey: "shimmer")
            
            // Layout constraints
            NSLayoutConstraint.activate([
                skeletonCell.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                skeletonCell.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                skeletonCell.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: CGFloat(i * 80 + 20)),
                skeletonCell.heightAnchor.constraint(equalToConstant: 60)
            ])
            
            if isUser {
                NSLayoutConstraint.activate([
                    bubbleView.trailingAnchor.constraint(equalTo: skeletonCell.trailingAnchor, constant: -16),
                    bubbleView.widthAnchor.constraint(equalToConstant: 200),
                    bubbleView.heightAnchor.constraint(equalToConstant: 50),
                    bubbleView.centerYAnchor.constraint(equalTo: skeletonCell.centerYAnchor)
                ])
            } else {
                NSLayoutConstraint.activate([
                    bubbleView.leadingAnchor.constraint(equalTo: skeletonCell.leadingAnchor, constant: 16),
                    bubbleView.widthAnchor.constraint(equalToConstant: 250),
                    bubbleView.heightAnchor.constraint(equalToConstant: 50),
                    bubbleView.centerYAnchor.constraint(equalTo: skeletonCell.centerYAnchor)
                ])
            }
            
            skeletonCell.tag = 99999 + i // Use tags to identify skeleton views
            skeletonViews.append(skeletonCell)
        }
    }
    
    private func hideChatSkeletonLoading() {
        // Remove all skeleton views
        view.subviews.forEach { subview in
            if subview.tag >= 99999 && subview.tag < 100004 {
                UIView.animate(withDuration: 0.3, animations: {
                    subview.alpha = 0
                }) { _ in
                    subview.removeFromSuperview()
                }
            }
        }
        
        // Show real content with fade animation
        UIView.animate(withDuration: 0.3) {
            self.tableView.alpha = 1
        }
    }
    
    // MARK: - Missing Methods (Stubs for building)
    
    @objc private func sendMessage() {
        guard let text = inputTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { 
            print("❌ [ChatVC] sendMessage: Empty text, aborting")
            return 
        }
        
        // Log timestamp for debugging
        let timestamp = Date()
        print("📤 [ChatVC] sendMessage START - \(timestamp.timeIntervalSince1970)")
        print("   Message: \(text)")
        print("   Project: \(project.name) at \(project.path)")
        
        // Create user message with unique ID
        let messageId = UUID().uuidString
        let userMessage = EnhancedChatMessage(
            id: messageId,
            content: text,
            isUser: true,
            timestamp: timestamp,
            status: .sending
        )
        print("   Message ID: \(messageId)")
        
        // Add to messages array with animation
        messages.append(userMessage)
        print("   Total messages: \(messages.count)")
        
        // Insert with animation
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .fade)
        print("   Inserted at row: \(indexPath.row)")
        
        // Animate the message cell after insertion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            if let cell = self?.tableView.cellForRow(at: indexPath) {
                // TODO: Add animations when MessageAnimator is added to project
                // MessageAnimator.animateSend(view: cell.contentView)
                // MessageAnimator.addGlowEffect(to: cell.contentView, color: CyberpunkTheme.primaryCyan)
                print("   ✅ Cell animation triggered")
            }
        }
        
        // Use debounced scroll to prevent jittery behavior
        scrollToBottomDebounced(animated: true, delay: 0.1)
        print("   📜 Scroll to bottom queued")
        
        // Clear input
        inputTextView.text = ""
        placeholderLabel.isHidden = false
        sendButton.isEnabled = false
        print("   🧹 Input cleared")
        
        // Adjust text view height back to default
        inputTextViewHeightConstraint.constant = 44
        view.layoutIfNeeded()
        
        // CRITICAL FIX: Send the message with CORRECT format
        // Backend expects 'content' field at top level, not nested in options
        let sessionId = currentSessionId ?? UserDefaults.standard.string(forKey: "currentSessionId_\(project.id)")
        print("   Session ID: \(sessionId ?? "nil")")
        
        let messageData: [String: Any] = [
            "type": "claude-command",
            "content": text,  // ✅ FIXED: Using 'content' instead of 'command'
            "projectPath": project.path,  // ✅ FIXED: Top-level field
            "sessionId": sessionId as Any  // ✅ FIXED: Top-level field
        ]
        
        print("📡 [ChatVC] Sending WebSocket message:")
        if let jsonData = try? JSONSerialization.data(withJSONObject: messageData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
            webSocketManager.send(jsonString)
            print("   ✅ Message sent via WebSocket")
        } else {
            print("   ❌ Failed to serialize message data")
        }
        
        // Show typing indicator after a brief delay (Claude is processing)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            // Only show typing if we haven't received a response yet
            if userMessage.status == .sending {
                print("   ⏳ Showing typing indicator (no response yet)")
                self.showTypingIndicator()
            } else {
                print("   ✅ Response already received, skipping typing indicator")
            }
        }
        
        print("📤 [ChatVC] sendMessage END - \(Date().timeIntervalSince1970)")
    }
    
    @objc private func showAttachmentOptions() {
        // Create action sheet for attachment options
        let actionSheet = UIAlertController(title: "Add Attachment", message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            self?.presentPhotoPicker()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
            self?.presentCamera()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Files", style: .default) { [weak self] _ in
            // Navigate to File Explorer
            self?.showFileExplorer()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = attachButton
            popover.sourceRect = attachButton.bounds
        }
        
        present(actionSheet, animated: true)
    }
    
    @objc private func showFileExplorer() {
        // Navigate to file explorer
        let fileExplorerVC = FileExplorerViewController(project: project)
        navigationController?.pushViewController(fileExplorerVC, animated: true)
    }
    
    @objc private func showTerminal() {
        // Navigate to terminal
        let terminalVC = TerminalViewController(project: project)
        navigationController?.pushViewController(terminalVC, animated: true)
    }
    
    @objc private func abortSession() {
        // Show confirmation alert
        let alert = UIAlertController(
            title: "Abort Session?",
            message: "This will stop the current Claude session. Are you sure?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Abort", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            // Hide typing indicator immediately
            self.hideTypingIndicator()
            
            // Send abort message via WebSocket using protocol's send method
            if let sessionId = self.currentSession?.id ?? UserDefaults.standard.string(forKey: "currentSessionId_\(self.project.id)") {
                let abortData: [String: Any] = [
                    "type": "abort-session",
                    "sessionId": sessionId,
                    "timestamp": ISO8601DateFormatter().string(from: Date())
                ]
                
                if let jsonData = try? JSONSerialization.data(withJSONObject: abortData, options: []),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    self.webSocketManager.send(jsonString)
                }
                
                // Update any pending messages to failed
                self.updatePendingMessagesToFailed()
                
                // Add system message to chat
                let abortMessage = EnhancedChatMessage(
                    id: UUID().uuidString,
                    content: "⚠️ Session aborted by user",
                    isUser: false,
                    timestamp: Date(),
                    status: .delivered
                )
                abortMessage.messageType = .error
                self.messages.append(abortMessage)
                self.tableView.reloadData()
                self.scrollToBottom()
            }
        })
        
        present(alert, animated: true)
    }
    
    private func isNearBottom(threshold: CGFloat = 100) -> Bool {
        let contentHeight = tableView.contentSize.height
        let scrollViewHeight = tableView.bounds.height
        let scrollOffset = tableView.contentOffset.y
        
        // Prevent NaN by checking for valid values
        guard contentHeight > 0 && scrollViewHeight > 0 else {
            return true // Consider it "near bottom" if no content
        }
        
        // Handle case where content is smaller than viewport
        if contentHeight <= scrollViewHeight {
            return true // Always at bottom if content fits in view
        }
        
        let distanceFromBottom = contentHeight - scrollViewHeight - scrollOffset
        return distanceFromBottom < threshold
    }
    
    // MARK: - Message Status Handling
    
    private func handleSuccessfulMessageDelivery(messageId: String) {
        if let message = messages.first(where: { $0.id == messageId && $0.status == .sending }) {
            message.status = .delivered
            if let index = messages.firstIndex(where: { $0.id == messageId }) {
                let indexPath = IndexPath(row: index, section: 0)
                if let cell = tableView.cellForRow(at: indexPath) as? BaseMessageCell {
                    cell.updateStatusIcon(.delivered)
                }
            }
        }
    }
    
    private func shouldAutoScroll() -> Bool {
        // Only auto-scroll if user is near bottom
        let scrollPosition = tableView.contentOffset.y
        let contentHeight = tableView.contentSize.height
        let frameHeight = tableView.frame.height
        
        // Prevent NaN by checking for valid values
        guard contentHeight > 0 && frameHeight > 0 else {
            return true // Auto-scroll if no content
        }
        
        // Handle case where content is smaller than viewport
        if contentHeight <= frameHeight {
            return true // Always auto-scroll if content fits in view
        }
        
        let distanceFromBottom = contentHeight - scrollPosition - frameHeight
        return distanceFromBottom < 100 // Within 100 points of bottom
    }
    
    // MARK: - Scroll Management
    
    private var scrollWorkItem: DispatchWorkItem?
    
    /// Debounced scroll to bottom to prevent excessive calls
    private func scrollToBottomDebounced(animated: Bool = true, delay: TimeInterval = 0.1) {
        // Cancel any pending scroll request
        scrollWorkItem?.cancel()
        
        // Create new debounced scroll work item
        scrollWorkItem = DispatchWorkItem { [weak self] in
            self?.scrollToBottom(animated: animated, force: true)
        }
        
        // Execute after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: scrollWorkItem!)
    }
    
    private func scrollToBottom(animated: Bool = true, force: Bool = false) {
        guard !messages.isEmpty else { 
            print("📜 [ChatVC] scrollToBottom: No messages, skipping")
            return 
        }
        
        // Cancel any pending debounced scrolls if forcing
        if force {
            scrollWorkItem?.cancel()
        }
        
        let lastIndex = IndexPath(row: messages.count - 1, section: 0)
        print("📜 [ChatVC] scrollToBottom: Scrolling to row \(lastIndex.row), animated: \(animated)")
        
        // Ensure table view is ready and valid
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.tableView.numberOfSections > 0 && 
               self.tableView.numberOfRows(inSection: 0) > lastIndex.row {
                self.tableView.scrollToRow(at: lastIndex, at: .bottom, animated: animated)
            }
        }
    }
    
    // MARK: - WebSocketManagerDelegate
    
    func webSocketDidConnect(_ manager: any WebSocketProtocol) {
        print("✅ WebSocket connected successfully")
        updateConnectionStatus("Connected", color: UIColor.systemGreen)
        
        // Update connection status view
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Connection successful - add a system message
            let connectionMessage = EnhancedChatMessage(
                id: "connection-success-\(Date().timeIntervalSince1970)",
                content: "🟢 Connected to backend (ws://localhost:3004/ws)",
                isUser: false,
                timestamp: Date()
            )
            self.messages.append(connectionMessage)
            self.tableView.reloadData()
            
            // Remove any connection error messages
            self.messages.removeAll { $0.id == "connection-status" || $0.id == "websocket-warning" }
            self.tableView.reloadData()
        }
    }
    
    func webSocketDidDisconnect(_ manager: any WebSocketProtocol, error: Error?) {
        let errorMessage = error?.localizedDescription ?? "Connection closed"
        print("❌ WebSocket disconnected: \(errorMessage)")
        updateConnectionStatus("Disconnected: \(errorMessage)", color: UIColor.systemRed)
        
        // Update connection status view
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Show disconnection status as a message
            let disconnectionMessage = EnhancedChatMessage(
                id: "connection-error-\(Date().timeIntervalSince1970)",
                content: "🔴 Disconnected - Check backend on localhost:3004",
                isUser: false,
                timestamp: Date()
            )
            self.messages.append(disconnectionMessage)
            self.tableView.reloadData()
        }
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveMessage message: WebSocketMessage) {
        print("📥 [ChatVC] WebSocket received message - \(Date().timeIntervalSince1970)")
        print("   Type: \(message.type)")
        print("   Session ID: \(message.sessionId ?? "nil")")
        
        // Log payload summary (avoid logging huge content)
        if let payload = message.payload {
            if let content = payload["content"] as? String {
                let preview = String(content.prefix(100))
                print("   Content preview: \(preview)...")
            }
            print("   Payload keys: \(payload.keys.joined(separator: ", "))")
        }
        
        // Handle the message based on its type
        handleWebSocketMessage(message)
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveData data: Data) {
        print("WebSocket received data: \(data.count) bytes")
        // Handle raw data if needed
    }
    
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState) {
        print("WebSocket connection state changed: \(state)")
        // Status updates will be handled in the individual connection methods
    }
    
    private func updateConnectionStatus(_ text: String, color: UIColor) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update UI to show connection status
            print("Connection status: \(text)")
            
            // Create or update status message
            let statusMessage = EnhancedChatMessage(
                id: "connection-status",
                content: "🔄 WebSocket Status: \(text)",
                isUser: false,
                timestamp: Date(),
                status: text == "Connected" ? .delivered : .failed
            )
            statusMessage.messageType = text == "Connected" ? .system : .error
            
            // Remove any existing connection status message
            self.messages.removeAll { $0.id == "connection-status" }
            
            // Add new status at the beginning if disconnected
            if text != "Connected" {
                self.messages.insert(statusMessage, at: 0)
                self.tableView.reloadData()
            }
        }
    }
    
    private func handleWebSocketMessage(_ message: WebSocketMessage) {
        // Process different message types
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Log raw message for debugging
            print("📦 Raw WebSocket message type: \(message.type)")
            if let payload = message.payload,
               let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📋 Raw JSON payload:\n\(jsonString)")
            }
            
            // Filter out metadata messages that shouldn't be displayed
            // Check if this is a metadata/status message
            if message.type == .claudeResponse {
                // Check if the content is just a status or ID
                if let content = message.payload?["content"] as? String {
                    let lowercased = content.lowercased()
                    // Skip messages that are just status indicators or IDs
                    if lowercased == "success" || 
                       lowercased == "assistant" || 
                       lowercased == "result" ||
                       lowercased == "thinking" ||
                       content.contains("-") && content.count == 36 || // UUID format
                       content.hasPrefix("claude-") || // Model identifiers
                       content.count < 3 { // Very short status messages
                        print("🚫 Skipping metadata message: \(content)")
                        return
                    }
                }
            }
            
            // Extract content from payload based on message type
            let content: String
            
            // Check multiple possible content locations based on backend response structure
            if let directContent = message.payload?["content"] as? String, !directContent.isEmpty {
                // Content is directly in payload (most common case)
                content = directContent
            } else if let data = message.payload?["data"] as? [String: Any] {
                // Content might be nested in 'data' object
                if let nestedContent = data["content"] as? String {
                    content = nestedContent
                } else if let nestedMessage = data["message"] as? String {
                    content = nestedMessage
                } else {
                    // Try to extract any text field from data
                    content = data.values.compactMap { $0 as? String }.first ?? ""
                }
            } else if let messageText = message.payload?["message"] as? String {
                // Sometimes content comes as 'message' field
                content = messageText
            } else if let text = message.payload?["text"] as? String {
                // Or as 'text' field
                content = text
            } else {
                // Last resort - try to stringify the entire payload if it contains useful info
                if let payload = message.payload,
                   message.type == .claudeResponse || message.type == .claudeOutput {
                    // For Claude responses, show the raw payload if we can't parse it properly
                    if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        content = "⚠️ Unable to parse response. Raw data:\n\(jsonString)"
                    } else {
                        content = ""
                    }
                } else {
                    content = ""
                }
            }
            
            switch message.type {
            case .claudeOutput:
                // Handle streaming Claude output (partial responses)
                // In debug mode, show what type of stream we're getting
                if self.showRawJSON && !content.isEmpty {
                    print("🌊 Streaming chunk: \(content)")
                }
                
                self.handleClaudeStreamingOutput(content: content)
                
            case .claudeResponse:
                // Handle complete Claude response
                var displayContent = content
                
                // Add raw JSON in debug mode (show the entire payload for debugging)
                if self.showRawJSON,
                   let payload = message.payload,
                   let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    displayContent = "\(content)\n\n🔍 Debug - Raw Response:\n```json\n\(jsonString)\n```"
                }
                
                self.handleClaudeCompleteResponse(content: displayContent)
                
            case .tool_use:
                // Handle tool use messages with enhanced formatting
                self.handleToolUseMessage(message: message)
                
            case .tool_result:
                // Handle tool result messages
                let resultMessage = EnhancedChatMessage(
                    id: UUID().uuidString,
                    content: "Tool Result:\n\(content)",
                    isUser: false,
                    timestamp: Date(),
                    status: .delivered
                )
                resultMessage.messageType = .toolResult
                self.messages.append(resultMessage)
                self.tableView.reloadData()
                self.scrollToBottom()
                
            case .error:
                // Handle errors and hide typing indicator
                self.hideTypingIndicator()
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
                // Update any pending user messages to failed state
                self.updatePendingMessagesToFailed()
                
            case .sessionCreated:
                // Handle session creation and extract sessionId
                self.handleSessionCreated(message: message)
                
            case .streamStart:
                // Start of streaming response - show typing indicator
                self.showTypingIndicator()
                self.handleStreamingMessage(message)
                
            case .streamChunk:
                // Continue streaming - keep typing indicator visible
                self.handleStreamingMessage(message)
                
            case .streamEnd:
                // End of streaming - hide typing indicator and mark as delivered
                self.hideTypingIndicator()
                self.handleStreamingMessage(message)
                
                // Mark the streaming message as delivered
                if let lastMessage = self.messages.last,
                   !lastMessage.isUser,
                   lastMessage.status == .sending {
                    lastMessage.status = .delivered
                    
                    // Add a note about the raw JSON if in debug mode
                    if let payload = message.payload,
                       let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        lastMessage.content += "\n\n🔍 Debug - Raw JSON:\n```json\n\(jsonString)\n```"
                    }
                    
                    let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                    if let cell = self.tableView.cellForRow(at: indexPath) as? EnhancedMessageCell {
                        cell.configure(with: lastMessage)
                    }
                }
                
            case .sessionAborted:
                // Handle session abort
                self.hideTypingIndicator()
                let abortMessage = EnhancedChatMessage(
                    id: UUID().uuidString,
                    content: "Session aborted",
                    isUser: false,
                    timestamp: Date(),
                    status: .delivered
                )
                abortMessage.messageType = .error
                self.messages.append(abortMessage)
                self.tableView.reloadData()
                
            default:
                print("Unhandled message type: \(message.type)")
            }
        }
    }
    
    // MARK: - Claude Response Handlers
    
    private func handleClaudeStreamingOutput(content: String) {
        // Process through streaming handler
        if let data = content.data(using: .utf8),
           let result = streamingHandler.processStreamingChunk(data) {
            
            print("🔄 Streaming: id=\(result.messageId), complete=\(result.isComplete)")
            
            // Find or create message
            if let existingIndex = messages.firstIndex(where: { $0.id == result.messageId }) {
                // Update existing message
                let message = messages[existingIndex]
                message.content = result.content
                
                // Detect and update message type
                let structured = streamingHandler.extractStructuredContent(from: result.content)
                message.messageType = structured.type
                
                if result.isComplete {
                    message.status = .delivered
                    activeStreamingMessageId = nil
                    hideTypingIndicator()
                }
                
                // Update cell
                let indexPath = IndexPath(row: existingIndex, section: 0)
                if let cell = tableView.cellForRow(at: indexPath) {
                    if let baseCell = cell as? BaseMessageCell {
                        baseCell.configure(with: message)
                    } else if let systemCell = cell as? SystemMessageCell {
                        systemCell.configure(with: message)
                    }
                }
            } else {
                // Create new streaming message
                showTypingIndicator()
                let chatMessage = EnhancedChatMessage(
                    id: result.messageId,
                    content: result.content,
                    isUser: false,
                    timestamp: Date(),
                    status: result.isComplete ? .delivered : .sending
                )
                
                // Set message type
                let structured = streamingHandler.extractStructuredContent(from: result.content)
                chatMessage.messageType = structured.type
                
                messages.append(chatMessage)
                activeStreamingMessageId = result.messageId
                
                // Insert with animation
                let indexPath = IndexPath(row: messages.count - 1, section: 0)
                tableView.insertRows(at: [indexPath], with: .fade)
                
                if result.isComplete {
                    activeStreamingMessageId = nil
                    hideTypingIndicator()
                }
                
                // Auto-scroll only if user is near bottom
                if shouldAutoScroll() {
                    scrollToBottomDebounced(animated: false)
                }
            }
        } else {
            // Fallback to simple text appending
            handleClaudeStreamingOutputLegacy(content: content)
        }
    }
    
    private func handleClaudeStreamingOutputLegacy(content: String) {
        // Legacy streaming handler for backward compatibility
        print("🔄 Claude streaming output (legacy): \(content)")
        
        // Check if we have an active streaming message
        if let lastMessage = messages.last,
           !lastMessage.isUser,
           lastMessage.messageType == .claudeResponse,
           lastMessage.status == .sending {
            // Append to existing streaming message
            lastMessage.content += content
            
            // Update only the last cell for performance
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            if let cell = tableView.cellForRow(at: indexPath) {
                if let baseCell = cell as? BaseMessageCell {
                    baseCell.configure(with: lastMessage)
                }
            }
            
            // Keep typing indicator visible
            if !isShowingTypingIndicator {
                showTypingIndicator()
            }
        } else {
            // Create new streaming message
            showTypingIndicator()
            let chatMessage = EnhancedChatMessage(
                id: UUID().uuidString,
                content: content.isEmpty ? "[Receiving response...]\n\(content)" : content,
                isUser: false,
                timestamp: Date(),
                status: .sending // Mark as sending during streaming
            )
            chatMessage.messageType = .claudeResponse
            messages.append(chatMessage)
            tableView.reloadData()
            scrollToBottom()
        }
    }
    
    private func handleClaudeCompleteResponse(content: String) {
        // Hide typing indicator
        hideTypingIndicator()
        
        // Check if we have a streaming message to complete
        if let lastMessage = messages.last,
           !lastMessage.isUser,
           lastMessage.messageType == .claudeResponse,
           lastMessage.status == .sending {
            // Complete the streaming message
            if !content.isEmpty {
                lastMessage.content = content // Replace with complete content
            }
            lastMessage.status = .delivered
            
            // Update the cell
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            if let cell = tableView.cellForRow(at: indexPath) as? EnhancedMessageCell {
                cell.configure(with: lastMessage)
            }
        } else {
            // Create new complete message with animation
            let chatMessage = EnhancedChatMessage(
                id: UUID().uuidString,
                content: content,
                isUser: false,
                timestamp: Date(),
                status: .delivered
            )
            chatMessage.messageType = .claudeResponse
            messages.append(chatMessage)
            
            // Insert with animation
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            tableView.insertRows(at: [indexPath], with: .fade)
            
            // Animate the message cell after insertion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                if let cell = self?.tableView.cellForRow(at: indexPath) {
                    // TODO: Add animations when MessageAnimator is added to project
                    // MessageAnimator.animateReceive(view: cell.contentView)
                    // MessageAnimator.addGlowEffect(to: cell.contentView, color: CyberpunkTheme.accentPink)
                }
            }
            
            // Smooth scroll to bottom
            // MessageAnimator.scrollToBottom(tableView: tableView, animated: true)
        // Fallback scroll to bottom
        if tableView.numberOfSections > 0 {
            let lastSection = tableView.numberOfSections - 1
            let lastRow = tableView.numberOfRows(inSection: lastSection) - 1
            if lastRow >= 0 {
                let indexPath = IndexPath(row: lastRow, section: lastSection)
                tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
        }
        
        // Update user message status to delivered
        updateUserMessageStatus(to: .delivered)
    }
    
    private func handleToolUseMessage(message: WebSocketMessage) {
        let payload = message.payload ?? [:]
        let toolName = payload["name"] as? String ?? "Unknown Tool"
        let toolParams = payload["parameters"] as? [String: Any] ?? [:]
        let toolInput = payload["input"] as? String ?? ""
        
        // Format tool use content
        var toolContent = "🔧 Using tool: \(toolName)"
        if !toolInput.isEmpty {
            toolContent += "\n\nInput:\n\(toolInput)"
        }
        if !toolParams.isEmpty {
            let paramsString = toolParams.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
            toolContent += "\n\nParameters:\n\(paramsString)"
        }
        
        let toolMessage = EnhancedChatMessage(
            id: UUID().uuidString,
            content: toolContent,
            isUser: false,
            timestamp: Date(),
            status: .delivered
        )
        toolMessage.messageType = .toolUse
        
        // Store tool data for enhanced display
        // Convert [String: Any] to [String: String] for ToolUseData
        var stringParams: [String: String]? = nil
        if !toolParams.isEmpty {
            stringParams = [:]
            for (key, value) in toolParams {
                stringParams?[key] = String(describing: value)
            }
        }
        
        let toolData = ToolUseData(
            name: toolName,
            parameters: stringParams,
            result: nil,
            status: "executing"
        )
        toolMessage.toolUseData = toolData
        
        messages.append(toolMessage)
        tableView.reloadData()
        scrollToBottom()
    }
    
    private func handleSessionCreated(message: WebSocketMessage) {
        if let sessionId = message.payload?["sessionId"] as? String {
            print("✅ Session created with ID: \(sessionId)")
            
            // Store the session ID
            self.currentSessionId = sessionId
            UserDefaults.standard.set(sessionId, forKey: "currentSessionId_\(self.project.id)")
            
            // Create or update session object
            if currentSession == nil {
                self.currentSession = Session(
                    id: sessionId,
                    projectId: self.project.id,
                    summary: "Chat Session",
                    messageCount: 0,
                    lastActivity: Date(),
                    status: .active
                )
            } else {
                currentSession?.id = sessionId
                currentSession?.status = .active
            }
            
            // Update any pending user messages to sent
            updateUserMessageStatus(to: .sent)
        }
    }
    
    // MARK: - Typing Indicator Management
    
    private func showTypingIndicator() {
        guard !isShowingTypingIndicator else { return }
        isShowingTypingIndicator = true
        
        // Insert typing indicator row
        let indexPath = IndexPath(row: messages.count, section: 0)
        tableView.insertRows(at: [indexPath], with: .fade)
        
        // Scroll to show typing indicator
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.scrollToBottom(animated: true)
        }
    }
    
    private func hideTypingIndicator() {
        guard isShowingTypingIndicator else { return }
        isShowingTypingIndicator = false
        
        // Remove typing indicator row
        let indexPath = IndexPath(row: messages.count, section: 0)
        tableView.deleteRows(at: [indexPath], with: .fade)
    }
    
    // MARK: - Message Status Updates
    
    private func updateUserMessageStatus(to status: MessageStatus) {
        // Find the most recent user message that's in sending state
        for message in messages.reversed() where message.isUser && message.status == .sending {
            message.status = status
            
            // Update the cell if visible
            if let index = messages.firstIndex(where: { $0.id == message.id }) {
                let indexPath = IndexPath(row: index, section: 0)
                if let cell = tableView.cellForRow(at: indexPath) as? EnhancedMessageCell {
                    cell.configure(with: message)
                }
            }
            break // Only update the most recent one
        }
    }
    
    private func updatePendingMessagesToFailed(excludeMessageId: String? = nil) {
        // Only mark messages as failed if they've been sending for too long
        let timeoutInterval: TimeInterval = 30.0 // 30 seconds timeout
        let now = Date()
        
        for message in messages where message.status == .sending {
            // Skip if this is the message we just received a response for
            if let excludeId = excludeMessageId, message.id == excludeId {
                continue
            }
            
            // Only mark as failed if it's been sending for too long
            if now.timeIntervalSince(message.timestamp) > timeoutInterval {
                message.status = .failed
                print("⚠️ [ChatVC] Marking message as failed due to timeout: \(message.id)")
            }
        }
        tableView.reloadData()
    }
    
    private func handleStreamingMessage(_ message: WebSocketMessage) {
        // Handle streaming messages with proper typing indicator management
        // Check if content is nested in 'data' object (for streaming messages from backend)
        let content: String
        if let data = message.payload?["data"] as? [String: Any],
           let nestedContent = data["content"] as? String {
            content = nestedContent
        } else {
            content = message.payload?["content"] as? String ?? ""
        }
        let messageId = message.payload?["messageId"] as? String
        
        // Log the raw message for debugging
        print("📡 Streaming message type: \(message.type), content: \(content)")
        
        // For debugging: show the raw JSON if available
        if let payload = message.payload {
            if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📋 Raw JSON payload:\n\(jsonString)")
            }
        }
        
        switch message.type {
        case .streamStart:
            // Start a new streaming message with unique ID
            let initialContent = content.isEmpty ? "[Streaming response...]" : content
            let chatMessage = EnhancedChatMessage(
                id: messageId ?? UUID().uuidString,
                content: initialContent,
                isUser: false,
                timestamp: Date(),
                status: .sending
            )
            chatMessage.messageType = .claudeResponse
            self.messages.append(chatMessage)
            self.tableView.reloadData()
            self.scrollToBottom()
            
        case .streamChunk:
            // Append to the streaming message
            if let lastMessage = self.messages.last,
               !lastMessage.isUser,
               lastMessage.status == .sending {
                // Append content to existing message
                lastMessage.content += content
                
                // Update only the last cell for performance
                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                if let cell = self.tableView.cellForRow(at: indexPath) as? EnhancedMessageCell {
                    cell.configure(with: lastMessage)
                }
                
                // Auto-scroll only if user is near bottom
                if self.shouldAutoScroll() {
                    self.scrollToBottomDebounced(animated: false)
                }
            }
            
        case .streamEnd:
            // Complete the streaming message
            if let lastMessage = self.messages.last,
               !lastMessage.isUser,
               lastMessage.status == .sending {
                // Add final content if provided
                if !content.isEmpty {
                    lastMessage.content += content
                }
                lastMessage.status = .delivered
                
                // Update the cell
                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                if let cell = self.tableView.cellForRow(at: indexPath) as? EnhancedMessageCell {
                    cell.configure(with: lastMessage)
                }
                
                // Update user message status
                self.updateUserMessageStatus(to: .delivered)
            }
            
        default:
            break
        }
    }
    
    // Helper method to check if scrolled near bottom
    private func isNearBottom() -> Bool {
        let contentHeight = tableView.contentSize.height
        let tableHeight = tableView.frame.height
        let scrollOffset = tableView.contentOffset.y
        
        // Prevent NaN by checking for valid values
        guard contentHeight > 0 && tableHeight > 0 else {
            return true // Consider at bottom if no content
        }
        
        // Handle case where content is smaller than viewport
        if contentHeight <= tableHeight {
            return true // Always at bottom if content fits in view
        }
        
        // Consider "near bottom" if within 100 points of the bottom
        return scrollOffset >= (contentHeight - tableHeight - 100)
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
        
        // Get message and determine cell type
        let message = messages[indexPath.row]
        
        // Select appropriate cell based on message type
        let cellIdentifier: String
        switch message.messageType {
        case .toolUse, .toolResult:
            cellIdentifier = ToolUseMessageCell.identifier
        case .thinking:
            cellIdentifier = ThinkingMessageCell.identifier
        case .code:
            cellIdentifier = CodeMessageCell.identifier
        case .error:
            cellIdentifier = ErrorMessageCell.identifier
        case .system:
            cellIdentifier = SystemMessageCell.identifier
        default:
            cellIdentifier = TextMessageCell.identifier
        }
        
        // Dequeue and configure appropriate cell
        if let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? BaseMessageCell {
            cell.configure(with: message)
            return cell
        } else if message.messageType == .system,
                  let cell = tableView.dequeueReusableCell(withIdentifier: SystemMessageCell.identifier, for: indexPath) as? SystemMessageCell {
            cell.configure(with: message)
            return cell
        } else {
            // Fallback to text cell
            let cell = tableView.dequeueReusableCell(withIdentifier: TextMessageCell.identifier, for: indexPath) as! TextMessageCell
            cell.configure(with: message)
            return cell
        }
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    // MARK: - UITableViewDataSourcePrefetching
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        // Prefetch messages for smooth scrolling
        for indexPath in indexPaths {
            if indexPath.row < messages.count {
                let message = messages[indexPath.row]
                // Pre-calculate any expensive operations here
                // For example, pre-parse code blocks or format timestamps
                message.detectMessageType()
            }
        }
        
        // Check if we need to load more messages (pagination)
        // Using improved threshold of 500 points
        if let maxRow = indexPaths.map({ $0.row }).max(),
           maxRow > messages.count - 10,
           !isLoadingMore,
           hasMoreMessages {
            // Load more messages when approaching the end
            if let sessionId = currentSessionId ?? currentSession?.id {
                loadSessionMessages(sessionId: sessionId, append: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        // Cancel any pending operations for these rows if needed
    }
    
    // MARK: - Pagination Support
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Check if we should load more messages when scrolling to top
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height
        
        // Calculate distance from top
        let distanceFromTop = offsetY
        
        // Log scroll position for debugging (throttled)
        if Int(offsetY) % 50 == 0 {  // Log every 50 points
            print("📜 [ChatVC] Scroll position: offset=\(Int(offsetY)), content=\(Int(contentHeight)), frame=\(Int(frameHeight))")
            print("   Distance from top: \(Int(distanceFromTop))")
            print("   Loading more: \(isLoadingMore), Has more: \(hasMoreMessages)")
        }
        
        // IMPROVED: Load more when scrolled near the top (increased threshold to 500 points for better UX)
        if offsetY < 500 && !isLoadingMore && hasMoreMessages && messages.count >= messagePageSize {
            // Load more historical messages
            if let sessionId = currentSessionId ?? currentSession?.id {
                print("📜 [ChatVC] PAGINATION TRIGGERED - Loading more messages...")
                print("   Current message count: \(messages.count)")
                print("   Offset Y: \(offsetY)")
                loadSessionMessages(sessionId: sessionId, append: true)
            }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Dismiss keyboard when scrolling
        view.endEditing(true)
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
    
    // MARK: - Photo Picker Methods
    
    private func presentPhotoPicker() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(title: "Camera Not Available", message: "Camera is not available on this device")
            return
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true)
    }
    
    // MARK: - PHPickerViewControllerDelegate
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        
        provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error", message: "Failed to load image: \(error.localizedDescription)")
                }
                return
            }
            
            guard let image = image as? UIImage else { return }
            DispatchQueue.main.async {
                self?.handleSelectedImage(image)
            }
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage else { return }
        handleSelectedImage(image)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    // MARK: - Image Handling
    
    private func handleSelectedImage(_ image: UIImage) {
        // For now, just show that we received the image
        // In a real implementation, you would upload this to the server
        let imageData = image.jpegData(compressionQuality: 0.8)
        let sizeInMB = Double(imageData?.count ?? 0) / 1024.0 / 1024.0
        
        let message = String(format: "📸 Image selected (%.2f MB). Upload functionality coming soon!", sizeInMB)
        
        // Create a temporary message to show the image was selected
        let tempMessage = EnhancedChatMessage(
            id: UUID().uuidString,
            content: message,
            isUser: true,
            timestamp: Date(),
            status: .sent
        )
        
        messages.append(tempMessage)
        tableView.reloadData()
        scrollToBottom(animated: true)
        
        // TODO: Implement actual image upload to backend
        print("Image selected with size: \(sizeInMB) MB")
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
