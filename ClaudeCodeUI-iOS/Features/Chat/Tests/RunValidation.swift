#!/usr/bin/env swift

//
//  RunValidation.swift
//  ClaudeCodeUI
//
//  Standalone validation runner for the 9 refactored chat components
//

import Foundation
import UIKit

// Since we need to run this as a script, we'll create a simplified version
// that can execute without XCTest

print("=" * 60)
print("🚀 CHAT COMPONENT VALIDATION")
print("=" * 60)
print("Testing all 9 refactored components...\n")

// Component validation results
var results: [String: Bool] = [:]

// Test 1: ChatViewModel
print("1️⃣ Testing ChatViewModel...")
if let viewModelClass = NSClassFromString("ChatViewModel") {
    print("   ✅ ChatViewModel class found")
    results["ChatViewModel"] = true
} else {
    print("   ❌ ChatViewModel class not found")
    results["ChatViewModel"] = false
}

// Test 2: ChatTableViewHandler
print("2️⃣ Testing ChatTableViewHandler...")
if let handlerClass = NSClassFromString("ChatTableViewHandler") {
    print("   ✅ ChatTableViewHandler class found")
    results["ChatTableViewHandler"] = true
} else {
    print("   ❌ ChatTableViewHandler class not found")
    results["ChatTableViewHandler"] = false
}

// Test 3: ChatInputHandler
print("3️⃣ Testing ChatInputHandler...")
if let inputClass = NSClassFromString("ChatInputHandler") {
    print("   ✅ ChatInputHandler class found")
    results["ChatInputHandler"] = true
} else {
    print("   ❌ ChatInputHandler class not found")
    results["ChatInputHandler"] = false
}

// Test 4: ChatWebSocketCoordinator
print("4️⃣ Testing ChatWebSocketCoordinator...")
if let wsClass = NSClassFromString("ChatWebSocketCoordinator") {
    print("   ✅ ChatWebSocketCoordinator class found")
    results["ChatWebSocketCoordinator"] = true
} else {
    print("   ❌ ChatWebSocketCoordinator class not found")
    results["ChatWebSocketCoordinator"] = false
}

// Test 5: ChatMessageProcessor
print("5️⃣ Testing ChatMessageProcessor...")
if let processorClass = NSClassFromString("ChatMessageProcessor") {
    print("   ✅ ChatMessageProcessor class found")
    results["ChatMessageProcessor"] = true
} else {
    print("   ❌ ChatMessageProcessor class not found")
    results["ChatMessageProcessor"] = false
}

// Test 6: ChatStateManager
print("6️⃣ Testing ChatStateManager...")
if let stateClass = NSClassFromString("ChatStateManager") {
    print("   ✅ ChatStateManager class found")
    results["ChatStateManager"] = true
} else {
    print("   ❌ ChatStateManager class not found")
    results["ChatStateManager"] = false
}

// Test 7: ChatAttachmentHandler
print("7️⃣ Testing ChatAttachmentHandler...")
if let attachmentClass = NSClassFromString("ChatAttachmentHandler") {
    print("   ✅ ChatAttachmentHandler class found")
    results["ChatAttachmentHandler"] = true
} else {
    print("   ❌ ChatAttachmentHandler class not found")
    results["ChatAttachmentHandler"] = false
}

// Test 8: StreamingMessageHandler
print("8️⃣ Testing StreamingMessageHandler...")
if let streamingClass = NSClassFromString("StreamingMessageHandler") {
    print("   ✅ StreamingMessageHandler class found")
    results["StreamingMessageHandler"] = true
} else {
    print("   ❌ StreamingMessageHandler class not found")
    results["StreamingMessageHandler"] = false
}

// Test 9: Cell Implementations
print("9️⃣ Testing Cell Implementations...")
let cellsExist = NSClassFromString("ChatMessageCell") != nil &&
                 NSClassFromString("ChatTypingIndicatorCell") != nil &&
                 NSClassFromString("ChatDateHeaderView") != nil
if cellsExist {
    print("   ✅ All cell implementations found")
    results["CellImplementations"] = true
} else {
    print("   ❌ Some cell implementations missing")
    results["CellImplementations"] = false
}

// Summary
print("\n" + "=" * 60)
print("📊 VALIDATION SUMMARY")
print("=" * 60)

let passed = results.values.filter { $0 }.count
let failed = results.values.filter { !$0 }.count

print("✅ Passed: \(passed)/9 components")
print("❌ Failed: \(failed)/9 components")

if failed > 0 {
    print("\n⚠️ Components needing attention:")
    for (component, status) in results where !status {
        print("   - \(component)")
    }
}

print("=" * 60)

// Helper extension
extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}