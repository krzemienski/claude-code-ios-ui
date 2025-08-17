#!/bin/bash

# Start Backend Server WITHOUT Authentication
# This runs the backend with all auth checks disabled

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

clear
echo -e "${CYAN}${BOLD}"
cat << "EOF"
 🔓 NO-AUTH BACKEND SERVER
 ========================
 Starting backend with authentication COMPLETELY DISABLED
 All endpoints will work without JWT tokens!
EOF
echo -e "${NC}"

# Step 1: Stop any existing server
echo -e "${YELLOW}Stopping any existing server on port 3004...${NC}"
lsof -ti:3004 | xargs kill -9 2>/dev/null || true
sleep 1

# Step 2: Verify auth is disabled in the code
echo -e "${CYAN}Verifying authentication is disabled...${NC}"

# Check auth middleware
if grep -q "Authentication completely disabled for testing" server/middleware/auth.js; then
    echo -e "${GREEN}✅ Auth middleware is disabled${NC}"
else
    echo -e "${RED}⚠️  Auth middleware may still be active${NC}"
fi

# Check auth routes
if grep -q "ALWAYS SUCCEEDS FOR TESTING" server/routes/auth.js; then
    echo -e "${GREEN}✅ Auth routes always succeed${NC}"
else
    echo -e "${RED}⚠️  Auth routes may still validate${NC}"
fi

# Step 3: Start the server
echo ""
echo -e "${CYAN}Starting backend server...${NC}"
echo -e "${YELLOW}Server will run at: http://localhost:3004${NC}"
echo ""

# Run the server (this will show logs in the terminal)
npm run server