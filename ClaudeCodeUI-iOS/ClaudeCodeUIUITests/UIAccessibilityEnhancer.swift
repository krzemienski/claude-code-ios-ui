//
//  UIAccessibilityEnhancer.swift
//  ClaudeCodeUI
//
//  Accessibility Enhancement Utilities for UI Testing
//

import UIKit

/// Protocol for views that support enhanced accessibility
protocol AccessibilityEnhanced {
    func setupAccessibility()
}

/// Utility class to enhance accessibility across the app
class UIAccessibilityEnhancer {
    
    static let shared = UIAccessibilityEnhancer()
    
    private init() {}
    
    // MARK: - View Controller Enhancements
    
    func enhanceProjectsViewController(_ viewController: UIViewController) {
        // Main view
        viewController.view.accessibilityIdentifier = "ProjectsView"
        viewController.view.isAccessibilityElement = false
        
        // Navigation bar
        viewController.navigationItem.accessibilityLabel = "Projects"
        
        // Find and enhance collection/table views
        if let collectionView = findCollectionView(in: viewController.view) {
            collectionView.accessibilityIdentifier = "ProjectsCollectionView"
            collectionView.isAccessibilityElement = false
        }
        
        if let tableView = findTableView(in: viewController.view) {
            tableView.accessibilityIdentifier = "ProjectsTableView"
            tableView.isAccessibilityElement = false
        }
        
        // Enhance buttons
        enhanceButtons(in: viewController.view, prefix: "Projects")
    }
    
    func enhanceSessionsViewController(_ viewController: UIViewController) {
        // Main view
        viewController.view.accessibilityIdentifier = "SessionsView"
        viewController.view.isAccessibilityElement = false
        
        // Navigation bar
        viewController.navigationItem.accessibilityLabel = "Sessions"
        
        // Find and enhance table view
        if let tableView = findTableView(in: viewController.view) {
            tableView.accessibilityIdentifier = "SessionsTableView"
            tableView.isAccessibilityElement = false
        }
        
        // Enhance buttons
        enhanceButtons(in: viewController.view, prefix: "Sessions")
    }
    
    func enhanceChatViewController(_ viewController: UIViewController) {
        // Main view
        viewController.view.accessibilityIdentifier = "ChatView"
        viewController.view.isAccessibilityElement = false
        
        // Find and enhance collection/table views
        if let collectionView = findCollectionView(in: viewController.view) {
            collectionView.accessibilityIdentifier = "ChatCollectionView"
            collectionView.isAccessibilityElement = false
        }
        
        if let tableView = findTableView(in: viewController.view) {
            tableView.accessibilityIdentifier = "ChatTableView"
            tableView.isAccessibilityElement = false
        }
        
        // Find and enhance input views
        if let textView = findTextView(in: viewController.view) {
            textView.accessibilityIdentifier = "MessageInputTextView"
            textView.accessibilityLabel = "Message input"
            textView.accessibilityHint = "Type your message here"
        }
        
        // Find send button
        if let sendButton = findButton(in: viewController.view, withTitle: "Send") {
            sendButton.accessibilityIdentifier = "SendButton"
            sendButton.accessibilityLabel = "Send message"
        }
    }
    
    func enhanceSettingsViewController(_ viewController: UIViewController) {
        // Main view
        viewController.view.accessibilityIdentifier = "SettingsView"
        viewController.view.isAccessibilityElement = false
        
        // Navigation bar
        viewController.navigationItem.accessibilityLabel = "Settings"
        
        // Find and enhance table view
        if let tableView = findTableView(in: viewController.view) {
            tableView.accessibilityIdentifier = "SettingsTableView"
            tableView.isAccessibilityElement = false
        }
        
        // Enhance buttons
        enhanceButtons(in: viewController.view, prefix: "Settings")
    }
    
    func enhanceSearchViewController(_ viewController: UIViewController) {
        // Main view
        viewController.view.accessibilityIdentifier = "SearchView"
        viewController.view.isAccessibilityElement = false
        
        // Navigation bar
        viewController.navigationItem.accessibilityLabel = "Search"
        
        // Find and enhance search bar
        if let searchBar = findSearchBar(in: viewController.view) {
            searchBar.accessibilityIdentifier = "SearchBar"
            searchBar.accessibilityLabel = "Search"
            searchBar.searchTextField.accessibilityIdentifier = "SearchTextField"
        }
        
        // Find and enhance results view
        if let tableView = findTableView(in: viewController.view) {
            tableView.accessibilityIdentifier = "SearchResultsTableView"
            tableView.isAccessibilityElement = false
        }
    }
    
    // MARK: - Tab Bar Enhancement
    
    func enhanceTabBar(_ tabBarController: UITabBarController) {
        tabBarController.tabBar.accessibilityIdentifier = "MainTabBar"
        
        // Enhance each tab item
        if let items = tabBarController.tabBar.items {
            for (index, item) in items.enumerated() {
                switch index {
                case 0:
                    item.accessibilityIdentifier = "ProjectsTab"
                    item.accessibilityLabel = "Projects"
                case 1:
                    item.accessibilityIdentifier = "SessionsTab"
                    item.accessibilityLabel = "Sessions"
                case 2:
                    item.accessibilityIdentifier = "SearchTab"
                    item.accessibilityLabel = "Search"
                case 3:
                    item.accessibilityIdentifier = "SettingsTab"
                    item.accessibilityLabel = "Settings"
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Cell Enhancement
    
    func enhanceTableViewCell(_ cell: UITableViewCell, identifier: String, label: String) {
        cell.accessibilityIdentifier = identifier
        cell.accessibilityLabel = label
        cell.isAccessibilityElement = true
        cell.accessibilityTraits = .button
    }
    
    func enhanceCollectionViewCell(_ cell: UICollectionViewCell, identifier: String, label: String) {
        cell.accessibilityIdentifier = identifier
        cell.accessibilityLabel = label
        cell.isAccessibilityElement = true
        cell.accessibilityTraits = .button
    }
    
    // MARK: - Private Helper Methods
    
    private func findCollectionView(in view: UIView) -> UICollectionView? {
        if let collectionView = view as? UICollectionView {
            return collectionView
        }
        
        for subview in view.subviews {
            if let found = findCollectionView(in: subview) {
                return found
            }
        }
        return nil
    }
    
    private func findTableView(in view: UIView) -> UITableView? {
        if let tableView = view as? UITableView {
            return tableView
        }
        
        for subview in view.subviews {
            if let found = findTableView(in: subview) {
                return found
            }
        }
        return nil
    }
    
    private func findTextView(in view: UIView) -> UITextView? {
        if let textView = view as? UITextView {
            return textView
        }
        
        for subview in view.subviews {
            if let found = findTextView(in: subview) {
                return found
            }
        }
        return nil
    }
    
    private func findSearchBar(in view: UIView) -> UISearchBar? {
        if let searchBar = view as? UISearchBar {
            return searchBar
        }
        
        for subview in view.subviews {
            if let found = findSearchBar(in: subview) {
                return found
            }
        }
        return nil
    }
    
    private func findButton(in view: UIView, withTitle title: String) -> UIButton? {
        if let button = view as? UIButton,
           button.titleLabel?.text == title {
            return button
        }
        
        for subview in view.subviews {
            if let found = findButton(in: subview, withTitle: title) {
                return found
            }
        }
        return nil
    }
    
    private func enhanceButtons(in view: UIView, prefix: String) {
        var buttonIndex = 0
        enhanceButtonsRecursive(in: view, prefix: prefix, index: &buttonIndex)
    }
    
    private func enhanceButtonsRecursive(in view: UIView, prefix: String, index: inout Int) {
        if let button = view as? UIButton {
            if button.accessibilityIdentifier == nil {
                button.accessibilityIdentifier = "\(prefix)Button\(index)"
                index += 1
            }
            if button.accessibilityLabel == nil {
                button.accessibilityLabel = button.titleLabel?.text ?? "Button"
            }
        }
        
        for subview in view.subviews {
            enhanceButtonsRecursive(in: subview, prefix: prefix, index: &index)
        }
    }
}

// MARK: - UIViewController Extension

extension UIViewController {
    
    /// Automatically enhance accessibility based on view controller type
    func autoEnhanceAccessibility() {
        let enhancer = UIAccessibilityEnhancer.shared
        
        switch String(describing: type(of: self)) {
        case "ProjectsViewController":
            enhancer.enhanceProjectsViewController(self)
        case "SessionsViewController", "SessionListViewController":
            enhancer.enhanceSessionsViewController(self)
        case "ChatViewController":
            enhancer.enhanceChatViewController(self)
        case "SettingsViewController":
            enhancer.enhanceSettingsViewController(self)
        case "SearchViewController":
            enhancer.enhanceSearchViewController(self)
        default:
            // Generic enhancement
            view.accessibilityIdentifier = String(describing: type(of: self))
        }
    }
}

// MARK: - Accessibility Validation

class AccessibilityValidator {
    
    static func validateViewController(_ viewController: UIViewController) -> [String] {
        var issues: [String] = []
        
        // Check main view
        if viewController.view.accessibilityIdentifier == nil {
            issues.append("Main view missing accessibility identifier")
        }
        
        // Check navigation
        if viewController.navigationItem.accessibilityLabel == nil {
            issues.append("Navigation item missing accessibility label")
        }
        
        // Check common UI elements
        validateViewRecursive(viewController.view, issues: &issues)
        
        return issues
    }
    
    private static func validateViewRecursive(_ view: UIView, issues: inout [String]) {
        // Check buttons
        if let button = view as? UIButton {
            if button.accessibilityIdentifier == nil && button.isUserInteractionEnabled {
                issues.append("Button missing accessibility identifier: \(button)")
            }
        }
        
        // Check text fields
        if let textField = view as? UITextField {
            if textField.accessibilityIdentifier == nil {
                issues.append("TextField missing accessibility identifier")
            }
        }
        
        // Check text views
        if let textView = view as? UITextView {
            if textView.accessibilityIdentifier == nil && textView.isEditable {
                issues.append("Editable TextView missing accessibility identifier")
            }
        }
        
        // Recurse through subviews
        for subview in view.subviews {
            validateViewRecursive(subview, issues: &issues)
        }
    }
}