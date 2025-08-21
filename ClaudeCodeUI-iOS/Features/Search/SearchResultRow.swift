//
//  SearchResultRow.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-21.
//

import SwiftUI

struct SearchResultRow: View {
    let result: SearchResult
    let searchText: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // File header
            Button(action: { withAnimation(.spring(response: 0.3)) { isExpanded.toggle() } }) {
                HStack {
                    // File icon
                    Image(systemName: result.fileIcon)
                        .font(.system(size: 16))
                        .foregroundColor(Color(UIColor.CyberpunkTheme.primaryCyan))
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // File name with highlighting
                        Text(result.fileName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(UIColor.CyberpunkTheme.textPrimary))
                        
                        // File path
                        Text(result.filePath)
                            .font(.system(size: 12))
                            .foregroundColor(Color(UIColor.CyberpunkTheme.textTertiary))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Match count badge
                    HStack(spacing: 4) {
                        Text("\(result.matchCount)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                        Text(result.matchCount == 1 ? "match" : "matches")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(Color(UIColor.CyberpunkTheme.primaryPink))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(UIColor.CyberpunkTheme.primaryPink).opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(Color(UIColor.CyberpunkTheme.primaryPink).opacity(0.3), lineWidth: 1)
                            )
                    )
                    
                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(Color(UIColor.CyberpunkTheme.textTertiary))
                        .padding(.leading, 8)
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
            
            // Match preview (if not expanded)
            if !isExpanded, let preview = result.matchPreview {
                HStack {
                    Rectangle()
                        .fill(Color(UIColor.CyberpunkTheme.primaryCyan).opacity(0.3))
                        .frame(width: 3)
                    
                    highlightedText(preview, searchText: searchText)
                        .font(.system(size: 12, design: .monospaced))
                        .lineLimit(2)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                    
                    Spacer()
                }
                .padding(.leading, 24)
                .padding(.trailing)
            }
            
            // Expanded matches
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(result.matches) { match in
                        SearchMatchRow(match: match, searchText: searchText)
                    }
                }
                .padding(.top, 8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.CyberpunkTheme.surface))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isExpanded ?
                            Color(UIColor.CyberpunkTheme.primaryCyan).opacity(0.3) :
                            Color(UIColor.CyberpunkTheme.border),
                            lineWidth: 1
                        )
                )
        )
        .padding(.horizontal)
        .shadow(
            color: isExpanded ? Color(UIColor.CyberpunkTheme.primaryCyan).opacity(0.2) : Color.clear,
            radius: 8,
            y: 2
        )
    }
    
    private func highlightedText(_ text: String, searchText: String) -> some View {
        let attributedString = NSMutableAttributedString(string: text)
        let range = NSString(string: text).range(of: searchText, options: .caseInsensitive)
        
        if range.location != NSNotFound {
            attributedString.addAttribute(.foregroundColor, 
                                         value: UIColor.CyberpunkTheme.primaryCyan,
                                         range: range)
            attributedString.addAttribute(.font,
                                         value: UIFont.systemFont(ofSize: 12, weight: .bold),
                                         range: range)
        }
        
        return Text(AttributedString(attributedString))
            .foregroundColor(Color(UIColor.CyberpunkTheme.textSecondary))
    }
}

struct SearchMatchRow: View {
    let match: SearchMatch
    let searchText: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Line number
            Text("\(match.lineNumber)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(Color(UIColor.CyberpunkTheme.textTertiary))
                .frame(minWidth: 40, alignment: .trailing)
            
            VStack(alignment: .leading, spacing: 4) {
                // Context before (if available)
                if let contextBefore = match.contextBefore {
                    Text(contextBefore)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color(UIColor.CyberpunkTheme.textTertiary).opacity(0.7))
                        .lineLimit(1)
                }
                
                // Main matched line with highlighting
                highlightedLine(match.lineContent, searchText: searchText)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(.vertical, 2)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(UIColor.CyberpunkTheme.primaryCyan).opacity(0.1))
                    )
                
                // Context after (if available)
                if let contextAfter = match.contextAfter {
                    Text(contextAfter)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color(UIColor.CyberpunkTheme.textTertiary).opacity(0.7))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Column indicator
            if match.columnNumber > 0 {
                Text("col \(match.columnNumber)")
                    .font(.system(size: 10))
                    .foregroundColor(Color(UIColor.CyberpunkTheme.textTertiary).opacity(0.5))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            Color(UIColor.CyberpunkTheme.background).opacity(0.3)
        )
    }
    
    private func highlightedLine(_ text: String, searchText: String) -> some View {
        let components = text.components(separatedBy: searchText)
        let lastIndex = components.count - 1
        
        return HStack(spacing: 0) {
            ForEach(0..<components.count, id: \.self) { index in
                Text(components[index])
                    .foregroundColor(Color(UIColor.CyberpunkTheme.textPrimary))
                
                if index < lastIndex {
                    Text(searchText)
                        .foregroundColor(Color(UIColor.CyberpunkTheme.primaryCyan))
                        .fontWeight(.bold)
                        .background(
                            Color(UIColor.CyberpunkTheme.primaryCyan).opacity(0.2)
                                .cornerRadius(2)
                        )
                }
            }
        }
    }
}

// MARK: - Preview Provider

struct SearchResultRow_Previews: PreviewProvider {
    static var previews: some View {
        let sampleResult = SearchResult(
            fileName: "ChatViewController.swift",
            filePath: "Features/Chat/",
            fileType: "swift",
            matchCount: 3,
            matches: [
                SearchMatch(
                    lineNumber: 42,
                    columnNumber: 15,
                    lineContent: "    func handleWebSocketMessage(_ message: String) {",
                    contextBefore: "    // WebSocket handler",
                    contextAfter: "        guard let data = message.data(using: .utf8) else { return }"
                ),
                SearchMatch(
                    lineNumber: 156,
                    columnNumber: 8,
                    lineContent: "        webSocketManager.send(message: messageText)",
                    contextBefore: nil,
                    contextAfter: nil
                )
            ],
            matchPreview: "    func handleWebSocketMessage(_ message: String) {"
        )
        
        ZStack {
            Color(UIColor.CyberpunkTheme.background)
                .ignoresSafeArea()
            
            VStack {
                SearchResultRow(result: sampleResult, searchText: "message")
                    .padding(.vertical)
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}