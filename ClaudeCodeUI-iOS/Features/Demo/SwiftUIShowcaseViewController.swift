import UIKit
import SwiftUI
import Combine

// MARK: - SwiftUI Showcase View Controller
class SwiftUIShowcaseViewController: UIViewController {
    
    private var hostingController: UIHostingController<SwiftUIShowcaseView>?
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSwiftUIView()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        title = "SwiftUI Components"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Test",
            style: .plain,
            target: self,
            action: #selector(testComponents)
        )
    }
    
    private func setupSwiftUIView() {
        let showcaseView = SwiftUIShowcaseView()
        hostingController = addSwiftUIView(showcaseView) { hosting in
            hosting.configureCyberpunkTheme()
        }
    }
    
    @objc private func testComponents() {
        // Trigger test actions
        NotificationCenter.default.post(name: .testComponentsNotification, object: nil)
    }
}

// MARK: - SwiftUI Showcase View
struct SwiftUIShowcaseView: View {
    @StateObject private var viewModel = ShowcaseViewModel()
    @State private var selectedTab = 0
    @State private var showToast: ToastModifier.Toast?
    @State private var showModal = false
    @State private var showError = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.black, Color(hex: "1a0033").opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Title
                    Text("SwiftUI Components")
                        .font(.largeTitle.bold())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "00D9FF"), Color(hex: "FF006E")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding(.top)
                    
                    // Components sections
                    messageSection
                    sessionSection
                    loadingSection
                    emptyStateSection
                    interactiveSection
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            
            // Tab bar demo
            VStack {
                Spacer()
                CyberpunkTabBar(
                    selectedTab: $selectedTab,
                    items: [
                        .init(title: "Chat", icon: "message", badge: 3),
                        .init(title: "Files", icon: "folder", badge: nil),
                        .init(title: "Terminal", icon: "terminal", badge: 1),
                        .init(title: "Settings", icon: "gear", badge: nil)
                    ]
                )
            }
        }
        .modifier(ToastModifier(toast: $showToast))
        .sheet(isPresented: $showModal) {
            CyberpunkModalSheet(
                isPresented: $showModal,
                title: "Modal Demo"
            ) {
                VStack(spacing: 20) {
                    Text("This is a draggable modal sheet")
                        .foregroundColor(.white)
                    
                    Text("Drag down to dismiss or tap the X button")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Button("Close") {
                        showModal = false
                    }
                    .buttonStyle(CyberpunkButtonStyle())
                }
                .padding()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .testComponentsNotification)) { _ in
            testAllComponents()
        }
    }
    
    // MARK: - Message Section
    var messageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Messages")
            
            // User message
            MessageBubbleView(
                message: ChatMessage(
                    content: "Can you help me build a REST API?",
                    isCurrentUser: true,
                    timestamp: Date(),
                    status: .delivered,
                    isTyping: false,
                    isCode: false,
                    codeLanguage: nil,
                    toolUse: nil
                ),
                isCurrentUser: true,
                onRetry: nil,
                onCopy: { print("Copy message") },
                onDelete: { print("Delete message") }
            )
            
            // Assistant message with typing
            if viewModel.showTyping {
                MessageBubbleView(
                    message: ChatMessage(
                        content: nil,
                        isCurrentUser: false,
                        timestamp: Date(),
                        status: .sending,
                        isTyping: true,
                        isCode: false,
                        codeLanguage: nil,
                        toolUse: nil
                    ),
                    isCurrentUser: false
                )
            }
            
            // Assistant message with code
            MessageBubbleView(
                message: ChatMessage(
                    content: "const express = require('express');\nconst app = express();\n\napp.get('/', (req, res) => {\n  res.json({ message: 'Hello World' });\n});",
                    isCurrentUser: false,
                    timestamp: Date(),
                    status: .delivered,
                    isTyping: false,
                    isCode: true,
                    codeLanguage: "javascript",
                    toolUse: nil
                ),
                isCurrentUser: false
            )
            
            // Message with tool use
            MessageBubbleView(
                message: ChatMessage(
                    content: "I've searched for the best practices",
                    isCurrentUser: false,
                    timestamp: Date(),
                    status: .delivered,
                    isTyping: false,
                    isCode: false,
                    codeLanguage: nil,
                    toolUse: ToolUse(
                        name: "WebSearch",
                        type: "search",
                        input: "REST API best practices 2025",
                        output: "Found 10 relevant articles..."
                    )
                ),
                isCurrentUser: false
            )
        }
    }
    
    // MARK: - Session Section
    var sessionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Sessions")
            
            // Mock sessions
            ForEach(viewModel.mockSessions) { session in
                SessionRowView(
                    session: session,
                    onTap: { print("Tapped session: \(session.id)") },
                    onDelete: { print("Delete session: \(session.id)") },
                    onArchive: { print("Archive session: \(session.id)") },
                    onPin: { viewModel.togglePin(for: session.id) }
                )
            }
        }
    }
    
    // MARK: - Loading Section
    var loadingSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionTitle("Loading States")
            
            HStack(spacing: 32) {
                VStack(spacing: 8) {
                    CyberpunkProgressView(size: 50)
                    Text("Circular")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack(spacing: 8) {
                    PulsingDotsLoader()
                    Text("Dots")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack(spacing: 8) {
                    InlineLoadingIndicator(text: "Loading")
                    Text("Inline")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                Text("Progress Bar")
                    .font(.caption)
                    .foregroundColor(.gray)
                CyberpunkProgressBar(progress: viewModel.progress)
                    .frame(height: 20)
            }
            
            // Skeleton loading
            Text("Skeleton Loading")
                .font(.caption)
                .foregroundColor(.gray)
            ShimmerSkeletonView(rows: 2)
        }
    }
    
    // MARK: - Empty State Section
    var emptyStateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Empty & Error States")
            
            if showError {
                ErrorStateView(
                    error: .network,
                    onRetry: {
                        showError = false
                        showToast = .init(
                            message: "Retrying connection...",
                            type: .info,
                            duration: 2
                        )
                    }
                )
                .frame(height: 300)
            } else {
                EmptyStateView(
                    title: "No Data",
                    message: "Start by creating your first project",
                    iconName: "folder.badge.plus",
                    actionTitle: "Create Project",
                    action: {
                        showToast = .init(
                            message: "Project created!",
                            type: .success,
                            duration: 2
                        )
                    }
                )
                .frame(height: 300)
            }
            
            Button("Toggle Error State") {
                withAnimation {
                    showError.toggle()
                }
            }
            .buttonStyle(CyberpunkButtonStyle())
        }
    }
    
    // MARK: - Interactive Section
    var interactiveSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Interactive Components")
            
            HStack(spacing: 16) {
                // Toast triggers
                Button("Success") {
                    showToast = .init(
                        message: "Operation completed successfully!",
                        type: .success,
                        duration: 3
                    )
                }
                .buttonStyle(CyberpunkButtonStyle(color: .green))
                
                Button("Error") {
                    showToast = .init(
                        message: "Something went wrong",
                        type: .error,
                        duration: 3
                    )
                }
                .buttonStyle(CyberpunkButtonStyle(color: Color(hex: "FF006E")))
                
                Button("Warning") {
                    showToast = .init(
                        message: "Check your connection",
                        type: .warning,
                        duration: 3
                    )
                }
                .buttonStyle(CyberpunkButtonStyle(color: .orange))
            }
            
            // Modal trigger
            Button("Show Modal") {
                showModal = true
            }
            .buttonStyle(CyberpunkButtonStyle())
            
            // Floating action button
            HStack {
                Spacer()
                FloatingActionButton(
                    icon: "plus",
                    action: {
                        showToast = .init(
                            message: "FAB tapped!",
                            type: .info,
                            duration: 2
                        )
                    }
                )
            }
        }
    }
    
    // MARK: - Helpers
    func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title2.bold())
            .foregroundColor(Color(hex: "00D9FF"))
            .padding(.bottom, 8)
    }
    
    func testAllComponents() {
        // Trigger various animations and states
        withAnimation {
            viewModel.showTyping = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                viewModel.showTyping = false
            }
        }
        
        // Animate progress
        withAnimation(.linear(duration: 3)) {
            viewModel.progress = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            viewModel.progress = 0.0
        }
        
        // Show toast sequence
        showToast = .init(
            message: "Testing all components...",
            type: .info,
            duration: 2
        )
    }
}

// MARK: - View Model
class ShowcaseViewModel: ObservableObject {
    @Published var showTyping = false
    @Published var progress: Double = 0.3
    @Published var mockSessions: [Session] = [
        Session(
            id: "1",
            summary: "Building REST API with Node.js",
            messageCount: 42,
            lastActivity: Date(),
            isActive: true,
            isArchived: false,
            isPinned: true,
            hasUnread: false
        ),
        Session(
            id: "2",
            summary: "SwiftUI Component Development",
            messageCount: 18,
            lastActivity: Date().addingTimeInterval(-3600),
            isActive: false,
            isArchived: false,
            isPinned: false,
            hasUnread: true
        ),
        Session(
            id: "3",
            summary: "Database Schema Design",
            messageCount: 7,
            lastActivity: Date().addingTimeInterval(-86400),
            isActive: false,
            isArchived: true,
            isPinned: false,
            hasUnread: false
        )
    ]
    
    func togglePin(for sessionId: String) {
        if let index = mockSessions.firstIndex(where: { $0.id == sessionId }) {
            mockSessions[index] = Session(
                id: mockSessions[index].id,
                summary: mockSessions[index].summary,
                messageCount: mockSessions[index].messageCount,
                lastActivity: mockSessions[index].lastActivity,
                isActive: mockSessions[index].isActive,
                isArchived: mockSessions[index].isArchived,
                isPinned: !mockSessions[index].isPinned,
                hasUnread: mockSessions[index].hasUnread
            )
        }
    }
}

// MARK: - Button Style
struct CyberpunkButtonStyle: ButtonStyle {
    let color: Color
    
    init(color: Color = Color(hex: "00D9FF")) {
        self.color = color
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(configuration.isPressed ? 0.3 : 0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(color, lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let testComponentsNotification = Notification.Name("testComponentsNotification")
}