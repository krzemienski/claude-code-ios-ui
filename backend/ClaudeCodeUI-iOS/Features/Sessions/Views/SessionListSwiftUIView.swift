import SwiftUI
import Combine

// MARK: - Session List View
struct SessionListSwiftUIView: View {
    @StateObject private var viewModel = SessionListViewModel()
    @State private var searchText = ""
    @State private var sortOption: SortOption = .recent
    @State private var showNewSessionSheet = false
    @State private var selectedSessionForAction: Session?
    @State private var refreshID = UUID()
    
    enum SortOption: String, CaseIterable {
        case recent = "Recent"
        case messageCount = "Messages"
        case alphabetical = "A-Z"
        
        var icon: String {
            switch self {
            case .recent: return "clock"
            case .messageCount: return "message"
            case .alphabetical: return "textformat"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.black,
                    Color(hex: "1a0033").opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with search
                VStack(spacing: 16) {
                    // Title and sort
                    HStack {
                        Text("Sessions")
                            .font(.largeTitle.bold())
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "00D9FF"), Color(hex: "FF006E")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Spacer()
                        
                        // Sort picker
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(action: { 
                                    withAnimation(.spring()) {
                                        sortOption = option
                                    }
                                }) {
                                    Label(option.rawValue, systemImage: option.icon)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: sortOption.icon)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .foregroundColor(Color(hex: "00D9FF"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(hex: "00D9FF").opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Search bar
                    SearchBarView(text: $searchText)
                }
                .padding()
                .background(
                    Color.black.opacity(0.3)
                        .background(.ultraThinMaterial)
                )
                
                // Sessions list
                if filteredSessions.isEmpty {
                    EmptyStateView(
                        title: searchText.isEmpty ? "No Sessions" : "No Results",
                        message: searchText.isEmpty 
                            ? "Start a new conversation to see it here"
                            : "Try adjusting your search",
                        iconName: searchText.isEmpty ? "message.badge.plus" : "magnifyingglass",
                        actionTitle: searchText.isEmpty ? "New Session" : "Clear Search",
                        action: {
                            if searchText.isEmpty {
                                showNewSessionSheet = true
                            } else {
                                searchText = ""
                            }
                        }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredSessions) { session in
                                SessionRowView(
                                    session: session,
                                    onTap: {
                                        viewModel.selectSession(session)
                                    },
                                    onDelete: {
                                        viewModel.deleteSession(session)
                                    },
                                    onArchive: {
                                        viewModel.archiveSession(session)
                                    },
                                    onPin: {
                                        viewModel.togglePin(session)
                                    }
                                )
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.refreshSessions()
                        refreshID = UUID()
                    }
                }
            }
            
            // Floating action button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton(
                        icon: "plus",
                        action: { showNewSessionSheet = true }
                    )
                    .padding(24)
                }
            }
        }
        .sheet(isPresented: $showNewSessionSheet) {
            NewSessionSheet(isPresented: $showNewSessionSheet)
        }
        .task {
            await viewModel.loadSessions()
        }
    }
    
    private var filteredSessions: [Session] {
        let filtered = searchText.isEmpty 
            ? viewModel.sessions
            : viewModel.sessions.filter { session in
                session.summary?.localizedCaseInsensitiveContains(searchText) ?? false ||
                session.id.localizedCaseInsensitiveContains(searchText)
            }
        
        return filtered.sorted { lhs, rhs in
            switch sortOption {
            case .recent:
                return (lhs.lastActivity ?? Date.distantPast) > (rhs.lastActivity ?? Date.distantPast)
            case .messageCount:
                return lhs.messageCount > rhs.messageCount
            case .alphabetical:
                return (lhs.summary ?? "") < (rhs.summary ?? "")
            }
        }
    }
}

// MARK: - Search Bar
struct SearchBarView: View {
    @Binding var text: String
    @State private var isEditing = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(hex: "00D9FF").opacity(0.6))
                
                TextField("Search sessions...", text: $text)
                    .foregroundColor(.white)
                    .focused($isFocused)
                    .onTapGesture {
                        withAnimation {
                            isEditing = true
                        }
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        withAnimation {
                            text = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(hex: "00D9FF").opacity(0.6))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isFocused ? Color(hex: "00D9FF") : Color.clear, lineWidth: 1)
            )
            
            if isEditing {
                Button("Cancel") {
                    withAnimation {
                        text = ""
                        isEditing = false
                        isFocused = false
                    }
                }
                .foregroundColor(Color(hex: "00D9FF"))
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: isEditing)
        .animation(.spring(), value: text)
    }
}

// MARK: - Session Row
struct SessionRowView: View {
    let session: Session
    let onTap: () -> Void
    let onDelete: () -> Void
    let onArchive: () -> Void
    let onPin: () -> Void
    
    @State private var isPressed = false
    @State private var showActions = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .fill(statusColor)
                            .frame(width: 16, height: 16)
                            .opacity(session.isActive ? 0.3 : 0)
                            .scaleEffect(session.isActive ? 1.5 : 1)
                            .animation(
                                session.isActive 
                                    ? Animation.easeInOut(duration: 1.5).repeatForever()
                                    : .default,
                                value: session.isActive
                            )
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if session.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption)
                                .foregroundColor(Color(hex: "FF006E"))
                        }
                        
                        Text(session.summary ?? "New Session")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if let date = session.lastActivity {
                            Text(date.relativeFormat)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    HStack {
                        Label("\(session.messageCount)", systemImage: "message")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if session.hasUnread {
                            Circle()
                                .fill(Color(hex: "00D9FF"))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isPressed ? 0.08 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "00D9FF").opacity(0.3),
                                        Color(hex: "FF006E").opacity(0.3)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: session.isActive ? 1 : 0
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            
            Button(action: onArchive) {
                Label("Archive", systemImage: "archivebox")
            }
            .tint(Color.orange)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(action: onPin) {
                Label(session.isPinned ? "Unpin" : "Pin", 
                      systemImage: session.isPinned ? "pin.slash" : "pin")
            }
            .tint(Color(hex: "FF006E"))
        }
        .contextMenu {
            Button(action: onPin) {
                Label(session.isPinned ? "Unpin" : "Pin",
                      systemImage: session.isPinned ? "pin.slash" : "pin")
            }
            
            Button(action: onArchive) {
                Label("Archive", systemImage: "archivebox")
            }
            
            Divider()
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity) { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        } perform: {
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
    }
    
    private var statusColor: Color {
        if session.isActive {
            return Color(hex: "00D9FF")
        } else if session.isArchived {
            return Color.gray
        } else {
            return Color(hex: "FF006E").opacity(0.6)
        }
    }
}

// MARK: - New Session Sheet
struct NewSessionSheet: View {
    @Binding var isPresented: Bool
    @State private var sessionName = ""
    @State private var selectedProject: Project?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    TextField("Session name (optional)", text: $sessionName)
                        .textFieldStyle(CyberpunkTextFieldStyle())
                    
                    // Project picker would go here
                    
                    Spacer()
                    
                    Button(action: createSession) {
                        Text("Create Session")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "00D9FF"), Color(hex: "FF006E")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(Color(hex: "00D9FF"))
                }
            }
        }
    }
    
    private func createSession() {
        // Create session logic
        isPresented = false
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    @State private var isPressed = false
    @State private var rotation = 0.0
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                rotation += 90
            }
            action()
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "00D9FF"), Color(hex: "FF006E")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: Color(hex: "00D9FF").opacity(0.5), radius: 8, x: 0, y: 4)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(rotation))
            }
        }
        .scaleEffect(isPressed ? 0.9 : 1)
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity) { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        } perform: {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        }
    }
}

// MARK: - Supporting Models
struct Session: Identifiable {
    let id: String
    let summary: String?
    let messageCount: Int
    let lastActivity: Date?
    let isActive: Bool
    let isArchived: Bool
    let isPinned: Bool
    let hasUnread: Bool
}

// MARK: - View Model
class SessionListViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    func loadSessions() async {
        // Load sessions from API
    }
    
    func refreshSessions() async {
        // Refresh sessions
    }
    
    func selectSession(_ session: Session) {
        // Navigate to session
    }
    
    func deleteSession(_ session: Session) {
        // Delete session
    }
    
    func archiveSession(_ session: Session) {
        // Archive session
    }
    
    func togglePin(_ session: Session) {
        // Toggle pin status
    }
}

// MARK: - Date Extension
extension Date {
    var relativeFormat: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}