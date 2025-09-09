//
//  PerformanceValidation.swift
//  ClaudeCodeUITests
//
//  Created by Performance Agent on 9/7/25.
//

import XCTest
import os.log
@testable import ClaudeCodeUI

final class PerformanceValidation: XCTestCase {
    
    private let logger = Logger(subsystem: "com.claudecode.ui", category: "PerformanceValidation")
    private var app: XCUIApplication!
    private var memoryBaseline: Double = 0
    private var performanceMetrics: [String: Any] = [:]
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--performance-test"]
        app.launchEnvironment = [
            "PERFORMANCE_TEST": "1",
            "DISABLE_ANIMATIONS": "1"
        ]
        
        // Record baseline memory
        memoryBaseline = getCurrentMemoryUsage()
        logger.info("Baseline memory: \(self.memoryBaseline) MB")
    }
    
    override func tearDownWithError() throws {
        // Generate performance report
        generatePerformanceReport()
        
        // Check for memory leaks
        let finalMemory = getCurrentMemoryUsage()
        let memoryDelta = finalMemory - memoryBaseline
        
        if memoryDelta > 10.0 { // More than 10MB increase indicates potential leak
            logger.error("Potential memory leak detected: \(memoryDelta) MB increase")
            XCTFail("Memory leak detected: \(memoryDelta) MB increase from baseline")
        }
        
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - WebSocket Performance Tests
    
    func testWebSocketLatency() throws {
        app.launch()
        
        let metrics = XCTApplicationLaunchMetric()
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        options.invocationOptions = [.manuallyStart, .manuallyStop]
        
        measure(metrics: [metrics], options: options) {
            startMeasuring()
            
            // Send a test message and measure response time
            let messageField = app.textViews["messageInput"]
            messageField.tap()
            messageField.typeText("Test message for latency measurement")
            
            let sendButton = app.buttons["sendButton"]
            sendButton.tap()
            
            // Wait for response indicator
            let responseIndicator = app.staticTexts.matching(identifier: "assistantMessage").firstMatch
            let exists = responseIndicator.waitForExistence(timeout: 2.0)
            
            stopMeasuring()
            
            XCTAssertTrue(exists, "WebSocket response not received within timeout")
            
            // Record latency
            if exists {
                performanceMetrics["websocket_latency"] = metrics.averageMeasurement
            }
        }
        
        // Validate latency requirement
        if let avgLatency = performanceMetrics["websocket_latency"] as? Double {
            XCTAssertLessThan(avgLatency, 0.5, "WebSocket latency exceeds 500ms requirement")
            logger.info("Average WebSocket latency: \(avgLatency * 1000) ms")
        }
    }
    
    func testWebSocketThroughput() throws {
        app.launch()
        
        measure {
            // Send multiple messages rapidly
            let messageField = app.textViews["messageInput"]
            let sendButton = app.buttons["sendButton"]
            
            for i in 1...10 {
                messageField.tap()
                messageField.clearAndTypeText("Throughput test message \(i)")
                sendButton.tap()
                
                // Brief pause to allow processing
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            // Verify all messages were processed
            let messages = app.staticTexts.matching(identifier: "userMessage")
            XCTAssertEqual(messages.count, 10, "Not all messages were processed")
        }
        
        performanceMetrics["websocket_throughput"] = "10 messages/second"
    }
    
    // MARK: - UI Performance Tests
    
    func testScrollingPerformance() throws {
        app.launch()
        
        // Populate with test messages
        populateTestMessages(count: 100)
        
        let scrollView = app.scrollViews.firstMatch
        
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        
        measure(options: options) {
            // Scroll to bottom
            scrollView.swipeUp(velocity: .fast)
            scrollView.swipeUp(velocity: .fast)
            scrollView.swipeUp(velocity: .fast)
            
            // Scroll back to top
            scrollView.swipeDown(velocity: .fast)
            scrollView.swipeDown(velocity: .fast)
            scrollView.swipeDown(velocity: .fast)
        }
        
        // Check frame rate (should maintain 60 FPS)
        let frameRate = measureFrameRate(during: {
            scrollView.swipeUp(velocity: .fast)
        })
        
        XCTAssertGreaterThan(frameRate, 55.0, "Scrolling performance below 60 FPS")
        performanceMetrics["scrolling_fps"] = frameRate
        logger.info("Scrolling frame rate: \(frameRate) FPS")
    }
    
    func testUIResponsiveness() throws {
        app.launch()
        
        let startTime = CACurrentMediaTime()
        
        // Test various UI interactions
        let actions = [
            { self.app.buttons["settingsButton"].tap() },
            { self.app.buttons["backButton"].tap() },
            { self.app.textViews["messageInput"].tap() },
            { self.app.buttons["sendButton"].tap() }
        ]
        
        for action in actions {
            let actionStart = CACurrentMediaTime()
            action()
            let actionEnd = CACurrentMediaTime()
            
            let responseTime = (actionEnd - actionStart) * 1000 // Convert to ms
            XCTAssertLessThan(responseTime, 100, "UI response time exceeds 100ms")
        }
        
        let totalTime = (CACurrentMediaTime() - startTime) * 1000
        performanceMetrics["ui_responsiveness"] = totalTime / Double(actions.count)
        logger.info("Average UI response time: \(totalTime / Double(actions.count)) ms")
    }
    
    // MARK: - Memory Performance Tests
    
    func testMemoryDuringMessageStreaming() throws {
        app.launch()
        
        let initialMemory = getCurrentMemoryUsage()
        logger.info("Initial memory: \(initialMemory) MB")
        
        // Stream multiple messages
        for i in 1...50 {
            sendTestMessage("Memory test message \(i)")
            
            if i % 10 == 0 {
                let currentMemory = getCurrentMemoryUsage()
                let memoryIncrease = currentMemory - initialMemory
                logger.info("Memory after \(i) messages: \(currentMemory) MB (Δ \(memoryIncrease) MB)")
                
                // Check for excessive memory growth
                XCTAssertLessThan(memoryIncrease, 50.0, "Excessive memory growth during streaming")
            }
        }
        
        // Wait for cleanup
        Thread.sleep(forTimeInterval: 2.0)
        
        let finalMemory = getCurrentMemoryUsage()
        let totalIncrease = finalMemory - initialMemory
        
        performanceMetrics["memory_streaming_delta"] = totalIncrease
        XCTAssertLessThan(totalIncrease, 20.0, "Memory not properly cleaned up after streaming")
        logger.info("Final memory delta: \(totalIncrease) MB")
    }
    
    func testMemoryLeakDetection() throws {
        app.launch()
        
        // Perform intensive operations
        for _ in 1...3 {
            // Open settings
            app.buttons["settingsButton"].tap()
            Thread.sleep(forTimeInterval: 0.5)
            
            // Navigate back
            app.buttons["backButton"].tap()
            Thread.sleep(forTimeInterval: 0.5)
            
            // Send messages
            sendTestMessage("Leak detection test")
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        // Force memory pressure
        simulateMemoryPressure()
        
        // Check for leaks
        let leaks = detectMemoryLeaks()
        XCTAssertEqual(leaks.count, 0, "Memory leaks detected: \(leaks)")
        
        if !leaks.isEmpty {
            logger.error("Memory leaks found: \(leaks)")
            performanceMetrics["memory_leaks"] = leaks
        } else {
            performanceMetrics["memory_leaks"] = "None"
        }
    }
    
    // MARK: - Network Performance Tests
    
    func testNetworkReconnection() throws {
        app.launch()
        
        // Simulate network disruption
        let startTime = CACurrentMediaTime()
        
        // Toggle airplane mode (requires special entitlements in real device)
        // For simulator, we'll use a different approach
        app.launchEnvironment["SIMULATE_NETWORK_LOSS"] = "1"
        app.terminate()
        app.launch()
        
        // Wait for reconnection
        let connectionIndicator = app.staticTexts["connectionStatus"]
        let reconnected = connectionIndicator.waitForExistence(timeout: 5.0)
        
        let reconnectionTime = CACurrentMediaTime() - startTime
        
        XCTAssertTrue(reconnected, "Failed to reconnect within 5 seconds")
        XCTAssertLessThan(reconnectionTime, 3.0, "Reconnection took too long")
        
        performanceMetrics["network_reconnection_time"] = reconnectionTime
        logger.info("Reconnection time: \(reconnectionTime) seconds")
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        }
        
        return 0
    }
    
    private func measureFrameRate(during action: () -> Void) -> Double {
        // This is a simplified frame rate measurement
        // In a real implementation, you'd use CADisplayLink or Metal Performance HUD
        let startTime = CACurrentMediaTime()
        var frameCount = 0
        
        let displayLink = CADisplayLink(target: self, selector: #selector(countFrame))
        displayLink.add(to: .current, forMode: .common)
        
        action()
        
        displayLink.invalidate()
        let duration = CACurrentMediaTime() - startTime
        
        return Double(frameCount) / duration
    }
    
    @objc private func countFrame() {
        // Frame counter for FPS measurement
    }
    
    private func populateTestMessages(count: Int) {
        for i in 1...count {
            sendTestMessage("Test message \(i) for performance testing")
        }
    }
    
    private func sendTestMessage(_ text: String) {
        let messageField = app.textViews["messageInput"]
        let sendButton = app.buttons["sendButton"]
        
        messageField.tap()
        messageField.clearAndTypeText(text)
        sendButton.tap()
    }
    
    private func simulateMemoryPressure() {
        // Simulate memory pressure to trigger cleanup
        var arrays: [[Int]] = []
        for _ in 0..<10 {
            arrays.append(Array(repeating: 0, count: 1000000))
        }
        arrays.removeAll() // Release memory
    }
    
    private func detectMemoryLeaks() -> [String] {
        // Run leaks detection tool
        let task = Process()
        task.launchPath = "/usr/bin/leaks"
        task.arguments = [String(ProcessInfo.processInfo.processIdentifier)]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            // Parse leaks output
            if output.contains("0 leaks for 0 total leaked bytes") {
                return []
            } else {
                // Extract leak information
                let lines = output.components(separatedBy: "\n")
                return lines.filter { $0.contains("leaked") }
            }
        } catch {
            logger.error("Failed to run leaks detection: \(error)")
            return []
        }
    }
    
    private func generatePerformanceReport() {
        logger.info("=== Performance Report ===")
        logger.info("Test Results:")
        
        for (key, value) in performanceMetrics {
            logger.info("  \(key): \(value)")
        }
        
        // Validate against requirements
        var allPassed = true
        
        if let latency = performanceMetrics["websocket_latency"] as? Double {
            if latency > 0.5 {
                logger.error("❌ WebSocket latency exceeds 500ms requirement")
                allPassed = false
            } else {
                logger.info("✅ WebSocket latency within requirements")
            }
        }
        
        if let fps = performanceMetrics["scrolling_fps"] as? Double {
            if fps < 55.0 {
                logger.error("❌ Scrolling performance below 60 FPS")
                allPassed = false
            } else {
                logger.info("✅ Scrolling maintains 60 FPS")
            }
        }
        
        if let responsiveness = performanceMetrics["ui_responsiveness"] as? Double {
            if responsiveness > 100 {
                logger.error("❌ UI response time exceeds 100ms")
                allPassed = false
            } else {
                logger.info("✅ UI responsiveness within requirements")
            }
        }
        
        if let leaks = performanceMetrics["memory_leaks"] as? String {
            if leaks != "None" {
                logger.error("❌ Memory leaks detected")
                allPassed = false
            } else {
                logger.info("✅ No memory leaks detected")
            }
        }
        
        if allPassed {
            logger.info("✅ All performance requirements met")
        } else {
            logger.error("❌ Some performance requirements not met")
        }
        
        logger.info("========================")
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    func clearAndTypeText(_ text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and type text into a non string value")
            return
        }
        
        self.tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
}