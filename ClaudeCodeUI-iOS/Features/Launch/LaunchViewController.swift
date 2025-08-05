//
//  LaunchViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import UIKit

class LaunchViewController: UIViewController {
    
    private let logoLabel = UILabel()
    private let gradientBlocks = GradientBlockPair()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Simulate loading and then transition to auth
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.showAuthentication()
        }
    }
    
    private func setupUI() {
        // Add grid background
        view.addClaudeCodeGridBackground()
        
        // Configure navigation
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Logo label
        logoLabel.text = "CLAUDE CODE"
        logoLabel.font = Typography.largeTitle
        logoLabel.textColor = CyberpunkTheme.primaryCyan
        logoLabel.textAlignment = .center
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Gradient blocks
        gradientBlocks.translatesAutoresizingMaskIntoConstraints = false
        
        // Loading indicator
        loadingIndicator.color = CyberpunkTheme.primaryCyan
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        
        // Add subviews
        view.addSubview(logoLabel)
        view.addSubview(gradientBlocks)
        view.addSubview(loadingIndicator)
        
        // Layout
        NSLayoutConstraint.activate([
            // Logo
            logoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            
            // Gradient blocks
            gradientBlocks.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gradientBlocks.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: 40),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: gradientBlocks.bottomAnchor, constant: 60)
        ])
        
        // Animate gradient blocks
        animateGradientBlocks()
    }
    
    private func animateGradientBlocks() {
        // Scale animation
        gradientBlocks.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       options: [.repeat, .autoreverse],
                       animations: {
            self.gradientBlocks.transform = .identity
        })
    }
    
    private func showAuthentication() {
        // For now, just log that we would show authentication
        print("Would show authentication screen")
        
        // Create a simple projects placeholder
        let projectsVC = UIViewController()
        projectsVC.view.backgroundColor = CyberpunkTheme.background
        projectsVC.title = "Projects"
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.pushViewController(projectsVC, animated: true)
    }
}