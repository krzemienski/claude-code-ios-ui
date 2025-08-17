#!/bin/bash

# Stop ALL backend server processes to apply auth removal changes
echo "🛑 Stopping ALL Backend Server Processes"
echo "====================================="

# Method 1: Kill processes on port 3004
echo "Checking port 3004..."
PIDS=$(lsof -ti:3004)
if [ -z "$PIDS" ]; then
    echo "  ✅ No processes on port 3004"
else
    echo "  Found process(es): $PIDS"
    for PID in $PIDS; do
        kill -9 $PID 2>/dev/null && echo "    ✅ Killed PID $PID"
    done
fi

# Method 2: Kill node server processes
echo "Checking for node server processes..."
pkill -f "node.*server/index.js" 2>/dev/null && echo "  ✅ Killed node server processes"
pkill -f "npm run" 2>/dev/null && echo "  ✅ Killed npm processes"

# Method 3: Kill by PID files
if [ -f "/Users/nick/Documents/claude-code-ios-ui/backend/cloudflare/backend.pid" ]; then
    kill $(cat "/Users/nick/Documents/claude-code-ios-ui/backend/cloudflare/backend.pid") 2>/dev/null
    rm -f "/Users/nick/Documents/claude-code-ios-ui/backend/cloudflare/backend.pid"
    echo "  ✅ Killed backend via PID file"
fi

# Method 4: Kill cloudflared tunnels
echo "Checking for Cloudflare tunnels..."
pkill cloudflared 2>/dev/null && echo "  ✅ Killed cloudflared processes"

echo ""
echo "====================================="
echo "✅ All server processes stopped!"
echo "====================================="
echo ""
echo "Next: Run ./start-all.sh to start with auth disabled"
