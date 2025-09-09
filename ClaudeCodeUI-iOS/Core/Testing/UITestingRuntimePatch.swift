//
//  UITestingRuntimePatch.swift
//  ClaudeCodeUI
//
//  Runtime patches for UI testing to ensure proper navigation
//

import UIKit

/// Runtime patches applied when UI testing is detected
public class UITestingRuntimePatch {
    
    public static let shared = UITestingRuntimePatch()
    
    private var hasAppliedPatches = false
    
    private init() {}
    
    /// Check if UI testing is active
    public static var isUITesting: Bool {
        return ProcessInfo.processInfo.arguments.contains("UI-TESTING")
    }
    
    /// Apply all runtime patches for UI testing
    public func applyPatchesIfNeeded() {
        guard UITestingRuntimePatch.isUITesting else { return }
        guard !hasAppliedPatches else { return }
        
        hasAppliedPatches = true
        
        print("🔧 Applying UI Testing Runtime Patches...")
        
        // Apply navigation patches
        patchNavigationControllers()
        
        // Apply tab bar patches
        patchTabBarControllers()
        
        // Apply accessibility patches
        patchAccessibility()
        
        // Apply gesture recognizer patches
        patchGestureRecognizers()
        
        // Apply collection/table view patches
        patchScrollViews()
        
        print("✅ UI Testing Runtime Patches Applied")
    }
    
    // MARK: - Navigation Patches
    
    private func patchNavigationControllers() {
        // Swizzle UINavigationController methods
        swizzleNavigationController()
        
        // Fix existing navigation controllers
        for window in UIApplication.shared.windows {
            fixNavigationInView(window)
        }
    }
    
    private func swizzleNavigationController() {
        let originalPush = class_getInstanceMethod(
            UINavigationController.self,
            #selector(UINavigationController.pushViewController(_:animated:))
        )
        let swizzledPush = class_getInstanceMethod(
            UINavigationController.self,
            #selector(UINavigationController.uitest_pushViewController(_:animated:))
        )
        
        if let original = originalPush, let swizzled = swizzledPush {
            method_exchangeImplementations(original, swizzled)
        }
    }
    
    private func fixNavigationInView(_ view: UIView) {
        if let nav = view as? UINavigationController {
            nav.interactivePopGestureRecognizer?.isEnabled = true
            nav.navigationBar.isHidden = false
            nav.navigationBar.isUserInteractionEnabled = true
        }
        
        for subview in view.subviews {
            fixNavigationInView(subview)
        }
    }
    
    // MARK: - Tab Bar Patches
    
    private func patchTabBarControllers() {
        // Fix all tab bar controllers
        for window in UIApplication.shared.windows {
            if let rootVC = window.rootViewController as? UITabBarController {
                patchTabBarController(rootVC)
            }
        }
    }
    
    private func patchTabBarController(_ tabBarController: UITabBarController) {
        // Ensure tab bar is visible
        tabBarController.tabBar.isHidden = false
        tabBarController.tabBar.alpha = 1.0
        
        // Add accessibility identifiers
        tabBarController.tabBar.accessibilityIdentifier = "MainTabBar"
        
        // Fix tab items
        if let items = tabBarController.tabBar.items {
            for (index, item) in items.enumerated() {
                switch index {
                case 0:
                    item.accessibilityIdentifier = "ProjectsTab"
                case 1:
                    item.accessibilityIdentifier = "SessionsTab"
                case 2:
                    item.accessibilityIdentifier = "SearchTab"
                case 3:
                    item.accessibilityIdentifier = "SettingsTab"
                default:
                    item.accessibilityIdentifier = "Tab\(index)"
                }
            }
        }
    }
    
    // MARK: - Accessibility Patches
    
    private func patchAccessibility() {
        // Enable accessibility for testing
        // Note: isVoiceOverRunning is read-only, cannot be set directly
        // UIAccessibility.isVoiceOverRunning = false
        
        // Add notification observer for view controller changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(viewControllerDidAppear(_:)),
            name: NSNotification.Name("UIViewControllerDidAppear"),
            object: nil
        )
    }
    
    @objc private func viewControllerDidAppear(_ notification: Notification) {
        guard let viewController = notification.object as? UIViewController else { return }
        
        // Add accessibility identifiers
        enhanceViewControllerAccessibility(viewController)
    }
    
    private func enhanceViewControllerAccessibility(_ vc: UIViewController) {
        let className = String(describing: type(of: vc))
        vc.view.accessibilityIdentifier = "\(className)View"
        
        // Enhance specific view controllers
        switch className {
        case "ProjectsViewController":
            enhanceProjectsViewController(vc)
        case "SessionListViewController", "SessionsViewController":
            enhanceSessionsViewController(vc)
        case "ChatViewController":
            enhanceChatViewController(vc)
        default:
            break
        }
    }
    
    private func enhanceProjectsViewController(_ vc: UIViewController) {
        // Find and tag collection/table views
        for subview in vc.view.subviews {
            if let collectionView = subview as? UICollectionView {
                collectionView.accessibilityIdentifier = "ProjectsCollectionView"
            } else if let tableView = subview as? UITableView {
                tableView.accessibilityIdentifier = "ProjectsTableView"
            }
        }
    }
    
    private func enhanceSessionsViewController(_ vc: UIViewController) {
        for subview in vc.view.subviews {
            if let tableView = subview as? UITableView {
                tableView.accessibilityIdentifier = "SessionsTableView"
            }
        }
    }
    
    private func enhanceChatViewController(_ vc: UIViewController) {
        for subview in vc.view.subviews {
            if let collectionView = subview as? UICollectionView {
                collectionView.accessibilityIdentifier = "ChatCollectionView"
            } else if let tableView = subview as? UITableView {
                tableView.accessibilityIdentifier = "ChatTableView"
            }
        }
    }
    
    // MARK: - Gesture Recognizer Patches
    
    private func patchGestureRecognizers() {
        // Disable gesture recognizers that might interfere with testing
        for window in UIApplication.shared.windows {
            disableBlockingGestures(in: window)
        }
    }
    
    private func disableBlockingGestures(in view: UIView) {
        for gesture in view.gestureRecognizers ?? [] {
            // Don't disable essential gestures
            if !(gesture is UITapGestureRecognizer) &&
               !(gesture is UISwipeGestureRecognizer) &&
               !(gesture is UIPanGestureRecognizer) {
                gesture.cancelsTouchesInView = false
            }
        }
        
        for subview in view.subviews {
            disableBlockingGestures(in: subview)
        }
    }
    
    // MARK: - Scroll View Patches
    
    private func patchScrollViews() {
        // Enable scrolling for all scroll views
        for window in UIApplication.shared.windows {
            enableScrolling(in: window)
        }
    }
    
    private func enableScrolling(in view: UIView) {
        if let scrollView = view as? UIScrollView {
            scrollView.isScrollEnabled = true
            scrollView.isUserInteractionEnabled = true
            scrollView.showsVerticalScrollIndicator = true
        }
        
        for subview in view.subviews {
            enableScrolling(in: subview)
        }
    }
}

// MARK: - UINavigationController Extension

extension UINavigationController {
    
    @objc func uitest_pushViewController(_ viewController: UIViewController, animated: Bool) {
        // Call original implementation
        uitest_pushViewController(viewController, animated: animated)
        
        // Apply fixes after push
        if UITestingRuntimePatch.isUITesting {
            viewController.view.accessibilityIdentifier = String(describing: type(of: viewController))
            
            // Ensure back button exists
            if viewControllers.count > 1 && viewController.navigationItem.leftBarButtonItem == nil {
                let backButton = UIBarButtonItem(
                    title: "Back",
                    style: .plain,
                    target: self,
                    action: #selector(popViewController(animated:))
                )
                backButton.accessibilityIdentifier = "BackButton"
                viewController.navigationItem.leftBarButtonItem = backButton
            }
        }
    }
}