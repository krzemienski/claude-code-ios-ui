#!/bin/bash

# Test Script: Verify ALL Backend APIs Work WITHOUT Authentication
# This confirms that auth has been completely removed from the backend

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Use local URL - no authentication required!
BASE_URL="http://localhost:3004"

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to test endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local data=$3
    local description=$4
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -n "Testing: $description... "
    
    if [ -z "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X $method "$BASE_URL$endpoint" -H "Content-Type: application/json")
    else
        response=$(curl -s -w "\n%{http_code}" -X $method "$BASE_URL$endpoint" -H "Content-Type: application/json" -d "$data")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [[ $http_code -ge 200 && $http_code -lt 400 ]]; then
        echo -e "${GREEN}✓${NC} ($http_code)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo "  Response: $(echo $body | head -c 100)..."
    else
        echo -e "${RED}✗${NC} ($http_code)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo "  Error: $body"
    fi
    echo ""
}

echo "========================================="
echo -e "${CYAN}🔓 Testing Backend APIs WITHOUT Authentication${NC}"
echo -e "${YELLOW}All endpoints should work without JWT tokens!${NC}"
echo "URL: $BASE_URL"
echo "========================================="
echo ""

# ===== AUTHENTICATION ENDPOINTS (5) =====
echo -e "${BLUE}Testing Authentication Endpoints...${NC}"
echo "-----------------------------------------"

test_endpoint "GET" "/api/auth/status" "" "Auth Status"
test_endpoint "POST" "/api/auth/register" '{"username":"testuser","password":"testpass123"}' "Register User"
test_endpoint "POST" "/api/auth/login" '{"username":"testuser","password":"testpass123"}' "Login User"
test_endpoint "GET" "/api/auth/user" "" "Get Current User"
test_endpoint "POST" "/api/auth/logout" "" "Logout"

# ===== PROJECT ENDPOINTS (5) =====
echo -e "${BLUE}Testing Project Endpoints...${NC}"
echo "-----------------------------------------"

test_endpoint "GET" "/api/projects" "" "List Projects"
test_endpoint "POST" "/api/projects/create" '{"name":"test-project","path":"/tmp/test-project"}' "Create Project"
test_endpoint "GET" "/api/projects/test-project" "" "Get Project Details"
test_endpoint "PUT" "/api/projects/test-project/rename" '{"newName":"renamed-project"}' "Rename Project"
test_endpoint "DELETE" "/api/projects/renamed-project" "" "Delete Project"

# ===== SESSION ENDPOINTS (3) =====
echo -e "${BLUE}Testing Session Endpoints...${NC}"
echo "-----------------------------------------"

test_endpoint "GET" "/api/projects/test-project/sessions" "" "Get Project Sessions"
test_endpoint "POST" "/api/projects/test-project/sessions" '{"type":"chat"}' "Create Session"
test_endpoint "GET" "/api/sessions" "" "List All Sessions"

# ===== FILE ENDPOINTS (3) =====
echo -e "${BLUE}Testing File Endpoints...${NC}"
echo "-----------------------------------------"

test_endpoint "GET" "/api/projects/test-project/files" "" "Get File Tree"
test_endpoint "GET" "/api/projects/test-project/file?path=README.md" "" "Read File"
test_endpoint "PUT" "/api/projects/test-project/file" '{"path":"test.txt","content":"test content"}' "Write File"

# ===== GIT ENDPOINTS (16) =====
echo -e "${BLUE}Testing Git Endpoints...${NC}"
echo "-----------------------------------------"

test_endpoint "GET" "/api/git/status" "" "Git Status"
test_endpoint "GET" "/api/git/diff" "" "Git Diff"
test_endpoint "POST" "/api/git/add" '{"files":["."]}' "Git Add"
test_endpoint "POST" "/api/git/commit" '{"message":"Test commit"}' "Git Commit"
test_endpoint "GET" "/api/git/branches" "" "List Branches"
test_endpoint "POST" "/api/git/checkout" '{"branch":"main"}' "Checkout Branch"
test_endpoint "POST" "/api/git/create-branch" '{"branch":"test-branch"}' "Create Branch"
test_endpoint "GET" "/api/git/commits" "" "List Commits"
test_endpoint "GET" "/api/git/remote" "" "Get Remote"
test_endpoint "POST" "/api/git/remote/add" '{"name":"origin","url":"https://github.com/test/repo.git"}' "Add Remote"
test_endpoint "POST" "/api/git/fetch" "" "Git Fetch"
test_endpoint "POST" "/api/git/pull" "" "Git Pull"
test_endpoint "POST" "/api/git/push" "" "Git Push"
test_endpoint "POST" "/api/git/clone" '{"url":"https://github.com/test/repo.git","path":"/tmp/clone"}' "Git Clone"
test_endpoint "POST" "/api/git/generate-commit" '{"files":["test.js"]}' "Generate Commit Message"
test_endpoint "GET" "/api/git/log" "" "Git Log"

# ===== CURSOR INTEGRATION (8) =====
echo -e "${BLUE}Testing Cursor Integration...${NC}"
echo "-----------------------------------------"

test_endpoint "GET" "/api/cursor/config" "" "Get Cursor Config"
test_endpoint "POST" "/api/cursor/config" '{"theme":"dark"}' "Update Cursor Config"
test_endpoint "GET" "/api/cursor/mcp/servers" "" "List MCP Servers"
test_endpoint "POST" "/api/cursor/mcp/add" '{"name":"test","url":"http://test.com"}' "Add MCP Server"
test_endpoint "DELETE" "/api/cursor/mcp/test" "" "Remove MCP Server"
test_endpoint "GET" "/api/cursor/sessions" "" "Get Cursor Sessions"
test_endpoint "GET" "/api/cursor/current-file" "" "Get Current File"
test_endpoint "POST" "/api/cursor/open-file" '{"path":"/test/file.js"}' "Open File in Cursor"

# ===== MCP SERVER API (6) =====
echo -e "${BLUE}Testing MCP Server API...${NC}"
echo "-----------------------------------------"

test_endpoint "GET" "/api/mcp/servers" "" "List MCP Servers"
test_endpoint "POST" "/api/mcp/servers" '{"name":"test-mcp","command":"test"}' "Add MCP Server"
test_endpoint "DELETE" "/api/mcp/servers/test-mcp" "" "Remove MCP Server"
test_endpoint "GET" "/api/mcp/cli" "" "Get MCP CLI Status"
test_endpoint "POST" "/api/mcp/install" "" "Install MCP CLI"
test_endpoint "POST" "/api/mcp/update" "" "Update MCP CLI"

# ===== OTHER ENDPOINTS =====
echo -e "${BLUE}Testing Other Endpoints...${NC}"
echo "-----------------------------------------"

test_endpoint "GET" "/api/config" "" "Get Config"
test_endpoint "POST" "/api/transcribe" '{"audio":"base64data"}' "Transcribe Audio"
test_endpoint "POST" "/api/search" '{"query":"test","path":"/"}' "Search Files"
test_endpoint "POST" "/api/terminal/execute" '{"command":"echo test"}' "Execute Command"
test_endpoint "POST" "/api/upload" "" "Upload File"
test_endpoint "GET" "/api/export/project/test-project" "" "Export Project"
test_endpoint "GET" "/api/health" "" "Health Check"

# ===== WEBSOCKET TEST =====
echo -e "${BLUE}Testing WebSocket Connections...${NC}"
echo "-----------------------------------------"

# Test WebSocket connection
echo "Testing WebSocket at wss://href-melbourne-quickly-shipping.trycloudflare.com/ws..."
(
    echo '{"type":"test","content":"ping"}' | websocat -t "wss://href-melbourne-quickly-shipping.trycloudflare.com/ws" &
    WSPID=$!
    sleep 2
    kill $WSPID 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} WebSocket connection successful"
    else
        echo -e "${RED}✗${NC} WebSocket connection failed"
    fi
) 2>/dev/null || echo -e "${YELLOW}⚠${NC} websocat not installed, skipping WebSocket test"

echo ""
echo "========================================="
echo "TEST RESULTS SUMMARY"
echo "========================================="
echo -e "Total Tests: ${BLUE}$TOTAL_TESTS${NC}"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
echo -e "Success Rate: $(echo "scale=2; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc)%"
echo "========================================="