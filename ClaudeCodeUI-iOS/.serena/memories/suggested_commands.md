# Suggested Commands for Development

## Build and Run
```bash
# Build the project
xcodebuild build -project ClaudeCodeUI.xcodeproj -scheme ClaudeCodeUI -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run on simulator
open -a Simulator
xcrun simctl boot "iPhone 15 Pro"
xcodebuild install -project ClaudeCodeUI.xcodeproj -scheme ClaudeCodeUI -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Using Tuist (alternative)
tuist generate
tuist build
```

## Testing
```bash
# Run all tests
xcodebuild test -project ClaudeCodeUI.xcodeproj -scheme ClaudeCodeUI -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run specific test suite
xcodebuild test -project ClaudeCodeUI.xcodeproj -scheme ClaudeCodeUI -only-testing:ClaudeCodeUITests

# UI Tests only
xcodebuild test -project ClaudeCodeUI.xcodeproj -scheme ClaudeCodeUI -only-testing:ClaudeCodeUIUITests

# Integration tests
./run_integration_tests.sh
```

## Code Quality
```bash
# Swift format
swift-format -i -r Sources/

# SwiftLint
swiftlint
swiftlint autocorrect

# Type checking
swift build --target ClaudeCodeUI
```

## Dependency Management
```bash
# Update packages
swift package update
swift package resolve

# Tuist dependencies
tuist fetch
tuist cache warm
```

## Debugging
```bash
# View build logs
xcodebuild -project ClaudeCodeUI.xcodeproj -scheme ClaudeCodeUI clean build | xcpretty

# Simulator logs
xcrun simctl spawn booted log stream --level debug --predicate 'subsystem=="com.claudecode.ui"'

# Clear derived data
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf DerivedData/
```

## Git Workflow
```bash
# Feature branch
git checkout -b feature/ui-improvements

# Commit with conventional commits
git commit -m "feat(ui): improve chat message cell accessibility"

# Pre-push checks
./Scripts/pre-push-checks.sh
```