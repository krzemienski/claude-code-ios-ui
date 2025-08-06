#!/bin/bash

# Swift validation script - checks syntax without full iOS build
# This uses the Swift compiler directly to validate code

set -e

echo "🔍 Swift Code Validation Script"
echo "================================"

# Check if Swift is installed
if ! command -v swift &> /dev/null; then
    echo "Installing Swift..."
    # Download Swift for Linux
    wget https://download.swift.org/swift-5.9.2-release/ubuntu2204/swift-5.9.2-RELEASE/swift-5.9.2-RELEASE-ubuntu22.04.tar.gz
    tar xzf swift-5.9.2-RELEASE-ubuntu22.04.tar.gz
    sudo mv swift-5.9.2-RELEASE-ubuntu22.04 /opt/swift
    export PATH=/opt/swift/usr/bin:$PATH
    echo 'export PATH=/opt/swift/usr/bin:$PATH' >> ~/.bashrc
fi

# Find all Swift files
echo "📁 Finding Swift files..."
SWIFT_FILES=$(find ClaudeCodeUI-iOS -name "*.swift" -type f)
TOTAL_FILES=$(echo "$SWIFT_FILES" | wc -l)

echo "Found $TOTAL_FILES Swift files"
echo ""

# Validate each Swift file for syntax
ERRORS=0
VALIDATED=0

for file in $SWIFT_FILES; do
    echo -n "Checking: $file ... "
    
    # Use swiftc to check syntax (parse only, don't compile)
    if swiftc -parse "$file" 2>/dev/null; then
        echo "✅"
        ((VALIDATED++))
    else
        echo "❌"
        echo "Error in $file:"
        swiftc -parse "$file" 2>&1 | head -20
        ((ERRORS++))
    fi
done

echo ""
echo "================================"
echo "Validation Complete!"
echo "✅ Valid files: $VALIDATED"
echo "❌ Files with errors: $ERRORS"

if [ $ERRORS -eq 0 ]; then
    echo "🎉 All Swift files are syntactically valid!"
    exit 0
else
    echo "⚠️ Fix the errors above before proceeding"
    exit 1
fi