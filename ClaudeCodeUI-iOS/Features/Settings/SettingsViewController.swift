//
//  SettingsViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/05.
//

import UIKit

class SettingsViewController: BaseViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        title = "Settings"
        
        // Add close button
        let closeButton = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(dismissSettings)
        )
        closeButton.tintColor = CyberpunkTheme.primaryCyan
        navigationItem.rightBarButtonItem = closeButton
        
        // Placeholder - will be implemented later
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Settings - Phase 6"
        label.font = CyberpunkTheme.headingFont
        label.textColor = CyberpunkTheme.secondaryText
        label.textAlignment = .center
        
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func dismissSettings() {
        dismiss(animated: true)
    }
}