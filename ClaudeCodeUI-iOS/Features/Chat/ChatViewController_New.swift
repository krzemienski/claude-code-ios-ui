//
//  ChatViewController_New.swift
//  ClaudeCodeUI
//
//  Refactored modular version using component architecture
//

import UIKit
import Combine

// MARK: - ChatViewController

/// Streamlined chat controller delegating to specialized components
final class ChatViewController: UIViewController {
    
    // MARK: - UI Components
    
    let tableView = UITableView(frame: .zero, style: .plain)
    let inputBar = ChatInputBar()
    
    // MARK: - Component Handlers
    
    private var viewModel: ChatViewModel!
    private var tableViewHandler: ChatTableViewHandler!
    private var inputHandler: ChatInputHandler!
    private var webSocketCoordinator: ChatWebSocketCoordinator!
    
    // MARK: - Properties
    
    var projectPath: String?
    var sessionId: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("🚀 ChatViewController loading with refactored architecture")
        
        // Initialize all components
        setupComponents()
        
        // Setup UI using the extension we created
        setupUI()
        
        // Start data flow
        startDataFlow()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        connectWebSocket()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            webSocketCoordinator?.disconnect()
        }
    }
    
    // MARK: - Component Setup
    
    private func setupComponents() {
        // Initialize ViewModel
        viewModel = ChatViewModel()
        viewModel.projectPath = projectPath
        viewModel.sessionId = sessionId
        
        // Initialize TableView Handler
        tableViewHandler = ChatTableViewHandler(
            tableView: tableView,
            viewModel: viewModel
        )
        tableViewHandler.navigationDelegate = self
        
        // Initialize Input Handler
        inputHandler = ChatInputHandler(
            inputBar: inputBar,
            viewModel: viewModel
        )
        inputHandler.presentingViewController = self
        
        // Initialize WebSocket Coordinator
        webSocketCoordinator = ChatWebSocketCoordinator(viewModel: viewModel)
        
        print("✅ All components initialized")
    }
    
    // MARK: - Data Flow
    
    private func startDataFlow() {
        // Load existing messages if we have a session
        if let sessionId = sessionId {
            Task {
                await viewModel.loadSessionMessages(sessionId)
                await MainActor.run {
                    tableViewHandler.scrollToBottom(animated: false)
                }
            }
        }
        
        // Setup bindings for UI updates
        setupBindings()
    }
    
    private func setupBindings() {
        // Connection status binding
        viewModel.$connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updateConnectionUI(status)
            }
            .store(in: &cancellables)
        
        // Error handling
        viewModel.$lastError
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - WebSocket Management
    
    private func connectWebSocket() {
        guard let projectPath = projectPath else {
            print("⚠️ No project path set")
            return
        }
        
        webSocketCoordinator.connect(
            projectPath: projectPath,
            sessionId: sessionId
        )
    }
    
    // MARK: - UI Updates
    
    private func updateConnectionUI(_ status: ChatViewModel.ConnectionStatus) {
        // Update navigation bar indicator
        switch status {
        case .connected:
            navigationItem.titleView = createStatusView(color: .systemGreen, text: "Connected")
        case .connecting:
            navigationItem.titleView = createStatusView(color: .systemOrange, text: "Connecting...")
        case .reconnecting:
            navigationItem.titleView = createStatusView(color: .systemOrange, text: "Reconnecting...")
        case .disconnected:
            navigationItem.titleView = createStatusView(color: .systemRed, text: "Disconnected")
        }
    }
    
    private func createStatusView(color: UIColor, text: String) -> UIView {
        let container = UIView()
        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = 4
        dot.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(dot)
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            dot.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            dot.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 8),
            dot.heightAnchor.constraint(equalToConstant: 8),
            
            label.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - ChatNavigationDelegate

extension ChatViewController: ChatNavigationDelegate {
    func navigateToURL(_ url: URL) {
        UIApplication.shared.open(url)
    }
    
    func navigateToUser(_ username: String) {
        print("Navigate to user: \(username)")
    }
    
    func showCodePreview(_ code: String) {
        let preview = SimpleCodePreviewController(code: code)
        let nav = UINavigationController(rootViewController: preview)
        present(nav, animated: true)
    }
}

// MARK: - Simple Code Preview

private class SimpleCodePreviewController: UIViewController {
    private let code: String
    private let textView = UITextView()
    
    init(code: String) {
        self.code = code
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = "Code"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismiss_)
        )
        
        textView.text = code
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func dismiss_() {
        dismiss(animated: true)
    }
}