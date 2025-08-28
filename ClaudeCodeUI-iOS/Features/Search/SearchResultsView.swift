//
//  SearchResultsView.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-16.
//

import SwiftUI

struct SearchResultRowInline: View {
    let result: SearchResult
    let searchText: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main result row
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    // File type icon
                    Image(systemName: result.fileIcon)
                        .font(.system(size: 20))
                        .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // File name with path
                        Text(result.fileName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(CyberpunkTheme.textPrimary))
                        
                        Text(result.filePath)
                            .font(.system(size: 11))
                            .foregroundColor(Color(CyberpunkTheme.tertiaryText))
                            .lineLimit(1)
                        
                        // Match preview with highlighting
                        if let preview = result.matchPreview {
                            HighlightedText(
                                text: preview,
                                highlight: searchText,
                                textColor: Color(CyberpunkTheme.textSecondary),
                                highlightColor: Color(CyberpunkTheme.warning)
                            )
                            .font(.system(size: 12, design: .monospaced))
                            .lineLimit(2)
                            .padding(.top, 4)
                        }
                    }
                    
                    Spacer()
                    
                    // Match count and chevron
                    VStack(alignment: .trailing, spacing: 4) {
                        if result.matchCount > 1 {
                            Text("\(result.matchCount)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(CyberpunkTheme.primaryCyan).opacity(0.2))
                                )
                        }
                        
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(Color(CyberpunkTheme.tertiaryText))
                    }
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded content with all matches
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(result.matches) { match in
                        SearchMatchView(match: match, searchText: searchText)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .background(
                    Color(CyberpunkTheme.background)
                        .opacity(0.5)
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(CyberpunkTheme.surface))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isExpanded ?
                            Color(CyberpunkTheme.primaryCyan).opacity(0.3) :
                            Color(CyberpunkTheme.border),
                            lineWidth: 1
                        )
                )
        )
        .padding(.horizontal)
    }
}

struct SearchMatchView: View {
    let match: SearchMatch
    let searchText: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Line number
            Text("L\(match.lineNumber)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(Color(CyberpunkTheme.tertiaryText))
                .frame(width: 40, alignment: .trailing)
            
            // Match content with context
            VStack(alignment: .leading, spacing: 2) {
                if let contextBefore = match.contextBefore {
                    Text(contextBefore)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color(CyberpunkTheme.tertiaryText))
                }
                
                HighlightedText(
                    text: match.lineContent,
                    highlight: searchText,
                    textColor: Color(CyberpunkTheme.textPrimary),
                    highlightColor: Color(CyberpunkTheme.warning),
                    backgroundColor: Color(CyberpunkTheme.warning).opacity(0.1)
                )
                .font(.system(size: 12, design: .monospaced))
                
                if let contextAfter = match.contextAfter {
                    Text(contextAfter)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color(CyberpunkTheme.tertiaryText))
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(CyberpunkTheme.surface).opacity(0.5))
        )
    }
}

struct HighlightedText: View {
    let text: String
    let highlight: String
    let textColor: Color
    let highlightColor: Color
    var backgroundColor: Color? = nil
    
    var body: some View {
        let parts = text.components(separatedBy: highlight)
        let result = parts.enumerated().reduce(Text("")) { result, item in
            let (index, part) = item
            var newResult = result + Text(part).foregroundColor(textColor)
            
            // Add highlight between parts (except after the last part)
            if index < parts.count - 1 {
                newResult = newResult + Text(highlight)
                    .foregroundColor(highlightColor)
                    .bold()
                    .background(backgroundColor ?? Color.clear)
            }
            
            return newResult
        }
        
        return result
    }
}