//
//  ChatViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/05.
//

import UIKit

class ChatViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let project: Project
    
    // MARK: - Initialization
    
    init(project: Project) {
        self.project = project
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        title = project.name
        
        // Placeholder - will be implemented in Phase 3
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Chat Interface - Phase 3"
        label.font = CyberpunkTheme.headingFont
        label.textColor = CyberpunkTheme.secondaryText
        label.textAlignment = .center
        
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}