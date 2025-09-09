//
//  VisualRegressionTests.swift
//  ClaudeCodeUI Visual Regression Tests
//
//  Created on 2025-01-16.
//
//  Visual regression and snapshot testing for SwiftUI components
//

import XCTest
import SwiftUI
import SnapshotTesting
@testable import ClaudeCodeUI

// MARK: - Visual Regression Tests

final class SwiftUIVisualRegressionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set to true to record new snapshots
        // isRecording = true
    }
    
    // MARK: - Component Snapshot Tests
    
    func testSettingsViewSnapshots() {
        let view = SettingsView()
        
        // Test different device sizes
        assertSnapshot(matching: view, as: .image(on: .iPhone13Pro))
        assertSnapshot(matching: view, as: .image(on: .iPhone13ProMax))
        assertSnapshot(matching: view, as: .image(on: .iPhone13Mini))
        assertSnapshot(matching: view, as: .image(on: .iPadPro12_9))
        
        // Test different color schemes
        assertSnapshot(matching: view, as: .image(on: .iPhone13Pro, traits: .init(userInterfaceStyle: .light)))
        assertSnapshot(matching: view, as: .image(on: .iPhone13Pro, traits: .init(userInterfaceStyle: .dark)))
        
        // Test different text sizes (Dynamic Type)
        assertSnapshot(matching: view, as: .image(on: .iPhone13Pro, traits: .init(preferredContentSizeCategory: .extraSmall)))
        assertSnapshot(matching: view, as: .image(on: .iPhone13Pro, traits: .init(preferredContentSizeCategory: .extraExtraExtraLarge)))
        assertSnapshot(matching: view, as: .image(on: .iPhone13Pro, traits: .init(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)))
    }
    
    func testMessageBubbleSnapshots() {
        // User message
        let userMessage = Message(
            id: "test-user",
            sessionId: "session-1",
            content: "This is a user message for snapshot testing",
            role: .user,
            timestamp: Date(timeIntervalSince1970: 1234567890)
        )
        
        let userBubble = MessageBubbleView(message: userMessage, isCurrentUser: true)
            .frame(width: 375)
            .background(Color.black)
        
        assertSnapshot(matching: userBubble, as: .image)
        
        // Assistant message
        let assistantMessage = Message(
            id: "test-assistant",
            sessionId: "session-1",
            content: "This is an assistant response with helpful information",
            role: .assistant,
            timestamp: Date(timeIntervalSince1970: 1234567890)
        )
        
        let assistantBubble = MessageBubbleView(message: assistantMessage, isCurrentUser: false)
            .frame(width: 375)
            .background(Color.black)
        
        assertSnapshot(matching: assistantBubble, as: .image)
        
        // Code message
        let codeMessage = Message(
            id: "test-code",
            sessionId: "session-1",
            content: """
            ```swift
            func example() {
                print("Hello, World!")
            }
            ```
            """,
            role: .assistant,
            timestamp: Date(timeIntervalSince1970: 1234567890)
        )
        
        let codeBubble = MessageBubbleView(message: codeMessage, isCurrentUser: false)
            .frame(width: 375)
            .background(Color.black)
        
        assertSnapshot(matching: codeBubble, as: .image)
    }
    
    func testLoadingStatesSnapshots() {
        // Loading skeleton
        let skeletonView = LoadingSkeletonView()
            .frame(width: 375, height: 200)
        
        assertSnapshot(matching: skeletonView, as: .image)
        
        // Progress indicator
        let progressView = ProgressIndicatorView(progress: 0.7)
            .frame(width: 375, height: 100)
        
        assertSnapshot(matching: progressView, as: .image)
        
        // Typing indicator
        let typingIndicator = TypingIndicatorView()
            .frame(width: 375, height: 100)
            .background(Color.black)
        
        assertSnapshot(matching: typingIndicator, as: .image)
    }
    
    func testErrorStatesSnapshots() {
        // Error alert
        let errorAlert = ErrorAlertView(
            title: "Connection Error",
            message: "Unable to connect to the server. Please check your network connection.",
            dismissAction: {}
        )
        .frame(width: 375, height: 200)
        
        assertSnapshot(matching: errorAlert, as: .image)
        
        // Empty state
        let emptyState = EmptyStateView(
            title: "No Messages",
            message: "Start a conversation by typing a message",
            systemImage: "message"
        )
        .frame(width: 375, height: 400)
        
        assertSnapshot(matching: emptyState, as: .image)
    }
    
    // MARK: - Theme Variation Tests
    
    func testThemeVariations() {
        struct ThemedView: View {
            let theme: Theme
            
            var body: some View {
                VStack(spacing: 20) {
                    Text("Theme: \(theme.name)")
                        .font(.title)
                        .foregroundColor(theme.primaryColor)
                    
                    Button("Primary Button") {}
                        .buttonStyle(theme.buttonStyle)
                    
                    Toggle("Setting", isOn: .constant(true))
                        .toggleStyle(theme.toggleStyle)
                }
                .padding()
                .frame(width: 350, height: 200)
                .background(theme.backgroundColor)
            }
        }
        
        let themes = [
            Theme(name: "Cyberpunk", primaryColor: .cyan, backgroundColor: Color(white: 0.05)),
            Theme(name: "Dark", primaryColor: .blue, backgroundColor: .black),
            Theme(name: "Light", primaryColor: .blue, backgroundColor: .white)
        ]
        
        for theme in themes {
            let themedView = ThemedView(theme: theme)
            assertSnapshot(matching: themedView, as: .image, named: theme.name)
        }
    }
    
    // MARK: - Interaction State Tests
    
    func testButtonInteractionStates() {
        struct ButtonStatesView: View {
            var body: some View {
                VStack(spacing: 20) {
                    // Normal state
                    Button("Normal") {}
                        .buttonStyle(CyberpunkButtonStyle(isPressed: false, isDisabled: false))
                    
                    // Pressed state
                    Button("Pressed") {}
                        .buttonStyle(CyberpunkButtonStyle(isPressed: true, isDisabled: false))
                    
                    // Disabled state
                    Button("Disabled") {}
                        .buttonStyle(CyberpunkButtonStyle(isPressed: false, isDisabled: true))
                }
                .padding()
                .frame(width: 300, height: 200)
                .background(Color.black)
            }
        }
        
        let view = ButtonStatesView()
        assertSnapshot(matching: view, as: .image)
    }
    
    func testFormValidationStates() {
        struct FormView: View {
            var body: some View {
                VStack(spacing: 20) {
                    // Valid field
                    TextField("Valid", text: .constant("valid@email.com"))
                        .textFieldStyle(ValidationTextFieldStyle(isValid: true))
                    
                    // Invalid field
                    TextField("Invalid", text: .constant("invalid"))
                        .textFieldStyle(ValidationTextFieldStyle(isValid: false))
                    
                    // Empty required field
                    TextField("Required", text: .constant(""))
                        .textFieldStyle(ValidationTextFieldStyle(isValid: false, showError: true))
                }
                .padding()
                .frame(width: 300, height: 200)
            }
        }
        
        let view = FormView()
        assertSnapshot(matching: view, as: .image)
    }
    
    // MARK: - Layout Tests
    
    func testResponsiveLayouts() {
        struct ResponsiveGrid: View {
            let columns: [GridItem]
            
            var body: some View {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(0..<12) { index in
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(0.3))
                                .frame(height: 100)
                                .overlay(Text("\(index + 1)"))
                        }
                    }
                    .padding()
                }
            }
        }
        
        // Test different column layouts
        let layouts = [
            (name: "Single", columns: [GridItem(.flexible())]),
            (name: "Double", columns: Array(repeating: GridItem(.flexible()), count: 2)),
            (name: "Triple", columns: Array(repeating: GridItem(.flexible()), count: 3)),
            (name: "Adaptive", columns: [GridItem(.adaptive(minimum: 100))])
        ]
        
        for layout in layouts {
            let view = ResponsiveGrid(columns: layout.columns)
                .frame(width: 375, height: 600)
            
            assertSnapshot(matching: view, as: .image, named: layout.name)
        }
    }
    
    // MARK: - Animation Frame Tests
    
    func testAnimationFrames() {
        struct AnimatedView: View {
            let progress: Double
            
            var body: some View {
                VStack {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 100, height: 100)
                        .scaleEffect(1 + progress * 0.5)
                        .rotationEffect(.degrees(progress * 360))
                        .opacity(1 - progress * 0.3)
                    
                    Text("Progress: \(Int(progress * 100))%")
                        .foregroundColor(.white)
                }
                .frame(width: 200, height: 200)
                .background(Color.black)
            }
        }
        
        // Capture animation frames
        let frames = [0.0, 0.25, 0.5, 0.75, 1.0]
        for progress in frames {
            let view = AnimatedView(progress: progress)
            assertSnapshot(matching: view, as: .image, named: "frame-\(Int(progress * 100))")
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilitySnapshots() {
        struct AccessibleView: View {
            var body: some View {
                VStack(spacing: 20) {
                    Text("Accessible Content")
                        .font(.largeTitle)
                        .accessibilityLabel("Main heading")
                        .accessibilityAddTraits(.isHeader)
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Item")
                        }
                    }
                    .accessibilityLabel("Add new item")
                    .accessibilityHint("Double tap to add a new item to the list")
                    
                    Slider(value: .constant(0.5))
                        .accessibilityLabel("Volume")
                        .accessibilityValue("50 percent")
                }
                .padding()
                .frame(width: 300, height: 200)
            }
        }
        
        let view = AccessibleView()
        
        // Test with accessibility inspector overlay
        assertSnapshot(matching: view, as: .image(traits: .init(accessibilityOptions: .invertColors)))
        assertSnapshot(matching: view, as: .image(traits: .init(displayGamut: .P3)))
    }
}

// MARK: - Helper Types

struct Theme {
    let name: String
    let primaryColor: Color
    let backgroundColor: Color
    
    var buttonStyle: some PrimitiveButtonStyle {
        ThemedButtonStyle(primaryColor: primaryColor)
    }
    
    var toggleStyle: some ToggleStyle {
        ThemedToggleStyle(primaryColor: primaryColor)
    }
}

struct ThemedButtonStyle: PrimitiveButtonStyle {
    let primaryColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(primaryColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}

struct ThemedToggleStyle: ToggleStyle {
    let primaryColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Rectangle()
                .fill(configuration.isOn ? primaryColor : Color.gray)
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .offset(x: configuration.isOn ? 10 : -10)
                )
                .cornerRadius(15)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

struct CyberpunkButtonStyle: PrimitiveButtonStyle {
    let isPressed: Bool
    let isDisabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(
                LinearGradient(
                    colors: isDisabled ? [Color.gray] : (isPressed ? [Color.blue] : [Color.cyan, Color.blue]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isDisabled ? 0.5 : 1.0)
    }
}

struct ValidationTextFieldStyle: TextFieldStyle {
    let isValid: Bool
    var showError: Bool = false
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isValid ? Color.green : Color.red, lineWidth: showError ? 2 : 1)
            )
    }
}

// Mock Views for Testing
struct LoadingSkeletonView: View {
    var body: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 20)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 20)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 60)
        }
        .padding()
    }
}

struct ProgressIndicatorView: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.cyan)
                    .frame(width: geometry.size.width * progress)
            }
        }
        .frame(height: 20)
        .padding()
    }
}

struct ErrorAlertView: View {
    let title: String
    let message: String
    let dismissAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.caption)
                .multilineTextAlignment(.center)
            
            Button("Dismiss", action: dismissAction)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Device Configurations

extension ViewImageConfig {
    static let iPhone13Pro = ViewImageConfig.iPhone13Pro
    static let iPhone13ProMax = ViewImageConfig.iPhone13ProMax
    static let iPhone13Mini = ViewImageConfig.iPhone13Mini
    static let iPadPro12_9 = ViewImageConfig.iPadPro12_9
}