//
//  MessageBubbleView.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-14.
//

import SwiftUI

// MARK: - Message Bubble View
struct MessageBubbleView: View {
    let message: Message
    let isCurrentUser: Bool
    @State private var isAnimating = false
    @State private var showActions = false
    @State private var isCopied = false
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer(minLength: 60) }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                // Message Content
                messageBubble
                
                // Timestamp and Status
                HStack(spacing: 4) {
                    if isCurrentUser {
                        statusIcon
                    }
                    
                    Text(timeString(from: message.timestamp))
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
            
            if !isCurrentUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .scaleEffect(isAnimating ? 1 : 0.95)
        .opacity(isAnimating ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }
    
    private var messageBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Role indicator for non-user messages
            if !isCurrentUser {
                HStack(spacing: 6) {
                    Image(systemName: roleIcon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(roleColor)
                    
                    Text(message.role.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(roleColor)
                }
                .padding(.bottom, 4)
            }
            
            // Message content with syntax highlighting if needed
            messageContentView
            
            // Tool use indicator if applicable
            if let metadata = message.metadata,
               let toolUse = metadata["tool_use"] as? [String: Any] {
                ToolUseIndicator(toolUse: toolUse)
            }
        }
        .padding(12)
        .background(bubbleBackground)
        .contextMenu {
            messageContextMenu
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                showActions.toggle()
            }
        }
    }
    
    @ViewBuilder
    private var messageContentView: some View {
        if isCodeMessage {
            CodeBlockView(content: message.content, language: detectLanguage(message.content))
        } else {
            Text(message.content)
                .font(.system(size: 15))
                .foregroundColor(isCurrentUser ? .black : .white)
                .textSelection(.enabled)
        }
    }
    
    private var bubbleBackground: some View {
        Group {
            if isCurrentUser {
                // User message gradient
                LinearGradient(
                    colors: [
                        Color(red: 0, green: 0.85, blue: 1),
                        Color(red: 0, green: 0.7, blue: 0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(BubbleShape(isCurrentUser: true))
                .overlay(
                    BubbleShape(isCurrentUser: true)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            } else {
                // Assistant/System message background
                BubbleShape(isCurrentUser: false)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        BubbleShape(isCurrentUser: false)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1, green: 0, blue: 0.43).opacity(0.5),
                                        Color(red: 0, green: 0.85, blue: 1).opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            }
        }
        .shadow(color: glowColor.opacity(0.3), radius: 8)
    }
    
    private var messageContextMenu: some View {
        Group {
            Button {
                copyMessage()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            
            Button {
                // Retry action
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
            }
            
            if !isCurrentUser {
                Button {
                    // Edit response
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            
            Divider()
            
            Button(role: .destructive) {
                // Delete message
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var roleIcon: String {
        switch message.role {
        case .assistant:
            return "cpu"
        case .system:
            return "gear"
        case .user:
            return "person.fill"
        case .tool:
            return "wrench.and.screwdriver"
        }
    }
    
    private var roleColor: Color {
        switch message.role {
        case .assistant:
            return Color(red: 1, green: 0, blue: 0.43) // Pink
        case .system:
            return .orange
        case .user:
            return Color(red: 0, green: 0.85, blue: 1) // Cyan
        case .tool:
            return .green
        }
    }
    
    private var glowColor: Color {
        isCurrentUser ? Color(red: 0, green: 0.85, blue: 1) : Color(red: 1, green: 0, blue: 0.43)
    }
    
    private var statusIcon: some View {
        Group {
            switch message.status {
            case .sending:
                ProgressView()
                    .scaleEffect(0.5)
            case .sent:
                Image(systemName: "checkmark")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            case .delivered:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color(red: 0, green: 0.85, blue: 1))
            case .failed:
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.red)
            default:
                EmptyView()
            }
        }
    }
    
    private var isCodeMessage: Bool {
        message.content.contains("```") || 
        (message.metadata?["type"] as? String) == "code"
    }
    
    // MARK: - Helper Methods
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func detectLanguage(_ content: String) -> String {
        if content.contains("```swift") { return "swift" }
        if content.contains("```javascript") || content.contains("```js") { return "javascript" }
        if content.contains("```python") { return "python" }
        if content.contains("```json") { return "json" }
        return "plaintext"
    }
    
    private func copyMessage() {
        UIPasteboard.general.string = message.content
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

// MARK: - Bubble Shape
struct BubbleShape: Shape {
    let isCurrentUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: isCurrentUser 
                ? [.topLeft, .topRight, .bottomLeft]
                : [.topLeft, .topRight, .bottomRight],
            cornerRadii: CGSize(width: 16, height: 16)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Code Block View
struct CodeBlockView: View {
    let content: String
    let language: String
    @State private var isCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Label(language, systemImage: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(red: 0, green: 0.85, blue: 1))
                
                Spacer()
                
                Button {
                    copyCode()
                } label: {
                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(isCopied ? .green : .gray)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.3))
            
            // Code content
            ScrollView(.horizontal, showsIndicators: false) {
                Text(cleanCode)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 0, green: 0.85, blue: 1).opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var cleanCode: String {
        content
            .replacingOccurrences(of: "```\(language)", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func copyCode() {
        UIPasteboard.general.string = cleanCode
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

// MARK: - Tool Use Indicator
struct ToolUseIndicator: View {
    let toolUse: [String: Any]
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                    
                    Text(toolName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    if let input = toolUse["input"] as? [String: Any] {
                        ForEach(Array(input.keys), id: \.self) { key in
                            HStack {
                                Text(key)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                Text(String(describing: input[key] ?? ""))
                                    .font(.system(size: 11))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding(8)
                .background(Color.black.opacity(0.3))
                .cornerRadius(6)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var toolName: String {
        (toolUse["name"] as? String) ?? "Tool"
    }
}

// MARK: - Typing Indicator View
struct TypingIndicatorView: View {
    @State private var animationAmount: Double = 1
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color(red: 1, green: 0, blue: 0.43))
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationAmount)
                        .opacity(2 - animationAmount)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animationAmount
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        Capsule()
                            .stroke(Color(red: 1, green: 0, blue: 0.43).opacity(0.3), lineWidth: 1)
                    )
            )
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .onAppear {
            animationAmount = 2
        }
    }
}

// MARK: - Preview
struct MessageBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            MessageBubbleView(
                message: Message(
                    id: "1",
                    content: "Hello! How can I help you today?",
                    role: .assistant,
                    timestamp: Date(),
                    status: .delivered
                ),
                isCurrentUser: false
            )
            
            MessageBubbleView(
                message: Message(
                    id: "2",
                    content: "Can you help me fix a bug in my SwiftUI code?",
                    role: .user,
                    timestamp: Date(),
                    status: .delivered
                ),
                isCurrentUser: true
            )
            
            TypingIndicatorView()
        }
        .padding()
        .background(Color(red: 0.05, green: 0.05, blue: 0.1))
        .preferredColorScheme(.dark)
    }
}