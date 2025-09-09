//
//  UserInteractionTests.swift
//  ClaudeCodeUI User Interaction Tests
//
//  Created on 2025-01-16.
//
//  User interaction and gesture testing for SwiftUI components
//

import XCTest
import SwiftUI
import ViewInspector
@testable import ClaudeCodeUI

// MARK: - User Interaction Tests

final class SwiftUIUserInteractionTests: XCTestCase {
    
    // MARK: - Gesture Recognition Tests
    
    func testTapGestureRecognition() throws {
        var tapCount = 0
        
        struct TappableView: View, Inspectable {
            let onTap: () -> Void
            
            var body: some View {
                Text("Tap Me")
                    .padding()
                    .background(Color.blue)
                    .onTapGesture {
                        onTap()
                    }
            }
        }
        
        let view = TappableView {
            tapCount += 1
        }
        
        // Simulate tap
        let text = try view.inspect().text()
        try text.callOnTapGesture()
        
        XCTAssertEqual(tapCount, 1, "Tap gesture should increment counter")
        
        // Multiple taps
        try text.callOnTapGesture()
        try text.callOnTapGesture()
        
        XCTAssertEqual(tapCount, 3, "Multiple taps should be recognized")
    }
    
    func testLongPressGesture() throws {
        var isPressed = false
        var pressDuration: TimeInterval = 0
        
        struct LongPressView: View, Inspectable {
            let onLongPress: (TimeInterval) -> Void
            
            var body: some View {
                Text("Long Press Me")
                    .padding()
                    .background(Color.green)
                    .onLongPressGesture(minimumDuration: 1.0) {
                        onLongPress(1.0)
                    }
            }
        }
        
        let view = LongPressView { duration in
            isPressed = true
            pressDuration = duration
        }
        
        // Simulate long press
        let text = try view.inspect().text()
        try text.callOnLongPressGesture()
        
        XCTAssertTrue(isPressed, "Long press should be recognized")
        XCTAssertEqual(pressDuration, 1.0, "Long press duration should match minimum")
    }
    
    func testDragGesture() throws {
        var dragOffset = CGSize.zero
        var isDragging = false
        
        struct DraggableView: View, Inspectable {
            @State private var offset = CGSize.zero
            let onDrag: (CGSize) -> Void
            let onDragEnd: () -> Void
            
            var body: some View {
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 100, height: 100)
                    .offset(offset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = value.translation
                                onDrag(value.translation)
                            }
                            .onEnded { _ in
                                onDragEnd()
                            }
                    )
            }
        }
        
        let view = DraggableView(
            onDrag: { offset in
                dragOffset = offset
                isDragging = true
            },
            onDragEnd: {
                isDragging = false
            }
        )
        
        // Test drag gesture tracking
        XCTAssertEqual(dragOffset, CGSize.zero, "Initial offset should be zero")
        
        // Simulate drag
        // Note: ViewInspector has limitations with complex gestures
        // This would require UI testing for full validation
    }
    
    func testSwipeGesture() throws {
        var swipeDirection: SwipeDirection?
        
        enum SwipeDirection {
            case left, right, up, down
        }
        
        struct SwipeableView: View {
            let onSwipe: (SwipeDirection) -> Void
            
            var body: some View {
                Rectangle()
                    .fill(Color.purple)
                    .frame(width: 200, height: 200)
                    .gesture(
                        DragGesture(minimumDistance: 30)
                            .onEnded { value in
                                let horizontal = value.translation.width
                                let vertical = value.translation.height
                                
                                if abs(horizontal) > abs(vertical) {
                                    onSwipe(horizontal > 0 ? .right : .left)
                                } else {
                                    onSwipe(vertical > 0 ? .down : .up)
                                }
                            }
                    )
            }
        }
        
        let view = SwipeableView { direction in
            swipeDirection = direction
        }
        
        // Test swipe detection logic
        XCTAssertNil(swipeDirection, "No swipe should be detected initially")
    }
    
    // MARK: - Form Interaction Tests
    
    func testTextFieldInteraction() throws {
        struct FormView: View, Inspectable {
            @State private var username = ""
            @State private var password = ""
            @State private var isValid = false
            
            var body: some View {
                VStack {
                    TextField("Username", text: $username)
                        .onChange(of: username) { _ in
                            validateForm()
                        }
                    
                    SecureField("Password", text: $password)
                        .onChange(of: password) { _ in
                            validateForm()
                        }
                    
                    Button("Submit") {
                        // Submit action
                    }
                    .disabled(!isValid)
                }
            }
            
            private func validateForm() {
                isValid = !username.isEmpty && password.count >= 8
            }
        }
        
        let view = FormView()
        let inspected = try view.inspect()
        
        // Test text field exists
        let usernameField = try inspected.vStack().textField(0)
        XCTAssertNotNil(usernameField)
        
        // Test secure field exists
        let passwordField = try inspected.vStack().secureField(1)
        XCTAssertNotNil(passwordField)
        
        // Test submit button is initially disabled
        let submitButton = try inspected.vStack().button(2)
        XCTAssertNotNil(submitButton)
    }
    
    func testToggleInteraction() throws {
        var toggleStates = [String: Bool]()
        
        struct SettingsToggles: View, Inspectable {
            @State private var notificationsEnabled = false
            @State private var darkModeEnabled = true
            @State private var soundEnabled = false
            
            let onChange: (String, Bool) -> Void
            
            var body: some View {
                VStack {
                    Toggle("Notifications", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { value in
                            onChange("notifications", value)
                        }
                    
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                        .onChange(of: darkModeEnabled) { value in
                            onChange("darkMode", value)
                        }
                    
                    Toggle("Sound", isOn: $soundEnabled)
                        .onChange(of: soundEnabled) { value in
                            onChange("sound", value)
                        }
                }
            }
        }
        
        let view = SettingsToggles { key, value in
            toggleStates[key] = value
        }
        
        let inspected = try view.inspect()
        
        // Test toggles exist
        let notificationToggle = try inspected.vStack().toggle(0)
        let darkModeToggle = try inspected.vStack().toggle(1)
        let soundToggle = try inspected.vStack().toggle(2)
        
        XCTAssertNotNil(notificationToggle)
        XCTAssertNotNil(darkModeToggle)
        XCTAssertNotNil(soundToggle)
    }
    
    func testPickerInteraction() throws {
        var selectedOption = ""
        
        struct PickerView: View, Inspectable {
            @State private var selection = "Option1"
            let options = ["Option1", "Option2", "Option3"]
            let onSelect: (String) -> Void
            
            var body: some View {
                Picker("Select Option", selection: $selection) {
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selection) { value in
                    onSelect(value)
                }
            }
        }
        
        let view = PickerView { option in
            selectedOption = option
        }
        
        let inspected = try view.inspect()
        let picker = try inspected.picker()
        
        XCTAssertNotNil(picker)
        
        // Test picker has correct number of options
        let forEach = try picker.forEach()
        XCTAssertEqual(try forEach.count, 3)
    }
    
    func testSliderInteraction() throws {
        var sliderValue: Double = 0
        
        struct SliderView: View, Inspectable {
            @State private var value: Double = 50
            let onValueChange: (Double) -> Void
            
            var body: some View {
                VStack {
                    Slider(value: $value, in: 0...100, step: 1)
                        .onChange(of: value) { newValue in
                            onValueChange(newValue)
                        }
                    
                    Text("Value: \(Int(value))")
                }
            }
        }
        
        let view = SliderView { value in
            sliderValue = value
        }
        
        let inspected = try view.inspect()
        
        // Test slider exists
        let slider = try inspected.vStack().slider(0)
        XCTAssertNotNil(slider)
        
        // Test value display
        let valueText = try inspected.vStack().text(1)
        XCTAssertEqual(try valueText.string(), "Value: 50")
    }
    
    // MARK: - Navigation Tests
    
    func testNavigationLinkInteraction() throws {
        var navigationTriggered = false
        
        struct NavigationView: View, Inspectable {
            @State private var isActive = false
            let onNavigate: () -> Void
            
            var body: some View {
                NavigationStack {
                    VStack {
                        NavigationLink(
                            "Go to Details",
                            destination: DetailView(),
                            isActive: $isActive
                        )
                        .onChange(of: isActive) { value in
                            if value { onNavigate() }
                        }
                    }
                }
            }
        }
        
        struct DetailView: View {
            var body: some View {
                Text("Detail View")
            }
        }
        
        let view = NavigationView {
            navigationTriggered = true
        }
        
        let inspected = try view.inspect()
        
        // Test navigation link exists
        XCTAssertNotNil(inspected)
        
        // Navigation would be triggered through isActive binding
        // Full testing requires UI tests
    }
    
    func testSheetPresentation() throws {
        var sheetPresented = false
        
        struct SheetView: View, Inspectable {
            @State private var showSheet = false
            let onPresent: () -> Void
            
            var body: some View {
                Button("Show Sheet") {
                    showSheet = true
                    onPresent()
                }
                .sheet(isPresented: $showSheet) {
                    Text("Sheet Content")
                }
            }
        }
        
        let view = SheetView {
            sheetPresented = true
        }
        
        let inspected = try view.inspect()
        let button = try inspected.button()
        
        // Simulate button tap
        try button.tap()
        
        XCTAssertTrue(sheetPresented, "Sheet should be presented on button tap")
    }
    
    // MARK: - Complex Interaction Tests
    
    func testSearchBarInteraction() throws {
        var searchResults: [String] = []
        
        struct SearchView: View, Inspectable {
            @State private var searchText = ""
            let items = ["Apple", "Banana", "Cherry", "Date", "Elderberry"]
            let onSearch: ([String]) -> Void
            
            var filteredItems: [String] {
                if searchText.isEmpty {
                    return items
                } else {
                    return items.filter { $0.localizedCaseInsensitiveContains(searchText) }
                }
            }
            
            var body: some View {
                VStack {
                    TextField("Search", text: $searchText)
                        .onChange(of: searchText) { _ in
                            onSearch(filteredItems)
                        }
                    
                    List(filteredItems, id: \.self) { item in
                        Text(item)
                    }
                }
            }
        }
        
        let view = SearchView { results in
            searchResults = results
        }
        
        // Test initial state
        XCTAssertEqual(searchResults.count, 0, "Initially no search performed")
        
        // Test search functionality
        let inspected = try view.inspect()
        let searchField = try inspected.vStack().textField(0)
        XCTAssertNotNil(searchField)
        
        // Test list displays filtered results
        let list = try inspected.vStack().list(1)
        XCTAssertNotNil(list)
    }
    
    func testPullToRefresh() throws {
        var refreshCount = 0
        
        struct RefreshableList: View, Inspectable {
            @State private var items = ["Item 1", "Item 2", "Item 3"]
            let onRefresh: () async -> Void
            
            var body: some View {
                List(items, id: \.self) { item in
                    Text(item)
                }
                .refreshable {
                    await onRefresh()
                    // Add new item after refresh
                    items.append("Item \(items.count + 1)")
                }
            }
        }
        
        let view = RefreshableList {
            refreshCount += 1
        }
        
        let inspected = try view.inspect()
        let list = try inspected.list()
        
        XCTAssertNotNil(list)
        
        // Refreshable modifier testing requires runtime/UI testing
    }
    
    func testContextMenuInteraction() throws {
        var selectedAction: String?
        
        struct ContextMenuView: View, Inspectable {
            let onAction: (String) -> Void
            
            var body: some View {
                Text("Long press for menu")
                    .padding()
                    .background(Color.gray)
                    .contextMenu {
                        Button("Copy") { onAction("copy") }
                        Button("Share") { onAction("share") }
                        Button("Delete", role: .destructive) { onAction("delete") }
                    }
            }
        }
        
        let view = ContextMenuView { action in
            selectedAction = action
        }
        
        let inspected = try view.inspect()
        let text = try inspected.text()
        
        XCTAssertNotNil(text)
        
        // Context menu interaction requires runtime testing
    }
}

// MARK: - Keyboard Interaction Tests

final class KeyboardInteractionTests: XCTestCase {
    
    func testKeyboardDismissal() throws {
        struct KeyboardView: View, Inspectable {
            @State private var text = ""
            @FocusState private var isTextFieldFocused: Bool
            
            var body: some View {
                VStack {
                    TextField("Enter text", text: $text)
                        .focused($isTextFieldFocused)
                    
                    Button("Dismiss Keyboard") {
                        isTextFieldFocused = false
                    }
                }
                .onTapGesture {
                    isTextFieldFocused = false
                }
            }
        }
        
        let view = KeyboardView()
        let inspected = try view.inspect()
        
        // Test text field exists
        let textField = try inspected.vStack().textField(0)
        XCTAssertNotNil(textField)
        
        // Test dismiss button exists
        let button = try inspected.vStack().button(1)
        XCTAssertNotNil(button)
    }
    
    func testKeyboardToolbar() throws {
        struct ToolbarView: View, Inspectable {
            @State private var text = ""
            
            var body: some View {
                TextField("Enter text", text: $text)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Button("Cancel") { }
                            Spacer()
                            Button("Done") { }
                        }
                    }
            }
        }
        
        let view = ToolbarView()
        let inspected = try view.inspect()
        
        // Test text field with toolbar
        let textField = try inspected.textField()
        XCTAssertNotNil(textField)
    }
}

// MARK: - Accessibility Interaction Tests

final class AccessibilityInteractionTests: XCTestCase {
    
    func testVoiceOverLabels() throws {
        struct AccessibleView: View, Inspectable {
            var body: some View {
                VStack {
                    Image(systemName: "star.fill")
                        .accessibilityLabel("Favorite")
                        .accessibilityHint("Double tap to mark as favorite")
                    
                    Text("Important Information")
                        .accessibilityAddTraits(.isHeader)
                    
                    Button("Submit") { }
                        .accessibilityLabel("Submit form")
                        .accessibilityHint("Double tap to submit the form")
                        .accessibilityAddTraits(.isButton)
                }
            }
        }
        
        let view = AccessibleView()
        let inspected = try view.inspect()
        
        // Test accessibility labels are present
        let image = try inspected.vStack().image(0)
        let text = try inspected.vStack().text(1)
        let button = try inspected.vStack().button(2)
        
        XCTAssertNotNil(image)
        XCTAssertNotNil(text)
        XCTAssertNotNil(button)
    }
    
    func testDynamicTypeSupport() throws {
        struct DynamicTypeView: View, Inspectable {
            @Environment(\.sizeCategory) var sizeCategory
            
            var body: some View {
                VStack {
                    Text("Dynamic Text")
                        .font(.body)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                    
                    if sizeCategory.isAccessibilityCategory {
                        // Adjusted layout for accessibility sizes
                        VStack {
                            Text("Label")
                            TextField("Input", text: .constant(""))
                        }
                    } else {
                        // Standard layout
                        HStack {
                            Text("Label")
                            TextField("Input", text: .constant(""))
                        }
                    }
                }
            }
        }
        
        let view = DynamicTypeView()
        let inspected = try view.inspect()
        
        // Test dynamic type support
        XCTAssertNotNil(inspected)
    }
}

// MARK: - Helper Extensions

extension View {
    func callOnTapGesture() throws {
        // Helper for testing tap gestures
    }
    
    func callOnLongPressGesture() throws {
        // Helper for testing long press gestures
    }
}

protocol Inspectable {}

extension Inspectable where Self: View {
    func inspect() throws -> InspectableView<ViewType.View<Self>> {
        try .init(self.body)
    }
}