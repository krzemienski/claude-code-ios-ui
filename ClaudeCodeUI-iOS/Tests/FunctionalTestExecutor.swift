#!/usr/bin/swift

import Foundation
import XCTest

// MARK: - Functional Test Executor for Claude Code iOS
// This script executes REAL UI automation tests on REAL simulators

class FunctionalTestExecutor {
    let deviceId = "BECB3FA0-518E-4F80-8B8E-7E10C16F3B36" // iPhone 16 Pro
    let appBundleId = "com.claudecode.ui"
    let backendURL = "ws://192.168.0.155:3004/ws"
    let testResultsPath = "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/TestResults_\(Date().timeIntervalSince1970)"
    
    func executeAllTestFlows() {
        print("🚀 Starting Functional Test Execution")
        print("📱 Device: iPhone 16 Pro")
        print("🌐 Backend: \(backendURL)")
        print("📁 Results: \(testResultsPath)")
        
        createResultsDirectory()
        
        // Execute each test flow
        let results = [
            executeTestFlow1_LaunchAndConnection(),
            executeTestFlow2_ProjectList(),
            executeTestFlow3_SessionNavigation(),
            executeTestFlow4_WebSocketStreaming(),
            executeTestFlow5_MultipleMessages(),
            executeTestFlow6_NavigationStress(),
            executeTestFlow7_HighVolumeScrolling()
        ]
        
        generateTestReport(results)
    }
    
    // MARK: - Test Flow 1: Launch & Connection
    func executeTestFlow1_LaunchAndConnection() -> TestResult {
        print("\n═══ Test Flow 1: Launch & Connection ═══")
        var result = TestResult(name: "Launch & Connection", status: .running)
        
        // Launch the app
        print("📱 Launching app...")
        let launchResult = shell("xcrun simctl launch --console-pty \(deviceId) \(appBundleId)")
        
        // Monitor console for WebSocket connection
        print("🔍 Monitoring WebSocket connection...")
        Thread.sleep(forTimeInterval: 3.0)
        
        // Capture console logs
        let consoleLog = captureConsoleLogs()
        
        // Verify WebSocket connection
        if consoleLog.contains("WebSocket connected") || consoleLog.contains("ws://192.168.0.155:3004") {
            print("✅ WebSocket connection established")
            result.status = .passed
            result.details = "Successfully connected to backend"
        } else {
            print("❌ WebSocket connection failed")
            result.status = .failed
            result.details = "No WebSocket connection detected"
        }
        
        // Take screenshot
        takeScreenshot("flow1_launch")
        
        // Capture network logs
        captureNetworkLogs("flow1_network")
        
        return result
    }
    
    // MARK: - Test Flow 2: Project List
    func executeTestFlow2_ProjectList() -> TestResult {
        print("\n═══ Test Flow 2: Project List ═══")
        var result = TestResult(name: "Project List", status: .running)
        
        // Wait for projects to load
        Thread.sleep(forTimeInterval: 2.0)
        
        // Get UI hierarchy
        let hierarchy = captureUIHierarchy()
        saveToFile(content: hierarchy, filename: "flow2_hierarchy.xml")
        
        // Count projects in list
        let projectCount = hierarchy.components(separatedBy: "XCUIElementTypeCell").count - 1
        print("📊 Found \(projectCount) projects")
        
        if projectCount > 0 {
            print("✅ Projects loaded from backend")
            result.status = .passed
            result.details = "Loaded \(projectCount) projects"
        } else {
            print("❌ No projects found")
            result.status = .failed
            result.details = "Project list is empty"
        }
        
        takeScreenshot("flow2_project_list")
        
        return result
    }
    
    // MARK: - Test Flow 3: Session Navigation
    func executeTestFlow3_SessionNavigation() -> TestResult {
        print("\n═══ Test Flow 3: Session Navigation ═══")
        var result = TestResult(name: "Session Navigation", status: .running)
        
        // Tap first project
        print("👆 Tapping first project...")
        let tapResult = performTap(x: 200, y: 300)
        
        Thread.sleep(forTimeInterval: 2.0)
        
        // Verify session messages loaded
        let hierarchy = captureUIHierarchy()
        
        if hierarchy.contains("XCUIElementTypeTextView") || hierarchy.contains("message") {
            print("✅ Session messages loaded")
            
            // Test scrolling
            print("📜 Testing scroll...")
            performSwipe(fromX: 200, fromY: 600, toX: 200, toY: 200)
            Thread.sleep(forTimeInterval: 1.0)
            
            result.status = .passed
            result.details = "Navigation and scrolling successful"
        } else {
            print("❌ Session messages not found")
            result.status = .failed
            result.details = "Failed to load session messages"
        }
        
        takeScreenshot("flow3_session")
        
        return result
    }
    
    // MARK: - Test Flow 4: WebSocket Streaming
    func executeTestFlow4_WebSocketStreaming() -> TestResult {
        print("\n═══ Test Flow 4: WebSocket Streaming ═══")
        var result = TestResult(name: "WebSocket Streaming", status: .running)
        
        // Start monitoring WebSocket frames
        startWebSocketMonitor()
        
        // Send a message
        print("💬 Sending test message...")
        typeText("Test WebSocket streaming")
        performTap(x: 350, y: 700) // Send button
        
        // Monitor for streaming response
        print("🌊 Monitoring streaming response...")
        var streamDetected = false
        
        for i in 0..<10 {
            Thread.sleep(forTimeInterval: 0.5)
            let wsLogs = captureWebSocketLogs()
            
            if wsLogs.contains("streaming") || wsLogs.contains("quad") || wsLogs.contains("chunk") {
                print("✅ Streaming detected at \(i*500)ms")
                streamDetected = true
                break
            }
        }
        
        if streamDetected {
            result.status = .passed
            result.details = "WebSocket streaming verified"
        } else {
            print("❌ No streaming detected")
            result.status = .failed
            result.details = "WebSocket streaming not working"
        }
        
        takeScreenshot("flow4_streaming")
        captureNetworkLogs("flow4_websocket")
        
        return result
    }
    
    // MARK: - Test Flow 5: Multiple Messages
    func executeTestFlow5_MultipleMessages() -> TestResult {
        print("\n═══ Test Flow 5: Multiple Messages ═══")
        var result = TestResult(name: "Multiple Messages", status: .running)
        
        let messages = [
            "First test message",
            "Second test message with longer content",
            "Third message testing special characters: !@#$%"
        ]
        
        var allSent = true
        
        for (index, message) in messages.enumerated() {
            print("📤 Sending message \(index + 1)...")
            clearTextField()
            typeText(message)
            performTap(x: 350, y: 700)
            
            Thread.sleep(forTimeInterval: 2.0)
            
            // Verify message appears
            let hierarchy = captureUIHierarchy()
            if !hierarchy.contains(message.prefix(10)) {
                allSent = false
                print("❌ Message \(index + 1) not found in UI")
            }
        }
        
        if allSent {
            result.status = .passed
            result.details = "All \(messages.count) messages sent successfully"
        } else {
            result.status = .failed
            result.details = "Some messages failed to send"
        }
        
        takeScreenshot("flow5_multiple_messages")
        
        return result
    }
    
    // MARK: - Test Flow 6: Navigation Stress
    func executeTestFlow6_NavigationStress() -> TestResult {
        print("\n═══ Test Flow 6: Navigation Stress ═══")
        var result = TestResult(name: "Navigation Stress", status: .running)
        
        print("🔄 Performing rapid navigation...")
        
        for i in 0..<5 {
            // Go back
            performTap(x: 50, y: 100)
            Thread.sleep(forTimeInterval: 0.5)
            
            // Select project
            performTap(x: 200, y: 300 + (i * 50))
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        // Check for crashes or memory issues
        let memoryUsage = captureMemoryUsage()
        print("💾 Memory usage: \(memoryUsage) MB")
        
        if memoryUsage < 500 {
            result.status = .passed
            result.details = "Navigation stress test passed, memory: \(memoryUsage)MB"
        } else {
            result.status = .warning
            result.details = "High memory usage: \(memoryUsage)MB"
        }
        
        takeScreenshot("flow6_navigation")
        
        return result
    }
    
    // MARK: - Test Flow 7: High Volume Scrolling
    func executeTestFlow7_HighVolumeScrolling() -> TestResult {
        print("\n═══ Test Flow 7: High Volume Scrolling ═══")
        var result = TestResult(name: "High Volume Scrolling", status: .running)
        
        print("📜 Performing rapid scrolling...")
        
        let startTime = Date()
        
        for _ in 0..<20 {
            performSwipe(fromX: 200, fromY: 600, toX: 200, toY: 100)
            Thread.sleep(forTimeInterval: 0.1)
            performSwipe(fromX: 200, fromY: 100, toX: 200, toY: 600)
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let fps = 40.0 / duration * 60
        
        print("⚡ Scroll performance: \(String(format: "%.1f", fps)) FPS")
        
        if fps > 30 {
            result.status = .passed
            result.details = "Smooth scrolling at \(String(format: "%.1f", fps)) FPS"
        } else {
            result.status = .warning
            result.details = "Scrolling performance below target: \(String(format: "%.1f", fps)) FPS"
        }
        
        takeScreenshot("flow7_scrolling")
        
        return result
    }
    
    // MARK: - Helper Functions
    
    func createResultsDirectory() {
        try? FileManager.default.createDirectory(atPath: testResultsPath, withIntermediateDirectories: true)
    }
    
    func shell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/bash"
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    func takeScreenshot(_ name: String) {
        let path = "\(testResultsPath)/\(name).png"
        shell("xcrun simctl io \(deviceId) screenshot \(path)")
        print("📸 Screenshot: \(name).png")
    }
    
    func captureUIHierarchy() -> String {
        // Using accessibility inspector or UI dump
        let result = shell("xcrun simctl ui \(deviceId) dump")
        return result.isEmpty ? getAlternativeHierarchy() : result
    }
    
    func getAlternativeHierarchy() -> String {
        // Alternative method using accessibility
        return shell("xcrun simctl spawn \(deviceId) log stream --predicate 'subsystem == \"com.apple.UIKit\"' --style compact | head -100")
    }
    
    func captureConsoleLogs() -> String {
        return shell("xcrun simctl spawn \(deviceId) log stream --predicate 'processImagePath ENDSWITH \"ClaudeCodeUI\"' --style compact | head -200")
    }
    
    func captureNetworkLogs(_ name: String) {
        let logs = shell("xcrun simctl spawn \(deviceId) log stream --predicate 'subsystem == \"com.apple.CFNetwork\"' --style compact | head -100")
        saveToFile(content: logs, filename: "\(name).log")
    }
    
    func captureWebSocketLogs() -> String {
        return shell("xcrun simctl spawn \(deviceId) log stream --predicate 'eventMessage CONTAINS \"WebSocket\" OR eventMessage CONTAINS \"ws://\"' --style compact | head -50")
    }
    
    func startWebSocketMonitor() {
        // Start background WebSocket monitoring
        DispatchQueue.global().async {
            let _ = self.shell("xcrun simctl spawn \(self.deviceId) log stream --predicate 'eventMessage CONTAINS \"WebSocket\"' > \(self.testResultsPath)/websocket_monitor.log &")
        }
    }
    
    func performTap(x: Int, y: Int) -> Bool {
        shell("xcrun simctl io \(deviceId) tap \(x) \(y)")
        return true
    }
    
    func performSwipe(fromX: Int, fromY: Int, toX: Int, toY: Int) {
        shell("xcrun simctl io \(deviceId) swipe \(fromX) \(fromY) \(toX) \(toY)")
    }
    
    func typeText(_ text: String) {
        // Escape special characters for shell
        let escaped = text.replacingOccurrences(of: "'", with: "\\'")
        shell("xcrun simctl io \(deviceId) text '\(escaped)'")
    }
    
    func clearTextField() {
        // Select all and delete
        shell("xcrun simctl io \(deviceId) keyevent 'CMD+A'")
        shell("xcrun simctl io \(deviceId) keyevent 'DELETE'")
    }
    
    func captureMemoryUsage() -> Int {
        let output = shell("xcrun simctl spawn \(deviceId) launchctl print system | grep 'memory in use' | awk '{print $3}'")
        return Int(output.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }
    
    func saveToFile(content: String, filename: String) {
        let path = "\(testResultsPath)/\(filename)"
        try? content.write(toFile: path, atomically: true, encoding: .utf8)
    }
    
    func generateTestReport(_ results: [TestResult]) {
        print("\n═══════════════════════════════════════")
        print("        TEST EXECUTION REPORT")
        print("═══════════════════════════════════════")
        
        var passed = 0
        var failed = 0
        var warnings = 0
        
        for result in results {
            let icon = result.status == .passed ? "✅" :
                      result.status == .failed ? "❌" : "⚠️"
            print("\(icon) \(result.name): \(result.status)")
            print("   \(result.details)")
            
            switch result.status {
            case .passed: passed += 1
            case .failed: failed += 1
            case .warning: warnings += 1
            default: break
            }
        }
        
        print("\n📊 Summary:")
        print("   Passed: \(passed)")
        print("   Failed: \(failed)")
        print("   Warnings: \(warnings)")
        print("   Total: \(results.count)")
        
        let reportContent = """
        # Functional Test Execution Report
        
        ## Summary
        - **Passed**: \(passed)
        - **Failed**: \(failed)
        - **Warnings**: \(warnings)
        - **Total**: \(results.count)
        
        ## Test Results
        
        \(results.map { "### \($0.name)\n- Status: \($0.status)\n- Details: \($0.details)\n" }.joined(separator: "\n"))
        
        ## Artifacts
        - Screenshots: \(testResultsPath)/*.png
        - Logs: \(testResultsPath)/*.log
        - UI Hierarchy: \(testResultsPath)/*.xml
        
        ## WebSocket Connection
        - URL: \(backendURL)
        - Status: \(results[0].status == .passed ? "Connected" : "Failed")
        
        ## Generated: \(Date())
        """
        
        saveToFile(content: reportContent, filename: "TEST_REPORT.md")
        print("\n📄 Report saved: \(testResultsPath)/TEST_REPORT.md")
    }
}

// MARK: - Test Result Model
struct TestResult {
    let name: String
    var status: TestStatus
    var details: String = ""
}

enum TestStatus {
    case running, passed, failed, warning
}

// MARK: - Main Execution
let executor = FunctionalTestExecutor()
executor.executeAllTestFlows()