#!/usr/bin/env swift
//
// test_claude_api_connection.swift
// E2E Test for Claude API SSE Streaming
//

import Foundation

// MARK: - Test Configuration
struct TestConfig {
    static let claudeAPIKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] ?? ""
    static let testMessage = "Hi, this is a test message. Please respond with 'Connection successful!'"
    static let apiURL = "https://api.anthropic.com/v1/messages"
    static let apiVersion = "2023-06-01"
    static let model = "claude-3-opus-20240229"
    static let timeout: TimeInterval = 30.0
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
struct TestResults {
    var connectionSuccessful = false
    var sseStreamingWorking = false
    var responseReceived = false
    var errorMessage: String?
    var metrics: TestMetrics
    
    struct TestMetrics {
        var connectionTime: TimeInterval = 0
        var firstByteTime: TimeInterval = 0
        var totalTime: TimeInterval = 0
        var bytesReceived = 0
        var eventsReceived = 0
    }
}

// MARK: - Claude API Test
class ClaudeAPITest: NSObject, URLSessionDataDelegate {
    private var session: URLSession!
    private var dataTask: URLSessionDataTask?
    private var streamBuffer = Data()
    private var results = TestResults(metrics: TestResults.TestMetrics())
    private var startTime: Date?
    private var firstByteTime: Date?
    private let semaphore = DispatchSemaphore(value: 0)
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = TestConfig.timeout
        config.httpAdditionalHeaders = [
            "anthropic-version": TestConfig.apiVersion,
            "content-type": "application/json",
            "x-api-key": TestConfig.claudeAPIKey,
            "accept": "text/event-stream"
        ]
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func runTest() -> TestResults {
        guard !TestConfig.claudeAPIKey.isEmpty else {
            results.errorMessage = "❌ CLAUDE_API_KEY environment variable not set"
            return results
        }
        
        print("🚀 Starting Claude API SSE streaming test...")
        print("📍 Endpoint: \(TestConfig.apiURL)")
        print("🤖 Model: \(TestConfig.model)")
        
        // Create request
        let requestBody: [String: Any] = [
            "model": TestConfig.model,
            "messages": [
                ["role": "user", "content": TestConfig.testMessage]
            ],
            "max_tokens": 100,
            "stream": true
        ]
        
        guard let url = URL(string: TestConfig.apiURL) else {
            results.errorMessage = "❌ Invalid API URL"
            return results
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(TestConfig.claudeAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue(TestConfig.apiVersion, forHTTPHeaderField: "anthropic-version")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            results.errorMessage = "❌ Failed to encode request: \(error)"
            return results
        }
        
        // Start test
        startTime = Date()
        dataTask = session.dataTask(with: request)
        dataTask?.resume()
        
        // Wait for completion
        _ = semaphore.wait(timeout: .now() + TestConfig.timeout)
        
        // Calculate final metrics
        if let start = startTime {
            results.metrics.totalTime = Date().timeIntervalSince(start)
        }
        
        return results
    }
    
    // MARK: - URLSessionDataDelegate
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 Response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                results.connectionSuccessful = true
                if let start = startTime {
                    results.metrics.connectionTime = Date().timeIntervalSince(start)
                    print("⚡ Connection time: \(results.metrics.connectionTime)s")
                }
                completionHandler(.allow)
            } else {
                results.errorMessage = "❌ HTTP error: \(httpResponse.statusCode)"
                completionHandler(.cancel)
                semaphore.signal()
            }
        } else {
            completionHandler(.allow)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if firstByteTime == nil {
            firstByteTime = Date()
            if let start = startTime {
                results.metrics.firstByteTime = firstByteTime!.timeIntervalSince(start)
                print("⚡ Time to first byte: \(results.metrics.firstByteTime)s")
            }
        }
        
        streamBuffer.append(data)
        results.metrics.bytesReceived += data.count
        processSSEEvents()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            results.errorMessage = "❌ Connection error: \(error.localizedDescription)"
        }
        semaphore.signal()
    }
    
    // MARK: - SSE Processing
    
    private func processSSEEvents() {
        while let eventData = extractNextEvent() {
            if let event = parseSSEEvent(eventData) {
                results.metrics.eventsReceived += 1
                results.sseStreamingWorking = true
                handleSSEEvent(event)
            }
        }
    }
    
    private func extractNextEvent() -> String? {
        guard let string = String(data: streamBuffer, encoding: .utf8) else { return nil }
        
        if let range = string.range(of: "\n\n") {
            let event = String(string[..<range.lowerBound])
            let remainingData = String(string[range.upperBound...]).data(using: .utf8) ?? Data()
            streamBuffer = remainingData
            return event
        }
        
        return nil
    }
    
    private func parseSSEEvent(_ eventString: String) -> (type: SSEEventType, data: String?)? {
        var eventType: SSEEventType?
        var eventData: String?
        
        let lines = eventString.components(separatedBy: "\n")
        for line in lines {
            if line.hasPrefix("event: ") {
                let typeString = String(line.dropFirst(7))
                eventType = SSEEventType(rawValue: typeString)
            } else if line.hasPrefix("data: ") {
                eventData = String(line.dropFirst(6))
            }
        }
        
        if let type = eventType {
            return (type, eventData)
        }
        
        return nil
    }
    
    private func handleSSEEvent(_ event: (type: SSEEventType, data: String?)) {
        print("📨 Event: \(event.type.rawValue)")
        
        switch event.type {
        case .contentBlockDelta:
            if let data = event.data,
               let jsonData = data.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let delta = json["delta"] as? [String: Any],
               let text = delta["text"] as? String {
                print("💬 Text: \(text)")
                results.responseReceived = true
            }
            
        case .messageStop:
            print("✅ Stream completed")
            dataTask?.cancel()
            semaphore.signal()
            
        case .error:
            if let data = event.data {
                results.errorMessage = "❌ API error: \(data)"
            }
            dataTask?.cancel()
            semaphore.signal()
            
        default:
            break
        }
    }
}

// MARK: - Main Test Execution
print(String(repeating: "=", count: 50))
print("CLAUDE API SSE STREAMING TEST")
print(String(repeating: "=", count: 50))

let test = ClaudeAPITest()
let results = test.runTest()

print("\n" + String(repeating: "=", count: 50))
print("TEST RESULTS")
print(String(repeating: "=", count: 50))

if let error = results.errorMessage {
    print(error)
} else {
    print("✅ Connection: \(results.connectionSuccessful ? "SUCCESS" : "FAILED")")
    print("✅ SSE Streaming: \(results.sseStreamingWorking ? "WORKING" : "NOT WORKING")")
    print("✅ Response Received: \(results.responseReceived ? "YES" : "NO")")
    print("\n📊 METRICS:")
    print("  • Connection Time: \(String(format: "%.3f", results.metrics.connectionTime))s")
    print("  • Time to First Byte: \(String(format: "%.3f", results.metrics.firstByteTime))s")
    print("  • Total Time: \(String(format: "%.3f", results.metrics.totalTime))s")
    print("  • Bytes Received: \(results.metrics.bytesReceived)")
    print("  • Events Received: \(results.metrics.eventsReceived)")
}

print("\n" + String(repeating: "=", count: 50))

// Exit with appropriate code
exit(results.connectionSuccessful && results.sseStreamingWorking && results.responseReceived ? 0 : 1)