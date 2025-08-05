#!/bin/bash
# Compile check script for Claude Code UI iOS on Linux
# This script verifies Swift syntax without building for iOS

echo "=== Claude Code UI iOS - Compile Check ==="
echo "Checking Swift syntax and compilation..."

SWIFT_PATH="/home/nick/.local/share/swift/usr/bin/swiftc"
PROJECT_DIR="/home/nick/claudecode-ios/ClaudeCodeUI-iOS"

# List of Swift files to check
declare -a swift_files=(
    "App/AppDelegate.swift"
    "App/SceneDelegate.swift"
    "Core/Data/Models/Project.swift"
    "Core/Data/Models/Settings.swift"
    "Core/Data/Models/FileNode.swift"
    "Core/Data/SwiftDataContainer.swift"
    "Core/DI/DIContainer.swift"
    "Core/Navigation/AppCoordinator.swift"
    "Core/Network/WebSocketManager.swift"
    "Core/Network/APIClient.swift"
    "Core/Services/Logger.swift"
    "Core/Services/ErrorHandlingService.swift"
    "Design/Theme/CyberpunkTheme.swift"
    "Design/Components/GradientBlock.swift"
    "Design/Components/GridBackgroundView.swift"
    "Design/Components/NeonButton.swift"
    "Features/Launch/LaunchViewController.swift"
    "UI/Base/BaseViewController.swift"
    "UI/Components/ProjectCard.swift"
    "UI/Components/MessageBubble.swift"
)

# Check each file
errors=0
for file in "${swift_files[@]}"; do
    echo -n "Checking $file... "
    if [ -f "$PROJECT_DIR/$file" ]; then
        # Use syntax check only (-parse)
        if $SWIFT_PATH -parse "$PROJECT_DIR/$file" 2>/dev/null; then
            echo "✓"
        else
            echo "✗ Syntax errors found"
            errors=$((errors + 1))
        fi
    else
        echo "✗ File not found"
        errors=$((errors + 1))
    fi
done

echo ""
if [ $errors -eq 0 ]; then
    echo "✅ All files passed syntax check!"
else
    echo "❌ Found $errors errors"
    exit 1
fi