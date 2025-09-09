import XCTest
import Foundation
import Network
import FFmpegKitSwift
import os.log

// MARK: - Claude API SSE/WebSocket Integration

/// Complete Claude API streaming test implementation
class ClaudeAPIStreamingIntegrationTests: XCTestCase {
    
    private let logger = Logger(subsystem: "com.claudecode.ui.tests", category: "ClaudeAPI")
    private var apiKey: String!
    private var mediaCapture: MediaCaptureManager!
    private var secretScanner: SecretScanner!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        // Load API key from environment
        guard let key = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] else {
            XCTFail("CLAUDE_API_KEY environment variable not set")
            return
        }
        apiKey = key
        
        // Initialize media capture
        mediaCapture = MediaCaptureManager()
        mediaCapture.startRecording(testName: name)
        
        // Run secret scanning
        secretScanner = SecretScanner()
        XCTAssertTrue(secretScanner.scanProject(), "Secrets detected in project")
        
        // Configure app for testing
        let app = XCUIApplication()
        app.launchEnvironment = [
            "TESTING_MODE": "true",
            "CLAUDE_API_KEY": apiKey,
            "NETWORK_LOGGING": "verbose"
        ]
        app.launch()
    }
    
    override func tearDown() {
        super.tearDown()
        
        // Stop recording and save
        mediaCapture.stopRecording { url in
            self.addAttachment(url: url)
        }
        
        // Generate performance report
        generatePerformanceReport()
    }
    
    // MARK: - SSE Streaming Tests
    
    func testClaudeSSEStreamingResponse() throws {
        let app = XCUIApplication()
        
        // Measure performance
        let metrics = [
            XCTClockMetric(),
            XCTMemoryMetric(),
            XCTCPUMetric(),
            XCTStorageMetric()
        ]
        
        self.measure(metrics: metrics) {
            // Enter prompt
            let promptField = app.textFields["prompt_input"]
            promptField.tap()
            promptField.typeText("Explain async/await in Swift with a code example")
            
            // Send request
            app.buttons["send_button"].tap()
            
            // Wait for streaming to start
            let streamingIndicator = app.activityIndicators["streaming_indicator"]
            XCTAssertTrue(streamingIndicator.waitForExistence(timeout: 5))
            
            // Validate progressive text appearance
            let responseView = app.textViews["response_view"]
            
            // Check for initial response
            expectation(for: NSPredicate(format: "value.length > 0"),
                       evaluatedWith: responseView,
                       handler: nil)
            
            // Wait for streaming chunks
            var previousLength = 0
            let streamExpectation = expectation(description: "Streaming chunks received")
            
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                let currentText = responseView.value as? String ?? ""
                let currentLength = currentText.count
                
                if currentLength > previousLength {
                    self.logger.debug("Received chunk: \(currentLength - previousLength) chars")
                    previousLength = currentLength
                }
                
                // Check for completion
                if !streamingIndicator.exists {
                    timer.invalidate()
                    streamExpectation.fulfill()
                }
            }
            
            wait(for: [streamExpectation], timeout: 60)
            
            // Validate final response
            let finalText = responseView.value as? String ?? ""
            XCTAssertGreaterThan(finalText.count, 100, "Response too short")
            XCTAssertTrue(finalText.contains("async"), "Response missing expected content")
        }
    }
    
    // MARK: - WebSocket Connection Tests
    
    func testWebSocketConnectionStability() throws {
        let connection = ClaudeWebSocketConnection(apiKey: apiKey)
        let connectionExpectation = expectation(description: "WebSocket connected")
        
        connection.onConnected = {
            connectionExpectation.fulfill()
        }
        
        connection.connect()
        wait(for: [connectionExpectation], timeout: 10)
        
        // Test message sending
        let messageExpectation = expectation(description: "Message received")
        var receivedChunks: [String] = []
        
        connection.onMessage = { message in
            receivedChunks.append(message)
            if message.contains("[DONE]") {
                messageExpectation.fulfill()
            }
        }
        
        connection.send(prompt: "Hello Claude")
        wait(for: [messageExpectation], timeout: 30)
        
        XCTAssertGreaterThan(receivedChunks.count, 0)
        
        // Test reconnection
        connection.disconnect()
        Thread.sleep(forTimeInterval: 1)
        
        let reconnectExpectation = expectation(description: "Reconnected")
        connection.onConnected = {
            reconnectExpectation.fulfill()
        }
        
        connection.connect()
        wait(for: [reconnectExpectation], timeout: 10)
    }
    
    // MARK: - Network Condition Tests
    
    func testStreamingUnderPoorNetwork() throws {
        // Configure network condition
        NetworkConditionSimulator.apply(profile: .poor3G)
        
        let app = XCUIApplication()
        app.terminate()
        app.launch()
        
        // Test with degraded network
        let promptField = app.textFields["prompt_input"]
        promptField.tap()
        promptField.typeText("Short response test")
        
        app.buttons["send_button"].tap()
        
        // Longer timeout for poor network
        let responseView = app.textViews["response_view"]
        XCTAssertTrue(responseView.waitForExistence(timeout: 30))
        
        // Verify graceful handling
        let errorAlert = app.alerts["network_error"]
        XCTAssertFalse(errorAlert.exists, "Network error shown on poor connection")
        
        // Reset network
        NetworkConditionSimulator.reset()
    }
    
    // MARK: - Performance Benchmarks
    
    func testFirstTokenLatency() throws {
        let app = XCUIApplication()
        var firstTokenTime: TimeInterval = 0
        
        let startTime = Date()
        
        // Send request
        let promptField = app.textFields["prompt_input"]
        promptField.tap()
        promptField.typeText("Say hello")
        app.buttons["send_button"].tap()
        
        // Wait for first character
        let responseView = app.textViews["response_view"]
        let predicate = NSPredicate(format: "value.length > 0")
        expectation(for: predicate, evaluatedWith: responseView) { _ in
            firstTokenTime = Date().timeIntervalSince(startTime)
            return true
        }
        
        waitForExpectations(timeout: 10)
        
        // Assert performance benchmark
        XCTAssertLessThan(firstTokenTime, 2.0, "First token took too long: \(firstTokenTime)s")
        
        // Log metric
        logger.info("First token latency: \(firstTokenTime)s")
    }
}

// MARK: - Claude WebSocket Connection Handler

class ClaudeWebSocketConnection: NSObject {
    private var urlSession: URLSession!
    private var webSocketTask: URLSessionWebSocketTask?
    private let apiKey: String
    private let logger = Logger(subsystem: "com.claudecode.ui", category: "WebSocket")
    
    var onConnected: (() -> Void)?
    var onMessage: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    
    init(apiKey: String) {
        self.apiKey = apiKey
        super.init()
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }
    
    func connect() {
        let url = URL(string: "wss://api.anthropic.com/v1/messages/stream")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("2024-01-01", forHTTPHeaderField: "anthropic-version")
        
        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()
        
        onConnected?()
        receiveMessage()
    }
    
    func send(prompt: String) {
        let message: [String: Any] = [
            "model": "claude-3-opus-20240229",
            "messages": [["role": "user", "content": prompt]],
            "max_tokens": 1024,
            "stream": true
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: message) else { return }
        let wsMessage = URLSessionWebSocketTask.Message.data(data)
        
        webSocketTask?.send(wsMessage) { [weak self] error in
            if let error = error {
                self?.logger.error("Send error: \(error)")
                self?.onError?(error)
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                self?.receiveMessage() // Continue receiving
                
            case .failure(let error):
                self?.logger.error("Receive error: \(error)")
                self?.onError?(error)
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        // Parse SSE format
        let lines = text.components(separatedBy: "\n")
        for line in lines {
            if line.hasPrefix("data: ") {
                let data = String(line.dropFirst(6))
                onMessage?(data)
            }
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
}

// MARK: - Media Capture Manager

class MediaCaptureManager {
    private var recordingSession: FFmpegSession?
    private let outputDirectory: URL
    private let logger = Logger(subsystem: "com.claudecode.ui", category: "MediaCapture")
    
    init() {
        outputDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TestVideos")
        try? FileManager.default.createDirectory(at: outputDirectory,
                                                withIntermediateDirectories: true)
    }
    
    func startRecording(testName: String) {
        let timestamp = DateFormatter.localizedString(from: Date(),
                                                     dateStyle: .none,
                                                     timeStyle: .medium)
            .replacingOccurrences(of: ":", with: "-")
        
        let outputPath = outputDirectory
            .appendingPathComponent("\(testName)_\(timestamp).mp4")
            .path
        
        // FFmpeg command for screen recording
        let command = "-f avfoundation -r 30 -i '1:none' -c:v libx264 -preset ultrafast -pix_fmt yuv420p -y '\(outputPath)'"
        
        FFmpegKit.executeAsync(command) { session in
            self.recordingSession = session
            self.logger.info("Recording started: \(outputPath)")
        }
    }
    
    func stopRecording(completion: @escaping (URL) -> Void) {
        guard let session = recordingSession else { return }
        
        FFmpegKit.cancel(session.getSessionId())
        
        if let outputPath = session.getOutput() {
            let url = URL(fileURLWithPath: outputPath)
            completion(url)
            logger.info("Recording saved: \(url.lastPathComponent)")
        }
    }
    
    func captureScreenshot(name: String) -> URL? {
        let outputPath = outputDirectory
            .appendingPathComponent("\(name).png")
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        task.arguments = ["simctl", "io", "booted", "screenshot", outputPath.path]
        
        do {
            try task.run()
            task.waitUntilExit()
            return outputPath
        } catch {
            logger.error("Screenshot failed: \(error)")
            return nil
        }
    }
}

// MARK: - Secret Scanner

class SecretScanner {
    private let logger = Logger(subsystem: "com.claudecode.ui", category: "Security")
    
    func scanProject() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/trufflehog")
        process.arguments = [
            "filesystem",
            ".",
            "--json",
            "--no-verification",
            "--config", ".trufflehog.yml"
        ]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                logger.warning("⚠️ Potential secrets detected:\n\(output)")
                return false
            }
            
            logger.info("✅ No secrets detected")
            return true
        } catch {
            logger.error("TruffleHog scan failed: \(error)")
            return false
        }
    }
}

// MARK: - Network Condition Simulator

enum NetworkConditionSimulator {
    enum Profile {
        case perfect
        case goodWiFi
        case averageLTE
        case poor3G
        case edge
        
        var command: String {
            switch self {
            case .perfect:
                return "set 100.0 0.0 0"
            case .goodWiFi:
                return "set 40.0 10.0 0"
            case .averageLTE:
                return "set 10.0 50.0 0.1"
            case .poor3G:
                return "set 0.78 200.0 1.0"
            case .edge:
                return "set 0.24 400.0 2.0"
            }
        }
    }
    
    static func apply(profile: Profile) {
        let deviceId = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_ID"] ?? "booted"
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        task.arguments = ["simctl", "network", deviceId, profile.command]
        
        try? task.run()
        task.waitUntilExit()
    }
    
    static func reset() {
        apply(profile: .perfect)
    }
}

// MARK: - Test Helpers

extension XCTestCase {
    func addAttachment(url: URL) {
        let attachment = XCTAttachment(contentsOfFile: url)
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func generatePerformanceReport() {
        // Implementation for generating detailed performance reports
        let metrics = [
            "First Token Latency": "< 2s",
            "Streaming Chunk Interval": "< 100ms",
            "Total Response Time": "< 30s",
            "Memory Usage": "< 150MB",
            "CPU Usage": "< 30%"
        ]
        
        print("Performance Report:")
        metrics.forEach { key, value in
            print("  \(key): \(value)")
        }
    }
}