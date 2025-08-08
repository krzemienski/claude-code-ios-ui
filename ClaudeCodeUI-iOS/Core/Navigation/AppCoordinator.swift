//
//  AppCoordinator.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import UIKit

// MARK: - Temporary Classes (until proper files are added to project)

// Temporary MainTabBarController
class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        customizeAppearance()
    }
    
    private func setupViewControllers() {
        // Use actual view controllers
        let projectsVC = ProjectsViewController()
        projectsVC.tabBarItem = UITabBarItem(title: "Projects", image: UIImage(systemName: "folder.fill"), tag: 0)
        let projectsNav = UINavigationController(rootViewController: projectsVC)
        
        let chatVC = UIViewController() // Placeholder for now
        chatVC.view.backgroundColor = CyberpunkTheme.background
        chatVC.title = "Chat"
        chatVC.tabBarItem = UITabBarItem(title: "Chat", image: UIImage(systemName: "message.fill"), tag: 1)
        let chatNav = UINavigationController(rootViewController: chatVC)
        
        let filesVC = UIViewController() // Placeholder for now
        filesVC.view.backgroundColor = CyberpunkTheme.background
        filesVC.title = "Files"
        filesVC.tabBarItem = UITabBarItem(title: "Files", image: UIImage(systemName: "doc.text.fill"), tag: 2)
        let filesNav = UINavigationController(rootViewController: filesVC)
        
        let terminalVC = UIViewController() // Placeholder for now
        terminalVC.view.backgroundColor = CyberpunkTheme.background
        terminalVC.title = "Terminal"
        terminalVC.tabBarItem = UITabBarItem(title: "Terminal", image: UIImage(systemName: "terminal.fill"), tag: 3)
        let terminalNav = UINavigationController(rootViewController: terminalVC)
        
        let settingsVC = SettingsViewController()
        settingsVC.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape.fill"), tag: 4)
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        
        viewControllers = [projectsNav, chatNav, filesNav, terminalNav, settingsNav]
    }
    
    private func createViewController(title: String, systemImage: String, color: UIColor) -> UINavigationController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = CyberpunkTheme.background
        viewController.title = title
        viewController.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: systemImage), tag: 0)
        
        let navController = UINavigationController(rootViewController: viewController)
        navController.navigationBar.prefersLargeTitles = true
        return navController
    }
    
    private func customizeAppearance() {
        tabBar.tintColor = CyberpunkTheme.primaryCyan
        tabBar.unselectedItemTintColor = CyberpunkTheme.textTertiary
        tabBar.backgroundColor = CyberpunkTheme.surface
        tabBar.isTranslucent = false
    }
}

// Temporary simplified view controllers for testing
// Note: The real implementations exist in Features/ but aren't in the Xcode project file

class ProjectsViewController: UIViewController, WebSocketManagerDelegate {
    // WebSocket delegate methods
    func webSocketDidConnect(_ manager: WebSocketManager) {
        print("✅ WebSocket connected")
    }
    
    func webSocketDidDisconnect(_ manager: WebSocketManager, error: Error?) {
        print("❌ WebSocket disconnected: \(error?.localizedDescription ?? "No error")")
    }
    
    func webSocket(_ manager: WebSocketManager, didReceiveMessage message: WebSocketMessage) {
        print("📨 WebSocket message: \(message.type)")
    }
    
    func webSocket(_ manager: WebSocketManager, didReceiveData data: Data) {
        print("📦 WebSocket data: \(data.count) bytes")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CyberpunkTheme.background
        title = "Projects"
        
        // Create test UI with button to open chat
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "Testing Chat Interface..."
        label.textColor = CyberpunkTheme.primaryCyan
        label.font = CyberpunkTheme.titleFont
        label.textAlignment = .center
        label.numberOfLines = 0
        
        let chatButton = UIButton(type: .system)
        chatButton.setTitle("Open Test Chat", for: .normal)
        chatButton.titleLabel?.font = CyberpunkTheme.headlineFont
        chatButton.setTitleColor(CyberpunkTheme.primaryCyan, for: .normal)
        chatButton.backgroundColor = CyberpunkTheme.surface
        chatButton.layer.cornerRadius = 12
        chatButton.layer.borderWidth = 2
        chatButton.layer.borderColor = CyberpunkTheme.primaryCyan.cgColor
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
            chatButton.configuration = config
        }
        
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(chatButton)
        
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
        
        // Test API and display real projects
        Task {
            do {
                let apiClient = APIClient(baseURL: "http://localhost:3004")
                let projects = try await apiClient.fetchProjects()
                
                // Create a test project for chat
                let dataContainer = SwiftDataContainer.shared
                let testProject = try dataContainer.createProject(
                    name: "Chat Test Project",
                    path: "/test/chat"
                )
                
                await MainActor.run {
                    // Show list of projects
                    var projectsList = "✅ Found \(projects.count) projects:\n\n"
                    for (index, project) in projects.prefix(10).enumerated() {
                        projectsList += "\(index + 1). \(project.name)\n"
                    }
                    if projects.count > 10 {
                        projectsList += "... and \(projects.count - 10) more\n"
                    }
                    projectsList += "\nTap button to test chat interface"
                    label.text = projectsList
                    
                    // Add action to open chat
                    chatButton.addTarget(self, action: #selector(self.openTestChat(_:)), for: .touchUpInside)
                    chatButton.tag = 1 // Use tag to pass project info
                    
                    // Store project in button's layer for retrieval
                    objc_setAssociatedObject(chatButton, "testProject", testProject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                }
            } catch {
                await MainActor.run {
                    label.text = "❌ Error: \(error.localizedDescription)"
                    label.textColor = CyberpunkTheme.accentPink
                    chatButton.isEnabled = false
                    chatButton.alpha = 0.5
                }
            }
        }
    }
    
    @objc private func openTestChat(_ sender: UIButton) {
        // Create a test project directly here instead of relying on associated object
        let testProject = Project(
            id: UUID().uuidString,
            name: "Chat Test Project",
            path: "/test/chat",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        print("🚀 Testing chat interface for project: \(testProject.name)")
        
        // Create a test chat view controller
        let chatTestVC = UIViewController()
        chatTestVC.view.backgroundColor = CyberpunkTheme.background
        chatTestVC.title = "Chat: \(testProject.name)"
        
        // Create chat UI elements for testing
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Chat messages area (simulated)
        let messagesView = UITextView()
        messagesView.backgroundColor = CyberpunkTheme.surface
        messagesView.textColor = CyberpunkTheme.primaryText
        messagesView.font = CyberpunkTheme.bodyFont
        messagesView.layer.cornerRadius = 12
        messagesView.layer.borderWidth = 1
        messagesView.layer.borderColor = CyberpunkTheme.border.cgColor
        messagesView.isEditable = false
        messagesView.text = "Assistant: Welcome to \(testProject.name)!\n\nUser: Testing chat interface\n\nAssistant: Chat interface is working! ✅"
        messagesView.translatesAutoresizingMaskIntoConstraints = false
        
        // Input field (simulated)
        let inputField = UITextField()
        inputField.placeholder = "Type a message..."
        inputField.backgroundColor = CyberpunkTheme.surface
        inputField.textColor = CyberpunkTheme.primaryText
        inputField.font = CyberpunkTheme.bodyFont
        inputField.layer.cornerRadius = 20
        inputField.layer.borderWidth = 1
        inputField.layer.borderColor = CyberpunkTheme.primaryCyan.cgColor
        inputField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        inputField.leftViewMode = .always
        inputField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        inputField.rightViewMode = .always
        inputField.translatesAutoresizingMaskIntoConstraints = false
        
        // Send button
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.titleLabel?.font = CyberpunkTheme.bodyFont
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.backgroundColor = CyberpunkTheme.primaryCyan
        sendButton.layer.cornerRadius = 20
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        
        // WebSocket status
        let wsStatusLabel = UILabel()
        wsStatusLabel.font = CyberpunkTheme.captionFont
        wsStatusLabel.textColor = CyberpunkTheme.secondaryText
        wsStatusLabel.textAlignment = .center
        wsStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Test WebSocket connection for chat
        let wsManager = WebSocketManager(baseURL: AppConfig.websocketURL.replacingOccurrences(of: "/ws", with: ""), endpoint: "/ws")
        wsManager.delegate = self
        wsManager.connect()
        
        // Update WebSocket status after connection attempt
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            if wsManager.isConnected {
                wsStatusLabel.text = "✅ WebSocket: Connected"
                wsStatusLabel.textColor = CyberpunkTheme.success
                
                // Test sending a message through WebSocket
                let message = WebSocketMessage(
                    type: .sessionMessage,
                    payload: [
                        "projectId": testProject.id,
                        "content": "Test message from iOS",
                        "timestamp": Date().timeIntervalSince1970
                    ]
                )
                wsManager.send(message)
                
                // Add sent message to display
                messagesView.text += "\n\n📤 Sent test message via WebSocket"
            } else {
                wsStatusLabel.text = "❌ WebSocket: Disconnected"
                wsStatusLabel.textColor = CyberpunkTheme.error
            }
        })
        
        // Add action to send button
        sendButton.addTarget(self, action: #selector(self.sendChatMessage(_:)), for: .touchUpInside)
        // Store references for the selector
        objc_setAssociatedObject(sendButton, "inputField", inputField, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(sendButton, "messagesView", messagesView, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(sendButton, "wsManager", wsManager, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(sendButton, "project", testProject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // Input container
        let inputContainer = UIView()
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(inputField)
        inputContainer.addSubview(sendButton)
        
        stackView.addArrangedSubview(messagesView)
        stackView.addArrangedSubview(wsStatusLabel)
        stackView.addArrangedSubview(inputContainer)
        
        chatTestVC.view.addSubview(stackView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: chatTestVC.view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: chatTestVC.view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: chatTestVC.view.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: chatTestVC.view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            messagesView.heightAnchor.constraint(equalToConstant: 300),
            
            inputContainer.heightAnchor.constraint(equalToConstant: 44),
            
            inputField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor),
            inputField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            inputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),
            inputField.heightAnchor.constraint(equalToConstant: 40),
            
            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 80),
            sendButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        navigationController?.pushViewController(chatTestVC, animated: true)
    }
    
    @objc private func sendChatMessage(_ sender: UIButton) {
        guard let inputField = objc_getAssociatedObject(sender, "inputField") as? UITextField,
              let messagesView = objc_getAssociatedObject(sender, "messagesView") as? UITextView,
              let wsManager = objc_getAssociatedObject(sender, "wsManager") as? WebSocketManager,
              let project = objc_getAssociatedObject(sender, "project") as? Project,
              let text = inputField.text, !text.isEmpty else {
            return
        }
        
        messagesView.text += "\n\nUser: \(text)"
        
        // Send via WebSocket if connected
        if wsManager.isConnected {
            let message = WebSocketMessage(
                type: .sessionMessage,
                payload: [
                    "projectId": project.id,
                    "content": text,
                    "timestamp": Date().timeIntervalSince1970
                ]
            )
            wsManager.send(message)
            messagesView.text += "\n📤 Sent via WebSocket"
        }
        
        inputField.text = ""
        
        // Scroll to bottom
        if messagesView.text.count > 0 {
            let bottom = NSMakeRange(messagesView.text.count - 1, 1)
            messagesView.scrollRangeToVisible(bottom)
        }
    }
}

class SettingsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CyberpunkTheme.background
        title = "Settings"
    }
}

// MARK: - Coordinator Protocol
protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }
    
    func start()
}

// MARK: - App Coordinator
class AppCoordinator: Coordinator {
    
    // MARK: - Properties
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    private let window: UIWindow
    
    // MARK: - Initialization
    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
        self.navigationController.navigationBar.prefersLargeTitles = true
    }
    
    // MARK: - Start
    func start() {
        // Check authentication status
        checkAuthentication()
    }
    
    // MARK: - Navigation
    private func checkAuthentication() {
        // For testing: Skip authentication and go directly to main interface with tab bar
        print("🚀 AppCoordinator: Skipping authentication, showing MainTabBarController")
        showMainInterface()
    }
    
    @MainActor
    private func checkOnboardingStatus() async -> Bool {
        let dataContainer = SwiftDataContainer.shared
        
        do {
            _ = try dataContainer.fetchSettings()
            return true // Skip onboarding for testing
        } catch {
            Logger.shared.error("Failed to fetch settings: \(error)")
            return false
        }
    }
    
    private func showLaunchScreen() {
        let launchViewController = LaunchViewController()
        window.rootViewController = launchViewController
    }
    
    private func showAuthenticationFlow() {
        let authCoordinator = AuthenticationCoordinator(navigationController: navigationController)
        authCoordinator.delegate = self
        childCoordinators.append(authCoordinator)
        authCoordinator.start()
        
        window.rootViewController = navigationController
    }
    
    private func showMainInterface() {
        let tabBarController = MainTabBarController()
        
        // Animate transition
        UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
            self.window.rootViewController = tabBarController
        })
    }
    
    // MARK: - Child Coordinator Management
    func childDidFinish(_ child: Coordinator?) {
        for (index, coordinator) in childCoordinators.enumerated() {
            if coordinator === child {
                childCoordinators.remove(at: index)
                break
            }
        }
    }
}

// MARK: - Authentication Coordinator Delegate
extension AppCoordinator: AuthenticationCoordinatorDelegate {
    func authenticationCoordinatorDidComplete(_ coordinator: AuthenticationCoordinator) {
        childDidFinish(coordinator)
        showMainInterface()
    }
}

// MARK: - Authentication Coordinator
class AuthenticationCoordinator: Coordinator {
    weak var delegate: AuthenticationCoordinatorDelegate?
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        // Note: AuthenticationViewController should be available via project's target membership
        // If not, the file needs to be added to the project target
        // For now, use a placeholder
        let authVC = UIViewController()
        authVC.view.backgroundColor = CyberpunkTheme.background
        authVC.title = "Authentication"
        navigationController.pushViewController(authVC, animated: false)
    }
}

protocol AuthenticationCoordinatorDelegate: AnyObject {
    func authenticationCoordinatorDidComplete(_ coordinator: AuthenticationCoordinator)
}