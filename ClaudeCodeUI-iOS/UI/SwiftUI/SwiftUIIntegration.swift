//
//  SwiftUIIntegration.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-14.
//

import UIKit
import SwiftUI

// MARK: - UIHostingController Extensions
extension UIViewController {
    
    /// Embeds a SwiftUI view in a UIViewController
    func embedSwiftUIView<Content: View>(
        _ swiftUIView: Content,
        in containerView: UIView? = nil
    ) -> UIHostingController<Content> {
        let hostingController = UIHostingController(rootView: swiftUIView)
        
        // Add as child view controller
        addChild(hostingController)
        
        // Configure hosting controller view
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        
        // Add to container or main view
        let targetView = containerView ?? view!
        targetView.addSubview(hostingController.view)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: targetView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: targetView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: targetView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: targetView.bottomAnchor)
        ])
        
        hostingController.didMove(toParent: self)
        
        return hostingController
    }
    
    /// Removes a SwiftUI hosting controller
    func removeSwiftUIView<Content: View>(_ hostingController: UIHostingController<Content>) {
        hostingController.willMove(toParent: nil)
        hostingController.view.removeFromSuperview()
        hostingController.removeFromParent()
    }
}

// MARK: - Enhanced Session List ViewController
public class EnhancedSessionListViewController: BaseViewController {
    // MARK: - Properties
    private let project: Project
    private var hostingController: UIHostingController<SessionListView>?
    
    // MARK: - Initialization
    init(project: Project) {
        self.project = project
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        title = "Sessions"
        
        // Create SwiftUI SessionListView
        let sessionListView = SessionListView(
            project: project,
            onSessionSelected: { [weak self] session in
                self?.navigateToChat(with: session)
            },
            onCreateSession: { [weak self] in
                self?.createNewSession()
            }
        )
        
        // Embed SwiftUI view
        hostingController = embedSwiftUIView(sessionListView)
    }
    
    // MARK: - Navigation
    private func navigateToChat(with session: Session) {
        let chatVC = ChatViewController(project: project, session: session)
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    private func createNewSession() {
        Task {
            do {
                let newSession = try await APIClient.shared.createSession(projectName: project.name)
                let chatVC = ChatViewController(project: project, session: newSession)
                navigationController?.pushViewController(chatVC, animated: true)
            } catch {
                showError(error)
            }
        }
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

// MARK: - Enhanced Chat View with SwiftUI Messages
public class EnhancedChatViewController: BaseViewController {
    // MARK: - Properties
    private let project: Project
    private let session: Session?
    private var messages: [Message] = []
    private var messagesHostingController: UIHostingController<ChatMessagesView>?
    private let inputField = UITextField()
    private let sendButton = UIButton(type: .system)
    
    // MARK: - Initialization
    init(project: Project, session: Session? = nil) {
        self.project = project
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMessages()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        title = session?.summary ?? "New Chat"
        
        // Container for messages
        let messagesContainer = UIView()
        messagesContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(messagesContainer)
        
        // Input container
        let inputContainer = createInputContainer()
        view.addSubview(inputContainer)
        
        // Layout
        NSLayoutConstraint.activate([
            messagesContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            messagesContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messagesContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messagesContainer.bottomAnchor.constraint(equalTo: inputContainer.topAnchor),
            
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            inputContainer.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        // Embed SwiftUI messages view
        let chatMessagesView = ChatMessagesView(
            messages: messages,
            onRetry: { [weak self] message in
                self?.retryMessage(message)
            },
            onDelete: { [weak self] message in
                self?.deleteMessage(message)
            }
        )
        
        messagesHostingController = embedSwiftUIView(chatMessagesView, in: messagesContainer)
    }
    
    private func createInputContainer() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor(red: 0.03, green: 0.03, blue: 0.07, alpha: 1.0)
        
        // Setup input field
        inputField.placeholder = "Type a message..."
        inputField.textColor = .white
        inputField.tintColor = UIColor(red: 0, green: 0.85, blue: 1, alpha: 1.0)
        inputField.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        inputField.layer.cornerRadius = 20
        inputField.layer.borderWidth = 1
        inputField.layer.borderColor = UIColor(red: 0, green: 0.85, blue: 1, alpha: 0.3).cgColor
        inputField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        inputField.leftViewMode = .always
        inputField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        inputField.rightViewMode = .always
        inputField.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup send button
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        sendButton.tintColor = UIColor(red: 1, green: 0, blue: 0.43, alpha: 1.0)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        
        container.addSubview(inputField)
        container.addSubview(sendButton)
        
        NSLayoutConstraint.activate([
            inputField.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            inputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            inputField.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            inputField.heightAnchor.constraint(equalToConstant: 44),
            
            sendButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 44),
            sendButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return container
    }
    
    // MARK: - Actions
    @objc private func sendMessage() {
        guard let text = inputField.text, !text.isEmpty else { return }
        
        let newMessage = Message(
            id: UUID().uuidString,
            sessionId: session?.id ?? "default",
            content: text,
            role: .user,
            timestamp: Date()
        )
        
        messages.append(newMessage)
        updateMessagesView()
        inputField.text = ""
        
        // Send via WebSocket
        // WebSocketManager.shared.sendMessage(...)
    }
    
    private func loadMessages() {
        // Load messages from session
        // This would normally fetch from API
    }
    
    private func updateMessagesView() {
        // Update SwiftUI view with new messages
        messagesHostingController?.rootView = ChatMessagesView(
            messages: messages,
            onRetry: { [weak self] message in
                self?.retryMessage(message)
            },
            onDelete: { [weak self] message in
                self?.deleteMessage(message)
            }
        )
    }
    
    private func retryMessage(_ message: Message) {
        // Retry sending message
    }
    
    private func deleteMessage(_ message: Message) {
        messages.removeAll { $0.id == message.id }
        updateMessagesView()
    }
}

// MARK: - Chat Messages SwiftUI View
struct ChatMessagesView: View {
    let messages: [Message]
    let onRetry: (Message) -> Void
    let onDelete: (Message) -> Void
    
    @State private var showTypingIndicator = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        MessageBubbleView(
                            message: message,
                            isCurrentUser: message.role == .user
                        )
                        .id(message.id)
                        .contextMenu {
                            Button {
                                onRetry(message)
                            } label: {
                                Label("Retry", systemImage: "arrow.clockwise")
                            }
                            
                            Button(role: .destructive) {
                                onDelete(message)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    
                    if showTypingIndicator {
                        TypingIndicatorView()
                            .id("typing")
                    }
                }
                .padding(.vertical, 16)
            }
            .onChange(of: messages.count) { _ in
                withAnimation {
                    proxy.scrollTo(messages.last?.id ?? "typing", anchor: .bottom)
                }
            }
        }
        .background(Color(red: 0.05, green: 0.05, blue: 0.1))
    }
}

// MARK: - Preview Helper
struct SwiftUIIntegration_Previews: PreviewProvider {
    static var previews: some View {
        ChatMessagesView(
            messages: [
                Message(
                    id: "1",
                    sessionId: "preview",
                    content: "Hello! How can I help you today?",
                    role: .assistant,
                    timestamp: Date()
                ),
                Message(
                    id: "2",
                    sessionId: "preview",
                    content: "I need help with SwiftUI",
                    role: .user,
                    timestamp: Date()
                )
            ],
            onRetry: { _ in },
            onDelete: { _ in }
        )
        .preferredColorScheme(.dark)
    }
}