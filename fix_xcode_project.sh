#!/bin/bash

echo "🔧 Xcode Project Fix Script"
echo "=========================="
echo ""
echo "This script will help fix the Xcode project file references."
echo ""

# Navigate to project directory
cd /Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS

echo "📋 Steps to fix the project manually:"
echo ""
echo "1. Open Xcode:"
echo "   open ClaudeCodeUI.xcodeproj"
echo ""
echo "2. In Xcode, remove broken references (they'll appear in red):"
echo "   - Select the red files in the navigator"
echo "   - Press Delete key and choose 'Remove Reference'"
echo ""
echo "3. Re-add the files correctly:"
echo "   - Right-click on 'UI/Components' group"
echo "   - Choose 'Add Files to ClaudeCodeUI...'"
echo "   - Navigate to UI/Components/"
echo "   - Select CyberpunkLoadingIndicator.swift"
echo "   - Make sure 'Copy items if needed' is UNCHECKED"
echo "   - Make sure 'ClaudeCodeUI' target is CHECKED"
echo "   - Click Add"
echo ""
echo "   - Right-click on 'Features/Search' group"
echo "   - Choose 'Add Files to ClaudeCodeUI...'"
echo "   - Navigate to Features/Search/"
echo "   - Select SearchResultRow.swift"
echo "   - Make sure 'Copy items if needed' is UNCHECKED"
echo "   - Make sure 'ClaudeCodeUI' target is CHECKED"
echo "   - Click Add"
echo ""
echo "4. Also ensure NoDataView.swift is added to target:"
echo "   - Find NoDataView.swift in UI/Components"
echo "   - Check the target membership in the inspector"
echo ""
echo "5. Clean and Build:"
echo "   - Product → Clean Build Folder (Cmd+Shift+K)"
echo "   - Product → Build (Cmd+B)"
echo ""
echo "📱 The files that need to be properly added:"
echo "   ✓ UI/Components/CyberpunkLoadingIndicator.swift"
echo "   ✓ Features/Search/SearchResultRow.swift"
echo "   ✓ UI/Components/NoDataView.swift (if not already added)"
echo ""
echo "🎯 Once fixed, the app should build and run successfully with all new features!"
echo ""

# Verify files exist
echo "✅ Verifying files exist in filesystem:"
for file in "UI/Components/CyberpunkLoadingIndicator.swift" \
            "Features/Search/SearchResultRow.swift" \
            "UI/Components/NoDataView.swift"; do
    if [ -f "$file" ]; then
        echo "   ✓ $file exists"
    else
        echo "   ✗ $file NOT FOUND"
    fi
done

echo ""
echo "📝 Note: The Swift code is complete and correct. This is only an Xcode project configuration issue."