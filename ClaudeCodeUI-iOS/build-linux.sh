#!/bin/bash
# Build script for Claude Code UI iOS on Linux using Docker

echo "Building Claude Code UI iOS for Linux..."

# Build Docker image
docker build -t claudecodeui-ios .

# Run build inside container
docker run --rm -v $(pwd):/app -w /app claudecodeui-ios swift build -c debug

# Run tests
docker run --rm -v $(pwd):/app -w /app claudecodeui-ios swift test

echo "Build complete!"