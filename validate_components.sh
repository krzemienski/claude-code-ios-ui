#!/bin/bash

echo "============================================================"
echo "🚀 CHAT COMPONENT FILE VALIDATION"
echo "============================================================"
echo "Checking for all 9 refactored component files..."
echo

BASE_DIR="/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS"
PASSED=0
FAILED=0

# Component 1: ChatViewModel
if [ -f "$BASE_DIR/Features/Chat/ViewModels/ChatViewModel.swift" ]; then
    echo "✅ Component 1: ChatViewModel.swift found"
    ((PASSED++))
else
    echo "❌ Component 1: ChatViewModel.swift NOT FOUND"
    ((FAILED++))
fi

# Component 2: ChatTableViewHandler
if [ -f "$BASE_DIR/Features/Chat/Handlers/ChatTableViewHandler.swift" ]; then
    echo "✅ Component 2: ChatTableViewHandler.swift found"
    ((PASSED++))
else
    echo "❌ Component 2: ChatTableViewHandler.swift NOT FOUND"
    ((FAILED++))
fi

# Component 3: ChatInputHandler
if [ -f "$BASE_DIR/Features/Chat/Handlers/ChatInputHandler.swift" ]; then
    echo "✅ Component 3: ChatInputHandler.swift found"
    ((PASSED++))
else
    echo "❌ Component 3: ChatInputHandler.swift NOT FOUND"
    ((FAILED++))
fi

# Component 4: ChatWebSocketCoordinator
if [ -f "$BASE_DIR/Features/Chat/Coordinators/ChatWebSocketCoordinator.swift" ]; then
    echo "✅ Component 4: ChatWebSocketCoordinator.swift found"
    ((PASSED++))
else
    echo "❌ Component 4: ChatWebSocketCoordinator.swift NOT FOUND"
    ((FAILED++))
fi

# Component 5: ChatMessageProcessor
if [ -f "$BASE_DIR/Features/Chat/Processors/ChatMessageProcessor.swift" ]; then
    echo "✅ Component 5: ChatMessageProcessor.swift found"
    ((PASSED++))
else
    echo "❌ Component 5: ChatMessageProcessor.swift NOT FOUND"
    ((FAILED++))
fi

# Component 6: ChatStateManager
if [ -f "$BASE_DIR/Features/Chat/Managers/ChatStateManager.swift" ]; then
    echo "✅ Component 6: ChatStateManager.swift found"
    ((PASSED++))
else
    echo "❌ Component 6: ChatStateManager.swift NOT FOUND"
    ((FAILED++))
fi

# Component 7: ChatAttachmentHandler
if [ -f "$BASE_DIR/Features/Chat/Handlers/ChatAttachmentHandler.swift" ]; then
    echo "✅ Component 7: ChatAttachmentHandler.swift found"
    ((PASSED++))
else
    echo "❌ Component 7: ChatAttachmentHandler.swift NOT FOUND"
    ((FAILED++))
fi

# Component 8: StreamingMessageHandler
if [ -f "$BASE_DIR/Features/Chat/Handlers/StreamingMessageHandler.swift" ]; then
    echo "✅ Component 8: StreamingMessageHandler.swift found"
    ((PASSED++))
else
    echo "❌ Component 8: StreamingMessageHandler.swift NOT FOUND"
    ((FAILED++))
fi

# Component 9: Cell Implementations
CELLS_FOUND=0
if [ -f "$BASE_DIR/Features/Chat/Views/ChatMessageCell.swift" ]; then
    ((CELLS_FOUND++))
fi
if [ -f "$BASE_DIR/Features/Chat/Views/ChatTypingIndicatorCell.swift" ]; then
    ((CELLS_FOUND++))
fi
if [ -f "$BASE_DIR/Features/Chat/Views/ChatDateHeaderView.swift" ]; then
    ((CELLS_FOUND++))
fi

if [ $CELLS_FOUND -eq 3 ]; then
    echo "✅ Component 9: All cell implementations found (3/3)"
    ((PASSED++))
else
    echo "❌ Component 9: Only $CELLS_FOUND/3 cell implementations found"
    ((FAILED++))
fi

echo
echo "============================================================"
echo "📊 VALIDATION SUMMARY"
echo "============================================================"
echo "✅ Passed: $PASSED/9 components"
echo "❌ Failed: $FAILED/9 components"

if [ $FAILED -gt 0 ]; then
    echo
    echo "⚠️ Some components are missing! Please check the file paths."
fi

echo "============================================================"