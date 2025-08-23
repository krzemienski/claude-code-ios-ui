#!/bin/bash

# Comprehensive Fix Verification Script
# Verifies all three critical fixes for the Chat View Controller

set -e

PROJECT_DIR="/Users/nick/Documents/claude-code-ios-ui"
SIMULATOR_UUID="6520A438-0B1F-485B-9037-F346837B6D14"
BUNDLE_ID="com.claudecode.ui"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_FILE="$PROJECT_DIR/fix_verification_results_$TIMESTAMP.txt"

cd "$PROJECT_DIR"

echo "==================================================="
echo "CHAT VIEW CONTROLLER FIX VERIFICATION"
echo "==================================================="
echo "Timestamp: $(date)"
echo "Simulator: iPhone 16 Pro Max"
echo "Bundle ID: $BUNDLE_ID"
echo ""

# Function to write results
write_result() {
    echo "$1" | tee -a "$RESULTS_FILE"
}

write_result "Starting comprehensive fix verification..."
write_result ""

# Check if simulator is booted
write_result "Step 1: Checking simulator status..."
if xcrun simctl list devices | grep "$SIMULATOR_UUID" | grep -q "Booted"; then
    write_result "✅ Simulator is booted"
else
    write_result "⚠️  Simulator not booted - booting now..."
    xcrun simctl boot "$SIMULATOR_UUID"
    sleep 5
fi

# Check if app is installed
write_result ""
write_result "Step 2: Checking app installation..."
if xcrun simctl listapps "$SIMULATOR_UUID" | grep -q "$BUNDLE_ID"; then
    write_result "✅ App is installed"
else
    write_result "❌ App not installed - please run: ./simulator-automation.sh build"
    exit 1
fi

# Check if app is running
write_result ""
write_result "Step 3: Checking if app is running..."
if xcrun simctl spawn "$SIMULATOR_UUID" launchctl list | grep -q "$BUNDLE_ID"; then
    write_result "✅ App is running"
else
    write_result "⚠️  App not running - launching..."
    xcrun simctl launch "$SIMULATOR_UUID" "$BUNDLE_ID"
    sleep 3
fi

# Verify code changes are present
write_result ""
write_result "Step 4: Verifying code changes..."
write_result ""
write_result "FIX 1 - Message Status Tracking:"

# Check for Fix 1 implementation
if grep -q "messages.last(where: { \$0.isUser && \$0.status == .sending })" ClaudeCodeUI-iOS/Features/Chat/ChatViewController.swift; then
    write_result "✅ Fix 1 code is present (pending message search)"
else
    write_result "❌ Fix 1 code NOT found"
fi

write_result ""
write_result "FIX 2 - Assistant Response Filtering:"

# Check for Fix 2 implementation
if grep -q "isSessionId" ClaudeCodeUI-iOS/Features/Chat/ChatViewController.swift; then
    write_result "✅ Fix 2 code is present (isSessionId in metadata check)"
else
    write_result "❌ Fix 2 code NOT found"
fi

write_result ""
write_result "FIX 3 - WebSocket Message Format:"

# Check for Fix 3 implementation
if grep -q '"content": content' ClaudeCodeUI-iOS/Features/Chat/ChatViewController.swift; then
    write_result "✅ Fix 3 code is present (correct 'content' field)"
else
    write_result "❌ Fix 3 code NOT found"
fi

# Capture and analyze runtime logs
write_result ""
write_result "Step 5: Capturing runtime logs..."
write_result ""
write_result "Starting 20-second log capture..."
write_result "Please perform these actions in the app NOW:"
write_result "  1. Navigate to Projects tab"
write_result "  2. Select or create a project"
write_result "  3. Select or create a session"
write_result "  4. Send a test message (e.g., 'Hello')"
write_result "  5. Wait for response"
write_result ""

# Capture logs for 20 seconds
LOG_TEMP="$PROJECT_DIR/temp_log_$TIMESTAMP.txt"
xcrun simctl spawn "$SIMULATOR_UUID" log stream \
    --predicate 'processImagePath contains "ClaudeCodeUI"' \
    --level debug 2>/dev/null > "$LOG_TEMP" &
LOG_PID=$!

# Progress indicator
for i in {20..1}; do
    echo -ne "\rTime remaining: $i seconds  "
    sleep 1
done
echo ""

# Stop log capture
kill $LOG_PID 2>/dev/null || true
sleep 1

# Analyze captured logs
write_result ""
write_result "Step 6: Analyzing captured logs..."
write_result ""

# Analysis for Fix 1
write_result "FIX 1 Analysis - Message Status:"
if grep -q "Marked user message.*as delivered" "$LOG_TEMP" 2>/dev/null; then
    count=$(grep -c "Marked user message.*as delivered" "$LOG_TEMP")
    write_result "✅ Found $count status update(s) to 'delivered'"
else
    write_result "⚠️  No 'delivered' status updates found"
fi

# Analysis for Fix 2
write_result ""
write_result "FIX 2 Analysis - Assistant Responses:"
if grep -q "role: assistant" "$LOG_TEMP" 2>/dev/null; then
    count=$(grep -c "role: assistant" "$LOG_TEMP")
    write_result "✅ Found $count assistant message(s)"
else
    write_result "⚠️  No assistant messages found"
fi

if grep -q "Filtered out metadata message" "$LOG_TEMP" 2>/dev/null; then
    count=$(grep -c "Filtered out metadata message" "$LOG_TEMP")
    write_result "ℹ️  Filtered $count metadata message(s)"
fi

# Analysis for Fix 3
write_result ""
write_result "FIX 3 Analysis - WebSocket Format:"
if grep -q "\[Continue/Resume\]" "$LOG_TEMP" 2>/dev/null; then
    count=$(grep -c "\[Continue/Resume\]" "$LOG_TEMP")
    write_result "❌ Found $count '[Continue/Resume]' - format issue!"
else
    write_result "✅ No '[Continue/Resume]' found - format correct"
fi

if grep -q '"content":' "$LOG_TEMP" 2>/dev/null; then
    count=$(grep -c '"content":' "$LOG_TEMP")
    write_result "✅ Found $count message(s) with 'content' field"
fi

# Clean up temp log
rm -f "$LOG_TEMP"

# Final summary
write_result ""
write_result "==================================================="
write_result "VERIFICATION SUMMARY"
write_result "==================================================="
write_result ""

# Count successes
success_count=0
total_checks=6

# Code verification
grep -q "messages.last(where: { \$0.isUser && \$0.status == .sending })" ClaudeCodeUI-iOS/Features/Chat/ChatViewController.swift && ((success_count++))
grep -q "isSessionId" ClaudeCodeUI-iOS/Features/Chat/ChatViewController.swift && ((success_count++))
grep -q '"content": content' ClaudeCodeUI-iOS/Features/Chat/ChatViewController.swift && ((success_count++))

# Runtime verification (check the results file for these)
grep -q "✅.*delivered" "$RESULTS_FILE" && ((success_count++))
grep -q "✅.*assistant message" "$RESULTS_FILE" && ((success_count++))
grep -q "✅ No.*Continue/Resume" "$RESULTS_FILE" && ((success_count++))

write_result "Verification Score: $success_count/$total_checks"
write_result ""

if [ "$success_count" -eq 6 ]; then
    write_result "🎉 ALL FIXES VERIFIED SUCCESSFULLY!"
elif [ "$success_count" -ge 4 ]; then
    write_result "✅ Most fixes are working ($success_count/6)"
    write_result "Some runtime verification may require manual testing"
else
    write_result "⚠️  Only $success_count/6 checks passed"
    write_result "Please review the implementation and test manually"
fi

write_result ""
write_result "Full results saved to: $RESULTS_FILE"
write_result "==================================================="

echo ""
echo "Verification complete!"