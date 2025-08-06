# iOS Claude Code UI - Comprehensive Testing Guide

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Backend Setup](#backend-setup)
4. [iOS Project Setup](#ios-project-setup)
5. [Testing Procedures](#testing-procedures)
6. [Log Monitoring](#log-monitoring)
7. [Performance Benchmarks](#performance-benchmarks)
8. [Bug Reporting](#bug-reporting)

## Prerequisites

### Required Software
- macOS 14.0+ (Sonoma or later)
- Xcode 15.0+ 
- iOS Simulator with iOS 17.0+
- Node.js 18.0+ and npm 9.0+
- Git 2.40+
- (Optional) Charles Proxy or Proxyman for network debugging

### Hardware Requirements
- Mac with Apple Silicon (M1/M2/M3) or Intel processor
- Minimum 8GB RAM (16GB recommended)
- 20GB free disk space
- Active internet connection

## Environment Setup

### Task 1-20: Initial Setup
1. ✅ Install Xcode from Mac App Store
2. ✅ Launch Xcode and accept license agreements
3. ✅ Install additional components when prompted
4. ✅ Open Xcode > Settings > Platforms
5. ✅ Download iOS 17.0+ Simulator
6. ✅ Install Node.js from nodejs.org or via Homebrew
7. ✅ Verify Node version: `node --version` (should be 18+)
8. ✅ Verify npm version: `npm --version` (should be 9+)
9. ✅ Clone repository: `git clone [repository-url]`
10. ✅ Navigate to repository: `cd claude-code-ios-ui`
11. ✅ Install backend dependencies: `cd backend && npm install`
12. ✅ Copy environment template: `cp .env.example .env`
13. ✅ Configure environment variables in .env
14. ✅ Return to root: `cd ..`
15. ✅ Open iOS project: `open ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj`
16. ✅ Wait for package resolution to complete
17. ✅ Select target device: iPhone 15 Pro
18. ✅ Select scheme: ClaudeCodeUI
19. ✅ Clean build folder: Cmd+Shift+K
20. ✅ Verify project settings are correct

## Backend Setup

### Task 21-35: Backend Server Configuration
21. ✅ Navigate to backend directory: `cd backend`
22. ✅ Start backend server: `npm start`
23. ✅ Verify server starts on port 3004
24. ✅ Test health endpoint: `curl http://localhost:3004/api/health`
25. ✅ Verify response: `{"status":"ok","timestamp":"..."}`
26. ✅ Check WebSocket endpoint is listening
27. ✅ Verify CORS headers are set correctly
28. ✅ Test projects endpoint: `curl http://localhost:3004/api/projects`
29. ✅ Verify returns array (may be empty initially)
30. ✅ Check logs directory exists: `ls logs/`
31. ✅ Verify uploads directory exists: `ls uploads/`
32. ✅ Check database file created: `ls data/database.sqlite`
33. ✅ Monitor server logs in terminal
34. ✅ Verify no error messages on startup
35. ✅ Keep backend running in separate terminal

## iOS Project Setup

### Task 36-50: Xcode Configuration
36. ✅ Open ClaudeCodeUI.xcodeproj in Xcode
37. ✅ Select ClaudeCodeUI target
38. ✅ Go to Signing & Capabilities tab
39. ✅ Uncheck "Automatically manage signing" for simulator
40. ✅ Or select your Apple Developer team if available
41. ✅ Select iPhone 15 Pro simulator from device list
42. ✅ Build project: Cmd+B
43. ✅ Verify build succeeds with no errors
44. ✅ Check for warnings (should be minimal)
45. ✅ Run on simulator: Cmd+R
46. ✅ Wait for simulator to boot
47. ✅ Verify app launches successfully
48. ✅ Check Xcode console for startup logs
49. ✅ Verify no crash on launch
50. ✅ Confirm cyberpunk theme loads (dark background)

## Testing Procedures

### Task 51-65: Onboarding Flow Testing
51. ✅ Launch app for first time
52. ✅ Verify onboarding screen appears
53. ✅ Check page 1: Welcome message displays
54. ✅ Test swipe right to go to page 2
55. ✅ Verify page indicators update (2 of 6)
56. ✅ Test "Next" button functionality
57. ✅ Check page 2: Projects overview
58. ✅ Check page 3: Chat features
59. ✅ Check page 4: File Explorer
60. ✅ Check page 5: Terminal
61. ✅ Check page 6: Get Started
62. ✅ Test "Skip" button on any page
63. ✅ Test "Get Started" button on last page
64. ✅ Verify onboarding completion saved
65. ✅ Restart app and verify onboarding doesn't show

### Task 66-85: Projects Dashboard Testing
66. ✅ Navigate to Projects tab
67. ✅ Verify empty state message if no projects
68. ✅ Tap "+" button to create new project
69. ✅ Enter project name "Test Project 1"
70. ✅ Enter project path "/test/path"
71. ✅ Tap "Create" button
72. ✅ Verify project appears in list
73. ✅ Check project cell shows name correctly
74. ✅ Check project shows "Active" status
75. ✅ Check timestamp shows "Just now"
76. ✅ Tap project cell to open
77. ✅ Verify navigation to project detail
78. ✅ Go back to projects list
79. ✅ Swipe left on project cell
80. ✅ Tap delete button
81. ✅ Confirm deletion in alert
82. ✅ Verify project removed from list
83. ✅ Pull down to refresh list
84. ✅ Verify refresh animation plays
85. ✅ Create 5 more test projects

### Task 86-110: Chat Interface Testing
86. ✅ Open a project
87. ✅ Navigate to Chat tab
88. ✅ Verify chat interface loads
89. ✅ Check message input field is visible
90. ✅ Type "Hello Claude" in input
91. ✅ Tap send button
92. ✅ Verify message appears in chat
93. ✅ Check message has timestamp
94. ✅ Verify message has user avatar
95. ✅ Check WebSocket connection indicator
96. ✅ Type message with markdown: "**Bold** and *italic*"
97. ✅ Send and verify markdown renders
98. ✅ Send code block: "```swift\nprint(\"Hello\")\n```"
99. ✅ Verify syntax highlighting works
100. ✅ Tap attachment button
101. ✅ Select image from gallery
102. ✅ Verify image preview shows
103. ✅ Send message with attachment
104. ✅ Scroll up in chat history
105. ✅ Verify pull to load more works
106. ✅ Long press on message
107. ✅ Test copy message option
108. ✅ Test share message option
109. ✅ Test keyboard dismiss on scroll
110. ✅ Test typing indicator animation

### Task 111-125: File Explorer Testing
111. ✅ Navigate to Files tab
112. ✅ Verify file list loads
113. ✅ Tap on a directory
114. ✅ Verify navigation into directory
115. ✅ Check breadcrumb navigation
116. ✅ Tap on a file
117. ✅ Verify file opens with syntax highlighting
118. ✅ Test create new file button
119. ✅ Enter filename "test.swift"
120. ✅ Verify file created
121. ✅ Long press on file
122. ✅ Test rename option
123. ✅ Test delete option
124. ✅ Test move option
125. ✅ Test search files functionality

### Task 126-140: Terminal Testing
126. ✅ Navigate to Terminal tab
127. ✅ Verify terminal interface loads
128. ✅ Type "ls" command
129. ✅ Press enter
130. ✅ Verify output displays
131. ✅ Test "pwd" command
132. ✅ Test "echo Hello World"
133. ✅ Verify ANSI colors work
134. ✅ Test up arrow for command history
135. ✅ Test clear command
136. ✅ Test long output scrolling
137. ✅ Test copy output
138. ✅ Test terminal color themes
139. ✅ Test font size adjustment
140. ✅ Test terminal buffer limits

### Task 141-160: Settings Testing
141. ✅ Navigate to Settings tab
142. ✅ Test theme toggle (dark/light)
143. ✅ Verify theme changes immediately
144. ✅ Test haptic feedback toggle
145. ✅ Test sound effects toggle
146. ✅ Adjust font size slider
147. ✅ Verify font size changes
148. ✅ Test backend URL configuration
149. ✅ Test export settings button
150. ✅ Verify settings JSON created
151. ✅ Test import settings
152. ✅ Select exported file
153. ✅ Verify settings restored
154. ✅ Test create backup
155. ✅ View backups list
156. ✅ Test restore from backup
157. ✅ Test delete old backups
158. ✅ Test reset to defaults
159. ✅ Verify about section info
160. ✅ Check version number display

### Task 161-175: Advanced Features Testing
161. ✅ Test feedback form opening
162. ✅ Select bug report type
163. ✅ Enter feedback text
164. ✅ Verify character counter
165. ✅ Add email address
166. ✅ Attach screenshot
167. ✅ Submit feedback
168. ✅ Verify success message
169. ✅ Test app tour from settings
170. ✅ Complete tour steps
171. ✅ Verify tour completion saved
172. ✅ Test accessibility with VoiceOver
173. ✅ Test Dynamic Type sizes
174. ✅ Test device rotation (iPad)
175. ✅ Test memory warnings handling

### Task 176-190: Performance Testing
176. ✅ Profile app with Instruments
177. ✅ Check memory usage < 150MB
178. ✅ Verify no memory leaks
179. ✅ Test with 100+ projects
180. ✅ Test with 1000+ chat messages
181. ✅ Monitor CPU usage < 30%
182. ✅ Test app launch time < 2s
183. ✅ Test screen transitions < 300ms
184. ✅ Test network timeouts
185. ✅ Test WebSocket reconnection
186. ✅ Test offline mode
187. ✅ Test background/foreground
188. ✅ Test low battery mode
189. ✅ Test with slow network
190. ✅ Run 1-hour stress test

## Log Monitoring

### Console Logs to Monitor
- **Xcode Console**: App lifecycle, errors, warnings
- **Backend Terminal**: API requests, WebSocket connections
- **Console.app**: System-level iOS logs
- **Instruments**: Performance metrics

### Key Log Patterns
```
✅ SUCCESS: "Successfully connected to backend"
⚠️ WARNING: "Network request timeout"
❌ ERROR: "Failed to decode response"
🔄 INFO: "WebSocket reconnecting..."
```

## Performance Benchmarks

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| App Launch | < 2s | - | ⏳ |
| Project List Load | < 500ms | - | ⏳ |
| Message Send | < 100ms | - | ⏳ |
| File List Load | < 300ms | - | ⏳ |
| Screen Transition | < 300ms | - | ⏳ |
| Memory Baseline | < 150MB | - | ⏳ |
| WebSocket Reconnect | < 3s | - | ⏳ |

## Bug Reporting

### Template
```markdown
**Bug Description**: [Clear description]
**Steps to Reproduce**: 
1. [Step 1]
2. [Step 2]
**Expected Result**: [What should happen]
**Actual Result**: [What actually happens]
**Device**: [iPhone 15 Pro / iPad]
**iOS Version**: [17.0]
**App Version**: [1.0.0]
**Logs**: [Attach relevant logs]
**Screenshots**: [Attach if applicable]
```

## Test Completion Checklist

- [ ] All 190 test tasks completed
- [ ] No critical bugs remaining
- [ ] Performance benchmarks met
- [ ] No memory leaks detected
- [ ] Accessibility audit passed
- [ ] All network errors handled
- [ ] Data persistence verified
- [ ] Documentation updated
- [ ] Test report generated
- [ ] Ready for production

---

**Last Updated**: January 2025
**Test Version**: 1.0.0
**Platform**: iOS 17.0+