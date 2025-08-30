//
//  ChatViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/05.
//

import UIKit
import Foundation
import PhotosUI
import SwiftData

// Import types from MessageTypes.swift to avoid redeclaration
// EnhancedMessageCell is defined in EnhancedMessageCell.swift

// ChatMessageCell is defined in Views/ChatMessageCell.swift

// MARK: - Chat View Controller

class ChatViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching, UITextViewDelegate, WebSocketManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    
    // MARK: - Properties
    
    // Debug mode - shows raw JSON responses inline
    private let showRawJSON = false // Set to false in production
    
    // TODO[CM-CHAT-05]: Update connection status UI dynamically
    // ISSUE: Connection status view not reflecting WebSocket state
    // ACCEPTANCE: Shows "Connecting...", "Connected", "Disconnected", "Reconnecting..."
    // PRIORITY: P0 - CRITICAL
    // IMPLEMENTATION: Listen to WebSocketManagerDelegate callbacks
    
    // Connection status UI
    internal let connectionStatusView = UIView()
    internal let connectionStatusLabel = UILabel()
    internal let connectionIndicatorView = UIView()
    internal var connectionStatusHeightConstraint: NSLayoutConstraint!
    
    // Component Integrator - NEW: Manages all 9 refactored components
    private var componentsIntegrator: ChatComponentsIntegrator?
    
    internal let project: Project
    private var currentSession: Session?
    private var messages: [EnhancedChatMessage] = []
    private let webSocketManager: any WebSocketProtocol
    private var isTyping = false
    private var isShowingTypingIndicator = false
    private var keyboardHeight: CGFloat = 0
    private var isLoadingMore = false
    
    // Memory optimization: Limit message history to prevent excessive memory usage
    private let maxMessagesInMemory = 100  // Keep only last 100 messages in memory
    private let messageBatchSize = 50      // Load messages in batches
    private var hasMoreMessages = true
    private let messagePageSize = 50
    private var currentSessionId: String?
    internal let emptyStateView = NoDataView(type: .noMessages)
    
    // UI Components needed by ChatViewSetup - already declared above
    
    // TODO[CM-CHAT-03]: Implement message persistence with SwiftData
    // ISSUE: Messages not saved, lost on app restart
    // ACCEPTANCE: Messages persist using SwiftData, reload on launch
    // PRIORITY: P0 - CRITICAL
    // IMPLEMENTATION:
    //   1. Create MessageEntity SwiftData model
    //   2. Save messages on receive/send
    //   3. Load messages in viewDidLoad
    //   4. Limit to last 100 messages for memory
    
    // Add isLoading property needed by BaseViewController
    public override var isLoading: Bool {
        didSet {
            // Could show/hide loading indicator here if needed
        }
    }
    
    // Streaming message handler
    private let streamingHandler = StreamingMessageHandler()
    private var activeStreamingMessageId: String?
    
    // FIX #1: Per-message status tracking with timers
    private var messageStatusTimers: [String: Timer] = [:]
    private var lastSentMessageId: String?
    
    // TODO[CM-CHAT-01]: Fix message status state machine
    // ISSUE: Status stuck on 'sending', never updates to 'delivered' or 'read'
    // ACCEPTANCE: Status changes: sending → delivered (on WS response) → read (on view)
    // PRIORITY: P0 - CRITICAL
    // BACKEND: Check for status field in WebSocket response
    // IMPLEMENTATION:
    //   1. Track messageId in messageStatusTimers dict
    //   2. On WebSocket response with matching ID, update to 'delivered'
    //   3. On message visible in viewport, update to 'read'
    //   4. Clear timer on status change
    
    // MARK: - UI Components
    
    // Typing indicator for showing when Claude is responding
    private lazy var typingIndicator: UIView = {
        return AnimationManager.shared.createTypingIndicator()
    }()
    
    internal lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.prefetchDataSource = self
        
        // Register only existing cell types - FIX: Non-existent cell classes were causing empty table view
        // Using ChatMessageCell for all message types since other cell classes don't exist
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.identifier)
        
        // These cell classes don't exist in the project - commenting out to fix empty table view issue:
        // tableView.register(TextMessageCell.self, forCellReuseIdentifier: TextMessageCell.identifier)
        // tableView.register(ToolUseMessageCell.self, forCellReuseIdentifier: ToolUseMessageCell.identifier)
        // tableView.register(ThinkingMessageCell.self, forCellReuseIdentifier: ThinkingMessageCell.identifier)
        // tableView.register(CodeMessageCell.self, forCellReuseIdentifier: CodeMessageCell.identifier)
        // tableView.register(ErrorMessageCell.self, forCellReuseIdentifier: ErrorMessageCell.identifier)
        // tableView.register(SystemMessageCell.self, forCellReuseIdentifier: SystemMessageCell.identifier)
        // tableView.register(TypingIndicatorCell.self, forCellReuseIdentifier: TypingIndicatorCell.identifier)
        // tableView.register(EnhancedMessageCell.self, forCellReuseIdentifier: EnhancedMessageCell.identifier)
        
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.keyboardDismissMode = .interactive
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        return tableView
    }()
    
    internal lazy var inputContainerView: UIView = {
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
    
    internal lazy var inputTextView: UITextView = {
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
    
    internal lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Type a message..."
        label.font = CyberpunkTheme.bodyFont
        label.textColor = CyberpunkTheme.secondaryText
        return label
    }()
    
    internal lazy var sendButton: UIButton = {
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
    
    internal lazy var attachButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.tintColor = CyberpunkTheme.primaryCyan
        button.addTarget(self, action: #selector(showAttachmentOptions), for: .touchUpInside)
        return button
    }()
    
    internal var inputContainerBottomConstraint: NSLayoutConstraint!
    internal var inputTextViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Initialization
    
    public init(project: Project, session: Session? = nil) {
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
        print("🚀🚀🚀 ChatViewController.viewDidLoad() started")
        setupUI()
        setupNavigationBar()
        setupKeyboardObservers()
        
        // Initialize the component integrator with all necessary dependencies
        setupComponentIntegrator()
        
        // CM-CHAT-03: Load persisted messages from SwiftData
        loadPersistedMessages()
        
        // TODO[CM-Chat-03]: Add pull-to-refresh with haptic feedback
        // ACCEPTANCE: Cyberpunk-themed refresh control, haptic on trigger
        // PRIORITY: P1
        // DEPENDENCIES: CyberpunkTheme.swift
        // NOTES: Use UIImpactFeedbackGenerator for haptics
        
        // Add memory warning observer for memory optimization
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        // Start the integrated components instead of direct WebSocket connection
        print("🔌 Starting component integrator...")
        componentsIntegrator?.start()
        
        // Load messages through integrator
        if let sessionId = currentSession?.id {
            print("📦 Loading messages for session: \(sessionId)")
            Task {
                await componentsIntegrator?.loadMessages()
            }
        }
        
        print("✅ ChatViewController.viewDidLoad() completed")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Stop the component integrator which handles cleanup
        componentsIntegrator?.stop()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        // Clean up message status timers
        for (_, timer) in messageStatusTimers {
            timer.invalidate()
        }
        messageStatusTimers.removeAll()
        
        // Clean up streaming handler
        Task { @MainActor in
            streamingHandler.reset()
        }
    }
    
    // MARK: - Component Integration
    
    private func setupComponentIntegrator() {
        // Create adapter for existing UI components to work with ChatInputBar protocol
        let inputBarAdapter = ChatInputBarAdapter(
            containerView: inputContainerView,
            inputTextView: inputTextView,
            sendButton: sendButton,
            attachButton: attachButton,
            placeholderLabel: placeholderLabel
        )
        
        // Initialize the component integrator with all dependencies
        componentsIntegrator = ChatComponentsIntegrator(
            viewController: self,
            tableView: tableView,
            inputBar: inputBarAdapter,
            webSocketManager: webSocketManager,
            project: project
        )
        
        print("✅ Component integrator initialized with all 9 components")
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        
        // CM-Chat-03: Pull-to-refresh with haptic feedback
        setupPullToRefresh()
        
        // Setup connection status view
        setupConnectionStatusView()
        
        // Add subviews
        view.addSubview(connectionStatusView)
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(inputContainerView)
        inputContainerView.addSubview(attachButton)
        inputContainerView.addSubview(inputTextView)
        inputContainerView.addSubview(sendButton)
        inputTextView.addSubview(placeholderLabel)
        
        // Configure empty state
        setupEmptyState()
        
        // Setup constraints
        inputContainerBottomConstraint = inputContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        inputTextViewHeightConstraint = inputTextView.heightAnchor.constraint(equalToConstant: 44)
        connectionStatusHeightConstraint = connectionStatusView.heightAnchor.constraint(equalToConstant: 0)
        
        NSLayoutConstraint.activate([
            // Connection status view
            connectionStatusView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            connectionStatusView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            connectionStatusView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            connectionStatusHeightConstraint,
            
            // Table view
            tableView.topAnchor.constraint(equalTo: connectionStatusView.bottomAnchor),
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
            placeholderLabel.centerYAnchor.constraint(equalTo: inputTextView.centerYAnchor),
            
            // Empty state view
            emptyStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor)
        ])
    }
    
    private func setupEmptyState() {
        // NoDataView is already configured with type .noMessages in init
        // No need to configure it again
        emptyStateView.isHidden = true
    }
    
    private func updateEmptyStateVisibility() {
        let shouldShowEmpty = messages.isEmpty && !isLoading && !isLoadingMore
        
        if shouldShowEmpty {
            tableView.isHidden = true
            emptyStateView.isHidden = false
            UIView.animate(withDuration: 0.3) {
                self.emptyStateView.alpha = 1
            }
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.emptyStateView.alpha = 0
            }) { [weak self] _ in
                self?.emptyStateView.isHidden = true
                self?.tableView.isHidden = false
            }
        }
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
    
    private func setupPullToRefresh() {
        // Create and configure refresh control with cyberpunk theme
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = CyberpunkTheme.primaryCyan
        refreshControl.backgroundColor = CyberpunkTheme.surface.withAlphaComponent(0.3)
        
        // Custom attributed title with cyberpunk styling
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: CyberpunkTheme.textSecondary,
            .font: UIFont.systemFont(ofSize: 14, weight: .medium)
        ]
        refreshControl.attributedTitle = NSAttributedString(
            string: "↻ Loading message history...",
            attributes: attributes
        )
        
        // Add target for refresh action
        refreshControl.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        
        // Add to table view
        tableView.refreshControl = refreshControl
        
        // Configure table view for better pull-to-refresh experience
        tableView.alwaysBounceVertical = true
    }
    
    @objc internal func handlePullToRefresh() {
        // Haptic feedback when pull-to-refresh triggers
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        // Update refresh control title
        if let refreshControl = tableView.refreshControl {
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: CyberpunkTheme.primaryCyan,
                .font: UIFont.systemFont(ofSize: 14, weight: .medium)
            ]
            refreshControl.attributedTitle = NSAttributedString(
                string: "⚡ Syncing with backend...",
                attributes: attributes
            )
        }
        
        // Load older messages
        Task { @MainActor in
            do {
                // Calculate offset based on current messages
                let offset = messages.count
                let limit = 50 // Load 50 older messages
                
                guard let sessionId = currentSessionId else {
                    tableView.refreshControl?.endRefreshing()
                    return
                }
                
                let projectName = project.name
                
                // Fetch older messages from API
                let olderMessages = try await APIClient.shared.fetchSessionMessages(
                    projectName: projectName,
                    sessionId: sessionId,
                    limit: limit,
                    offset: offset
                )
                
                // Convert and prepend messages
                if !olderMessages.isEmpty {
                    let convertedMessages = olderMessages.map { message in
                        EnhancedChatMessage(
                            id: message.id,
                            content: message.content,
                            isUser: message.role == .user,
                            timestamp: message.timestamp,
                            status: .delivered
                        )
                    }
                    
                    // Prepend older messages to the beginning
                    messages.insert(contentsOf: convertedMessages, at: 0)
                    
                    // Reload table view while maintaining scroll position
                    let contentOffset = tableView.contentOffset
                    tableView.reloadData()
                    
                    // Calculate new content offset to maintain visual position
                    let newContentHeight = tableView.contentSize.height
                    let heightDifference = newContentHeight - contentOffset.y
                    if heightDifference > 0 {
                        tableView.setContentOffset(
                            CGPoint(x: 0, y: contentOffset.y + heightDifference),
                            animated: false
                        )
                    }
                    
                    // Success haptic feedback
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)
                }
                
                // Update refresh control title for completion
                if let refreshControl = tableView.refreshControl {
                    let attributes: [NSAttributedString.Key: Any] = [
                        .foregroundColor: CyberpunkTheme.success,
                        .font: UIFont.systemFont(ofSize: 14, weight: .medium)
                    ]
                    let messageCount = olderMessages.isEmpty ? "No" : "\(olderMessages.count)"
                    refreshControl.attributedTitle = NSAttributedString(
                        string: "✓ \(messageCount) older messages loaded",
                        attributes: attributes
                    )
                }
                
            } catch {
                // Error haptic feedback
                let errorFeedback = UINotificationFeedbackGenerator()
                errorFeedback.notificationOccurred(.error)
                
                // Update refresh control with error
                if let refreshControl = tableView.refreshControl {
                    let attributes: [NSAttributedString.Key: Any] = [
                        .foregroundColor: CyberpunkTheme.error,
                        .font: UIFont.systemFont(ofSize: 14, weight: .medium)
                    ]
                    refreshControl.attributedTitle = NSAttributedString(
                        string: "✗ Failed to load messages",
                        attributes: attributes
                    )
                }
                
                print("🔴 Failed to load older messages: \(error)")
            }
            
            // End refreshing after a short delay to show the status
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.tableView.refreshControl?.endRefreshing()
                
                // Reset title for next pull
                if let refreshControl = self?.tableView.refreshControl {
                    let attributes: [NSAttributedString.Key: Any] = [
                        .foregroundColor: CyberpunkTheme.textSecondary,
                        .font: UIFont.systemFont(ofSize: 14, weight: .medium)
                    ]
                    refreshControl.attributedTitle = NSAttributedString(
                        string: "↻ Pull to load older messages",
                        attributes: attributes
                    )
                }
            }
        }
    }
    
    private func setupConnectionStatusView() {
        // Configure connection status view
        connectionStatusView.translatesAutoresizingMaskIntoConstraints = false
        connectionStatusView.backgroundColor = CyberpunkTheme.surface
        connectionStatusView.layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor
        connectionStatusView.layer.shadowOpacity = 0.3
        connectionStatusView.layer.shadowOffset = CGSize(width: 0, height: 2)
        connectionStatusView.layer.shadowRadius = 4
        connectionStatusView.clipsToBounds = false
        
        // Configure connection status label
        connectionStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        connectionStatusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        connectionStatusLabel.textColor = CyberpunkTheme.textSecondary
        connectionStatusLabel.textAlignment = .center
        connectionStatusLabel.text = "Connecting..."
        
        // Configure connection indicator (animated dot)
        connectionIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        connectionIndicatorView.backgroundColor = CyberpunkTheme.warning
        connectionIndicatorView.layer.cornerRadius = 4
        connectionIndicatorView.layer.masksToBounds = true
        
        // Add subviews
        connectionStatusView.addSubview(connectionIndicatorView)
        connectionStatusView.addSubview(connectionStatusLabel)
        
        // Setup constraints for internal elements
        NSLayoutConstraint.activate([
            // Indicator view (left side)
            connectionIndicatorView.leadingAnchor.constraint(equalTo: connectionStatusView.leadingAnchor, constant: 16),
            connectionIndicatorView.centerYAnchor.constraint(equalTo: connectionStatusView.centerYAnchor),
            connectionIndicatorView.widthAnchor.constraint(equalToConstant: 8),
            connectionIndicatorView.heightAnchor.constraint(equalToConstant: 8),
            
            // Status label (center)
            connectionStatusLabel.leadingAnchor.constraint(equalTo: connectionIndicatorView.trailingAnchor, constant: 8),
            connectionStatusLabel.trailingAnchor.constraint(equalTo: connectionStatusView.trailingAnchor, constant: -16),
            connectionStatusLabel.centerYAnchor.constraint(equalTo: connectionStatusView.centerYAnchor)
        ])
        
        // Start with hidden status bar
        connectionStatusView.alpha = 0
    }
    
    private func showConnectionStatus(_ status: String, isConnected: Bool) {
        // Update the label text
        connectionStatusLabel.text = status
        
        // Update indicator color based on connection state
        let indicatorColor = isConnected ? CyberpunkTheme.success : CyberpunkTheme.warning
        connectionIndicatorView.backgroundColor = indicatorColor
        
        // Add pulsing animation to indicator
        if !isConnected {
            // Use AnimationManager for neon pulse effect
            AnimationManager.shared.neonPulse(connectionIndicatorView, color: CyberpunkTheme.warning)
        } else {
            // Remove pulsing animation when connected and add success pulse
            connectionIndicatorView.layer.removeAllAnimations()
            AnimationManager.shared.scaleSpring(connectionIndicatorView, scale: 1.2, duration: 0.4)
        }
        
        // Animate the status bar appearance
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            self.connectionStatusView.alpha = 1.0
            
            // Add glow effect
            self.connectionStatusView.layer.shadowOpacity = isConnected ? 0.5 : 0.8
            self.connectionStatusView.layer.shadowColor = indicatorColor.cgColor
        })
    }
    
    private func hideConnectionStatus() {
        // Animate the status bar disappearance
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn], animations: {
            self.connectionStatusView.alpha = 0
            self.connectionStatusView.layer.shadowOpacity = 0
        }) { _ in
            // Remove any animations after hiding
            self.connectionIndicatorView.layer.removeAllAnimations()
        }
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
    
    // WebSocket connection is now handled by ChatComponentsIntegrator
    // which is initialized in setupComponentIntegrator() and started in viewDidLoad()
    
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
            updateEmptyStateVisibility()
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
                    self.updateEmptyStateVisibility()
                    
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
    
    // MARK: - Memory Management
    
    private func trimMessageHistory() {
        // Keep only the most recent messages to prevent memory bloat
        if messages.count > maxMessagesInMemory {
            let trimCount = messages.count - maxMessagesInMemory
            messages.removeFirst(trimCount)
            
            // Reload table to reflect trimmed messages
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
            
            logInfo("Trimmed \(trimCount) old messages to manage memory", category: "Memory")
        }
    }
    
    private func clearOldMessageData() {
        // Clear image cache and other heavy resources from old messages
        for (index, message) in messages.enumerated() {
            if index < messages.count - 50 {  // Keep only last 50 messages fully loaded
                // Clear any heavy resources (future: images, attachments, etc.)
                message.toolUseData = nil
                message.todos = nil
            }
        }
    }
    
    @objc private func handleMemoryWarning() {
        logWarning("⚠️ Received memory warning - clearing caches", category: "Memory")
        
        // Aggressively trim message history
        if messages.count > 50 {
            let keepCount = 30  // Keep only last 30 messages during memory pressure
            let trimCount = messages.count - keepCount
            messages.removeFirst(trimCount)
            
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
            
            logInfo("Emergency trimmed \(trimCount) messages due to memory pressure", category: "Memory")
        }
        
        // Clear all heavy resources
        clearOldMessageData()
        
        // Clear image cache if available
        URLCache.shared.removeAllCachedResponses()
        
        // Force garbage collection by clearing any temporary data
        activeStreamingMessageId = nil
        scrollWorkItem?.cancel()
        scrollWorkItem = nil
    }
    
    // FIX #1: Update message status with per-message timer tracking
    private func updateMessageStatus(messageId: String, to status: MessageStatus) {
        print("\n🔄 [UPDATE_STATUS] Starting at \(Date().ISO8601Format())")
        print("📊 [UPDATE_STATUS] Message ID: \(messageId)")
        print("🎯 [UPDATE_STATUS] Target status: \(status)")
        
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else {
            print("⚠️ [UPDATE_STATUS] Message \(messageId) not found in array at \(Date().ISO8601Format())")
            return
        }
        
        let oldStatus = messages[index].status
        print("🔄 [UPDATE_STATUS] Status transition: \(oldStatus) → \(status) at \(Date().ISO8601Format())")
        messages[index].status = status
        
        // Cancel timer if message succeeded
        if status == .delivered || status == .read || status == .failed {
            print("⏹️ [UPDATE_STATUS] Canceling timer for message \(messageId) at \(Date().ISO8601Format())")
            messageStatusTimers[messageId]?.invalidate()
            messageStatusTimers.removeValue(forKey: messageId)
            print("✅ [UPDATE_STATUS] Timer canceled and removed")
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let indexPath = IndexPath(row: index, section: 0)
            print("📱 [UPDATE_STATUS] Updating UI cell at row \(index) at \(Date().ISO8601Format())")
            if let cell = self.tableView.cellForRow(at: indexPath) as? BaseMessageCell {
                cell.updateStatus(status)
                print("✅ [UPDATE_STATUS] Cell updated successfully")
            } else {
                print("⚠️ [UPDATE_STATUS] Cell not found or wrong type at row \(index)")
            }
        }
        print("================================================\n")
    }
    
    // FIX #1: Start timeout timer for message delivery confirmation
    private func startMessageStatusTimer(for messageId: String) {
        print("\n⏱️ [STATUS_TIMER] Starting timer for message \(messageId) at \(Date().ISO8601Format())")
        
        // Cancel any existing timer
        if messageStatusTimers[messageId] != nil {
            print("🔄 [STATUS_TIMER] Canceling existing timer for message \(messageId)")
            messageStatusTimers[messageId]?.invalidate()
        }
        
        // Start new timer - 30 seconds timeout
        print("⏲️ [STATUS_TIMER] Creating 30-second timeout timer at \(Date().ISO8601Format())")
        let timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            print("⚠️ [STATUS_TIMER] Timeout reached for message \(messageId) at \(Date().ISO8601Format())")
            self?.updateMessageStatus(messageId: messageId, to: .failed)
            self?.messageStatusTimers.removeValue(forKey: messageId)
        }
        
        messageStatusTimers[messageId] = timer
        print("✅ [STATUS_TIMER] Timer started and tracking \(messageStatusTimers.count) active timers")
        print("================================================\n")
    }
    
    @objc private func sendMessage() {
        // TODO[CM-CHAT-02]: Fix message status updates not showing in UI
        // ACCEPTANCE: Messages show sending → sent → delivered status with icons
        // PRIORITY: P1  
        // DEPENDENCIES: StreamingMessageHandler.updateMessageStatus(), MessageCell.updateStatusIcon()
        // NOTES: Track individual message status, update cells when backend confirms delivery
        
        print("\n🚀🚀🚀 [SEND_MESSAGE] Starting at \(Date().ISO8601Format())")
        print("📤📤📤 sendMessage() called")
        
        // CRITICAL DEBUG: Check inputTextView content before trimming
        print("🔍🔍🔍 [INPUT_DEBUG] Raw inputTextView.text:")
        if let rawText = inputTextView.text {
            print("  Length: \(rawText.count)")
            print("  Content: '\(rawText)'")
            print("  First 50 chars: '\(String(rawText.prefix(50)))'")
            print("  Last 50 chars: '\(String(rawText.suffix(50)))'")
        } else {
            print("  inputTextView.text is nil!")
        }
        
        guard let text = inputTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { 
            print("❌ [SEND_MESSAGE] Empty text, aborting at \(Date().ISO8601Format())")
            return 
        }
        
        print("📝 [SEND_MESSAGE] Trimmed text content: '\(text)' at \(Date().ISO8601Format())")
        print("📁 [SEND_MESSAGE] Project: \(project.name) at path: \(project.path)")
        print("🔑 [SEND_MESSAGE] Project ID: \(project.id)")
        
        // Log timestamp for debugging
        let timestamp = Date()
        print("⏰ [SEND_MESSAGE] Timestamp: \(timestamp.ISO8601Format())")
        print("   Unix time: \(timestamp.timeIntervalSince1970)")
        print("   Message: \(text)")
        print("   Project: \(project.name) at \(project.path)")
        
        // Create user message with unique ID
        let messageId = UUID().uuidString
        print("🆔 [SEND_MESSAGE] Creating message with ID: \(messageId) at \(Date().ISO8601Format())")
        let userMessage = EnhancedChatMessage(
            id: messageId,
            content: text,
            isUser: true,
            timestamp: timestamp,
            status: .sending
        )
        print("💬 [SEND_MESSAGE] Message created:")
        print("   ID: \(messageId)")
        print("   Status: \(userMessage.status)")
        print("   IsUser: \(userMessage.isUser)")
        print("   Content length: \(text.count) chars")
        
        // FIX #1: Track this message ID for status updates
        print("📌 [SEND_MESSAGE] Setting lastSentMessageId: \(messageId) at \(Date().ISO8601Format())")
        lastSentMessageId = messageId
        
        // FIX #1: Start per-message status timer
        print("⏱️ [SEND_MESSAGE] Starting status timer for message \(messageId) at \(Date().ISO8601Format())")
        startMessageStatusTimer(for: messageId)
        
        // CM-CHAT-03: Save message to SwiftData for persistence
        Task { @MainActor in
            do {
                guard let sessionId = self.currentSessionId else {
                    print("⚠️ [PERSISTENCE] No session ID available")
                    return
                }
                let container = SwiftDataContainer.shared
                if let session = try container.container.mainContext.fetch(
                    FetchDescriptor<Session>(
                        predicate: #Predicate { $0.id == sessionId }
                    )
                ).first {
                    _ = try container.createMessage(for: session, role: .user, content: userMessage.content)
                    print("💾 [PERSISTENCE] Saved user message to SwiftData")
                }
            } catch {
                print("❌ [PERSISTENCE] Failed to save message: \(error)")
            }
        }
        
        // Add to messages array with animation
        print("➕ [SEND_MESSAGE] Adding message to array at \(Date().ISO8601Format())")
        messages.append(userMessage)
        print("📊 [SEND_MESSAGE] Total messages now: \(messages.count)")
        
        // Memory management: Trim history if needed
        print("🧹 [SEND_MESSAGE] Performing memory management at \(Date().ISO8601Format())")
        trimMessageHistory()
        clearOldMessageData()
        print("✅ [SEND_MESSAGE] Memory management complete")
        
        // Insert with animation
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        print("📋 [SEND_MESSAGE] Inserting row at index \(indexPath.row) at \(Date().ISO8601Format())")
        tableView.insertRows(at: [indexPath], with: .fade)
        print("✅ [SEND_MESSAGE] Row inserted successfully")
        
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
        print("🧹 [SEND_MESSAGE] Clearing input field at \(Date().ISO8601Format())")
        inputTextView.text = ""
        placeholderLabel.isHidden = false
        sendButton.isEnabled = false
        print("✅ [SEND_MESSAGE] Input cleared and UI updated")
        
        // Adjust text view height back to default
        inputTextViewHeightConstraint.constant = 44
        view.layoutIfNeeded()
        
        // Use component integrator to send the message
        // The integrator handles WebSocket communication, message formatting, and coordination
        print("📡 [SEND_MESSAGE] Sending via component integrator at \(Date().ISO8601Format())")
        componentsIntegrator?.sendMessage(text)
        
        Logger.shared.info("✅ [ChatVC] Message sent through component integrator", category: "ChatVC")
        Logger.shared.info("   Original text: \(text)", category: "ChatVC")
        Logger.shared.info("   Text length: \(text.count) chars", category: "ChatVC")
        Logger.shared.info("   Project path: \(project.path)", category: "ChatVC")
        
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
        
        print("✅ [SEND_MESSAGE] Complete at \(Date().ISO8601Format())")
        print("📤 [ChatVC] sendMessage END - \(Date().timeIntervalSince1970)")
        print("================================================\n")
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
    
    @objc internal func showFileExplorer() {
        // Navigate to file explorer
        let fileExplorerVC = FileExplorerViewController(project: project)
        navigationController?.pushViewController(fileExplorerVC, animated: true)
    }
    
    @objc internal func showTerminal() {
        // Navigate to terminal
        let terminalVC = TerminalViewController(project: project)
        navigationController?.pushViewController(terminalVC, animated: true)
    }
    
    @objc internal func abortSession() {
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
        if let message = messages.first(where: { $0.id == messageId && $0.status == MessageStatus.sending }) {
            message.status = MessageStatus.delivered
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
        print("✅✅✅ WebSocketDidConnect delegate method called!")
        print("   WebSocket is now CONNECTED")
        print("   Manager: \(type(of: manager))")
        updateConnectionStatus("Connected", color: UIColor.systemGreen)
        
        // FIX #3 (CM-CHAT-05): Update connection status UI immediately
        // Update connection status view
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update connection status bar with proper state
            self.connectionStatusLabel.text = "Connected"
            self.connectionIndicatorView.backgroundColor = UIColor.systemGreen
            self.showConnectionStatus("Connected", isConnected: true)
            
            // Update navigation bar indicator
            self.updateNavigationStatusIndicator(isConnected: true, isConnecting: false)
            
            // Hide the status bar after 3 seconds if connected
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.hideConnectionStatus()
            }
            
            // Remove any connection error messages
            self.messages.removeAll { $0.id == "connection-status" || $0.id == "websocket-warning" }
            self.tableView.reloadData()
            
            // Load persisted messages when connection is established
            self.loadPersistedMessages()
        }
    }
    
    func webSocketDidDisconnect(_ manager: any WebSocketProtocol, error: Error?) {
        let errorMessage = error?.localizedDescription ?? "Connection closed"
        print("❌❌❌ WebSocketDidDisconnect delegate method called!")
        print("   Error: \(errorMessage)")
        print("   Manager: \(type(of: manager))")
        updateConnectionStatus("Disconnected: \(errorMessage)", color: UIColor.systemRed)
        
        // FIX #3 (CM-CHAT-05): Update connection status UI immediately
        // Update connection status view
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update connection status bar with proper state
            self.connectionStatusLabel.text = "Disconnected - Reconnecting..."
            self.connectionIndicatorView.backgroundColor = UIColor.systemRed
            self.showConnectionStatus("Disconnected - Reconnecting...", isConnected: false)
            
            // Update navigation bar indicator
            self.updateNavigationStatusIndicator(isConnected: false, isConnecting: false)
            
            // Show disconnection status as a message
            let disconnectionMessage = EnhancedChatMessage(
                id: "connection-error-\(Date().timeIntervalSince1970)",
                content: "🔴 Disconnected - Check backend on localhost:3004",
                isUser: false,
                timestamp: Date()
            )
            self.messages.append(disconnectionMessage)
            self.tableView.reloadData()
            
            // Show network error alert with retry option
            self.showNetworkError(
                message: "WebSocket connection lost. The app will automatically reconnect when the backend is available.",
                retryAction: { [weak self] in
                    // Force reconnection attempt
                    guard let self = self else { return }
                    let wsURL = AppConfig.websocketURL
                    let token = UserDefaults.standard.string(forKey: "authToken")
                    self.webSocketManager.connect(to: wsURL, with: token)
                }
            )
        }
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveMessage message: WebSocketMessage) {
        print("\n📥📥📥 [WS_RECEIVE] Message received at \(Date().ISO8601Format())")
        print("📨 [WS_RECEIVE] Message details:")
        print("   Unix timestamp: \(Date().timeIntervalSince1970)")
        print("   Type: \(message.type)")
        print("   Session ID: \(message.sessionId ?? "nil")")
        
        // Log payload summary (avoid logging huge content)
        if let payload = message.payload {
            if let content = payload["content"] as? String {
                let preview = String(content.prefix(100))
                print("   Content preview: \(preview)...")
            }
            print("   Payload keys: \(payload.keys.joined(separator: ", "))")
            
            // FIX #1 (CM-CHAT-01): Update message status to delivered when response received
            // Check if this is a response to our last sent message
            if let messageId = payload["replyToMessageId"] as? String ?? lastSentMessageId,
               !messageId.isEmpty {
                print("✅ [WS_RECEIVE] Updating message \(messageId) status to delivered")
                updateMessageStatus(messageId: messageId, to: .delivered)
                // Clear last sent message ID
                if messageId == lastSentMessageId {
                    lastSentMessageId = nil
                }
                
                // Update to read after a short delay (simulating the message being viewed)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.updateMessageStatus(messageId: messageId, to: .read)
                }
            }
        }
        
        // Handle the message based on its type
        print("🎯 [WS_RECEIVE] Routing to handleWebSocketMessage at \(Date().ISO8601Format())")
        handleWebSocketMessage(message)
        print("================================================\n")
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveData data: Data) {
        print("📦 WebSocket received data: \(data.count) bytes")
        // Handle raw data if needed
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveText text: String) {
        print("📝📝📝 WebSocket received raw text!")
        print("   Text length: \(text.count) characters")
        print("   Text preview: \(text.prefix(200))...")
        
        // Try to parse as JSON for Claude responses
        if let data = text.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            print("   ✅ Successfully parsed as JSON")
            if let type = json["type"] as? String {
                print("   Message type: \(type)")
            }
            if let content = json["content"] as? String {
                print("   Content preview: \(content.prefix(100))...")
            }
        } else {
            print("   ⚠️ Could not parse as JSON, might be plain text response")
        }
    }
    
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState) {
        print("🔄🔄🔄 WebSocketConnectionStateChanged called!")
        print("   New state: \(state)")
        
        // FIX #3 (CM-CHAT-05): Update connection status UI for all state changes
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Log state transition for debugging
            switch state {
            case .disconnected:
                print("   📵 State = DISCONNECTED")
                self.connectionStatusLabel.text = "Disconnected"
                self.connectionIndicatorView.backgroundColor = UIColor.systemRed
                self.showConnectionStatus("Disconnected", isConnected: false)
                self.updateNavigationStatusIndicator(isConnected: false, isConnecting: false)
            case .connecting:
                print("   🔄 State = CONNECTING...")
                self.connectionStatusLabel.text = "Connecting..."
                self.connectionIndicatorView.backgroundColor = UIColor.systemOrange
                self.showConnectionStatus("Connecting...", isConnected: false)
                self.updateNavigationStatusIndicator(isConnected: false, isConnecting: true)
            case .connected:
                print("   ✅ State = CONNECTED")
                self.connectionStatusLabel.text = "Connected"
                self.connectionIndicatorView.backgroundColor = UIColor.systemGreen
                self.showConnectionStatus("Connected", isConnected: true)
                self.updateNavigationStatusIndicator(isConnected: true, isConnecting: false)
                // Hide after 3 seconds when connected
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                    self?.hideConnectionStatus()
                }
            case .reconnecting:
                print("   🔁 State = RECONNECTING...")
                self.connectionStatusLabel.text = "Reconnecting..."
                self.connectionIndicatorView.backgroundColor = UIColor.systemOrange
                self.showConnectionStatus("Reconnecting...", isConnected: false)
                self.updateNavigationStatusIndicator(isConnected: false, isConnecting: true)
            case .failed:
                print("   ❌ State = FAILED")
                self.connectionStatusLabel.text = "Connection Failed"
                self.connectionIndicatorView.backgroundColor = UIColor.systemRed
                self.showConnectionStatus("Connection Failed", isConnected: false)
                self.updateNavigationStatusIndicator(isConnected: false, isConnecting: false)
            }
        }
    }
    
    // CM-CHAT-03: Load persisted messages from SwiftData
    private func loadPersistedMessages() {
        Task { @MainActor in
            do {
                guard let sessionId = self.currentSessionId else {
                    print("⚠️ [PERSISTENCE] No session ID available for loading messages")
                    return
                }
                let container = SwiftDataContainer.shared
                let descriptor = FetchDescriptor<Session>(
                    predicate: #Predicate { $0.id == sessionId }
                )
                
                guard let session = try container.container.mainContext.fetch(descriptor).first else {
                    print("⚠️ [PERSISTENCE] Session not found in SwiftData: \(sessionId)")
                    return
                }
                
                let messages = try container.fetchMessages(for: session)
                print("💾 [PERSISTENCE] Loaded \(messages.count) persisted messages")
                
                // Convert SwiftData Messages to EnhancedChatMessages
                for message in messages.sortedByTimestamp() {
                    let chatMessage = EnhancedChatMessage(
                        id: message.id,
                        content: message.content,
                        isUser: message.role.isUser,
                        timestamp: message.timestamp,
                        status: .delivered  // Persisted messages are delivered
                    )
                    chatMessage.detectMessageType()
                    self.messages.append(chatMessage)
                }
                
                // Reload table view
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    if !self.messages.isEmpty {
                        let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
                    }
                }
            } catch {
                print("❌ [PERSISTENCE] Failed to load persisted messages: \(error)")
            }
        }
    }
    
    // CM-CHAT-05: Add connection status indicator to navigation bar
    private func updateNavigationStatusIndicator(isConnected: Bool, isConnecting: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Create status indicator view
            let statusView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
            statusView.layer.cornerRadius = 5
            statusView.clipsToBounds = true
            
            // Set color based on connection state
            if isConnected {
                statusView.backgroundColor = CyberpunkTheme.success // Green for connected
            } else if isConnecting {
                statusView.backgroundColor = .systemOrange // Orange for connecting/reconnecting
                
                // Add pulsing animation for connecting state
                let pulseAnimation = CABasicAnimation(keyPath: "opacity")
                pulseAnimation.fromValue = 1.0
                pulseAnimation.toValue = 0.3
                pulseAnimation.duration = 0.8
                pulseAnimation.autoreverses = true
                pulseAnimation.repeatCount = .infinity
                statusView.layer.add(pulseAnimation, forKey: "pulse")
            } else {
                statusView.backgroundColor = CyberpunkTheme.accentPink // Red for disconnected/failed
            }
            
            // Add glow effect
            statusView.layer.shadowColor = statusView.backgroundColor?.cgColor
            statusView.layer.shadowOffset = .zero
            statusView.layer.shadowRadius = 5
            statusView.layer.shadowOpacity = 0.8
            
            // Create bar button item with the status indicator
            let statusBarItem = UIBarButtonItem(customView: statusView)
            
            // Get existing right bar items
            var rightItems = self.navigationItem.rightBarButtonItems ?? []
            
            // Remove any existing status indicator (first item if it's a view)
            if let firstItem = rightItems.first,
               firstItem.customView != nil,
               firstItem.customView?.frame.width == 10 {
                rightItems.removeFirst()
            }
            
            // Insert status indicator at the beginning
            rightItems.insert(statusBarItem, at: 0)
            self.navigationItem.rightBarButtonItems = rightItems
        }
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
        print("\n🎯 [HANDLE_WS] Processing message at \(Date().ISO8601Format())")
        // TODO[CM-Chat-01]: Add real-time message status indicators - IMPLEMENTED ✅
        // Using MessageStatusManager for robust status tracking
        
        // Process different message types
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Log raw message for debugging
            print("📦 [HANDLE_WS] Message type: \(message.type) at \(Date().ISO8601Format())")
            if let payload = message.payload,
               let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📋 Raw JSON payload:\n\(jsonString)")
            }
            
            // Early filtering for metadata messages
            // This happens BEFORE content extraction to avoid processing empty messages
            if message.type == .claudeResponse {
                // First, try to get content from various possible locations
                var preliminaryContent: String? = nil
                
                if let directContent = message.payload?["content"] as? String, !directContent.isEmpty {
                    preliminaryContent = directContent
                } else if let data = message.payload?["data"] as? [String: Any] {
                    if let nestedContent = data["content"] as? String, !nestedContent.isEmpty {
                        preliminaryContent = nestedContent
                    } else if let nestedMessage = data["message"] as? String, !nestedMessage.isEmpty {
                        preliminaryContent = nestedMessage
                    } else if let messageDict = data["message"] as? [String: Any],
                              let contentArray = messageDict["content"] as? [[String: Any]] {
                        // Handle Claude API response structure: data.message.content[{type: 'text', text: '...'}]
                        let textParts = contentArray.compactMap { item -> String? in
                            if let type = item["type"] as? String, type == "text",
                               let text = item["text"] as? String {
                                return text
                            }
                            return nil
                        }
                        preliminaryContent = textParts.joined(separator: "\n")
                    }
                } else if let messageText = message.payload?["message"] as? String, !messageText.isEmpty {
                    preliminaryContent = messageText
                } else if let text = message.payload?["text"] as? String, !text.isEmpty {
                    preliminaryContent = text
                }
                
                // Check if we have content to evaluate
                if let content = preliminaryContent {
                    // CM-CHAT-02: FIXED - More lenient assistant message filtering
                    // Only filter out truly empty messages or pure session ID strings
                    // Allow all legitimate assistant responses including those with UUIDs
                    
                    let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Very strict filtering - only skip if:
                    // 1. Content is completely empty
                    // 2. Content is EXACTLY a session ID (format: "session_" followed by UUID)
                    let isEmpty = trimmedContent.isEmpty
                    
                    // Check if it's exactly a session ID using regex pattern
                    let sessionIdPattern = "^session_[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
                    let isExactSessionId = trimmedContent.range(of: sessionIdPattern, options: .regularExpression) != nil && trimmedContent.count == 45 // "session_" (8) + UUID (36) + "-" (1) = 45
                    
                    if isEmpty {
                        print("🚫 [ChatVC] Skipping empty message at \(Date().timeIntervalSince1970)")
                        return
                    }
                    
                    if isExactSessionId {
                        print("🚫 [ChatVC] Skipping pure session ID metadata at \(Date().timeIntervalSince1970)")
                        return
                    }
                    
                    // Log that we're allowing this assistant response
                    print("✅ [ChatVC] Processing assistant response at \(Date().timeIntervalSince1970)")
                    print("   Content length: \(content.count) chars")
                    print("   Content preview: \(content.prefix(100))...")
                } else {
                    // No content found at all - skip this empty message
                    print("⚠️ [ChatVC] Skipping empty claude-response message at \(Date().timeIntervalSince1970)")
                    return
                }
            }
            
            // ✅ COMPLETED[CM-Chat-02]: Implement typing indicator animation
            // IMPLEMENTATION: Created TypingIndicatorCell with animated dots
            // - TypingIndicatorView provides the animated UI component
            // - TypingIndicatorCell integrates with UITableView
            // - Animation starts/stops via willDisplay/didEndDisplaying delegate methods
            // - Triggered by showTypingIndicator()/hideTypingIndicator() on WebSocket events
            
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
                } else if let messageDict = data["message"] as? [String: Any],
                          let contentArray = messageDict["content"] as? [[String: Any]] {
                    // Handle Claude API response structure: data.message.content[{type: 'text', text: '...'}]
                    let textParts = contentArray.compactMap { item -> String? in
                        if let type = item["type"] as? String, type == "text",
                           let text = item["text"] as? String {
                            return text
                        }
                        return nil
                    }
                    content = textParts.joined(separator: "\n")
                    print("📊 [HANDLE_WS] Extracted text from Claude API structure: \(content.prefix(100))...")
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
            
            print("🔀 [HANDLE_WS] Entering switch statement at \(Date().ISO8601Format())")
            switch message.type {
            case .claudeOutput:
                // Handle streaming Claude output (partial responses)
                print("🌊 [HANDLE_WS] Case: claudeOutput at \(Date().ISO8601Format())")
                print("   Content chunk length: \(content.count) chars")
                print("   Last sent message ID: \(self.lastSentMessageId ?? "none")")
                
                // In debug mode, show what type of stream we're getting
                if self.showRawJSON && !content.isEmpty {
                    print("   Streaming chunk preview: \(content.prefix(100))...")
                }
                
                // FIX #2: Mark user message as delivered when we start receiving stream
                if let lastMessageId = self.lastSentMessageId {
                    print("📡 [HANDLE_WS] Streaming started, updating message status at \(Date().ISO8601Format())")
                    print("   📊 Message ID: \(lastMessageId)")
                    print("   🎯 New status: delivered")
                    self.updateMessageStatus(messageId: lastMessageId, to: .delivered)
                    print("   ✅ Status update triggered")
                } else {
                    print("⚠️ [HANDLE_WS] No lastSentMessageId to update at \(Date().ISO8601Format())")
                }
                
                self.handleClaudeStreamingOutput(content: content)
                
            case .claudeResponse:
                // Handle complete Claude response
                var displayContent = content
                
                print("🤖 [HANDLE_WS] Case: claudeResponse at \(Date().ISO8601Format())")
                print("   Content length: \(content.count) chars")
                print("   Last sent message ID: \(self.lastSentMessageId ?? "none")")
                
                // FIX #2: Mark the last sent message as delivered
                if let lastMessageId = self.lastSentMessageId {
                    print("🎯 [HANDLE_WS] Complete response received at \(Date().ISO8601Format())")
                    print("   📊 Message ID to update: \(lastMessageId)")
                    self.updateMessageStatus(messageId: lastMessageId, to: .delivered)
                    print("   ✅ Delivery status applied")
                    self.lastSentMessageId = nil // Clear after processing
                } else {
                    print("⚠️ [HANDLE_WS] No pending message to mark as delivered at \(Date().ISO8601Format())")
                }
                
                // Add raw JSON in debug mode (show the entire payload for debugging)
                if self.showRawJSON,
                   let payload = message.payload,
                   let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    displayContent = "\(content)\n\n🔍 Debug - Raw Response:\n```json\n\(jsonString)\n```"
                }
                
                self.handleClaudeCompleteResponse(content: displayContent)
                
                // CM-CHAT-03: Save assistant message to SwiftData for persistence
                Task { @MainActor in
                    do {
                        guard let sessionId = self.currentSessionId else {
                            print("⚠️ [PERSISTENCE] No session ID available for saving assistant message")
                            return
                        }
                        let container = SwiftDataContainer.shared
                        if let session = try container.container.mainContext.fetch(
                            FetchDescriptor<Session>(
                                predicate: #Predicate { $0.id == sessionId }
                            )
                        ).first {
                            _ = try container.createMessage(for: session, role: .assistant, content: displayContent)
                            print("💾 [PERSISTENCE] Saved assistant message to SwiftData")
                        }
                    } catch {
                        print("❌ [PERSISTENCE] Failed to save assistant message: \(error)")
                    }
                }
                
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
                    if let cell = self.tableView.cellForRow(at: indexPath) as? BaseMessageCell {
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
        print("\n🌊 [STREAMING_OUTPUT] Starting at \(Date().ISO8601Format())")
        print("📝 [STREAMING_OUTPUT] Content length: \(content.count) chars")
        print("📊 [STREAMING_OUTPUT] Content preview: \(String(content.prefix(100)))...")
        
        // Skip empty streaming content
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ [STREAMING_OUTPUT] Skipping empty streaming content at \(Date().ISO8601Format())")
            return
        }
        print("✅ [STREAMING_OUTPUT] Content validated at \(Date().ISO8601Format())")
        
        // Process through streaming handler
        print("🔄 [STREAMING_OUTPUT] Processing through handler at \(Date().ISO8601Format())")
        let streamingMessageId = activeStreamingMessageId ?? UUID().uuidString
        if activeStreamingMessageId == nil {
            activeStreamingMessageId = streamingMessageId
        }
        // Process the streaming chunk (void function)
        streamingHandler.processStreamingChunk(content, for: streamingMessageId)
        
        print("🔄 [STREAMING_OUTPUT] Processing chunk at \(Date().ISO8601Format())")
        print("   📊 Message ID: \(streamingMessageId)")
        print("   📝 Content length: \(content.count) chars")
        
        // Find or create message
        print("🔍 [STREAMING_OUTPUT] Looking for existing message at \(Date().ISO8601Format())")
        if let existingIndex = messages.firstIndex(where: { $0.id == streamingMessageId }) {
            print("✅ [STREAMING_OUTPUT] Found existing message at index \(existingIndex) at \(Date().ISO8601Format())")
            // Update existing message
            let message = messages[existingIndex]
            print("📝 [STREAMING_OUTPUT] Appending content to message")
            message.content += content
            
            // Detect and update message type
            let structured = streamingHandler.extractStructuredContent(from: message.content)
            // For now, keep message type as text - we'd need additional logic to detect specific types
            message.messageType = .text
            
            // Check for completion markers in the content
            let isComplete = content.contains("[DONE]") || content.contains("</response>")
            if isComplete {
                print("✅ [STREAMING_OUTPUT] Stream complete, marking delivered at \(Date().ISO8601Format())")
                message.status = MessageStatus.delivered
                activeStreamingMessageId = nil
                print("🔄 [STREAMING_OUTPUT] Hiding typing indicator at \(Date().ISO8601Format())")
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
            print("🆕 [STREAMING_OUTPUT] Creating new streaming message at \(Date().ISO8601Format())")
            // Create new streaming message
            print("🔄 [STREAMING_OUTPUT] Showing typing indicator at \(Date().ISO8601Format())")
            showTypingIndicator()
            let chatMessage = EnhancedChatMessage(
                id: streamingMessageId,
                content: content,
                isUser: false,
                timestamp: Date(),
                status: .sending
            )
            
            // Set message type
            let structured = streamingHandler.extractStructuredContent(from: content)
            // For now, keep message type as text - we'd need additional logic to detect specific types
            chatMessage.messageType = .text
            
            messages.append(chatMessage)
            activeStreamingMessageId = streamingMessageId
            
            // Insert with animation
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            tableView.insertRows(at: [indexPath], with: .fade)
            
            // Check for completion markers
            let isComplete = content.contains("[DONE]") || content.contains("</response>")
            if isComplete {
                activeStreamingMessageId = nil
                hideTypingIndicator()
            }
            
            // Auto-scroll only if user is near bottom
            if shouldAutoScroll() {
                scrollToBottomDebounced(animated: false)
            }
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
        print("\n🤖🤖🤖 [COMPLETE_RESPONSE] Starting at \(Date().ISO8601Format())")
        print("📝 [COMPLETE_RESPONSE] Content length: \(content.count) chars")
        print("📊 [COMPLETE_RESPONSE] Content preview: \(String(content.prefix(200)))...")
        print("⏱️ [COMPLETE_RESPONSE] Timestamp: \(Date().timeIntervalSince1970)")
        print("\n🔍🔍🔍 DEBUG - Messages array BEFORE adding response:")
        print("   Total messages: \(messages.count)")
        for (index, msg) in messages.enumerated() {
            print("   [\(index)]: role=\(msg.isUser ? "user" : "assistant"), status=\(msg.status), content=\(msg.content.prefix(50))...")
        }
        
        // Skip empty responses entirely
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ [COMPLETE_RESPONSE] Skipping empty response at \(Date().ISO8601Format())")
            print("🔄 [COMPLETE_RESPONSE] Hiding typing indicator due to empty response")
            hideTypingIndicator()
            return
        }
        print("✅ [COMPLETE_RESPONSE] Content validated, not empty at \(Date().ISO8601Format())")
        
        // Hide typing indicator
        print("🔄 [COMPLETE_RESPONSE] Hiding typing indicator at \(Date().ISO8601Format())")
        hideTypingIndicator()
        
        // Mark user message as delivered since we got a response
        print("🔍 [COMPLETE_RESPONSE] Looking for pending user message at \(Date().ISO8601Format())")
        // FIX: Find the most recent user message with 'sending' status instead of relying on lastSentMessageId
        if let pendingMessage = messages.last(where: { $0.isUser && $0.status == .sending }) {
            let messageId = pendingMessage.id
            print("✅ [COMPLETE_RESPONSE] Found pending message: \(messageId) at \(Date().ISO8601Format())")
            updateUserMessageStatus(to: .delivered, messageId: messageId)
            print("   ✅ Marked user message \(messageId) as delivered")
            // Update the message directly as well
            pendingMessage.status = .delivered
        } else if let messageId = lastSentMessageId {
            // Fallback to lastSentMessageId if no pending message found
            updateUserMessageStatus(to: .delivered, messageId: messageId)
            print("   ✅ Marked user message \(messageId) as delivered (using lastSentMessageId)")
            lastSentMessageId = nil
        }
        
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
            if let cell = tableView.cellForRow(at: indexPath) as? BaseMessageCell {
                cell.configure(with: lastMessage)
            }
            print("   Updated existing streaming message")
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
            
            print("\n➕ DEBUG - Adding new Claude message:")
            print("   ID: \(chatMessage.id)")
            print("   Content: \(chatMessage.content.prefix(100))...")
            print("   Status: \(chatMessage.status)")
            print("   Messages count before: \(messages.count)")
            
            messages.append(chatMessage)
            
            print("   Messages count after: \(messages.count)")
            print("   Table view sections: \(tableView.numberOfSections)")
            print("   Table view rows before reload: \(tableView.numberOfRows(inSection: 0))")
            
            // Reload the table view to show the new message
            tableView.reloadData()
            
            print("   ✅ Reloaded table view")
            print("   Table view rows after reload: \(tableView.numberOfRows(inSection: 0))")
            
            // Animate the message cell after insertion
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
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
        print("\n🔧 [TOOL_USE] Starting at \(Date().ISO8601Format())")
        let payload = message.payload ?? [:]
        let toolName = payload["name"] as? String ?? "Unknown Tool"
        let toolParams = payload["parameters"] as? [String: Any] ?? [:]
        let toolInput = payload["input"] as? String ?? ""
        print("📝 [TOOL_USE] Tool name: \(toolName)")
        print("📊 [TOOL_USE] Parameters count: \(toolParams.count)")
        print("📝 [TOOL_USE] Input length: \(toolInput.count) chars")
        
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
        print("\n🆕 [SESSION_CREATED] Starting at \(Date().ISO8601Format())")
        if let sessionId = message.payload?["sessionId"] as? String {
            print("✅ [SESSION_CREATED] Session created with ID: \(sessionId) at \(Date().ISO8601Format())")
            print("📝 [SESSION_CREATED] Session ID length: \(sessionId.count) chars")
            
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
    
    // Note: lastSentMessageId and messageStatusTimers are already declared at line 408-409
    
    private func updateUserMessageStatus(to status: MessageStatus, messageId: String? = nil) {
        // Use MessageStatusManager for centralized tracking
        let targetMessageId = messageId ?? lastSentMessageId
        
        // If specific message ID provided, update that message
        if let targetMessageId = targetMessageId {
            // Update via MessageStatusManager with proper tracking
            MessageStatusManager.shared.updateStatus(for: targetMessageId, to: status) { [weak self] success in
                guard let self = self, success else { return }
                
                // Update local message model
                if let index = self.messages.firstIndex(where: { $0.id == targetMessageId }) {
                    self.messages[index].status = status
                    
                    // Update the cell if visible
                    DispatchQueue.main.async {
                        let indexPath = IndexPath(row: index, section: 0)
                        if let cell = self.tableView.cellForRow(at: indexPath) as? BaseMessageCell {
                            cell.updateStatusIcon(status)
                        }
                    }
                    
                    print("✅ [ChatVC] Updated message \(targetMessageId) status to: \(status) via MessageStatusManager")
                }
            }
            
            // Cancel local timer if message succeeded (backup cleanup)
            if status == .delivered || status == .read || status == .failed {
                messageStatusTimers[targetMessageId]?.invalidate()
                messageStatusTimers.removeValue(forKey: targetMessageId)
            }
            return
        }
        
        // Fallback: Find the most recent user message that's in sending state
        for message in messages.reversed() where message.isUser && (message.status == .sending || message.status == .sent) {
            // Update via MessageStatusManager
            MessageStatusManager.shared.updateStatus(for: message.id, to: status) { [weak self] success in
                guard let self = self, success else { return }
                
                // Update local model
                message.status = status
                
                // Update the cell if visible
                if let index = self.messages.firstIndex(where: { $0.id == message.id }) {
                    DispatchQueue.main.async {
                        let indexPath = IndexPath(row: index, section: 0)
                        if let cell = self.tableView.cellForRow(at: indexPath) as? BaseMessageCell {
                            cell.updateStatusIcon(status)
                        }
                    }
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
                message.status = MessageStatus.failed
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
            // Mark user message as delivered when streaming starts
            // FIX: Find pending message first, then fallback to lastSentMessageId
            if let pendingMessage = self.messages.last(where: { $0.isUser && $0.status == .sending }) {
                let userMessageId = pendingMessage.id
                MessageStatusManager.shared.markAsDelivered(userMessageId)
                self.updateUserMessageStatus(to: .delivered, messageId: userMessageId)
                pendingMessage.status = .delivered
                print("✅ [Streaming] Marked user message \(userMessageId) as delivered on stream start")
                // Don't clear lastSentMessageId yet - might be needed for other updates
            } else if let userMessageId = self.lastSentMessageId {
                MessageStatusManager.shared.markAsDelivered(userMessageId)
                self.updateUserMessageStatus(to: .delivered, messageId: userMessageId)
                print("✅ [Streaming] Marked user message \(userMessageId) as delivered on stream start (using lastSentMessageId)")
            }
            
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
                if let cell = self.tableView.cellForRow(at: indexPath) as? BaseMessageCell {
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
                if let cell = self.tableView.cellForRow(at: indexPath) as? BaseMessageCell {
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
        print("🔢 DEBUG - numberOfRowsInSection called: messages=\(messages.count), typingIndicator=\(isShowingTypingIndicator), returning=\(count)")
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("📱 DEBUG - cellForRowAt called: row=\(indexPath.row), messages.count=\(messages.count), typingIndicator=\(isShowingTypingIndicator)")
        
        // Show typing indicator if it's the last row
        if isShowingTypingIndicator && indexPath.row == messages.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: TypingIndicatorCell.identifier, for: indexPath)
            // Add pulse animation to typing indicator
            AnimationManager.shared.pulse(cell, scale: 1.02, duration: 0.8)
            return cell
        }
        
        // Get message and determine cell type
        guard indexPath.row < messages.count else {
            print("⚠️ DEBUG - Index out of bounds: row=\(indexPath.row), messages.count=\(messages.count)")
            return UITableViewCell()
        }
        
        let message = messages[indexPath.row]
        print("   Message at row \(indexPath.row): isUser=\(message.isUser), type=\(message.messageType), content=\(message.content.prefix(50))...")
        
        // FIX: Use ChatMessageCell for all message types since other cell classes don't exist
        // This was causing the empty table view issue - dequeueReusableCell was failing for non-existent cells
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatMessageCell.identifier, for: indexPath) as! ChatMessageCell
        cell.configure(with: message)
        
        // Set retry handler for failed messages if needed
        // Note: ChatMessageCell may not have onRetryTapped property - will need to check
        if message.isUser && message.status == .failed {
            // TODO: Implement retry functionality in ChatMessageCell if needed
            // cell.onRetryTapped = { [weak self] in
            //     self?.retryFailedMessage(at: indexPath)
            // }
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    // MARK: - Swipe Actions for Message Retry
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Only allow editing for failed user messages
        guard indexPath.row < messages.count else { return false }
        let message = messages[indexPath.row]
        return message.isUser && message.status == .failed
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row < messages.count else { return nil }
        let message = messages[indexPath.row]
        
        // Only show retry action for failed user messages
        guard message.isUser && message.status == .failed else { return nil }
        
        // Create retry action
        let retryAction = UIContextualAction(style: .normal, title: "Retry") { [weak self] _, _, completion in
            self?.retryFailedMessage(at: indexPath)
            completion(true)
        }
        retryAction.backgroundColor = CyberpunkTheme.primaryCyan
        retryAction.image = UIImage(systemName: "arrow.clockwise")
        
        // Create delete action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.deleteMessage(at: indexPath)
            completion(true)
        }
        deleteAction.backgroundColor = CyberpunkTheme.accentPink
        deleteAction.image = UIImage(systemName: "trash")
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, retryAction])
        configuration.performsFirstActionWithFullSwipe = false // Prevent accidental deletion
        return configuration
    }
    
    private func retryFailedMessage(at indexPath: IndexPath) {
        guard indexPath.row < messages.count else { return }
        let message = messages[indexPath.row]
        
        logInfo("🔄 Retrying failed message: \(message.id)", category: "Retry")
        
        // Reset message status to sending
        message.status = MessageStatus.sending
        
        // Update the cell
        if let cell = tableView.cellForRow(at: indexPath) as? BaseMessageCell {
            cell.updateStatusIcon(.sending)
        }
        
        // Resend the message
        let messageContent = message.content
        
        // Create message payload for resend
        let messageId = message.id // Keep the same ID for tracking
        lastSentMessageId = messageId
        
        // Start status timer for retry
        // TODO: Implement message status timer
        // startMessageStatusTimer(for: messageId)
        
        // Send via WebSocket with CORRECT format
        let messageDict: [String: Any] = [
            "type": "claude-command",
            "command": messageContent,  // ✅ FIXED: Using 'command' as backend expects
            "projectPath": project.fullPath,  // ✅ FIXED: At top level, not nested
            "sessionId": currentSessionId ?? ""  // ✅ FIXED: At top level, not nested
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: messageDict),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            webSocketManager.send(jsonString)
        }
        
        // Haptic feedback for retry
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)
        
        logInfo("✅ Message retry initiated", category: "Retry")
    }
    
    private func deleteMessage(at indexPath: IndexPath) {
        guard indexPath.row < messages.count else { return }
        
        // Remove message from array
        let deletedMessage = messages.remove(at: indexPath.row)
        
        // Delete row with animation
        tableView.deleteRows(at: [indexPath], with: .fade)
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        logInfo("🗑️ Deleted message: \(deletedMessage.id)", category: "Delete")
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Start typing indicator animation when cell becomes visible
        if let typingCell = cell as? TypingIndicatorCell {
            typingCell.startAnimating()
            print("🔄 Started typing indicator animation")
        } else {
            // Add entrance animation for message cells
            // Only animate new messages (last 3 rows)
            let rowsFromBottom = messages.count - indexPath.row
            if rowsFromBottom <= 3 {
                // Slide in from right with fade
                cell.alpha = 0
                cell.transform = CGAffineTransform(translationX: tableView.bounds.width * 0.3, y: 0)
                
                UIView.animate(withDuration: 0.3, 
                              delay: 0.05 * Double(3 - rowsFromBottom),
                              usingSpringWithDamping: 0.8,
                              initialSpringVelocity: 0.5,
                              options: .curveEaseOut,
                              animations: {
                    cell.alpha = 1
                    cell.transform = .identity
                })
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Stop typing indicator animation when cell goes off-screen
        if let typingCell = cell as? TypingIndicatorCell {
            typingCell.stopAnimating()
            print("⏹️ Stopped typing indicator animation")
        }
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
