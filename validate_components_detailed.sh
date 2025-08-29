#!/bin/bash

echo "============================================================"
echo "🔍 DETAILED CHAT COMPONENT VALIDATION"
echo "============================================================"
echo "Checking component methods and properties..."
echo

BASE_DIR="/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/Features/Chat"
PASSED=0
FAILED=0
ISSUES=""

# Component 1: ChatViewModel
echo "📋 Component 1: ChatViewModel"
if [ -f "$BASE_DIR/ViewModels/ChatViewModel.swift" ]; then
    echo "  ✅ File exists"
    
    # Check for required methods/properties
    if grep -q "@Published var messages" "$BASE_DIR/ViewModels/ChatViewModel.swift"; then
        echo "  ✅ Has @Published messages property"
        ((PASSED++))
    else
        echo "  ❌ Missing @Published messages property"
        ISSUES="$ISSUES\n  - ChatViewModel: Missing @Published messages"
        ((FAILED++))
    fi
    
    if grep -q "func sendMessage" "$BASE_DIR/ViewModels/ChatViewModel.swift"; then
        echo "  ✅ Has sendMessage method"
        ((PASSED++))
    else
        echo "  ❌ Missing sendMessage method"
        ISSUES="$ISSUES\n  - ChatViewModel: Missing sendMessage"
        ((FAILED++))
    fi
    
    if grep -q "func loadMessages" "$BASE_DIR/ViewModels/ChatViewModel.swift"; then
        echo "  ✅ Has loadMessages method"
        ((PASSED++))
    else
        echo "  ❌ Missing loadMessages method"
        ISSUES="$ISSUES\n  - ChatViewModel: Missing loadMessages"
        ((FAILED++))
    fi
else
    echo "  ❌ File not found"
    ((FAILED++))
fi
echo

# Component 2: ChatTableViewHandler
echo "📋 Component 2: ChatTableViewHandler"
if [ -f "$BASE_DIR/Handlers/ChatTableViewHandler.swift" ]; then
    echo "  ✅ File exists"
    
    if grep -q "func setupTableView" "$BASE_DIR/Handlers/ChatTableViewHandler.swift"; then
        echo "  ✅ Has setupTableView method"
        ((PASSED++))
    else
        echo "  ❌ Missing setupTableView method"
        ISSUES="$ISSUES\n  - ChatTableViewHandler: Missing setupTableView"
        ((FAILED++))
    fi
    
    if grep -q "func reloadData" "$BASE_DIR/Handlers/ChatTableViewHandler.swift"; then
        echo "  ✅ Has reloadData method"
        ((PASSED++))
    else
        echo "  ❌ Missing reloadData method"
        ISSUES="$ISSUES\n  - ChatTableViewHandler: Missing reloadData"
        ((FAILED++))
    fi
    
    if grep -q "weak var viewModel" "$BASE_DIR/Handlers/ChatTableViewHandler.swift"; then
        echo "  ✅ Has weak viewModel reference"
        ((PASSED++))
    else
        echo "  ❌ Missing weak viewModel reference"
        ISSUES="$ISSUES\n  - ChatTableViewHandler: Missing viewModel"
        ((FAILED++))
    fi
else
    echo "  ❌ File not found"
    ((FAILED++))
fi
echo

# Component 3: ChatInputHandler
echo "📋 Component 3: ChatInputHandler"
if [ -f "$BASE_DIR/Handlers/ChatInputHandler.swift" ]; then
    echo "  ✅ File exists"
    
    if grep -q "func handleSendButtonTapped" "$BASE_DIR/Handlers/ChatInputHandler.swift"; then
        echo "  ✅ Has handleSendButtonTapped method"
        ((PASSED++))
    else
        echo "  ❌ Missing handleSendButtonTapped method"
        ISSUES="$ISSUES\n  - ChatInputHandler: Missing handleSendButtonTapped"
        ((FAILED++))
    fi
    
    if grep -q "func updateInputState" "$BASE_DIR/Handlers/ChatInputHandler.swift"; then
        echo "  ✅ Has updateInputState method"
        ((PASSED++))
    else
        echo "  ❌ Missing updateInputState method"
        ISSUES="$ISSUES\n  - ChatInputHandler: Missing updateInputState"
        ((FAILED++))
    fi
else
    echo "  ❌ File not found"
    ((FAILED++))
fi
echo

# Component 4: ChatWebSocketCoordinator
echo "📋 Component 4: ChatWebSocketCoordinator"
if [ -f "$BASE_DIR/Coordinators/ChatWebSocketCoordinator.swift" ]; then
    echo "  ✅ File exists"
    
    if grep -q "func connect" "$BASE_DIR/Coordinators/ChatWebSocketCoordinator.swift"; then
        echo "  ✅ Has connect method"
        ((PASSED++))
    else
        echo "  ❌ Missing connect method"
        ISSUES="$ISSUES\n  - ChatWebSocketCoordinator: Missing connect"
        ((FAILED++))
    fi
    
    if grep -q "func sendMessage" "$BASE_DIR/Coordinators/ChatWebSocketCoordinator.swift"; then
        echo "  ✅ Has sendMessage method"
        ((PASSED++))
    else
        echo "  ❌ Missing sendMessage method"
        ISSUES="$ISSUES\n  - ChatWebSocketCoordinator: Missing sendMessage"
        ((FAILED++))
    fi
    
    if grep -q "var projectPath" "$BASE_DIR/Coordinators/ChatWebSocketCoordinator.swift"; then
        echo "  ✅ Has projectPath property"
        ((PASSED++))
    else
        echo "  ❌ Missing projectPath property"
        ISSUES="$ISSUES\n  - ChatWebSocketCoordinator: Missing projectPath"
        ((FAILED++))
    fi
else
    echo "  ❌ File not found"
    ((FAILED++))
fi
echo

# Component 5: ChatMessageProcessor
echo "📋 Component 5: ChatMessageProcessor"
if [ -f "$BASE_DIR/Processors/ChatMessageProcessor.swift" ]; then
    echo "  ✅ File exists"
    
    if grep -q "func processMessage" "$BASE_DIR/Processors/ChatMessageProcessor.swift"; then
        echo "  ✅ Has processMessage method"
        ((PASSED++))
    else
        echo "  ❌ Missing processMessage method"
        ISSUES="$ISSUES\n  - ChatMessageProcessor: Missing processMessage"
        ((FAILED++))
    fi
else
    echo "  ❌ File not found"
    ((FAILED++))
fi
echo

# Component 6: ChatStateManager
echo "📋 Component 6: ChatStateManager"
if [ -f "$BASE_DIR/Managers/ChatStateManager.swift" ]; then
    echo "  ✅ File exists"
    
    if grep -q "enum State" "$BASE_DIR/Managers/ChatStateManager.swift"; then
        echo "  ✅ Has State enum"
        ((PASSED++))
    else
        echo "  ❌ Missing State enum"
        ISSUES="$ISSUES\n  - ChatStateManager: Missing State enum"
        ((FAILED++))
    fi
    
    if grep -q "var currentState" "$BASE_DIR/Managers/ChatStateManager.swift"; then
        echo "  ✅ Has currentState property"
        ((PASSED++))
    else
        echo "  ❌ Missing currentState property"
        ISSUES="$ISSUES\n  - ChatStateManager: Missing currentState"
        ((FAILED++))
    fi
else
    echo "  ❌ File not found"
    ((FAILED++))
fi
echo

# Component 7: ChatAttachmentHandler
echo "📋 Component 7: ChatAttachmentHandler"
if [ -f "$BASE_DIR/Handlers/ChatAttachmentHandler.swift" ]; then
    echo "  ✅ File exists"
    
    if grep -q "func handleAttachment" "$BASE_DIR/Handlers/ChatAttachmentHandler.swift"; then
        echo "  ✅ Has handleAttachment method"
        ((PASSED++))
    else
        echo "  ❌ Missing handleAttachment method"
        ISSUES="$ISSUES\n  - ChatAttachmentHandler: Missing handleAttachment"
        ((FAILED++))
    fi
else
    echo "  ❌ File not found"
    ((FAILED++))
fi
echo

# Component 8: StreamingMessageHandler
echo "📋 Component 8: StreamingMessageHandler"
if [ -f "$BASE_DIR/Handlers/StreamingMessageHandler.swift" ]; then
    echo "  ✅ File exists"
    
    if grep -q "func startStreaming" "$BASE_DIR/Handlers/StreamingMessageHandler.swift"; then
        echo "  ✅ Has startStreaming method"
        ((PASSED++))
    else
        echo "  ❌ Missing startStreaming method"
        ISSUES="$ISSUES\n  - StreamingMessageHandler: Missing startStreaming"
        ((FAILED++))
    fi
    
    if grep -q "func addChunk" "$BASE_DIR/Handlers/StreamingMessageHandler.swift"; then
        echo "  ✅ Has addChunk method"
        ((PASSED++))
    else
        echo "  ❌ Missing addChunk method"
        ISSUES="$ISSUES\n  - StreamingMessageHandler: Missing addChunk"
        ((FAILED++))
    fi
    
    if grep -q "func completeStreaming" "$BASE_DIR/Handlers/StreamingMessageHandler.swift"; then
        echo "  ✅ Has completeStreaming method"
        ((PASSED++))
    else
        echo "  ❌ Missing completeStreaming method"
        ISSUES="$ISSUES\n  - StreamingMessageHandler: Missing completeStreaming"
        ((FAILED++))
    fi
else
    echo "  ❌ File not found"
    ((FAILED++))
fi
echo

# Component 9: Cell Implementations
echo "📋 Component 9: Cell Implementations"
CELLS_OK=0
if [ -f "$BASE_DIR/Views/ChatMessageCell.swift" ]; then
    echo "  ✅ ChatMessageCell exists"
    ((CELLS_OK++))
    ((PASSED++))
else
    echo "  ❌ ChatMessageCell not found"
    ISSUES="$ISSUES\n  - Missing ChatMessageCell"
    ((FAILED++))
fi

if [ -f "$BASE_DIR/Views/ChatTypingIndicatorCell.swift" ]; then
    echo "  ✅ ChatTypingIndicatorCell exists"
    ((CELLS_OK++))
    ((PASSED++))
else
    echo "  ❌ ChatTypingIndicatorCell not found"
    ISSUES="$ISSUES\n  - Missing ChatTypingIndicatorCell"
    ((FAILED++))
fi

if [ -f "$BASE_DIR/Views/ChatDateHeaderView.swift" ]; then
    echo "  ✅ ChatDateHeaderView exists"
    ((CELLS_OK++))
    ((PASSED++))
else
    echo "  ❌ ChatDateHeaderView not found"
    ISSUES="$ISSUES\n  - Missing ChatDateHeaderView"
    ((FAILED++))
fi
echo

echo "============================================================"
echo "📊 VALIDATION SUMMARY"
echo "============================================================"
echo "✅ Passed checks: $PASSED"
echo "❌ Failed checks: $FAILED"
echo
if [ $FAILED -gt 0 ]; then
    echo "⚠️ Issues found:"
    echo -e "$ISSUES"
else
    echo "🎉 All validation checks passed!"
fi
echo "============================================================"