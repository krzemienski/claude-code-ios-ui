# 📱 iOS Claude Code UI - SwiftUI Implementation Plan

## 🎯 Implementation Roadmap for 75 Priority 1 UI/UX Tasks

### Week 1: Foundation & Infrastructure (Days 1-3)

#### Day 1: Tuist Setup & Module Architecture
```bash
# Initialize Tuist in project
cd /Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS
tuist init
tuist fetch
tuist generate

# Expected modules after generation:
# - ClaudeCodeUI (Main App)
# - ClaudeCodeUIKit (UIKit components)
# - ClaudeCodeSwiftUI (SwiftUI components)
# - ClaudeCodeCore (Business logic)
# - ClaudeCodeUIComponents (New UI components)
# - ClaudeCodeDesignSystem (Theme & styles)
```

#### Day 2-3: Loading States & Skeletons (15 components)
```swift
// File: UIComponents/LoadingStates/SkeletonModifier.swift
import SwiftUI

struct SkeletonModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    let gradient = LinearGradient(
        colors: [
            Color(hex: "00D9FF").opacity(0.3),
            Color(hex: "FF006E").opacity(0.5),
            Color(hex: "00D9FF").opacity(0.3)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    func body(content: Content) -> some View {
        content
            .redacted(reason: .placeholder)
            .overlay(
                gradient
                    .mask(content)
                    .offset(x: phase * 400 - 200)
            )
            .animation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false),
                value: phase
            )
            .onAppear { phase = 1 }
    }
}

// Usage in each view controller:
// 1. ProjectsViewController skeleton
// 2. SessionListViewController skeleton  
// 3. ChatViewController skeleton
// 4. FileExplorerViewController skeleton
// 5. Search results skeleton
// 6. Git commit list skeleton
// 7. MCP server list skeleton
// 8. User avatar skeleton
// 9. Code preview skeleton
// 10. Custom gradient animations
```

### Week 1: Core Interactions (Days 4-5)

#### Day 4: Pull-to-Refresh Implementation (10 components)
```swift
// File: UIComponents/RefreshControl/CyberpunkRefreshView.swift
struct CyberpunkRefreshView: View {
    @Binding var isRefreshing: Bool
    let onRefresh: () async -> Void
    
    var body: some View {
        GeometryReader { geometry in
            if isRefreshing {
                VStack {
                    ProgressView()
                        .progressViewStyle(CyberpunkProgressStyle())
                        .scaleEffect(1.5)
                    
                    Text("SYNCING...")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "00D9FF"))
                        .glowEffect(color: .cyan, radius: 4)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "FF006E"), lineWidth: 1)
                        )
                )
            }
        }
        .task {
            if isRefreshing {
                await onRefresh()
                withAnimation { isRefreshing = false }
            }
        }
    }
}

// Apply to:
// 1. SessionListViewController
// 2. ProjectsViewController
// 3. FileExplorerViewController
// 4. Git commit list
// 5. MCP server list
// 6. Search results
// 7. Terminal output
// 8. Chat messages
// 9. Settings sync
// 10. Custom themed control
```

#### Day 5: Empty States Design (15 variants)
```swift
// File: UIComponents/EmptyStates/EmptyStateFactory.swift
enum EmptyStateType {
    case noProjects
    case noSessions
    case noMessages
    case noSearchResults
    case noFiles
    case noGitCommits
    case noMCPServers
    case error(Error)
    case offline
    case loadingFailed
    case permissionDenied
    case timeout
    case rateLimited
    case maintenance
}

struct EmptyStateView: View {
    let type: EmptyStateType
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 24) {
            // ASCII Art Animation
            ASCIIArtView(type: type)
                .frame(height: 120)
            
            // Title
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "00D9FF"))
            
            // Description
            Text(description)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            // Action Button
            if let action = action {
                Button(action: action) {
                    Text(buttonTitle)
                        .cyberpunkButtonStyle()
                }
            }
        }
        .padding()
        .glitchEffect(isActive: type.isError)
    }
}
```

### Week 2: Advanced Interactions (Days 6-8)

#### Day 6: Swipe Actions (10 gesture types)
```swift
// File: UIComponents/SwipeActions/SwipeActionModifier.swift
struct SwipeAction {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
}

struct SwipeActionsModifier: ViewModifier {
    let leadingActions: [SwipeAction]
    let trailingActions: [SwipeAction]
    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    
    func body(content: Content) -> some View {
        ZStack {
            // Background actions
            HStack {
                if offset > 0 {
                    leadingActionsView
                }
                Spacer()
                if offset < 0 {
                    trailingActionsView
                }
            }
            
            // Main content
            content
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            offset = value.translation.width
                            hapticFeedback()
                        }
                        .onEnded { value in
                            withAnimation(.spring()) {
                                processSwipe(value)
                            }
                        }
                )
        }
    }
}

// Implement for:
// 1. Delete sessions (red, trash icon)
// 2. Archive sessions (yellow, archive icon)
// 3. Duplicate projects (cyan, copy icon)
// 4. Rename files (blue, edit icon)
// 5. Share messages (green, share icon)
// 6. Pin/Unpin projects (purple, pin icon)
// 7. Mark as read (gray, check icon)
// 8. Flag sessions (orange, flag icon)
// 9. Move files (indigo, folder icon)
// 10. Confirmation haptics
```

#### Day 7: Navigation Transitions (10 custom animations)
```swift
// File: UIComponents/Transitions/NavigationTransitions.swift
struct CyberpunkTransition: ViewModifier {
    let isPresented: Bool
    let type: TransitionType
    
    enum TransitionType {
        case push, pop, modal, tabSwitch, drawer
        case parallax, hero, fade, spring, gestureDriver
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scaleValue)
            .opacity(opacityValue)
            .offset(offsetValue)
            .rotation3DEffect(
                .degrees(rotationValue),
                axis: (x: 0, y: 1, z: 0),
                perspective: 1
            )
            .animation(animationType, value: isPresented)
    }
    
    private var animationType: Animation {
        switch type {
        case .push: return .spring(response: 0.4, dampingFraction: 0.8)
        case .pop: return .spring(response: 0.3, dampingFraction: 0.9)
        case .modal: return .easeOut(duration: 0.3)
        case .hero: return .interpolatingSpring(stiffness: 200, damping: 25)
        default: return .default
        }
    }
}
```

#### Day 8: Button & Interaction Animations (15 types)
```swift
// File: UIComponents/Animations/InteractionAnimations.swift
struct CyberpunkButtonStyle: ButtonStyle {
    @State private var isPressed = false
    @State private var glowIntensity: Double = 0.5
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "00D9FF"), Color(hex: "FF006E")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
                    .blur(radius: configuration.isPressed ? 8 : 4)
                    .opacity(glowIntensity)
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.6))
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowIntensity = 1.0
                }
            }
            .onChange(of: configuration.isPressed) { pressed in
                if pressed {
                    hapticImpact(.medium)
                }
            }
    }
}

// Implement animations for:
// 1. Button press (scale + haptic)
// 2. Glow effect (neon pulse)
// 3. Ripple effect (touch points)
// 4. Toggle animation (smooth slide)
// 5. Checkbox animation (spring pop)
// 6. Radio button (fade transition)
// 7. FAB animation (rotate + menu)
// 8. Menu reveal (morph)
// 9. Dropdown (accordion)
// 10. Tooltip (fade + position)
// 11. Progress button (loading)
// 12. Success animation (checkmark)
// 13. Error animation (shake)
// 14. Pulse notifications
// 15. Morph animations
```

### Week 2: Testing & Optimization (Days 9-10)

#### Day 9: SwiftUI Preview Configuration
```swift
// File: UIComponents/Previews/PreviewProvider+Extensions.swift
struct PreviewDevice {
    static let iPhone16ProMax = PreviewDevice(
        rawValue: "iPhone 16 Pro Max",
        simulatorID: "A707456B-44DB-472F-9722-C88153CDFFA1"
    )
}

extension PreviewProvider {
    static var cyberpunkPreview: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GridBackgroundView()
                .opacity(0.3)
        }
    }
    
    static var mockWebSocket: WebSocketManager {
        let manager = WebSocketManager()
        manager.connect(to: "ws://192.168.0.43:3004/ws")
        return manager
    }
}

// Create preview for each component:
struct SkeletonView_Previews: PreviewProvider {
    static var previews: some View {
        cyberpunkPreview
            .overlay(
                VStack {
                    ProjectsSkeletonView()
                    SessionsSkeletonView()
                    ChatSkeletonView()
                }
            )
            .previewDevice(PreviewDevice.iPhone16ProMax)
            .preferredColorScheme(.dark)
    }
}
```

#### Day 10: Performance & Accessibility
```swift
// File: UIComponents/Accessibility/AccessibilityManager.swift
struct AccessibilityConfig {
    static func configure(for view: any View) -> some View {
        view
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(localizedLabel)
            .accessibilityHint(localizedHint)
            .accessibilityValue(currentValue)
            .dynamicTypeSize(...DynamicTypeSize.accessibility5)
    }
}

// Performance monitoring
class PerformanceMonitor: ObservableObject {
    @Published var fps: Double = 60
    @Published var memoryUsage: Double = 0
    @Published var cpuUsage: Double = 0
    
    func startMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.updateMetrics()
        }
    }
    
    private func updateMetrics() {
        // Monitor frame rate
        CADisplayLink.fps { fps in
            self.fps = fps
        }
        
        // Monitor memory
        let memoryInfo = ProcessInfo.processInfo.physicalMemory
        self.memoryUsage = Double(memoryInfo) / 1_000_000 // MB
        
        // Ensure < 150MB target
        if memoryUsage > 150 {
            triggerMemoryWarning()
        }
    }
}
```

## 📊 Success Metrics & Validation

### Completion Checklist
- [ ] All 15 skeleton loading states implemented
- [ ] All 10 pull-to-refresh controls added  
- [ ] All 15 empty states designed
- [ ] All 10 swipe actions functional
- [ ] All 10 navigation transitions smooth
- [ ] All 15 button animations working
- [ ] Tuist modules properly configured
- [ ] SwiftUI previews for all components
- [ ] Accessibility audit passed (100% VoiceOver)
- [ ] Performance targets met (<150MB, 60fps)

### Testing Protocol
```bash
# Run Tuist tests
tuist test

# Generate and test on simulator
tuist generate
xcodebuild test \
  -project ClaudeCodeUI.xcodeproj \
  -scheme ClaudeCodeUI-Dev \
  -destination 'id=A707456B-44DB-472F-9722-C88153CDFFA1'

# Measure performance
instruments -t "Activity Monitor" -D performance.trace ClaudeCodeUI
```

## 🚀 Deployment Strategy

### Phase 1: Module Integration (Week 1)
1. Generate Tuist project structure
2. Migrate existing SwiftUI components
3. Create new UI component modules
4. Set up preview providers

### Phase 2: Component Implementation (Week 1-2)
1. Implement all skeleton views
2. Add pull-to-refresh to all scrollable views
3. Design and implement empty states
4. Create swipe actions
5. Build navigation transitions
6. Add interaction animations

### Phase 3: Testing & Polish (Week 2)
1. Unit tests for all components
2. UI tests for interactions
3. Performance profiling
4. Accessibility validation
5. Memory optimization

### Phase 4: Production Ready
1. Final performance tuning
2. Crashlytics integration
3. A/B testing setup
4. Feature flags
5. Release preparation

## 🎯 Expected Outcomes

### User Experience Improvements
- **Loading States**: 100% coverage, no blank screens
- **Responsiveness**: All interactions < 100ms
- **Animations**: 60fps smooth animations
- **Accessibility**: 100% VoiceOver compatible
- **Performance**: <150MB baseline, 2s launch time

### Developer Experience
- **Modular Architecture**: Clean separation of concerns
- **SwiftUI Previews**: Instant feedback loop
- **Tuist Integration**: Consistent builds
- **Testing**: 80%+ code coverage
- **Documentation**: Complete component library

---

**Total Implementation Time**: 10 days
**Priority 1 Tasks Completed**: 75/75
**Simulator Target**: A707456B-44DB-472F-9722-C88153CDFFA1
**Theme**: Cyberpunk (Cyan #00D9FF, Pink #FF006E)