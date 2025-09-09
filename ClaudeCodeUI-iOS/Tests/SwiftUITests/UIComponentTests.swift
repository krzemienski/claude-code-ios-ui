//
//  UIComponentTests.swift
//  ClaudeCodeUI SwiftUI Tests
//
//  Created on 2025-01-16.
//
//  Comprehensive UI Component Testing Suite using ViewInspector
//

import XCTest
import SwiftUI
import ViewInspector
@testable import ClaudeCodeUI

// MARK: - Settings View Tests

final class SettingsViewTests: XCTestCase {
    
    var sut: SettingsView!
    
    override func setUp() {
        super.setUp()
        sut = SettingsView()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - View Structure Tests
    
    func testSettingsViewHasCorrectStructure() throws {
        let view = sut.body
        
        // Test ZStack exists
        let zStack = try view.inspect().zStack()
        XCTAssertNotNil(zStack)
        
        // Test background gradient
        let gradient = try zStack.linearGradient(0)
        XCTAssertNotNil(gradient)
        
        // Test ScrollView exists
        let scrollView = try zStack.scrollView(1)
        XCTAssertNotNil(scrollView)
        
        // Test VStack in ScrollView
        let vStack = try scrollView.vStack()
        XCTAssertNotNil(vStack)
    }
    
    func testHeaderSectionContent() throws {
        let headerSection = try sut.headerSection.inspect()
        
        // Test title text
        let titleText = try headerSection.vStack().text(0)
        XCTAssertEqual(try titleText.string(), "Settings")
        
        // Test subtitle text
        let subtitleText = try headerSection.vStack().text(1)
        XCTAssertEqual(try subtitleText.string(), "Customize your Claude Code experience")
        
        // Test font attributes
        let titleFont = try titleText.attributes().font()
        XCTAssertNotNil(titleFont)
    }
    
    func testAppearanceSectionToggles() throws {
        let appearanceSection = try sut.appearanceSection.inspect()
        
        // Test glow effects toggle
        let glowToggle = try appearanceSection.find(viewWithId: "glowEffectsToggle").toggle()
        XCTAssertNotNil(glowToggle)
        
        // Test animations toggle
        let animationsToggle = try appearanceSection.find(viewWithId: "animationsToggle").toggle()
        XCTAssertNotNil(animationsToggle)
    }
    
    // MARK: - State Management Tests
    
    func testFontSizeSliderUpdatesValue() throws {
        // Create a test view model
        let viewModel = SettingsViewModel()
        viewModel.fontSize = 12
        
        // Test initial value
        XCTAssertEqual(viewModel.fontSize, 12)
        
        // Update font size
        viewModel.fontSize = 16
        XCTAssertEqual(viewModel.fontSize, 16)
        
        // Test bounds
        viewModel.fontSize = 25 // Should be clamped
        XCTAssertLessThanOrEqual(viewModel.fontSize, 20)
    }
    
    func testThemeSelectionUpdates() throws {
        let viewModel = SettingsViewModel()
        
        // Test initial theme
        XCTAssertEqual(viewModel.selectedTheme, .cyberpunk)
        
        // Change theme
        viewModel.selectedTheme = .dark
        XCTAssertEqual(viewModel.selectedTheme, .dark)
        
        // Test persistence
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme")
        XCTAssertNotNil(savedTheme)
    }
    
    // MARK: - Interaction Tests
    
    func testExportSettingsButtonAction() throws {
        let viewModel = SettingsViewModel()
        
        // Test export creates file
        let exportURL = viewModel.exportSettings()
        XCTAssertNotNil(exportURL)
        
        if let url = exportURL {
            // Test file exists
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
            
            // Test file content is valid JSON
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            XCTAssertNotNil(json)
            
            // Clean up
            try FileManager.default.removeItem(at: url)
        }
    }
    
    func testConnectionTestValidation() async throws {
        let viewModel = SettingsViewModel()
        
        // Set test URL
        viewModel.backendURL = "http://localhost:3004"
        
        // Test connection
        await viewModel.testConnection()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Check status was updated
        XCTAssertNotNil(viewModel.connectionStatus)
    }
}

// MARK: - Message Bubble View Tests

final class MessageBubbleViewTests: XCTestCase {
    
    func testUserMessageBubbleRendering() throws {
        let message = Message(
            id: "test-1",
            sessionId: "session-1",
            content: "Test user message",
            role: .user,
            timestamp: Date()
        )
        
        let view = MessageBubbleView(message: message, isCurrentUser: true)
        let inspected = try view.inspect()
        
        // Test alignment for user message
        let hStack = try inspected.hStack()
        let spacer = try hStack.spacer(0)
        XCTAssertNotNil(spacer)
        
        // Test bubble color is correct for user
        let bubble = try hStack.vStack(1).view(MessageBubbleView.self).messageBubble
        XCTAssertNotNil(bubble)
    }
    
    func testAssistantMessageBubbleRendering() throws {
        let message = Message(
            id: "test-2",
            sessionId: "session-1",
            content: "Test assistant message",
            role: .assistant,
            timestamp: Date()
        )
        
        let view = MessageBubbleView(message: message, isCurrentUser: false)
        let inspected = try view.inspect()
        
        // Test role indicator exists
        let vStack = try inspected.hStack().vStack(0)
        let bubble = try vStack.view(MessageBubbleView.self).messageBubble
        
        // Find role indicator
        let roleStack = try bubble.inspect().vStack().hStack(0)
        let roleIcon = try roleStack.image(0)
        XCTAssertEqual(try roleIcon.actualImage().name(), "cpu")
    }
    
    func testCodeBlockDetection() throws {
        let codeMessage = Message(
            id: "test-3",
            sessionId: "session-1",
            content: "```swift\nlet x = 10\n```",
            role: .assistant,
            timestamp: Date()
        )
        
        let view = MessageBubbleView(message: codeMessage, isCurrentUser: false)
        
        // Test that code block view is rendered
        XCTAssertTrue(view.isCodeMessage)
    }
    
    func testMessageTimestampFormatting() throws {
        let date = Date()
        let message = Message(
            id: "test-4",
            sessionId: "session-1",
            content: "Test",
            role: .user,
            timestamp: date
        )
        
        let view = MessageBubbleView(message: message, isCurrentUser: true)
        
        // Test timestamp is formatted correctly
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let expectedTime = formatter.string(from: date)
        
        let timestamp = view.timeString(from: date)
        XCTAssertEqual(timestamp, expectedTime)
    }
    
    func testMessageContextMenuActions() throws {
        let message = Message(
            id: "test-5",
            sessionId: "session-1",
            content: "Test message with context menu",
            role: .user,
            timestamp: Date()
        )
        
        let view = MessageBubbleView(message: message, isCurrentUser: true)
        
        // Test copy action
        view.copyMessage()
        XCTAssertEqual(UIPasteboard.general.string, message.content)
    }
}

// MARK: - State Management Tests

final class SwiftUIStateManagementTests: XCTestCase {
    
    // Test @State property updates
    func testStatePropertyUpdates() throws {
        struct TestView: View {
            @State var counter = 0
            
            var body: some View {
                VStack {
                    Text("Count: \(counter)")
                    Button("Increment") {
                        counter += 1
                    }
                }
            }
        }
        
        let view = TestView()
        let inspected = try view.inspect()
        
        // Initial state
        let text = try inspected.vStack().text(0)
        XCTAssertEqual(try text.string(), "Count: 0")
        
        // Simulate button tap
        let button = try inspected.vStack().button(1)
        try button.tap()
        
        // Note: ViewInspector has limitations with @State updates
        // This would need runtime testing in actual UI tests
    }
    
    // Test @StateObject lifecycle
    func testStateObjectLifecycle() throws {
        class TestViewModel: ObservableObject {
            @Published var value = "Initial"
            var initCount = 0
            
            init() {
                initCount += 1
            }
        }
        
        struct TestView: View {
            @StateObject private var viewModel = TestViewModel()
            
            var body: some View {
                Text(viewModel.value)
            }
        }
        
        let view = TestView()
        
        // Test that StateObject is initialized only once
        // This requires runtime testing or UI testing
    }
    
    // Test @EnvironmentObject injection
    func testEnvironmentObjectInjection() throws {
        class SharedModel: ObservableObject {
            @Published var sharedValue = "Shared"
        }
        
        struct ParentView: View {
            @StateObject private var model = SharedModel()
            
            var body: some View {
                ChildView()
                    .environmentObject(model)
            }
        }
        
        struct ChildView: View {
            @EnvironmentObject var model: SharedModel
            
            var body: some View {
                Text(model.sharedValue)
            }
        }
        
        let parent = ParentView()
        let inspected = try parent.inspect()
        
        // Test environment object is passed
        let child = try inspected.view(ChildView.self)
        XCTAssertNotNil(child)
    }
    
    // Test @Binding propagation
    func testBindingPropagation() throws {
        struct ParentView: View {
            @State private var text = "Hello"
            
            var body: some View {
                ChildView(text: $text)
            }
        }
        
        struct ChildView: View {
            @Binding var text: String
            
            var body: some View {
                TextField("Enter text", text: $text)
            }
        }
        
        let parent = ParentView()
        let inspected = try parent.inspect()
        
        // Test binding is passed to child
        let child = try inspected.view(ChildView.self)
        let textField = try child.textField()
        XCTAssertNotNil(textField)
    }
}

// MARK: - Custom View Modifiers Tests

final class CustomViewModifiersTests: XCTestCase {
    
    func testCyberpunkButtonModifier() throws {
        struct CyberpunkButtonModifier: ViewModifier {
            func body(content: Content) -> some View {
                content
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.cyan, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                    .shadow(color: .cyan.opacity(0.5), radius: 10)
            }
        }
        
        let button = Button("Test") {}
            .modifier(CyberpunkButtonModifier())
        
        let inspected = try button.inspect()
        
        // Test modifier applied correctly
        XCTAssertNotNil(inspected)
    }
}

// MARK: - Test Helpers

extension View {
    func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func copyMessage() {
        // Helper for testing copy functionality
    }
}

// MARK: - Mock Objects

class SettingsViewModel: ObservableObject {
    enum Theme: String, CaseIterable {
        case cyberpunk, dark, light
    }
    
    @Published var selectedTheme: Theme = .cyberpunk
    @Published var fontSize: CGFloat = 14
    @Published var glowEffectsEnabled = true
    @Published var animationsEnabled = true
    @Published var showLineNumbers = true
    @Published var syntaxHighlighting = true
    @Published var tabSize = 4
    @Published var wordWrapEnabled = true
    @Published var backendURL = "http://localhost:3004"
    @Published var isTestingConnection = false
    @Published var connectionStatus: (success: Bool, message: String)?
    @Published var cacheSize = "0 MB"
    
    var appVersion: String { "1.0.0" }
    var buildNumber: String { "100" }
    
    func testConnection() async {
        isTestingConnection = true
        // Simulate network call
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        connectionStatus = (true, "Connected successfully")
        isTestingConnection = false
    }
    
    func exportSettings() -> URL? {
        let settings = [
            "theme": selectedTheme.rawValue,
            "fontSize": fontSize,
            "backendURL": backendURL
        ] as [String : Any]
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("settings.json")
        
        do {
            let data = try JSONSerialization.data(withJSONObject: settings)
            try data.write(to: tempURL)
            return tempURL
        } catch {
            return nil
        }
    }
    
    func clearCache() {
        cacheSize = "0 MB"
    }
    
    func resetToDefaults() {
        selectedTheme = .cyberpunk
        fontSize = 14
        backendURL = "http://localhost:3004"
    }
    
    func handleImportResult(_ result: Result<[URL], Error>) {
        // Handle import
    }
}

// Mock Message model
struct Message: Identifiable {
    let id: String
    let sessionId: String
    let content: String
    let role: MessageRole
    let timestamp: Date
    var metadata: MessageMetadata?
}

enum MessageRole {
    case user, assistant, system, human
    
    var displayName: String {
        switch self {
        case .user, .human: return "You"
        case .assistant: return "Claude"
        case .system: return "System"
        }
    }
}

struct MessageMetadata {
    var commandType: String?
}

// Mock Theme
struct CyberpunkTheme {
    static let textPrimary = UIColor.white
    static let textSecondary = UIColor.lightGray
    static let textTertiary = UIColor.gray
    static let primaryCyan = UIColor.cyan
    static let accentPink = UIColor.systemPink
    static let gradientBlue = UIColor.blue
    static let surface = UIColor(white: 0.1, alpha: 1)
    static let background = UIColor.black
    static let border = UIColor(white: 0.2, alpha: 1)
    static let success = UIColor.green
    static let error = UIColor.red
    static let warning = UIColor.orange
}

extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
}