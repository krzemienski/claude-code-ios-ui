import UIKit

/// Singleton manager for caching images with memory and disk caching
class ImageCacheManager {
    
    // MARK: - Singleton
    
    static let shared = ImageCacheManager()
    
    // MARK: - Properties
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCacheQueue = DispatchQueue(label: "com.claudecode.imagecache", attributes: .concurrent)
    private let diskCacheURL: URL
    
    // Configuration
    var maxMemoryCost: Int = 100 * 1024 * 1024 // 100MB
    var maxDiskSize: Int = 500 * 1024 * 1024 // 500MB
    
    // MARK: - Initialization
    
    private init() {
        // Setup memory cache
        memoryCache.totalCostLimit = maxMemoryCost
        memoryCache.countLimit = 100
        
        // Setup disk cache directory
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = cacheDirectory.appendingPathComponent("ImageCache")
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        
        // Listen for memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        // Clean old cache on startup
        cleanDiskCache()
    }
    
    // MARK: - Public Methods
    
    /// Load image from cache or fetch from URL
    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let key = url.absoluteString as NSString
        
        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: key) {
            print("🖼️ Image loaded from memory cache: \(url.lastPathComponent)")
            completion(cachedImage)
            return
        }
        
        // Check disk cache
        diskCacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            let diskPath = self.diskCachePath(for: key as String)
            if let diskImage = UIImage(contentsOfFile: diskPath) {
                print("💾 Image loaded from disk cache: \(url.lastPathComponent)")
                
                // Store in memory cache
                self.memoryCache.setObject(diskImage, forKey: key, cost: diskImage.jpegData(compressionQuality: 1.0)?.count ?? 0)
                
                DispatchQueue.main.async {
                    completion(diskImage)
                }
                return
            }
            
            // Fetch from network
            self.fetchImage(from: url) { image in
                completion(image)
            }
        }
    }
    
    /// Preload images for better performance
    func preloadImages(urls: [URL]) {
        for url in urls {
            loadImage(from: url) { _ in
                // Just cache, don't need the result
            }
        }
    }
    
    /// Clear all caches
    func clearCache() {
        memoryCache.removeAllObjects()
        
        diskCacheQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            try? FileManager.default.removeItem(at: self.diskCacheURL)
            try? FileManager.default.createDirectory(at: self.diskCacheURL, withIntermediateDirectories: true)
        }
        
        print("🗑️ Image cache cleared")
    }
    
    /// Get cache size
    func getCacheSize(completion: @escaping (Int) -> Void) {
        diskCacheQueue.async { [weak self] in
            guard let self = self else { 
                completion(0)
                return 
            }
            
            var size = 0
            let fileManager = FileManager.default
            
            if let files = try? fileManager.contentsOfDirectory(at: self.diskCacheURL, includingPropertiesForKeys: [.fileSizeKey]) {
                for file in files {
                    if let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                        size += fileSize
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(size)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        print("🌐 Fetching image from network: \(url)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  let image = UIImage(data: data) else {
                print("❌ Failed to fetch image: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let key = url.absoluteString as NSString
            
            // Store in memory cache
            self.memoryCache.setObject(image, forKey: key, cost: data.count)
            
            // Store in disk cache
            self.diskCacheQueue.async(flags: .barrier) {
                let diskPath = self.diskCachePath(for: key as String)
                try? data.write(to: URL(fileURLWithPath: diskPath))
            }
            
            print("✅ Image cached: \(url.lastPathComponent)")
            
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
    
    private func diskCachePath(for key: String) -> String {
        let filename = key.data(using: .utf8)?.base64EncodedString() ?? key
        return diskCacheURL.appendingPathComponent(filename).path
    }
    
    private func cleanDiskCache() {
        diskCacheQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let fileManager = FileManager.default
            let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
            
            do {
                let files = try fileManager.contentsOfDirectory(at: self.diskCacheURL, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey])
                
                var totalSize = 0
                var filesToDelete: [(URL, Date)] = []
                
                for file in files {
                    let resourceValues = try file.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
                    
                    if let modificationDate = resourceValues.contentModificationDate {
                        if modificationDate < oneWeekAgo {
                            filesToDelete.append((file, modificationDate))
                        } else if let fileSize = resourceValues.fileSize {
                            totalSize += fileSize
                        }
                    }
                }
                
                // Delete old files
                for (file, _) in filesToDelete {
                    try? fileManager.removeItem(at: file)
                }
                
                // If still over limit, delete oldest files
                if totalSize > self.maxDiskSize {
                    let sortedFiles = files.sorted { file1, file2 in
                        let date1 = try? file1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date()
                        let date2 = try? file2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date()
                        return date1! < date2!
                    }
                    
                    for file in sortedFiles {
                        try? fileManager.removeItem(at: file)
                        totalSize -= (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) ?? 0
                        
                        if totalSize < self.maxDiskSize * 3 / 4 { // Keep 75% of max
                            break
                        }
                    }
                }
                
                print("🧹 Disk cache cleaned. Size: \(totalSize / 1024 / 1024)MB")
                
            } catch {
                print("❌ Failed to clean disk cache: \(error)")
            }
        }
    }
    
    @objc private func handleMemoryWarning() {
        print("⚠️ Memory warning received - clearing image memory cache")
        memoryCache.removeAllObjects()
    }
}

// MARK: - UIImageView Extension

extension UIImageView {
    
    /// Load image from URL with caching
    func loadImage(from url: URL?, placeholder: UIImage? = nil) {
        // Set placeholder
        self.image = placeholder
        
        guard let url = url else { return }
        
        // Load from cache or network
        ImageCacheManager.shared.loadImage(from: url) { [weak self] image in
            self?.image = image ?? placeholder
        }
    }
    
    /// Load image from URL string with caching
    func loadImage(from urlString: String?, placeholder: UIImage? = nil) {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            self.image = placeholder
            return
        }
        
        loadImage(from: url, placeholder: placeholder)
    }
}