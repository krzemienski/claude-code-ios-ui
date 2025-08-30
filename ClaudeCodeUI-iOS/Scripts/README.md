# Tuist Build Automation Scripts

This directory contains comprehensive shell scripts for Tuist project management, build automation, and CI/CD integration.

## 📦 Available Scripts

### 🔨 Core Build Scripts

- **`tuist-build.sh`** - Primary build automation with logging and performance tracking
- **`tuist-generate.sh`** - Project generation with validation and dependency management  
- **`tuist-clean.sh`** - Comprehensive cleanup of builds, caches, and derived data
- **`tuist-test.sh`** - Test execution with coverage reporting and multi-target support

### 📊 Monitoring & Insights

- **`tuist-watch.sh`** - Background monitoring with real-time insights and auto-rebuild

## 🚀 Quick Start

### Basic Build Workflow
```bash
# Generate project (with validation)
./Scripts/tuist-generate.sh

# Build the main app
./Scripts/tuist-build.sh ClaudeCodeUI

# Run tests with coverage
./Scripts/tuist-test.sh

# Clean build artifacts
./Scripts/tuist-clean.sh
```

### Development Monitoring
```bash
# Start background monitoring with auto-rebuild
./Scripts/tuist-watch.sh start --auto-rebuild --notifications

# Check monitoring status
./Scripts/tuist-watch.sh status

# View performance metrics
./Scripts/tuist-watch.sh metrics

# Stop monitoring
./Scripts/tuist-watch.sh stop
```

## 🛠️ Script Features

### tuist-build.sh
- ✅ Comprehensive logging with timestamps
- ✅ Retry logic for transient failures  
- ✅ Parallel build execution
- ✅ Performance metrics collection
- ✅ Build insights integration
- ✅ Support for Debug/Release configurations
- ✅ xcbeautify integration for better output

**Usage Examples:**
```bash
./Scripts/tuist-build.sh                              # Build all schemes
./Scripts/tuist-build.sh ClaudeCodeUI                 # Build specific scheme
./Scripts/tuist-build.sh --configuration Release      # Release build
./Scripts/tuist-build.sh --clean --no-cache           # Clean build without cache
./Scripts/tuist-build.sh --verbose                    # Verbose output
```

### tuist-generate.sh
- ✅ Environment validation
- ✅ Project manifest syntax checking
- ✅ Dependency validation
- ✅ Force regeneration option
- ✅ Derived data cleanup
- ✅ Comprehensive error reporting

**Usage Examples:**
```bash
./Scripts/tuist-generate.sh                      # Standard generation
./Scripts/tuist-generate.sh --validate-only      # Validation only
./Scripts/tuist-generate.sh --force --clean-derived-data  # Force clean generation
./Scripts/tuist-generate.sh --no-cache --verbose # Generate without cache
```

### tuist-clean.sh
- ✅ Tuist cache cleanup
- ✅ Derived data management
- ✅ Build products cleanup
- ✅ Swift Package Manager cache clearing
- ✅ Log file rotation
- ✅ Safety confirmations
- ✅ Dry-run mode

**Usage Examples:**
```bash
./Scripts/tuist-clean.sh                         # Standard cleanup
./Scripts/tuist-clean.sh --clean-logs            # Include log cleanup
./Scripts/tuist-clean.sh --clean-workspace --force  # Clean everything
./Scripts/tuist-clean.sh --dry-run --verbose     # Preview cleanup
```

### tuist-test.sh
- ✅ Multi-target test execution (Unit/UI/Integration)
- ✅ Code coverage collection
- ✅ HTML coverage reports
- ✅ Simulator management
- ✅ Parallel test execution
- ✅ Test result bundling
- ✅ Performance tracking

**Usage Examples:**
```bash
./Scripts/tuist-test.sh                          # Run all tests
./Scripts/tuist-test.sh ClaudeCodeUITests        # Unit tests only
./Scripts/tuist-test.sh --no-coverage --fail-fast  # Quick test run
./Scripts/tuist-test.sh --device "iPhone 14" --ios-version "16.0"  # Specific device
```

### tuist-watch.sh
- ✅ Real-time file change monitoring
- ✅ Build performance tracking
- ✅ System resource monitoring
- ✅ Cache usage analysis
- ✅ Auto-rebuild on changes
- ✅ Desktop notifications
- ✅ Webhook integration
- ✅ Background daemon mode

**Usage Examples:**
```bash
./Scripts/tuist-watch.sh start                   # Start monitoring
./Scripts/tuist-watch.sh start --auto-rebuild    # Auto-rebuild on changes
./Scripts/tuist-watch.sh --interval 10 start     # Custom check interval
./Scripts/tuist-watch.sh metrics                 # Show performance data
./Scripts/tuist-watch.sh logs --tail 50         # Show recent logs
```

## 📊 Logging & Metrics

All scripts generate detailed logs in the `logs/` directory:

- **Build logs**: `tuist-build-YYYYMMDD_HHMMSS.log`
- **Error logs**: `tuist-*-errors-YYYYMMDD_HHMMSS.log`  
- **Performance metrics**: `tuist-build-performance.log`
- **Coverage reports**: `logs/coverage/html/index.html`
- **Test results**: `logs/test-results/*.xcresult`

## 🔧 CI/CD Integration

### GitHub Actions Example
```yaml
name: Build and Test
on: [push, pull_request]

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Tuist
        run: curl -Ls https://install.tuist.io | bash
        
      - name: Validate Project  
        run: ./Scripts/tuist-generate.sh --validate-only
        
      - name: Generate Project
        run: ./Scripts/tuist-generate.sh
        
      - name: Build
        run: ./Scripts/tuist-build.sh --configuration Release
        
      - name: Test
        run: ./Scripts/tuist-test.sh --no-ui-tests --quiet
        
      - name: Upload Coverage
        uses: actions/upload-artifact@v3
        with:
          name: coverage-report
          path: logs/coverage/
```

### Fastlane Integration
```ruby
# Fastfile
lane :build do
  sh("../Scripts/tuist-generate.sh")
  sh("../Scripts/tuist-build.sh --configuration Release")
end

lane :test do
  sh("../Scripts/tuist-test.sh")
end

lane :clean do
  sh("../Scripts/tuist-clean.sh --force")
end
```

## 🎯 Performance Optimization

### Build Performance
- **Enable Binary Cache**: Default enabled, use `--no-cache` only when needed
- **Parallel Builds**: Enabled by default for faster compilation
- **Incremental Builds**: Avoid `--clean` unless necessary
- **Cache Warming**: Use `tuist cache warm` for CI optimization

### Expected Performance
- **Project Generation**: 5-60 seconds (depends on cache state)
- **Clean Build**: 2-5 minutes
- **Incremental Build**: 30 seconds - 2 minutes  
- **Test Suite**: 1-15 minutes (depends on test types)
- **Cache Hit Rate**: Up to 80% build time reduction

### Monitoring & Insights
- Use `tuist-watch.sh` for continuous performance monitoring
- Enable build insights with `tuist inspect build`
- Monitor cache usage and effectiveness
- Track build time trends over time

## 🔒 Safety Features

- **Confirmation Prompts**: For destructive operations
- **Dry Run Mode**: Preview changes without execution
- **Backup & Recovery**: Automatic log rotation and retention
- **Error Recovery**: Retry mechanisms with exponential backoff
- **Graceful Handling**: Proper signal handling and cleanup

## 📱 Project Targets

The scripts support all project targets:
- **ClaudeCodeUI**: Main iOS application
- **ClaudeCodeUITests**: Unit tests
- **ClaudeCodeUIUITests**: UI automation tests  
- **ClaudeCodeUIIntegrationTests**: Integration tests

## 🤝 Contributing

When modifying scripts:
1. Maintain backward compatibility
2. Update help text and examples
3. Add comprehensive error handling
4. Include performance logging
5. Test in both local and CI environments
6. Update this README with new features

## 📚 Dependencies

### Required
- **Tuist**: Project management tool
- **Xcode**: iOS development environment
- **Bash 4+**: Shell environment

### Optional (Enhanced Features)
- **xcbeautify**: Better build output formatting (`brew install xcbeautify`)
- **xcov**: Enhanced coverage reporting (`gem install xcov`)
- **fswatch**: Advanced file monitoring (`brew install fswatch`)

---

🚀 **Happy Building with Tuist!**

For issues or feature requests, please check the logs in the `logs/` directory first, then consult the script help text using the `--help` flag.