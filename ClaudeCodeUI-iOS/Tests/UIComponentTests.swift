import XCTest
@testable import ClaudeCodeUI

class UIComponentTests: XCTestCase {
    
    var window: UIWindow!
    var testViewController: UIViewController!
    
    override func setUp() {
        super.setUp()
        window = UIWindow(frame: UIScreen.main.bounds)
        testViewController = UIViewController()
        window.rootViewController = testViewController
        window.makeKeyAndVisible()
    }
    
    override func tearDown() {
        window = nil
        testViewController = nil
        super.tearDown()
    }
    
    // MARK: - Success Notification Tests
    
    func testSuccessNotificationDisplay() {
        let expectation = XCTestExpectation(description: "Success notification displayed")
        
        DispatchQueue.main.async {
            let notification = SuccessNotificationView()
            notification.show(message: "Test successful!", title: "Success", in: self.testViewController.view)
            
            // Verify notification is added to view
            XCTAssertTrue(self.testViewController.view.subviews.contains(where: { $0 is SuccessNotificationView }))
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSuccessNotificationAutoDismiss() {
        let expectation = XCTestExpectation(description: "Success notification auto-dismissed")
        
        DispatchQueue.main.async {
            let notification = SuccessNotificationView()
            notification.autoDismissDelay = 0.5 // Short delay for testing
            notification.show(message: "Test", in: self.testViewController.view)
            
            // Wait for auto-dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                XCTAssertFalse(self.testViewController.view.subviews.contains(where: { $0 is SuccessNotificationView }))
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Progress Indicator Tests
    
    func testProgressIndicatorDisplay() {
        let expectation = XCTestExpectation(description: "Progress indicator displayed")
        
        DispatchQueue.main.async {
            let indicator = ProgressIndicatorView()
            indicator.show(title: "Loading...", in: self.testViewController.view)
            
            XCTAssertTrue(self.testViewController.view.subviews.contains(where: { $0 is ProgressIndicatorView }))
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testProgressIndicatorUpdate() {
        let expectation = XCTestExpectation(description: "Progress updated")
        
        DispatchQueue.main.async {
            let indicator = ProgressIndicatorView()
            indicator.show(title: "Processing", in: self.testViewController.view)
            
            // Update progress
            indicator.updateProgress(0.5, status: "50% complete")
            
            // Verify progress update (would need to expose properties for testing)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                indicator.dismiss {
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Connection Status Tests
    
    func testConnectionStatusUpdates() {
        let statusView = ConnectionStatusView()
        
        // Test all status states
        let statuses: [ConnectionStatus] = [.connected, .connecting, .disconnected, .reconnecting, .error]
        
        for status in statuses {
            statusView.setStatus(status)
            XCTAssertEqual(statusView.status, status)
        }
    }
    
    func testConnectionStatusManager() {
        let statusView1 = ConnectionStatusView()
        let statusView2 = ConnectionStatusView()
        
        ConnectionStatusManager.shared.registerStatusView(statusView1)
        ConnectionStatusManager.shared.registerStatusView(statusView2)
        
        // Post notification
        NotificationCenter.default.post(name: NSNotification.Name("WebSocketConnected"), object: nil)
        
        // Wait for async update
        let expectation = XCTestExpectation(description: "Status updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(statusView1.status, .connected)
            XCTAssertEqual(statusView2.status, .connected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Clean up
        ConnectionStatusManager.shared.unregisterStatusView(statusView1)
        ConnectionStatusManager.shared.unregisterStatusView(statusView2)
    }
}

// MARK: - Performance Tests

extension UIComponentTests {
    
    func testNotificationPerformance() {
        measure {
            let notification = SuccessNotificationView()
            notification.show(message: "Performance test", in: testViewController.view)
            notification.dismiss()
        }
    }
    
    func testProgressIndicatorPerformance() {
        measure {
            let indicator = ProgressIndicatorView()
            indicator.show(title: "Performance", in: testViewController.view)
            for i in 0...10 {
                indicator.updateProgress(Float(i) / 10.0)
            }
            indicator.dismiss()
        }
    }
}