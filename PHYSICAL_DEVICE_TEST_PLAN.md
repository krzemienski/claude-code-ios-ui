# 📱 Physical Device Test Plan

## Device Test Matrix

### Primary Devices (Must Test)
| Device | iOS Version | Priority | Test Focus |
|--------|------------|----------|------------|
| iPhone 16 Pro Max | iOS 18.0+ | P0 | Full feature validation |
| iPhone 15 Pro | iOS 17.5+ | P0 | Performance benchmarks |
| iPhone 14 | iOS 17.0+ | P1 | Compatibility testing |
| iPhone 13 mini | iOS 17.0+ | P1 | Small screen layout |

### Secondary Devices (Nice to Have)
| Device | iOS Version | Priority | Test Focus |
|--------|------------|----------|------------|
| iPad Pro 12.9" | iOS 17.0+ | P2 | Tablet layout |
| iPad Air | iOS 17.0+ | P2 | Mid-range performance |
| iPhone SE 3 | iOS 17.0+ | P2 | Budget device testing |

## Pre-Test Setup

### 1. Device Preparation
- [ ] Update to latest iOS version
- [ ] Enable Developer Mode: Settings → Privacy & Security → Developer Mode
- [ ] Free up storage: At least 500MB available
- [ ] Disable Low Power Mode
- [ ] Connect to stable WiFi
- [ ] Enable Face ID/Touch ID for testing

### 2. Backend Setup
```bash
# Start backend server accessible from device
cd backend

# Option 1: Local network (same WiFi)
npm start
# Note the IP address (e.g., 192.168.1.100:3004)

# Option 2: CloudFlare Tunnel (remote access)
cloudflared tunnel --url http://localhost:3004
# Note the public URL provided
```

### 3. App Configuration
- [ ] Update `AppConfig.swift` with backend URL
- [ ] Set proper code signing team
- [ ] Configure push notification certificates (if testing)
- [ ] Add device UDID to provisioning profile

## Test Scenarios

### 🚀 Launch & Performance Tests

#### Cold Start Test
1. Force quit app
2. Clear device memory (restart if needed)
3. Launch app
4. **Measure**: Time to first screen
5. **Target**: <2 seconds
6. **Record**: Actual time: _____ seconds

#### Warm Start Test
1. Launch app
2. Press home button
3. Re-open app
4. **Measure**: Time to restore
5. **Target**: <500ms
6. **Record**: Actual time: _____ ms

#### Memory Usage Test
1. Navigate through all screens
2. Create 10 sessions
3. Send 50 messages
4. Check memory in Xcode
5. **Target**: <150MB baseline
6. **Record**: Peak usage: _____ MB

### 🔌 Connectivity Tests

#### WebSocket Connection
- [ ] Connect on WiFi
- [ ] Connect on cellular (4G/5G)
- [ ] Switch between WiFi/cellular
- [ ] Handle airplane mode
- [ ] Test auto-reconnection
- [ ] Verify message delivery

#### Network Interruption
1. Send message
2. Turn on airplane mode
3. Wait 10 seconds
4. Turn off airplane mode
5. **Verify**: Message retries and delivers
6. **Record**: Reconnection time: _____ seconds

### 🔐 Security Tests

#### Face ID Test (iPhone 16/15/14)
1. Enable app lock in settings
2. Background app for 3 minutes
3. Return to app
4. **Verify**: Face ID prompt appears
5. Authenticate with Face ID
6. **Verify**: App unlocks successfully

#### Touch ID Test (iPhone SE/older)
1. Enable app lock
2. Background app
3. Return after timeout
4. **Verify**: Touch ID prompt
5. Authenticate
6. **Verify**: Success

#### Passcode Fallback
1. Fail biometric 3 times
2. **Verify**: Passcode option appears
3. Enter device passcode
4. **Verify**: App unlocks

### 📱 UI/UX Tests

#### Orientation Tests
- [ ] Portrait mode navigation
- [ ] Landscape mode (if supported)
- [ ] Rotation during typing
- [ ] Rotation during loading

#### Gesture Tests
- [ ] Swipe to delete sessions
- [ ] Pull to refresh
- [ ] Pinch to zoom (code view)
- [ ] Long press for context menu
- [ ] Edge swipe for back navigation

#### Keyboard Tests
1. Type message
2. Use emoji keyboard
3. Use voice dictation
4. Test with external keyboard
5. **Verify**: No layout issues

#### Dark Mode Test
1. Enable system dark mode
2. **Verify**: UI adapts correctly
3. Check contrast ratios
4. Test neon effects visibility

### 💬 Core Feature Tests

#### Message Flow
1. Create new session
2. Send text message
3. **Verify**: Status updates (sending → delivered)
4. Receive AI response
5. **Verify**: Proper formatting
6. Send code snippet
7. **Verify**: Syntax highlighting

#### File Operations
1. Browse project files
2. Open code file
3. **Verify**: Syntax highlighting
4. Create new file
5. Edit and save
6. **Verify**: Changes persist

#### Terminal Tests
1. Open terminal tab
2. Execute `ls` command
3. **Verify**: Output displayed
4. Test ANSI colors: `ls --color`
5. Test long output: `find /`
6. **Verify**: Scrolling works

#### Git Integration
1. View git status
2. Stage changes
3. Create commit
4. **Verify**: Commit success
5. View commit history
6. **Verify**: Proper display

### 🔋 Battery & Thermal Tests

#### Battery Drain Test
1. Note starting battery %
2. Use app for 1 hour continuously
3. Note ending battery %
4. **Target**: <5% drain per hour
5. **Record**: Actual drain: _____ %

#### Thermal Test
1. Use app for 30 minutes
2. Monitor device temperature
3. **Verify**: No overheating warnings
4. **Record**: Subjective heat level (1-10): _____

### 🌐 Accessibility Tests

#### VoiceOver Test
1. Enable VoiceOver
2. Navigate all screens
3. **Verify**: All elements labeled
4. Test custom actions
5. **Record**: Issues found: _____

#### Dynamic Type Test
1. Set text size to largest
2. **Verify**: Text remains readable
3. **Verify**: No layout breaks
4. Set text size to smallest
5. **Verify**: Still usable

### 📊 Performance Metrics

#### Frame Rate Test
1. Scroll through long lists
2. Monitor in Instruments
3. **Target**: 60 fps consistently
4. **Record**: Average fps: _____
5. **Record**: Drops below 60: _____ times

#### Network Usage Test
1. Reset cellular statistics
2. Use app for 30 minutes
3. Check data usage
4. **Target**: <10MB for typical session
5. **Record**: Actual usage: _____ MB

## Bug Report Template

### Bug #___: [Title]
**Device**: iPhone ___ (iOS ___)
**Severity**: P0/P1/P2/P3
**Frequency**: Always/Often/Sometimes/Once

**Steps to Reproduce**:
1. 
2. 
3. 

**Expected Result**:

**Actual Result**:

**Screenshot/Video**: [Attach if applicable]

**Additional Notes**:

## Performance Report

### Device: ________________
### iOS Version: ____________
### Test Date: ______________

| Metric | Target | Actual | Pass/Fail |
|--------|--------|--------|-----------|
| Cold Start | <2s | ___s | ⬜ |
| Warm Start | <500ms | ___ms | ⬜ |
| Memory (baseline) | <150MB | ___MB | ⬜ |
| Memory (peak) | <300MB | ___MB | ⬜ |
| Frame Rate | 60fps | ___fps | ⬜ |
| Battery/hour | <5% | ___% | ⬜ |
| Network/session | <10MB | ___MB | ⬜ |
| Crash Rate | 0% | ___% | ⬜ |

### Overall Assessment
- [ ] Ready for TestFlight
- [ ] Needs minor fixes
- [ ] Needs major fixes
- [ ] Not ready

### Top Issues
1. 
2. 
3. 

### Recommendations
1. 
2. 
3. 

## Post-Test Actions

### Immediate (P0 bugs)
- [ ] Fix crash issues
- [ ] Fix data loss bugs
- [ ] Fix security issues

### Before TestFlight (P1)
- [ ] Fix major UI issues
- [ ] Fix performance problems
- [ ] Fix connectivity issues

### Nice to Have (P2+)
- [ ] Polish animations
- [ ] Optimize battery usage
- [ ] Enhance accessibility

## Test Sign-off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Developer | __________ | __________ | __/__/__ |
| QA Tester | __________ | __________ | __/__/__ |
| Product Owner | __________ | __________ | __/__/__ |

---

*Test Plan Version: 1.0*
*Last Updated: January 21, 2025*