//
//  ProjectCard.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import UIKit

// MARK: - Project Card Delegate
protocol ProjectCardDelegate: AnyObject {
    func projectCardDidTap(_ card: ProjectCard, project: Project)
    func projectCardDidLongPress(_ card: ProjectCard, project: Project)
}

// MARK: - Project Card
class ProjectCard: UIView {
    
    // MARK: - Properties
    weak var delegate: ProjectCardDelegate?
    private var project: Project?
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = CyberpunkTheme.surfacePrimary
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.3).cgColor
        return view
    }()
    
    private let glowView: UIView = {
        let view = UIView()
        view.backgroundColor = CyberpunkTheme.primaryCyan
        view.layer.cornerRadius = 16
        view.alpha = 0
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = CyberpunkTheme.textPrimary
        label.numberOfLines = 1
        return label
    }()
    
    private let pathLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = CyberpunkTheme.textSecondary
        label.numberOfLines = 1
        return label
    }()
    
    private let sessionsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = CyberpunkTheme.primaryCyan
        return label
    }()
    
    private let lastActiveLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = CyberpunkTheme.textTertiary
        label.textAlignment = .right
        return label
    }()
    
    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = CyberpunkTheme.primaryCyan
        return imageView
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Add glow effect behind container
        addSubview(glowView)
        addSubview(containerView)
        
        // Add content to container
        containerView.addSubview(iconView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(pathLabel)
        containerView.addSubview(sessionsLabel)
        containerView.addSubview(lastActiveLabel)
        
        // Layout
        glowView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        pathLabel.translatesAutoresizingMaskIntoConstraints = false
        sessionsLabel.translatesAutoresizingMaskIntoConstraints = false
        lastActiveLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Glow view (slightly larger than container)
            glowView.topAnchor.constraint(equalTo: topAnchor, constant: -2),
            glowView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -2),
            glowView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 2),
            glowView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 2),
            
            // Container view
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Icon
            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            
            // Name label
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Path label
            pathLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            pathLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            pathLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            // Sessions label
            sessionsLabel.topAnchor.constraint(equalTo: pathLabel.bottomAnchor, constant: 8),
            sessionsLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            sessionsLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            
            // Last active label
            lastActiveLabel.centerYAnchor.constraint(equalTo: sessionsLabel.centerYAnchor),
            lastActiveLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            lastActiveLabel.leadingAnchor.constraint(greaterThanOrEqualTo: sessionsLabel.trailingAnchor, constant: 8)
        ])
        
        // Apply glow blur effect
        glowView.layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor
        glowView.layer.shadowRadius = 20
        glowView.layer.shadowOpacity = 0.8
        glowView.layer.shadowOffset = .zero
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.minimumPressDuration = 0.5
        addGestureRecognizer(longPressGesture)
    }
    
    // MARK: - Configuration
    func configure(with project: Project) {
        self.project = project
        
        nameLabel.text = project.displayName ?? project.name
        pathLabel.text = project.path
        
        let sessionCount = project.sessionCount
        sessionsLabel.text = "\(sessionCount) session\(sessionCount == 1 ? "" : "s")"
        
        if let lastDate = project.lastSessionDate {
            lastActiveLabel.text = formatRelativeDate(lastDate)
        } else if sessionCount > 0 {
            lastActiveLabel.text = "Active"
        } else {
            lastActiveLabel.text = "No sessions"
        }
        
        // Set icon based on project type
        iconView.image = UIImage(systemName: "folder.fill")
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // MARK: - Actions
    @objc private func handleTap() {
        guard let project = project else { return }
        
        // Animate tap
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        }
        
        delegate?.projectCardDidTap(self, project: project)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let project = project else { return }
        
        if gesture.state == .began {
            // Show glow effect
            UIView.animate(withDuration: 0.3) {
                self.glowView.alpha = 0.3
            }
            
            delegate?.projectCardDidLongPress(self, project: project)
        } else if gesture.state == .ended || gesture.state == .cancelled {
            // Hide glow effect
            UIView.animate(withDuration: 0.3) {
                self.glowView.alpha = 0
            }
        }
    }
    
    // MARK: - Highlighting
    func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let alpha: CGFloat = highlighted ? 0.2 : 0
        
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.glowView.alpha = alpha
            }
        } else {
            glowView.alpha = alpha
        }
    }
}