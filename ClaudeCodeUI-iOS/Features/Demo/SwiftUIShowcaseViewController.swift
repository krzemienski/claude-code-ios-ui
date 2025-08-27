import UIKit
import SwiftUI
import Combine

// MARK: - Toast Support
struct Toast {
    let message: String
    let type: ToastType
    
    enum ToastType {
        case success, error, info
    }
}

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
        let hosting = UIHostingController(rootView: showcaseView)
        hostingController = hosting
        
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hosting.didMove(toParent: self)
    }
    
    @objc private func testComponents() {
        // Trigger test actions
        NotificationCenter.default.post(name: .testComponentsNotification, object: nil)
    }
}

// MARK: - SwiftUI Showcase View
// Simplified demo view - components not yet implemented
struct SwiftUIShowcaseView: View {
    @StateObject private var viewModel = ShowcaseViewModel()
    @State private var showDemo = true
    
    struct ToastInfo {
        let message: String
        let type: ToastType
        let duration: Double
        
        enum ToastType {
            case success, error, info, warning
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.black, Color(red: 0.1, green: 0, blue: 0.2).opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Title
                Text("SwiftUI Components Demo")
                    .font(.largeTitle.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cyan, Color.pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.top)
                
                Text("Components are being implemented")
                    .font(.headline)
                    .foregroundColor(.white)
                
                // Simple demo content
                if showDemo {
                    VStack(spacing: 20) {
                        ForEach(viewModel.mockSessions) { session in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(session.summary ?? "No summary")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("\(session.messageCount) messages")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
        }
        .onReceive(NotificationCenter.default.publisher(for: .testComponentsNotification)) { _ in
            // Demo test action
            showDemo.toggle()
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
            projectId: "demo-project",
            summary: "Building REST API with Node.js",
            messageCount: 42,
            lastActivity: Date()
        ),
        Session(
            id: "2",
            projectId: "demo-project",
            summary: "SwiftUI Component Development",
            messageCount: 18,
            lastActivity: Date().addingTimeInterval(-3600)
        ),
        Session(
            id: "3",
            projectId: "demo-project",
            summary: "Database Schema Design",
            messageCount: 7,
            lastActivity: Date().addingTimeInterval(-86400)
        )
    ]
    
    func togglePin(for sessionId: String) {
        if let index = mockSessions.firstIndex(where: { $0.id == sessionId }) {
            mockSessions[index].isPinned = !(mockSessions[index].isPinned ?? false)
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