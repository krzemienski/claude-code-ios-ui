#!/bin/bash

# Docker-OSX setup script for iOS development
# This runs a full macOS VM inside Docker on Linux

set -e

echo "🍎 Setting up Docker-OSX for iOS development..."

# Check for KVM support
if [ ! -e /dev/kvm ]; then
    echo "❌ KVM is not available. Please enable virtualization in BIOS and install KVM."
    echo "Run: sudo apt-get install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils"
    exit 1
fi

# Check if user is in kvm group
if ! groups | grep -q kvm; then
    echo "⚠️ Adding user to kvm group..."
    sudo usermod -aG kvm $USER
    echo "Please log out and back in, then run this script again."
    exit 1
fi

# Start the macOS container
echo "🚀 Starting macOS Sonoma container..."
docker-compose -f docker-compose-macos.yml up -d

echo "⏳ Waiting for macOS to boot (this takes 5-10 minutes first time)..."
sleep 30

echo "📱 macOS Docker container started!"
echo ""
echo "Next steps:"
echo "1. Connect via VNC: vncviewer localhost:5999"
echo "2. Complete macOS installation wizard"
echo "3. Open App Store and install Xcode (7-10GB download)"
echo "4. Once Xcode is installed, SSH into container:"
echo "   ssh -p 50922 user@localhost"
echo "5. Install Xcode command line tools:"
echo "   xcode-select --install"
echo "6. Build the iOS app:"
echo "   cd /workspace"
echo "   xcodebuild -project ClaudeCodeUI-iOS.xcodeproj -scheme ClaudeCodeUI -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' build"
echo ""
echo "⚠️ First-time setup will take 1-2 hours including Xcode download"