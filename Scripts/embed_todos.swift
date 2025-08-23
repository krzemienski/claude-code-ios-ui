#!/usr/bin/env swift

import Foundation

// Script to embed TODO markers into iOS source files for Context Manager coordination

struct TodoMarker {
    let file: String
    let lineNumber: Int
    let todoId: String
    let description: String
    let acceptance: String
    let priority: String
    let dependencies: String?
    let notes: String?
}

let todoMarkers = [
    // Chat View Controller TODOs
    TodoMarker(
        file: "ClaudeCodeUI-iOS/Features/Chat/ChatViewController.swift",
        lineNumber: 1420,
        todoId: "CM-Chat-01",
        description: "Add real-time message status indicators",
        acceptance: "Display sending → sent → delivered → failed states",
        priority: "P1",
        dependencies: "StreamingMessageHandler.swift",
        notes: "Use status enum: .sending, .sent, .delivered, .failed"
    ),
    TodoMarker(
        file: "ClaudeCodeUI-iOS/Features/Chat/ChatViewController.swift",
        lineNumber: 1460,
        todoId: "CM-Chat-02",
        description: "Implement typing indicator animation",
        acceptance: "Show 'Claude is typing...' with dots animation",
        priority: "P1",
        dependencies: "WebSocketManager message types",
        notes: "Add typing indicator view below last message"
    ),
    TodoMarker(
        file: "ClaudeCodeUI-iOS/Features/Chat/ChatViewController.swift",
        lineNumber: 350,
        todoId: "CM-Chat-03",
        description: "Add pull-to-refresh with haptic feedback",
        acceptance: "Cyberpunk-themed refresh control, haptic on trigger",
        priority: "P1",
        dependencies: "CyberpunkTheme.swift",
        notes: "Use UIImpactFeedbackGenerator for haptics"
    ),
    
    // Terminal View Controller TODOs
    TodoMarker(
        file: "ClaudeCodeUI-iOS/Features/Terminal/TerminalViewController.swift",
        lineNumber: 150,
        todoId: "CM-Term-01",
        description: "Verify ShellWebSocketManager connection",
        acceptance: "Connects to ws://192.168.0.43:3004/shell successfully",
        priority: "P1",
        dependencies: nil,
        notes: "Test with 'ls -la' command"
    ),
    TodoMarker(
        file: "ClaudeCodeUI-iOS/Features/Terminal/TerminalViewController.swift",
        lineNumber: 450,
        todoId: "CM-Term-02",
        description: "Test ANSI color rendering",
        acceptance: "All 16 colors + bright variants display correctly",
        priority: "P1",
        dependencies: "ANSIColorParser.swift",
        notes: "Use comprehensive color test string"
    ),
    
    // Search View Model TODOs
    TodoMarker(
        file: "ClaudeCodeUI-iOS/Features/Search/SearchViewModel.swift",
        lineNumber: 125,
        todoId: "CM-Search-01",
        description: "Replace mock data with API call",
        acceptance: "Real search results from backend",
        priority: "P1",
        dependencies: nil,
        notes: "Endpoint: POST /api/projects/:projectName/search"
    ),
    TodoMarker(
        file: "ClaudeCodeUI-iOS/Features/Search/SearchViewModel.swift",
        lineNumber: 200,
        todoId: "CM-Search-02",
        description: "Implement search result caching",
        acceptance: "Cache for 5 minutes, invalidate on project change",
        priority: "P1",
        dependencies: nil,
        notes: "Cache key: {projectName}_{query}_{scope}"
    ),
    
    // UI Component TODOs
    TodoMarker(
        file: "ClaudeCodeUI-iOS/UI/Components/SkeletonView.swift",
        lineNumber: 1,
        todoId: "CM-UI-01",
        description: "Create base SkeletonView component",
        acceptance: "Reusable skeleton with shimmer animation",
        priority: "P2",
        dependencies: nil,
        notes: "Use gradient animation for shimmer effect"
    ),
]

func formatTodoComment(_ marker: TodoMarker) -> String {
    var comment = """
    // TODO[\(marker.todoId)]: \(marker.description)
    // ACCEPTANCE: \(marker.acceptance)
    // PRIORITY: \(marker.priority)
    """
    
    if let deps = marker.dependencies {
        comment += "\n// DEPENDENCIES: \(deps)"
    }
    
    if let notes = marker.notes {
        comment += "\n// NOTES: \(notes)"
    }
    
    return comment
}

func embedTodoMarker(_ marker: TodoMarker) {
    let projectRoot = "/Users/nick/Documents/claude-code-ios-ui/"
    let fullPath = projectRoot + marker.file
    
    print("Processing: \(marker.file)")
    print("  TODO ID: \(marker.todoId)")
    print("  Line: \(marker.lineNumber)")
    
    // For this script, we'll just output the formatted TODOs
    // In production, we'd read the file, insert at line number, and write back
    
    let formattedTodo = formatTodoComment(marker)
    print("  Formatted TODO:")
    print(formattedTodo.split(separator: "\n").map { "    \($0)" }.joined(separator: "\n"))
    print("")
}

// Main execution
print("=== iOS Claude Code UI - TODO Embedding Script ===")
print("Total TODOs to embed: \(todoMarkers.count)")
print("")

for marker in todoMarkers {
    embedTodoMarker(marker)
}

print("=== Summary ===")
let groupedByFile = Dictionary(grouping: todoMarkers, by: { $0.file })
for (file, markers) in groupedByFile.sorted(by: { $0.key < $1.key }) {
    print("\(file): \(markers.count) TODOs")
}

print("\nNote: This script outputs formatted TODOs. To actually embed them,")
print("the iOS Developer Agent should insert these at the specified line numbers.")
print("\nNext steps:")
print("1. iOS Developer Agent reviews TODO markers")
print("2. Begins implementation starting with P1 tasks")
print("3. Reports progress using the format: ✅ TODO[CM-XXX-XX] Complete")