import SwiftUI

// MARK: - Empty State View
struct EmptyStateView: View {
    let title: String
    let message: String
    let iconName: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    @State private var iconScale: CGFloat = 0.8
    @State private var iconRotation: Double = 0
    @State private var particleOffset: CGFloat = 0
    
    init(
        title: String,
        message: String,
        iconName: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.iconName = iconName
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Animated icon with particles
            ZStack {
                // Particle effects
                ForEach(0..<6) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "00D9FF").opacity(0.3),
                                    Color(hex: "FF006E").opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 8, height: 8)
                        .offset(
                            x: cos(Double(index) * .pi / 3) * particleOffset,
                            y: sin(Double(index) * .pi / 3) * particleOffset
                        )
                        .blur(radius: 2)
                }
                
                // Main icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "00D9FF").opacity(0.1),
                                    Color(hex: "FF006E").opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "00D9FF"), Color(hex: "FF006E")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(iconScale)
                        .rotationEffect(.degrees(iconRotation))
                }
            }
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "00D9FF"), Color(hex: "FF006E")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(PressableButtonStyle())
            }
            
            Spacer()
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Icon bounce
        withAnimation(
            Animation.spring(response: 0.6, dampingFraction: 0.5)
                .delay(0.2)
        ) {
            iconScale = 1.0
        }
        
        // Icon rotation
        withAnimation(
            Animation.easeInOut(duration: 4)
                .repeatForever(autoreverses: true)
        ) {
            iconRotation = 5
        }
        
        // Particle animation
        withAnimation(
            Animation.easeInOut(duration: 3)
                .repeatForever(autoreverses: true)
        ) {
            particleOffset = 60
        }
    }
}

// MARK: - Error View
struct ErrorStateView: View {
    let error: ErrorType
    let onRetry: (() -> Void)?
    
    enum ErrorType {
        case network
        case server
        case notFound
        case unauthorized
        case custom(title: String, message: String, icon: String)
        
        var title: String {
            switch self {
            case .network: return "Connection Lost"
            case .server: return "Server Error"
            case .notFound: return "Not Found"
            case .unauthorized: return "Access Denied"
            case .custom(let title, _, _): return title
            }
        }
        
        var message: String {
            switch self {
            case .network: return "Check your internet connection and try again"
            case .server: return "Something went wrong on our end. Please try again"
            case .notFound: return "The requested resource could not be found"
            case .unauthorized: return "You don't have permission to access this"
            case .custom(_, let message, _): return message
            }
        }
        
        var icon: String {
            switch self {
            case .network: return "wifi.slash"
            case .server: return "exclamationmark.triangle"
            case .notFound: return "questionmark.circle"
            case .unauthorized: return "lock.shield"
            case .custom(_, _, let icon): return icon
            }
        }
        
        var color: Color {
            switch self {
            case .network: return Color.orange
            case .server, .unauthorized: return Color(hex: "FF006E")
            case .notFound: return Color(hex: "00D9FF")
            case .custom: return Color(hex: "FF006E")
            }
        }
    }
    
    @State private var isShaking = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Error icon with shake effect
            ZStack {
                Circle()
                    .fill(error.color.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                
                Image(systemName: error.icon)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(error.color)
                    .rotationEffect(.degrees(isShaking ? -5 : 5))
                    .animation(
                        isShaking
                            ? Animation.easeInOut(duration: 0.1)
                                .repeatCount(5, autoreverses: true)
                            : .default,
                        value: isShaking
                    )
            }
            
            VStack(spacing: 8) {
                Text(error.title)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                Text(error.message)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            if let onRetry = onRetry {
                Button(action: {
                    triggerShake()
                    onRetry()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(error.color.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(error.color, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .onAppear {
            triggerShake()
        }
    }
    
    private func triggerShake() {
        isShaking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isShaking = false
        }
    }
}

// MARK: - Network Offline View
struct NetworkOfflineView: View {
    let onRetry: () -> Void
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated wifi icon
            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(Color.orange.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                        .frame(
                            width: 60 + CGFloat(index * 30),
                            height: 60 + CGFloat(index * 30)
                        )
                        .scaleEffect(pulseAnimation ? 1.1 : 0.9)
                        .opacity(pulseAnimation ? 0 : 1)
                        .animation(
                            Animation.easeOut(duration: 2)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.3),
                            value: pulseAnimation
                        )
                }
                
                Image(systemName: "wifi.slash")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 8) {
                Text("You're Offline")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                Text("Connect to the internet to continue")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .font(.headline)
                .foregroundColor(.orange)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .stroke(Color.orange, lineWidth: 1)
                )
            }
            .buttonStyle(PressableButtonStyle())
        }
        .onAppear {
            pulseAnimation = true
        }
    }
}

// MARK: - Pressable Button Style
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
            }
    }
}