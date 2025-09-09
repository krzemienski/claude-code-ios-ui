#!/usr/bin/env swift

//
// test_claude_api_integration.swift
// Test script for Claude API SSE streaming integration
// Agent-002: WebSocket/SSE Claude API Integration Specialist
//

import Foundation

// MARK: - Test Configuration
struct TestConfig {
    static let apiKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] ?? ""
    static let baseURL = "https://api.anthropic.com/v1"
    static let model = "claude-3-opus-20240229"
    static let apiVersion = "2023-06-01"
    static let testMessage = "Hello Claude, please respond with a brief greeting to test SSE streaming."
}

// MARK: - SSE Event Types
enum SSEEventType: String {
    case messageStart = "message_start"
    case contentBlockStart = "content_block_start"
    case contentBlockDelta = "content_block_delta"
    case contentBlockStop = "content_block_stop"
    case messageDelta = "message_delta"
    case messageStop = "message_stop"
    case ping = "ping"
    case error = "error"
}

// MARK: - Test Results
class TestResults {
    var connectionTime: TimeInterval = 0
    var firstByteTime: TimeInterval = 0
    var totalStreamTime: TimeInterval = 0
    var eventsReceived: [String] = []
    var bytesReceived = 0
    var contentReceived = ""
    var errors: [String] = []
    
    func printResults() {
        print("\n" + String(repeating: "=", count: 60))
        print("📊 CLAUDE API SSE STREAMING TEST RESULTS")
        print(String(repeating: "=", count: 60))
        
        print("\n⏱️ PERFORMANCE METRICS:")
        print("  • Connection Time: \(String(format: "%.3f", connectionTime))s")
        print("  • Time to First Byte: \(String(format: "%.3f", firstByteTime))s")
        print("  • Total Stream Time: \(String(format: "%.3f", totalStreamTime))s")
        print("  • Bytes Received: \(bytesReceived)")
        
        print("\n📨 SSE EVENTS RECEIVED (\(eventsReceived.count) total):")
        let eventCounts = Dictionary(grouping: eventsReceived, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.key < $1.key }
        
        for (event, count) in eventCounts {
            print("  • \(event): \(count)")
        }
        
        print("\n💬 CONTENT RECEIVED:")
        print("  \(contentReceived.isEmpty ? "[No content]" : contentReceived)")
        
        if !errors.isEmpty {
            print("\n❌ ERRORS:")
            for error in errors {
                print("  • \(error)")
            }
        }
        
        print("\n✅ TEST STATUS: \(errors.isEmpty ? "PASSED" : "FAILED")")
        print(String(repeating: "=", count: 60))
    }
}

// MARK: - SSE Stream Handler
class SSEStreamHandler: NSObject, URLSessionDataDelegate {
    let results = TestResults()
    private var streamBuffer = Data()
    private var startTime: Date?
    private var firstByteTime: Date?
    private let semaphore = DispatchSemaphore(value: 0)
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // Track first byte time
        if firstByteTime == nil {
            firstByteTime = Date()
            if let start = startTime {
                results.firstByteTime = firstByteTime!.timeIntervalSince(start)
            }
        }
        
        streamBuffer.append(data)
        results.bytesReceived += data.count
        
        // Process complete SSE events
        while let eventData = extractNextEvent() {
            processSSEEvent(eventData)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            results.errors.append("Stream error: \(error.localizedDescription)")
        }
        
        if let start = startTime {
            results.totalStreamTime = Date().timeIntervalSince(start)
        }
        
        semaphore.signal()
    }
    
    private func extractNextEvent() -> Data? {
        let doubleNewline = "\n\n".data(using: .utf8)!
        if let range = streamBuffer.range(of: doubleNewline) {
            let eventData = streamBuffer.subdata(in: 0..<range.upperBound)
            streamBuffer.removeSubrange(0..<range.upperBound)
            return eventData
        }
        return nil
    }
    
    private func processSSEEvent(_ data: Data) {
        guard let string = String(data: data, encoding: .utf8) else { return }
        
        var eventType: String?
        var eventData: [String: Any]?
        
        let lines = string.components(separatedBy: "\n")
        for line in lines {
            if line.hasPrefix("event: ") {
                eventType = String(line.dropFirst(7))
                results.eventsReceived.append(eventType ?? "unknown")
            } else if line.hasPrefix("data: ") {
                let dataString = String(line.dropFirst(6))
                if let data = dataString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    eventData = json
                }
            }
        }
        
        // Extract text content from content_block_delta events
        if eventType == SSEEventType.contentBlockDelta.rawValue,
           let delta = eventData?["delta"] as? [String: Any],
           let text = delta["text"] as? String {
            results.contentReceived += text
        }
        
        // Stop on message_stop event
        if eventType == SSEEventType.messageStop.rawValue {
            semaphore.signal()
        }
    }
    
    func startStream() {
        startTime = Date()
    }
    
    func waitForCompletion(timeout: TimeInterval = 30) {
        _ = semaphore.wait(timeout: .now() + timeout)
    }
}

// MARK: - Test Runner
class ClaudeAPITester {
    
    static func run() {
        print("\n🚀 Starting Claude API SSE Streaming Test...")
        print("   API Key: \(TestConfig.apiKey.isEmpty ? "❌ NOT SET" : "✅ Set (\(TestConfig.apiKey.prefix(10))...)")")
        
        guard !TestConfig.apiKey.isEmpty else {
            print("\n❌ ERROR: CLAUDE_API_KEY environment variable not set!")
            print("   Please set: export CLAUDE_API_KEY='your-api-key'")
            exit(1)
        }
        
        // Create request
        guard let url = URL(string: "\(TestConfig.baseURL)/messages") else {
            print("❌ Invalid URL")
            exit(1)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(TestConfig.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(TestConfig.apiVersion, forHTTPHeaderField: "anthropic-version")
        
        // Create request body
        let requestBody: [String: Any] = [
            "model": TestConfig.model,
            "messages": [
                ["role": "user", "content": TestConfig.testMessage]
            ],
            "max_tokens": 100,
            "stream": true,
            "temperature": 0.7
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("❌ Failed to serialize request: \(error)")
            exit(1)
        }
        
        // Create URLSession with delegate
        let handler = SSEStreamHandler()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        let session = URLSession(configuration: config, delegate: handler, delegateQueue: nil)
        
        // Start the stream
        print("📡 Connecting to Claude API...")
        handler.startStream()
        
        let connectionStart = Date()
        let task = session.dataTask(with: request)
        task.resume()
        
        handler.results.connectionTime = Date().timeIntervalSince(connectionStart)
        
        print("⏳ Waiting for SSE stream...")
        handler.waitForCompletion()
        
        // Print results
        handler.results.printResults()
        
        // Validate results
        validateResults(handler.results)
    }
    
    static func validateResults(_ results: TestResults) {
        print("\n🔍 VALIDATION:")
        
        var validationPassed = true
        
        // Check connection time
        if results.connectionTime < 5.0 {
            print("  ✅ Connection time under 5s")
        } else {
            print("  ⚠️ Connection time over 5s: \(results.connectionTime)s")
        }
        
        // Check first byte time
        if results.firstByteTime < 2.0 {
            print("  ✅ Time to first byte under 2s")
        } else {
            print("  ⚠️ Time to first byte over 2s: \(results.firstByteTime)s")
        }
        
        // Check events received
        let requiredEvents = ["message_start", "content_block_start", "content_block_delta", "message_stop"]
        let receivedEventTypes = Set(results.eventsReceived)
        
        for event in requiredEvents {
            if receivedEventTypes.contains(event) {
                print("  ✅ Received required event: \(event)")
            } else {
                print("  ❌ Missing required event: \(event)")
                validationPassed = false
            }
        }
        
        // Check content
        if !results.contentReceived.isEmpty {
            print("  ✅ Received streaming content (\(results.contentReceived.count) chars)")
        } else {
            print("  ❌ No content received")
            validationPassed = false
        }
        
        // Check errors
        if results.errors.isEmpty {
            print("  ✅ No errors during streaming")
        } else {
            print("  ❌ Errors occurred during streaming")
            validationPassed = false
        }
        
        print("\n" + String(repeating: "=", count: 60))
        if validationPassed {
            print("🎉 CLAUDE API SSE INTEGRATION TEST PASSED!")
            print("✅ Ready for iOS app integration")
        } else {
            print("❌ CLAUDE API SSE INTEGRATION TEST FAILED")
            print("Please review the errors above")
        }
        print(String(repeating: "=", count: 60))
        
        exit(validationPassed ? 0 : 1)
    }
}

// MARK: - Main
ClaudeAPITester.run()