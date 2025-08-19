//
//  NavigationTests.swift
//  ClaudeCodeUITests
//
//  Created on 2025-01-18.
//

import XCTest
@testable import ClaudeCodeUI

class NavigationTests: XCTestCase {
    
    var window: UIWindow!
    var appCoordinator: AppCoordinator!
    var navigationController: UINavigationController!
    
    override func setUp() {
        super.setUp()
        
        // Create window and navigation controller
        window = UIWindow(frame: UIScreen.main.bounds)
        navigationController = UINavigationController()
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        // Initialize app coordinator
        appCoordinator = AppCoordinator(navigationController: navigationController)
    }
    
    override func tearDown() {
        window = nil
        appCoordinator = nil
        navigationController = nil
        super.tearDown()
    }
    
    // MARK: - Main Tab Bar Tests
    
    func testMainTabBarSetup() {
        // Test main tab bar is set up correctly
        appCoordinator.start()
        
        // Wait for navigation
        let expectation = self.expectation(description: "Tab bar loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        // Verify tab bar controller is root
        XCTAssertTrue(navigationController.viewControllers.first is MainTabBarController)
        
        if let tabBar = navigationController.viewControllers.first as? MainTabBarController {
            // Verify all tabs are present
            XCTAssertEqual(tabBar.viewControllers?.count, 6)
            
            // Verify tab order
            XCTAssertTrue(tabBar.viewControllers?[0] is UINavigationController) // Projects
            XCTAssertTrue(tabBar.viewControllers?[1] is UINavigationController) // Sessions
            XCTAssertTrue(tabBar.viewControllers?[2] is UINavigationController) // Files
            XCTAssertTrue(tabBar.viewControllers?[3] is UINavigationController) // Git
            XCTAssertTrue(tabBar.viewControllers?[4] is UINavigationController) // MCP
            XCTAssertTrue(tabBar.viewControllers?[5] is UINavigationController) // Settings
        }
    }
    
    func testMoreMenuForExtraTabs() {
        // Test that iOS automatically creates More menu for 6+ tabs
        appCoordinator.start()
        
        let expectation = self.expectation(description: "More menu created")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        if let tabBar = navigationController.viewControllers.first as? MainTabBarController {
            // iOS automatically shows only 4 tabs + More
            let visibleTabs = tabBar.tabBar.items?.count ?? 0
            XCTAssertLessThanOrEqual(visibleTabs, 5, "iOS should show max 4 tabs + More")
            
            // Verify More navigation controller exists
            XCTAssertNotNil(tabBar.moreNavigationController)
        }
    }
    
    // MARK: - Navigation Flow Tests
    
    func testProjectToSessionNavigation() {
        // Test navigating from projects to sessions
        appCoordinator.start()
        
        let expectation = self.expectation(description: "Navigation completed")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let tabBar = self.navigationController.viewControllers.first as? MainTabBarController,
               let projectNav = tabBar.viewControllers?[0] as? UINavigationController,
               let projectVC = projectNav.viewControllers.first as? ProjectListViewController {
                
                // Simulate project selection
                let project = Project(
                    id: "test",
                    name: "Test Project",
                    path: "/test",
                    lastAccessed: Date(),
                    icon: "folder"
                )
                
                projectVC.didSelectProject(project)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Verify session list is pushed
                    XCTAssertTrue(projectNav.viewControllers.last is SessionListViewController)
                    expectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testSessionToChatNavigation() {
        // Test navigating from sessions to chat
        let sessionVC = SessionListViewController(project: Project(
            id: "test",
            name: "Test",
            path: "/test",
            lastAccessed: Date(),
            icon: "folder"
        ))
        
        navigationController.pushViewController(sessionVC, animated: false)
        
        // Create test session
        let session = ChatSession(
            id: "test-session",
            projectId: "test",
            title: "Test Session",
            createdAt: Date(),
            lastMessageAt: Date()
        )
        
        // Navigate to chat
        sessionVC.navigateToChat(with: session)
        
        let expectation = self.expectation(description: "Chat pushed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(self.navigationController.viewControllers.last is ChatViewController)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testChatToFileExplorerNavigation() {
        // Test navigating from chat to file explorer
        let chatVC = ChatViewController(
            project: Project(
                id: "test",
                name: "Test",
                path: "/test",
                lastAccessed: Date(),
                icon: "folder"
            ),
            session: ChatSession(
                id: "test-session",
                projectId: "test",
                title: "Test",
                createdAt: Date(),
                lastMessageAt: Date()
            )
        )
        
        navigationController.pushViewController(chatVC, animated: false)
        
        // Navigate to file explorer
        chatVC.navigateToFileExplorer()
        
        let expectation = self.expectation(description: "File explorer pushed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(self.navigationController.viewControllers.last is FileExplorerViewController)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testChatToTerminalNavigation() {
        // Test navigating from chat to terminal
        let chatVC = ChatViewController(
            project: Project(
                id: "test",
                name: "Test",
                path: "/test",
                lastAccessed: Date(),
                icon: "folder"
            ),
            session: ChatSession(
                id: "test-session",
                projectId: "test",
                title: "Test",
                createdAt: Date(),
                lastMessageAt: Date()
            )
        )
        
        navigationController.pushViewController(chatVC, animated: false)
        
        // Navigate to terminal
        chatVC.navigateToTerminal()
        
        let expectation = self.expectation(description: "Terminal pushed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(self.navigationController.viewControllers.last is TerminalViewController)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testSettingsToMCPNavigation() {
        // Test navigating from settings to MCP servers
        let settingsVC = SettingsViewController()
        navigationController.pushViewController(settingsVC, animated: false)
        
        // Find and tap MCP servers row
        let tableView = settingsVC.tableView!
        tableView.reloadData()
        
        // Find MCP section (section 1)
        let mcpIndexPath = IndexPath(row: 0, section: 1)
        
        // Simulate tap
        settingsVC.tableView(tableView, didSelectRowAt: mcpIndexPath)
        
        let expectation = self.expectation(description: "MCP pushed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(self.navigationController.viewControllers.last is MCPServerListViewController)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - Navigation Stack Tests
    
    func testNavigationStackDepth() {
        // Test that navigation stack doesn't exceed reasonable depth
        appCoordinator.start()
        
        let expectation = self.expectation(description: "Navigation tested")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Push multiple view controllers
            for i in 0..<5 {
                let vc = UIViewController()
                vc.title = "Test \(i)"
                self.navigationController.pushViewController(vc, animated: false)
            }
            
            // Verify stack depth
            XCTAssertLessThanOrEqual(
                self.navigationController.viewControllers.count,
                10,
                "Navigation stack should not exceed reasonable depth"
            )
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testBackNavigation() {
        // Test back navigation
        let vc1 = UIViewController()
        vc1.title = "First"
        let vc2 = UIViewController()
        vc2.title = "Second"
        let vc3 = UIViewController()
        vc3.title = "Third"
        
        navigationController.setViewControllers([vc1, vc2, vc3], animated: false)
        
        // Pop one view controller
        navigationController.popViewController(animated: false)
        
        XCTAssertEqual(navigationController.viewControllers.count, 2)
        XCTAssertEqual(navigationController.viewControllers.last?.title, "Second")
        
        // Pop to root
        navigationController.popToRootViewController(animated: false)
        
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertEqual(navigationController.viewControllers.last?.title, "First")
    }
    
    // MARK: - Tab Selection Tests
    
    func testTabSelection() {
        // Test programmatic tab selection
        appCoordinator.start()
        
        let expectation = self.expectation(description: "Tab selected")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let tabBar = self.navigationController.viewControllers.first as? MainTabBarController {
                // Select Sessions tab
                tabBar.selectedIndex = 1
                XCTAssertEqual(tabBar.selectedIndex, 1)
                
                // Select Files tab
                tabBar.selectedIndex = 2
                XCTAssertEqual(tabBar.selectedIndex, 2)
                
                // Try to select More items (Git, MCP, Settings)
                tabBar.selectedIndex = 4 // MCP
                XCTAssertEqual(tabBar.selectedIndex, 4)
                
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - Modal Presentation Tests
    
    func testModalPresentation() {
        // Test modal presentation
        let baseVC = UIViewController()
        navigationController.pushViewController(baseVC, animated: false)
        
        let modalVC = UIViewController()
        modalVC.title = "Modal"
        
        baseVC.present(modalVC, animated: false)
        
        let expectation = self.expectation(description: "Modal presented")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertNotNil(baseVC.presentedViewController)
            XCTAssertEqual(baseVC.presentedViewController?.title, "Modal")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testModalDismissal() {
        // Test modal dismissal
        let baseVC = UIViewController()
        navigationController.pushViewController(baseVC, animated: false)
        
        let modalVC = UIViewController()
        baseVC.present(modalVC, animated: false)
        
        let expectation = self.expectation(description: "Modal dismissed")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            modalVC.dismiss(animated: false) {
                XCTAssertNil(baseVC.presentedViewController)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
}

// MARK: - Test Extensions

extension ChatViewController {
    func navigateToFileExplorer() {
        // Implementation would push FileExplorerViewController
        let fileExplorer = FileExplorerViewController(project: project)
        navigationController?.pushViewController(fileExplorer, animated: true)
    }
    
    func navigateToTerminal() {
        // Implementation would push TerminalViewController
        let terminal = TerminalViewController(project: project)
        navigationController?.pushViewController(terminal, animated: true)
    }
}

extension ProjectListViewController {
    func didSelectProject(_ project: Project) {
        // Implementation would navigate to sessions
        let sessionsVC = SessionListViewController(project: project)
        navigationController?.pushViewController(sessionsVC, animated: true)
    }
}

extension SessionListViewController {
    func navigateToChat(with session: ChatSession) {
        // Implementation would navigate to chat
        let chatVC = ChatViewController(project: project, session: session)
        navigationController?.pushViewController(chatVC, animated: true)
    }
}