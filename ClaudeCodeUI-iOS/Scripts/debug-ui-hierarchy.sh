#!/bin/bash

# Debug UI Hierarchy Script
# This script launches the app and captures the UI hierarchy for debugging

set -e

PROJECT_DIR="/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS"
SCHEME="ClaudeCodeUI"

echo "🔍 Debug UI Hierarchy Script"
echo "============================"

# Clean previous results
rm -rf "$PROJECT_DIR/UIDebugResults.xcresult" 2>/dev/null || true

# Create a simple UI test that just prints the hierarchy
cat > "$PROJECT_DIR/ClaudeCodeUIUITests/UIHierarchyDebugTest.swift" << 'EOF'
import XCTest

final class UIHierarchyDebugTest: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        app.launchArguments = [
            "--uitesting",
            "--enable-backend",
            "--real-data"
        ]
        
        app.launchEnvironment = [
            "TESTING_MODE": "functional",
            "BACKEND_URL": "http://localhost:3004",
            "ENABLE_LOGGING": "true",
            "DEBUG_UI": "true"
        ]
        
        app.launch()
    }
    
    func testDebugUIHierarchy() throws {
        print("🚀 Debugging UI Hierarchy")
        
        // Wait for app to stabilize
        Thread.sleep(forTimeInterval: 3.0)
        
        // Print entire UI hierarchy
        print("\n📋 COMPLETE UI HIERARCHY:")
        print("========================")
        print(app.debugDescription)
        
        // Check tab bars
        print("\n📊 TAB BARS:")
        for i in 0..<app.tabBars.count {
            let tabBar = app.tabBars.element(boundBy: i)
            if tabBar.exists {
                print("TabBar[\(i)]: \(tabBar.debugDescription)")
                
                // Print all buttons in tab bar
                for j in 0..<tabBar.buttons.count {
                    let button = tabBar.buttons.element(boundBy: j)
                    if button.exists {
                        print("  Button[\(j)]: label='\(button.label)' id='\(button.identifier)' selected=\(button.isSelected)")
                    }
                }
            }
        }
        
        // Check for collection views
        print("\n📊 COLLECTION VIEWS:")
        for i in 0..<app.collectionViews.count {
            let cv = app.collectionViews.element(boundBy: i)
            if cv.exists {
                print("CollectionView[\(i)]: cells=\(cv.cells.count) id='\(cv.identifier)'")
                
                // Print first few cells
                for j in 0..<min(3, cv.cells.count) {
                    let cell = cv.cells.element(boundBy: j)
                    if cell.exists {
                        print("  Cell[\(j)]: \(cell.debugDescription)")
                    }
                }
            }
        }
        
        // Check for tables
        print("\n📊 TABLES:")
        for i in 0..<app.tables.count {
            let table = app.tables.element(boundBy: i)
            if table.exists {
                print("Table[\(i)]: cells=\(table.cells.count) id='\(table.identifier)'")
                
                // Print first few cells
                for j in 0..<min(3, table.cells.count) {
                    let cell = table.cells.element(boundBy: j)
                    if cell.exists {
                        print("  Cell[\(j)]: \(cell.debugDescription)")
                    }
                }
            }
        }
        
        // Check for any views with "project" in identifier or label
        print("\n🔍 SEARCHING FOR PROJECT-RELATED ELEMENTS:")
        let projectPredicate = NSPredicate(format: "identifier CONTAINS[c] 'project' OR label CONTAINS[c] 'project'")
        let projectElements = app.descendants(matching: .any).matching(projectPredicate)
        print("Found \(projectElements.count) project-related elements")
        
        for i in 0..<min(5, projectElements.count) {
            let element = projectElements.element(boundBy: i)
            if element.exists {
                print("  Element[\(i)]: type=\(element.elementType) label='\(element.label)' id='\(element.identifier)'")
            }
        }
        
        // Check all static texts to understand what's on screen
        print("\n📝 ALL STATIC TEXTS:")
        for i in 0..<min(10, app.staticTexts.count) {
            let text = app.staticTexts.element(boundBy: i)
            if text.exists {
                print("  Text[\(i)]: '\(text.label)'")
            }
        }
        
        // Check if we're in an empty state
        let emptyStatePredicate = NSPredicate(format: "label CONTAINS[c] 'no projects' OR label CONTAINS[c] 'empty' OR label CONTAINS[c] 'get started'")
        let emptyElements = app.staticTexts.matching(emptyStatePredicate)
        if emptyElements.count > 0 {
            print("\n⚠️ EMPTY STATE DETECTED:")
            for i in 0..<emptyElements.count {
                let element = emptyElements.element(boundBy: i)
                if element.exists {
                    print("  '\(element.label)'")
                }
            }
        }
        
        // Take a screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "UI_Hierarchy_Debug"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        print("\n✅ UI Hierarchy Debug Complete")
    }
}
EOF

echo "🔨 Building and running UI hierarchy debug test..."

# Run the debug test
xcodebuild test \
    -workspace "$PROJECT_DIR/ClaudeCodeUI.xcworkspace" \
    -scheme "$SCHEME" \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' \
    -only-testing:ClaudeCodeUIUITests/UIHierarchyDebugTest \
    -resultBundlePath "$PROJECT_DIR/UIDebugResults.xcresult" \
    2>&1 | tee "$PROJECT_DIR/ui_hierarchy_debug.log"

echo ""
echo "📊 Extracting hierarchy information..."
grep -A 100 "COMPLETE UI HIERARCHY:" "$PROJECT_DIR/ui_hierarchy_debug.log" > "$PROJECT_DIR/ui_hierarchy_extracted.txt" || true
grep -A 50 "TAB BARS:" "$PROJECT_DIR/ui_hierarchy_debug.log" >> "$PROJECT_DIR/ui_hierarchy_extracted.txt" || true
grep -A 50 "COLLECTION VIEWS:" "$PROJECT_DIR/ui_hierarchy_debug.log" >> "$PROJECT_DIR/ui_hierarchy_extracted.txt" || true
grep -A 50 "TABLES:" "$PROJECT_DIR/ui_hierarchy_debug.log" >> "$PROJECT_DIR/ui_hierarchy_extracted.txt" || true
grep -A 50 "PROJECT-RELATED ELEMENTS:" "$PROJECT_DIR/ui_hierarchy_debug.log" >> "$PROJECT_DIR/ui_hierarchy_extracted.txt" || true
grep -A 50 "ALL STATIC TEXTS:" "$PROJECT_DIR/ui_hierarchy_debug.log" >> "$PROJECT_DIR/ui_hierarchy_extracted.txt" || true
grep -A 50 "EMPTY STATE DETECTED:" "$PROJECT_DIR/ui_hierarchy_debug.log" >> "$PROJECT_DIR/ui_hierarchy_extracted.txt" || true

echo ""
echo "✅ Debug complete. Check ui_hierarchy_extracted.txt for results"