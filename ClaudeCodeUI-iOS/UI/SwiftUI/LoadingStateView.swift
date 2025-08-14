//
//  LoadingStateView.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-14.
//

import SwiftUI

// MARK: - Loading State View
struct LoadingStateView: View {
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.5
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .blur(radius: 3)
            
            VStack(spacing: 24) {
                // Animated loader
                ZStack {
                    // Outer ring
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
                            lineWidth: 3
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(rotation))
                        .scaleEffect(scale)
                    
                    // Inner ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 1, green: 0, blue: 0.43),
                                    Color(red: 0, green: 0.85, blue: 1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-rotation * 1.5))
                        .scaleEffect(scale * 0.9)
                    
                    // Center dot
                    Circle()
                        .fill(Color(red: 0, green: 0.85, blue: 1))
                        .frame(width: 12, height: 12)
                        .opacity(opacity)
                }
                .shadow(color: Color(red: 0, green: 0.85, blue: 1).opacity(0.5), radius: 20)
                
                // Loading text
                Text("Loading...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .opacity(opacity)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.05, green: 0.05, blue: 0.1).opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0, green: 0.85, blue: 1).opacity(0.3),
                                        Color(red: 1, green: 0, blue: 0.43).opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .onAppear {
            withAnimation(
                .linear(duration: 2)
                .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }
            
            withAnimation(
                .easeInOut(duration: 1)
                .repeatForever(autoreverses: true)
            ) {
                scale = 1.1
                opacity = 1.0
            }
        }
    }
}

// MARK: - Skeleton Loading View
struct SkeletonLoadingView: View {
    @State private var shimmerOffset: CGFloat = -1
    
    let rows: Int
    
    init(rows: Int = 5) {
        self.rows = rows
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<rows, id: \.self) { index in
                skeletonRow(delay: Double(index) * 0.1)
            }
        }
        .padding()
        .onAppear {
            withAnimation(
                .linear(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                shimmerOffset = 2
            }
        }
    }
    
    private func skeletonRow(delay: Double) -> some View {
        HStack(spacing: 12) {
            // Avatar skeleton
            Circle()
                .fill(shimmerGradient)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 8) {
                // Title skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(width: CGFloat.random(in: 120...200), height: 12)
                
                // Subtitle skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(width: CGFloat.random(in: 80...140), height: 10)
                    .opacity(0.7)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        )
        .animation(.easeInOut(duration: 1.5).delay(delay), value: shimmerOffset)
    }
    
    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.05),
                Color.white.opacity(0.1),
                Color.white.opacity(0.05)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Progress Indicator View
struct ProgressIndicatorView: View {
    let progress: Double
    let label: String
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0, green: 0.85, blue: 1),
                                    Color(red: 1, green: 0, blue: 0.43)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * animatedProgress, height: 8)
                        .shadow(color: Color(red: 0, green: 0.85, blue: 1).opacity(0.5), radius: 4)
                }
            }
            .frame(height: 8)
            
            // Label and percentage
            HStack {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text("\(Int(animatedProgress * 100))%")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 0, green: 0.85, blue: 1))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.spring(response: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation(.spring(response: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Pulsing Dot Loader
struct PulsingDotLoader: View {
    @State private var scale: [CGFloat] = [1, 1, 1]
    @State private var opacity: [Double] = [1, 1, 1]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0, green: 0.85, blue: 1),
                                Color(red: 1, green: 0, blue: 0.43)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 12, height: 12)
                    .scaleEffect(scale[index])
                    .opacity(opacity[index])
            }
        }
        .onAppear {
            animateDots()
        }
    }
    
    private func animateDots() {
        for index in 0..<3 {
            withAnimation(
                .easeInOut(duration: 0.6)
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.15)
            ) {
                scale[index] = 1.3
                opacity[index] = 0.6
            }
        }
    }
}

// MARK: - Circular Progress View
struct CircularProgressView: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    
    @State private var animatedProgress: Double = 0
    @State private var rotation: Double = 0
    
    init(progress: Double, size: CGFloat = 100, lineWidth: CGFloat = 8) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0, green: 0.85, blue: 1),
                            Color(red: 1, green: 0, blue: 0.43)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .rotationEffect(.degrees(rotation))
            
            // Percentage text
            Text("\(Int(animatedProgress * 100))%")
                .font(.system(size: size * 0.2, weight: .bold))
                .foregroundColor(.white)
        }
        .shadow(color: Color(red: 0, green: 0.85, blue: 1).opacity(0.3), radius: 10)
        .onAppear {
            withAnimation(.spring(response: 1.0)) {
                animatedProgress = progress
            }
            
            withAnimation(
                .linear(duration: 4)
                .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation(.spring(response: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Preview
struct LoadingStateView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                LoadingStateView()
                
                SkeletonLoadingView(rows: 3)
                
                ProgressIndicatorView(progress: 0.75, label: "Processing")
                
                PulsingDotLoader()
                
                CircularProgressView(progress: 0.65)
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}