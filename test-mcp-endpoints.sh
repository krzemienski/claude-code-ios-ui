#!/bin/bash

# Test MCP REST API endpoints
echo "Testing MCP Server Management Endpoints..."
echo "========================================="

# Base URL
BASE_URL="http://localhost:3004/api/mcp"

# Test 1: List MCP servers
echo -e "\n1. GET /api/mcp/servers - List all servers:"
curl -s -X GET "$BASE_URL/servers" | jq '.'

# Test 2: Add a new MCP server
echo -e "\n2. POST /api/mcp/servers - Add new server:"
NEW_SERVER=$(curl -s -X POST "$BASE_URL/servers" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test MCP Server",
    "url": "http://localhost:5000/mcp",
    "description": "Test server for iOS app",
    "type": "rest",
    "apiKey": null,
    "isDefault": false
  }')
echo "$NEW_SERVER" | jq '.'
SERVER_ID=$(echo "$NEW_SERVER" | jq -r '.id')

# Test 3: Test connection to the server
echo -e "\n3. POST /api/mcp/servers/:id/test - Test connection:"
curl -s -X POST "$BASE_URL/servers/$SERVER_ID/test" | jq '.'

# Test 4: Update the server
echo -e "\n4. PUT /api/mcp/servers/:id - Update server:"
curl -s -X PUT "$BASE_URL/servers/$SERVER_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Test Server",
    "description": "Updated description"
  }' | jq '.'

# Test 5: Execute CLI command
echo -e "\n5. POST /api/mcp/cli - Execute CLI command:"
curl -s -X POST "$BASE_URL/cli" \
  -H "Content-Type: application/json" \
  -d '{
    "command": "list",
    "args": ["--verbose"]
  }' | jq '.'

# Test 6: Delete the server
echo -e "\n6. DELETE /api/mcp/servers/:id - Delete server:"
curl -s -X DELETE "$BASE_URL/servers/$SERVER_ID" -o /dev/null -w "%{http_code}\n"

# Test 7: Verify deletion
echo -e "\n7. GET /api/mcp/servers - Verify deletion:"
curl -s -X GET "$BASE_URL/servers" | jq '. | length'

echo -e "\n✅ All MCP endpoint tests completed!"