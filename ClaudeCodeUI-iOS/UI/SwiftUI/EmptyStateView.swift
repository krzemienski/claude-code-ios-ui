//
//  EmptyStateView.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-14.
//

import SwiftUI

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    @State private var isAnimating = false
    @State private var iconRotation: Double = 0
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Animated Icon
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0, green: 0.85, blue: 1).opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .opacity(isAnimating ? 0.5 : 0.8)
                
                // Icon container
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0, green: 0.85, blue: 1),
                                        Color(red: 1, green: 0, blue: 0.43)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(Color(red: 0, green: 0.85, blue: 1))
                    .rotationEffect(.degrees(iconRotation))
            }
            
            // Text content
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)
            
            // Action button
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: 8) {
                        Text(actionTitle)
                            .font(.system(size: 16, weight: .semibold))
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0, green: 0.85, blue: 1),
                                Color(red: 0, green: 0.7, blue: 0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color(red: 0, green: 0.85, blue: 1).opacity(0.5), radius: 8)
                }
                .scaleEffect(isAnimating ? 1.05 : 1.0)
            }
            
            Spacer()
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
            
            withAnimation(
                .linear(duration: 10)
                .repeatForever(autoreverses: false)
            ) {
                iconRotation = 360
            }
        }
    }
}

// MARK: - Error State View
struct ErrorStateView: View {
    let error: Error
    let retryAction: () -> Void
    
    @State private var showDetails = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Error Icon
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(Color.red.opacity(0.3), lineWidth: 2)
                    )
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
            }
            
            // Error message
            VStack(spacing: 12) {
                Text("Something went wrong")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(error.localizedDescription)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(showDetails ? nil : 2)
                    .padding(.horizontal, 32)
                
                if error.localizedDescription.count > 100 {
                    Button {
                        withAnimation {
                            showDetails.toggle()
                        }
                    } label: {
                        Text(showDetails ? "Show Less" : "Show More")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0, green: 0.85, blue: 1))
                    }
                }
            }
            
            // Retry button
            Button(action: retryAction) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Try Again")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.red.opacity(0.2))
                        .overlay(
                            Capsule()
                                .stroke(Color.red, lineWidth: 2)
                        )
                )
            }
            
            Spacer()
        }
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var rotation: Double = 0
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                isPressed = true
                rotation += 45
            }
            
            action()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3)) {
                    isPressed = false
                }
            }
        }) {
            ZStack {
                // Shadow and glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1, green: 0, blue: 0.43).opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .blur(radius: 10)
                
                // Button background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1, green: 0, blue: 0.43),
                                Color(red: 0.8, green: 0, blue: 0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(rotation))
            }
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .shadow(color: Color(red: 1, green: 0, blue: 0.43).opacity(0.5), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Pull to Refresh View
struct PullToRefreshView: View {
    @Binding var isRefreshing: Bool
    let onRefresh: () async -> Void
    
    @State private var pullProgress: CGFloat = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            if pullProgress > 0 || isRefreshing {
                VStack {
                    ZStack {
                        // Progress indicator
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 3)
                            .frame(width: 30, height: 30)
                        
                        Circle()
                            .trim(from: 0, to: min(pullProgress, 1))
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0, green: 0.85, blue: 1),
                                        Color(red: 1, green: 0, blue: 0.43)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 30, height: 30)
                            .rotationEffect(.degrees(-90))
                            .rotationEffect(.degrees(rotation))
                        
                        // Arrow icon
                        Image(systemName: "arrow.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 0, green: 0.85, blue: 1))
                            .opacity(isRefreshing ? 0 : Double(min(pullProgress, 1)))
                            .scaleEffect(isRefreshing ? 0.5 : 1)
                    }
                    .padding(.top, 20)
                    .opacity(Double(min(max(pullProgress, 0.3), 1)))
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onChange(of: isRefreshing) { refreshing in
            if refreshing {
                withAnimation(
                    .linear(duration: 1)
                    .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
            } else {
                rotation = 0
            }
        }
    }
}

// MARK: - Search Bar View
struct SearchBarView: View {
    @Binding var searchText: String
    var placeholder: String = "Search..."
    var onSearchSubmit: (() -> Void)? = nil
    
    @State private var isEditing = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isEditing ? Color(red: 0, green: 0.85, blue: 1) : .gray)
            
            // Text field
            TextField(placeholder, text: $searchText, onEditingChanged: { editing in
                withAnimation(.spring(response: 0.3)) {
                    isEditing = editing
                }
            })
            .textFieldStyle(PlainTextFieldStyle())
            .foregroundColor(.white)
            .onSubmit {
                onSearchSubmit?()
            }
            
            // Clear button
            if !searchText.isEmpty {
                Button {
                    withAnimation {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }
            
            // Cancel button
            if isEditing {
                Button("Cancel") {
                    withAnimation {
                        searchText = ""
                        isEditing = false
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0, green: 0.85, blue: 1))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(isEditing ? 0.08 : 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isEditing 
                                ? Color(red: 0, green: 0.85, blue: 1)
                                : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: isEditing ? Color(red: 0, green: 0.85, blue: 1).opacity(0.3) : .clear,
            radius: 8
        )
    }
}

// MARK: - Preview
struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                EmptyStateView(
                    icon: "bubble.left.and.bubble.right",
                    title: "No Messages",
                    message: "Start a conversation to see messages here",
                    actionTitle: "Start Chat",
                    action: {}
                )
                
                FloatingActionButton(icon: "plus", action: {})
                
                SearchBarView(searchText: .constant(""))
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}