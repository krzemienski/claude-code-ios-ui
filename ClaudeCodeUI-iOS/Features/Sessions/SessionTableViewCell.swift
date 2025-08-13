//
//  SessionTableViewCell.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-13.
//

import UIKit

class SessionTableViewCell: UITableViewCell {
    // MARK: - UI Elements
    private let summaryLabel = UILabel()
    private let messageCountBadge = UILabel()
    private let timestampLabel = UILabel()
    private let cwdLabel = UILabel()
    private let containerView = UIView()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        selectionStyle = .none
        
        // Container view with cyberpunk styling
        containerView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        containerView.layer.cornerRadius = 8
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 0, green: 0.85, blue: 1, alpha: 0.3).cgColor // Cyan border
        
        // Summary label
        summaryLabel.textColor = .white
        summaryLabel.font = .systemFont(ofSize: 16, weight: .medium)
        summaryLabel.numberOfLines = 2
        
        // Message count badge
        messageCountBadge.backgroundColor = UIColor(red: 1, green: 0, blue: 0.43, alpha: 1.0) // Pink
        messageCountBadge.textColor = .white
        messageCountBadge.font = .systemFont(ofSize: 12, weight: .bold)
        messageCountBadge.textAlignment = .center
        messageCountBadge.layer.cornerRadius = 12
        messageCountBadge.layer.masksToBounds = true
        
        // Timestamp label
        timestampLabel.textColor = UIColor(red: 0, green: 0.85, blue: 1, alpha: 0.7) // Cyan
        timestampLabel.font = .systemFont(ofSize: 12)
        
        // CWD label
        cwdLabel.textColor = UIColor.lightGray
        cwdLabel.font = .systemFont(ofSize: 11)
        cwdLabel.numberOfLines = 1
        
        // Add subviews
        contentView.addSubview(containerView)
        containerView.addSubview(summaryLabel)
        containerView.addSubview(messageCountBadge)
        containerView.addSubview(timestampLabel)
        containerView.addSubview(cwdLabel)
        
        // Setup constraints
        containerView.translatesAutoresizingMaskIntoConstraints = false
        summaryLabel.translatesAutoresizingMaskIntoConstraints = false
        messageCountBadge.translatesAutoresizingMaskIntoConstraints = false
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        cwdLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            // Summary label
            summaryLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            summaryLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            summaryLabel.trailingAnchor.constraint(equalTo: messageCountBadge.leadingAnchor, constant: -8),
            
            // Message count badge
            messageCountBadge.centerYAnchor.constraint(equalTo: summaryLabel.centerYAnchor),
            messageCountBadge.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            messageCountBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 24),
            messageCountBadge.heightAnchor.constraint(equalToConstant: 24),
            
            // Timestamp label
            timestampLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            timestampLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            
            // CWD label
            cwdLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            cwdLabel.leadingAnchor.constraint(equalTo: timestampLabel.trailingAnchor, constant: 12),
            cwdLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12)
        ])
    }
    
    // MARK: - Configuration
    func configure(with session: Session) {
        // Set summary or default text
        summaryLabel.text = session.summary ?? "Session \(session.id.prefix(8))..."
        
        // Set message count
        let count = session.messageCount
        messageCountBadge.text = count > 99 ? "99+" : "\(count)"
        
        // Format timestamp
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        timestampLabel.text = formatter.localizedString(for: session.lastActiveAt, relativeTo: Date())
        
        // Set working directory if available
        if let cwd = session.cwd {
            cwdLabel.text = "📁 \(URL(fileURLWithPath: cwd).lastPathComponent)"
        } else {
            cwdLabel.text = ""
        }
        
        // Add glow effect for active sessions
        if session.status == .active {
            containerView.layer.shadowColor = UIColor(red: 0, green: 0.85, blue: 1, alpha: 1.0).cgColor
            containerView.layer.shadowOffset = CGSize(width: 0, height: 0)
            containerView.layer.shadowRadius = 4
            containerView.layer.shadowOpacity = 0.3
        } else {
            containerView.layer.shadowOpacity = 0
        }
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        summaryLabel.text = nil
        messageCountBadge.text = nil
        timestampLabel.text = nil
        cwdLabel.text = nil
        containerView.layer.shadowOpacity = 0
    }
}