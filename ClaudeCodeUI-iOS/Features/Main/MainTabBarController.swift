//
//  MainTabBarController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import UIKit

public class MainTabBarController: UITabBarController {
    
    // MARK: - Properties
    private let projectsVC = ProjectsViewController()
    private let settingsVC = SettingsViewController()
    private var currentProject: Project?
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set delegate to enable tab selection
        self.delegate = self
        
        setupTabBar()
        setupViewControllers()
        applyTheme()
        setupProjectSelectionHandler()
    }
    
    // MARK: - Setup
    private func setupTabBar() {
        // Configure tab bar appearance
        tabBar.isTranslucent = false
        tabBar.backgroundColor = CyberpunkTheme.background
        tabBar.tintColor = CyberpunkTheme.primaryCyan
        tabBar.unselectedItemTintColor = CyberpunkTheme.textTertiary
        
        // Add top border with neon effect
        let topBorder = CALayer()
        topBorder.frame = CGRect(x: 0, y: 0, width: tabBar.frame.width, height: 1)
        topBorder.backgroundColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.3).cgColor
        tabBar.layer.addSublayer(topBorder)
        
        // Apply blur effect
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = tabBar.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tabBar.insertSubview(blurView, at: 0)
    }
    
    private func setupViewControllers() {
        // Projects Tab - Always available
        let projectsNav = UINavigationController(rootViewController: projectsVC)
        projectsNav.tabBarItem = UITabBarItem(
            title: "Projects",
            image: createTabIcon(systemName: "folder.fill"),
            selectedImage: createTabIcon(systemName: "folder.fill.badge.plus")
        )
        
        // Settings Tab - Always available
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(
            title: "Settings",
            image: createTabIcon(systemName: "gearshape.fill"),
            selectedImage: createTabIcon(systemName: "gearshape.2.fill")
        )
        
        // Set initial view controllers (projects and settings only)
        viewControllers = [projectsNav, settingsNav]
        
        // Configure navigation bars
        [projectsNav, settingsNav].forEach { nav in
            nav.navigationBar.prefersLargeTitles = true
            nav.navigationBar.isTranslucent = false
            nav.navigationBar.backgroundColor = CyberpunkTheme.background
            nav.navigationBar.tintColor = CyberpunkTheme.primaryCyan
            
            // Navigation bar title attributes
            nav.navigationBar.largeTitleTextAttributes = [
                .foregroundColor: CyberpunkTheme.textPrimary,
                .font: UIFont.systemFont(ofSize: 34, weight: .bold)
            ]
            nav.navigationBar.titleTextAttributes = [
                .foregroundColor: CyberpunkTheme.textPrimary,
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
            ]
        }
    }
    
    private func createTabIcon(systemName: String) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        return UIImage(systemName: systemName, withConfiguration: config)
    }
    
    private func applyTheme() {
        // Apply appearance for iOS 15+
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = CyberpunkTheme.background
            
            // Normal state
            appearance.stackedLayoutAppearance.normal.iconColor = CyberpunkTheme.textTertiary
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: CyberpunkTheme.textTertiary,
                .font: UIFont.systemFont(ofSize: 10, weight: .medium)
            ]
            
            // Selected state
            appearance.stackedLayoutAppearance.selected.iconColor = CyberpunkTheme.primaryCyan
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: CyberpunkTheme.primaryCyan,
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
            ]
            
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        }
    }
    
    private func setupProjectSelectionHandler() {
        // Listen for project selection from ProjectsViewController
        projectsVC.onProjectSelected = { [weak self] project in
            self?.openChatForProject(project)
        }
    }
    
    private func openChatForProject(_ project: Project) {
        // Store current project
        currentProject = project
        
        // Create chat view controller for this project
        let chatVC = ChatViewController(project: project)
        let chatNav = UINavigationController(rootViewController: chatVC)
        chatNav.tabBarItem = UITabBarItem(
            title: "Chat",
            image: createTabIcon(systemName: "message.fill"),
            selectedImage: createTabIcon(systemName: "message.fill")
        )
        
        // Configure navigation bar
        chatNav.navigationBar.prefersLargeTitles = true
        chatNav.navigationBar.isTranslucent = false
        chatNav.navigationBar.backgroundColor = CyberpunkTheme.background
        chatNav.navigationBar.tintColor = CyberpunkTheme.primaryCyan
        chatNav.navigationBar.largeTitleTextAttributes = [
            .foregroundColor: CyberpunkTheme.textPrimary,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        chatNav.navigationBar.titleTextAttributes = [
            .foregroundColor: CyberpunkTheme.textPrimary,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
        // Update tab bar with chat tab
        if let projectsNav = viewControllers?[0] as? UINavigationController,
           let settingsNav = viewControllers?.last as? UINavigationController {
            viewControllers = [projectsNav, chatNav, settingsNav]
            
            // Switch to chat tab
            selectedIndex = 1
            
            // Add animation
            UIView.animate(withDuration: 0.3) {
                self.tabBar.alpha = 0.8
            } completion: { _ in
                UIView.animate(withDuration: 0.2) {
                    self.tabBar.alpha = 1.0
                }
            }
        }
    }
    
    // MARK: - Public Methods
    func switchToChat() {
        if viewControllers?.count ?? 0 >= 3 {
            selectedIndex = 1
        }
    }
    
    func switchToProjects() {
        selectedIndex = 0
    }
    
    func switchToSettings() {
        selectedIndex = viewControllers?.count == 2 ? 1 : 2
    }
}

// MARK: - UITabBarControllerDelegate
extension MainTabBarController: UITabBarControllerDelegate {
    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // Add subtle scale animation for the selected tab
        guard let tabBar = tabBarController.tabBar as? UITabBar,
              let selectedIndex = viewControllers?.firstIndex(of: viewController),
              selectedIndex < tabBar.items?.count ?? 0,
              let item = tabBar.items?[selectedIndex] else { return }
        
        // Find the image view for the selected tab
        if let barButtonView = tabBar.subviews.compactMap({ $0 as? UIControl }).first(where: { 
            $0.subviews.contains(where: { subview in
                if let imageView = subview as? UIImageView {
                    return true
                }
                return false
            })
        }) {
            UIView.animate(withDuration: 0.15, animations: {
                barButtonView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }) { _ in
                UIView.animate(withDuration: 0.15) {
                    barButtonView.transform = .identity
                }
            }
        }
    }
}