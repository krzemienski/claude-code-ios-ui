//
//  LaunchViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import UIKit

class LaunchViewController: UIViewController {
    
    // MARK: - Properties
    private let logoLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let versionLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let gridBackgroundView = GridBackgroundView()
    
    // MARK: - Gradient Blocks
    private let topLeftGradient = GradientBlock(type: .blue)
    private let bottomRightGradient = GradientBlock(type: .purple)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startAnimations()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        
        // Add grid background
        view.insertSubview(gridBackgroundView, at: 0)
        gridBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure logo
        logoLabel.text = "CLAUDE CODE"
        logoLabel.font = .systemFont(ofSize: 42, weight: .black)
        logoLabel.textColor = CyberpunkTheme.primaryCyan
        logoLabel.textAlignment = .center
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure subtitle
        subtitleLabel.text = "Mobile AI Companion"
        subtitleLabel.font = .systemFont(ofSize: 18, weight: .medium)
        subtitleLabel.textColor = CyberpunkTheme.textSecondary
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure version
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        versionLabel.text = "v\(version)"
        versionLabel.font = .systemFont(ofSize: 14, weight: .regular)
        versionLabel.textColor = CyberpunkTheme.textTertiary
        versionLabel.textAlignment = .center
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure loading indicator
        loadingIndicator.color = CyberpunkTheme.primaryCyan
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        
        // Configure gradient blocks
        topLeftGradient.translatesAutoresizingMaskIntoConstraints = false
        bottomRightGradient.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        view.addSubview(topLeftGradient)
        view.addSubview(bottomRightGradient)
        view.addSubview(logoLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(versionLabel)
        view.addSubview(loadingIndicator)
        
        // Layout
        NSLayoutConstraint.activate([
            // Grid background
            gridBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            gridBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Top left gradient
            topLeftGradient.topAnchor.constraint(equalTo: view.topAnchor, constant: -100),
            topLeftGradient.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -100),
            topLeftGradient.widthAnchor.constraint(equalToConstant: 300),
            topLeftGradient.heightAnchor.constraint(equalToConstant: 300),
            
            // Bottom right gradient
            bottomRightGradient.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 100),
            bottomRightGradient.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 100),
            bottomRightGradient.widthAnchor.constraint(equalToConstant: 300),
            bottomRightGradient.heightAnchor.constraint(equalToConstant: 300),
            
            // Logo
            logoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            
            // Subtitle
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: 8),
            
            // Version
            versionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            versionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 60)
        ])
    }
    
    // MARK: - Animations
    private func startAnimations() {
        // Fade in animation
        [logoLabel, subtitleLabel, versionLabel, loadingIndicator].forEach { $0.alpha = 0 }
        
        UIView.animate(withDuration: 0.8, delay: 0.2, options: .curveEaseOut) {
            self.logoLabel.alpha = 1
        }
        
        UIView.animate(withDuration: 0.8, delay: 0.4, options: .curveEaseOut) {
            self.subtitleLabel.alpha = 1
        }
        
        UIView.animate(withDuration: 0.8, delay: 0.6, options: .curveEaseOut) {
            self.versionLabel.alpha = 1
            self.loadingIndicator.alpha = 1
        }
        
        // Gradient rotation animation
        animateGradients()
    }
    
    private func animateGradients() {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = 0
        rotationAnimation.toValue = Double.pi * 2
        rotationAnimation.duration = 20
        rotationAnimation.repeatCount = .infinity
        
        topLeftGradient.layer.add(rotationAnimation, forKey: "rotation")
        
        let reverseRotation = CABasicAnimation(keyPath: "transform.rotation")
        reverseRotation.fromValue = 0
        reverseRotation.toValue = -Double.pi * 2
        reverseRotation.duration = 25
        reverseRotation.repeatCount = .infinity
        
        bottomRightGradient.layer.add(reverseRotation, forKey: "rotation")
    }
}