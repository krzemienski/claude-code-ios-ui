//
//  CursorSessionsView.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-16.
//

import SwiftUI

// MARK: - Cursor Sessions View
struct CursorSessionsView: View {
    @ObservedObject var viewModel: CursorViewModel
    @State private var selectedSession: CursorSession?
    @State private var showSessionDetail = false
    @State private var sortBy: SessionSortOption = .recent
    
    enum SessionSortOption: String, CaseIterable {
        case recent = "Recent"
        case title = "Title"
        case tokens = "Tokens"
        case cost = "Cost"
        
        var icon: String {
            switch self {
            case .recent: return "clock"
            case .title: return "textformat"
            case .tokens: return "number"
            case .cost: return "dollarsign.circle"
            }
        }
    }
    
    var sortedSessions: [CursorSession] {
        let sessions = viewModel.filteredSessions
        
        switch sortBy {
        case .recent:
            return sessions.sorted { $0.createdAt > $1.createdAt }
        case .title:
            return sessions.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .tokens:
            return sessions.sorted { ($0.metadata?.tokenCount ?? 0) > ($1.metadata?.tokenCount ?? 0) }
        case .cost:
            return sessions.sorted { ($0.metadata?.cost ?? 0) > ($1.metadata?.cost ?? 0) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Sessions")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                HStack {
                    Text("Browse and restore your Cursor AI sessions")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.6))
                    
                    Spacer()
                    
                    // Stats
                    HStack(spacing: 16) {
                        StatBadge(
                            icon: "bubble.left.and.bubble.right",
                            value: "\(viewModel.sessions.count)",
                            label: "Sessions"
                        )
                        
                        StatBadge(
                            icon: "number",
                            value: formatNumber(viewModel.totalTokenCount),
                            label: "Tokens"
                        )
                        
                        StatBadge(
                            icon: "dollarsign.circle",
                            value: String(format: "$%.2f", viewModel.estimatedCost),
                            label: "Cost"
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top)
            
            // Search and Sort
            VStack(spacing: 12) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.white.opacity(0.5))
                    
                    TextField("Search sessions...", text: $viewModel.searchText)
                        .foregroundColor(.white)
                }
                .padding(12)
                .background(Color.white.opacity(0.08))
                .cornerRadius(10)
                
                // Sort Options
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Text("Sort by:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.5))
                        
                        ForEach(SessionSortOption.allCases, id: \.self) { option in
                            SortButton(
                                title: option.rawValue,
                                icon: option.icon,
                                isSelected: sortBy == option,
                                action: { sortBy = option }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            // Sessions List
            if sortedSessions.isEmpty {
                EmptyStateView(
                    icon: "bubble.left.and.bubble.right",
                    title: viewModel.searchText.isEmpty ? "No Sessions" : "No Results",
                    message: viewModel.searchText.isEmpty ?
                        "Your Cursor AI sessions will appear here" :
                        "No sessions match your search"
                )
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(sortedSessions) { session in
                            SessionCard(
                                session: session,
                                onTap: {
                                    selectedSession = session
                                    showSessionDetail = true
                                },
                                onRestore: {
                                    Task {
                                        await viewModel.restoreSession(session)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(item: $selectedSession) { session in
            SessionDetailView(session: session, viewModel: viewModel)
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        } else {
            return "\(number)"
        }
    }
}

// MARK: - Session Card
struct SessionCard: View {
    let session: CursorSession
    let onTap: () -> Void
    let onRestore: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and Date
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(session.createdAt, style: .relative)
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                
                Spacer()
                
                // Model Badge
                if let model = session.metadata?.model {
                    ModelBadge(model: model)
                }
            }
            
            // Message Preview
            if let lastMessage = session.messages.last {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: lastMessage.role == .user ? "person.circle" : "cpu")
                            .font(.system(size: 10))
                            .foregroundColor(lastMessage.role == .user ?
                                           Color(red: 0, green: 0.85, blue: 1) :
                                           Color(red: 1, green: 0, blue: 0.43))
                        
                        Text(lastMessage.role == .user ? "You" : "AI")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(lastMessage.role == .user ?
                                           Color(red: 0, green: 0.85, blue: 1) :
                                           Color(red: 1, green: 0, blue: 0.43))
                    }
                    
                    Text(lastMessage.content)
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.7))
                        .lineLimit(2)
                }
                .padding(8)
                .background(Color.white.opacity(0.03))
                .cornerRadius(6)
            }
            
            // Stats and Actions
            HStack {
                // Stats
                if let metadata = session.metadata {
                    HStack(spacing: 12) {
                        if metadata.tokenCount > 0 {
                            StatChip(
                                icon: "number",
                                value: "\(metadata.tokenCount)",
                                color: Color.white.opacity(0.5)
                            )
                        }
                        
                        if metadata.cost > 0 {
                            StatChip(
                                icon: "dollarsign.circle",
                                value: String(format: "$%.3f", metadata.cost),
                                color: Color.white.opacity(0.5)
                            )
                        }
                    }
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 8) {
                    Button(action: onTap) {
                        Text("View")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 0, green: 0.85, blue: 1))
                    }
                    
                    Button(action: onRestore) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 11))
                            Text("Restore")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0, green: 0.85, blue: 1), Color(red: 0, green: 0.65, blue: 0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Session Detail View
struct SessionDetailView: View {
    let session: CursorSession
    @ObservedObject var viewModel: CursorViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1))
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Session Info
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Session Information")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            InfoRow(label: "Created", value: session.createdAt.formatted())
                            InfoRow(label: "Last Updated", value: session.updatedAt.formatted())
                            
                            if let metadata = session.metadata {
                                InfoRow(label: "Model", value: metadata.model)
                                InfoRow(label: "Tokens", value: "\(metadata.tokenCount)")
                                InfoRow(label: "Cost", value: String(format: "$%.4f", metadata.cost))
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        
                        // Messages
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Conversation")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            ForEach(session.messages) { message in
                                MessageBubble(message: message)
                            }
                        }
                        
                        // Actions
                        HStack(spacing: 16) {
                            Button(action: {
                                Task {
                                    await viewModel.restoreSession(session)
                                    dismiss()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Restore Session")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0, green: 0.85, blue: 1), Color(red: 0, green: 0.65, blue: 0.9)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(session.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0, green: 0.85, blue: 1))
                }
            }
        }
    }
}

// MARK: - Helper Views
struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(Color(red: 0, green: 0.85, blue: 1))
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Color.white.opacity(0.5))
        }
    }
}

struct SortButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? .black : Color(red: 0, green: 0.85, blue: 1))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected ?
                LinearGradient(
                    colors: [Color(red: 0, green: 0.85, blue: 1), Color(red: 0, green: 0.65, blue: 0.9)],
                    startPoint: .leading,
                    endPoint: .trailing
                ) : nil
            )
            .background(isSelected ? nil : Color.white.opacity(0.1))
            .cornerRadius(6)
        }
    }
}

struct ModelBadge: View {
    let model: String
    
    var modelColor: Color {
        if model.contains("gpt-4") {
            return Color.green
        } else if model.contains("claude") {
            return Color.purple
        } else {
            return Color.blue
        }
    }
    
    var body: some View {
        Text(model.uppercased())
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(modelColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(modelColor.opacity(0.1))
            .cornerRadius(4)
    }
}

struct StatChip: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(value)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(color)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

struct MessageBubble: View {
    let message: CursorMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: message.role == .user ? "person.circle.fill" : "cpu")
                    .foregroundColor(message.role == .user ?
                                   Color(red: 0, green: 0.85, blue: 1) :
                                   Color(red: 1, green: 0, blue: 0.43))
                
                Text(message.role == .user ? "You" : "AI")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(message.role == .user ?
                                   Color(red: 0, green: 0.85, blue: 1) :
                                   Color(red: 1, green: 0, blue: 0.43))
                
                Spacer()
                
                if let timestamp = message.timestamp {
                    Text(timestamp, style: .time)
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.5))
                }
            }
            
            Text(message.content)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(
            message.role == .user ?
            Color(red: 0, green: 0.85, blue: 1).opacity(0.1) :
            Color.white.opacity(0.05)
        )
        .cornerRadius(12)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(Color.white.opacity(0.3))
            
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}