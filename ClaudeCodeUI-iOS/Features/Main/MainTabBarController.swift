//
//  MainTabBarController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import UIKit
import SwiftUI

public class MainTabBarController: UITabBarController {
    
    // MARK: - Properties
    private let projectsVC = ProjectsViewController()
    private let settingsVC = SettingsViewController()
    private let transcriptionVC = TranscriptionViewController()
    private let mcpServerVC = MCPServerListViewController()
    private lazy var searchVC = SearchViewController(project: currentProject)
    private lazy var terminalVC = TerminalViewController(project: currentProject)
    private lazy var gitVC = GitViewController(project: currentProject)
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
        
        // Search Tab - Project-wide search functionality
        searchVC.title = "Search"
        let searchNav = UINavigationController(rootViewController: searchVC)
        searchNav.tabBarItem = UITabBarItem(
            title: "Search",
            image: createTabIcon(systemName: "magnifyingglass"),
            selectedImage: createTabIcon(systemName: "magnifyingglass.circle.fill")
        )
        
        // Terminal Tab - Command execution
        terminalVC.title = "Terminal"
        let terminalNav = UINavigationController(rootViewController: terminalVC)
        terminalNav.tabBarItem = UITabBarItem(
            title: "Terminal",
            image: createTabIcon(systemName: "terminal"),
            selectedImage: createTabIcon(systemName: "terminal.fill")
        )
        
        // Git Tab - Version control management
        gitVC.title = "Git"
        let gitNav = UINavigationController(rootViewController: gitVC)
        gitNav.tabBarItem = UITabBarItem(
            title: "Git",
            image: createTabIcon(systemName: "arrow.triangle.branch"),
            selectedImage: createTabIcon(systemName: "arrow.triangle.branch")
        )
        
        // MCP Servers Tab - Integrated MCP server management
        mcpServerVC.title = "MCP Servers"
        let mcpNav = UINavigationController(rootViewController: mcpServerVC)
        mcpNav.tabBarItem = UITabBarItem(
            title: "MCP",
            image: createTabIcon(systemName: "server.rack"),
            selectedImage: createTabIcon(systemName: "server.rack")
        )
        
        // Settings Tab - Always available
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(
            title: "Settings",
            image: createTabIcon(systemName: "gearshape.fill"),
            selectedImage: createTabIcon(systemName: "gearshape.2.fill")
        )
        
        // Set initial view controllers (projects, search, terminal, Git, MCP, and settings)
        // Now includes Git integration for version control
        viewControllers = [projectsNav, searchNav, terminalNav, gitNav, mcpNav, settingsNav]
        
        // Debug: Log tab count
        print("🔵 DEBUG: Set up \(viewControllers?.count ?? 0) tabs in tab bar")
        
        // Configure navigation bars
        [projectsNav, searchNav, terminalNav, gitNav, mcpNav, settingsNav].forEach { nav in
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
        
        // Update SearchViewController with new project context
        if let searchNav = viewControllers?[1] as? UINavigationController {
            // Create new SearchViewController with project context
            let newSearchVC = SearchViewController(project: project)
            newSearchVC.title = "Search"
            searchNav.setViewControllers([newSearchVC], animated: false)
        }
        
        // Update TerminalViewController with new project context
        if let terminalNav = viewControllers?[2] as? UINavigationController {
            // Create new TerminalViewController with project context
            let newTerminalVC = TerminalViewController(project: project)
            newTerminalVC.title = "Terminal"
            terminalNav.setViewControllers([newTerminalVC], animated: false)
        }
        
        // Update GitViewController with new project context
        if let gitNav = viewControllers?[3] as? UINavigationController {
            // Create new GitViewController with project context
            let newGitVC = GitViewController(project: project)
            newGitVC.title = "Git"
            gitNav.setViewControllers([newGitVC], animated: false)
        }
        
        // Navigate to session list within the Projects tab instead of replacing tabs
        if let projectsNav = viewControllers?[0] as? UINavigationController {
            let sessionListVC = SessionListViewController(project: project)
            projectsNav.pushViewController(sessionListVC, animated: true)
        }
    }
    
    // MARK: - Public Methods
    func switchToProjects() {
        selectedIndex = 0
    }
    
    func switchToSearch() {
        selectedIndex = 1  // Search is at index 1
    }
    
    func switchToTerminal() {
        selectedIndex = 2  // Terminal is at index 2
    }
    
    func switchToGit() {
        selectedIndex = 3  // Git is at index 3
    }
    
    func switchToMCP() {
        selectedIndex = 4  // MCP is at index 4
    }
    
    func switchToSettings() {
        selectedIndex = 5  // Settings is always at index 5 (last tab)
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

// MARK: - SwiftUI Demo View
struct SwiftUIDemoView: View {
    @State private var isLoading = false
    @State private var progress: Double = 0.3
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.black, Color(red: 0.1, green: 0, blue: 0.2).opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Title
                    Text("SwiftUI Components")
                        .font(.largeTitle.bold())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0, green: 0.85, blue: 1), Color(red: 1, green: 0, blue: 0.43)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding(.top)
                    
                    // Loading Indicator Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Loading States")
                            .font(.title2.bold())
                            .foregroundColor(Color(red: 0, green: 0.85, blue: 1))
                        
                        // Circular Progress
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0, green: 0.85, blue: 1)))
                                .scaleEffect(1.5)
                            
                            Text("Loading API data...")
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.leading)
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Linear Progress Bar
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Progress: \(Int(progress * 100))%")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(red: 0, green: 0.85, blue: 1), Color(red: 1, green: 0, blue: 0.43)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * progress, height: 8)
                                        .animation(.spring(), value: progress)
                                }
                            }
                            .frame(height: 8)
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Test Button
                    Button(action: {
                        withAnimation {
                            isLoading.toggle()
                            progress = progress < 1.0 ? progress + 0.2 : 0.0
                        }
                    }) {
                        Text(isLoading ? "Stop Loading" : "Start Loading")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0, green: 0.85, blue: 1), Color(red: 1, green: 0, blue: 0.43)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            
            // Full Screen Loading Overlay
            if isLoading {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2)
                    
                    Text("Loading...")
                        .foregroundColor(.white)
                        .font(.headline)
                }
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color(red: 0, green: 0.85, blue: 1).opacity(0.5), Color(red: 1, green: 0, blue: 0.43).opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
            }
        }
    }
}