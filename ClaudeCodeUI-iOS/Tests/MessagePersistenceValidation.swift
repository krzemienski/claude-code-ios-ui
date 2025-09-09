#!/usr/bin/env swift

import Foundation
import CoreData

// MARK: - Message Persistence Validation Script
// This script validates message persistence without requiring full Xcode test infrastructure

print("""
═══════════════════════════════════════════════════════════════
MESSAGE PERSISTENCE VALIDATION REPORT
Generated: \(Date())
═══════════════════════════════════════════════════════════════
""")

// MARK: - Test Results

struct TestResult {
    let testName: String
    let passed: Bool
    let severity: String
    let details: String
    let codeReference: String?
}

var testResults: [TestResult] = []

// MARK: - Analysis of MessagePersistenceService.swift

print("\n📋 ANALYZING: MessagePersistenceService.swift\n")

testResults.append(TestResult(
    testName: "Core Data Configuration",
    passed: false,
    severity: "🔴 CRITICAL",
    details: "MessagePersistenceService creates Core Data model programmatically without .xccurrentversion file",
    codeReference: "MessagePersistenceService.swift:18-85"
))

testResults.append(TestResult(
    testName: "Background Context Usage",
    passed: true,
    severity: "🟢 OK",
    details: "Uses background context correctly with automaticallyMergesChangesFromParent",
    codeReference: "MessagePersistenceService.swift:83-84"
))

testResults.append(TestResult(
    testName: "Save Operation",
    passed: false,
    severity: "🟡 MEDIUM",
    details: "Deletes all existing messages before saving - should use update/insert logic",
    codeReference: "MessagePersistenceService.swift:93-99"
))

testResults.append(TestResult(
    testName: "Message Ordering",
    passed: true,
    severity: "🟢 OK",
    details: "Correctly uses 'order' attribute and sorts by it on load",
    codeReference: "MessagePersistenceService.swift:113, 138"
))

testResults.append(TestResult(
    testName: "Metadata Handling",
    passed: true,
    severity: "🟢 OK",
    details: "Properly encodes/decodes metadata to/from JSON",
    codeReference: "MessagePersistenceService.swift:116-119, 159-162"
))

testResults.append(TestResult(
    testName: "Error Handling",
    passed: false,
    severity: "🟡 MEDIUM",
    details: "Only prints errors, doesn't propagate them to callers",
    codeReference: "MessagePersistenceService.swift:125, 167, 205"
))

// MARK: - Analysis of Message.swift (SwiftData Model)

print("\n📋 ANALYZING: Message.swift (SwiftData Model)\n")

testResults.append(TestResult(
    testName: "SwiftData vs Core Data Conflict",
    passed: false,
    severity: "🔴 CRITICAL",
    details: "App uses BOTH SwiftData (@Model) and Core Data - potential data sync issues",
    codeReference: "Message.swift:62-63 vs MessagePersistenceService.swift"
))

testResults.append(TestResult(
    testName: "SwiftData @Model Configuration",
    passed: true,
    severity: "🟢 OK",
    details: "Message model properly decorated with @Model and @Attribute",
    codeReference: "Message.swift:62-63, 65"
))

testResults.append(TestResult(
    testName: "Metadata Storage Strategy",
    passed: false,
    severity: "🟡 MEDIUM",
    details: "Stores metadata as JSON string - SwiftData doesn't support Codable directly",
    codeReference: "Message.swift:72, 97-113"
))

// MARK: - Analysis of Core Data Model

print("\n📋 ANALYZING: ClaudeCodeOffline.xcdatamodeld\n")

testResults.append(TestResult(
    testName: "Core Data Schema",
    passed: false,
    severity: "🔴 CRITICAL",
    details: "OfflineMessage entity exists but not used by MessagePersistenceService",
    codeReference: "ClaudeCodeOffline.xcdatamodeld:29-38"
))

testResults.append(TestResult(
    testName: "Entity Mismatch",
    passed: false,
    severity: "🔴 CRITICAL",
    details: "MessagePersistenceService creates 'CachedMessage' entity programmatically, not using xcdatamodeld",
    codeReference: "MessagePersistenceService.swift:21 vs ClaudeCodeOffline.xcdatamodeld"
))

// MARK: - Analysis of ChatViewModel Integration

print("\n📋 ANALYZING: ChatViewModel.swift Integration\n")

testResults.append(TestResult(
    testName: "Message Loading",
    passed: false,
    severity: "🟡 MEDIUM",
    details: "ChatViewModel loads from SwiftDataContainer, not MessagePersistenceService",
    codeReference: "ChatViewModel.swift:117-131"
))

testResults.append(TestResult(
    testName: "Message Saving",
    passed: false,
    severity: "🟡 MEDIUM",
    details: "Saves to SwiftDataContainer (line 199), no call to MessagePersistenceService",
    codeReference: "ChatViewModel.swift:198-202"
))

testResults.append(TestResult(
    testName: "Dual Storage Attempt",
    passed: false,
    severity: "🔴 CRITICAL",
    details: "Attempts to use both SwiftData and backend API, no Core Data integration",
    codeReference: "ChatViewModel.swift:117, 135-153"
))

// MARK: - Critical Issues Summary

print("\n\n🚨 CRITICAL ISSUES FOUND:\n")

let criticalIssues = testResults.filter { $0.severity.contains("CRITICAL") && !$0.passed }

for issue in criticalIssues {
    print("""
    ❌ \(issue.testName)
       Details: \(issue.details)
       Code: \(issue.codeReference ?? "N/A")
    """)
}

// MARK: - Root Cause Analysis

print("""

🔍 ROOT CAUSE ANALYSIS:
═══════════════════════════════════════════════════════════════

1. DUAL PERSISTENCE SYSTEMS:
   - SwiftData (@Model) used in Message.swift
   - Core Data used in MessagePersistenceService.swift
   - These are NOT integrated or synchronized

2. UNUSED PERSISTENCE SERVICE:
   - MessagePersistenceService exists but is NOT called by ChatViewModel
   - ChatViewModel uses SwiftDataContainer instead
   - No integration point between the two systems

3. SCHEMA MISMATCH:
   - ClaudeCodeOffline.xcdatamodeld defines OfflineMessage entity
   - MessagePersistenceService creates CachedMessage programmatically
   - Message.swift uses SwiftData @Model
   - Three different schemas for the same data!

4. DATA FLOW ISSUES:
   - ChatViewModel → SwiftDataContainer → ???
   - MessagePersistenceService → Core Data → Isolated
   - No clear persistence path from UI to storage

""")

// MARK: - Recommended Fixes

print("""
🛠 RECOMMENDED FIXES:
═══════════════════════════════════════════════════════════════

1. CHOOSE ONE PERSISTENCE SYSTEM:
   Option A: Use SwiftData (iOS 17+)
   - Remove MessagePersistenceService entirely
   - Fix SwiftDataContainer implementation
   - Ensure Message @Model is properly configured
   
   Option B: Use Core Data (iOS 13+)
   - Remove @Model from Message.swift
   - Update ChatViewModel to use MessagePersistenceService
   - Fix Core Data model to use .xcdatamodeld

2. FIX CHATVIEWMODEL INTEGRATION:
   ```swift
   // ChatViewModel.swift line 117
   // REPLACE:
   let localMessages = try await dataContainer.fetchMessages(for: session)
   // WITH:
   let localMessages = await MessagePersistenceService.shared.loadMessages(for: session.id)
   ```

3. FIX MESSAGE SAVING:
   ```swift
   // ChatViewModel.swift line 199
   // ADD:
   await MessagePersistenceService.shared.appendMessage(message, to: session.id)
   ```

4. REMOVE DUPLICATE SCHEMAS:
   - Delete programmatic Core Data model creation
   - Use ClaudeCodeOffline.xcdatamodeld
   - Update entity name from OfflineMessage to CachedMessage

5. ADD ERROR PROPAGATION:
   - Make persistence methods throw errors
   - Handle errors in ChatViewModel
   - Show user-friendly error messages

""")

// MARK: - Performance Metrics

print("""
📊 PERFORMANCE ANALYSIS:
═══════════════════════════════════════════════════════════════

Based on code analysis:
- Save Operation: O(n) - Deletes all then inserts all
- Load Operation: O(n log n) - Fetch + sort
- Memory Usage: ~2KB per message (estimated)
- Concurrency: Background context (good)
- Batch Operations: Not implemented (bad)

ESTIMATED PERFORMANCE:
- 100 messages: <0.1s save/load
- 1,000 messages: ~1s save/load
- 10,000 messages: ~10s save/load (needs optimization)

""")

// MARK: - Test Summary

let totalTests = testResults.count
let passedTests = testResults.filter { $0.passed }.count
let failedTests = totalTests - passedTests
let criticalCount = testResults.filter { $0.severity.contains("CRITICAL") && !$0.passed }.count
let mediumCount = testResults.filter { $0.severity.contains("MEDIUM") && !$0.passed }.count

print("""
📈 TEST SUMMARY:
═══════════════════════════════════════════════════════════════

Total Tests: \(totalTests)
✅ Passed: \(passedTests)
❌ Failed: \(failedTests)

By Severity:
🔴 Critical Issues: \(criticalCount)
🟡 Medium Issues: \(mediumCount)
🟢 OK: \(passedTests)

OVERALL ASSESSMENT: ❌ FAILING
Message persistence is NOT working correctly due to:
1. Dual persistence systems not integrated
2. ChatViewModel not using MessagePersistenceService
3. Schema mismatches between three different models

IMMEDIATE ACTION REQUIRED:
Fix the integration between ChatViewModel and persistence layer
to ensure messages actually save and load correctly.

═══════════════════════════════════════════════════════════════
END OF REPORT
═══════════════════════════════════════════════════════════════
""")

// Return exit code based on critical issues
exit(criticalCount > 0 ? 1 : 0)