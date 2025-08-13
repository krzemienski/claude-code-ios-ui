//
//  AppCoordinator.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import UIKit

// Import LoginViewController from Authentication feature
import Foundation

// MARK: - App Coordinator
// The view controllers are now properly organized:
// - Features/Projects/ProjectsViewController.swift - Dynamic project list with backend integration
// - Features/Main/MainTabBarController.swift - Dynamic tab bar that adds Chat tab when project selected
// - Core/Navigation/ViewControllers.swift - Bridge implementations for backend connectivity

// Import the actual MainTabBarController from Features folder
// The file exists at Features/Main/MainTabBarController.swift and is declared as public

// Since both files are in the same module, we need to import the missing view controllers
// that MainTabBarController depends on

// The temp view controllers have been removed - using real implementations from Features folder

// Import the view controllers from ViewControllers.swift which provides
// connectivity to the backend at localhost:3004

// MARK: - Main Tab Bar Controller
// This is now moved to Features/Main/MainTabBarController.swift for dynamic tab management

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
        Task {
            do {
                // Check if we have a saved auth token
                let dataContainer = SwiftDataContainer.shared
                let settings = try await dataContainer.fetchSettings()
                
                if let token = settings.authToken, !token.isEmpty {
                    // Set token in API client
                    await DIContainer.shared.apiClient.setAuthToken(token)
                    
                    // Try to verify auth status with backend
                    let authStatusURL = URL(string: AppConfig.backendURL + "/api/auth/status")!
                    var request = URLRequest(url: authStatusURL)
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    request.timeoutInterval = 5
                    
                    do {
                        let (_, response) = try await URLSession.shared.data(for: request)
                        if let httpResponse = response as? HTTPURLResponse,
                           httpResponse.statusCode == 200 {
                            // Token is valid, proceed to main interface
                            await MainActor.run {
                                self.showMainInterface()
                            }
                            return
                        }
                    } catch {
                        print("Auth check failed: \(error)")
                    }
                }
                
                // No valid token or auth check failed, show login
                await MainActor.run {
                    self.showLoginScreen()
                }
                
            } catch {
                print("Error checking authentication: \(error)")
                await MainActor.run {
                    self.showLoginScreen()
                }
            }
        }
    }
    
    private func showLoginScreen() {
        // Temporarily skip login and go directly to main screen
        // let loginVC = LoginViewController()
        // window.rootViewController = loginVC
        
        Task { @MainActor in
            self.showMainInterface()
        }
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
        // Create a basic tab bar controller with projects and settings
        // MainTabBarController is not currently included in the Xcode project build
        let tabBarController = UITabBarController()
        
        // Projects Tab - Using the real ProjectsViewController instead of TempProjectsViewController
        let projectsVC = ProjectsViewController()
        let projectsNav = UINavigationController(rootViewController: projectsVC)
        projectsNav.tabBarItem = UITabBarItem(
            title: "Projects",
            image: UIImage(systemName: "folder.fill"),
            selectedImage: UIImage(systemName: "folder.fill.badge.plus")
        )
        
        // Settings Tab
        let settingsVC = SettingsViewController()
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gearshape.fill"),
            selectedImage: UIImage(systemName: "gearshape.2.fill")
        )
        
        // Configure tab bar
        tabBarController.viewControllers = [projectsNav, settingsNav]
        tabBarController.tabBar.backgroundColor = CyberpunkTheme.background
        tabBarController.tabBar.tintColor = CyberpunkTheme.primaryCyan
        tabBarController.tabBar.unselectedItemTintColor = CyberpunkTheme.secondaryText
        
        // Style navigation bars
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = CyberpunkTheme.background
        appearance.titleTextAttributes = [.foregroundColor: CyberpunkTheme.primaryText]
        appearance.largeTitleTextAttributes = [.foregroundColor: CyberpunkTheme.primaryText]
        
        [projectsNav, settingsNav].forEach { nav in
            guard let nav = nav as? UINavigationController else { return }
            nav.navigationBar.standardAppearance = appearance
            nav.navigationBar.scrollEdgeAppearance = appearance
            nav.navigationBar.prefersLargeTitles = true
            nav.navigationBar.tintColor = CyberpunkTheme.primaryCyan
        }
        
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
