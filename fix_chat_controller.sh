#!/bin/bash

# Fix 1: Update status tracking for streaming responses
sed -i.bak1 '1877,1885s/if let messageId = self.lastSentMessageId {/if let pendingMessage = self.messages.last(where: { $0.isUser \&\& $0.status == .sending }) {/' ClaudeCodeUI-iOS/Features/Chat/ChatViewController.swift

sed -i.bak2 '1878,1885s/print("   📊 Marking message \\(messageId) as delivered (streaming started)")/let messageId = pendingMessage.id\
                    print("   📊 Marking message \\(messageId) as delivered (streaming started)")/' ClaudeCodeUI-iOS/Features/Chat/ChatViewController.swift

sed -i.bak3 '1881,1885s/self.updateUserMessageStatus(to: .delivered, messageId: messageId)/pendingMessage.status = .delivered\
                    self.updateUserMessageStatus(to: .delivered, messageId: messageId)/' ClaudeCodeUI-iOS/Features/Chat/ChatViewController.swift

sed -i.bak4 '1882,1883d' ClaudeCodeUI-iOS/Features/Chat/ChatViewController.swift

# Fix 2: Update status tracking for complete responses  
sed -i.bak5 '1897,1907s/if let messageId = self.lastSentMessageId {/if let pendingMessage = self.messages.last(where: { $0.isUser \&\& $0.status == .sending }) {/' ClaudeCodeUI-iOS/Features/Chat/ChatViewController.swift

sed -i.bak6 '1898,1907s/print("   📊 Marking message \\(messageId) as delivered")/let messageId = pendingMessage.id\
                    print("   📊 Marking message \\(messageId) as delivered")/' ClaudeCodeUI-iOS/Features/Chat/ChatViewController.swift

sed -i.bak7 '1901,1907s/self.updateUserMessageStatus(to: .delivered, messageId: messageId)/pendingMessage.status = .delivered\
                    self.updateUserMessageStatus(to: .delivered, messageId: messageId)/' ClaudeCodeUI-iOS/Features/Chat/ChatViewController.swift

sed -i.bak8 '1902,1903d' ClaudeCodeUI-iOS/Features/Chat/ChatViewController.swift

# Fix 3: Enhance metadata filtering to include session IDs
sed -i.bak9 '1800,1801s/let isJustNumber = Int(trimmedContent) != nil/let isJustNumber = Int(trimmedContent) != nil\
                    let isSessionId = trimmedContent.hasPrefix("session_") \&\& trimmedContent.count < 50/' ClaudeCodeUI-iOS/Features/Chat/ChatViewController.swift

sed -i.bak10 '1801s/let isMetadata = isJustUUID || isJustNumber || trimmedContent.isEmpty/let isMetadata = isJustUUID || isJustNumber || isSessionId || trimmedContent.isEmpty/' ClaudeCodeUI-iOS/Features/Chat/ChatViewController.swift

echo "Fixes applied successfully!"
