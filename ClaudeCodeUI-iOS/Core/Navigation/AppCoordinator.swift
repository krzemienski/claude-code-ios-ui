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
        // Skip authentication and go directly to main interface
        showMainInterface()
    }
    
    private func checkOnboardingStatus() async -> Bool {
        guard let dataContainer = try? SwiftDataContainer() else { return false }
        
        do {
            let settings = try await dataContainer.fetchSettings()
            return settings?.hasCompletedOnboarding ?? false
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
        let authVC = AuthenticationViewController()
        navigationController.pushViewController(authVC, animated: false)
    }
}

protocol AuthenticationCoordinatorDelegate: AnyObject {
    func authenticationCoordinatorDidComplete(_ coordinator: AuthenticationCoordinator)
}