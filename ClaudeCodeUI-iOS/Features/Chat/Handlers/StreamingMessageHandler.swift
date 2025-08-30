//
//  StreamingMessageHandler.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-30.
//  Handles streaming message updates and partial content rendering
//

import UIKit
import Combine

// MARK: - StreamingMessageHandler

/// Manages streaming message updates, partial content, and progressive rendering
@MainActor
final class StreamingMessageHandler {
    
    // MARK: - Properties
    
    weak var viewModel: ChatViewModel?
    weak var tableView: UITableView?
    
    private var streamingMessages: [String: StreamingMessage] = [:]
    private var updateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Configuration
    private let updateInterval: TimeInterval = 0.1 // 100ms updates
    private let maxBufferSize = 5000 // Characters before forced flush
    
    // MARK: - Models
    
    private struct StreamingMessage {
        let id: String
        var content: String
        var chunks: [String]
        var lastUpdate: Date
        var isComplete: Bool
        var metadata: StreamingMetadata
    }
    
    struct StreamingMetadata {
        var tokenCount: Int = 0
        var chunkCount: Int = 0
        var startTime: Date
        var endTime: Date?
        var averageChunkSize: Double = 0
        var streamingRate: Double = 0 // tokens per second
    }
    
    // MARK: - Initialization
    
    init(viewModel: ChatViewModel? = nil, tableView: UITableView? = nil) {
        self.viewModel = viewModel
        self.tableView = tableView
        setupTimer()
    }
    
    deinit {
        updateTimer?.invalidate()
        cancellables.forEach { $0.cancel() }
    }
    
    // MARK: - Setup
    
    private func setupTimer() {
        updateTimer = Timer.scheduledTimer(
            withTimeInterval: updateInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.processStreamingUpdates()
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Reset the handler's state
    func reset() {
        streamingMessages.removeAll()
        updateTimer?.invalidate()
        updateTimer = nil
        cancellables.removeAll()
    }
    
    /// Process a streaming chunk
    func processStreamingChunk(_ chunk: String, for messageId: String) {
        addChunk(chunk, to: messageId)
    }
    
    /// Extract structured content from a message
    func extractStructuredContent(from text: String) -> String {
        // Basic extraction logic - can be enhanced
        return text
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Streaming Operations
    
    /// Start streaming a new message
    func startStreaming(messageId: String) {
        print("🌊 Starting stream for message: \(messageId)")
        
        streamingMessages[messageId] = StreamingMessage(
            id: messageId,
            content: "",
            chunks: [],
            lastUpdate: Date(),
            isComplete: false,
            metadata: StreamingMetadata(startTime: Date())
        )
        
        // Show typing indicator
        viewModel?.isTyping = true
    }
    
    /// Add a chunk to the streaming message
    func addChunk(_ chunk: String, to messageId: String) {
        guard var message = streamingMessages[messageId] else {
            // Start new stream if not exists
            startStreaming(messageId: messageId)
            addChunk(chunk, to: messageId)
            return
        }
        
        // Update streaming message
        message.chunks.append(chunk)
        message.content += chunk
        message.lastUpdate = Date()
        message.metadata.chunkCount += 1
        message.metadata.tokenCount += estimateTokens(in: chunk)
        
        // Calculate streaming rate
        let elapsed = Date().timeIntervalSince(message.metadata.startTime)
        message.metadata.streamingRate = Double(message.metadata.tokenCount) / max(elapsed, 0.1)
        
        streamingMessages[messageId] = message
        
        // Force update if buffer is large
        if message.content.count > maxBufferSize {
            updateStreamingMessage(messageId)
        }
    }
    
    /// Complete the streaming for a message
    func completeStreaming(messageId: String) {
        guard var message = streamingMessages[messageId] else { return }
        
        print("✅ Completing stream for message: \(messageId)")
        
        message.isComplete = true
        message.metadata.endTime = Date()
        streamingMessages[messageId] = message
        
        // Final update
        updateStreamingMessage(messageId)
        
        // Clean up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.streamingMessages.removeValue(forKey: messageId)
            
            // Hide typing indicator if no more streams
            if self?.streamingMessages.isEmpty ?? true {
                self?.viewModel?.isTyping = false
            }
        }
    }
    
    /// Cancel streaming for a message
    func cancelStreaming(messageId: String) {
        print("❌ Cancelling stream for message: \(messageId)")
        
        streamingMessages.removeValue(forKey: messageId)
        
        // Hide typing indicator if no more streams
        if streamingMessages.isEmpty {
            viewModel?.isTyping = false
        }
    }
    
    // MARK: - Private Methods
    
    private func processStreamingUpdates() {
        let now = Date()
        
        for (messageId, message) in streamingMessages {
            // Update if enough time has passed or message is complete
            let timeSinceLastUpdate = now.timeIntervalSince(message.lastUpdate)
            
            if timeSinceLastUpdate > updateInterval || message.isComplete {
                updateStreamingMessage(messageId)
            }
        }
    }
    
    @MainActor
    private func updateStreamingMessage(_ messageId: String) {
        guard let message = streamingMessages[messageId] else { return }
        
        // Update view model
        viewModel?.updateStreamingContent(
            messageId: messageId,
            content: message.content,
            isComplete: message.isComplete
        )
        
        // Update table view cell if visible
        updateVisibleCell(for: messageId)
    }
    
    @MainActor
    private func updateVisibleCell(for messageId: String) {
        guard let tableView = tableView,
              let messages = viewModel?.messages,
              let index = messages.firstIndex(where: { $0.id == messageId }) else {
            return
        }
        
        let indexPath = IndexPath(row: index, section: 0)
        
        // Check if cell is visible
        if tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false {
            // Reload specific cell with animation
            UIView.performWithoutAnimation {
                tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }
    
    private func estimateTokens(in text: String) -> Int {
        // Rough estimation: ~4 characters per token
        return max(1, text.count / 4)
    }
    
    // MARK: - Public Utilities
    
    /// Get streaming metadata for a message
    func getMetadata(for messageId: String) -> StreamingMetadata? {
        return streamingMessages[messageId]?.metadata
    }
    
    /// Check if a message is currently streaming
    func isStreaming(_ messageId: String) -> Bool {
        return streamingMessages[messageId] != nil
    }
    
    /// Get current streaming content
    func getStreamingContent(for messageId: String) -> String? {
        return streamingMessages[messageId]?.content
    }
    
    /// Clear all streaming messages
    @MainActor
    func clearAll() {
        streamingMessages.removeAll()
        viewModel?.isTyping = false
    }
}

// MARK: - ViewModel Extension

extension ChatViewModel {
    
    /// Update streaming content for a message
    func updateStreamingContent(messageId: String, content: String, isComplete: Bool) {
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else {
            // Create new message if doesn't exist
            let newMessage = ChatMessage(
                id: messageId,
                content: content,
                isUser: false,  // Assistant message
                timestamp: Date(),
                status: isComplete ? MessageStatus.delivered : MessageStatus.sending
            )
            messages.append(newMessage)
            return
        }
        
        // Update existing message
        messages[index].content = content
        messages[index].status = isComplete ? MessageStatus.delivered : MessageStatus.sending
    }
}

// MARK: - Streaming Protocol

protocol StreamingDelegate: AnyObject {
    func streamingDidStart(messageId: String)
    func streamingDidUpdate(messageId: String, content: String)
    func streamingDidComplete(messageId: String)
    func streamingDidFail(messageId: String, error: Error)
}

// MARK: - Streaming Renderer

/// Handles progressive rendering of streaming content with markdown support
final class StreamingContentRenderer {
    
    private let markdownParser = MarkdownParser()
    private var renderCache: [String: NSAttributedString] = [:]
    
    /// Render streaming content with partial markdown support
    func renderContent(_ content: String, isComplete: Bool) -> NSAttributedString {
        // Check cache
        if let cached = renderCache[content], isComplete {
            return cached
        }
        
        // Parse markdown progressively
        let attributed = markdownParser.parseStreaming(
            content,
            isComplete: isComplete
        )
        
        // Cache if complete
        if isComplete {
            renderCache[content] = attributed
        }
        
        return attributed
    }
    
    /// Clear render cache
    func clearCache() {
        renderCache.removeAll()
    }
}

// MARK: - Markdown Parser

private class MarkdownParser {
    
    /// Parse markdown with streaming support (partial content)
    func parseStreaming(_ text: String, isComplete: Bool) -> NSAttributedString {
        let attributed = NSMutableAttributedString()
        
        // Basic attributes
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: CyberpunkTheme.textPrimary
        ]
        
        // Split into lines for processing
        let lines = text.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            // Skip incomplete lines unless it's the last line
            if !isComplete && index == lines.count - 1 && !line.isEmpty {
                // Show partial line with typing indicator
                let partial = NSAttributedString(
                    string: line + "█",
                    attributes: baseAttributes
                )
                attributed.append(partial)
            } else {
                // Process complete lines
                let processed = processMarkdownLine(line, attributes: baseAttributes)
                attributed.append(processed)
                
                if index < lines.count - 1 {
                    attributed.append(NSAttributedString(string: "\n"))
                }
            }
        }
        
        return attributed
    }
    
    private func processMarkdownLine(_ line: String, attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        // Headers
        if line.hasPrefix("# ") {
            var headerAttributes = attributes
            headerAttributes[.font] = UIFont.boldSystemFont(ofSize: 24)
            result.append(NSAttributedString(string: String(line.dropFirst(2)), attributes: headerAttributes))
        }
        // Code blocks
        else if line.hasPrefix("```") {
            var codeAttributes = attributes
            codeAttributes[.font] = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
            codeAttributes[.backgroundColor] = CyberpunkTheme.surface
            result.append(NSAttributedString(string: line, attributes: codeAttributes))
        }
        // Bold
        else if line.contains("**") {
            result.append(processBold(line, attributes: attributes))
        }
        // Regular line
        else {
            result.append(NSAttributedString(string: line, attributes: attributes))
        }
        
        return result
    }
    
    private func processBold(_ text: String, attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let components = text.components(separatedBy: "**")
        
        for (index, component) in components.enumerated() {
            var attrs = attributes
            if index % 2 == 1 {
                // Bold text
                attrs[.font] = UIFont.boldSystemFont(ofSize: 16)
            }
            result.append(NSAttributedString(string: component, attributes: attrs))
        }
        
        return result
    }
}