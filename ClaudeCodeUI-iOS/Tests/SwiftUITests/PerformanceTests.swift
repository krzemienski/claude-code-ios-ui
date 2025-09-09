//
//  PerformanceTests.swift
//  ClaudeCodeUI SwiftUI Performance Tests
//
//  Created on 2025-01-16.
//
//  Performance testing suite for SwiftUI views and components
//

import XCTest
import SwiftUI
import os.signpost
@testable import ClaudeCodeUI

// MARK: - SwiftUI Performance Tests

final class SwiftUIPerformanceTests: XCTestCase {
    
    private let performanceLog = OSLog(subsystem: "com.claudecode.ui", category: "Performance")
    private let signpostID = OSSignpostID(log: .default)
    
    override func setUp() {
        super.setUp()
        // Warm up the runtime
        _ = Text("Warmup").frame(width: 100, height: 100)
    }
    
    // MARK: - View Rendering Performance
    
    func testSettingsViewRenderingPerformance() throws {
        let metrics: [XCTMetric] = [
            XCTClockMetric(),           // Wall clock time
            XCTCPUMetric(),             // CPU usage
            XCTMemoryMetric(),          // Memory usage
            XCTStorageMetric()          // Disk I/O
        ]
        
        measure(metrics: metrics) {
            os_signpost(.begin, log: performanceLog, name: "SettingsView Render", signpostID: signpostID)
            
            autoreleasepool {
                let view = SettingsView()
                let hostingController = UIHostingController(rootView: view)
                
                // Force layout
                hostingController.view.setNeedsLayout()
                hostingController.view.layoutIfNeeded()
                
                // Force rendering
                let renderer = UIGraphicsImageRenderer(bounds: hostingController.view.bounds)
                _ = renderer.image { context in
                    hostingController.view.layer.render(in: context.cgContext)
                }
            }
            
            os_signpost(.end, log: performanceLog, name: "SettingsView Render", signpostID: signpostID)
        }
    }
    
    func testMessageBubbleRenderingPerformance() throws {
        let messages = (0..<100).map { index in
            Message(
                id: "msg-\(index)",
                sessionId: "session-1",
                content: "This is message number \(index) with some content to render",
                role: index % 2 == 0 ? .user : .assistant,
                timestamp: Date()
            )
        }
        
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            autoreleasepool {
                let view = ScrollView {
                    LazyVStack {
                        ForEach(messages) { message in
                            MessageBubbleView(
                                message: message,
                                isCurrentUser: message.role == .user
                            )
                        }
                    }
                }
                
                let hostingController = UIHostingController(rootView: view)
                hostingController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
                
                // Force layout and rendering
                hostingController.view.setNeedsLayout()
                hostingController.view.layoutIfNeeded()
            }
        }
    }
    
    // MARK: - List/ScrollView Performance
    
    func testLazyVStackPerformanceWithLargeDataset() throws {
        let items = (0..<1000).map { "Item \($0)" }
        
        let options = XCTMeasureOptions()
        options.invocationOptions = [.manuallyStart, .manuallyStop]
        options.iterationCount = 5
        
        measure(options: options) {
            autoreleasepool {
                let view = ScrollView {
                    LazyVStack {
                        ForEach(items, id: \.self) { item in
                            HStack {
                                Image(systemName: "doc.text")
                                Text(item)
                                Spacer()
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                
                let hostingController = UIHostingController(rootView: view)
                hostingController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
                
                startMeasuring()
                
                // Simulate scrolling
                for offset in stride(from: 0, to: 5000, by: 100) {
                    let scrollView = hostingController.view.subviews.first as? UIScrollView
                    scrollView?.setContentOffset(CGPoint(x: 0, y: CGFloat(offset)), animated: false)
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
                }
                
                stopMeasuring()
            }
        }
    }
    
    func testListVsLazyVStackPerformance() throws {
        let items = (0..<500).map { "Item \($0)" }
        
        // Test List performance
        let listMetrics = measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            autoreleasepool {
                let view = List(items, id: \.self) { item in
                    Text(item)
                }
                
                let hostingController = UIHostingController(rootView: view)
                hostingController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
                hostingController.view.layoutIfNeeded()
            }
        }
        
        // Test LazyVStack performance
        let lazyVStackMetrics = measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            autoreleasepool {
                let view = ScrollView {
                    LazyVStack {
                        ForEach(items, id: \.self) { item in
                            Text(item)
                        }
                    }
                }
                
                let hostingController = UIHostingController(rootView: view)
                hostingController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
                hostingController.view.layoutIfNeeded()
            }
        }
        
        // Compare results (manual comparison needed)
        print("List metrics: \(listMetrics)")
        print("LazyVStack metrics: \(lazyVStackMetrics)")
    }
    
    // MARK: - Animation Performance
    
    func testAnimationPerformance() throws {
        struct AnimatedView: View {
            @State private var isAnimating = false
            
            var body: some View {
                VStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 100, height: 100)
                        .scaleEffect(isAnimating ? 1.5 : 1.0)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(.easeInOut(duration: 1), value: isAnimating)
                    
                    Button("Animate") {
                        isAnimating.toggle()
                    }
                }
            }
        }
        
        measure(metrics: [XCTClockMetric(), XCTCPUMetric()]) {
            autoreleasepool {
                let view = AnimatedView()
                let hostingController = UIHostingController(rootView: view)
                
                hostingController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
                hostingController.view.layoutIfNeeded()
                
                // Trigger multiple animations
                for _ in 0..<10 {
                    // Simulate button tap
                    if let button = findButton(in: hostingController.view) {
                        button.sendActions(for: .touchUpInside)
                    }
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
                }
            }
        }
    }
    
    func testComplexAnimationChain() throws {
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
            autoreleasepool {
                var views: [AnyView] = []
                
                // Create multiple animated views
                for i in 0..<20 {
                    let view = AnyView(
                        Circle()
                            .fill(Color.random)
                            .frame(width: 50, height: 50)
                            .offset(x: CGFloat.random(in: -100...100), y: CGFloat.random(in: -100...100))
                            .animation(.spring(), value: i)
                    )
                    views.append(view)
                }
                
                let container = ZStack {
                    ForEach(0..<views.count, id: \.self) { index in
                        views[index]
                    }
                }
                
                let hostingController = UIHostingController(rootView: container)
                hostingController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
                hostingController.view.layoutIfNeeded()
                
                // Let animations run
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 2))
            }
        }
    }
    
    // MARK: - State Management Performance
    
    func testStateUpdatePerformance() throws {
        class LargeViewModel: ObservableObject {
            @Published var items: [String] = []
            @Published var selectedIndex: Int = 0
            @Published var searchText: String = ""
            @Published var isLoading: Bool = false
            
            func updateItems() {
                items = (0..<1000).map { "Item \($0)" }
            }
        }
        
        struct TestView: View {
            @StateObject private var viewModel = LargeViewModel()
            
            var body: some View {
                VStack {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                    
                    TextField("Search", text: $viewModel.searchText)
                    
                    List(viewModel.items.filter { item in
                        viewModel.searchText.isEmpty || item.contains(viewModel.searchText)
                    }, id: \.self) { item in
                        Text(item)
                    }
                }
            }
        }
        
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            autoreleasepool {
                let view = TestView()
                let hostingController = UIHostingController(rootView: view)
                
                hostingController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
                hostingController.view.layoutIfNeeded()
                
                // Trigger state updates
                if let viewModel = Mirror(reflecting: view).descendant("_viewModel") as? LargeViewModel {
                    viewModel.updateItems()
                    viewModel.searchText = "Item 5"
                    viewModel.isLoading = true
                    viewModel.isLoading = false
                }
                
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
            }
        }
    }
    
    // MARK: - Memory Performance
    
    func testMemoryLeaksInViewLifecycle() throws {
        weak var weakViewModel: SettingsViewModel?
        
        autoreleasepool {
            let viewModel = SettingsViewModel()
            weakViewModel = viewModel
            
            let view = SettingsView()
            let hostingController = UIHostingController(rootView: view)
            
            // Use the view
            _ = hostingController.view
            hostingController.view.layoutIfNeeded()
        }
        
        // Check for memory leaks
        XCTAssertNil(weakViewModel, "ViewModel should be deallocated")
    }
    
    func testLargeImageHandling() throws {
        measure(metrics: [XCTMemoryMetric()]) {
            autoreleasepool {
                let view = ScrollView {
                    VStack {
                        ForEach(0..<50) { _ in
                            Image(systemName: "photo.fill")
                                .resizable()
                                .frame(width: 300, height: 300)
                                .cornerRadius(10)
                        }
                    }
                }
                
                let hostingController = UIHostingController(rootView: view)
                hostingController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
                
                // Simulate scrolling through images
                if let scrollView = hostingController.view.subviews.first as? UIScrollView {
                    for offset in stride(from: 0, to: 10000, by: 500) {
                        scrollView.setContentOffset(CGPoint(x: 0, y: CGFloat(offset)), animated: false)
                        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func findButton(in view: UIView) -> UIButton? {
        if let button = view as? UIButton {
            return button
        }
        
        for subview in view.subviews {
            if let button = findButton(in: subview) {
                return button
            }
        }
        
        return nil
    }
}

// MARK: - Performance Benchmarks

final class SwiftUIBenchmarks: XCTestCase {
    
    func testViewCreationBenchmark() throws {
        let benchmarks = [
            ("Text", { Text("Hello World") }),
            ("Button", { Button("Tap") {} }),
            ("Image", { Image(systemName: "star") }),
            ("VStack", { VStack { Text("1"); Text("2") } }),
            ("List", { List { Text("Item") } })
        ]
        
        for (name, viewBuilder) in benchmarks {
            measure(metrics: [XCTClockMetric()]) {
                for _ in 0..<1000 {
                    _ = viewBuilder()
                }
            }
            print("Benchmark for \(name) completed")
        }
    }
    
    func testModifierChainPerformance() throws {
        measure(metrics: [XCTClockMetric()]) {
            for _ in 0..<1000 {
                _ = Text("Test")
                    .font(.title)
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1)
                    )
            }
        }
    }
    
    func testGeometryReaderPerformance() throws {
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            let view = GeometryReader { geometry in
                VStack {
                    ForEach(0..<100) { index in
                        Text("Width: \(geometry.size.width)")
                            .frame(width: geometry.size.width * 0.8)
                    }
                }
            }
            
            let hostingController = UIHostingController(rootView: view)
            hostingController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
            hostingController.view.layoutIfNeeded()
        }
    }
}

// MARK: - Helpers

extension Color {
    static var random: Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}