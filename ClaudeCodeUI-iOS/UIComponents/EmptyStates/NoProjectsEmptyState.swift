import SwiftUI

/// Empty state view for when no projects are available
struct NoProjectsEmptyState: View {
    @State private var glitchOffset: CGFloat = 0
    @State private var textOpacity: Double = 1.0
    @State private var scanlineOffset: CGFloat = -100
    private let cyanColor = Color(red: 0, green: 217/255, blue: 1)
    private let pinkColor = Color(red: 1, green: 6/255, blue: 110/255)
    
    let onCreateProject: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            // ASCII Art Terminal
            ZStack {
                asciiArt
                    .offset(x: glitchOffset)
                    .onAppear {
                        startGlitchAnimation()
                    }
                
                // Scanline effect
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                cyanColor.opacity(0),
                                cyanColor.opacity(0.3),
                                cyanColor.opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 4)
                    .offset(y: scanlineOffset)
                    .onAppear {
                        withAnimation(
                            Animation.linear(duration: 3)
                                .repeatForever(autoreverses: false)
                        ) {
                            scanlineOffset = 200
                        }
                    }
            }
            .frame(height: 150)
            
            // Title
            Text("NO PROJECTS DETECTED")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(cyanColor)
                .opacity(textOpacity)
                .shadow(color: cyanColor, radius: 8)
                .onAppear {
                    withAnimation(
                        Animation.easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true)
                    ) {
                        textOpacity = 0.7
                    }
                }
            
            // Description
            Text("Initialize a new project or import existing codebase")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(Color.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Action Buttons
            VStack(spacing: 16) {
                Button(action: onCreateProject) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("CREATE NEW PROJECT")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(cyanColor)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [cyanColor, pinkColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .opacity(0.8)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: cyanColor, radius: 12)
                }
                
                Button(action: {}) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 18))
                        Text("IMPORT PROJECT")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(cyanColor)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(cyanColor, lineWidth: 1)
                    )
                }
            }
        }
        .padding()
    }
    
    private var asciiArt: some View {
        Text("""
        ╔══════════════════════════════╗
        ║  ▓▓▓▓  SYSTEM READY  ▓▓▓▓   ║
        ╠══════════════════════════════╣
        ║ > Scanning directories...    ║
        ║ > No projects found          ║
        ║ > Awaiting initialization    ║
        ║ > _                          ║
        ╚══════════════════════════════╝
        """)
        .font(.system(size: 12, weight: .medium, design: .monospaced))
        .foregroundColor(cyanColor)
        .blur(radius: 0.3)
    }
    
    private func startGlitchAnimation() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                glitchOffset = CGFloat.random(in: -2...2)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    glitchOffset = 0
                }
            }
        }
    }
}

// MARK: - Preview
struct NoProjectsEmptyState_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            NoProjectsEmptyState {
                print("Create project tapped")
            }
        }
        .preferredColorScheme(.dark)
        .previewDevice("iPhone 16 Pro Max")
    }
}