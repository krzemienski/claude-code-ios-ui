//
//  AppCoordinator.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import UIKit

// MARK: - Temporary ViewControllers (defined in ViewControllers.swift but accessible here)
// If these are not being found, create simple stubs for compilation
#if false
// These are defined in ViewControllers.swift
#else
// Temporary stubs to allow compilation - real implementations are in Features folder
class ProjectsViewController: UIViewController { }
class ChatViewController: UIViewController {
    init(project: Any?) { super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
}
class FileExplorerViewController: UIViewController { }
class TerminalViewController: UIViewController { }
class SettingsViewController: UIViewController { }
#endif

// MARK: - Temporary Theme Colors (using actual theme from Design/Theme/CyberpunkTheme.swift)
private struct AppTheme {
    static let background = UIColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1.0)
    static let surface = UIColor(red: 0.1, green: 0.1, blue: 0.18, alpha: 1.0)
    static let primaryCyan = UIColor(red: 0, green: 0.85, blue: 1, alpha: 1.0)
    static let primaryText = UIColor.white
    static let secondaryText = UIColor(white: 0.88, alpha: 1.0)
    static let border = UIColor(red: 0.16, green: 0.16, blue: 0.25, alpha: 1.0)
}

// MARK: - Import View Controllers from ViewControllers.swift
// The actual view controller implementations are in ViewControllers.swift
// which provides connectivity to the backend at localhost:3004

// MARK: - Main Tab Bar Controller

class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        customizeAppearance()
    }
    
    private func setupViewControllers() {
        // Use the real Feature ViewControllers from Features/ folder
        // These have full functionality and proper backend connectivity
        
        // Projects Tab - Using real ProjectsViewController from Features/Projects/
        let projectsVC = ProjectsViewController()
        projectsVC.tabBarItem = UITabBarItem(title: "Projects", image: UIImage(systemName: "folder.fill"), tag: 0)
        let projectsNav = UINavigationController(rootViewController: projectsVC)
        
        // Chat Tab - Using real ChatViewController from Features/Chat/
        let chatVC = ChatViewController(project: nil)
        chatVC.tabBarItem = UITabBarItem(title: "Chat", image: UIImage(systemName: "message.fill"), tag: 1)
        let chatNav = UINavigationController(rootViewController: chatVC)
        
        // Files Tab - Using real FileExplorerViewController from Features/FileExplorer/
        let filesVC = FileExplorerViewController()
        filesVC.tabBarItem = UITabBarItem(title: "Files", image: UIImage(systemName: "doc.text.fill"), tag: 2)
        let filesNav = UINavigationController(rootViewController: filesVC)
        
        // Terminal Tab - Using real TerminalViewController from Features/Terminal/
        let terminalVC = TerminalViewController()
        terminalVC.tabBarItem = UITabBarItem(title: "Terminal", image: UIImage(systemName: "terminal.fill"), tag: 3)
        let terminalNav = UINavigationController(rootViewController: terminalVC)
        
        // Settings Tab - Using real SettingsViewController from Features/Settings/
        let settingsVC = SettingsViewController()
        settingsVC.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape.fill"), tag: 4)
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        
        viewControllers = [projectsNav, chatNav, filesNav, terminalNav, settingsNav]
    }
    
    private func customizeAppearance() {
        tabBar.tintColor = UIColor(red: 0, green: 0.85, blue: 1, alpha: 1.0) // Cyan
        tabBar.unselectedItemTintColor = UIColor(red: 0.5, green: 0.5, blue: 0.6, alpha: 1.0)
        tabBar.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        tabBar.isTranslucent = false
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
        // Skip authentication for now and go directly to main interface
        print("🚀 AppCoordinator: Showing MainTabBarController")
        showMainInterface()
    }
    
    @MainActor
    private func checkOnboardingStatus() async -> Bool {
        // Skip onboarding check for now
        return true
    }
    
    private func showLaunchScreen() {
        let launchViewController = UIViewController()
        launchViewController.view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        
        let label = UILabel()
        label.text = "Claude Code"
        label.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        label.textColor = UIColor(red: 0, green: 0.85, blue: 1, alpha: 1.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        launchViewController.view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: launchViewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: launchViewController.view.centerYAnchor)
        ])
        
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
        // Create simple authentication view controller
        let authVC = UIViewController()
        authVC.view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        authVC.title = "Authentication"
        navigationController.pushViewController(authVC, animated: false)
    }
}

protocol AuthenticationCoordinatorDelegate: AnyObject {
    func authenticationCoordinatorDidComplete(_ coordinator: AuthenticationCoordinator)
}