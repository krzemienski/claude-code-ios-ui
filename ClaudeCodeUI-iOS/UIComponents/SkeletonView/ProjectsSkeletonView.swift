import SwiftUI

/// Skeleton loading view for Projects list with cyberpunk theme
struct ProjectsSkeletonView: View {
    @State private var isAnimating = false
    private let cyanColor = Color(red: 0, green: 217/255, blue: 1)
    private let pinkColor = Color(red: 1, green: 6/255, blue: 110/255)
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<5) { _ in
                ProjectSkeletonRow()
            }
        }
        .padding()
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}

struct ProjectSkeletonRow: View {
    @State private var gradientOffset: CGFloat = -1.0
    private let cyanColor = Color(red: 0, green: 217/255, blue: 1)
    private let pinkColor = Color(red: 1, green: 6/255, blue: 110/255)
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(shimmerOverlay)
            
            VStack(alignment: .leading, spacing: 8) {
                // Project name placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 180, height: 16)
                    .overlay(shimmerOverlay)
                
                // Project path placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 240, height: 12)
                    .overlay(shimmerOverlay)
            }
            
            Spacer()
            
            // Chevron placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.1))
                .frame(width: 20, height: 20)
                .overlay(shimmerOverlay)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [cyanColor.opacity(0.3), pinkColor.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
        )
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                gradientOffset = 2.0
            }
        }
    }
    
    private var shimmerOverlay: some View {
        GeometryReader { geometry in
            LinearGradient(
                colors: [
                    Color.white.opacity(0.0),
                    Color.white.opacity(0.1),
                    cyanColor.opacity(0.2),
                    pinkColor.opacity(0.2),
                    Color.white.opacity(0.1),
                    Color.white.opacity(0.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width * 2)
            .offset(x: geometry.size.width * gradientOffset)
            .mask(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white)
            )
        }
    }
}

// MARK: - Preview
struct ProjectsSkeletonView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Grid background
            GeometryReader { geometry in
                Path { path in
                    let gridSize: CGFloat = 30
                    let rows = Int(geometry.size.height / gridSize)
                    let cols = Int(geometry.size.width / gridSize)
                    
                    for row in 0...rows {
                        path.move(to: CGPoint(x: 0, y: CGFloat(row) * gridSize))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: CGFloat(row) * gridSize))
                    }
                    
                    for col in 0...cols {
                        path.move(to: CGPoint(x: CGFloat(col) * gridSize, y: 0))
                        path.addLine(to: CGPoint(x: CGFloat(col) * gridSize, y: geometry.size.height))
                    }
                }
                .stroke(Color(red: 0, green: 217/255, blue: 1).opacity(0.1), lineWidth: 0.5)
            }
            
            ProjectsSkeletonView()
        }
        .preferredColorScheme(.dark)
        .previewDevice("iPhone 16 Pro Max")
    }
}