//
//  TypingIndicatorCell.swift
//  ClaudeCodeUI
//
//  Created by iOS Swift Developer on 2025-01-22.
//  Implements CM-Chat-01: Typing indicator cell for table view
//

import UIKit

/// Table view cell that displays the typing indicator animation
class TypingIndicatorCell: UITableViewCell {
    
    // MARK: - Properties
    
    static let identifier = "TypingIndicatorCell"
    private let typingIndicatorView = UIKitTypingIndicatorView()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Configure cell appearance
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        
        // Add typing indicator view
        contentView.addSubview(typingIndicatorView)
        typingIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup constraints
        NSLayoutConstraint.activate([
            typingIndicatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            typingIndicatorView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            typingIndicatorView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            typingIndicatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        // Set accessibility
        accessibilityIdentifier = "typingIndicatorCell"
        accessibilityLabel = "Claude is typing"
        accessibilityHint = "Waiting for Claude's response"
    }
    
    // MARK: - Lifecycle
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Stop animation when cell is being reused
        typingIndicatorView.stopAnimating()
    }
    
    // MARK: - Public Methods
    
    /// Start the typing animation
    func startAnimating() {
        typingIndicatorView.startAnimating()
    }
    
    /// Stop the typing animation
    func stopAnimating() {
        typingIndicatorView.stopAnimating()
    }
    
    /// Update the typing text
    func updateText(_ text: String) {
        typingIndicatorView.updateText(text)
    }
    
    /// Check if currently animating
    var isAnimating: Bool {
        return typingIndicatorView.isAnimating
    }
}