import SwiftUI
import Combine

// MARK: - Message Bubble View
struct MessageBubbleView: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    @State private var isExpanded = false
    @State private var showContextMenu = false
    @State private var appearAnimation = false
    @Environment(\.colorScheme) var colorScheme
    
    // Callbacks
    var onRetry: (() -> Void)?
    var onCopy: (() -> Void)?
    var onDelete: (() -> Void)?
    
    private var bubbleGradient: LinearGradient {
        LinearGradient(
            colors: isCurrentUser 
                ? [Color(hex: "00D9FF"), Color(hex: "0099CC")]
                : [Color(hex: "FF006E"), Color(hex: "CC0056")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var glowColor: Color {
        isCurrentUser ? Color(hex: "00D9FF") : Color(hex: "FF006E")
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !isCurrentUser {
                AvatarView(type: .assistant)
                    .frame(width: 32, height: 32)
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                // Message bubble
                VStack(alignment: .leading, spacing: 8) {
                    // Message content
                    if let content = message.content {
                        if message.isCode {
                            CodeBlockView(code: content, language: message.codeLanguage)
                        } else {
                            Text(content)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(.white)
                                .textSelection(.enabled)
                        }
                    }
                    
                    // Tool usage indicator
                    if let toolUse = message.toolUse {
                        ToolUseIndicator(toolUse: toolUse, isExpanded: $isExpanded)
                    }
                    
                    // Typing indicator
                    if message.isTyping {
                        TypingIndicator()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(bubbleGradient)
                .clipShape(MessageBubbleShape(isCurrentUser: isCurrentUser))
                .shadow(color: glowColor.opacity(0.3), radius: 8, x: 0, y: 4)
                .overlay(
                    MessageBubbleShape(isCurrentUser: isCurrentUser)
                        .stroke(glowColor.opacity(0.2), lineWidth: 1)
                )
                .contextMenu {
                    contextMenuItems
                }
                
                // Status and timestamp
                HStack(spacing: 4) {
                    if let timestamp = message.timestamp {
                        Text(timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    MessageStatusIcon(status: message.status)
                }
                .padding(.horizontal, 4)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: isCurrentUser ? .trailing : .leading)
            
            if isCurrentUser {
                AvatarView(type: .user)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 16)
        .scaleEffect(appearAnimation ? 1 : 0.8)
        .opacity(appearAnimation ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                appearAnimation = true
            }
        }
    }
    
    @ViewBuilder
    private var contextMenuItems: some View {
        Button(action: { onCopy?() }) {
            Label("Copy", systemImage: "doc.on.doc")
        }
        
        if message.status == .failed {
            Button(action: { onRetry?() }) {
                Label("Retry", systemImage: "arrow.clockwise")
            }
        }
        
        Divider()
        
        Button(role: .destructive, action: { onDelete?() }) {
            Label("Delete", systemImage: "trash")
        }
    }
}

// MARK: - Message Bubble Shape
struct MessageBubbleShape: Shape {
    let isCurrentUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tailSize: CGFloat = 8
        
        var path = Path()
        
        if isCurrentUser {
            // Right-aligned bubble with tail
            path.move(to: CGPoint(x: radius, y: 0))
            path.addLine(to: CGPoint(x: rect.width - radius - tailSize, y: 0))
            path.addArc(center: CGPoint(x: rect.width - radius - tailSize, y: radius),
                       radius: radius,
                       startAngle: .degrees(-90),
                       endAngle: .degrees(0),
                       clockwise: false)
            
            // Tail
            path.addLine(to: CGPoint(x: rect.width - tailSize, y: rect.height - radius))
            path.addQuadCurve(to: CGPoint(x: rect.width, y: rect.height),
                             control: CGPoint(x: rect.width - tailSize/2, y: rect.height))
            path.addQuadCurve(to: CGPoint(x: rect.width - tailSize, y: rect.height - 4),
                             control: CGPoint(x: rect.width - 2, y: rect.height - 2))
            
            path.addArc(center: CGPoint(x: rect.width - radius - tailSize, y: rect.height - radius),
                       radius: radius,
                       startAngle: .degrees(0),
                       endAngle: .degrees(90),
                       clockwise: false)
            path.addLine(to: CGPoint(x: radius, y: rect.height))
            path.addArc(center: CGPoint(x: radius, y: rect.height - radius),
                       radius: radius,
                       startAngle: .degrees(90),
                       endAngle: .degrees(180),
                       clockwise: false)
            path.addLine(to: CGPoint(x: 0, y: radius))
            path.addArc(center: CGPoint(x: radius, y: radius),
                       radius: radius,
                       startAngle: .degrees(180),
                       endAngle: .degrees(270),
                       clockwise: false)
        } else {
            // Left-aligned bubble with tail
            path.move(to: CGPoint(x: radius + tailSize, y: 0))
            path.addLine(to: CGPoint(x: rect.width - radius, y: 0))
            path.addArc(center: CGPoint(x: rect.width - radius, y: radius),
                       radius: radius,
                       startAngle: .degrees(-90),
                       endAngle: .degrees(0),
                       clockwise: false)
            path.addLine(to: CGPoint(x: rect.width, y: rect.height - radius))
            path.addArc(center: CGPoint(x: rect.width - radius, y: rect.height - radius),
                       radius: radius,
                       startAngle: .degrees(0),
                       endAngle: .degrees(90),
                       clockwise: false)
            path.addLine(to: CGPoint(x: radius + tailSize, y: rect.height))
            
            // Tail
            path.addArc(center: CGPoint(x: radius + tailSize, y: rect.height - radius),
                       radius: radius,
                       startAngle: .degrees(90),
                       endAngle: .degrees(180),
                       clockwise: false)
            path.addQuadCurve(to: CGPoint(x: 0, y: rect.height),
                             control: CGPoint(x: tailSize/2, y: rect.height))
            path.addQuadCurve(to: CGPoint(x: tailSize, y: rect.height - 4),
                             control: CGPoint(x: 2, y: rect.height - 2))
            
            path.addLine(to: CGPoint(x: tailSize, y: radius))
            path.addArc(center: CGPoint(x: radius + tailSize, y: radius),
                       radius: radius,
                       startAngle: .degrees(180),
                       endAngle: .degrees(270),
                       clockwise: false)
        }
        
        return path
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var animationPhase = 0.0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationPhase == Double(index) ? 1.3 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animationPhase
                    )
            }
        }
        .onAppear {
            animationPhase = 2.0
        }
    }
}

// MARK: - Tool Use Indicator
struct ToolUseIndicator: View {
    let toolUse: ToolUse
    @Binding var isExpanded: Bool
    @State private var rotationAngle = 0.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                    rotationAngle += 180
                }
            }) {
                HStack {
                    Image(systemName: toolIcon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text(toolUse.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    if let input = toolUse.input {
                        Text("Input:")
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.7))
                        Text(input)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(8)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(6)
                    }
                    
                    if let output = toolUse.output {
                        Text("Output:")
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.7))
                        Text(output)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(8)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(6)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var toolIcon: String {
        switch toolUse.type {
        case "search":
            return "magnifyingglass"
        case "code":
            return "chevron.left.forwardslash.chevron.right"
        case "file":
            return "doc.text"
        case "terminal":
            return "terminal"
        default:
            return "wrench.and.screwdriver"
        }
    }
}

// MARK: - Message Status Icon
struct MessageStatusIcon: View {
    let status: MessageStatus
    
    var body: some View {
        Group {
            switch status {
            case .sending:
                Image(systemName: "clock")
                    .foregroundColor(.gray)
            case .sent:
                Image(systemName: "checkmark")
                    .foregroundColor(.gray)
            case .delivered:
                Image(systemName: "checkmark.circle")
                    .foregroundColor(Color(hex: "00D9FF"))
            case .failed:
                Image(systemName: "exclamationmark.circle")
                    .foregroundColor(Color(hex: "FF006E"))
            case .read:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(hex: "00D9FF"))
            }
        }
        .font(.system(size: 10))
    }
}

// MARK: - Avatar View
struct AvatarView: View {
    enum AvatarType {
        case user, assistant
    }
    
    let type: AvatarType
    
    var body: some View {
        ZStack {
            Circle()
                .fill(gradientBackground)
                .overlay(
                    Circle()
                        .stroke(glowColor.opacity(0.5), lineWidth: 1)
                )
            
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .shadow(color: glowColor.opacity(0.3), radius: 4)
    }
    
    private var gradientBackground: LinearGradient {
        LinearGradient(
            colors: type == .user 
                ? [Color(hex: "00D9FF"), Color(hex: "0099CC")]
                : [Color(hex: "FF006E"), Color(hex: "CC0056")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var glowColor: Color {
        type == .user ? Color(hex: "00D9FF") : Color(hex: "FF006E")
    }
    
    private var iconName: String {
        type == .user ? "person.fill" : "cpu"
    }
}

// MARK: - Code Block View
struct CodeBlockView: View {
    let code: String
    let language: String?
    @State private var isCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                if let lang = language {
                    Text(lang.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Button(action: copyCode) {
                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.4))
            
            // Code content
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white.opacity(0.95))
                    .padding(12)
            }
            .background(Color.black.opacity(0.2))
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func copyCode() {
        UIPasteboard.general.string = code
        withAnimation {
            isCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isCopied = false
            }
        }
    }
}

// MARK: - Supporting Models
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String?
    let isCurrentUser: Bool
    let timestamp: Date?
    let status: MessageStatus
    let isTyping: Bool
    let isCode: Bool
    let codeLanguage: String?
    let toolUse: ToolUse?
}

enum MessageStatus {
    case sending, sent, delivered, read, failed
}

struct ToolUse {
    let name: String
    let type: String
    let input: String?
    let output: String?
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}