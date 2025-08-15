#!/usr/bin/env node

/**
 * Updates the backend configuration to work with CloudFlare Tunnel
 * This script modifies the backend server to properly handle proxied requests
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

console.log('🔧 Updating Backend Configuration for CloudFlare Tunnel');
console.log('=====================================================\n');

// Create or update .env file with CloudFlare settings
const envPath = path.join(__dirname, '../../.env');
const envContent = `
# CloudFlare Tunnel Configuration
CLOUDFLARE_TUNNEL_ENABLED=true
TRUST_PROXY=true
ALLOWED_ORIGINS=*
SECURE_COOKIES=true

# Backend Server Configuration
PORT=3004
NODE_ENV=production

# WebSocket Configuration
WS_KEEPALIVE_INTERVAL=30000
WS_MAX_PAYLOAD=10485760

# Security Headers for CloudFlare
HELMET_ENABLED=true
RATE_LIMIT_ENABLED=true
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
`;

// Check if .env exists and append or create
if (fs.existsSync(envPath)) {
    const existingEnv = fs.readFileSync(envPath, 'utf8');
    if (!existingEnv.includes('CLOUDFLARE_TUNNEL_ENABLED')) {
        fs.appendFileSync(envPath, envContent);
        console.log('✅ Updated .env file with CloudFlare settings');
    } else {
        console.log('ℹ️  CloudFlare settings already exist in .env');
    }
} else {
    fs.writeFileSync(envPath, envContent.trim());
    console.log('✅ Created .env file with CloudFlare settings');
}

// Create middleware for CloudFlare proxy handling
const middlewarePath = path.join(__dirname, '../../server/middleware/cloudflare.js');
const middlewareContent = `/**
 * CloudFlare Tunnel Middleware
 * Handles headers and security for CloudFlare proxied requests
 */

export function cloudflareMiddleware(req, res, next) {
    // Trust CloudFlare proxy headers
    if (process.env.CLOUDFLARE_TUNNEL_ENABLED === 'true') {
        // Get real IP from CloudFlare headers
        const cfConnectingIp = req.headers['cf-connecting-ip'];
        const xForwardedFor = req.headers['x-forwarded-for'];
        const xRealIp = req.headers['x-real-ip'];
        
        req.realIp = cfConnectingIp || xRealIp || 
                     (xForwardedFor ? xForwardedFor.split(',')[0].trim() : null) || 
                     req.ip;
        
        // Get original protocol
        const cfVisitorScheme = req.headers['cf-visitor'];
        if (cfVisitorScheme) {
            try {
                const visitor = JSON.parse(cfVisitorScheme);
                req.protocol = visitor.scheme || req.protocol;
            } catch (e) {
                // Ignore JSON parse errors
            }
        }
        
        // Add CloudFlare Ray ID for debugging
        req.cfRayId = req.headers['cf-ray'];
        
        // Log CloudFlare request info
        console.log(\`[CF] Request from \${req.realIp} - Ray: \${req.cfRayId}\`);
    }
    
    next();
}

export function setupCloudflareHeaders(app) {
    // Set up trust proxy for CloudFlare
    if (process.env.CLOUDFLARE_TUNNEL_ENABLED === 'true') {
        // Trust CloudFlare proxy IPs
        app.set('trust proxy', true);
        
        // Add security headers
        app.use((req, res, next) => {
            // Security headers
            res.setHeader('X-Content-Type-Options', 'nosniff');
            res.setHeader('X-Frame-Options', 'DENY');
            res.setHeader('X-XSS-Protection', '1; mode=block');
            res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
            
            // CORS headers for CloudFlare
            const origin = req.headers.origin;
            if (process.env.ALLOWED_ORIGINS === '*' || 
                (process.env.ALLOWED_ORIGINS && process.env.ALLOWED_ORIGINS.split(',').includes(origin))) {
                res.setHeader('Access-Control-Allow-Origin', origin || '*');
                res.setHeader('Access-Control-Allow-Credentials', 'true');
            }
            
            next();
        });
    }
}

export function handleWebSocketUpgrade(wss, server) {
    // Special handling for WebSocket connections through CloudFlare
    server.on('upgrade', (request, socket, head) => {
        // Check if this is coming through CloudFlare
        if (process.env.CLOUDFLARE_TUNNEL_ENABLED === 'true') {
            const cfConnectingIp = request.headers['cf-connecting-ip'];
            const cfRayId = request.headers['cf-ray'];
            
            console.log(\`[CF-WS] WebSocket upgrade from \${cfConnectingIp} - Ray: \${cfRayId}\`);
            
            // Add CloudFlare headers to the request
            request.cfConnectingIp = cfConnectingIp;
            request.cfRayId = cfRayId;
        }
    });
}
`;

// Ensure middleware directory exists
const middlewareDir = path.dirname(middlewarePath);
if (!fs.existsSync(middlewareDir)) {
    fs.mkdirSync(middlewareDir, { recursive: true });
}

fs.writeFileSync(middlewarePath, middlewareContent);
console.log('✅ Created CloudFlare middleware');

// Create startup script that ensures backend is running before tunnel
const startupScriptPath = path.join(__dirname, '../start-with-tunnel.sh');
const startupScriptContent = `#!/bin/bash

# Start Backend Server and CloudFlare Tunnel Together
# This ensures the backend is running before the tunnel connects

set -e

echo "🚀 Starting Claude Code UI Backend with CloudFlare Tunnel"
echo "========================================================"

# Colors for output
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
RED='\\033[0;31m'
NC='\\033[0m' # No Color

# Function to cleanup on exit
cleanup() {
    echo -e "\\n\${YELLOW}Shutting down...\\${NC}"
    
    # Kill backend server
    if [ ! -z "$BACKEND_PID" ]; then
        echo "Stopping backend server (PID: $BACKEND_PID)..."
        kill $BACKEND_PID 2>/dev/null || true
    fi
    
    # Kill tunnel
    if [ ! -z "$TUNNEL_PID" ]; then
        echo "Stopping CloudFlare tunnel (PID: $TUNNEL_PID)..."
        kill $TUNNEL_PID 2>/dev/null || true
    fi
    
    exit 0
}

# Set up trap to cleanup on script exit
trap cleanup EXIT INT TERM

# Change to backend directory
cd "$(dirname "$0")/../.."

# Step 1: Start the backend server
echo -e "\\${YELLOW}Starting backend server...\\${NC}"

# Check if node modules are installed
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi

# Start the backend server in the background
npm run server &
BACKEND_PID=$!

# Wait for backend to be ready
echo -e "\\${YELLOW}Waiting for backend to be ready...\\${NC}"
MAX_TRIES=30
TRIES=0
while ! curl -s http://localhost:3004/api/health > /dev/null 2>&1; do
    sleep 1
    TRIES=$((TRIES + 1))
    if [ $TRIES -ge $MAX_TRIES ]; then
        echo -e "\\${RED}Backend failed to start after 30 seconds\\${NC}"
        exit 1
    fi
    echo -n "."
done
echo ""
echo -e "\\${GREEN}✓ Backend is running on http://localhost:3004\\${NC}"

# Step 2: Start CloudFlare Tunnel
echo -e "\\n\\${YELLOW}Starting CloudFlare Tunnel...\\${NC}"
TUNNEL_NAME="claude-code-ui-backend"

# Check if tunnel exists
if ! cloudflared tunnel list | grep -q "$TUNNEL_NAME"; then
    echo -e "\\${RED}Tunnel '$TUNNEL_NAME' does not exist. Please run setup-tunnel.sh first.\\${NC}"
    exit 1
fi

# Start the tunnel
cloudflared tunnel run "$TUNNEL_NAME" &
TUNNEL_PID=$!

echo -e "\\${GREEN}✓ CloudFlare Tunnel is running\\${NC}"
echo ""
echo "Your backend is now accessible at:"
echo "  • Local: http://localhost:3004"
echo "  • Remote: https://[your-subdomain].[your-domain]"
echo ""
echo "Press Ctrl+C to stop both services"
echo ""

# Wait for either process to exit
wait -n $BACKEND_PID $TUNNEL_PID

# If we get here, one of the processes died
echo -e "\\${RED}One of the services stopped unexpectedly\\${NC}"
exit 1
`;

fs.writeFileSync(startupScriptPath, startupScriptContent);
fs.chmodSync(startupScriptPath, '755');
console.log('✅ Created startup script');

// Create iOS configuration update script
const iosConfigPath = path.join(__dirname, '../update-ios-config.swift');
const iosConfigContent = `#!/usr/bin/env swift

/**
 * Updates iOS App Configuration for CloudFlare Tunnel
 * Run this after setting up your CloudFlare tunnel
 */

import Foundation

print("📱 Updating iOS App Configuration")
print("==================================\\n")

// Get CloudFlare tunnel URL from user
print("Enter your CloudFlare tunnel URL (e.g., https://claude-backend.example.com):")
guard let tunnelURL = readLine(), !tunnelURL.isEmpty else {
    print("❌ Invalid URL")
    exit(1)
}

// Configuration template for iOS app
let configContent = """
//
// CloudFlareConfig.swift
// ClaudeCodeUI
//
// CloudFlare Tunnel Configuration for Remote Access
//

import Foundation

struct CloudFlareConfig {
    /// CloudFlare tunnel URL for backend access
    static let tunnelURL = "\\(tunnelURL)"
    
    /// WebSocket URL for real-time chat
    static var webSocketURL: String {
        let wsProtocol = tunnelURL.hasPrefix("https") ? "wss" : "ws"
        let host = tunnelURL
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
        return "\\(wsProtocol)://\\(host)/ws"
    }
    
    /// Shell WebSocket URL
    static var shellWebSocketURL: String {
        let wsProtocol = tunnelURL.hasPrefix("https") ? "wss" : "ws"
        let host = tunnelURL
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
        return "\\(wsProtocol)://\\(host)/shell"
    }
    
    /// Check if we should use CloudFlare tunnel
    static var isRemoteMode: Bool {
        // You can toggle this based on network conditions or user preference
        return true
    }
    
    /// Get the appropriate base URL
    static var baseURL: String {
        if isRemoteMode {
            return tunnelURL
        } else {
            // Fallback to local network
            return "http://\\(getLocalIPAddress()):3004"
        }
    }
    
    /// Get local IP address for fallback
    private static func getLocalIPAddress() -> String {
        // This would normally detect your Mac's local IP
        // For now, return localhost
        return "localhost"
    }
}

// Update AppConfig to use CloudFlare tunnel
extension AppConfig {
    /// Override base URL when CloudFlare is enabled
    static var dynamicBaseURL: String {
        if CloudFlareConfig.isRemoteMode {
            return CloudFlareConfig.baseURL
        }
        return baseURL
    }
    
    /// Override WebSocket URL when CloudFlare is enabled
    static var dynamicWebSocketURL: String {
        if CloudFlareConfig.isRemoteMode {
            return CloudFlareConfig.webSocketURL
        }
        return webSocketURL
    }
}
"""

// Save configuration file
let configPath = "CloudFlareConfig.swift"
do {
    try configContent.write(toFile: configPath, atomically: true, encoding: .utf8)
    print("✅ Created \\(configPath)")
    print("")
    print("Next steps:")
    print("1. Copy CloudFlareConfig.swift to your iOS project")
    print("2. Add it to your Xcode project")
    print("3. Update ChatViewController to use CloudFlareConfig.baseURL")
    print("4. Update WebSocketManager to use CloudFlareConfig.webSocketURL")
    print("")
} catch {
    print("❌ Failed to create config file: \\(error)")
    exit(1)
}
`;

fs.writeFileSync(iosConfigPath, iosConfigContent);
fs.chmodSync(iosConfigPath, '755');
console.log('✅ Created iOS configuration updater');

console.log('\n✅ Backend configuration updated successfully!');
console.log('\nNext steps:');
console.log('1. Run ./setup-tunnel.sh to create your CloudFlare tunnel');
console.log('2. Run ./install-service.sh to set up automatic startup');
console.log('3. Run ./update-ios-config.swift to generate iOS configuration');
console.log('4. Use ./start-with-tunnel.sh to run both backend and tunnel together');