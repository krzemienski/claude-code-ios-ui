import SwiftUI

// MARK: - Full Screen Loading View (Simple Version)
public struct FullScreenLoadingView: View {
    let message: String?
    @State private var isAnimating = false
    
    public init(message: String? = nil) {
        self.message = message
    }
    
    public var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Loading animation
                ZStack {
                    // Rotating rings
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0/255, green: 217/255, blue: 255/255).opacity(0.3 + Double(index) * 0.2),
                                        Color(red: 255/255, green: 0/255, blue: 110/255).opacity(0.3 + Double(index) * 0.2)
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
                                        Color(red: 0/255, green: 217/255, blue: 255/255).opacity(0.5),
                                        Color(red: 255/255, green: 0/255, blue: 110/255).opacity(0.5)
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

// MARK: - Preview
struct LoadingViews_Previews: PreviewProvider {
    static var previews: some View {
        FullScreenLoadingView(message: "Loading projects...")
            .preferredColorScheme(.dark)
    }
}