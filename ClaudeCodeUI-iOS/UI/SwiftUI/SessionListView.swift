//
//  SessionListView.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-14.
//

import SwiftUI

// MARK: - Session List View Model
@MainActor
class SessionListViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var filteredSessions: [Session] = []
    @Published var searchText: String = ""
    @Published var sortOption: SortOption = .recent
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hasMoreSessions: Bool = true
    
    private let project: Project
    private let apiClient = APIClient.shared
    private var currentOffset: Int = 0
    private let pageSize: Int = 20
    
    enum SortOption: String, CaseIterable {
        case recent = "Recent"
        case messageCount = "Messages"
        case name = "Name"
        
        var icon: String {
            switch self {
            case .recent: return "clock.fill"
            case .messageCount: return "message.fill"
            case .name: return "textformat"
            }
        }
    }
    
    init(project: Project) {
        self.project = project
    }
    
    @MainActor
    func loadSessions(append: Bool = false) async {
        guard !isLoading else { return }
        
        if !append {
            currentOffset = 0
            hasMoreSessions = true
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedSessions = try await apiClient.fetchSessions(
                projectName: project.name,
                limit: pageSize,
                offset: currentOffset
            )
            
            if append {
                sessions.append(contentsOf: fetchedSessions)
            } else {
                sessions = fetchedSessions
            }
            
            hasMoreSessions = fetchedSessions.count == pageSize
            currentOffset += fetchedSessions.count
            applyFilters()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func deleteSession(_ session: Session) async {
        do {
            try await apiClient.deleteSession(projectName: project.name, sessionId: session.id)
            sessions.removeAll { $0.id == session.id }
            applyFilters()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func createNewSession() async -> Session? {
        isLoading = true
        errorMessage = nil
        
        do {
            let newSession = try await apiClient.createSession(projectName: project.name)
            sessions.insert(newSession, at: 0)
            applyFilters()
            isLoading = false
            return newSession
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return nil
        }
    }
    
    func applyFilters() {
        // Apply search filter
        var filtered = sessions
        if !searchText.isEmpty {
            filtered = sessions.filter { session in
                let summaryMatch = session.summary?.localizedCaseInsensitiveContains(searchText) ?? false
                let idMatch = session.id.localizedCaseInsensitiveContains(searchText)
                return summaryMatch || idMatch
            }
        }
        
        // Apply sorting
        switch sortOption {
        case .recent:
            filtered.sort { 
                let date1 = $0.lastActivity ?? Date.distantPast
                let date2 = $1.lastActivity ?? Date.distantPast
                return date1 > date2
            }
        case .messageCount:
            filtered.sort { $0.messageCount > $1.messageCount }
        case .name:
            filtered.sort { 
                let summary1 = $0.summary ?? ""
                let summary2 = $1.summary ?? ""
                return summary1.localizedCaseInsensitiveCompare(summary2) == .orderedAscending
            }
        }
        
        filteredSessions = filtered
    }
}

// MARK: - Main Session List View
struct SessionListView: View {
    @StateObject private var viewModel: SessionListViewModel
    @State private var showingCreateAlert = false
    @State private var sessionToDelete: Session?
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) private var dismiss
    
    let onSessionSelected: (Session) -> Void
    let onCreateSession: () -> Void
    
    init(project: Project, 
         onSessionSelected: @escaping (Session) -> Void,
         onCreateSession: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: SessionListViewModel(project: project))
        self.onSessionSelected = onSessionSelected
        self.onCreateSession = onCreateSession
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color(red: 0.02, green: 0.02, blue: 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Sort Options
                sortOptionsView
                
                // Search Bar
                searchBarView
                
                // Session List
                if viewModel.filteredSessions.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    sessionListView
                }
            }
            
            // Floating Action Button
            floatingActionButton
            
            // Loading Overlay
            if viewModel.isLoading && viewModel.sessions.isEmpty {
                LoadingStateView()
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadSessions()
        }
        .refreshable {
            await viewModel.loadSessions()
        }
        .alert("Delete Session", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let session = sessionToDelete {
                    Task {
                        await viewModel.deleteSession(session)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this session? This action cannot be undone.")
        }
    }
    
    // MARK: - View Components
    
    private var sortOptionsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(SessionListViewModel.SortOption.allCases, id: \.self) { option in
                    SortChipView(
                        title: option.rawValue,
                        icon: option.icon,
                        isSelected: viewModel.sortOption == option
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.sortOption = option
                            viewModel.applyFilters()
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(red: 0, green: 0.85, blue: 1))
            
            TextField("Search sessions...", text: $viewModel.searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.white)
                .onChange(of: viewModel.searchText) { _ in
                    viewModel.applyFilters()
                }
            
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    withAnimation {
                        viewModel.searchText = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0, green: 0.85, blue: 1).opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var sessionListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredSessions) { session in
                    SessionRowView(session: session)
                        .onTapGesture {
                            onSessionSelected(session)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                sessionToDelete = session
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button {
                                onSessionSelected(session)
                            } label: {
                                Label("Open", systemImage: "arrow.right.circle")
                            }
                            
                            Button {
                                // Archive functionality
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                sessionToDelete = session
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    
                    // Load more trigger
                    if session == viewModel.filteredSessions.last && viewModel.hasMoreSessions {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .task {
                                await viewModel.loadSessions(append: true)
                            }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 80) // Space for FAB
        }
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "bubble.left.and.bubble.right",
            title: viewModel.searchText.isEmpty ? "No Sessions Yet" : "No Results",
            message: viewModel.searchText.isEmpty 
                ? "Start a new conversation to begin"
                : "Try adjusting your search terms"
        )
    }
    
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                FloatingActionButton(
                    icon: "plus",
                    action: onCreateSession
                )
                .padding()
            }
        }
    }
}

// MARK: - Session Row View
struct SessionRowView: View {
    let session: Session
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Status Indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(statusColor.opacity(0.3), lineWidth: 2)
                        .frame(width: 16, height: 16)
                )
            
            // Session Info
            VStack(alignment: .leading, spacing: 6) {
                Text(session.summary ?? "New Session")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    // Message Count
                    Label("\(session.messageCount)", systemImage: "message")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0, green: 0.85, blue: 1))
                    
                    // Last Activity
                    if let lastActivity = session.lastActivity {
                        Label(relativeTimeString(from: lastActivity), systemImage: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 1, green: 0, blue: 0.43))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(isPressed ? 0.08 : 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0, green: 0.85, blue: 1).opacity(0.3),
                                    Color(red: 1, green: 0, blue: 0.43).opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onTapGesture {}
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity) { _ in
            withAnimation(.spring(response: 0.3)) {
                isPressed = true
            }
        } onPressingChanged: { pressing in
            withAnimation(.spring(response: 0.3)) {
                isPressed = pressing
            }
        }
    }
    
    private var statusColor: Color {
        // Determine status based on last activity
        guard let lastActivity = session.lastActivity else {
            return Color.gray
        }
        
        let timeSinceActivity = Date().timeIntervalSince(lastActivity)
        if timeSinceActivity < 300 { // Active in last 5 minutes
            return Color(red: 0, green: 0.85, blue: 1) // Cyan
        } else if timeSinceActivity < 3600 { // Active in last hour
            return Color(red: 1, green: 0, blue: 0.43) // Pink
        } else {
            return Color.gray
        }
    }
    
    private func relativeTimeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Sort Chip View
struct SortChipView: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected 
                        ? Color(red: 0, green: 0.85, blue: 1).opacity(0.2)
                        : Color.white.opacity(0.05))
                    .overlay(
                        Capsule()
                            .stroke(isSelected 
                                ? Color(red: 0, green: 0.85, blue: 1)
                                : Color.white.opacity(0.1), 
                                lineWidth: 1)
                    )
            )
            .foregroundColor(isSelected 
                ? Color(red: 0, green: 0.85, blue: 1)
                : Color.white.opacity(0.7))
        }
    }
}

// MARK: - Preview
struct SessionListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SessionListView(
                project: Project(
                    id: "1",
                    name: "Test Project",
                    path: "/test",
                    sessions: []
                ),
                onSessionSelected: { _ in },
                onCreateSession: {}
            )
        }
        .preferredColorScheme(.dark)
    }
}