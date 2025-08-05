//
//  AppCoordinator.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import UIKit

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
        // For now, always show launch screen first
        showLaunchScreen()
        
        // Simulate auth check delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.showMainInterface()
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
        let tabBarController = createMainTabBarController()
        
        // Animate transition
        UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
            self.window.rootViewController = tabBarController
        })
    }
    
    private func createMainTabBarController() -> UITabBarController {
        let tabBarController = UITabBarController()
        
        // Projects Tab
        let projectsNav = UINavigationController()
        let projectsCoordinator = ProjectsCoordinator(navigationController: projectsNav)
        childCoordinators.append(projectsCoordinator)
        projectsCoordinator.start()
        projectsNav.tabBarItem = UITabBarItem(
            title: "Projects",
            image: UIImage(systemName: "folder"),
            selectedImage: UIImage(systemName: "folder.fill")
        )
        
        // Terminal Tab
        let terminalNav = UINavigationController()
        let terminalCoordinator = TerminalCoordinator(navigationController: terminalNav)
        childCoordinators.append(terminalCoordinator)
        terminalCoordinator.start()
        terminalNav.tabBarItem = UITabBarItem(
            title: "Terminal",
            image: UIImage(systemName: "terminal"),
            selectedImage: UIImage(systemName: "terminal.fill")
        )
        
        // Settings Tab
        let settingsNav = UINavigationController()
        let settingsCoordinator = SettingsCoordinator(navigationController: settingsNav)
        childCoordinators.append(settingsCoordinator)
        settingsCoordinator.start()
        settingsNav.tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )
        
        tabBarController.viewControllers = [projectsNav, terminalNav, settingsNav]
        
        return tabBarController
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

// MARK: - Placeholder Coordinators
class AuthenticationCoordinator: Coordinator {
    weak var delegate: AuthenticationCoordinatorDelegate?
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        // TODO: Implement authentication flow
    }
}

protocol AuthenticationCoordinatorDelegate: AnyObject {
    func authenticationCoordinatorDidComplete(_ coordinator: AuthenticationCoordinator)
}

class ProjectsCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let projectsVC = ProjectsViewController()
        navigationController.pushViewController(projectsVC, animated: false)
    }
}

class TerminalCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let terminalVC = TerminalViewController()
        navigationController.pushViewController(terminalVC, animated: false)
    }
}

class SettingsCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let settingsVC = SettingsViewController()
        navigationController.pushViewController(settingsVC, animated: false)
    }
}

// MARK: - Placeholder View Controllers
class ProjectsViewController: BaseCollectionViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Projects"
        navigationItem.largeTitleDisplayMode = .always
    }
}

class TerminalViewController: BaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Terminal"
        navigationItem.largeTitleDisplayMode = .always
    }
}

class SettingsViewController: BaseTableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        navigationItem.largeTitleDisplayMode = .always
    }
}