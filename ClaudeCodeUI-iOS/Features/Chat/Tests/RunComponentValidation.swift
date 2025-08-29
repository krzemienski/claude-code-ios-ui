//
//  RunComponentValidation.swift
//  ClaudeCodeUI
//
//  Test runner for validating all 9 refactored chat components
//

import UIKit
import XCTest
import Combine
@testable import ClaudeCodeUI

// MARK: - Component Validation Test Runner

class RunComponentValidation: XCTestCase {
    
    // MARK: - Properties
    
    private var validator: ChatComponentValidator!
    private var reports: [ComponentValidationReport] = []
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        validator = ChatComponentValidator()
    }
    
    override func tearDown() {
        validator = nil
        reports = []
        super.tearDown()
    }
    
    // MARK: - Main Test
    
    func testAllComponentsValidation() {
        // Run comprehensive validation
        print("\n🚀 STARTING COMPREHENSIVE COMPONENT VALIDATION")
        print("=" * 60)
        print("Testing all 9 refactored components...")
        print("=" * 60)
        
        reports = validator.validateAllComponents()
        
        // Analyze results
        let passedComponents = reports.filter { $0.status == .passed }
        let warningComponents = reports.filter { $0.status == .warning }
        let failedComponents = reports.filter { $0.status == .failed }
        
        // Generate detailed report
        generateDetailedReport()
        
        // Assert all components pass
        XCTAssertEqual(passedComponents.count, 9, 
                      "Expected all 9 components to pass, but only \(passedComponents.count) passed")
        
        // Log any warnings
        if !warningComponents.isEmpty {
            print("\n⚠️ COMPONENTS WITH WARNINGS:")
            for component in warningComponents {
                print("  - \(component.componentName): \(component.issues.count) warnings")
            }
        }
        
        // Fail test if any components failed
        if !failedComponents.isEmpty {
            print("\n❌ FAILED COMPONENTS:")
            for component in failedComponents {
                print("  - \(component.componentName): \(component.issues.count) issues")
                for issue in component.issues {
                    print("    • \(issue.description)")
                }
            }
            XCTFail("Validation failed for \(failedComponents.count) components")
        } else {
            print("\n✅ ALL COMPONENTS VALIDATED SUCCESSFULLY!")
        }
    }
    
    // MARK: - Individual Component Tests
    
    func testChatViewModelComponent() {
        let report = validator.validateChatViewModel()
        assertComponentPasses(report, "ChatViewModel")
    }
    
    func testChatTableViewHandlerComponent() {
        let report = validator.validateChatTableViewHandler()
        assertComponentPasses(report, "ChatTableViewHandler")
    }
    
    func testChatInputHandlerComponent() {
        let report = validator.validateChatInputHandler()
        assertComponentPasses(report, "ChatInputHandler")
    }
    
    func testChatWebSocketCoordinatorComponent() {
        let report = validator.validateChatWebSocketCoordinator()
        assertComponentPasses(report, "ChatWebSocketCoordinator")
    }
    
    func testChatMessageProcessorComponent() {
        let report = validator.validateChatMessageProcessor()
        assertComponentPasses(report, "ChatMessageProcessor")
    }
    
    func testChatStateManagerComponent() {
        let report = validator.validateChatStateManager()
        assertComponentPasses(report, "ChatStateManager")
    }
    
    func testChatAttachmentHandlerComponent() {
        let report = validator.validateChatAttachmentHandler()
        assertComponentPasses(report, "ChatAttachmentHandler")
    }
    
    func testStreamingMessageHandlerComponent() {
        let report = validator.validateStreamingMessageHandler()
        assertComponentPasses(report, "StreamingMessageHandler")
    }
    
    func testCellImplementationsComponent() {
        let report = validator.validateCellImplementations()
        assertComponentPasses(report, "Cell Implementations")
    }
    
    // MARK: - Integration Tests
    
    func testComponentIntegration() {
        print("\n🔄 TESTING COMPONENT INTEGRATION")
        
        // Test ViewModel + TableViewHandler integration
        let viewModel = ChatViewModel()
        let tableView = UITableView()
        let tableHandler = ChatTableViewHandler(tableView: tableView, viewModel: viewModel)
        
        // Add test message
        let message = ChatMessage(
            id: "test",
            role: .user,
            content: "Integration test",
            timestamp: Date(),
            status: .delivered
        )
        viewModel.messages.append(message)
        
        // Verify table updates
        tableView.reloadData()
        let rows = tableView.numberOfRows(inSection: 0)
        XCTAssertEqual(rows, 1, "TableView should show 1 message")
        
        // Test InputHandler + ViewModel integration
        let inputBar = ChatInputBar()
        let inputHandler = ChatInputHandler(inputBar: inputBar, viewModel: viewModel)
        
        inputBar.textView.text = "Test input"
        inputHandler.handleSendButtonTapped()
        
        XCTAssertEqual(viewModel.messages.count, 2, "Should have 2 messages after sending")
        XCTAssertTrue(inputBar.textView.text.isEmpty, "Input should be cleared after sending")
        
        print("✅ Component integration tests passed")
    }
    
    func testStreamingIntegration() {
        print("\n🌊 TESTING STREAMING MESSAGE INTEGRATION")
        
        let viewModel = ChatViewModel()
        let tableView = UITableView()
        let streamingHandler = StreamingMessageHandler(
            viewModel: viewModel,
            tableView: tableView
        )
        
        // Start streaming
        let messageId = "stream-test"
        streamingHandler.startStreaming(messageId: messageId)
        
        // Add chunks
        let chunks = ["Hello", " ", "World", "!"]
        for chunk in chunks {
            streamingHandler.addChunk(chunk, to: messageId)
        }
        
        // Complete streaming
        streamingHandler.completeStreaming(messageId: messageId)
        
        // Verify result
        let content = streamingHandler.getStreamingContent(for: messageId)
        XCTAssertEqual(content, "Hello World!", "Streaming content should be complete")
        
        print("✅ Streaming integration test passed")
    }
    
    func testWebSocketIntegration() {
        print("\n🔌 TESTING WEBSOCKET INTEGRATION")
        
        let viewModel = ChatViewModel()
        let coordinator = ChatWebSocketCoordinator(viewModel: viewModel)
        
        // Set project path
        coordinator.projectPath = "/test/project"
        
        // Test connection state management
        coordinator.updateConnectionStatus(.connecting)
        XCTAssertEqual(viewModel.connectionStatus, .connecting)
        
        coordinator.updateConnectionStatus(.connected)
        XCTAssertEqual(viewModel.connectionStatus, .connected)
        
        print("✅ WebSocket integration test passed")
    }
    
    // MARK: - Performance Tests
    
    func testComponentPerformance() {
        print("\n⚡ TESTING COMPONENT PERFORMANCE")
        
        // Test large message list performance
        measure {
            let viewModel = ChatViewModel()
            let messages = (0..<1000).map { index in
                ChatMessage(
                    id: "\(index)",
                    role: index % 2 == 0 ? .user : .assistant,
                    content: "Message \(index)",
                    timestamp: Date(),
                    status: .delivered
                )
            }
            viewModel.messages = messages
        }
        
        print("✅ Performance tests completed")
    }
    
    // MARK: - Helper Methods
    
    private func assertComponentPasses(_ report: ComponentValidationReport, _ name: String) {
        if report.status == .failed {
            XCTFail("\(name) validation failed with \(report.issues.count) issues")
            for issue in report.issues {
                print("  ❌ \(issue.description) at \(issue.file):\(issue.line)")
            }
        } else if report.status == .warning {
            print("  ⚠️ \(name) has \(report.issues.count) warnings")
        } else {
            print("  ✅ \(name) validation passed")
        }
    }
    
    private func generateDetailedReport() {
        print("\n📊 DETAILED VALIDATION REPORT")
        print("=" * 60)
        
        for (index, report) in reports.enumerated() {
            let statusEmoji = report.status == .passed ? "✅" :
                             report.status == .warning ? "⚠️" : "❌"
            
            print("\n\(index + 1). \(statusEmoji) \(report.componentName)")
            print("   Status: \(report.status)")
            print("   Lines of Code: \(report.metrics.linesOfCode)")
            print("   Setup Time: \(String(format: "%.3f", report.metrics.setupTime))s")
            print("   Memory Footprint: \(report.metrics.memoryFootprint) bytes")
            print("   Dependencies: \(report.metrics.dependencies)")
            
            if !report.issues.isEmpty {
                print("   Issues:")
                for issue in report.issues {
                    let severityEmoji = issue.severity == .critical ? "🔴" :
                                       issue.severity == .warning ? "🟡" : "🔵"
                    print("     \(severityEmoji) \(issue.description)")
                    print("        File: \(issue.file):\(issue.line)")
                }
            }
        }
        
        // Summary statistics
        let totalLines = reports.reduce(0) { $0 + $1.metrics.linesOfCode }
        let totalMemory = reports.reduce(0) { $0 + $1.metrics.memoryFootprint }
        let avgSetupTime = reports.reduce(0.0) { $0 + $1.metrics.setupTime } / Double(reports.count)
        
        print("\n📈 SUMMARY STATISTICS")
        print("=" * 60)
        print("Total Components: \(reports.count)")
        print("Total Lines of Code: \(totalLines)")
        print("Total Memory Footprint: \(totalMemory) bytes")
        print("Average Setup Time: \(String(format: "%.3f", avgSetupTime))s")
        
        let passedCount = reports.filter { $0.status == .passed }.count
        let successRate = Double(passedCount) / Double(reports.count) * 100
        print("Success Rate: \(String(format: "%.1f", successRate))%")
    }
}

// MARK: - String Extension for Repeating

extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}

// MARK: - Test Execution Helper

class ComponentValidationExecutor {
    
    static func runValidation() {
        print("\n🎯 EXECUTING CHAT COMPONENT VALIDATION SUITE")
        print("Time: \(Date())")
        print("=" * 60)
        
        let testSuite = RunComponentValidation()
        testSuite.setUp()
        
        // Run all tests
        testSuite.testAllComponentsValidation()
        testSuite.testComponentIntegration()
        testSuite.testStreamingIntegration()
        testSuite.testWebSocketIntegration()
        testSuite.testComponentPerformance()
        
        testSuite.tearDown()
        
        print("\n🏁 VALIDATION SUITE COMPLETED")
        print("=" * 60)
    }
}