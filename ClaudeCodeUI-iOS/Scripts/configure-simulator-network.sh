#!/bin/bash

# Configure Simulator Network Settings for Backend Connectivity
# This script ensures the simulator can reach the backend at 192.168.0.155:3004

set -e

# Configuration
BACKEND_HOST="192.168.0.155"
BACKEND_PORT="3004"
SIMULATOR_NAME="iPhone 16 Pro"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} Simulator Network Configuration${NC}"
echo -e "${GREEN}========================================${NC}"

# Get the simulator UUID
SIMULATOR_UUID=$(xcrun simctl list devices | grep "$SIMULATOR_NAME" | grep -E '\([A-F0-9-]+\)' | head -1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')

if [ -z "$SIMULATOR_UUID" ]; then
    echo -e "${RED}Error: Could not find simulator '$SIMULATOR_NAME'${NC}"
    exit 1
fi

echo -e "${GREEN}Configuring simulator: $SIMULATOR_NAME ($SIMULATOR_UUID)${NC}"

# Test network connectivity from host machine
echo -e "${YELLOW}Testing backend connectivity from host...${NC}"
if nc -z -v -w5 $BACKEND_HOST $BACKEND_PORT 2>/dev/null; then
    echo -e "${GREEN}✓ Backend is reachable at $BACKEND_HOST:$BACKEND_PORT${NC}"
else
    echo -e "${RED}✗ Cannot reach backend at $BACKEND_HOST:$BACKEND_PORT${NC}"
    echo -e "${YELLOW}Please ensure the backend server is running${NC}"
fi

# Create a test script to verify connectivity from within the app
TEST_SCRIPT="/tmp/test_backend_connectivity.swift"
cat > "$TEST_SCRIPT" << 'EOF'
import Foundation

let semaphore = DispatchSemaphore(value: 0)
let host = "192.168.0.155"
let port = 3004

print("Testing connectivity to \(host):\(port)...")

let url = URL(string: "http://\(host):\(port)/api/health")!
var request = URLRequest(url: url)
request.timeoutInterval = 5.0

let task = URLSession.shared.dataTask(with: request) { data, response, error in
    if let error = error {
        print("❌ Connection failed: \(error.localizedDescription)")
    } else if let httpResponse = response as? HTTPURLResponse {
        if httpResponse.statusCode == 200 {
            print("✅ Backend is reachable! Status: \(httpResponse.statusCode)")
        } else {
            print("⚠️ Backend responded with status: \(httpResponse.statusCode)")
        }
    }
    semaphore.signal()
}

task.resume()
_ = semaphore.wait(timeout: .now() + 10)
EOF

# Additional network diagnostics
echo -e "${YELLOW}Network diagnostics:${NC}"
echo -e "  Host IP: $(ipconfig getifaddr en0 2>/dev/null || echo 'Not found')"
echo -e "  Backend: http://$BACKEND_HOST:$BACKEND_PORT"
echo ""

# Create app configuration file
CONFIG_FILE="/tmp/claudecode_config.json"
cat > "$CONFIG_FILE" << EOF
{
    "backend": {
        "host": "$BACKEND_HOST",
        "port": $BACKEND_PORT,
        "baseURL": "http://$BACKEND_HOST:$BACKEND_PORT",
        "websocketURL": "ws://$BACKEND_HOST:$BACKEND_PORT"
    },
    "environment": "development",
    "debug": true
}
EOF

echo -e "${GREEN}Configuration created at: $CONFIG_FILE${NC}"
echo ""
echo -e "${GREEN}Network configuration complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Ensure backend is running at http://$BACKEND_HOST:$BACKEND_PORT"
echo "2. The app should automatically connect to the backend"
echo "3. If connection fails, check:"
echo "   - Backend server is running"
echo "   - Firewall settings allow connections"
echo "   - Both devices are on the same network"
echo ""
echo "To test connectivity manually:"
echo "  curl -v http://$BACKEND_HOST:$BACKEND_PORT/api/health"