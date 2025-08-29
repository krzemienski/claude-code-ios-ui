# Production Deployment Configuration Guide

## Quick Start Production Checklist

### 1. Update AppConfig.swift
```swift
// Change from development:
static var backendURL = "http://192.168.0.43:3004"
static let websocketURL = "ws://192.168.0.43:3004/ws"
static let shellWebSocketURL = "ws://192.168.0.43:3004/shell"

// To production:
static var backendURL = "https://api.claudecode.com"
static let websocketURL = "wss://api.claudecode.com/ws"
static let shellWebSocketURL = "wss://api.claudecode.com/shell"

// Disable debug features:
static let enableDebugLogging = false
static var isDebugMode = false
```

### 2. Update Info.plist
```xml
<!-- Remove or restrict for production: -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>  <!-- Change to false -->
    <key>NSExceptionDomains</key>
    <dict>
        <key>api.claudecode.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
        </dict>
    </dict>
</dict>

<!-- Update version: -->
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
<key>CFBundleVersion</key>
<string>1</string>
```

### 3. Build Schemes Configuration

#### Create Production Scheme in Xcode:
1. Product → Scheme → Edit Scheme
2. Duplicate "ClaudeCodeUI" scheme
3. Name it "ClaudeCodeUI-Production"
4. Set Build Configuration to "Release"
5. Add environment variables:
   - `BACKEND_ENV`: `production`
   - `ENABLE_LOGGING`: `false`

### 4. Code Signing Setup
```bash
# Install certificates
security import production.p12 -P "password" -A -t cert -k ~/Library/Keychains/login.keychain

# Install provisioning profiles
cp *.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
```

### 5. App Store Connect Configuration

#### Basic Information:
- **App Name**: Claude Code
- **Bundle ID**: com.claudecode.ui
- **Primary Language**: English (U.S.)
- **Category**: Developer Tools
- **Secondary Category**: Productivity

#### App Description:
```
Claude Code is a powerful iOS client for Claude AI development workflows. Connect to your local or remote Claude Code backend server to manage projects, sessions, and leverage AI-powered coding assistance on the go.

Key Features:
• Real-time WebSocket communication for instant AI responses
• Comprehensive Git integration with 20+ operations
• Terminal access with full ANSI color support
• File explorer with syntax highlighting
• MCP server management
• Secure authentication with Keychain storage
• Cyberpunk-themed UI with dark mode
• Pull-to-refresh and swipe actions
• Offline support for cached data

Perfect for developers who want to access their Claude Code projects from anywhere, review code, manage Git repositories, and get AI assistance directly from their iPhone or iPad.
```

#### Keywords:
```
claude, ai, code, developer, git, terminal, programming, coding, assistant, ide
```

#### Screenshots Required:
1. iPhone 6.7" (1290 x 2796)
2. iPhone 6.5" (1242 x 2688)
3. iPhone 5.5" (1242 x 2208)
4. iPad Pro 12.9" (2048 x 2732)

#### Privacy Policy URL:
```
https://claudecode.com/privacy
```

#### Support URL:
```
https://claudecode.com/support
```

### 6. Build & Archive Commands

```bash
# Clean build folder
xcodebuild clean -project ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj \
  -scheme ClaudeCodeUI-Production

# Archive for App Store
xcodebuild archive \
  -project ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj \
  -scheme ClaudeCodeUI-Production \
  -archivePath ./build/ClaudeCode.xcarchive \
  -configuration Release \
  CODE_SIGN_IDENTITY="iPhone Distribution: Your Company" \
  PROVISIONING_PROFILE_SPECIFIER="ClaudeCode-AppStore"

# Export IPA
xcodebuild -exportArchive \
  -archivePath ./build/ClaudeCode.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist
```

### 7. ExportOptions.plist
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <true/>
    <key>compileBitcode</key>
    <true/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>iPhone Distribution</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.claudecode.ui</key>
        <string>ClaudeCode-AppStore</string>
    </dict>
</dict>
</plist>
```

### 8. TestFlight Setup

1. Upload IPA to App Store Connect:
```bash
xcrun altool --upload-app \
  -f build/ClaudeCode.ipa \
  -t ios \
  -u your@email.com \
  -p app-specific-password
```

2. Configure TestFlight:
   - Add internal testers (up to 100)
   - Add external testers (up to 10,000)
   - Set beta app description
   - Configure test information

### 9. Performance Monitoring

#### Firebase Setup (Optional):
```swift
// AppDelegate.swift
import Firebase

func application(_ application: UIApplication, 
                didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    #if !DEBUG
    FirebaseApp.configure()
    #endif
    return true
}
```

#### Sentry Setup (Optional):
```swift
import Sentry

SentrySDK.start { options in
    options.dsn = "YOUR_SENTRY_DSN"
    options.environment = "production"
    options.enableAutoSessionTracking = true
    options.attachScreenshots = true
}
```

### 10. Feature Flags (Optional)

```swift
// FeatureFlags.swift
struct FeatureFlags {
    static let cursorIntegration = false  // Enable in v1.1
    static let pushNotifications = false  // Enable in v1.2
    static let widgetExtension = false    // Enable in v1.3
    static let cloudSync = false          // Enable in v2.0
}
```

### 11. CI/CD Pipeline (GitHub Actions)

```yaml
name: Deploy to App Store

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: latest-stable
      
      - name: Install certificates
        run: |
          # Install certificates from secrets
          
      - name: Build and archive
        run: |
          xcodebuild archive \
            -project ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj \
            -scheme ClaudeCodeUI-Production \
            -archivePath $PWD/build/ClaudeCode.xcarchive
            
      - name: Export IPA
        run: |
          xcodebuild -exportArchive \
            -archivePath $PWD/build/ClaudeCode.xcarchive \
            -exportOptionsPlist ExportOptions.plist \
            -exportPath $PWD/build
            
      - name: Upload to App Store
        run: |
          xcrun altool --upload-app \
            -f build/ClaudeCode.ipa \
            -u ${{ secrets.APPLE_ID }} \
            -p ${{ secrets.APP_PASSWORD }}
```

### 12. Post-Release Monitoring

#### Key Metrics to Track:
- Crash-free users rate (target: >99.5%)
- App launch time (target: <2s)
- Memory usage (target: <150MB)
- Network error rate (target: <1%)
- WebSocket connection success (target: >95%)

#### Monitoring Tools:
- App Store Connect Analytics
- Firebase Crashlytics
- Sentry Performance Monitoring
- Custom analytics events

### 13. Rollback Plan

If critical issues are discovered:
1. Remove from sale in App Store Connect
2. Prepare hotfix on `hotfix/v1.0.1` branch
3. Expedite review request to Apple
4. Deploy fix within 24-48 hours
5. Notify users via in-app messaging

### 14. Production Backend Requirements

Ensure backend server has:
- SSL/TLS certificates configured
- CORS properly configured for app bundle ID
- Rate limiting implemented
- Authentication required for all endpoints
- Database backups configured
- Monitoring and alerting setup
- Horizontal scaling capability

### 15. Final Pre-Release Checklist

- [ ] All production URLs configured
- [ ] Debug logging disabled
- [ ] Crash reporting enabled
- [ ] Analytics configured
- [ ] Code signing valid
- [ ] App icons provided (all sizes)
- [ ] Launch screen updated
- [ ] App Store metadata complete
- [ ] Screenshots captured
- [ ] Privacy policy live
- [ ] Support page live
- [ ] TestFlight beta complete
- [ ] Performance benchmarks met
- [ ] Security audit passed
- [ ] Accessibility audit passed

---

## Estimated Timeline

- **Configuration Updates**: 2-4 hours
- **Testing on Devices**: 4-6 hours
- **App Store Submission**: 1-2 hours
- **Apple Review**: 24-48 hours (expedited) or 3-7 days (normal)
- **Total Time to Store**: 3-9 days

---

*Last updated: January 29, 2025*