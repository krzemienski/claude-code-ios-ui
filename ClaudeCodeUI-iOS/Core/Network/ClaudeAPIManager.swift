//
//  ClaudeAPIManager.swift
//  ClaudeCodeUI
//
//  Created for E2E Claude API Testing - SSE Streaming Support
//

import Foundation

// MARK: - Claude API Configuration
struct ClaudeAPIConfig {
    static let baseURL = "https://api.anthropic.com/v1"
    static let messagesEndpoint = "/messages"
    static let streamingEndpoint = "/messages"
    static let apiVersion = "2023-06-01"
    static let model = "claude-3-opus-20240229"
    
    // API Key should be stored securely in Keychain
    // For E2E testing, we'll read from environment or UserDefaults
    static var apiKey: String {
        // First check environment (for testing)
        if let envKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] {
            return envKey
        }
        // Then check UserDefaults (temporary for testing)
        if let savedKey = UserDefaults.standard.string(forKey: "claude_api_key") {
            return savedKey
        }
        // TODO: Use KeychainManager when available
        return ""
    }
}

// MARK: - Claude SSE Event Types
enum ClaudeSSEEventType: String {
    case messageStart = "message_start"
    case contentBlockStart = "content_block_start"
    case contentBlockDelta = "content_block_delta"
    case contentBlockStop = "content_block_stop"
    case messageDelta = "message_delta"
    case messageStop = "message_stop"
    case ping = "ping"
    case error = "error"
}

// MARK: - Claude API Response Models
struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

struct ClaudeAPIRequest: Codable {
    let model: String
    let messages: [ClaudeMessage]
    let max_tokens: Int
    let stream: Bool
    let temperature: Double?
    let system: String?
}

struct ClaudeSSEEvent {
    let type: ClaudeSSEEventType
    let data: [String: Any]?
}

// MARK: - Claude API Manager Protocol
protocol ClaudeAPIManagerDelegate: AnyObject {
    func claudeAPIDidConnect(_ manager: ClaudeAPIManager)
    func claudeAPIDidDisconnect(_ manager: ClaudeAPIManager, error: Error?)
    func claudeAPI(_ manager: ClaudeAPIManager, didReceiveEvent event: ClaudeSSEEvent)
    func claudeAPI(_ manager: ClaudeAPIManager, didReceiveText text: String)
    func claudeAPI(_ manager: ClaudeAPIManager, didCompleteStream messageId: String)
}

// MARK: - Claude API Manager
final class ClaudeAPIManager: NSObject {
    
    // MARK: - Properties
    weak var delegate: ClaudeAPIManagerDelegate?
    private var urlSession: URLSession?
    private var dataTask: URLSessionDataTask?
    private var streamBuffer = Data()
    private var isStreaming = false
    private var currentMessageId: String?
    
    // Connection state
    private(set) var isConnected: Bool = false {
        didSet {
            if isConnected {
                delegate?.claudeAPIDidConnect(self)
            } else {
                delegate?.claudeAPIDidDisconnect(self, error: nil)
            }
        }
    }
    
    // Metrics tracking
    private var connectionStartTime: Date?
    private var firstByteTime: Date?
    private var bytesReceived: Int = 0
    private var eventsReceived: Int = 0
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupURLSession()
    }
    
    private func setupURLSession() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60.0
        config.timeoutIntervalForResource = 300.0
        config.waitsForConnectivity = true
        
        // Set headers for Claude API
        config.httpAdditionalHeaders = [
            "anthropic-version": ClaudeAPIConfig.apiVersion,
            "content-type": "application/json",
            "x-api-key": ClaudeAPIConfig.apiKey,
            "accept": "text/event-stream" // For SSE
        ]
        
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    // MARK: - Public Methods
    
    /// Send a message to Claude API with SSE streaming
    func sendMessage(_ content: String, systemPrompt: String? = nil) {
        guard !ClaudeAPIConfig.apiKey.isEmpty else {
            logError("Claude API key not configured", category: "ClaudeAPI")
            delegate?.claudeAPIDidDisconnect(self, error: ClaudeAPIError.missingAPIKey)
            return
        }
        
        // Cancel any existing stream
        if isStreaming {
            stopStreaming()
        }
        
        // Prepare request
        let messages = [ClaudeMessage(role: "user", content: content)]
        let request = ClaudeAPIRequest(
            model: ClaudeAPIConfig.model,
            messages: messages,
            max_tokens: 4096,
            stream: true, // Enable SSE streaming
            temperature: 0.7,
            system: systemPrompt
        )
        
        // Create URL request
        guard let url = URL(string: ClaudeAPIConfig.baseURL + ClaudeAPIConfig.streamingEndpoint) else {
            logError("Invalid Claude API URL", category: "ClaudeAPI")
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(ClaudeAPIConfig.apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(ClaudeAPIConfig.apiVersion, forHTTPHeaderField: "anthropic-version")
        
        do {
            let encoder = JSONEncoder()
            urlRequest.httpBody = try encoder.encode(request)
            
            // Start metrics tracking
            connectionStartTime = Date()
            bytesReceived = 0
            eventsReceived = 0
            currentMessageId = UUID().uuidString
            
            // Start streaming
            isStreaming = true
            isConnected = true
            streamBuffer = Data()
            
            logInfo("🚀 Starting Claude API SSE stream for message: \(content.prefix(100))...", category: "ClaudeAPI")
            
            // Create data task for streaming
            dataTask = urlSession?.dataTask(with: urlRequest)
            dataTask?.resume()
            
        } catch {
            logError("Failed to encode Claude API request: \(error)", category: "ClaudeAPI")
            delegate?.claudeAPIDidDisconnect(self, error: error)
        }
    }
    
    /// Stop the current streaming session
    func stopStreaming() {
        isStreaming = false
        isConnected = false
        dataTask?.cancel()
        dataTask = nil
        streamBuffer = Data()
        
        if let messageId = currentMessageId {
            delegate?.claudeAPI(self, didCompleteStream: messageId)
        }
        
        // Log metrics
        if let startTime = connectionStartTime {
            let duration = Date().timeIntervalSince(startTime)
            logInfo("📊 Stream metrics - Duration: \(duration)s, Bytes: \(bytesReceived), Events: \(eventsReceived)", category: "ClaudeAPI")
        }
    }
    
    /// Test connection to Claude API
    func testConnection() async -> Bool {
        guard !ClaudeAPIConfig.apiKey.isEmpty else {
            logError("Claude API key not configured", category: "ClaudeAPI")
            return false
        }
        
        // Create a simple test request
        let messages = [ClaudeMessage(role: "user", content: "Hi")]
        let request = ClaudeAPIRequest(
            model: ClaudeAPIConfig.model,
            messages: messages,
            max_tokens: 10,
            stream: false, // Non-streaming for test
            temperature: 0.0,
            system: nil
        )
        
        guard let url = URL(string: ClaudeAPIConfig.baseURL + ClaudeAPIConfig.messagesEndpoint) else {
            return false
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(ClaudeAPIConfig.apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(ClaudeAPIConfig.apiVersion, forHTTPHeaderField: "anthropic-version")
        
        do {
            let encoder = JSONEncoder()
            urlRequest.httpBody = try encoder.encode(request)
            
            let (_, response) = try await URLSession.shared.data(for: urlRequest)
            
            if let httpResponse = response as? HTTPURLResponse {
                logInfo("Claude API test response: \(httpResponse.statusCode)", category: "ClaudeAPI")
                return httpResponse.statusCode == 200
            }
            
        } catch {
            logError("Claude API test failed: \(error)", category: "ClaudeAPI")
        }
        
        return false
    }
    
    // MARK: - SSE Parsing
    
    private func processStreamData(_ data: Data) {
        streamBuffer.append(data)
        bytesReceived += data.count
        
        // Track first byte time for metrics
        if firstByteTime == nil {
            firstByteTime = Date()
            if let startTime = connectionStartTime {
                let ttfb = firstByteTime!.timeIntervalSince(startTime)
                logInfo("⚡ Time to first byte: \(ttfb)s", category: "ClaudeAPI")
            }
        }
        
        // Process complete SSE events from buffer
        while let eventRange = findNextSSEEvent() {
            let eventData = streamBuffer.subdata(in: eventRange)
            
            if let event = parseSSEEvent(eventData) {
                eventsReceived += 1
                handleSSEEvent(event)
            }
            
            // Remove processed data from buffer
            streamBuffer.removeSubrange(0..<eventRange.upperBound)
        }
    }
    
    private func findNextSSEEvent() -> Range<Int>? {
        // SSE events are separated by double newlines
        let doubleNewline = "\n\n".data(using: .utf8)!
        
        if let range = streamBuffer.range(of: doubleNewline) {
            return 0..<(range.upperBound)
        }
        
        return nil
    }
    
    private func parseSSEEvent(_ data: Data) -> ClaudeSSEEvent? {
        guard let string = String(data: data, encoding: .utf8) else { return nil }
        
        var eventType: ClaudeSSEEventType?
        var eventData: [String: Any]?
        
        // Parse SSE format
        let lines = string.components(separatedBy: "\n")
        for line in lines {
            if line.hasPrefix("event: ") {
                let typeString = String(line.dropFirst(7))
                eventType = ClaudeSSEEventType(rawValue: typeString)
            } else if line.hasPrefix("data: ") {
                let dataString = String(line.dropFirst(6))
                if let data = dataString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    eventData = json
                }
            }
        }
        
        if let type = eventType {
            return ClaudeSSEEvent(type: type, data: eventData)
        }
        
        return nil
    }
    
    private func handleSSEEvent(_ event: ClaudeSSEEvent) {
        logInfo("📨 Received SSE event: \(event.type.rawValue)", category: "ClaudeAPI")
        
        // Notify delegate
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.claudeAPI(self, didReceiveEvent: event)
            
            // Extract text content for specific events
            switch event.type {
            case .contentBlockDelta:
                if let delta = event.data?["delta"] as? [String: Any],
                   let text = delta["text"] as? String {
                    self.delegate?.claudeAPI(self, didReceiveText: text)
                }
                
            case .messageStop:
                self.stopStreaming()
                
            case .error:
                if let error = event.data?["error"] as? [String: Any] {
                    logError("Claude API error: \(error)", category: "ClaudeAPI")
                    self.stopStreaming()
                }
                
            default:
                break
            }
        }
    }
}

// MARK: - URLSessionDataDelegate
extension ClaudeAPIManager: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        processStreamData(data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            logError("Claude API stream error: \(error)", category: "ClaudeAPI")
            delegate?.claudeAPIDidDisconnect(self, error: error)
        }
        
        stopStreaming()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        if let httpResponse = response as? HTTPURLResponse {
            logInfo("Claude API response status: \(httpResponse.statusCode)", category: "ClaudeAPI")
            
            if httpResponse.statusCode == 200 {
                completionHandler(.allow)
            } else {
                logError("Claude API error response: \(httpResponse.statusCode)", category: "ClaudeAPI")
                completionHandler(.cancel)
                delegate?.claudeAPIDidDisconnect(self, error: ClaudeAPIError.httpError(httpResponse.statusCode))
            }
        } else {
            completionHandler(.allow)
        }
    }
}

// MARK: - Claude API Errors
enum ClaudeAPIError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case httpError(Int)
    case streamingError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Claude API key not configured"
        case .invalidURL:
            return "Invalid Claude API URL"
        case .httpError(let code):
            return "Claude API HTTP error: \(code)"
        case .streamingError(let message):
            return "Claude API streaming error: \(message)"
        }
    }
}