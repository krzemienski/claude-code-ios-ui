# iOS Claude Code UI - Deployment Guide

**Version**: 1.0.0  
**Last Updated**: January 21, 2025

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Development Setup](#development-setup)
3. [Production Build](#production-build)
4. [Backend Deployment](#backend-deployment)
5. [iOS App Deployment](#ios-app-deployment)
6. [Testing](#testing)
7. [Monitoring](#monitoring)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

### Development Environment
- **macOS**: Ventura 13.0 or later
- **Xcode**: 15.0 or later
- **iOS SDK**: 17.0+
- **Node.js**: 18.0+ (for backend)
- **npm**: 9.0+ (for backend)
- **Git**: 2.0+
- **Docker**: Optional for containerized deployment

### Apple Developer Requirements
- Apple Developer Account ($99/year)
- App Store Connect access
- Valid signing certificates
- Provisioning profiles configured

## Development Setup

### 1. Clone the Repository
```bash
git clone https://github.com/your-org/claude-code-ios-ui.git
cd claude-code-ios-ui
```

### 2. Backend Setup
```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Create environment file
cp .env.example .env

# Edit .env with your configuration
nano .env
```

#### Backend Environment Variables (.env)
```env
# Server Configuration
PORT=3004
HOST=0.0.0.0

# Database
DB_PATH=./data/store.db
AUTH_DB_PATH=./data/auth.db

# JWT Configuration
JWT_SECRET=your-secure-jwt-secret-here
JWT_EXPIRY=7d

# Security
CORS_ORIGIN=*
RATE_LIMIT_WINDOW=60000
RATE_LIMIT_MAX=100

# WebSocket
WS_HEARTBEAT_INTERVAL=30000
WS_TIMEOUT=120000

# File Operations
MAX_FILE_SIZE=10485760
ALLOWED_FILE_TYPES=.js,.ts,.swift,.json,.md,.txt

# Git Configuration
GIT_DEFAULT_BRANCH=main
GIT_AUTO_FETCH=true

# MCP Servers (optional)
MCP_DEFAULT_TIMEOUT=30000
MCP_MAX_CONNECTIONS=10
```

### 3. Start Backend Server
```bash
# Development mode with auto-reload
npm run dev

# Production mode
npm start

# With PM2 (recommended for production)
npm install -g pm2
pm2 start server/index.js --name claude-backend
```

### 4. iOS App Setup
```bash
# Navigate to iOS directory
cd ../ClaudeCodeUI-iOS

# Open in Xcode
open ClaudeCodeUI.xcodeproj

# Or use xcodebuild
xcodebuild -list
```

## Production Build

### 1. Pre-Build Checklist

#### Code Quality
- [ ] Remove all debug print statements
- [ ] Remove hardcoded development tokens
- [ ] Update API URLs to production endpoints
- [ ] Disable verbose logging
- [ ] Remove test data and mock responses

#### Configuration Updates
```swift
// AppConfig.swift - Update for production
struct AppConfig {
    static let baseURL = "https://api.claudecode.com"  // Production URL
    static let wsURL = "wss://api.claudecode.com/ws"
    static let shellWsURL = "wss://api.claudecode.com/shell"
    static let isDebugMode = false
    static let enableLogging = false
}
```

#### Security
- [ ] Enable certificate pinning
- [ ] Implement jailbreak detection
- [ ] Add obfuscation for sensitive strings
- [ ] Enable App Transport Security (ATS)
- [ ] Configure Keychain for token storage

### 2. Build Configuration

#### Update Info.plist
```xml
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
<key>CFBundleVersion</key>
<string>1</string>
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

#### Configure Build Settings
1. Select project in Xcode
2. Choose "ClaudeCodeUI" target
3. Build Settings tab:
   - **Swift Compiler - Optimization**: Whole Module Optimization
   - **Build Active Architecture Only**: No
   - **Enable Bitcode**: Yes (if required)
   - **Strip Debug Symbols**: Yes

### 3. Create Production Build

#### Using Xcode
1. Select "Any iOS Device (arm64)" as destination
2. Product → Archive
3. Window → Organizer
4. Select archive → Distribute App
5. Choose "App Store Connect" → Upload

#### Using Command Line
```bash
# Clean build folder
xcodebuild clean -project ClaudeCodeUI.xcodeproj -scheme ClaudeCodeUI

# Create archive
xcodebuild archive \
  -project ClaudeCodeUI.xcodeproj \
  -scheme ClaudeCodeUI \
  -archivePath ./build/ClaudeCodeUI.xcarchive \
  -configuration Release \
  CODE_SIGN_IDENTITY="iPhone Distribution: Your Company" \
  PROVISIONING_PROFILE_SPECIFIER="your-profile-name"

# Export IPA
xcodebuild -exportArchive \
  -archivePath ./build/ClaudeCodeUI.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist
```

#### ExportOptions.plist
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>iPhone Distribution</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.claudecode.ui</key>
        <string>ClaudeCodeUI Distribution</string>
    </dict>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <true/>
</dict>
</plist>
```

## Backend Deployment

### Option 1: Docker Deployment

#### Dockerfile
```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci --only=production

# Copy application
COPY . .

# Create data directory
RUN mkdir -p /app/data

# Expose port
EXPOSE 3004

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js || exit 1

# Start server
CMD ["node", "server/index.js"]
```

#### docker-compose.yml
```yaml
version: '3.8'

services:
  backend:
    build: ./backend
    ports:
      - "3004:3004"
    environment:
      - NODE_ENV=production
      - JWT_SECRET=${JWT_SECRET}
    volumes:
      - ./data:/app/data
      - ./logs:/app/logs
    restart: unless-stopped
    networks:
      - claudecode

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/ssl
    depends_on:
      - backend
    networks:
      - claudecode

networks:
  claudecode:
    driver: bridge
```

### Option 2: Cloud Deployment (AWS/GCP/Azure)

#### AWS EC2 Deployment
```bash
# SSH into EC2 instance
ssh -i your-key.pem ec2-user@your-instance.amazonaws.com

# Install Node.js
curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install nodejs -y

# Clone and setup
git clone https://github.com/your-org/claude-code-ios-ui.git
cd claude-code-ios-ui/backend
npm install --production

# Setup PM2
sudo npm install -g pm2
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

#### ecosystem.config.js
```javascript
module.exports = {
  apps: [{
    name: 'claude-backend',
    script: './server/index.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3004
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    max_memory_restart: '1G',
    autorestart: true,
    watch: false
  }]
};
```

### Option 3: Serverless (Vercel/Netlify)

#### vercel.json
```json
{
  "version": 2,
  "builds": [
    {
      "src": "server/index.js",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/api/(.*)",
      "dest": "server/index.js"
    },
    {
      "src": "/ws",
      "dest": "server/index.js"
    }
  ]
}
```

## iOS App Deployment

### 1. TestFlight Beta Testing

#### Upload to TestFlight
1. Archive and upload build via Xcode
2. Log in to App Store Connect
3. Navigate to "My Apps" → Your App → TestFlight
4. Add build to test group
5. Add external testers (up to 10,000)
6. Submit for Beta App Review

#### Beta Testing Checklist
- [ ] Test on multiple devices (iPhone, iPad)
- [ ] Test on different iOS versions (17.0+)
- [ ] Verify all API endpoints work
- [ ] Test WebSocket reconnection
- [ ] Check memory usage and performance
- [ ] Validate error handling
- [ ] Test offline mode behavior

### 2. App Store Submission

#### App Store Connect Setup
1. Create new app in App Store Connect
2. Fill in app information:
   - App name: Claude Code UI
   - Primary language: English
   - Bundle ID: com.claudecode.ui
   - SKU: CLAUDECODEUI001

#### Required Assets
- **App Icon**: 1024x1024px
- **Screenshots**:
  - iPhone 6.7" (1290 x 2796)
  - iPhone 6.5" (1242 x 2688)
  - iPhone 5.5" (1242 x 2208)
  - iPad Pro 12.9" (2048 x 2732)
- **App Preview Video**: Optional (15-30 seconds)

#### App Description
```
Claude Code UI - AI-Powered iOS Development Assistant

Transform your iOS development workflow with Claude Code UI, a powerful native client that brings AI assistance directly to your mobile device.

Key Features:
• Real-time AI chat with Claude for coding assistance
• WebSocket-based communication for instant responses
• Git integration with 20+ operations
• Terminal access with full ANSI color support
• File explorer with syntax highlighting
• Session management for organized workflows
• MCP server management
• Cyberpunk-themed UI with stunning visual effects

Perfect for:
• iOS developers on the go
• Code reviews and debugging
• Learning new programming concepts
• Managing development projects

Requirements:
• iOS 17.0 or later
• Active internet connection
• Backend server access (self-hosted or cloud)
```

#### Privacy Policy
Create and host a privacy policy covering:
- Data collection practices
- User information storage
- Third-party services used
- Data retention policies
- User rights and contact information

### 3. Release Process

#### Pre-Release Checklist
- [ ] All tests passing
- [ ] No critical bugs in TestFlight
- [ ] Performance metrics met
- [ ] Security audit completed
- [ ] Documentation updated
- [ ] Release notes prepared

#### Submit for Review
1. Select build from TestFlight
2. Complete app information
3. Add screenshots and descriptions
4. Set pricing (Free/Paid)
5. Select availability (countries)
6. Submit for review

#### Review Process Timeline
- Initial review: 24-48 hours
- If rejected: Address issues and resubmit
- After approval: Release immediately or schedule

## Testing

### Automated Testing
```bash
# Run unit tests
xcodebuild test \
  -project ClaudeCodeUI.xcodeproj \
  -scheme ClaudeCodeUI \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=18.6'

# Run UI tests
xcodebuild test \
  -project ClaudeCodeUI.xcodeproj \
  -scheme ClaudeCodeUIUITests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=18.6'
```

### Performance Testing
```bash
# Use Instruments for profiling
instruments -t "Time Profiler" \
  -D trace.trace \
  ClaudeCodeUI.app
```

## Monitoring

### Backend Monitoring

#### Health Check Endpoint
```javascript
// healthcheck.js
const http = require('http');

const options = {
  hostname: 'localhost',
  port: 3004,
  path: '/api/health',
  timeout: 2000
};

const req = http.get(options, (res) => {
  if (res.statusCode === 200) {
    process.exit(0);
  } else {
    process.exit(1);
  }
});

req.on('error', () => {
  process.exit(1);
});

req.end();
```

#### Logging with Winston
```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});
```

### iOS App Monitoring

#### Crash Reporting (Firebase Crashlytics)
```swift
import FirebaseCrashlytics

// In AppDelegate
FirebaseApp.configure()
Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)

// Log custom events
Crashlytics.crashlytics().log("User started chat session")
```

#### Analytics
```swift
import FirebaseAnalytics

// Track events
Analytics.logEvent("chat_message_sent", parameters: [
    "session_id": sessionId,
    "message_length": messageLength
])
```

## Troubleshooting

### Common Issues

#### Backend Issues

**Port Already in Use**
```bash
# Find process using port 3004
lsof -i :3004
# Kill process
kill -9 <PID>
```

**Database Locked**
```bash
# Remove lock file
rm backend/data/*.db-journal
# Restart server
pm2 restart claude-backend
```

**WebSocket Connection Failed**
- Check firewall settings
- Verify CORS configuration
- Ensure SSL certificates are valid
- Check nginx proxy settings

#### iOS App Issues

**Code Signing Errors**
```bash
# Reset certificates
security delete-certificate -c "iPhone Developer"
# Re-download from Apple Developer portal
```

**Archive Failed**
```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData
# Clean build folder
xcodebuild clean
```

**App Crashes on Launch**
- Check Info.plist configuration
- Verify minimum iOS version
- Review crash logs in Xcode Organizer
- Test on physical device

### Performance Optimization

#### Backend
- Enable gzip compression
- Implement Redis caching
- Use database indexing
- Enable HTTP/2
- Implement CDN for static assets

#### iOS App
- Lazy load images
- Implement pagination
- Use background queues
- Cache API responses
- Optimize image assets

### Security Hardening

#### Backend
```javascript
// Rate limiting
const rateLimit = require('express-rate-limit');
app.use(rateLimit({
  windowMs: 60000,
  max: 100
}));

// Helmet for security headers
const helmet = require('helmet');
app.use(helmet());

// Input validation
const validator = require('validator');
```

#### iOS App
```swift
// Keychain storage
KeychainWrapper.standard.set(token, forKey: "authToken")

// Certificate pinning
let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
    certificates: ServerTrustPolicy.certificates(),
    validateCertificateChain: true,
    validateHost: true
)

// Jailbreak detection
if UIDevice.current.isJailbroken {
    // Block app functionality
}
```

## Support

### Resources
- GitHub Issues: https://github.com/your-org/claude-code-ios-ui/issues
- Documentation: See CLAUDE.md
- API Reference: See API_DOCUMENTATION.md
- Testing Guide: See TESTING_REPORT.md

### Contact
- Email: support@claudecode.com
- Discord: https://discord.gg/claudecode
- Twitter: @claudecodeui

---

*This deployment guide is part of the iOS Claude Code UI v1.0.0 release*