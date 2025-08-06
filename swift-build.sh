#!/bin/bash

# Swift build validation using Docker
# This validates Swift syntax without needing macOS/Xcode

set -e

echo "🐳 Swift Validation in Docker"
echo "=============================="

# Start Swift container
echo "Starting Swift container..."
docker-compose -f docker-compose-swift.yml up -d

# Wait for container
sleep 2

# Function to validate Swift files
validate_swift() {
    echo "🔍 Validating Swift syntax..."
    
    # Create a validation script inside container
    docker exec ios-swift-validator bash -c 'cat > /tmp/validate.sh << "EOF"
#!/bin/bash
ERRORS=0
CHECKED=0

# Find all Swift files
for file in $(find /workspace -name "*.swift" -type f); do
    echo -n "Checking: ${file#/workspace/} ... "
    
    # Try to parse the file using swiftc
    if swiftc -parse "$file" 2>/dev/null; then
        echo "✅"
        ((CHECKED++))
    else
        echo "❌"
        echo "Error details:"
        swiftc -parse "$file" 2>&1 | head -10
        ((ERRORS++))
    fi
done

echo ""
echo "Summary:"
echo "✅ Valid files: $CHECKED"
echo "❌ Files with errors: $ERRORS"

exit $ERRORS
EOF'

    # Run validation
    docker exec ios-swift-validator bash /tmp/validate.sh
}

# Function to build Package.swift if it exists
build_package() {
    echo "📦 Checking for Swift Package..."
    
    if docker exec ios-swift-validator test -f /workspace/Package.swift; then
        echo "Found Package.swift, attempting build..."
        docker exec ios-swift-validator swift build
    else
        echo "No Package.swift found (iOS apps typically use .xcodeproj)"
    fi
}

# Main execution
validate_swift

# Check result
if [ $? -eq 0 ]; then
    echo "✅ All Swift files are valid!"
    
    # Try to build if possible
    build_package
else
    echo "❌ Fix syntax errors before proceeding"
    exit 1
fi

# Cleanup
echo "Stopping container..."
docker-compose -f docker-compose-swift.yml down