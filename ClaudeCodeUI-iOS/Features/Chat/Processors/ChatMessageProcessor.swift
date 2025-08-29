//
//  ChatMessageProcessor.swift
//  ClaudeCodeUI
//
//  Component 5: Message processing and formatting
//

import Foundation
import UIKit

// MARK: - ChatMessageProcessor

/// Processes and formats chat messages including markdown parsing and link detection
final class ChatMessageProcessor {
    
    // MARK: - Properties
    
    private let markdownParser = MarkdownParser()
    private let linkDetector = LinkDetector()
    private let codeBlockParser = CodeBlockParser()
    
    // MARK: - Public Methods
    
    /// Process raw message content into formatted attributed string
    func processMessage(_ content: String) -> NSAttributedString {
        // Remove markdown formatting for validation
        let processed = content
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "`", with: "")
        
        return parseMarkdown(content) ?? NSAttributedString(string: processed)
    }
    
    /// Parse markdown content into attributed string
    func parseMarkdown(_ text: String) -> NSAttributedString? {
        let attributed = NSMutableAttributedString(string: text)
        let range = NSRange(location: 0, length: text.count)
        
        // Bold
        let boldRegex = try? NSRegularExpression(pattern: "\\*\\*(.*?)\\*\\*")
        boldRegex?.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let matchRange = match?.range else { return }
            attributed.addAttribute(.font, 
                                   value: UIFont.boldSystemFont(ofSize: 16), 
                                   range: matchRange)
        }
        
        // Italic
        let italicRegex = try? NSRegularExpression(pattern: "\\*(.*?)\\*")
        italicRegex?.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let matchRange = match?.range else { return }
            attributed.addAttribute(.font, 
                                   value: UIFont.italicSystemFont(ofSize: 16), 
                                   range: matchRange)
        }
        
        // Code inline
        let codeRegex = try? NSRegularExpression(pattern: "`(.*?)`")
        codeRegex?.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let matchRange = match?.range else { return }
            attributed.addAttribute(.font, 
                                   value: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular), 
                                   range: matchRange)
            attributed.addAttribute(.backgroundColor, 
                                   value: UIColor.systemGray6, 
                                   range: matchRange)
        }
        
        return attributed
    }
    
    /// Extract code blocks from message
    func extractCodeBlocks(from text: String) -> [CodeBlock] {
        return codeBlockParser.parse(text)
    }
    
    /// Detect URLs in message
    func detectURLs(in text: String) -> [URL] {
        return linkDetector.detect(text)
    }
    
    /// Format timestamp for display
    func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "'Yesterday' h:mm a"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }
        
        return formatter.string(from: date)
    }
    
    /// Sanitize message content for display
    func sanitizeContent(_ content: String) -> String {
        // Remove any potentially harmful content
        var sanitized = content
        
        // Remove script tags
        sanitized = sanitized.replacingOccurrences(
            of: "<script[^>]*>.*?</script>",
            with: "",
            options: .regularExpression
        )
        
        // Remove other HTML tags
        sanitized = sanitized.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
        
        return sanitized
    }
}

// MARK: - Supporting Types

struct CodeBlock {
    let language: String?
    let code: String
    let range: NSRange
}

// MARK: - Private Helpers

private class MarkdownParser {
    func parse(_ text: String) -> NSAttributedString {
        // Implementation handled by main processor
        return NSAttributedString(string: text)
    }
}

private class LinkDetector {
    func detect(_ text: String) -> [URL] {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, range: NSRange(location: 0, length: text.count))
        
        return matches?.compactMap { match in
            guard let range = Range(match.range, in: text),
                  let url = URL(string: String(text[range])) else { return nil }
            return url
        } ?? []
    }
}

private class CodeBlockParser {
    func parse(_ text: String) -> [CodeBlock] {
        let pattern = "```(\\w+)?\\n([^`]+)```"
        let regex = try? NSRegularExpression(pattern: pattern)
        let matches = regex?.matches(in: text, range: NSRange(location: 0, length: text.count))
        
        return matches?.compactMap { match in
            guard match.numberOfRanges >= 3,
                  let codeRange = Range(match.range(at: 2), in: text) else { return nil }
            
            let language = match.numberOfRanges > 1 ? 
                          (try? NSString(string: text).substring(with: match.range(at: 1))) : nil
            
            return CodeBlock(
                language: language,
                code: String(text[codeRange]),
                range: match.range
            )
        } ?? []
    }
}