//
//  RefreshableScrollView.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-16.
//  Custom pull-to-refresh implementation with cyberpunk styling
//

import SwiftUI
import UIKit

// MARK: - Refreshable ScrollView

struct RefreshableScrollView<Content: View>: View {
    let content: Content
    let onRefresh: () async -> Void
    
    @State private var isRefreshing = false
    @State private var pullProgress: CGFloat = 0
    @State private var contentOffset: CGFloat = 0
    
    private let threshold: CGFloat = 80
    
    init(@ViewBuilder content: () -> Content, onRefresh: @escaping () async -> Void) {
        self.content = content()
        self.onRefresh = onRefresh
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Pull to refresh indicator
                    RefreshIndicator(
                        progress: pullProgress,
                        isRefreshing: isRefreshing
                    )
                    .frame(height: isRefreshing ? 60 : max(0, contentOffset))
                    .animation(.spring(), value: isRefreshing)
                    
                    // Main content
                    content
                        .anchorPreference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: .top
                        ) { geometry[$0].y }
                }
            }
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                handleOffsetChange(offset, geometry: geometry)
            }
        }
    }
    
    private func handleOffsetChange(_ offset: CGFloat, geometry: GeometryProxy) {
        contentOffset = offset - geometry.safeAreaInsets.top
        
        if !isRefreshing {
            pullProgress = min(1, max(0, contentOffset / threshold))
            
            if contentOffset > threshold && !isRefreshing {
                startRefresh()
            }
        }
    }
    
    private func startRefresh() {
        isRefreshing = true
        pullProgress = 1
        
        // Haptic feedback
        HapticFeedback.shared.refreshPull()
        
        Task {
            await onRefresh()
            await MainActor.run {
                withAnimation {
                    isRefreshing = false
                    pullProgress = 0
                }
                HapticFeedback.shared.success()
            }
        }
    }
}

// MARK: - Refresh Indicator

struct RefreshIndicator: View {
    let progress: CGFloat
    let isRefreshing: Bool
    
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Background glow
            if progress > 0 {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(UIColor.CyberpunkTheme.primaryCyan).opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(progress)
            }
            
            // Loading indicator
            if isRefreshing {
                CyberpunkLoadingIndicator()
            } else {
                // Pull indicator
                Image(systemName: "arrow.down")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(UIColor.CyberpunkTheme.primaryCyan))
                    .rotationEffect(.degrees(progress * 180))
                    .scaleEffect(0.6 + progress * 0.4)
                    .opacity(progress)
            }
        }
        .frame(height: 60)
    }
}

// MARK: - Cyberpunk Loading Indicator

struct CyberpunkLoadingIndicator: View {
    @State private var rotation = 0.0
    @State private var trimEnd = 0.1
    
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(
                    Color(UIColor.CyberpunkTheme.primaryCyan).opacity(0.2),
                    lineWidth: 3
                )
                .frame(width: 40, height: 40)
            
            // Animated arc
            Circle()
                .trim(from: 0, to: trimEnd)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(UIColor.CyberpunkTheme.primaryCyan),
                            Color(UIColor.CyberpunkTheme.accentPink)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(rotation))
                .animation(
                    Animation.linear(duration: 1)
                        .repeatForever(autoreverses: false),
                    value: rotation
                )
                .animation(
                    Animation.easeInOut(duration: 1)
                        .repeatForever(autoreverses: true),
                    value: trimEnd
                )
                .onAppear {
                    rotation = 360
                    trimEnd = 0.8
                }
            
            // Center dot
            Circle()
                .fill(Color(UIColor.CyberpunkTheme.primaryCyan))
                .frame(width: 8, height: 8)
                .opacity(trimEnd)
        }
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    @State private var isAnimating = false
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon with animation
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(UIColor.CyberpunkTheme.primaryCyan).opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .animation(
                        Animation.easeInOut(duration: 2)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 64))
                    .foregroundColor(Color(UIColor.CyberpunkTheme.textTertiary))
                    .scaleEffect(isAnimating ? 1 : 0.95)
                    .animation(
                        Animation.easeInOut(duration: 2)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(UIColor.CyberpunkTheme.textPrimary))
                
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(Color(UIColor.CyberpunkTheme.textSecondary))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if let actionTitle = actionTitle, let action = action {
                GlowButton(title: actionTitle, icon: "plus.circle", action: action)
                    .padding(.top, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Error State View

struct ErrorStateView: View {
    let error: Error
    let retry: () -> Void
    
    @State private var isShaking = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Error icon
            ZStack {
                Circle()
                    .fill(Color(UIColor.CyberpunkTheme.error).opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color(UIColor.CyberpunkTheme.error))
                    .rotationEffect(.degrees(isShaking ? -5 : 5))
                    .animation(
                        Animation.easeInOut(duration: 0.1)
                            .repeatCount(5, autoreverses: true),
                        value: isShaking
                    )
            }
            
            VStack(spacing: 12) {
                Text("Something went wrong")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color(UIColor.CyberpunkTheme.textPrimary))
                
                Text(error.localizedDescription)
                    .font(.system(size: 14))
                    .foregroundColor(Color(UIColor.CyberpunkTheme.textSecondary))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: {
                HapticFeedback.shared.buttonTap()
                retry()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [
                            Color(UIColor.CyberpunkTheme.error),
                            Color(UIColor.CyberpunkTheme.error).opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
            }
            .buttonStyle(HapticButtonStyle(hapticStyle: .medium))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            isShaking = true
            HapticFeedback.shared.error()
        }
    }
}

// MARK: - Loading State View

struct LoadingStateView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 24) {
            CyberpunkLoadingIndicator()
                .scaleEffect(1.5)
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(Color(UIColor.CyberpunkTheme.textSecondary))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - UIKit Integration for Pull to Refresh

class RefreshableTableViewController: UITableViewController {
    var onRefresh: (() async -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup refresh control with cyberpunk styling
        refreshControl = UIRefreshControl()
        refreshControl?.tintColor = UIColor.CyberpunkTheme.primaryCyan
        refreshControl?.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        
        // Add attributed title
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.CyberpunkTheme.textSecondary,
            .font: UIFont.systemFont(ofSize: 14)
        ]
        refreshControl?.attributedTitle = NSAttributedString(
            string: "Pull to refresh",
            attributes: attributes
        )
    }
    
    @objc private func handleRefresh() {
        HapticFeedback.shared.refreshPull()
        
        Task {
            if let onRefresh = onRefresh {
                await onRefresh()
            }
            await MainActor.run {
                self.refreshControl?.endRefreshing()
                HapticFeedback.shared.success()
            }
        }
    }
}