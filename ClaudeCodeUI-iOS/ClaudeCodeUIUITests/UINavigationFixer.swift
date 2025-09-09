//
//  UINavigationFixer.swift
//  ClaudeCodeUI
//
//  Runtime UI Navigation Fixes for Testing
//

import UIKit

/// Utility to fix common UI navigation issues at runtime
class UINavigationFixer {
    
    static let shared = UINavigationFixer()
    
    private init() {}
    
    // MARK: - Navigation Controller Fixes
    
    func fixNavigationController(_ navigationController: UINavigationController) {
        // Ensure navigation bar is visible
        navigationController.setNavigationBarHidden(false, animated: false)
        
        // Enable interactive pop gesture
        navigationController.interactivePopGestureRecognizer?.isEnabled = true
        navigationController.interactivePopGestureRecognizer?.delegate = nil
        
        // Fix navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        
        // Ensure proper delegate
        if navigationController.delegate == nil {
            navigationController.delegate = NavigationControllerDelegate.shared
        }
    }
    
    func fixBackButton(for viewController: UIViewController) {
        // Ensure back button exists
        if viewController.navigationItem.leftBarButtonItem == nil &&
           viewController.navigationController?.viewControllers.count ?? 0 > 1 {
            
            let backButton = UIBarButtonItem(
                title: "Back",
                style: .plain,
                target: viewController.navigationController,
                action: #selector(UINavigationController.popViewController(animated:))
            )
            backButton.accessibilityIdentifier = "BackButton"
            viewController.navigationItem.leftBarButtonItem = backButton
        }
    }
    
    // MARK: - Tab Bar Fixes
    
    func fixTabBarController(_ tabBarController: UITabBarController) {
        // Ensure tab bar is visible
        tabBarController.tabBar.isHidden = false
        tabBarController.tabBar.isTranslucent = false
        
        // Fix tab bar items
        guard let viewControllers = tabBarController.viewControllers else { return }
        
        for (index, vc) in viewControllers.enumerated() {
            // Wrap in navigation controller if needed
            if !(vc is UINavigationController) {
                let navController = UINavigationController(rootViewController: vc)
                tabBarController.viewControllers?[index] = navController
                fixNavigationController(navController)
            }
            
            // Fix tab bar item
            let tabBarItem = vc.tabBarItem ?? UITabBarItem()
            
            switch index {
            case 0:
                tabBarItem.title = "Projects"
                tabBarItem.image = UIImage(systemName: "folder")
                tabBarItem.accessibilityIdentifier = "ProjectsTab"
            case 1:
                tabBarItem.title = "Sessions"
                tabBarItem.image = UIImage(systemName: "message")
                tabBarItem.accessibilityIdentifier = "SessionsTab"
            case 2:
                tabBarItem.title = "Search"
                tabBarItem.image = UIImage(systemName: "magnifyingglass")
                tabBarItem.accessibilityIdentifier = "SearchTab"
            case 3:
                tabBarItem.title = "Settings"
                tabBarItem.image = UIImage(systemName: "gearshape")
                tabBarItem.accessibilityIdentifier = "SettingsTab"
            default:
                break
            }
            
            vc.tabBarItem = tabBarItem
        }
    }
    
    // MARK: - Collection/Table View Fixes
    
    func fixCollectionView(_ collectionView: UICollectionView) {
        // Ensure collection view is interactive
        collectionView.isUserInteractionEnabled = true
        collectionView.allowsSelection = true
        
        // Fix scroll indicators
        collectionView.showsVerticalScrollIndicator = true
        collectionView.showsHorizontalScrollIndicator = false
        
        // Ensure proper content insets
        if collectionView.contentInset == .zero {
            collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        }
        
        // Fix accessibility
        collectionView.isAccessibilityElement = false
        
        // Reload if no items
        if collectionView.numberOfSections == 0 {
            collectionView.reloadData()
        }
    }
    
    func fixTableView(_ tableView: UITableView) {
        // Ensure table view is interactive
        tableView.isUserInteractionEnabled = true
        tableView.allowsSelection = true
        
        // Fix separators
        tableView.separatorStyle = .singleLine
        
        // Ensure proper content insets
        if tableView.contentInset == .zero {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        }
        
        // Fix accessibility
        tableView.isAccessibilityElement = false
        
        // Reload if no items
        if tableView.numberOfSections == 0 {
            tableView.reloadData()
        }
    }
    
    // MARK: - Touch Event Fixes
    
    func fixTouchHandling(for view: UIView) {
        // Ensure view can receive touches
        view.isUserInteractionEnabled = true
        
        // Remove any blocking gesture recognizers
        for gesture in view.gestureRecognizers ?? [] {
            if gesture.isEnabled && gesture.cancelsTouchesInView {
                gesture.cancelsTouchesInView = false
            }
        }
        
        // Fix subviews
        for subview in view.subviews {
            if subview.alpha > 0 && !subview.isHidden {
                fixTouchHandling(for: subview)
            }
        }
    }
    
    // MARK: - SwiftUI Integration Fixes
    
    func fixSwiftUIHosting(_ hostingController: UIViewController) {
        // Ensure proper embedding
        if hostingController.view.superview == nil {
            return
        }
        
        // Fix constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: hostingController.view.superview!.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: hostingController.view.superview!.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: hostingController.view.superview!.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: hostingController.view.superview!.bottomAnchor)
        ])
        
        // Fix interaction
        hostingController.view.isUserInteractionEnabled = true
    }
    
    // MARK: - Input Field Fixes
    
    func fixTextInput(_ textField: UITextField) {
        textField.isUserInteractionEnabled = true
        textField.isEnabled = true
        
        // Add accessibility
        if textField.accessibilityIdentifier == nil {
            textField.accessibilityIdentifier = "TextField"
        }
        
        // Fix keyboard
        textField.autocorrectionType = .default
        textField.autocapitalizationType = .sentences
    }
    
    func fixTextView(_ textView: UITextView) {
        textView.isUserInteractionEnabled = true
        textView.isEditable = true
        
        // Add accessibility
        if textView.accessibilityIdentifier == nil {
            textView.accessibilityIdentifier = "TextView"
        }
        
        // Fix keyboard
        textView.autocorrectionType = .default
        textView.autocapitalizationType = .sentences
    }
    
    // MARK: - Button Fixes
    
    func fixButton(_ button: UIButton) {
        button.isUserInteractionEnabled = true
        button.isEnabled = true
        
        // Add accessibility
        if button.accessibilityIdentifier == nil {
            button.accessibilityIdentifier = "Button"
        }
        
        // Ensure touch target size
        if button.frame.width < 44 || button.frame.height < 44 {
            button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        }
    }
    
    // MARK: - Comprehensive Fix
    
    func applyComprehensiveFixes(to viewController: UIViewController) {
        // Fix navigation
        if let nav = viewController.navigationController {
            fixNavigationController(nav)
        }
        fixBackButton(for: viewController)
        
        // Fix tab bar
        if let tabBar = viewController.tabBarController {
            fixTabBarController(tabBar)
        }
        
        // Fix views
        fixViewHierarchy(viewController.view)
        
        // Fix touch handling
        fixTouchHandling(for: viewController.view)
        
        // Apply accessibility
        viewController.autoEnhanceAccessibility()
    }
    
    private func fixViewHierarchy(_ view: UIView) {
        // Fix collection views
        if let collectionView = view as? UICollectionView {
            fixCollectionView(collectionView)
        }
        
        // Fix table views
        if let tableView = view as? UITableView {
            fixTableView(tableView)
        }
        
        // Fix text fields
        if let textField = view as? UITextField {
            fixTextInput(textField)
        }
        
        // Fix text views
        if let textView = view as? UITextView {
            fixTextView(textView)
        }
        
        // Fix buttons
        if let button = view as? UIButton {
            fixButton(button)
        }
        
        // Recurse through subviews
        for subview in view.subviews {
            fixViewHierarchy(subview)
        }
    }
}

// MARK: - Navigation Controller Delegate

class NavigationControllerDelegate: NSObject, UINavigationControllerDelegate {
    static let shared = NavigationControllerDelegate()
    
    func navigationController(_ navigationController: UINavigationController,
                            didShow viewController: UIViewController,
                            animated: Bool) {
        // Fix any issues after navigation
        UINavigationFixer.shared.fixBackButton(for: viewController)
        viewController.autoEnhanceAccessibility()
    }
    
    func navigationController(_ navigationController: UINavigationController,
                            willShow viewController: UIViewController,
                            animated: Bool) {
        // Prepare view controller
        UINavigationFixer.shared.applyComprehensiveFixes(to: viewController)
    }
}