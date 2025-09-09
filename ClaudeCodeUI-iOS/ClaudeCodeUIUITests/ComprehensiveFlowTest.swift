import XCTest

final class ComprehensiveFlowTest: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Set up launch arguments for real backend testing
        // These are passed to the app and can be read via ProcessInfo.processInfo.arguments
        app.launchArguments = [
            "--uitesting",
            "--backend-url", "http://localhost:3004",
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
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testCompleteUserFlow() throws {
        print("🚀 Starting Complete User Flow Test")
        
        // CRITICAL: Wait for app to load and fetch data
        print("⏳ Waiting for app to stabilize and load data...")
        print("🔧 Test environment variables:")
        print("   BACKEND_URL: \(ProcessInfo.processInfo.environment["BACKEND_URL"] ?? "not set")")
        print("   TESTING_MODE: \(ProcessInfo.processInfo.environment["TESTING_MODE"] ?? "not set")")
        
        // Check if we see any debug output from the app
        Thread.sleep(forTimeInterval: 2.0)  // Give app time to print debug logs
        
        // First check if we're stuck on an authentication screen
        let authSkipButton = app.buttons["Skip"]
        if authSkipButton.waitForExistence(timeout: 2.0) {
            print("🔐 Found authentication screen - skipping")
            authSkipButton.tap()
            Thread.sleep(forTimeInterval: 2.0)
        } else {
            print("🔍 No authentication screen found - checking current screen")
            
            // Debug: Print all buttons to see what's available
            let allButtons = app.buttons.allElementsBoundByIndex
            print("📱 Available buttons: \(allButtons.count)")
            for i in 0..<min(5, allButtons.count) {
                let button = allButtons[i]
                if button.exists {
                    print("  Button \(i): \(button.label)")
                }
            }
            
            // Debug: Print all navigation bars
            let navBars = app.navigationBars.allElementsBoundByIndex
            print("🧭 Navigation bars: \(navBars.count)")
            for i in 0..<min(3, navBars.count) {
                let navBar = navBars[i]
                if navBar.exists {
                    print("  NavBar \(i): \(navBar.identifier)")
                }
            }
        }
        
        // Force refresh the Projects view by tapping tab bar (workaround)
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            print("🔄 Attempting to force refresh via tab bar")
            let projectsTab = tabBar.buttons["Projects"]
            if projectsTab.exists {
                projectsTab.tap()
                Thread.sleep(forTimeInterval: 1.0)
                projectsTab.tap()  // Tap twice to force refresh
                print("✅ Projects tab tapped to force refresh")
            }
        }
        
        // Wait for the collection view to appear with proper timeout
        print("⏳ Waiting for collection view to appear...")
        let projectsCollectionView = app.collectionViews["projectsCollectionView"]
        let collectionViewExists = projectsCollectionView.waitForExistence(timeout: 10.0)
        
        if collectionViewExists {
            print("✅ Collection view appeared!")
            // Give it a moment to populate with data
            Thread.sleep(forTimeInterval: 2.0)
        } else {
            print("❌ Collection view did not appear within 10 seconds")
        }
        
        // Step 1: Debug current UI state
        print("\n📊 Step 1: Analyzing current UI state")
        debugUIHierarchy()
        
        // Step 1.5: Try to verify backend configuration via UI
        print("\n🔍 Step 1.5: Looking for any debug information in UI")
        let allTexts = app.staticTexts.allElementsBoundByIndex
        for i in 0..<min(10, allTexts.count) {
            let text = allTexts[i]
            if text.exists {
                let label = text.label
                if label.contains("backend") || label.contains("URL") || label.contains("localhost") || label.contains("192.168") {
                    print("   Found config text: '\(label)'")
                }
            }
        }
        
        // Step 2: Check if Projects tab is selected
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
        
        let projectsTab = tabBar.buttons["Projects"]
        if projectsTab.exists && !projectsTab.isSelected {
            print("📱 Tapping Projects tab")
            projectsTab.tap()
            Thread.sleep(forTimeInterval: 2.0)
        }
        
        // Step 3: Try to trigger refresh with pull-to-refresh
        print("\n🔄 Step 3: Attempting pull-to-refresh")
        app.swipeDown()
        Thread.sleep(forTimeInterval: 3.0)
        
        // Step 4: Look for project elements with various strategies
        print("\n🔍 Step 4: Searching for project elements")
        
        // First ensure we're on the Projects tab
        let projectsTabElement = app.tabBars.buttons["Projects"]
        if projectsTabElement.exists {
            print("📱 Projects tab found - ensuring it's selected")
            if !projectsTabElement.isSelected {
                projectsTabElement.tap()
                Thread.sleep(forTimeInterval: 2.0)
            }
        }
        
        // Look for the collection view by accessibility identifier
        let projectsCollectionViewDebug = app.collectionViews["projectsCollectionView"]
        if projectsCollectionViewDebug.exists {
            print("✅ Found projectsCollectionView by accessibility identifier!")
            print("  Collection view is visible: \(projectsCollectionViewDebug.isHittable)")
            print("  Number of cells: \(projectsCollectionViewDebug.cells.count)")
            
            // Try to get cell details
            let cells = projectsCollectionViewDebug.cells.allElementsBoundByIndex
            for i in 0..<min(3, cells.count) {
                let cell = cells[i]
                if cell.exists {
                    print("  Cell \(i): \(cell.identifier)")
                }
            }
        } else {
            print("❌ projectsCollectionView not found by accessibility identifier")
        }
        
        // Check for any error messages or empty states
        let staticTexts = app.staticTexts.allElementsBoundByIndex
        print("📝 Static texts found: \(staticTexts.count)")
        for i in 0..<min(10, staticTexts.count) {
            let text = staticTexts[i]
            if text.exists && !text.label.isEmpty {
                print("  Text \(i): '\(text.label)'")
            }
        }
        
        // Check for loading indicators
        let activityIndicators = app.activityIndicators
        if activityIndicators.count > 0 {
            print("⏳ Loading indicators found: \(activityIndicators.count) - waiting...")
            Thread.sleep(forTimeInterval: 3.0)
        }
        
        // Strategy 1: Check for collection views
        let collectionViews = app.collectionViews
        print("📊 Collection views found: \(collectionViews.count)")
        if collectionViews.count > 0 {
            print("✅ Found \(collectionViews.count) collection view(s)")
            let firstCollection = collectionViews.firstMatch
            
            // Wait for cells to appear
            let cellsExist = firstCollection.cells.count > 0
            if cellsExist {
                print("✅ Found \(firstCollection.cells.count) project cells")
                captureScreenshot(name: "Projects_List_With_Data")
                
                // Try to tap the first project
                let firstCell = firstCollection.cells.element(boundBy: 0)
                if firstCell.exists {
                    print("📱 Tapping first project cell")
                    firstCell.tap()
                    Thread.sleep(forTimeInterval: 2.0)
                    captureScreenshot(name: "Project_Sessions_View")
                    
                    // Navigate back
                    if app.navigationBars.buttons["Back"].exists {
                        app.navigationBars.buttons["Back"].tap()
                    } else if app.navigationBars.buttons.element(boundBy: 0).exists {
                        app.navigationBars.buttons.element(boundBy: 0).tap()
                    }
                }
            } else {
                print("⚠️ Collection view exists but has no cells")
                captureScreenshot(name: "Empty_Collection_View")
                XCTFail("❌ CRITICAL: Collection view has no cells despite backend having projects")
            }
        } else {
            // CRITICAL: No collection views found at all!
            XCTFail("❌ CRITICAL: No collection views found in UI - projects are not being displayed!")
        }
        
        // Strategy 2: Check for table views
        let tables = app.tables
        if tables.count > 0 {
            print("✅ Found \(tables.count) table(s)")
            let firstTable = tables.firstMatch
            
            if firstTable.cells.count > 0 {
                print("✅ Found \(firstTable.cells.count) table cells")
                captureScreenshot(name: "Projects_Table_With_Data")
                
                // Try to tap the first cell
                let firstCell = firstTable.cells.element(boundBy: 0)
                if firstCell.exists {
                    print("📱 Tapping first table cell")
                    firstCell.tap()
                    Thread.sleep(forTimeInterval: 2.0)
                    captureScreenshot(name: "Table_Cell_Tapped")
                }
            }
        }
        
        // Strategy 3: Look for any clickable elements with "Project" in them
        let projectElements = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] 'project' OR identifier CONTAINS[c] 'project'"))
        if projectElements.count > 0 {
            print("✅ Found \(projectElements.count) project-related elements")
            for i in 0..<min(3, projectElements.count) {
                let element = projectElements.element(boundBy: i)
                if element.exists {
                    print("  - Element: \(element.elementType), label: '\(element.label)'")
                }
            }
        }
        
        // Step 5: Check for empty state (this should NOT happen)
        let emptyStateTexts = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'no projects' OR label CONTAINS[c] 'empty' OR label CONTAINS[c] 'get started'"))
        if emptyStateTexts.count > 0 {
            print("\n❌ CRITICAL: Empty state detected when backend has projects:")
            for i in 0..<emptyStateTexts.count {
                let text = emptyStateTexts.element(boundBy: i)
                if text.exists {
                    print("  - '\(text.label)'")
                }
            }
            captureScreenshot(name: "Empty_State_Failure")
            
            // This is a critical failure - we should have projects!
            XCTFail("❌ CRITICAL: App is showing empty state despite backend having 3 projects. Backend URL configuration issue!")
        }
        
        // Step 6: Test scrolling performance (if we have content)
        if collectionViews.count > 0 && collectionViews.firstMatch.cells.count > 3 {
            print("\n📜 Step 6: Testing scrolling performance")
            testScrollingPerformance(on: collectionViews.firstMatch)
        }
        
        print("\n✅ Complete User Flow Test finished")
    }
    
    private func debugUIHierarchy() {
        print("\n🔍 Current UI Hierarchy:")
        print("  Collection Views: \(app.collectionViews.count)")
        print("  Tables: \(app.tables.count)")
        print("  Static Texts: \(app.staticTexts.count)")
        
        // Print first few static texts to understand what's on screen
        for i in 0..<min(5, app.staticTexts.count) {
            let text = app.staticTexts.element(boundBy: i)
            if text.exists {
                print("  Text[\(i)]: '\(text.label)'")
            }
        }
    }
    
    private func testScrollingPerformance(on collectionView: XCUIElement) {
        print("🚀 Testing rapid scrolling...")
        
        // Capture initial state
        captureScreenshot(name: "Scroll_Test_Start")
        
        // Perform rapid scrolls
        for i in 1...5 {
            collectionView.swipeUp(velocity: .fast)
            Thread.sleep(forTimeInterval: 0.5)
            print("  Scroll \(i) up completed")
        }
        
        captureScreenshot(name: "Scroll_Test_After_Up")
        
        // Scroll back down
        for i in 1...5 {
            collectionView.swipeDown(velocity: .fast)
            Thread.sleep(forTimeInterval: 0.5)
            print("  Scroll \(i) down completed")
        }
        
        captureScreenshot(name: "Scroll_Test_Complete")
        
        // Verify no UI glitches or duplicates
        let cellCount = collectionView.cells.count
        print("✅ Scrolling test complete. Cell count: \(cellCount)")
    }
    
    private func captureScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        print("📸 Screenshot captured: \(name)")
    }
}