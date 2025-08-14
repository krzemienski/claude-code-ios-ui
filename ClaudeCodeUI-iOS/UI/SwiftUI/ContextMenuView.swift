//
//  ContextMenuView.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-14.
//

import SwiftUI

// MARK: - Context Menu Action
struct ContextMenuAction {
    let title: String
    let icon: String
    let role: ButtonRole?
    let action: () -> Void
    
    init(title: String, icon: String, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.role = role
        self.action = action
    }
}

// MARK: - Advanced Context Menu View
struct AdvancedContextMenu<Content: View>: View {
    let content: Content
    let actions: [ContextMenuAction]
    
    @State private var isShowingMenu = false
    @State private var dragOffset: CGSize = .zero
    @State private var selectedAction: ContextMenuAction?
    
    init(@ViewBuilder content: () -> Content, actions: [ContextMenuAction]) {
        self.content = content()
        self.actions = actions
    }
    
    var body: some View {
        content
            .overlay(
                Group {
                    if isShowingMenu {
                        contextMenuOverlay
                    }
                }
            )
            .onLongPressGesture(minimumDuration: 0.5) {
                withAnimation(.spring(response: 0.3)) {
                    isShowingMenu = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
    }
    
    private var contextMenuOverlay: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        isShowingMenu = false
                    }
                }
                .transition(.opacity)
            
            // Menu container
            VStack(spacing: 0) {
                ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                    contextMenuItem(action: action, index: index)
                    
                    if index < actions.count - 1 {
                        Divider()
                            .background(Color.white.opacity(0.1))
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0, green: 0.85, blue: 1).opacity(0.5),
                                        Color(red: 1, green: 0, blue: 0.43).opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: Color(red: 0, green: 0.85, blue: 1).opacity(0.3), radius: 20)
            .scaleEffect(isShowingMenu ? 1 : 0.8)
            .opacity(isShowingMenu ? 1 : 0)
            .offset(dragOffset)
            .animation(.spring(response: 0.3), value: isShowingMenu)
        }
    }
    
    private func contextMenuItem(action: ContextMenuAction, index: Int) -> some View {
        Button {
            selectedAction = action
            
            withAnimation(.spring(response: 0.3)) {
                isShowingMenu = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                action.action()
                selectedAction = nil
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: action.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor(for: action))
                    .frame(width: 24)
                
                Text(action.title)
                    .font(.system(size: 15))
                    .foregroundColor(textColor(for: action))
                
                Spacer()
                
                if selectedAction?.title == action.title {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(Color(red: 0, green: 0.85, blue: 1))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                selectedAction?.title == action.title
                    ? Color.white.opacity(0.1)
                    : Color.clear
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func iconColor(for action: ContextMenuAction) -> Color {
        if action.role == .destructive {
            return Color(red: 1, green: 0, blue: 0.43)
        }
        return Color(red: 0, green: 0.85, blue: 1)
    }
    
    private func textColor(for action: ContextMenuAction) -> Color {
        if action.role == .destructive {
            return Color(red: 1, green: 0.3, blue: 0.3)
        }
        return .white
    }
}

// MARK: - Message Actions Menu
struct MessageActionsMenu: View {
    let message: Message
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onRetry: () -> Void
    let onDelete: () -> Void
    let onShare: () -> Void
    
    @State private var showMenu = false
    @State private var selectedAction: String?
    
    var body: some View {
        Menu {
            // Copy action
            Button {
                performAction("copy", action: onCopy)
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            
            // Edit action (only for user messages)
            if message.role == .user {
                Button {
                    performAction("edit", action: onEdit)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            
            // Retry action
            Button {
                performAction("retry", action: onRetry)
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
            }
            
            // Share action
            Button {
                performAction("share", action: onShare)
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            
            Divider()
            
            // Delete action
            Button(role: .destructive) {
                performAction("delete", action: onDelete)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
                .padding(8)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.05))
                )
        }
    }
    
    private func performAction(_ name: String, action: @escaping () -> Void) {
        selectedAction = name
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            action()
            selectedAction = nil
        }
    }
}

// MARK: - Swipe Actions View
struct SwipeActionsView<Content: View>: View {
    let content: Content
    let leadingActions: [ContextMenuAction]
    let trailingActions: [ContextMenuAction]
    
    @GestureState private var dragOffset: CGSize = .zero
    @State private var offset: CGFloat = 0
    @State private var showingActions = false
    
    init(
        @ViewBuilder content: () -> Content,
        leadingActions: [ContextMenuAction] = [],
        trailingActions: [ContextMenuAction] = []
    ) {
        self.content = content()
        self.leadingActions = leadingActions
        self.trailingActions = trailingActions
    }
    
    var body: some View {
        ZStack {
            // Background actions
            HStack(spacing: 0) {
                if offset > 0 {
                    // Leading actions
                    ForEach(Array(leadingActions.enumerated()), id: \.offset) { _, action in
                        actionButton(action: action, isLeading: true)
                    }
                }
                
                Spacer()
                
                if offset < 0 {
                    // Trailing actions
                    ForEach(Array(trailingActions.enumerated()), id: \.offset) { _, action in
                        actionButton(action: action, isLeading: false)
                    }
                }
            }
            
            // Main content
            content
                .offset(x: offset + dragOffset.width)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            handleDragEnd(value: value)
                        }
                )
                .animation(.spring(response: 0.3), value: offset)
        }
    }
    
    private func actionButton(action: ContextMenuAction, isLeading: Bool) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                offset = 0
            }
            action.action()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: action.icon)
                    .font(.system(size: 20, weight: .medium))
                
                Text(action.title)
                    .font(.system(size: 10))
            }
            .foregroundColor(.white)
            .frame(width: 80)
            .frame(maxHeight: .infinity)
            .background(
                action.role == .destructive
                    ? Color.red
                    : isLeading 
                        ? Color(red: 0, green: 0.85, blue: 1)
                        : Color(red: 1, green: 0, blue: 0.43)
            )
        }
    }
    
    private func handleDragEnd(value: DragGesture.Value) {
        let threshold: CGFloat = 100
        
        withAnimation(.spring(response: 0.3)) {
            if value.translation.width > threshold && !leadingActions.isEmpty {
                offset = 80 * CGFloat(leadingActions.count)
                showingActions = true
            } else if value.translation.width < -threshold && !trailingActions.isEmpty {
                offset = -80 * CGFloat(trailingActions.count)
                showingActions = true
            } else {
                offset = 0
                showingActions = false
            }
        }
    }
}

// MARK: - Quick Actions Bar
struct QuickActionsBar: View {
    let actions: [ContextMenuAction]
    @State private var selectedAction: String?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(actions.enumerated()), id: \.offset) { _, action in
                    quickActionButton(action: action)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(
            Color(red: 0.05, green: 0.05, blue: 0.1).opacity(0.95)
                .blur(radius: 10)
        )
    }
    
    private func quickActionButton(action: ContextMenuAction) -> some View {
        Button {
            selectedAction = action.title
            action.action()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                selectedAction = nil
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: action.icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(action.title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(
                selectedAction == action.title 
                    ? .black
                    : .white
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(
                        selectedAction == action.title
                            ? LinearGradient(
                                colors: [
                                    Color(red: 0, green: 0.85, blue: 1),
                                    Color(red: 0, green: 0.7, blue: 0.9)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                selectedAction == action.title
                                    ? Color.clear
                                    : Color.white.opacity(0.2),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(selectedAction == action.title ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct ContextMenuView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Advanced context menu example
                AdvancedContextMenu(
                    content: {
                        Text("Long press me")
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                    },
                    actions: [
                        ContextMenuAction(title: "Copy", icon: "doc.on.doc", action: {}),
                        ContextMenuAction(title: "Edit", icon: "pencil", action: {}),
                        ContextMenuAction(title: "Share", icon: "square.and.arrow.up", action: {}),
                        ContextMenuAction(title: "Delete", icon: "trash", role: .destructive, action: {})
                    ]
                )
                
                // Quick actions bar
                QuickActionsBar(
                    actions: [
                        ContextMenuAction(title: "Reply", icon: "arrow.turn.up.left", action: {}),
                        ContextMenuAction(title: "Forward", icon: "arrow.turn.up.right", action: {}),
                        ContextMenuAction(title: "Copy", icon: "doc.on.doc", action: {}),
                        ContextMenuAction(title: "More", icon: "ellipsis", action: {})
                    ]
                )
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}