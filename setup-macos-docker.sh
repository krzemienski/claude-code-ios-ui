#!/bin/bash
# Setup script for macOS Docker container with Xcode

echo "=== Setting up macOS Docker for iOS Development ==="

# Check if KVM is available
if [ ! -e /dev/kvm ]; then
    echo "ERROR: KVM is not available. Please ensure virtualization is enabled in BIOS."
    echo "You can check with: egrep -c '(vmx|svm)' /proc/cpuinfo"
    exit 1
fi

# Check if user has access to KVM
if [ ! -r /dev/kvm ] || [ ! -w /dev/kvm ]; then
    echo "ERROR: No read/write access to /dev/kvm"
    echo "Try: sudo chmod 666 /dev/kvm"
    exit 1
fi

# Create storage directory
mkdir -p macos-storage

# Pull the Docker image
echo "Pulling dockurr/macos Docker image..."
docker pull dockurr/macos:latest

# Start the container
echo "Starting macOS container..."
docker-compose up -d

echo ""
echo "=== macOS Docker Setup Complete ==="
echo ""
echo "Access the macOS desktop via:"
echo "  - Web Browser: http://localhost:8006"
echo "  - VNC Client: localhost:5900"
echo ""
echo "First boot will take 10-15 minutes to:"
echo "  1. Download macOS installer"
echo "  2. Create disk image" 
echo "  3. Install macOS"
echo "  4. Boot to desktop"
echo ""
echo "After macOS boots, you'll need to:"
echo "  1. Open App Store and install Xcode"
echo "  2. Launch Xcode and accept license agreements"
echo "  3. Install additional components when prompted"
echo "  4. Open Terminal and navigate to /workspace"
echo "  5. Run: xcodebuild -project ClaudeCodeUI-iOS.xcodeproj -scheme ClaudeCodeUI-iOS -sdk iphonesimulator"
echo ""
echo "Monitor logs with: docker-compose logs -f"