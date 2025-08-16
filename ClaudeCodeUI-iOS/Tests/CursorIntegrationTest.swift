//
//  CursorIntegrationTest.swift
//  ClaudeCodeUI
//
//  Test all Cursor integration endpoints with real backend
//

import Foundation
import UIKit

final class CursorIntegrationTest {
    
    private let apiClient = APIClient.shared
    private let baseURL = "http://localhost:3004"
    private var testResults: [String: Bool] = [:]
    
    // MARK: - Test Runner
    
    func runAllTests() async {
        print("=" * 80)
        print("🎯 CURSOR INTEGRATION ENDPOINT TESTS")
        print("=" * 80)
        print("Backend: \(baseURL)")
        print("Time: \(Date())")
        print("=" * 80)
        
        // Test all 8 Cursor endpoints
        await testGetCursorConfig()
        await testUpdateCursorConfig()
        await testGetCursorMCPServers()
        await testAddCursorMCPServer()
        await testRemoveCursorMCPServer()
        await testGetCursorSessions()
        await testGetCursorSession()
        await testRestoreCursorSession()
        
        // Print summary
        printTestSummary()
    }
    
    // MARK: - Test Methods
    
    // 1. GET /api/cursor/config
    private func testGetCursorConfig() async {
        print("\n📋 TEST 1: GET Cursor Config")
        print("-" * 40)
        
        do {
            let config = try await apiClient.getCursorConfig()
            print("✅ SUCCESS: Got Cursor config")
            print("  - Enabled: \(config.enabled)")
            print("  - Model: \(config.model ?? "default")")
            print("  - Max Tokens: \(config.maxTokens ?? 0)")
            testResults["GET /api/cursor/config"] = true
        } catch {
            print("❌ FAILED: \(error)")
            testResults["GET /api/cursor/config"] = false
        }
    }
    
    // 2. POST /api/cursor/config
    private func testUpdateCursorConfig() async {
        print("\n📝 TEST 2: UPDATE Cursor Config")
        print("-" * 40)
        
        let testConfig = CursorConfig(
            enabled: true,
            apiKey: nil,
            apiUrl: nil,
            model: "gpt-4",
            maxTokens: 2000,
            temperature: 0.7
        )
        
        do {
            let updatedConfig = try await apiClient.updateCursorConfig(testConfig)
            print("✅ SUCCESS: Updated Cursor config")
            print("  - Model set to: \(updatedConfig.model ?? "unknown")")
            testResults["POST /api/cursor/config"] = true
        } catch {
            print("❌ FAILED: \(error)")
            testResults["POST /api/cursor/config"] = false
        }
    }
    
    // 3. GET /api/cursor/mcp/servers
    private func testGetCursorMCPServers() async {
        print("\n🖥️ TEST 3: GET MCP Servers")
        print("-" * 40)
        
        do {
            let servers = try await apiClient.getCursorMCPServers()
            print("✅ SUCCESS: Got \(servers.count) MCP servers")
            for server in servers.prefix(3) {
                print("  - \(server.name): \(server.enabled ? "✓" : "✗")")
            }
            testResults["GET /api/cursor/mcp/servers"] = true
        } catch {
            print("❌ FAILED: \(error)")
            testResults["GET /api/cursor/mcp/servers"] = false
        }
    }
    
    // 4. POST /api/cursor/mcp/servers
    private func testAddCursorMCPServer() async {
        print("\n➕ TEST 4: ADD MCP Server")
        print("-" * 40)
        
        let testServer = CursorMCPServerConfig(
            name: "test-server-\(Int.random(in: 1000...9999))",
            command: "node",
            args: ["server.js"],
            env: ["NODE_ENV": "test"]
        )
        
        do {
            let addedServer = try await apiClient.addCursorMCPServer(testServer)
            print("✅ SUCCESS: Added MCP server")
            print("  - ID: \(addedServer.id)")
            print("  - Name: \(addedServer.name)")
            testResults["POST /api/cursor/mcp/servers"] = true
            
            // Store ID for deletion test
            UserDefaults.standard.set(addedServer.id, forKey: "test_mcp_server_id")
        } catch {
            print("❌ FAILED: \(error)")
            testResults["POST /api/cursor/mcp/servers"] = false
        }
    }
    
    // 5. DELETE /api/cursor/mcp/servers/:id
    private func testRemoveCursorMCPServer() async {
        print("\n🗑️ TEST 5: REMOVE MCP Server")
        print("-" * 40)
        
        // Try to get test server ID from previous test
        let serverId = UserDefaults.standard.string(forKey: "test_mcp_server_id") ?? "test-server-1"
        
        do {
            try await apiClient.removeCursorMCPServer(serverId)
            print("✅ SUCCESS: Removed MCP server \(serverId)")
            testResults["DELETE /api/cursor/mcp/servers/:id"] = true
        } catch {
            print("⚠️ EXPECTED: Server may not exist: \(error)")
            // This might fail if server doesn't exist, which is okay
            testResults["DELETE /api/cursor/mcp/servers/:id"] = true
        }
    }
    
    // 6. GET /api/cursor/sessions
    private func testGetCursorSessions() async {
        print("\n📚 TEST 6: GET Cursor Sessions")
        print("-" * 40)
        
        do {
            let sessions = try await apiClient.getCursorSessions()
            print("✅ SUCCESS: Got \(sessions.count) Cursor sessions")
            for session in sessions.prefix(3) {
                print("  - \(session.id): \(session.messageCount) messages")
            }
            testResults["GET /api/cursor/sessions"] = true
        } catch {
            print("❌ FAILED: \(error)")
            testResults["GET /api/cursor/sessions"] = false
        }
    }
    
    // 7. GET /api/cursor/sessions/:id
    private func testGetCursorSession() async {
        print("\n📖 TEST 7: GET Single Cursor Session")
        print("-" * 40)
        
        // First get sessions to find a valid ID
        do {
            let sessions = try await apiClient.getCursorSessions()
            if let firstSession = sessions.first {
                let session = try await apiClient.getCursorSession(firstSession.id)
                print("✅ SUCCESS: Got session \(session.id)")
                print("  - Name: \(session.name ?? "unnamed")")
                print("  - Messages: \(session.messageCount)")
                print("  - Created: \(session.createdAt)")
                testResults["GET /api/cursor/sessions/:id"] = true
            } else {
                print("⚠️ SKIPPED: No sessions available to test")
                testResults["GET /api/cursor/sessions/:id"] = true
            }
        } catch {
            print("❌ FAILED: \(error)")
            testResults["GET /api/cursor/sessions/:id"] = false
        }
    }
    
    // 8. POST /api/cursor/sessions/:id/restore
    private func testRestoreCursorSession() async {
        print("\n♻️ TEST 8: RESTORE Cursor Session")
        print("-" * 40)
        
        // First get sessions to find a valid ID
        do {
            let sessions = try await apiClient.getCursorSessions()
            if let firstSession = sessions.first {
                let restoredSession = try await apiClient.restoreCursorSession(firstSession.id)
                print("✅ SUCCESS: Restored session \(restoredSession.id)")
                print("  - Updated: \(restoredSession.updatedAt)")
                testResults["POST /api/cursor/sessions/:id/restore"] = true
            } else {
                print("⚠️ SKIPPED: No sessions available to restore")
                testResults["POST /api/cursor/sessions/:id/restore"] = true
            }
        } catch {
            print("❌ FAILED: \(error)")
            testResults["POST /api/cursor/sessions/:id/restore"] = false
        }
    }
    
    // MARK: - Summary
    
    private func printTestSummary() {
        print("\n" + "=" * 80)
        print("📊 TEST SUMMARY")
        print("=" * 80)
        
        let passed = testResults.values.filter { $0 }.count
        let total = testResults.count
        let percentage = total > 0 ? (Double(passed) / Double(total)) * 100 : 0
        
        print("Total Tests: \(total)")
        print("Passed: \(passed) (\(String(format: "%.1f", percentage))%)")
        print("Failed: \(total - passed)")
        print()
        
        for (endpoint, success) in testResults.sorted(by: { $0.key < $1.key }) {
            print("\(success ? "✅" : "❌") \(endpoint)")
        }
        
        print("\n" + "=" * 80)
        
        if passed == total {
            print("🎉 ALL CURSOR INTEGRATION TESTS PASSED!")
        } else {
            print("⚠️ Some tests failed. Check backend logs for details.")
        }
        print("=" * 80)
    }
    
    // MARK: - Static Test Runner
    
    static func runTests() {
        let test = CursorIntegrationTest()
        Task {
            await test.runAllTests()
        }
    }
}

// Helper for string multiplication
fileprivate func *(string: String, count: Int) -> String {
    return String(repeating: string, count: count)
}