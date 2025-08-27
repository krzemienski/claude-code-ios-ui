//
//  LoadingSkeletonView.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-16.
//  Loading skeleton animations for better UX
//

import SwiftUI

// MARK: - Skeleton View

struct SwiftUISkeletonView: View {
    @State private var isAnimating = false
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = 8) {
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(CyberpunkTheme.surface),
                Color(CyberpunkTheme.surface).opacity(0.4),
                Color(CyberpunkTheme.surface)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .cornerRadius(cornerRadius)
        .overlay(
            GeometryReader { geometry in
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color(CyberpunkTheme.primaryCyan).opacity(0.1),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geometry.size.width * 0.3)
                .offset(x: isAnimating ? geometry.size.width : -geometry.size.width * 0.3)
                .animation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
            }
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Project List Skeleton

struct ProjectListSkeleton: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<5, id: \.self) { _ in
                ProjectRowSkeleton()
            }
        }
        .padding()
    }
}

struct ProjectRowSkeleton: View {
    var body: some View {
        HStack(spacing: 16) {
            // Icon placeholder
            SwiftUISkeletonView(cornerRadius: 12)
                .frame(width: 48, height: 48)
            
            VStack(alignment: .leading, spacing: 8) {
                // Title placeholder
                SwiftUISkeletonView(cornerRadius: 4)
                    .frame(width: 180, height: 20)
                
                // Subtitle placeholder
                SwiftUISkeletonView(cornerRadius: 4)
                    .frame(width: 120, height: 16)
            }
            
            Spacer()
            
            // Chevron placeholder
            SwiftUISkeletonView(cornerRadius: 4)
                .frame(width: 20, height: 20)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(CyberpunkTheme.surface))
        )
    }
}

// MARK: - Chat Message Skeleton

struct ChatMessageSkeleton: View {
    let isUser: Bool
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
                // Message content placeholder
                VStack(alignment: .leading, spacing: 6) {
                    SwiftUISkeletonView(cornerRadius: 4)
                        .frame(width: 200, height: 16)
                    SwiftUISkeletonView(cornerRadius: 4)
                        .frame(width: 160, height: 16)
                    SwiftUISkeletonView(cornerRadius: 4)
                        .frame(width: 140, height: 16)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isUser ?
                            Color(CyberpunkTheme.primaryCyan).opacity(0.2) :
                            Color(CyberpunkTheme.surface)
                        )
                )
                
                // Timestamp placeholder
                SwiftUISkeletonView(cornerRadius: 2)
                    .frame(width: 60, height: 12)
            }
            
            if !isUser { Spacer() }
        }
        .padding(.horizontal)
    }
}

// MARK: - File List Skeleton

struct FileListSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(0..<8, id: \.self) { index in
                HStack(spacing: 12) {
                    // Indentation for nested items
                    if index > 2 && index < 6 {
                        Spacer()
                            .frame(width: 20)
                    }
                    
                    // File icon placeholder
                    SwiftUISkeletonView(cornerRadius: 4)
                        .frame(width: 20, height: 20)
                    
                    // File name placeholder
                    SwiftUISkeletonView(cornerRadius: 4)
                        .frame(width: CGFloat.random(in: 80...150), height: 16)
                    
                    Spacer()
                }
            }
        }
        .padding()
    }
}

// MARK: - Search Result Skeleton

struct SearchResultSkeleton: View {
    var body: some View {
        VStack(spacing: 16) {
            // Search summary skeleton
            HStack {
                SwiftUISkeletonView(cornerRadius: 4)
                    .frame(width: 120, height: 16)
                Spacer()
                SwiftUISkeletonView(cornerRadius: 4)
                    .frame(width: 60, height: 16)
            }
            .padding(.horizontal)
            
            // Result items
            ForEach(0..<4, id: \.self) { _ in
                SearchResultRowSkeleton()
            }
        }
    }
}

struct SearchResultRowSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // File icon
                SwiftUISkeletonView(cornerRadius: 4)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 6) {
                    // File name
                    SwiftUISkeletonView(cornerRadius: 4)
                        .frame(width: 150, height: 16)
                    
                    // File path
                    SwiftUISkeletonView(cornerRadius: 4)
                        .frame(width: 200, height: 12)
                }
                
                Spacer()
                
                // Match count
                SwiftUISkeletonView(cornerRadius: 8)
                    .frame(width: 30, height: 20)
            }
            
            // Code preview
            VStack(alignment: .leading, spacing: 4) {
                SwiftUISkeletonView(cornerRadius: 2)
                    .frame(width: 280, height: 14)
                SwiftUISkeletonView(cornerRadius: 2)
                    .frame(width: 250, height: 14)
            }
            .padding(.leading, 36)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(CyberpunkTheme.surface))
        )
        .padding(.horizontal)
    }
}

// MARK: - Terminal Output Skeleton

struct TerminalOutputSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<10, id: \.self) { index in
                HStack(spacing: 8) {
                    // Command prompt
                    if index % 3 == 0 {
                        SwiftUISkeletonView(cornerRadius: 2)
                            .frame(width: 40, height: 14)
                    }
                    
                    // Output line
                    SwiftUISkeletonView(cornerRadius: 2)
                        .frame(width: CGFloat.random(in: 100...300), height: 14)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(CyberpunkTheme.background))
    }
}

// MARK: - Settings Section Skeleton

struct SettingsSectionSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                SwiftUISkeletonView(cornerRadius: 4)
                    .frame(width: 24, height: 24)
                SwiftUISkeletonView(cornerRadius: 4)
                    .frame(width: 100, height: 20)
                Spacer()
            }
            
            // Settings items
            ForEach(0..<3, id: \.self) { _ in
                HStack {
                    SwiftUISkeletonView(cornerRadius: 4)
                        .frame(width: 120, height: 16)
                    Spacer()
                    SwiftUISkeletonView(cornerRadius: 8)
                        .frame(width: 50, height: 24)
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(CyberpunkTheme.surface))
        )
    }
}

// MARK: - Generic Content Skeleton

struct ContentSkeleton: View {
    let lineCount: Int
    let lineWidths: [CGFloat]
    
    init(lineCount: Int = 3) {
        self.lineCount = lineCount
        self.lineWidths = (0..<lineCount).map { index in
            // Vary line widths for more natural look
            if index == lineCount - 1 {
                return CGFloat.random(in: 100...180)
            } else {
                return CGFloat.random(in: 200...280)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<lineCount, id: \.self) { index in
                SwiftUISkeletonView(cornerRadius: 4)
                    .frame(width: lineWidths[index], height: 16)
            }
        }
    }
}

// MARK: - Skeleton Modifier

struct SkeletonModifier: ViewModifier {
    let isLoading: Bool
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        if isLoading {
            SwiftUISkeletonView(cornerRadius: cornerRadius)
        } else {
            content
        }
    }
}

extension View {
    func skeleton(isLoading: Bool, cornerRadius: CGFloat = 8) -> some View {
        modifier(SkeletonModifier(isLoading: isLoading, cornerRadius: cornerRadius))
    }
}