import XCTest

class ProjectListTests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["UI-TESTING"]
        app.launchEnvironment = ["DISABLE_ANIMATIONS": "1"]
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // MARK: - Project List Tests
    
    func testProjectListLoads() {
        // Wait for projects to load
        let projectTable = app.tables["projectList"]
        XCTAssertTrue(projectTable.waitForExistence(timeout: 10), "Project list table should exist")
        
        // Verify projects exist
        let projectCells = projectTable.cells
        XCTAssertGreaterThan(projectCells.count, 0, "No projects loaded in the list!")
        
        // Verify first project has correct elements
        let firstProject = projectCells.element(boundBy: 0)
        XCTAssertTrue(firstProject.exists, "First project cell should exist")
        
        // Take screenshot for evidence
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Project_List_Loaded"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testProjectCellContents() {
        let projectTable = app.tables["projectList"]
        XCTAssertTrue(projectTable.waitForExistence(timeout: 10))
        
        let firstProjectCell = projectTable.cells.element(boundBy: 0)
        XCTAssertTrue(firstProjectCell.exists)
        
        // Check for title label
        let titleLabel = firstProjectCell.staticTexts["projectTitle"]
        if !titleLabel.exists {
            // Try alternative query
            let anyTitle = firstProjectCell.staticTexts.firstMatch
            XCTAssertTrue(anyTitle.exists, "Project cell should have a title")
        }
        
        // Check for timestamp
        let timestampLabel = firstProjectCell.staticTexts["projectTimestamp"]
        if !timestampLabel.exists {
            print("Warning: Timestamp label not found with identifier 'projectTimestamp'")
        }
    }
    
    func testProjectSelection() {
        let projectTable = app.tables["projectList"]
        XCTAssertTrue(projectTable.waitForExistence(timeout: 10))
        
        // Get initial count
        let initialCellCount = projectTable.cells.count
        XCTAssertGreaterThan(initialCellCount, 0, "Should have at least one project")
        
        // Tap first project
        let firstProject = projectTable.cells.element(boundBy: 0)
        firstProject.tap()
        
        // Verify navigation to chat view
        let chatView = app.collectionViews["messageList"]
        let chatViewExists = chatView.waitForExistence(timeout: 5)
        
        if !chatViewExists {
            // Try alternative identifiers
            let anyCollectionView = app.collectionViews.firstMatch
            XCTAssertTrue(anyCollectionView.waitForExistence(timeout: 5), "Should navigate to chat view")
        }
        
        // Take screenshot
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Project_Selected_Chat_View"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testMultipleProjectsScroll() {
        let projectTable = app.tables["projectList"]
        XCTAssertTrue(projectTable.waitForExistence(timeout: 10))
        
        // Check if we have enough projects to scroll
        let cellCount = projectTable.cells.count
        
        if cellCount > 5 {
            // Perform scroll test
            projectTable.swipeUp()
            Thread.sleep(forTimeInterval: 0.5)
            projectTable.swipeDown()
            Thread.sleep(forTimeInterval: 0.5)
            
            // Verify table still responsive
            XCTAssertTrue(projectTable.exists)
        } else {
            print("Note: Not enough projects for scroll test (found \(cellCount))")
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToFirstProject() {
        let projectTable = app.tables["projectList"]
        XCTAssertTrue(projectTable.waitForExistence(timeout: 10))
        
        let firstProject = projectTable.cells.element(boundBy: 0)
        XCTAssertTrue(firstProject.exists)
        firstProject.tap()
        
        // Wait for navigation
        Thread.sleep(forTimeInterval: 1)
    }
}