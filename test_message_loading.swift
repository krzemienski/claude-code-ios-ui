#!/usr/bin/env swift

import Foundation

// Test the message loading API directly
struct TestMessageLoading {
    static func main() async {
        print("🧪 Testing Message Loading API Fix")
        print(String(repeating: "=", count: 50))
        
        // Test 1: Empty session (should not show error)
        await testEmptySession()
        
        // Test 2: Session with messages
        await testSessionWithMessages()
        
        // Test 3: Complex assistant message structure
        await testComplexMessageStructure()
        
        print("\n✅ All tests completed!")
    }
    
    static func testEmptySession() async {
        print("\n📝 Test 1: Empty Session")
        let url = URL(string: "http://192.168.0.43:3004/api/projects/claude-code-ios-ui/sessions/test-empty/messages?limit=50&offset=0")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let messages = json?["messages"] as? [[String: Any]] {
                print("  ✓ Response has messages array: \(messages.count) messages")
                print("  ✓ Empty session handled correctly (no error)")
            }
        } catch {
            print("  ✗ Error: \(error)")
        }
    }
    
    static func testSessionWithMessages() async {
        print("\n📝 Test 2: Session with Messages")
        let url = URL(string: "http://192.168.0.43:3004/api/projects/-Users-nick/sessions/f50c633c-7f9c-4340-b0ee-0f89fbaf0ea6/messages?limit=5&offset=0")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let messages = json?["messages"] as? [[String: Any]] {
                print("  ✓ Found \(messages.count) messages")
                
                // Check first message structure
                if let firstMsg = messages.first,
                   let msgContent = firstMsg["message"] as? [String: Any],
                   let role = msgContent["role"] as? String {
                    print("  ✓ First message role: \(role)")
                    
                    // Check content structure
                    if msgContent["content"] is String {
                        print("  ✓ User message with string content")
                    } else if let contentArray = msgContent["content"] as? [[String: Any]] {
                        print("  ✓ Assistant message with content array (\(contentArray.count) items)")
                    }
                }
            }
        } catch {
            print("  ✗ Error: \(error)")
        }
    }
    
    static func testComplexMessageStructure() async {
        print("\n📝 Test 3: Complex Message Structure")
        
        // Create test JSON that mimics the backend structure
        let testJSON = """
        {
            "messages": [
                {
                    "uuid": "test-1",
                    "timestamp": "2025-01-20T12:00:00Z",
                    "type": "user",
                    "message": {
                        "role": "user",
                        "content": "Test user message"
                    }
                },
                {
                    "uuid": "test-2",
                    "timestamp": "2025-01-20T12:00:01Z",
                    "type": "assistant",
                    "message": {
                        "role": "assistant",
                        "content": [
                            {
                                "type": "text",
                                "text": "Test assistant response"
                            },
                            {
                                "type": "tool_use",
                                "name": "calculator",
                                "input": {"expression": "2+2"}
                            }
                        ]
                    }
                }
            ],
            "total": 2,
            "hasMore": false
        }
        """.data(using: .utf8)!
        
        do {
            let json = try JSONSerialization.jsonObject(with: testJSON) as? [String: Any]
            
            if let messages = json?["messages"] as? [[String: Any]] {
                print("  ✓ Parsed \(messages.count) messages from complex structure")
                
                for (index, msg) in messages.enumerated() {
                    if let msgContent = msg["message"] as? [String: Any],
                       let role = msgContent["role"] as? String {
                        print("  ✓ Message \(index + 1) role: \(role)")
                    }
                }
            }
        } catch {
            print("  ✗ Error parsing complex structure: \(error)")
        }
    }
}

// Run the tests
await TestMessageLoading.main()