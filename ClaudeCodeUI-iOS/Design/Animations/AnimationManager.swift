//
//  AnimationManager.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/21.
//

import UIKit

/// Central manager for app-wide animations and transitions
public class AnimationManager {
    
    // MARK: - Singleton
    
    public static let shared = AnimationManager()
    private init() {}
    
    // MARK: - Animation Constants
    
    struct Duration {
        static let instant: TimeInterval = 0.1
        static let fast: TimeInterval = 0.2
        static let normal: TimeInterval = 0.3
        static let slow: TimeInterval = 0.5
        static let verySlow: TimeInterval = 0.8
    }
    
    struct Spring {
        static let bouncy = (damping: 0.6, velocity: 0.8)
        static let smooth = (damping: 0.8, velocity: 0.5)
        static let stiff = (damping: 0.9, velocity: 0.3)
    }
    
    // MARK: - View Animations
    
    /// Fade in animation
    func fadeIn(_ view: UIView, duration: TimeInterval = Duration.normal, completion: (() -> Void)? = nil) {
        view.alpha = 0
        UIView.animate(withDuration: duration, animations: {
            view.alpha = 1
        }) { _ in
            completion?()
        }
    }
    
    /// Fade out animation
    func fadeOut(_ view: UIView, duration: TimeInterval = Duration.normal, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            view.alpha = 0
        }) { _ in
            completion?()
        }
    }
    
    /// Scale animation with spring effect
    func scaleSpring(_ view: UIView, scale: CGFloat = 1.1, duration: TimeInterval = Duration.normal) {
        UIView.animate(withDuration: duration,
                      delay: 0,
                      usingSpringWithDamping: CGFloat(Spring.bouncy.damping),
                      initialSpringVelocity: CGFloat(Spring.bouncy.velocity),
                      options: .curveEaseInOut,
                      animations: {
            view.transform = CGAffineTransform(scaleX: scale, y: scale)
        }) { _ in
            UIView.animate(withDuration: duration * 0.5) {
                view.transform = .identity
            }
        }
    }
    
    /// Pulse animation
    func pulse(_ view: UIView, scale: CGFloat = 1.05, duration: TimeInterval = Duration.fast) {
        UIView.animate(withDuration: duration,
                      delay: 0,
                      options: [.curveEaseInOut, .autoreverse],
                      animations: {
            view.transform = CGAffineTransform(scaleX: scale, y: scale)
        }) { _ in
            view.transform = .identity
        }
    }
    
    /// Shake animation for errors
    func shake(_ view: UIView, intensity: CGFloat = 20) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.6
        animation.values = [-intensity, intensity, -intensity, intensity, -intensity/2, intensity/2, -intensity/4, intensity/4, 0]
        view.layer.add(animation, forKey: "shake")
        
        // Add haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    /// Bounce animation
    func bounce(_ view: UIView, height: CGFloat = 20) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.duration = 0.6
        animation.values = [0, -height, 0, -height/2, 0, -height/4, 0]
        view.layer.add(animation, forKey: "bounce")
    }
    
    /// Rotate animation
    func rotate(_ view: UIView, angle: CGFloat = .pi * 2, duration: TimeInterval = Duration.normal) {
        UIView.animate(withDuration: duration) {
            view.transform = view.transform.rotated(by: angle)
        }
    }
    
    /// Flip animation
    func flip(_ view: UIView, direction: UIView.AnimationOptions = .transitionFlipFromLeft, duration: TimeInterval = Duration.normal) {
        UIView.transition(with: view,
                         duration: duration,
                         options: [direction, .curveEaseInOut],
                         animations: nil,
                         completion: nil)
    }
    
    // MARK: - Cyberpunk Effects
    
    /// Glitch effect animation
    func glitch(_ view: UIView) {
        let glitchAnimation = CAAnimationGroup()
        glitchAnimation.duration = 0.3
        glitchAnimation.repeatCount = 2
        
        // Position glitch
        let positionAnimation = CAKeyframeAnimation(keyPath: "position")
        positionAnimation.values = [
            NSValue(cgPoint: view.center),
            NSValue(cgPoint: CGPoint(x: view.center.x + 2, y: view.center.y)),
            NSValue(cgPoint: CGPoint(x: view.center.x - 2, y: view.center.y)),
            NSValue(cgPoint: view.center)
        ]
        
        // Opacity glitch
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.values = [1.0, 0.8, 1.0, 0.9, 1.0]
        
        glitchAnimation.animations = [positionAnimation, opacityAnimation]
        view.layer.add(glitchAnimation, forKey: "glitch")
    }
    
    /// Neon glow pulse
    func neonPulse(_ view: UIView, color: UIColor = CyberpunkTheme.primaryCyan) {
        view.layer.shadowColor = color.cgColor
        view.layer.shadowRadius = 10
        view.layer.shadowOpacity = 0.8
        view.layer.shadowOffset = .zero
        
        let animation = CABasicAnimation(keyPath: "shadowOpacity")
        animation.fromValue = 0.8
        animation.toValue = 0.2
        animation.duration = 1.5
        animation.autoreverses = true
        animation.repeatCount = .infinity
        view.layer.add(animation, forKey: "neonPulse")
    }
    
    /// Scanning line effect
    func scanline(_ view: UIView) {
        let scanlineLayer = CAGradientLayer()
        scanlineLayer.frame = view.bounds
        scanlineLayer.colors = [
            UIColor.clear.cgColor,
            CyberpunkTheme.primaryCyan.withAlphaComponent(0.3).cgColor,
            UIColor.clear.cgColor
        ]
        scanlineLayer.locations = [0, 0.5, 1]
        scanlineLayer.startPoint = CGPoint(x: 0, y: 0)
        scanlineLayer.endPoint = CGPoint(x: 0, y: 0.1)
        
        view.layer.addSublayer(scanlineLayer)
        
        let animation = CABasicAnimation(keyPath: "position.y")
        animation.fromValue = -view.bounds.height
        animation.toValue = view.bounds.height * 2
        animation.duration = 3.0
        animation.repeatCount = .infinity
        scanlineLayer.add(animation, forKey: "scanline")
    }
    
    // MARK: - Transition Animations
    
    /// Slide in from direction
    func slideIn(_ view: UIView, from direction: SlideDirection, duration: TimeInterval = Duration.normal) {
        let offset = getOffset(for: direction, view: view)
        view.transform = CGAffineTransform(translationX: offset.x, y: offset.y)
        
        UIView.animate(withDuration: duration,
                      delay: 0,
                      usingSpringWithDamping: CGFloat(Spring.smooth.damping),
                      initialSpringVelocity: CGFloat(Spring.smooth.velocity),
                      options: .curveEaseOut,
                      animations: {
            view.transform = .identity
        })
    }
    
    /// Slide out to direction
    func slideOut(_ view: UIView, to direction: SlideDirection, duration: TimeInterval = Duration.normal, completion: (() -> Void)? = nil) {
        let offset = getOffset(for: direction, view: view)
        
        UIView.animate(withDuration: duration,
                      delay: 0,
                      options: .curveEaseIn,
                      animations: {
            view.transform = CGAffineTransform(translationX: offset.x, y: offset.y)
        }) { _ in
            completion?()
        }
    }
    
    /// Pop in animation
    func popIn(_ view: UIView, duration: TimeInterval = Duration.normal) {
        view.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        view.alpha = 0
        
        UIView.animate(withDuration: duration,
                      delay: 0,
                      usingSpringWithDamping: CGFloat(Spring.bouncy.damping),
                      initialSpringVelocity: CGFloat(Spring.bouncy.velocity),
                      options: .curveEaseOut,
                      animations: {
            view.transform = .identity
            view.alpha = 1
        })
    }
    
    /// Pop out animation
    func popOut(_ view: UIView, duration: TimeInterval = Duration.normal, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration,
                      delay: 0,
                      options: .curveEaseIn,
                      animations: {
            view.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            view.alpha = 0
        }) { _ in
            completion?()
        }
    }
    
    // MARK: - Collection View Animations
    
    /// Animate collection view cells appearing
    func animateCollectionView(_ collectionView: UICollectionView) {
        collectionView.visibleCells.forEach { cell in
            cell.alpha = 0
            cell.transform = CGAffineTransform(translationX: 0, y: 30)
        }
        
        var delay = 0.0
        for cell in collectionView.visibleCells {
            UIView.animate(withDuration: Duration.normal,
                          delay: delay,
                          usingSpringWithDamping: CGFloat(Spring.smooth.damping),
                          initialSpringVelocity: CGFloat(Spring.smooth.velocity),
                          options: .curveEaseOut,
                          animations: {
                cell.alpha = 1
                cell.transform = .identity
            })
            delay += 0.05
        }
    }
    
    /// Animate table view cells appearing
    func animateTableView(_ tableView: UITableView) {
        tableView.visibleCells.forEach { cell in
            cell.alpha = 0
            cell.transform = CGAffineTransform(translationX: -tableView.bounds.width, y: 0)
        }
        
        var delay = 0.0
        for cell in tableView.visibleCells {
            UIView.animate(withDuration: Duration.normal,
                          delay: delay,
                          usingSpringWithDamping: CGFloat(Spring.smooth.damping),
                          initialSpringVelocity: CGFloat(Spring.smooth.velocity),
                          options: .curveEaseOut,
                          animations: {
                cell.alpha = 1
                cell.transform = .identity
            })
            delay += 0.03
        }
    }
    
    // MARK: - Navigation Transitions
    
    /// Custom push transition
    func pushTransition(duration: TimeInterval = Duration.normal) -> CATransition {
        let transition = CATransition()
        transition.duration = duration
        transition.type = .push
        transition.subtype = .fromRight
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        return transition
    }
    
    /// Custom pop transition
    func popTransition(duration: TimeInterval = Duration.normal) -> CATransition {
        let transition = CATransition()
        transition.duration = duration
        transition.type = .push
        transition.subtype = .fromLeft
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        return transition
    }
    
    /// Fade transition
    func fadeTransition(duration: TimeInterval = Duration.normal) -> CATransition {
        let transition = CATransition()
        transition.duration = duration
        transition.type = .fade
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        return transition
    }
    
    // MARK: - Helper Types
    
    enum SlideDirection {
        case left, right, top, bottom
    }
    
    private func getOffset(for direction: SlideDirection, view: UIView) -> CGPoint {
        switch direction {
        case .left:
            return CGPoint(x: -UIScreen.main.bounds.width, y: 0)
        case .right:
            return CGPoint(x: UIScreen.main.bounds.width, y: 0)
        case .top:
            return CGPoint(x: 0, y: -UIScreen.main.bounds.height)
        case .bottom:
            return CGPoint(x: 0, y: UIScreen.main.bounds.height)
        }
    }
    
    // MARK: - Loading Animations
    
    /// Create a loading spinner
    func createLoadingSpinner(color: UIColor = CyberpunkTheme.primaryCyan) -> UIView {
        let spinnerView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        
        let circleLayer = CAShapeLayer()
        let radius: CGFloat = 20
        let path = UIBezierPath(arcCenter: CGPoint(x: 25, y: 25),
                                radius: radius,
                                startAngle: 0,
                                endAngle: .pi * 2,
                                clockwise: true)
        
        circleLayer.path = path.cgPath
        circleLayer.strokeColor = color.cgColor
        circleLayer.lineWidth = 3
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.lineCap = .round
        circleLayer.strokeEnd = 0.8
        
        spinnerView.layer.addSublayer(circleLayer)
        
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = 1
        rotation.isCumulative = true
        rotation.repeatCount = .infinity
        
        spinnerView.layer.add(rotation, forKey: "rotation")
        
        return spinnerView
    }
    
    /// Create typing indicator dots
    func createTypingIndicator() -> UIView {
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 20))
        
        for i in 0..<3 {
            let dot = UIView(frame: CGRect(x: CGFloat(i) * 20 + 5, y: 5, width: 10, height: 10))
            dot.backgroundColor = CyberpunkTheme.primaryCyan
            dot.layer.cornerRadius = 5
            containerView.addSubview(dot)
            
            let animation = CAKeyframeAnimation(keyPath: "opacity")
            animation.values = [0.2, 1.0, 0.2]
            animation.duration = 1.5
            animation.repeatCount = .infinity
            animation.beginTime = CACurrentMediaTime() + Double(i) * 0.2
            dot.layer.add(animation, forKey: "typing")
        }
        
        return containerView
    }
}

// MARK: - UIView Extension

extension UIView {
    /// Convenience method to apply animations
    func animate() -> AnimationManager {
        return AnimationManager.shared
    }
    
    /// Add parallax effect
    func addParallax(intensity: CGFloat = 20) {
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -intensity
        horizontal.maximumRelativeValue = intensity
        
        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -intensity
        vertical.maximumRelativeValue = intensity
        
        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontal, vertical]
        
        addMotionEffect(group)
    }
    
    /// Add gradient animation
    func addGradientAnimation(colors: [UIColor] = [CyberpunkTheme.primaryCyan, CyberpunkTheme.accentPink]) {
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = colors.map { $0.cgColor }
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        
        layer.insertSublayer(gradient, at: 0)
        
        let animation = CABasicAnimation(keyPath: "colors")
        animation.fromValue = colors.map { $0.cgColor }
        animation.toValue = colors.reversed().map { $0.cgColor }
        animation.duration = 3.0
        animation.autoreverses = true
        animation.repeatCount = .infinity
        
        gradient.add(animation, forKey: "gradientAnimation")
    }
}