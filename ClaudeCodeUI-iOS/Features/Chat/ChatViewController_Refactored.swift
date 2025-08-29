//
//  ChatViewController.swift (Refactored)
//  ClaudeCodeUI
//
//  Refactored on 2025-01-21 to be under 500 lines
//

import UIKit
import Foundation
import PhotosUI
import SwiftData

// MARK: - Chat View Controller (Refactored)

class ChatViewController: BaseViewController {
    
    // MARK: - Properties
    
    // Core dependencies
    private(set) var project: Project
    private var viewModel: ChatViewModel!
    private var tableViewHandler: ChatTableViewHandler!
    private var inputHandler: ChatInputHandler!
    private var webSocketCoordinator: ChatWebSocketCoordinator!
    
    // UI Components (created in ChatViewSetup.swift)
    private(set) lazy var tableView = createTableView()
    private(set) lazy var inputContainerView = createInputContainerView()
    private(set) lazy var inputTextView = createInputTextView()
    private(set) lazy var sendButton = createSendButton()
    private(set) lazy var attachButton = createAttachButton()
    private(set) lazy var placeholderLabel = createPlaceholderLabel()
    private(set) lazy var connectionStatusView = createConnectionStatusView()
    private(set) lazy var connectionStatusLabel = createConnectionStatusLabel()
    private(set) lazy var connectionIndicatorView = createConnectionIndicatorView()
    private(set) lazy var typingIndicator = createTypingIndicator()
    
    // Constraints
    private(set) var inputContainerBottomConstraint: NSLayoutConstraint!
    private(set) var inputTextViewHeightConstraint: NSLayoutConstraint!
    private(set) var connectionStatusHeightConstraint: NSLayoutConstraint!
    
    // State
    private let emptyStateView = NoDataView(type: .noMessages)
    private let streamingHandler = StreamingMessageHandler()
    
    // Required by BaseViewController
    public override var isLoading: Bool {
        didSet {
            updateEmptyStateVisibility()
        }
    }
    
    // MARK: - Initialization
    
    public init(project: Project, session: Session? = nil) {
        self.project = project
        super.init(nibName: nil, bundle: nil)
        
        // Initialize view model
        let webSocketManager = DIContainer.shared.webSocketManager
        self.viewModel = ChatViewModel(
            project: project,
            session: session,
            webSocketManager: webSocketManager
        )
        
        // Initialize coordinators and handlers after view model
        self.webSocketCoordinator = ChatWebSocketCoordinator(
            webSocketManager: webSocketManager,
            streamingHandler: streamingHandler,
            project: project
        )
        
        self.tableViewHandler = ChatTableViewHandler(
            tableView: tableView,
            viewModel: viewModel,
            streamingHandler: streamingHandler
        )
        
        self.inputHandler = ChatInputHandler(
            inputContainerView: inputContainerView,
            inputTextView: inputTextView,
            sendButton: sendButton,
            attachButton: attachButton,
            placeholderLabel: placeholderLabel
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🚀 ChatViewController.viewDidLoad() started")
        
        // Setup UI (from ChatViewSetup.swift)
        setupMainLayout()
        setupConstraints()
        setupNavigationItems()
        setupRefreshControl()
        
        // Configure delegates
        configureDelegates()
        
        // Configure empty state
        emptyStateView.isHidden = true
        
        // Connect WebSocket
        webSocketCoordinator.connect()
        
        // Load initial data
        loadInitialMessages()
        
        // Setup observers
        setupObservers()
        
        print("✅ ChatViewController.viewDidLoad() completed")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webSocketCoordinator.disconnect()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func configureDelegates() {
        webSocketCoordinator.delegate = self
        inputHandler.delegate = self
        inputHandler.viewController = self
        tableViewHandler.viewController = self
        
        // Set input handler constraints
        inputHandler.setConstraints(
            bottomConstraint: inputContainerBottomConstraint,
            heightConstraint: inputTextViewHeightConstraint
        )
    }
    
    private func setupObservers() {
        // Memory warning observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    // MARK: - Data Loading
    
    private func loadInitialMessages() {
        Task { @MainActor in
            isLoading = true
            await viewModel.loadInitialMessages()
            isLoading = false
            
            tableViewHandler.reloadData()
            updateEmptyStateVisibility()
            
            if !viewModel.messages.isEmpty {
                tableViewHandler.scrollToBottom(animated: false)
            }
        }
    }
    
    @objc private func handlePullToRefresh() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        // Update refresh control
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
        
        // Load more messages
        Task { @MainActor in
            let newMessages = await viewModel.loadMoreMessages(offset: viewModel.messages.count)
            
            if !newMessages.isEmpty {
                // Calculate content offset to maintain position
                let contentOffset = tableView.contentOffset
                tableViewHandler.reloadData()
                
                // Maintain scroll position
                if newMessages.count > 0 {
                    let indexPath = IndexPath(row: newMessages.count, section: 0)
                    tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                }
            }
            
            tableView.refreshControl?.endRefreshing()
        }
    }
    
    // MARK: - Navigation Actions
    
    @objc private func showFileExplorer() {
        let fileExplorer = FileExplorerViewController(project: project)
        navigationController?.pushViewController(fileExplorer, animated: true)
    }
    
    @objc private func showTerminal() {
        let terminal = TerminalViewController(project: project)
        navigationController?.pushViewController(terminal, animated: true)
    }
    
    @objc private func abortSession() {
        let alert = UIAlertController(
            title: "Abort Session?",
            message: "This will stop the current conversation. Are you sure?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Abort", style: .destructive) { [weak self] _ in
            self?.webSocketCoordinator.disconnect()
            self?.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Memory Management
    
    @objc private func handleMemoryWarning() {
        viewModel.handleMemoryWarning()
        tableViewHandler.reloadData()
    }
    
    // MARK: - Empty State
    
    private func updateEmptyStateVisibility() {
        let shouldShowEmpty = viewModel.messages.isEmpty && !isLoading
        
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
}

// MARK: - ChatInputHandlerDelegate

extension ChatViewController: ChatInputHandlerDelegate {
    
    func inputHandler(_ handler: ChatInputHandler, didSendMessage message: String) {
        // Send via view model
        viewModel.sendMessage(message)
        
        // Update UI
        tableViewHandler.reloadData()
        
        // Scroll to bottom
        if tableViewHandler.isNearBottom() {
            tableViewHandler.scrollToBottom()
        }
    }
    
    func inputHandler(_ handler: ChatInputHandler, didSelectImage image: UIImage) {
        // Handle image selection
        // TODO: Implement image upload
        print("📷 Image selected for upload")
    }
    
    func inputHandlerDidRequestAttachment(_ handler: ChatInputHandler) {
        // Show attachment options
        let actionSheet = UIAlertController(title: "Add Attachment", message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
            handler.presentImagePicker()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
            handler.presentCamera()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = attachButton
            popover.sourceRect = attachButton.bounds
        }
        
        present(actionSheet, animated: true)
    }
}

// MARK: - ChatWebSocketCoordinatorDelegate

extension ChatViewController: ChatWebSocketCoordinatorDelegate {
    
    func coordinatorDidConnect(_ coordinator: ChatWebSocketCoordinator) {
        viewModel.updateConnectionStatus(.connected)
        updateConnectionStatusUI(status: .connected)
    }
    
    func coordinatorDidDisconnect(_ coordinator: ChatWebSocketCoordinator, error: Error?) {
        let status: ChatViewModel.ConnectionStatus = error != nil ? .error(error!.localizedDescription) : .disconnected
        viewModel.updateConnectionStatus(status)
        updateConnectionStatusUI(status: status)
    }
    
    func coordinator(_ coordinator: ChatWebSocketCoordinator, didReceiveMessage message: String, messageId: String?) {
        // Add message to view model
        viewModel.addIncomingMessage(message, messageId: messageId)
        
        // Update UI
        let wasNearBottom = tableViewHandler.isNearBottom()
        tableViewHandler.reloadData()
        
        if wasNearBottom {
            tableViewHandler.scrollToBottom()
        }
    }
    
    func coordinator(_ coordinator: ChatWebSocketCoordinator, didReceiveStreamingChunk chunk: String, messageId: String, isComplete: Bool) {
        // Handle streaming chunks
        // Update existing message or create new one
        if let index = viewModel.messages.firstIndex(where: { $0.id == messageId }) {
            viewModel.messages[index].content += chunk
            tableViewHandler.reloadMessage(at: index)
        } else {
            viewModel.addIncomingMessage(chunk, messageId: messageId)
            tableViewHandler.reloadData()
        }
        
        if isComplete {
            // Mark as delivered
            viewModel.updateMessageStatus(messageId, status: .delivered)
        }
    }
    
    func coordinator(_ coordinator: ChatWebSocketCoordinator, didReceiveTypingIndicator isTyping: Bool) {
        // Handle typing indicator
        if isTyping {
            typingIndicator.isHidden = false
            typingIndicator.alpha = 1
        } else {
            UIView.animate(withDuration: 0.3) {
                self.typingIndicator.alpha = 0
            } completion: { _ in
                self.typingIndicator.isHidden = true
            }
        }
    }
    
    func coordinator(_ coordinator: ChatWebSocketCoordinator, didReceiveError error: String) {
        // Show error alert
        let alert = UIAlertController(
            title: "Error",
            message: error,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func coordinatorDidStartReconnecting(_ coordinator: ChatWebSocketCoordinator) {
        viewModel.updateConnectionStatus(.reconnecting)
        updateConnectionStatusUI(status: .reconnecting)
    }
}

// MARK: - Connection Status UI

extension ChatViewController {
    
    private func updateConnectionStatusUI(status: ChatViewModel.ConnectionStatus) {
        switch status {
        case .connected:
            connectionStatusLabel.text = "Connected"
            connectionIndicatorView.backgroundColor = .systemGreen
            hideConnectionStatus()
            
        case .connecting:
            connectionStatusLabel.text = "Connecting..."
            connectionIndicatorView.backgroundColor = .systemOrange
            showConnectionStatus()
            
        case .disconnected:
            connectionStatusLabel.text = "Disconnected"
            connectionIndicatorView.backgroundColor = .systemRed
            showConnectionStatus()
            
        case .reconnecting:
            connectionStatusLabel.text = "Reconnecting..."
            connectionIndicatorView.backgroundColor = .systemOrange
            showConnectionStatus()
            
        case .error(let message):
            connectionStatusLabel.text = "Error: \(message)"
            connectionIndicatorView.backgroundColor = .systemRed
            showConnectionStatus()
        }
    }
    
    private func showConnectionStatus() {
        guard connectionStatusView.alpha == 0 else { return }
        
        UIView.animate(withDuration: 0.3) {
            self.connectionStatusHeightConstraint.constant = 30
            self.connectionStatusView.alpha = 1
            self.view.layoutIfNeeded()
        }
    }
    
    private func hideConnectionStatus() {
        guard connectionStatusView.alpha == 1 else { return }
        
        UIView.animate(withDuration: 0.3, delay: 2.0, options: [], animations: {
            self.connectionStatusHeightConstraint.constant = 0
            self.connectionStatusView.alpha = 0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}

// MARK: - Factory Methods for UI Components

extension ChatViewController {
    
    private func createTableView() -> UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = CyberpunkTheme.background
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }
    
    private func createInputContainerView() -> UIView {
        let view = UIView()
        view.backgroundColor = CyberpunkTheme.surface
        view.layer.borderWidth = 1
        view.layer.borderColor = CyberpunkTheme.border.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
    
    private func createInputTextView() -> UITextView {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.font = .systemFont(ofSize: 16)
        textView.textColor = CyberpunkTheme.textPrimary
        textView.isScrollEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }
    
    private func createSendButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        button.tintColor = CyberpunkTheme.primaryCyan
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    private func createAttachButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.tintColor = CyberpunkTheme.textSecondary
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    private func createPlaceholderLabel() -> UILabel {
        let label = UILabel()
        label.text = "Type a message..."
        label.font = .systemFont(ofSize: 16)
        label.textColor = CyberpunkTheme.textSecondary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func createConnectionStatusView() -> UIView {
        let view = UIView()
        view.backgroundColor = CyberpunkTheme.surface
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        return view
    }
    
    private func createConnectionStatusLabel() -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = CyberpunkTheme.textSecondary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func createConnectionIndicatorView() -> UIView {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
    
    private func createTypingIndicator() -> UIView {
        let view = UIView()
        view.backgroundColor = CyberpunkTheme.surface
        view.layer.cornerRadius = 12
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // Add typing dots
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        for _ in 0..<3 {
            let dot = UIView()
            dot.backgroundColor = CyberpunkTheme.accentPink
            dot.layer.cornerRadius = 3
            dot.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: 6),
                dot.heightAnchor.constraint(equalToConstant: 6)
            ])
            stackView.addArrangedSubview(dot)
        }
        
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
    }
}

// MARK: - Layout Setup

extension ChatViewController {
    
    private func setupMainLayout() {
        view.backgroundColor = CyberpunkTheme.background
        
        // Add all subviews
        view.addSubview(tableView)
        view.addSubview(inputContainerView)
        view.addSubview(connectionStatusView)
        view.addSubview(emptyStateView)
        view.addSubview(typingIndicator)
        
        // Add input components to container
        inputContainerView.addSubview(attachButton)
        inputContainerView.addSubview(inputTextView)
        inputContainerView.addSubview(sendButton)
        inputContainerView.addSubview(placeholderLabel)
        
        // Add connection status components
        connectionStatusView.addSubview(connectionIndicatorView)
        connectionStatusView.addSubview(connectionStatusLabel)
    }
    
    private func setupConstraints() {
        // Create constraints
        inputContainerBottomConstraint = inputContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        inputTextViewHeightConstraint = inputTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        connectionStatusHeightConstraint = connectionStatusView.heightAnchor.constraint(equalToConstant: 0)
        
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
            
            // Connection status
            connectionStatusView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            connectionStatusView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            connectionStatusView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            connectionStatusHeightConstraint,
            
            // Connection indicator
            connectionIndicatorView.leadingAnchor.constraint(equalTo: connectionStatusView.leadingAnchor, constant: 12),
            connectionIndicatorView.centerYAnchor.constraint(equalTo: connectionStatusView.centerYAnchor),
            connectionIndicatorView.widthAnchor.constraint(equalToConstant: 8),
            connectionIndicatorView.heightAnchor.constraint(equalToConstant: 8),
            
            // Connection label
            connectionStatusLabel.leadingAnchor.constraint(equalTo: connectionIndicatorView.trailingAnchor, constant: 8),
            connectionStatusLabel.centerYAnchor.constraint(equalTo: connectionStatusView.centerYAnchor),
            
            // Input components
            attachButton.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 12),
            attachButton.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -12),
            attachButton.widthAnchor.constraint(equalToConstant: 32),
            attachButton.heightAnchor.constraint(equalToConstant: 32),
            
            inputTextView.leadingAnchor.constraint(equalTo: attachButton.trailingAnchor, constant: 8),
            inputTextView.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 8),
            inputTextView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -8),
            inputTextViewHeightConstraint,
            
            sendButton.leadingAnchor.constraint(equalTo: inputTextView.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -12),
            sendButton.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -12),
            sendButton.widthAnchor.constraint(equalToConstant: 32),
            sendButton.heightAnchor.constraint(equalToConstant: 32),
            
            // Placeholder
            placeholderLabel.leadingAnchor.constraint(equalTo: inputTextView.leadingAnchor, constant: 5),
            placeholderLabel.topAnchor.constraint(equalTo: inputTextView.topAnchor, constant: 8),
            
            // Empty state
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            emptyStateView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            // Typing indicator
            typingIndicator.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            typingIndicator.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: -8),
            typingIndicator.widthAnchor.constraint(equalToConstant: 60),
            typingIndicator.heightAnchor.constraint(equalToConstant: 28)
        ])
    }
    
    private func setupNavigationItems() {
        title = project.name
        
        // Right bar buttons
        let fileButton = UIBarButtonItem(
            image: UIImage(systemName: "folder"),
            style: .plain,
            target: self,
            action: #selector(showFileExplorer)
        )
        
        let terminalButton = UIBarButtonItem(
            image: UIImage(systemName: "terminal"),
            style: .plain,
            target: self,
            action: #selector(showTerminal)
        )
        
        let abortButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark.circle"),
            style: .plain,
            target: self,
            action: #selector(abortSession)
        )
        abortButton.tintColor = CyberpunkTheme.error
        
        navigationItem.rightBarButtonItems = [abortButton, terminalButton, fileButton]
    }
    
    private func setupRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = CyberpunkTheme.primaryCyan
        refreshControl.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
}