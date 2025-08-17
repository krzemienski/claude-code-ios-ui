//
//  MCPServerListViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-17.
//

import UIKit
import SwiftUI

/// UIKit wrapper for the SwiftUI MCPServerListView
public class MCPServerListViewController: UIViewController {
    
    // MARK: - Properties
    private var hostingController: UIHostingController<MCPServerListView>?
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupNavigationBar()
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Create SwiftUI view with view model
        let viewModel = MCPServerViewModel()
        let swiftUIView = MCPServerListView(viewModel: viewModel)
        
        // Create hosting controller
        let hostingController = UIHostingController(rootView: swiftUIView)
        self.hostingController = hostingController
        
        // Add as child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        // Setup constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        hostingController.didMove(toParent: self)
        
        // Apply cyberpunk theme to background
        view.backgroundColor = CyberpunkTheme.background
        hostingController.view.backgroundColor = CyberpunkTheme.background
    }
    
    private func setupNavigationBar() {
        title = "MCP Servers"
        
        // Add refresh button
        let refreshButton = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshServers)
        )
        refreshButton.tintColor = CyberpunkTheme.primaryCyan
        
        // Add button
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addServer)
        )
        addButton.tintColor = CyberpunkTheme.primaryCyan
        
        navigationItem.rightBarButtonItems = [addButton, refreshButton]
    }
    
    // MARK: - Actions
    @objc private func refreshServers() {
        // Trigger refresh in the SwiftUI view model
        if let hostingController = hostingController {
            // Access the view model through the hosting controller's root view
            let mirror = Mirror(reflecting: hostingController.rootView)
            for child in mirror.children {
                if let viewModel = child.value as? MCPServerViewModel {
                    Task {
                        await viewModel.loadServers()
                    }
                    break
                }
            }
        }
        
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    @objc private func addServer() {
        // Show add server alert
        let alert = UIAlertController(
            title: "Add MCP Server",
            message: "Enter server details",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Server Name"
            textField.textColor = .label
            textField.clearButtonMode = .whileEditing
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Server URL (e.g., ws://localhost:3000)"
            textField.textColor = .label
            textField.clearButtonMode = .whileEditing
            textField.keyboardType = .URL
            textField.autocapitalizationType = .none
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Type (stdio, websocket, http)"
            textField.textColor = .label
            textField.clearButtonMode = .whileEditing
            textField.autocapitalizationType = .none
        }
        
        alert.addTextField { textField in
            textField.placeholder = "API Key (optional)"
            textField.textColor = .label
            textField.clearButtonMode = .whileEditing
            textField.isSecureTextEntry = true
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let name = alert.textFields?[0].text, !name.isEmpty,
                  let url = alert.textFields?[1].text, !url.isEmpty,
                  let type = alert.textFields?[2].text, !type.isEmpty else {
                self?.showError("Please fill in all required fields")
                return
            }
            
            let apiKey = alert.textFields?[3].text
            
            // Add server through view model
            if let hostingController = self?.hostingController {
                let mirror = Mirror(reflecting: hostingController.rootView)
                for child in mirror.children {
                    if let viewModel = child.value as? MCPServerViewModel {
                        Task {
                            await viewModel.addServer(
                                name: name,
                                url: url,
                                type: type,
                                apiKey: apiKey
                            )
                        }
                        break
                    }
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        // Style the alert for cyberpunk theme
        alert.view.tintColor = CyberpunkTheme.primaryCyan
        
        present(alert, animated: true)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        alert.view.tintColor = CyberpunkTheme.primaryPink
        present(alert, animated: true)
    }
}