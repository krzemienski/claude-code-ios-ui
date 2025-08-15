#!/bin/bash
# Quick test script for the tunnel
URL="https://mileage-maui-vip-ski.trycloudflare.com"

echo "Testing $URL..."
echo ""
echo "Auth Status:"
curl -s "$URL/api/auth/status" | jq . 2>/dev/null || curl -s "$URL/api/auth/status"
echo ""
echo "Projects:"
curl -s "$URL/api/projects" | jq . 2>/dev/null || curl -s "$URL/api/projects"
