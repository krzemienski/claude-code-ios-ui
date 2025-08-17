import UIKit

/// Provides animations for chat messages
final class MessageAnimator {
    
    // MARK: - Send Animations
    
    /// Animate message send action
    static func animateSend(view: UIView) {
        // Scale and fade animation
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [.curveEaseOut]) {
            view.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            view.alpha = 0.9
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                view.transform = .identity
                view.alpha = 1.0
            }
        }
    }
    
    // MARK: - Receive Animations
    
    /// Animate message receive action
    static func animateReceive(view: UIView) {
        // Slide in from bottom with fade
        view.transform = CGAffineTransform(translationX: 0, y: 20)
        view.alpha = 0
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.5, options: [.curveEaseOut]) {
            view.transform = .identity
            view.alpha = 1.0
        }
    }
    
    // MARK: - Glow Effects
    
    /// Add a glow effect to a view
    static func addGlowEffect(to view: UIView, color: UIColor) {
        view.layer.shadowColor = color.cgColor
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0.5
        view.layer.shadowOffset = .zero
        
        // Pulse animation
        let animation = CABasicAnimation(keyPath: "shadowOpacity")
        animation.fromValue = 0.5
        animation.toValue = 0.8
        animation.duration = 0.5
        animation.autoreverses = true
        animation.repeatCount = 2
        view.layer.add(animation, forKey: "glowPulse")
    }
    
    // MARK: - Scroll Animations
    
    /// Smoothly scroll to bottom of table view
    static func scrollToBottom(tableView: UITableView, animated: Bool) {
        guard tableView.numberOfSections > 0 else { return }
        
        let lastSection = tableView.numberOfSections - 1
        let lastRow = tableView.numberOfRows(inSection: lastSection) - 1
        
        guard lastRow >= 0 else { return }
        
        let indexPath = IndexPath(row: lastRow, section: lastSection)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }
    
    // MARK: - Typing Indicator
    
    /// Show typing indicator animation
    static func showTypingIndicator(in view: UIView) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.9)
        container.layer.cornerRadius = 16
        
        // Create three dots
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.distribution = .equalSpacing
        
        for i in 0..<3 {
            let dot = UIView()
            dot.backgroundColor = CyberpunkTheme.primaryCyan
            dot.layer.cornerRadius = 3
            dot.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: 6),
                dot.heightAnchor.constraint(equalToConstant: 6)
            ])
            
            // Animate dots with delay
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 0.3
            animation.toValue = 1.0
            animation.duration = 0.6
            animation.autoreverses = true
            animation.repeatCount = .infinity
            animation.beginTime = CACurrentMediaTime() + Double(i) * 0.2
            dot.layer.add(animation, forKey: "typingDot")
            
            stackView.addArrangedSubview(dot)
        }
        
        container.addSubview(stackView)
        view.addSubview(container)
        
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
            container.heightAnchor.constraint(equalToConstant: 32),
            container.widthAnchor.constraint(equalToConstant: 60),
            
            stackView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        // Fade in animation
        container.alpha = 0
        UIView.animate(withDuration: 0.3) {
            container.alpha = 1.0
        }
        
        return container
    }
    
    /// Hide typing indicator
    static func hideTypingIndicator(_ indicator: UIView) {
        UIView.animate(withDuration: 0.3, animations: {
            indicator.alpha = 0
        }) { _ in
            indicator.removeFromSuperview()
        }
    }
    
    // MARK: - Loading Animations
    
    /// Show skeleton loading animation
    static func showSkeletonLoading(in view: UIView) -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [
            UIColor.systemGray5.cgColor,
            UIColor.systemGray6.cgColor,
            UIColor.systemGray5.cgColor
        ]
        gradient.locations = [0, 0.5, 1]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        
        view.layer.addSublayer(gradient)
        
        // Shimmer animation
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue = [1, 1.5, 2]
        animation.duration = 1.5
        animation.repeatCount = .infinity
        gradient.add(animation, forKey: "shimmer")
        
        return gradient
    }
    
    /// Hide skeleton loading
    static func hideSkeletonLoading(_ layer: CAGradientLayer) {
        layer.removeAllAnimations()
        layer.removeFromSuperlayer()
    }
}