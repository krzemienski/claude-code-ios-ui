import SwiftUI
import Combine

// MARK: - Toast Notification
struct ToastView: View {
    let message: String
    let type: ToastType
    let duration: TimeInterval
    @Binding var isShowing: Bool
    
    enum ToastType {
        case success, error, warning, info
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return Color.green
            case .error: return Color(hex: "FF006E")
            case .warning: return Color.orange
            case .info: return Color(hex: "00D9FF")
            }
        }
    }
    
    @State private var workItem: DispatchWorkItem?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 20))
                .foregroundColor(type.color)
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
            
            Spacer()
            
            Button(action: { isShowing = false }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(type.color.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: type.color.opacity(0.3), radius: 8, x: 0, y: 4)
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
        .onAppear {
            scheduleDisappearance()
        }
        .onDisappear {
            workItem?.cancel()
        }
        .onChange(of: isShowing) { newValue in
            if newValue {
                scheduleDisappearance()
            }
        }
    }
    
    private func scheduleDisappearance() {
        workItem?.cancel()
        workItem = DispatchWorkItem {
            withAnimation {
                isShowing = false
            }
        }
        if let workItem = workItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
        }
    }
}

// MARK: - Toast Modifier
struct ToastModifier: ViewModifier {
    @Binding var toast: Toast?
    
    struct Toast: Equatable {
        let message: String
        let type: ToastView.ToastType
        let duration: TimeInterval
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                if let toast = toast {
                    ToastView(
                        message: toast.message,
                        type: toast.type,
                        duration: toast.duration,
                        isShowing: Binding(
                            get: { self.toast != nil },
                            set: { if !$0 { self.toast = nil } }
                        )
                    )
                    .padding(.horizontal)
                    .padding(.top, 50)
                }
                
                Spacer()
            }
            .animation(.spring(), value: toast)
        }
    }
}

// MARK: - Context Menu
struct CyberpunkContextMenu<Content: View>: View {
    let items: [ContextMenuItem]
    @ViewBuilder let content: Content
    @State private var isPresented = false
    @State private var pressLocation: CGPoint = .zero
    
    struct ContextMenuItem {
        let title: String
        let icon: String
        let destructive: Bool
        let action: () -> Void
        
        init(
            title: String,
            icon: String,
            destructive: Bool = false,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.icon = icon
            self.destructive = destructive
            self.action = action
        }
    }
    
    var body: some View {
        content
            .onLongPressGesture { location in
                pressLocation = location
                withAnimation(.spring()) {
                    isPresented = true
                }
                
                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            }
            .overlay(
                Group {
                    if isPresented {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation {
                                    isPresented = false
                                }
                            }
                        
                        ContextMenuView(items: items, isPresented: $isPresented)
                            .position(pressLocation)
                    }
                }
            )
    }
}

struct ContextMenuView: View {
    let items: [CyberpunkContextMenu<EmptyView>.ContextMenuItem]
    @Binding var isPresented: Bool
    @State private var itemScales: [CGFloat] = []
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                    item.action()
                }) {
                    HStack {
                        Image(systemName: item.icon)
                            .font(.system(size: 16))
                            .foregroundColor(
                                item.destructive 
                                    ? Color(hex: "FF006E")
                                    : Color(hex: "00D9FF")
                            )
                            .frame(width: 24)
                        
                        Text(item.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(
                                item.destructive
                                    ? Color(hex: "FF006E")
                                    : .white
                            )
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Color.white.opacity(0.05)
                            .background(.ultraThinMaterial)
                    )
                }
                .scaleEffect(itemScales.indices.contains(index) ? itemScales[index] : 0.8)
                
                if index < items.count - 1 {
                    Divider()
                        .background(Color.white.opacity(0.1))
                }
            }
        }
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
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
        .shadow(color: Color(hex: "00D9FF").opacity(0.3), radius: 12, x: 0, y: 8)
        .onAppear {
            animateItems()
        }
    }
    
    private func animateItems() {
        itemScales = Array(repeating: 0.8, count: items.count)
        
        for index in 0..<items.count {
            withAnimation(
                Animation.spring(response: 0.3, dampingFraction: 0.7)
                    .delay(Double(index) * 0.05)
            ) {
                if index < itemScales.count {
                    itemScales[index] = 1.0
                }
            }
        }
    }
}

// MARK: - Modal Sheet
struct CyberpunkModalSheet<Content: View>: View {
    @Binding var isPresented: Bool
    let title: String
    @ViewBuilder let content: Content
    @State private var dragOffset: CGFloat = 0
    @State private var backgroundOpacity: Double = 0
    
    var body: some View {
        ZStack {
            if isPresented {
                // Background
                Color.black.opacity(backgroundOpacity)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }
                    .transition(.opacity)
                
                // Sheet content
                VStack(spacing: 0) {
                    // Drag indicator
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 40, height: 4)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    
                    // Header
                    HStack {
                        Text(title)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: dismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color.white.opacity(0.3))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    // Content
                    content
                        .padding(.horizontal)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.black.opacity(0.95))
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "00D9FF").opacity(0.3),
                                            Color(hex: "FF006E").opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .offset(y: max(dragOffset, 0))
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.height
                            backgroundOpacity = 0.7 * (1 - dragOffset / UIScreen.main.bounds.height)
                        }
                        .onEnded { value in
                            if value.translation.height > 100 {
                                dismiss()
                            } else {
                                withAnimation(.spring()) {
                                    dragOffset = 0
                                    backgroundOpacity = 0.7
                                }
                            }
                        }
                )
            }
        }
        .onAppear {
            withAnimation(.spring()) {
                backgroundOpacity = 0.7
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.spring()) {
            backgroundOpacity = 0
            isPresented = false
        }
    }
}

// MARK: - Tab Bar with Badges
struct CyberpunkTabBar: View {
    @Binding var selectedTab: Int
    let items: [TabItem]
    
    struct TabItem {
        let title: String
        let icon: String
        let badge: Int?
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                TabBarButton(
                    item: item,
                    isSelected: selectedTab == index,
                    action: {
                        withAnimation(.spring()) {
                            selectedTab = index
                        }
                    }
                )
            }
        }
        .padding(.vertical, 8)
        .background(
            Color.black.opacity(0.9)
                .background(.ultraThinMaterial)
        )
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "00D9FF").opacity(0.3),
                            Color(hex: "FF006E").opacity(0.3)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1),
            alignment: .top
        )
    }
}

struct TabBarButton: View {
    let item: CyberpunkTabBar.TabItem
    let isSelected: Bool
    let action: () -> Void
    @State private var bounceAnimation = false
    
    var body: some View {
        Button(action: {
            action()
            triggerBounce()
        }) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: item.icon)
                        .font(.system(size: 24))
                        .foregroundColor(
                            isSelected 
                                ? Color(hex: "00D9FF")
                                : Color.white.opacity(0.4)
                        )
                        .scaleEffect(bounceAnimation ? 1.2 : 1.0)
                    
                    if let badge = item.badge, badge > 0 {
                        BadgeView(count: badge)
                            .offset(x: 12, y: -8)
                    }
                }
                
                Text(item.title)
                    .font(.caption2)
                    .foregroundColor(
                        isSelected
                            ? Color(hex: "00D9FF")
                            : Color.white.opacity(0.4)
                    )
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private func triggerBounce() {
        bounceAnimation = true
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            bounceAnimation = false
        }
    }
}

struct BadgeView: View {
    let count: Int
    
    var body: some View {
        Text(count > 99 ? "99+" : "\(count)")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color(hex: "FF006E"))
            )
            .scaleEffect(count > 0 ? 1 : 0)
            .animation(.spring(), value: count)
    }
}

// MARK: - Cyberpunk Text Field Style
struct CyberpunkTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: "00D9FF").opacity(0.5), lineWidth: 1)
            )
            .foregroundColor(.white)
    }
}