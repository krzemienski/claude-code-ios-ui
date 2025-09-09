#!/bin/bash
# Continuous Compilation Monitor for iOS E2E Testing
# Agent-001: Git Operations & Compilation Validation Specialist
# This script monitors for file changes and validates compilation after each change

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project paths
PROJECT_ROOT="/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS"
OUTPUT_ROOT="/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/output/20250909-122718_ios_e2e_claude"
VALIDATION_SCRIPT="$PROJECT_ROOT/Scripts/validate_compilation.sh"

# Navigate to project root
cd "$PROJECT_ROOT"

echo "====================================="
echo "=== Continuous Compilation Monitor ==="
echo "====================================="
echo "Started at: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Project: $PROJECT_ROOT"
echo "Monitoring for file changes..."
echo ""

# Function to validate compilation and commit if successful
validate_and_commit() {
    local changed_file="$1"
    local commit_message="$2"
    
    echo -e "${BLUE}📝 File changed: $changed_file${NC}"
    echo "Running compilation validation..."
    
    # Run validation script
    if "$VALIDATION_SCRIPT"; then
        echo -e "${GREEN}✅ Compilation successful!${NC}"
        
        # Stage the changed file
        git add "$changed_file"
        
        # Create atomic commit
        git commit -m "$commit_message" -m "Validated: Compilation successful" -m "Agent-001: Automated commit after validation"
        
        echo -e "${GREEN}✅ Changes committed successfully${NC}"
        echo "Commit: $(git log -1 --oneline)"
        
        # Log success
        echo "$(date '+%Y-%m-%d %H:%M:%S'): Committed after successful compilation - $changed_file" >> "${OUTPUT_ROOT}/continuous_monitor.log"
        
        return 0
    else
        echo -e "${RED}❌ Compilation failed!${NC}"
        echo "Changes NOT committed. Please fix compilation errors."
        
        # Revert unstaged changes if compilation fails
        git checkout -- "$changed_file"
        echo -e "${YELLOW}⚠️  Reverted changes to $changed_file${NC}"
        
        # Log failure
        echo "$(date '+%Y-%m-%d %H:%M:%S'): Compilation failed, changes reverted - $changed_file" >> "${OUTPUT_ROOT}/continuous_monitor.log"
        
        return 1
    fi
}

# Function to monitor specific file change
monitor_file_change() {
    local file_path="$1"
    local last_modified=""
    
    if [ -f "$file_path" ]; then
        last_modified=$(stat -f "%m" "$file_path" 2>/dev/null || stat -c "%Y" "$file_path" 2>/dev/null)
    fi
    
    while true; do
        sleep 2  # Check every 2 seconds
        
        if [ -f "$file_path" ]; then
            current_modified=$(stat -f "%m" "$file_path" 2>/dev/null || stat -c "%Y" "$file_path" 2>/dev/null)
            
            if [ "$current_modified" != "$last_modified" ]; then
                echo ""
                echo "$(date '+%Y-%m-%d %H:%M:%S'): Change detected!"
                
                # Generate commit message based on file type
                if [[ "$file_path" == *".swift" ]]; then
                    commit_msg="Update Swift file: $(basename $file_path)"
                elif [[ "$file_path" == *".md" ]]; then
                    commit_msg="Update documentation: $(basename $file_path)"
                elif [[ "$file_path" == *"Test"* ]]; then
                    commit_msg="Update test: $(basename $file_path)"
                else
                    commit_msg="Update: $(basename $file_path)"
                fi
                
                validate_and_commit "$file_path" "$commit_msg"
                
                last_modified="$current_modified"
                echo ""
                echo "Continuing to monitor..."
            fi
        fi
    done
}

# Function to monitor entire directory
monitor_directory() {
    echo "Monitoring all Swift files in project..."
    
    # Use fswatch if available, otherwise fall back to polling
    if command -v fswatch &> /dev/null; then
        echo "Using fswatch for file monitoring..."
        
        fswatch -r --exclude ".*" --include "\.swift$" "$PROJECT_ROOT" | while read changed_file; do
            # Skip build directories
            if [[ "$changed_file" != *"/build/"* ]] && [[ "$changed_file" != *"/.build/"* ]]; then
                relative_path="${changed_file#$PROJECT_ROOT/}"
                commit_msg="Update: $relative_path"
                validate_and_commit "$changed_file" "$commit_msg"
            fi
        done
    else
        echo "fswatch not found. Using polling method (less efficient)..."
        echo "Install fswatch for better performance: brew install fswatch"
        echo ""
        
        # Poll for changes
        while true; do
            sleep 5  # Check every 5 seconds
            
            # Find recently modified Swift files
            find "$PROJECT_ROOT" -name "*.swift" -type f -mmin -1 2>/dev/null | while read changed_file; do
                # Skip build directories
                if [[ "$changed_file" != *"/build/"* ]] && [[ "$changed_file" != *"/.build/"* ]]; then
                    relative_path="${changed_file#$PROJECT_ROOT/}"
                    commit_msg="Update: $relative_path"
                    validate_and_commit "$changed_file" "$commit_msg"
                fi
            done
        done
    fi
}

# Handle script termination
cleanup() {
    echo ""
    echo "====================================="
    echo "=== Monitor Stopped ==="
    echo "====================================="
    echo "Stopped at: $(date '+%Y-%m-%d %H:%M:%S')"
    
    # Final git status
    echo ""
    echo "Final git status:"
    git status --short
    
    exit 0
}

trap cleanup INT TERM

# Main execution
if [ $# -eq 0 ]; then
    # No arguments - monitor entire directory
    monitor_directory
elif [ -f "$1" ]; then
    # Monitor specific file
    echo "Monitoring specific file: $1"
    monitor_file_change "$1"
else
    echo -e "${RED}Error: Invalid argument${NC}"
    echo "Usage:"
    echo "  $0                  # Monitor all Swift files"
    echo "  $0 <file_path>      # Monitor specific file"
    exit 1
fi