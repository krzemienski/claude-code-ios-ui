#!/bin/bash

# Chat View Controller QA Test Script
# Tests the critical fixes for message status and assistant responses

echo "======================================"
echo "Chat View Controller QA Test"
echo "Testing message status and assistant responses"
echo "======================================"

# Configuration
SIMULATOR_UUID="6520A438-0B1F-485B-9037-F346837B6D14"
BUNDLE_ID="com.claudecode.ui"
LOG_FILE="logs/chat_qa_test_$(date +%Y%m%d_%H%M%S).log"

# Start log capture in background
echo "[INFO] Starting log capture..."
xcrun simctl spawn $SIMULATOR_UUID log stream \
  --predicate 'processImagePath contains "ClaudeCodeUI"' \
  --style json > "$LOG_FILE" 2>&1 &
LOG_PID=$!
echo "[INFO] Log capture started (PID: $LOG_PID)"

# Wait for logs to start
sleep 2

# Launch the app
echo "[INFO] Launching app..."
xcrun simctl launch $SIMULATOR_UUID $BUNDLE_ID

# Wait for app to start
sleep 3

echo "[INFO] App should be running. Please manually:"
echo "  1. Navigate to Projects tab"
echo "  2. Select a project"
echo "  3. Select or create a session"
echo "  4. Send a test message"
echo "  5. Observe message status (should change from sending → delivered)"
echo "  6. Check if assistant response appears"

# Keep logging for 60 seconds
echo "[INFO] Monitoring for 60 seconds..."
sleep 60

# Stop log capture
echo "[INFO] Stopping log capture..."
kill $LOG_PID 2>/dev/null

# Analyze logs
echo ""
echo "======================================"
echo "Log Analysis"
echo "======================================"

echo ""
echo "Checking for message status updates:"
grep -E "Message.*status|Status.*delivered|markAsDelivered" "$LOG_FILE" | tail -20

echo ""
echo "Checking for assistant responses:"
grep -E "claudeResponse|assistant.*response|Processing assistant" "$LOG_FILE" | tail -20

echo ""
echo "Checking for UUID filtering:"
grep -E "Skipping.*metadata|Processing.*assistant|UUID" "$LOG_FILE" | tail -20

echo ""
echo "Checking for errors:"
grep -E "ERROR|Failed|Error|failed" "$LOG_FILE" | tail -10

echo ""
echo "======================================"
echo "Test Complete"
echo "Log saved to: $LOG_FILE"
echo "======================================"