import XCTest
import os.log
@testable import ClaudeCodeUI

/// Advanced memory leak detection and performance monitoring
final class MemoryLeakDetectorTests: XCTestCase {
    
    private let logger = Logger(subsystem: "com.claudecode.ui", category: "MemoryLeakDetector")
    private var initialMemory: Int64 = 0
    private var memorySnapshots: [(String, Int64, Date)] = []
    private var retainCycles: [String] = []
    
    override func setUp() {
        super.setUp()
        initialMemory = getMemoryUsage()
        memorySnapshots.removeAll()
        retainCycles.removeAll()
        logger.info("Initial memory baseline: \(formatBytes(initialMemory))")
    }
    
    override func tearDown() {
        let finalMemory = getMemoryUsage()
        let growth = finalMemory - initialMemory
        logger.info("Memory growth in test: \(formatBytes(growth))")
        super.tearDown()
    }
    
    // MARK: - View Controller Memory Leaks
    
    func testChatViewControllerMemoryLeak() throws {
        logger.info("Testing ChatViewController for memory leaks")
        
        autoreleasepool {
            var viewController: ChatViewController? = ChatViewController()
            let viewModel = ChatViewModel()
            viewController?.viewModel = viewModel
            
            // Simulate lifecycle
            viewController?.loadViewIfNeeded()
            viewController?.viewDidLoad()
            viewController?.viewWillAppear(false)
            viewController?.viewDidAppear(false)
            
            // Take snapshot after setup
            recordMemorySnapshot("After ChatVC setup")
            
            // Simulate user interactions
            for i in 1...10 {
                viewModel.sendMessage("Test message \(i)")
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            recordMemorySnapshot("After sending messages")
            
            // Simulate cleanup
            viewController?.viewWillDisappear(false)
            viewController?.viewDidDisappear(false)
            
            // Strong reference check
            weak var weakVC = viewController
            viewController = nil
            
            // Force cleanup
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
            
            XCTAssertNil(weakVC, "ChatViewController not deallocated - potential retain cycle")
            
            recordMemorySnapshot("After ChatVC cleanup")
        }
        
        analyzeMemoryGrowth(threshold: 5_000_000) // 5MB threshold
    }
    
    func testProjectsViewControllerMemoryLeak() throws {
        logger.info("Testing ProjectsViewController for memory leaks")
        
        autoreleasepool {
            var viewController: ProjectsViewController? = ProjectsViewController()
            
            // Simulate lifecycle
            viewController?.loadViewIfNeeded()
            viewController?.viewDidLoad()
            
            recordMemorySnapshot("After ProjectsVC setup")
            
            // Simulate loading projects
            for _ in 1...5 {
                viewController?.reloadData()
                Thread.sleep(forTimeInterval: 0.2)
            }
            
            recordMemorySnapshot("After loading projects")
            
            // Check for leak
            weak var weakVC = viewController
            viewController = nil
            
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
            
            XCTAssertNil(weakVC, "ProjectsViewController not deallocated - potential retain cycle")
            
            recordMemorySnapshot("After ProjectsVC cleanup")
        }
        
        analyzeMemoryGrowth(threshold: 3_000_000) // 3MB threshold
    }
    
    // MARK: - WebSocket Memory Leaks
    
    func testWebSocketManagerMemoryLeak() throws {
        logger.info("Testing WebSocketManager for memory leaks")
        
        autoreleasepool {
            var webSocketManager: WebSocketManager? = WebSocketManager()
            
            // Setup callbacks (potential retain cycle source)
            webSocketManager?.onMessageReceived = { message in
                print("Received: \(message)")
            }
            
            webSocketManager?.onConnectionStateChanged = { state in
                print("State: \(state)")
            }
            
            webSocketManager?.connect()
            recordMemorySnapshot("After WebSocket connect")
            
            // Send messages
            for i in 1...20 {
                let message = Message(
                    id: "\(i)",
                    text: "Test message \(i)",
                    timestamp: Date(),
                    isFromUser: true
                )
                webSocketManager?.sendMessage(message) { _ in }
            }
            
            Thread.sleep(forTimeInterval: 2)
            recordMemorySnapshot("After sending messages")
            
            // Disconnect and cleanup
            webSocketManager?.disconnect()
            
            weak var weakManager = webSocketManager
            webSocketManager = nil
            
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
            
            XCTAssertNil(weakManager, "WebSocketManager not deallocated - potential retain cycle")
            
            recordMemorySnapshot("After WebSocket cleanup")
        }
        
        analyzeMemoryGrowth(threshold: 2_000_000) // 2MB threshold
    }
    
    // MARK: - Data Persistence Memory Leaks
    
    func testCoreDataMemoryLeak() throws {
        logger.info("Testing Core Data stack for memory leaks")
        
        autoreleasepool {
            let persistenceController = PersistenceController.shared
            let context = persistenceController.container.viewContext
            
            recordMemorySnapshot("Before Core Data operations")
            
            // Create many objects
            for i in 1...100 {
                let session = SessionEntity(context: context)
                session.id = UUID()
                session.title = "Test Session \(i)"
                session.createdAt = Date()
                
                for j in 1...10 {
                    let message = MessageEntity(context: context)
                    message.id = UUID()
                    message.text = "Message \(j) in session \(i)"
                    message.timestamp = Date()
                    message.session = session
                }
            }
            
            try? context.save()
            recordMemorySnapshot("After creating Core Data objects")
            
            // Fetch operations
            let fetchRequest = SessionEntity.fetchRequest()
            let sessions = try? context.fetch(fetchRequest)
            logger.info("Fetched \(sessions?.count ?? 0) sessions")
            
            recordMemorySnapshot("After fetching")
            
            // Delete all
            sessions?.forEach { context.delete($0) }
            try? context.save()
            
            // Reset context
            context.reset()
            
            recordMemorySnapshot("After Core Data cleanup")
        }
        
        analyzeMemoryGrowth(threshold: 10_000_000) // 10MB threshold for bulk operations
    }
    
    // MARK: - Image Loading Memory Leaks
    
    func testImageCacheMemoryLeak() throws {
        logger.info("Testing image cache for memory leaks")
        
        autoreleasepool {
            var imageCache: NSCache<NSString, UIImage>? = NSCache()
            imageCache?.countLimit = 50
            imageCache?.totalCostLimit = 50_000_000 // 50MB
            
            recordMemorySnapshot("Before image caching")
            
            // Load and cache images
            for i in 1...20 {
                let image = generateTestImage(size: CGSize(width: 500, height: 500))
                imageCache?.setObject(image, forKey: "image_\(i)" as NSString)
            }
            
            recordMemorySnapshot("After caching images")
            
            // Access cached images
            for i in 1...20 {
                _ = imageCache?.object(forKey: "image_\(i)" as NSString)
            }
            
            recordMemorySnapshot("After accessing cached images")
            
            // Clear cache
            imageCache?.removeAllObjects()
            
            weak var weakCache = imageCache
            imageCache = nil
            
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
            
            XCTAssertNil(weakCache, "Image cache not deallocated")
            
            recordMemorySnapshot("After image cache cleanup")
        }
        
        analyzeMemoryGrowth(threshold: 15_000_000) // 15MB threshold for images
    }
    
    // MARK: - Closure Retain Cycle Detection
    
    func testClosureRetainCycles() throws {
        logger.info("Testing for closure retain cycles")
        
        class TestObject {
            var value = 0
            var closure: (() -> Void)?
            
            func setupStrongCycle() {
                // This creates a retain cycle
                closure = {
                    self.value += 1
                }
            }
            
            func setupWeakCycle() {
                // This avoids retain cycle
                closure = { [weak self] in
                    self?.value += 1
                }
            }
            
            deinit {
                print("TestObject deallocated")
            }
        }
        
        // Test strong reference cycle
        autoreleasepool {
            var strongObject: TestObject? = TestObject()
            strongObject?.setupStrongCycle()
            
            weak var weakRef = strongObject
            strongObject = nil
            
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
            
            if weakRef != nil {
                retainCycles.append("TestObject with strong closure reference")
                logger.warning("Detected retain cycle in TestObject with strong closure")
            }
        }
        
        // Test weak reference (should deallocate)
        autoreleasepool {
            var weakObject: TestObject? = TestObject()
            weakObject?.setupWeakCycle()
            
            weak var weakRef = weakObject
            weakObject = nil
            
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
            
            XCTAssertNil(weakRef, "TestObject with weak closure should deallocate")
        }
        
        XCTAssertTrue(retainCycles.isEmpty, "Retain cycles detected: \(retainCycles)")
    }
    
    // MARK: - Long Session Memory Test
    
    func testLongSessionMemoryGrowth() throws {
        logger.info("Testing memory growth during long session")
        
        let testDuration: TimeInterval = 30 // 30 seconds
        let startTime = Date()
        var peakMemory: Int64 = initialMemory
        
        recordMemorySnapshot("Start of long session")
        
        // Simulate long user session
        while Date().timeIntervalSince(startTime) < testDuration {
            autoreleasepool {
                // Simulate various operations
                let viewModel = ChatViewModel()
                
                for i in 1...5 {
                    viewModel.sendMessage("Long session message \(i)")
                }
                
                // Check memory periodically
                let currentMemory = getMemoryUsage()
                if currentMemory > peakMemory {
                    peakMemory = currentMemory
                    logger.info("New peak memory: \(formatBytes(peakMemory))")
                }
                
                Thread.sleep(forTimeInterval: 1)
            }
        }
        
        recordMemorySnapshot("End of long session")
        
        // Allow cleanup
        Thread.sleep(forTimeInterval: 5)
        
        let finalMemory = getMemoryUsage()
        recordMemorySnapshot("After cleanup")
        
        let totalGrowth = finalMemory - initialMemory
        let peakGrowth = peakMemory - initialMemory
        
        logger.info("Long Session Memory Results:")
        logger.info("  - Duration: \(testDuration)s")
        logger.info("  - Initial: \(formatBytes(initialMemory))")
        logger.info("  - Peak: \(formatBytes(peakMemory)) (+\(formatBytes(peakGrowth)))")
        logger.info("  - Final: \(formatBytes(finalMemory)) (+\(formatBytes(totalGrowth)))")
        
        // Allow reasonable growth over long session (20MB)
        XCTAssertLessThan(totalGrowth, 20_000_000, "Excessive memory growth: \(formatBytes(totalGrowth))")
    }
    
    // MARK: - Notification Observer Leaks
    
    func testNotificationObserverLeaks() throws {
        logger.info("Testing notification observer cleanup")
        
        class ObserverTest {
            var observations: [NSObjectProtocol] = []
            
            func addObservers() {
                let observer = NotificationCenter.default.addObserver(
                    forName: UIApplication.didReceiveMemoryWarningNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    print("Memory warning received")
                }
                observations.append(observer)
            }
            
            func removeObservers() {
                observations.forEach {
                    NotificationCenter.default.removeObserver($0)
                }
                observations.removeAll()
            }
            
            deinit {
                removeObservers()
            }
        }
        
        autoreleasepool {
            var observer: ObserverTest? = ObserverTest()
            observer?.addObservers()
            
            recordMemorySnapshot("After adding observers")
            
            // Post notifications
            for _ in 1...10 {
                NotificationCenter.default.post(
                    name: UIApplication.didReceiveMemoryWarningNotification,
                    object: nil
                )
            }
            
            weak var weakObserver = observer
            observer = nil
            
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
            
            XCTAssertNil(weakObserver, "Observer not deallocated - notification leak")
            
            recordMemorySnapshot("After observer cleanup")
        }
        
        analyzeMemoryGrowth(threshold: 1_000_000) // 1MB threshold
    }
    
    // MARK: - Comprehensive Memory Report
    
    func testGenerateMemoryReport() throws {
        logger.info("Generating comprehensive memory leak report")
        
        // Run all memory tests
        try? testChatViewControllerMemoryLeak()
        try? testProjectsViewControllerMemoryLeak()
        try? testWebSocketManagerMemoryLeak()
        try? testCoreDataMemoryLeak()
        try? testImageCacheMemoryLeak()
        try? testClosureRetainCycles()
        try? testLongSessionMemoryGrowth()
        try? testNotificationObserverLeaks()
        
        // Generate report
        logger.info("======= MEMORY LEAK DETECTION REPORT =======")
        logger.info("Timestamp: \(Date())")
        logger.info("")
        logger.info("MEMORY SNAPSHOTS:")
        
        for (label, memory, timestamp) in memorySnapshots {
            let growth = memory - initialMemory
            logger.info("  - \(label): \(formatBytes(memory)) (+\(formatBytes(growth)))")
        }
        
        logger.info("")
        logger.info("RETAIN CYCLES DETECTED:")
        if retainCycles.isEmpty {
            logger.info("  ✅ No retain cycles found")
        } else {
            for cycle in retainCycles {
                logger.error("  ❌ \(cycle)")
            }
        }
        
        let finalMemory = getMemoryUsage()
        let totalGrowth = finalMemory - initialMemory
        
        logger.info("")
        logger.info("OVERALL MEMORY ANALYSIS:")
        logger.info("  - Initial Memory: \(formatBytes(initialMemory))")
        logger.info("  - Final Memory: \(formatBytes(finalMemory))")
        logger.info("  - Total Growth: \(formatBytes(totalGrowth))")
        logger.info("  - Status: \(totalGrowth < 50_000_000 ? "✅ PASS" : "❌ FAIL")")
        logger.info("=============================================")
    }
    
    // MARK: - Helper Methods
    
    private func recordMemorySnapshot(_ label: String) {
        let memory = getMemoryUsage()
        memorySnapshots.append((label, memory, Date()))
        logger.info("Memory snapshot '\(label)': \(formatBytes(memory))")
    }
    
    private func analyzeMemoryGrowth(threshold: Int64) {
        guard let lastSnapshot = memorySnapshots.last else { return }
        
        let growth = lastSnapshot.1 - initialMemory
        let status = growth < threshold ? "✅ PASS" : "❌ FAIL"
        
        logger.info("Memory growth analysis: \(formatBytes(growth)) \(status) (threshold: \(formatBytes(threshold)))")
        
        XCTAssertLessThan(growth, threshold, "Memory growth exceeds threshold: \(formatBytes(growth)) > \(formatBytes(threshold))")
    }
    
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
    
    private func generateTestImage(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        UIColor.random.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
}

extension UIColor {
    static var random: UIColor {
        UIColor(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1.0
        )
    }
}