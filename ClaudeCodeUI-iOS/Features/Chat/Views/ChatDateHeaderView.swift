//
//  ChatDateHeaderView.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-30.
//  Date header view for grouping chat messages by date
//

import UIKit

// MARK: - ChatDateHeaderView

/// Header view for displaying date separators in chat with cyberpunk styling
final class ChatDateHeaderView: UITableViewHeaderFooterView {
    
    // MARK: - UI Components
    
    private let dateLabel = UILabel()
    private let leftLineView = UIView()
    private let rightLineView = UIView()
    private let glowView = UIView()
    
    // MARK: - Properties
    
    private var pulseAnimation: CABasicAnimation?
    
    // MARK: - Initialization
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        contentView.backgroundColor = .clear
        
        setupGlowView()
        setupDateLabel()
        setupLineViews()
        setupConstraints()
        
        // Add subtle animation
        addPulseAnimation()
    }
    
    private func setupGlowView() {
        glowView.backgroundColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.1)
        glowView.layer.cornerRadius = 12
        glowView.layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor
        glowView.layer.shadowOffset = CGSize(width: 0, height: 0)
        glowView.layer.shadowOpacity = 0.3
        glowView.layer.shadowRadius = 8
        glowView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(glowView)
    }
    
    private func setupDateLabel() {
        dateLabel.font = .preferredFont(forTextStyle: .caption1)
        dateLabel.textColor = CyberpunkTheme.textSecondary
        dateLabel.textAlignment = .center
        dateLabel.backgroundColor = CyberpunkTheme.background
        dateLabel.layer.cornerRadius = 12
        dateLabel.layer.borderWidth = 1
        dateLabel.layer.borderColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.3).cgColor
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(dateLabel)
    }
    
    private func setupLineViews() {
        [leftLineView, rightLineView].forEach { line in
            line.backgroundColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.2)
            line.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(line)
            
            // Add gradient
            let gradient = CAGradientLayer()
            gradient.colors = [
                UIColor.clear.cgColor,
                CyberpunkTheme.primaryCyan.withAlphaComponent(0.3).cgColor,
                UIColor.clear.cgColor
            ]
            gradient.startPoint = CGPoint(x: 0, y: 0.5)
            gradient.endPoint = CGPoint(x: 1, y: 0.5)
            line.layer.insertSublayer(gradient, at: 0)
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Date label
            dateLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dateLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            dateLabel.heightAnchor.constraint(equalToConstant: 24),
            
            // Glow view (behind label)
            glowView.centerXAnchor.constraint(equalTo: dateLabel.centerXAnchor),
            glowView.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor),
            glowView.widthAnchor.constraint(equalTo: dateLabel.widthAnchor, constant: 20),
            glowView.heightAnchor.constraint(equalTo: dateLabel.heightAnchor, constant: 4),
            
            // Left line
            leftLineView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            leftLineView.trailingAnchor.constraint(equalTo: dateLabel.leadingAnchor, constant: -12),
            leftLineView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            leftLineView.heightAnchor.constraint(equalToConstant: 1),
            
            // Right line
            rightLineView.leadingAnchor.constraint(equalTo: dateLabel.trailingAnchor, constant: 12),
            rightLineView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            rightLineView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rightLineView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with date: Date) {
        dateLabel.text = formatDate(date)
        
        // Update label width constraint
        let text = dateLabel.text ?? ""
        let size = text.size(withAttributes: [.font: dateLabel.font ?? UIFont()])
        dateLabel.widthAnchor.constraint(equalToConstant: size.width + 24).isActive = true
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE" // Day name
            return formatter.string(from: date)
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .month) {
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "MMMM d"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Animation
    
    private func addPulseAnimation() {
        // Subtle pulse on the glow
        let pulseAnimation = CABasicAnimation(keyPath: "opacity")
        pulseAnimation.fromValue = 0.3
        pulseAnimation.toValue = 0.1
        pulseAnimation.duration = 3.0
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        glowView.layer.add(pulseAnimation, forKey: "pulse")
        
        // Subtle line animation
        animateLines()
    }
    
    private func animateLines() {
        [leftLineView, rightLineView].forEach { line in
            // Create shimmer effect
            let shimmerAnimation = CABasicAnimation(keyPath: "opacity")
            shimmerAnimation.fromValue = 0.2
            shimmerAnimation.toValue = 0.4
            shimmerAnimation.duration = 2.0
            shimmerAnimation.autoreverses = true
            shimmerAnimation.repeatCount = .infinity
            shimmerAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            line.layer.add(shimmerAnimation, forKey: "shimmer")
        }
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        dateLabel.text = nil
    }
}

// MARK: - CyberpunkTheme

/// Cyberpunk theme colors and styles
struct CyberpunkTheme {
    static let primaryCyan = UIColor(red: 0, green: 217/255, blue: 255/255, alpha: 1)
    static let accentPink = UIColor(red: 255/255, green: 0, blue: 110/255, alpha: 1)
    static let background = UIColor.systemBackground
    static let surface = UIColor.secondarySystemBackground
    static let textPrimary = UIColor.label
    static let textSecondary = UIColor.secondaryLabel
    static let border = UIColor.separator
    static let error = UIColor.systemRed
    static let warning = UIColor.systemOrange
    static let success = UIColor.systemGreen
    
    static func applyGlowEffect(to view: UIView, color: UIColor, radius: CGFloat = 8) {
        view.layer.shadowColor = color.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.layer.shadowOpacity = 0.3
        view.layer.shadowRadius = radius
    }
    
    static func createNeonBorder(for view: UIView, color: UIColor, width: CGFloat = 1) {
        view.layer.borderColor = color.cgColor
        view.layer.borderWidth = width
        
        // Add glow
        applyGlowEffect(to: view, color: color)
    }
}