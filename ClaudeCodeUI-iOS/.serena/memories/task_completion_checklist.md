# Task Completion Checklist

## Before Marking Task Complete

### 1. Code Quality
- [ ] Code compiles without warnings
- [ ] SwiftLint passes
- [ ] No force unwraps or implicitly unwrapped optionals
- [ ] Proper error handling implemented

### 2. Testing
- [ ] Unit tests written and passing
- [ ] UI tests for new screens/flows
- [ ] Manual testing on different iPhone models
- [ ] Accessibility testing with VoiceOver
- [ ] Dark mode verified

### 3. UI/UX Validation
- [ ] Consistent with cyberpunk theme
- [ ] Smooth animations (60fps)
- [ ] Proper loading states
- [ ] Error states handled gracefully
- [ ] Empty states have appropriate messaging

### 4. Performance
- [ ] No memory leaks (Instruments check)
- [ ] Smooth scrolling in lists
- [ ] Images properly cached
- [ ] Network requests optimized

### 5. Documentation
- [ ] Code comments updated
- [ ] README updated if needed
- [ ] API documentation current
- [ ] Changelog entry added

### 6. Final Checks
```bash
# Run full test suite
xcodebuild test -project ClaudeCodeUI.xcodeproj -scheme ClaudeCodeUI

# Check for build issues
xcodebuild clean build -project ClaudeCodeUI.xcodeproj -scheme ClaudeCodeUI

# Verify no uncommitted changes
git status

# Run linter
swiftlint
```

## Post-Completion
- Create PR with descriptive title
- Include screenshots/videos for UI changes
- Request code review
- Update project board/tickets