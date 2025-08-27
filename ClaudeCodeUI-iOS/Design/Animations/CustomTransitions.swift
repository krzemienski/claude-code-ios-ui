//
//  CustomTransitions.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/21.
//

import UIKit

// MARK: - Zoom Transition

class ZoomTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    private let duration: TimeInterval = 0.4
    private var presenting = true
    private var originFrame = CGRect.zero
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        guard let toView = transitionContext.view(forKey: .to),
              let fromView = transitionContext.view(forKey: .from) else {
            return
        }
        
        let initialFrame = presenting ? originFrame : toView.frame
        let finalFrame = presenting ? toView.frame : originFrame
        
        let xScaleFactor = presenting ?
            initialFrame.width / finalFrame.width :
            finalFrame.width / initialFrame.width
        
        let yScaleFactor = presenting ?
            initialFrame.height / finalFrame.height :
            finalFrame.height / initialFrame.height
        
        let scaleTransform = CGAffineTransform(scaleX: xScaleFactor, y: yScaleFactor)
        
        if presenting {
            toView.transform = scaleTransform
            toView.center = CGPoint(x: initialFrame.midX, y: initialFrame.midY)
            toView.clipsToBounds = true
        }
        
        containerView.addSubview(toView)
        containerView.bringSubviewToFront(presenting ? toView : fromView)
        
        UIView.animate(withDuration: duration,
                      delay: 0,
                      usingSpringWithDamping: 0.8,
                      initialSpringVelocity: 0,
                      options: [],
                      animations: {
            if self.presenting {
                toView.transform = .identity
                toView.center = CGPoint(x: finalFrame.midX, y: finalFrame.midY)
            } else {
                fromView.transform = scaleTransform
                fromView.center = CGPoint(x: finalFrame.midX, y: finalFrame.midY)
            }
        }) { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

// MARK: - Slide Transition

class SlideTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    enum Direction: Equatable {
        case left, right, up, down
    }
    
    private let duration: TimeInterval = 0.3
    private let direction: Direction
    private let presenting: Bool
    
    init(direction: Direction = .right, presenting: Bool = true) {
        self.direction = direction
        self.presenting = presenting
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to),
              let fromView = fromVC.view,
              let toView = toVC.view else {
            return
        }
        
        containerView.addSubview(toView)
        
        let screenBounds = UIScreen.main.bounds
        let offset = getOffset(for: screenBounds)
        
        if presenting {
            toView.frame = CGRect(origin: offset, size: screenBounds.size)
        }
        
        UIView.animate(withDuration: duration,
                      delay: 0,
                      usingSpringWithDamping: 0.9,
                      initialSpringVelocity: 0.1,
                      options: .curveEaseInOut,
                      animations: {
            if self.presenting {
                toView.frame = screenBounds
                fromView.frame = CGRect(origin: self.getOppositeOffset(for: screenBounds),
                                       size: screenBounds.size)
            } else {
                fromView.frame = CGRect(origin: offset, size: screenBounds.size)
            }
        }) { finished in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    private func getOffset(for bounds: CGRect) -> CGPoint {
        switch direction {
        case .left:
            return CGPoint(x: -bounds.width, y: 0)
        case .right:
            return CGPoint(x: bounds.width, y: 0)
        case .up:
            return CGPoint(x: 0, y: -bounds.height)
        case .down:
            return CGPoint(x: 0, y: bounds.height)
        }
    }
    
    private func getOppositeOffset(for bounds: CGRect) -> CGPoint {
        switch direction {
        case .left:
            return CGPoint(x: bounds.width, y: 0)
        case .right:
            return CGPoint(x: -bounds.width, y: 0)
        case .up:
            return CGPoint(x: 0, y: bounds.height)
        case .down:
            return CGPoint(x: 0, y: -bounds.height)
        }
    }
}

// MARK: - Fade Transition

class FadeTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    private let duration: TimeInterval = 0.25
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toView = transitionContext.view(forKey: .to) else { return }
        
        let containerView = transitionContext.containerView
        toView.alpha = 0.0
        containerView.addSubview(toView)
        
        UIView.animate(withDuration: duration, animations: {
            toView.alpha = 1.0
        }) { finished in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

// MARK: - Flip Transition

class FlipTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    private let duration: TimeInterval = 0.6
    private let presenting: Bool
    
    init(presenting: Bool = true) {
        self.presenting = presenting
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        guard let fromView = transitionContext.view(forKey: .from),
              let toView = transitionContext.view(forKey: .to) else {
            return
        }
        
        containerView.addSubview(toView)
        containerView.sendSubviewToBack(toView)
        
        let direction: UIView.AnimationOptions = presenting ? .transitionFlipFromRight : .transitionFlipFromLeft
        
        UIView.transition(from: fromView,
                         to: toView,
                         duration: duration,
                         options: [direction, .showHideTransitionViews]) { finished in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

// MARK: - Card Presentation Transition

class CardPresentationTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    private let duration: TimeInterval = 0.5
    private let presenting: Bool
    
    init(presenting: Bool) {
        self.presenting = presenting
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to),
              let fromView = fromVC.view,
              let toView = toVC.view else {
            return
        }
        
        if presenting {
            // Configure card appearance
            toView.layer.cornerRadius = 20
            toView.layer.shadowColor = UIColor.black.cgColor
            toView.layer.shadowOpacity = 0.3
            toView.layer.shadowOffset = CGSize(width: 0, height: 10)
            toView.layer.shadowRadius = 20
            
            // Initial position (bottom of screen)
            toView.frame = CGRect(x: 0,
                                 y: containerView.bounds.height,
                                 width: containerView.bounds.width,
                                 height: containerView.bounds.height * 0.9)
            
            containerView.addSubview(toView)
            
            // Add dimming view
            let dimmingView = UIView(frame: containerView.bounds)
            dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            dimmingView.alpha = 0
            dimmingView.tag = 999
            containerView.insertSubview(dimmingView, belowSubview: toView)
            
            UIView.animate(withDuration: duration,
                          delay: 0,
                          usingSpringWithDamping: 0.8,
                          initialSpringVelocity: 0,
                          options: .curveEaseOut,
                          animations: {
                toView.frame = CGRect(x: 0,
                                     y: containerView.bounds.height * 0.1,
                                     width: containerView.bounds.width,
                                     height: containerView.bounds.height * 0.9)
                dimmingView.alpha = 1.0
                
                // Scale down the from view slightly
                fromView.transform = CGAffineTransform(scaleX: 0.93, y: 0.93)
                fromView.layer.cornerRadius = 20
            }) { finished in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
            
        } else {
            // Dismissing
            let dimmingView = containerView.viewWithTag(999)
            
            UIView.animate(withDuration: duration,
                          delay: 0,
                          options: .curveEaseIn,
                          animations: {
                fromView.frame = CGRect(x: 0,
                                       y: containerView.bounds.height,
                                       width: containerView.bounds.width,
                                       height: containerView.bounds.height * 0.9)
                dimmingView?.alpha = 0
                
                // Restore the to view
                toView.transform = .identity
                toView.layer.cornerRadius = 0
            }) { finished in
                dimmingView?.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}

// MARK: - Interactive Transition Controller

class InteractiveTransition: UIPercentDrivenInteractiveTransition {
    
    var hasStarted = false
    var shouldFinish = false
    
    func handlePanGesture(_ gesture: UIPanGestureRecognizer, in viewController: UIViewController) {
        let translation = gesture.translation(in: gesture.view?.superview)
        let verticalMovement = translation.y / viewController.view.bounds.height
        let downwardMovement = fmaxf(Float(verticalMovement), 0.0)
        let progress = fminf(downwardMovement, 1.0)
        
        switch gesture.state {
        case .began:
            hasStarted = true
            viewController.dismiss(animated: true)
            
        case .changed:
            shouldFinish = progress > 0.5
            update(CGFloat(progress))
            
        case .cancelled:
            hasStarted = false
            cancel()
            
        case .ended:
            hasStarted = false
            shouldFinish ? finish() : cancel()
            
        default:
            break
        }
    }
}

// MARK: - Transition Coordinator

class TransitionCoordinator: NSObject {
    
    static let shared = TransitionCoordinator()
    
    private var currentTransition: UIViewControllerAnimatedTransitioning?
    private var interactiveTransition: InteractiveTransition?
    
    func configureTransition(for viewController: UIViewController,
                           type: TransitionType,
                           interactive: Bool = false) {
        viewController.transitioningDelegate = self
        viewController.modalPresentationStyle = type == .card ? .custom : .fullScreen
        
        if interactive {
            interactiveTransition = InteractiveTransition()
            
            let panGesture = UIPanGestureRecognizer(target: self,
                                                   action: #selector(handlePanGesture(_:)))
            viewController.view.addGestureRecognizer(panGesture)
        }
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let viewController = gesture.view?.next as? UIViewController else { return }
        interactiveTransition?.handlePanGesture(gesture, in: viewController)
    }
    
    enum TransitionType: Equatable {
        case zoom(CGRect)
        case slide(SlideTransition.Direction)
        case fade
        case flip
        case card
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension TransitionCoordinator: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController,
                            presenting: UIViewController,
                            source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return CardPresentationTransition(presenting: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return CardPresentationTransition(presenting: false)
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveTransition?.hasStarted == true ? interactiveTransition : nil
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveTransition?.hasStarted == true ? interactiveTransition : nil
    }
}