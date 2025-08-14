import SwiftUI

// MARK: - Shimmer Skeleton View
struct ShimmerSkeletonView: View {
    @State private var shimmerOffset: CGFloat = -1
    let rows: Int
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<rows, id: \.self) { _ in
                SkeletonRow()
            }
        }
        .padding()
        .modifier(ShimmerModifier(offset: shimmerOffset))
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                shimmerOffset = 2
            }
        }
    }
}

struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: 12) {
            // Avatar skeleton
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 8) {
                // Title skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 180, height: 14)
                
                // Subtitle skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 120, height: 12)
            }
            
            Spacer()
            
            // Timestamp skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.08))
                .frame(width: 40, height: 10)
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}

// MARK: - Shimmer Modifier
struct ShimmerModifier: ViewModifier {
    let offset: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.15),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.3)
                    .offset(x: geometry.size.width * offset)
                    .allowsHitTesting(false)
                }
                .mask(content)
            )
    }
}

// MARK: - Circular Progress View
struct CyberpunkProgressView: View {
    @State private var rotation = 0.0
    @State private var trimEnd = 0.0
    let size: CGFloat
    let lineWidth: CGFloat
    
    init(size: CGFloat = 60, lineWidth: CGFloat = 4) {
        self.size = size
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Animated gradient circle
            Circle()
                .trim(from: 0, to: trimEnd)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(hex: "00D9FF"),
                            Color(hex: "FF006E"),
                            Color(hex: "00D9FF")
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation))
            
            // Glow effect
            Circle()
                .trim(from: 0, to: trimEnd)
                .stroke(
                    Color(hex: "00D9FF"),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .blur(radius: 4)
                .opacity(0.5)
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1)
                    .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }
            
            withAnimation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
            ) {
                trimEnd = 0.8
            }
        }
    }
}

// MARK: - Pulsing Dots Loader
struct PulsingDotsLoader: View {
    @State private var scale: [CGFloat] = [1, 1, 1]
    @State private var opacity: [Double] = [1, 1, 1]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "00D9FF"), Color(hex: "FF006E")],
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
                Animation.easeInOut(duration: 0.6)
                    .repeatForever()
                    .delay(Double(index) * 0.2)
            ) {
                scale[index] = 1.3
                opacity[index] = 0.5
            }
        }
    }
}

// MARK: - Progress Bar with Percentage
struct CyberpunkProgressBar: View {
    let progress: Double
    let showPercentage: Bool
    
    init(progress: Double, showPercentage: Bool = true) {
        self.progress = min(max(progress, 0), 1)
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "00D9FF"), Color(hex: "FF006E")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.spring(), value: progress)
                    
                    // Glow effect
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "00D9FF"))
                        .frame(width: geometry.size.width * progress, height: 8)
                        .blur(radius: 4)
                        .opacity(0.5)
                        .animation(.spring(), value: progress)
                }
            }
            .frame(height: 8)
            
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "00D9FF"))
            }
        }
    }
}

// MARK: - Full Screen Loading Overlay
struct FullScreenLoadingView: View {
    let message: String?
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Blur background
            Color.black.opacity(0.7)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Animated logo or progress
                ZStack {
                    // Rotating rings
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "00D9FF").opacity(0.3 + Double(index) * 0.2),
                                        Color(hex: "FF006E").opacity(0.3 + Double(index) * 0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 60 + CGFloat(index * 20), 
                                   height: 60 + CGFloat(index * 20))
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                            .animation(
                                Animation.linear(duration: 3 + Double(index))
                                    .repeatForever(autoreverses: false),
                                value: isAnimating
                            )
                    }
                    
                    // Center icon
                    Image(systemName: "cpu")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(isAnimating ? 1.1 : 0.9)
                        .animation(
                            Animation.easeInOut(duration: 1)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                
                if let message = message {
                    Text(message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "00D9FF").opacity(0.5),
                                        Color(hex: "FF006E").opacity(0.5)
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
            isAnimating = true
        }
    }
}

// MARK: - Inline Loading Indicator
struct InlineLoadingIndicator: View {
    let text: String
    @State private var dots = ""
    
    var body: some View {
        HStack(spacing: 4) {
            CyberpunkProgressView(size: 16, lineWidth: 2)
            
            Text(text + dots)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .onAppear {
            animateDots()
        }
    }
    
    private func animateDots() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation {
                if dots.count >= 3 {
                    dots = ""
                } else {
                    dots += "."
                }
            }
        }
    }
}