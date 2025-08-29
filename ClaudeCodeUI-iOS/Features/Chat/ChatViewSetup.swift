//
//  ChatViewSetup.swift
//  ClaudeCodeUI
//
//  Created by Refactoring on 2025-01-21.
//

import UIKit

// MARK: - Chat View Setup Extension

extension ChatViewController {
    
    // MARK: - UI Component Creation
    
    func createTableView() -> UITableView {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.keyboardDismissMode = .interactive
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tableView.alwaysBounceVertical = true
        return tableView
    }
    
    func createInputContainerView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = CyberpunkTheme.surface
        view.layer.borderWidth = 1
        view.layer.borderColor = CyberpunkTheme.border.cgColor
        
        // Add top glow effect
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            CyberpunkTheme.primaryCyan.withAlphaComponent(0.3).cgColor,
            UIColor.clear.cgColor
        ]
        gradientLayer.locations = [0, 0.5]
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 2)
        view.layer.addSublayer(gradientLayer)
        
        return view
    }
    
    func createInputTextView() -> UITextView {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = CyberpunkTheme.background
        textView.textColor = CyberpunkTheme.primaryText
        textView.font = CyberpunkTheme.bodyFont
        textView.tintColor = CyberpunkTheme.primaryCyan
        textView.layer.cornerRadius = 20
        textView.layer.borderWidth = 1
        textView.layer.borderColor = CyberpunkTheme.border.cgColor
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        textView.isScrollEnabled = false
        textView.accessibilityIdentifier = "chatInputTextView"
        return textView
    }
    
    func createPlaceholderLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Type a message..."
        label.font = CyberpunkTheme.bodyFont
        label.textColor = CyberpunkTheme.secondaryText
        return label
    }
    
    func createSendButton() -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        button.tintColor = CyberpunkTheme.primaryCyan
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.isEnabled = false
        button.accessibilityIdentifier = "chatSendButton"
        return button
    }
    
    func createAttachButton() -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.tintColor = CyberpunkTheme.primaryCyan
        return button
    }
    
    func createConnectionStatusView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = CyberpunkTheme.surface
        view.isHidden = true
        return view
    }
    
    func createConnectionStatusLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = CyberpunkTheme.secondaryText
        label.textAlignment = .center
        label.text = "Connecting..."
        return label
    }
    
    func createConnectionIndicatorView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = CyberpunkTheme.warning
        view.layer.cornerRadius = 4
        view.frame.size = CGSize(width: 8, height: 8)
        return view
    }
    
    func createTypingIndicator() -> UIView {
        return AnimationManager.shared.createTypingIndicator()
    }
    
    // MARK: - Layout Setup
    
    func setupMainLayout() {
        view.backgroundColor = CyberpunkTheme.background
        
        // Add all subviews
        view.addSubview(connectionStatusView)
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(inputContainerView)
        
        // Add input components to container
        inputContainerView.addSubview(attachButton)
        inputContainerView.addSubview(inputTextView)
        inputContainerView.addSubview(sendButton)
        inputTextView.addSubview(placeholderLabel)
        
        // Add status components
        connectionStatusView.addSubview(connectionStatusLabel)
        connectionStatusView.addSubview(connectionIndicatorView)
    }
    
    func setupConstraints() {
        // Create constraints
        inputContainerBottomConstraint = inputContainerView.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor
        )
        inputTextViewHeightConstraint = inputTextView.heightAnchor.constraint(equalToConstant: 44)
        connectionStatusHeightConstraint = connectionStatusView.heightAnchor.constraint(equalToConstant: 0)
        
        NSLayoutConstraint.activate([
            // Connection status view
            connectionStatusView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            connectionStatusView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            connectionStatusView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            connectionStatusHeightConstraint,
            
            // Connection status label
            connectionStatusLabel.centerYAnchor.constraint(equalTo: connectionStatusView.centerYAnchor),
            connectionStatusLabel.centerXAnchor.constraint(equalTo: connectionStatusView.centerXAnchor),
            
            // Connection indicator
            connectionIndicatorView.centerYAnchor.constraint(equalTo: connectionStatusView.centerYAnchor),
            connectionIndicatorView.trailingAnchor.constraint(equalTo: connectionStatusLabel.leadingAnchor, constant: -8),
            connectionIndicatorView.widthAnchor.constraint(equalToConstant: 8),
            connectionIndicatorView.heightAnchor.constraint(equalToConstant: 8),
            
            // Table view
            tableView.topAnchor.constraint(equalTo: connectionStatusView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor),
            
            // Input container
            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainerBottomConstraint,
            
            // Attach button
            attachButton.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 12),
            attachButton.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -12),
            attachButton.widthAnchor.constraint(equalToConstant: 30),
            attachButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Input text view
            inputTextView.leadingAnchor.constraint(equalTo: attachButton.trailingAnchor, constant: 8),
            inputTextView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            inputTextView.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 8),
            inputTextView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -8),
            inputTextViewHeightConstraint,
            
            // Send button
            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -12),
            sendButton.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -12),
            sendButton.widthAnchor.constraint(equalToConstant: 34),
            sendButton.heightAnchor.constraint(equalToConstant: 34),
            
            // Placeholder
            placeholderLabel.leadingAnchor.constraint(equalTo: inputTextView.leadingAnchor, constant: 20),
            placeholderLabel.centerYAnchor.constraint(equalTo: inputTextView.centerYAnchor),
            
            // Empty state view
            emptyStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor)
        ])
    }
    
    // MARK: - Navigation Bar Setup
    
    func setupNavigationItems() {
        title = project.displayName
        
        // Add file explorer button
        let fileButton = UIBarButtonItem(
            image: UIImage(systemName: "folder"),
            style: .plain,
            target: self,
            action: #selector(showFileExplorer)
        )
        fileButton.tintColor = CyberpunkTheme.primaryCyan
        fileButton.accessibilityIdentifier = "fileExplorerButton"
        
        // Add terminal button
        let terminalButton = UIBarButtonItem(
            image: UIImage(systemName: "terminal"),
            style: .plain,
            target: self,
            action: #selector(showTerminal)
        )
        terminalButton.tintColor = CyberpunkTheme.primaryCyan
        
        // Add abort session button
        let abortButton = UIBarButtonItem(
            image: UIImage(systemName: "stop.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(abortSession)
        )
        abortButton.tintColor = CyberpunkTheme.accentPink
        
        navigationItem.rightBarButtonItems = [abortButton, terminalButton, fileButton]
    }
    
    // MARK: - Pull to Refresh Setup
    
    func setupRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = CyberpunkTheme.primaryCyan
        refreshControl.backgroundColor = CyberpunkTheme.surface.withAlphaComponent(0.3)
        
        // Custom attributed title
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: CyberpunkTheme.textSecondary,
            .font: UIFont.systemFont(ofSize: 14, weight: .medium)
        ]
        refreshControl.attributedTitle = NSAttributedString(
            string: "↻ Loading message history...",
            attributes: attributes
        )
        
        refreshControl.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    // MARK: - Connection Status UI
    
    func updateConnectionStatusUI(status: ChatViewModel.ConnectionStatus) {
        let shouldShow = status != .connected
        
        connectionStatusLabel.text = status.displayText
        connectionIndicatorView.backgroundColor = status.statusColor
        
        // Animate status bar visibility
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.connectionStatusHeightConstraint.constant = shouldShow ? 28 : 0
            self?.connectionStatusView.isHidden = !shouldShow
            self?.view.layoutIfNeeded()
        }
        
        // Add pulsing animation for connecting states
        switch status {
        case .connecting, .reconnecting:
            startPulsingAnimation()
        default:
            stopPulsingAnimation()
        }
    }
    
    private func startPulsingAnimation() {
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.duration = 1.0
        pulse.fromValue = 1.0
        pulse.toValue = 0.3
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        connectionIndicatorView.layer.add(pulse, forKey: "pulse")
    }
    
    private func stopPulsingAnimation() {
        connectionIndicatorView.layer.removeAnimation(forKey: "pulse")
    }
}