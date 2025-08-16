//
//  AnimatedComponents.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-16.
//  Reusable animated UI components with cyberpunk effects
//

import SwiftUI
import UIKit

// MARK: - Pulse Animation View

struct PulseView: View {
    @State private var isAnimating = false
    let color: Color
    let maxScale: CGFloat
    
    init(color: Color = Color(UIColor.CyberpunkTheme.primaryCyan), maxScale: CGFloat = 1.5) {
        self.color = color
        self.maxScale = maxScale
    }
    
    var body: some View {
        Circle()
            .fill(color)
            .scaleEffect(isAnimating ? maxScale : 1.0)
            .opacity(isAnimating ? 0 : 0.5)
            .animation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var animatingDot = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color(UIColor.CyberpunkTheme.primaryCyan))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animatingDot == index ? 1.3 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 0.5),
                        value: animatingDot
                    )
            }
        }
        .onAppear {
            animateDots()
        }
    }
    
    private func animateDots() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            animatingDot = (animatingDot + 1) % 3
        }
    }
}

// MARK: - Glow Button

struct GlowButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    @State private var isPressed = false
    @State private var isGlowing = false
    
    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    // Gradient background
                    LinearGradient(
                        colors: [
                            Color(UIColor.CyberpunkTheme.primaryCyan),
                            Color(UIColor.CyberpunkTheme.gradientBlue)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    
                    // Glow effect
                    if isGlowing {
                        LinearGradient(
                            colors: [
                                Color(UIColor.CyberpunkTheme.primaryCyan).opacity(0.6),
                                Color(UIColor.CyberpunkTheme.gradientBlue).opacity(0.6)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .blur(radius: 10)
                    }
                }
            )
            .cornerRadius(12)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(
                color: isGlowing ? Color(UIColor.CyberpunkTheme.primaryCyan).opacity(0.6) : Color.clear,
                radius: 20
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 2)
                    .repeatForever(autoreverses: true)
            ) {
                isGlowing = true
            }
        }
    }
}

// MARK: - Animated Card

struct AnimatedCard<Content: View>: View {
    let content: Content
    @State private var isVisible = false
    @State private var dragOffset = CGSize.zero
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .offset(dragOffset)
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.8)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isVisible)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: dragOffset)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3)) {
                    isVisible = true
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        withAnimation {
                            // Snap back or dismiss based on drag distance
                            if abs(value.translation.width) > 100 {
                                dragOffset = CGSize(
                                    width: value.translation.width > 0 ? 500 : -500,
                                    height: value.translation.height
                                )
                                isVisible = false
                            } else {
                                dragOffset = .zero
                            }
                        }
                    }
            )
    }
}

// MARK: - Animated Progress Bar

struct AnimatedProgressBar: View {
    let progress: Double
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(UIColor.CyberpunkTheme.surface))
                
                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(UIColor.CyberpunkTheme.primaryCyan),
                                Color(UIColor.CyberpunkTheme.accentPink)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * animatedProgress)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animatedProgress)
                
                // Glow effect
                if animatedProgress > 0 {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(UIColor.CyberpunkTheme.primaryCyan).opacity(0.3),
                                    Color(UIColor.CyberpunkTheme.accentPink).opacity(0.3)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * animatedProgress)
                        .blur(radius: 8)
                }
            }
        }
        .frame(height: 8)
        .onAppear {
            withAnimation {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    @State private var isExpanded = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            action()
        }) {
            ZStack {
                // Shadow circle
                Circle()
                    .fill(Color(UIColor.CyberpunkTheme.primaryCyan).opacity(0.3))
                    .frame(width: 64, height: 64)
                    .blur(radius: 10)
                    .scaleEffect(isExpanded ? 1.2 : 1.0)
                
                // Main button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(UIColor.CyberpunkTheme.primaryCyan),
                                Color(UIColor.CyberpunkTheme.gradientBlue)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isExpanded ? 45 : 0))
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isExpanded)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
            if pressing {
                withAnimation {
                    isExpanded = true
                }
            } else {
                withAnimation {
                    isExpanded = false
                }
            }
        }, perform: {})
    }
}

// MARK: - Animated Tab Indicator

struct AnimatedTabIndicator: View {
    let selectedIndex: Int
    let tabCount: Int
    let tabWidth: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(UIColor.CyberpunkTheme.primaryCyan))
                .frame(width: tabWidth, height: 3)
                .offset(x: CGFloat(selectedIndex) * tabWidth)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedIndex)
                .shadow(
                    color: Color(UIColor.CyberpunkTheme.primaryCyan).opacity(0.6),
                    radius: 4,
                    y: 2
                )
        }
        .frame(height: 3)
    }
}

// MARK: - Success/Error Animation

struct StatusAnimation: View {
    enum Status {
        case success
        case error
        case warning
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return Color(UIColor.CyberpunkTheme.success)
            case .error: return Color(UIColor.CyberpunkTheme.error)
            case .warning: return Color(UIColor.CyberpunkTheme.warning)
            }
        }
    }
    
    let status: Status
    let message: String
    @State private var isVisible = false
    @State private var scale: CGFloat = 0.5
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: status.icon)
                .font(.system(size: 64))
                .foregroundColor(status.color)
                .scaleEffect(scale)
                .shadow(color: status.color.opacity(0.5), radius: 20)
            
            Text(message)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(UIColor.CyberpunkTheme.textPrimary))
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.CyberpunkTheme.surface))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(status.color.opacity(0.3), lineWidth: 2)
                )
        )
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                isVisible = true
                scale = 1.0
            }
            
            // Haptic feedback
            switch status {
            case .success:
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .error:
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            case .warning:
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
            
            // Auto dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isVisible = false
                }
            }
        }
    }
}

// MARK: - Shimmer Effect Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color(UIColor.CyberpunkTheme.primaryCyan).opacity(0.3),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 400 - 200)
                .animation(
                    Animation.linear(duration: duration)
                        .repeatForever(autoreverses: false),
                    value: phase
                )
            )
            .onAppear {
                phase = 1
            }
    }
}

extension View {
    func shimmer(duration: Double = 1.5) -> some View {
        modifier(ShimmerModifier(duration: duration))
    }
}