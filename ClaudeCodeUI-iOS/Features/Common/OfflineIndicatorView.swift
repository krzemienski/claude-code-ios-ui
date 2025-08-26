//
//  OfflineIndicatorView.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-26.
//

import UIKit
import Combine

// MARK: - Offline Indicator View

/// A view that displays network status and offline mode indicator
class OfflineIndicatorView: UIView {
    
    // MARK: - Properties
    
    private let containerView = UIView()
    private let statusIcon = UIImageView()
    private let statusLabel = UILabel()
    private let syncButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    private var cancellables = Set<AnyCancellable>()
    private let offlineManager = OfflineManager.shared
    private var isSyncing = false
    
    // Animation
    private var pulseAnimation: CABasicAnimation?
    private var scanlineAnimation: CAGradientLayer?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        observeNetworkStatus()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        observeNetworkStatus()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Container setup
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        containerView.layer.cornerRadius = 20
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemCyan.cgColor
        
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Status icon
        statusIcon.contentMode = .scaleAspectFit
        statusIcon.tintColor = .systemCyan
        containerView.addSubview(statusIcon)
        statusIcon.translatesAutoresizingMaskIntoConstraints = false
        
        // Status label
        statusLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        statusLabel.textColor = .systemCyan
        statusLabel.textAlignment = .center
        containerView.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Sync button
        syncButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        syncButton.tintColor = .systemCyan
        syncButton.isHidden = true
        syncButton.addTarget(self, action: #selector(syncTapped), for: .touchUpInside)
        containerView.addSubview(syncButton)
        syncButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Activity indicator
        activityIndicator.color = .systemCyan
        activityIndicator.hidesWhenStopped = true
        containerView.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // Layout
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 40),
            
            // Icon
            statusIcon.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            statusIcon.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            statusIcon.widthAnchor.constraint(equalToConstant: 20),
            statusIcon.heightAnchor.constraint(equalToConstant: 20),
            
            // Label
            statusLabel.leadingAnchor.constraint(equalTo: statusIcon.trailingAnchor, constant: 8),
            statusLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            // Sync button
            syncButton.leadingAnchor.constraint(equalTo: statusLabel.trailingAnchor, constant: 8),
            syncButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            syncButton.widthAnchor.constraint(equalToConstant: 30),
            syncButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: syncButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: syncButton.centerYAnchor),
            
            // Container width
            containerView.trailingAnchor.constraint(equalTo: syncButton.trailingAnchor, constant: 12)
        ])
        
        // Initial state
        isHidden = true
        alpha = 0
    }
    
    // MARK: - Network Observation
    
    private func observeNetworkStatus() {
        // Observe offline status
        offlineManager.$isOffline
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isOffline in
                self?.updateUI(isOffline: isOffline)
            }
            .store(in: &cancellables)
        
        // Observe connection type
        offlineManager.$connectionType
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connectionType in
                self?.updateConnectionType(connectionType)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - UI Updates
    
    private func updateUI(isOffline: Bool) {
        if isOffline {
            show()
            statusLabel.text = "Offline Mode"
            statusIcon.image = UIImage(systemName: "wifi.slash")
            containerView.layer.borderColor = UIColor.systemOrange.cgColor
            statusIcon.tintColor = .systemOrange
            statusLabel.textColor = .systemOrange
            syncButton.tintColor = .systemOrange
            startPulseAnimation()
            
            // Show sync button if there are pending changes
            syncButton.isHidden = !offlineManager.requiresSync()
        } else {
            if offlineManager.requiresSync() && !isSyncing {
                // Show syncing state
                statusLabel.text = "Syncing..."
                statusIcon.image = UIImage(systemName: "arrow.triangle.2.circlepath")
                containerView.layer.borderColor = UIColor.systemGreen.cgColor
                statusIcon.tintColor = .systemGreen
                statusLabel.textColor = .systemGreen
                startSyncAnimation()
                
                // Hide after sync completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.hide()
                }
            } else {
                hide()
            }
            stopPulseAnimation()
        }
    }
    
    private func updateConnectionType(_ type: OfflineManager.ConnectionType) {
        guard !isHidden else { return }
        
        switch type {
        case .cellular:
            statusLabel.text = "Cellular • Offline Mode"
        case .wifi:
            statusLabel.text = "WiFi • Limited"
        case .ethernet:
            statusLabel.text = "Ethernet • Limited"
        case .unknown:
            statusLabel.text = "Unknown Connection"
        case .offline:
            statusLabel.text = "Offline Mode"
        }
    }
    
    // MARK: - Actions
    
    @objc private func syncTapped() {
        guard !isSyncing else { return }
        
        isSyncing = true
        syncButton.isHidden = true
        activityIndicator.startAnimating()
        
        Task {
            do {
                try await offlineManager.forceSyncNow()
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.syncButton.isHidden = false
                    self.isSyncing = false
                    NotificationManager.shared.showSuccess("Changes synced successfully")
                }
            } catch {
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.syncButton.isHidden = false
                    self.isSyncing = false
                    NotificationManager.shared.showError(error)
                }
            }
        }
    }
    
    // MARK: - Animations
    
    private func show() {
        guard isHidden else { return }
        
        isHidden = false
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.alpha = 1
            self.transform = .identity
        }
    }
    
    private func hide() {
        guard !isHidden else { return }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            self.isHidden = true
        }
    }
    
    private func startPulseAnimation() {
        pulseAnimation = CABasicAnimation(keyPath: "opacity")
        pulseAnimation?.fromValue = 1.0
        pulseAnimation?.toValue = 0.3
        pulseAnimation?.duration = 1.5
        pulseAnimation?.autoreverses = true
        pulseAnimation?.repeatCount = .infinity
        statusIcon.layer.add(pulseAnimation!, forKey: "pulse")
    }
    
    private func stopPulseAnimation() {
        statusIcon.layer.removeAnimation(forKey: "pulse")
        pulseAnimation = nil
    }
    
    private func startSyncAnimation() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = 1.0
        rotation.isCumulative = true
        rotation.repeatCount = .infinity
        statusIcon.layer.add(rotation, forKey: "rotation")
    }
    
    private func stopSyncAnimation() {
        statusIcon.layer.removeAnimation(forKey: "rotation")
    }
}

// MARK: - Offline Badge View

/// A small badge view to show offline status on specific screens
class OfflineBadgeView: UIView {
    
    // MARK: - Properties
    
    private let iconView = UIImageView()
    private let countLabel = UILabel()
    private var cancellables = Set<AnyCancellable>()
    
    var pendingCount: Int = 0 {
        didSet {
            updateBadge()
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        observeOfflineStatus()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        observeOfflineStatus()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = UIColor.systemOrange
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.systemOrange.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8
        layer.shadowOpacity = 0.5
        
        // Icon
        iconView.image = UIImage(systemName: "arrow.triangle.2.circlepath")
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        addSubview(iconView)
        
        // Count label
        countLabel.font = .systemFont(ofSize: 10, weight: .bold)
        countLabel.textColor = .white
        countLabel.textAlignment = .center
        addSubview(countLabel)
        
        // Layout
        iconView.translatesAutoresizingMaskIntoConstraints = false
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -2),
            iconView.widthAnchor.constraint(equalToConstant: 14),
            iconView.heightAnchor.constraint(equalToConstant: 14),
            
            countLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            countLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: -2),
            
            widthAnchor.constraint(equalToConstant: 24),
            heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Initial state
        isHidden = true
    }
    
    // MARK: - Observation
    
    private func observeOfflineStatus() {
        OfflineManager.shared.$isOffline
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isOffline in
                self?.isHidden = !isOffline || self?.pendingCount == 0
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Updates
    
    private func updateBadge() {
        countLabel.text = pendingCount > 99 ? "99+" : "\(pendingCount)"
        isHidden = pendingCount == 0 || !OfflineManager.shared.isOffline
        
        // Pulse animation when count changes
        if !isHidden && pendingCount > 0 {
            UIView.animate(withDuration: 0.2, animations: {
                self.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }) { _ in
                UIView.animate(withDuration: 0.2) {
                    self.transform = .identity
                }
            }
        }
    }
}