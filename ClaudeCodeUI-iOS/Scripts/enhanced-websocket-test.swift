#!/usr/bin/env swift

import Foundation
import Combine

// ============================================================================
// Enhanced WebSocket Validation Test
// ============================================================================
// Purpose: Comprehensive WebSocket connectivity and streaming validation
// ============================================================================

struct WebSocketTestConfig {
    let url: String
    let timeout: TimeInterval
    let messageCount: Int
    let streamingTest: Bool
    let performanceTest: Bool
    let stressTest: Bool
}

class WebSocketValidator {
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession
    private var cancellables = Set<AnyCancellable>()
    private let config: WebSocketTestConfig
    
    // Test metrics
    private var connectionTime: TimeInterval = 0
    private var messagesSent = 0
    private var messagesReceived = 0
    private var streamingChunksReceived = 0
    private var totalLatency: TimeInterval = 0
    private var errors: [String] = []
    
    init(config: WebSocketTestConfig) {
        self.config = config
        self.session = URLSession(configuration: .default)
    }
    
    func runTests() async -> TestResult {
        print("🚀 Starting Enhanced WebSocket Validation")
        print("📍 URL: \(config.url)")
        print("⏱️ Timeout: \(config.timeout)s")
        print("📊 Tests: Connection, Messaging, Streaming, Performance")
        print("=" * 60)
        
        var results = TestResult()
        
        // Test 1: Connection
        if await testConnection() {
            results.connectionTest = .passed
            print("✅ Connection test passed (\(String(format: "%.2f", connectionTime))s)")
        } else {
            results.connectionTest = .failed
            print("❌ Connection test failed")
            return results
        }
        
        // Test 2: Basic messaging
        if await testBasicMessaging() {
            results.messagingTest = .passed
            print("✅ Basic messaging test passed")
        } else {
            results.messagingTest = .failed
            print("❌ Basic messaging test failed")
        }
        
        // Test 3: Streaming response
        if config.streamingTest {
            if await testStreamingResponse() {
                results.streamingTest = .passed
                print("✅ Streaming test passed (\(streamingChunksReceived) chunks)")
            } else {
                results.streamingTest = .failed
                print("❌ Streaming test failed")
            }
        }
        
        // Test 4: Performance
        if config.performanceTest {
            let metrics = await testPerformance()
            results.performanceMetrics = metrics
            print("📊 Performance Metrics:")
            print("   • Average latency: \(String(format: "%.2f", metrics.averageLatency))ms")
            print("   • Throughput: \(metrics.throughput) msg/s")
            print("   • Success rate: \(String(format: "%.1f", metrics.successRate))%")
        }
        
        // Test 5: Stress test
        if config.stressTest {
            if await testStressConditions() {
                results.stressTest = .passed
                print("✅ Stress test passed")
            } else {
                results.stressTest = .failed
                print("❌ Stress test failed")
            }
        }
        
        // Disconnect
        await disconnect()
        
        // Generate report
        results.generateReport()
        
        return results
    }
    
    private func testConnection() async -> Bool {
        let startTime = Date()
        
        guard let url = URL(string: config.url) else {
            errors.append("Invalid URL: \(config.url)")
            return false
        }
        
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Send ping to verify connection
        do {
            let pingMessage = """
            {
                "type": "ping",
                "timestamp": \(Date().timeIntervalSince1970)
            }
            """
            
            try await webSocketTask?.send(.string(pingMessage))
            
            // Wait for pong response
            let message = try await withTimeout(seconds: 5) {
                try await self.webSocketTask?.receive()
            }
            
            if case .string(let text) = message {
                if text.contains("pong") {
                    connectionTime = Date().timeIntervalSince(startTime)
                    return true
                }
            }
            
        } catch {
            errors.append("Connection failed: \(error)")
            return false
        }
        
        return false
    }
    
    private func testBasicMessaging() async -> Bool {
        do {
            // Send a simple message
            let testMessage = """
            {
                "type": "message",
                "content": "Test message from iOS client",
                "timestamp": \(Date().timeIntervalSince1970)
            }
            """
            
            try await webSocketTask?.send(.string(testMessage))
            messagesSent += 1
            
            // Receive response
            let response = try await withTimeout(seconds: 10) {
                try await self.webSocketTask?.receive()
            }
            
            if case .string(let text) = response {
                messagesReceived += 1
                return text.contains("received") || text.contains("echo")
            }
            
        } catch {
            errors.append("Messaging failed: \(error)")
        }
        
        return false
    }
    
    private func testStreamingResponse() async -> Bool {
        do {
            // Send streaming request
            let streamRequest = """
            {
                "type": "stream",
                "action": "startStreaming",
                "messageId": "\(UUID().uuidString)",
                "content": "Generate a long streaming response to test real-time data flow"
            }
            """
            
            try await webSocketTask?.send(.string(streamRequest))
            
            // Receive streaming chunks
            let startTime = Date()
            var chunks: [String] = []
            
            while Date().timeIntervalSince(startTime) < 30 { // 30 second timeout
                if let message = try? await withTimeout(seconds: 1) {
                    try await self.webSocketTask?.receive()
                } {
                    if case .string(let text) = message {
                        chunks.append(text)
                        streamingChunksReceived += 1
                        
                        // Check for end of stream
                        if text.contains("endOfStream") || text.contains("complete") {
                            break
                        }
                    }
                }
            }
            
            return streamingChunksReceived > 0
            
        } catch {
            errors.append("Streaming test failed: \(error)")
        }
        
        return false
    }
    
    private func testPerformance() async -> PerformanceMetrics {
        var metrics = PerformanceMetrics()
        var latencies: [TimeInterval] = []
        let testMessages = 100
        
        for i in 0..<testMessages {
            let startTime = Date()
            
            let message = """
            {
                "type": "performance",
                "id": \(i),
                "timestamp": \(startTime.timeIntervalSince1970)
            }
            """
            
            do {
                try await webSocketTask?.send(.string(message))
                
                if let response = try? await withTimeout(seconds: 1) {
                    try await self.webSocketTask?.receive()
                } {
                    let latency = Date().timeIntervalSince(startTime) * 1000 // Convert to ms
                    latencies.append(latency)
                    
                    if case .string(let text) = response {
                        // Process response
                        messagesReceived += 1
                    }
                }
                
                messagesSent += 1
                
            } catch {
                // Record failure
            }
            
            // Small delay between messages
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        // Calculate metrics
        if !latencies.isEmpty {
            metrics.averageLatency = latencies.reduce(0, +) / Double(latencies.count)
            metrics.minLatency = latencies.min() ?? 0
            metrics.maxLatency = latencies.max() ?? 0
            metrics.p95Latency = percentile(latencies, 0.95)
            metrics.p99Latency = percentile(latencies, 0.99)
        }
        
        let duration = Double(testMessages) * 0.01 // Approximate duration
        metrics.throughput = Double(messagesReceived) / duration
        metrics.successRate = Double(messagesReceived) / Double(messagesSent) * 100
        
        return metrics
    }
    
    private func testStressConditions() async -> Bool {
        // Test rapid message sending
        let stressMessageCount = 1000
        var successCount = 0
        
        await withTaskGroup(of: Bool.self) { group in
            for i in 0..<stressMessageCount {
                group.addTask {
                    let message = """
                    {
                        "type": "stress",
                        "id": \(i),
                        "data": "\(String(repeating: "X", count: 1024))"
                    }
                    """
                    
                    do {
                        try await self.webSocketTask?.send(.string(message))
                        return true
                    } catch {
                        return false
                    }
                }
            }
            
            for await success in group {
                if success {
                    successCount += 1
                }
            }
        }
        
        let successRate = Double(successCount) / Double(stressMessageCount) * 100
        return successRate > 95 // Accept 95% success rate
    }
    
    private func disconnect() async {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
    }
    
    private func percentile(_ values: [Double], _ p: Double) -> Double {
        let sorted = values.sorted()
        let index = Int(Double(sorted.count - 1) * p)
        return sorted[index]
    }
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

// ============================================================================
// Supporting Types
// ============================================================================

struct TestResult {
    enum Status {
        case passed, failed, skipped
    }
    
    var connectionTest: Status = .skipped
    var messagingTest: Status = .skipped
    var streamingTest: Status = .skipped
    var stressTest: Status = .skipped
    var performanceMetrics: PerformanceMetrics?
    
    func generateReport() {
        print("\n" + "=" * 60)
        print("📊 WebSocket Validation Report")
        print("=" * 60)
        
        let tests = [
            ("Connection", connectionTest),
            ("Messaging", messagingTest),
            ("Streaming", streamingTest),
            ("Stress", stressTest)
        ]
        
        var passed = 0
        var failed = 0
        
        for (name, status) in tests {
            let icon = status == .passed ? "✅" : (status == .failed ? "❌" : "⏭️")
            print("\(icon) \(name) Test: \(status)")
            
            if status == .passed { passed += 1 }
            if status == .failed { failed += 1 }
        }
        
        if let metrics = performanceMetrics {
            print("\n📈 Performance Metrics:")
            print("   • Average Latency: \(String(format: "%.2f", metrics.averageLatency))ms")
            print("   • Min Latency: \(String(format: "%.2f", metrics.minLatency))ms")
            print("   • Max Latency: \(String(format: "%.2f", metrics.maxLatency))ms")
            print("   • P95 Latency: \(String(format: "%.2f", metrics.p95Latency))ms")
            print("   • P99 Latency: \(String(format: "%.2f", metrics.p99Latency))ms")
            print("   • Throughput: \(String(format: "%.2f", metrics.throughput)) msg/s")
            print("   • Success Rate: \(String(format: "%.1f", metrics.successRate))%")
        }
        
        print("\n📊 Summary:")
        print("   • Tests Passed: \(passed)")
        print("   • Tests Failed: \(failed)")
        print("   • Pass Rate: \(passed * 100 / (passed + failed))%")
        
        let overallStatus = failed == 0 ? "✅ ALL TESTS PASSED" : "❌ SOME TESTS FAILED"
        print("\n\(overallStatus)")
        print("=" * 60)
    }
}

struct PerformanceMetrics {
    var averageLatency: Double = 0
    var minLatency: Double = 0
    var maxLatency: Double = 0
    var p95Latency: Double = 0
    var p99Latency: Double = 0
    var throughput: Double = 0
    var successRate: Double = 0
}

struct TimeoutError: Error {}

// ============================================================================
// String Extension for Repeating
// ============================================================================

extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}

// ============================================================================
// Main Execution
// ============================================================================

@main
struct WebSocketTestRunner {
    static func main() async {
        // Parse command line arguments
        let arguments = CommandLine.arguments
        
        var url = "ws://192.168.0.155:3004/ws"
        var timeout: TimeInterval = 30
        var messageCount = 10
        var runStreaming = true
        var runPerformance = true
        var runStress = false
        
        for i in 0..<arguments.count {
            switch arguments[i] {
            case "--url":
                if i + 1 < arguments.count {
                    url = arguments[i + 1]
                }
            case "--timeout":
                if i + 1 < arguments.count {
                    timeout = TimeInterval(arguments[i + 1]) ?? 30
                }
            case "--messages":
                if i + 1 < arguments.count {
                    messageCount = Int(arguments[i + 1]) ?? 10
                }
            case "--no-streaming":
                runStreaming = false
            case "--no-performance":
                runPerformance = false
            case "--stress":
                runStress = true
            case "--help":
                printHelp()
                return
            default:
                break
            }
        }
        
        let config = WebSocketTestConfig(
            url: url,
            timeout: timeout,
            messageCount: messageCount,
            streamingTest: runStreaming,
            performanceTest: runPerformance,
            stressTest: runStress
        )
        
        let validator = WebSocketValidator(config: config)
        let result = await validator.runTests()
        
        // Exit with appropriate code
        let exitCode = result.connectionTest == .failed || 
                      result.messagingTest == .failed || 
                      result.streamingTest == .failed ? 1 : 0
        
        exit(Int32(exitCode))
    }
    
    static func printHelp() {
        print("""
        Enhanced WebSocket Validation Test
        
        Usage: swift enhanced-websocket-test.swift [options]
        
        Options:
            --url <url>           WebSocket URL (default: ws://192.168.0.155:3004/ws)
            --timeout <seconds>   Connection timeout (default: 30)
            --messages <count>    Number of test messages (default: 10)
            --no-streaming        Skip streaming test
            --no-performance      Skip performance test
            --stress              Run stress test
            --help                Show this help message
        
        Example:
            swift enhanced-websocket-test.swift --url ws://localhost:3004/ws --stress
        """)
    }
}