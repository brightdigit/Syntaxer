import Foundation
import CryptoKit

public actor CacheManager {
    private let cacheDirectory: URL
    private let maxCacheSize: Int
    private let maxCacheAge: TimeInterval
    
    private struct CacheEntry: Codable {
        let dslCode: String
        let generatedCode: String
        let timestamp: Date
        let hash: String
    }
    
    public init(cacheDirectory: URL? = nil, maxCacheSize: Int = 100, maxCacheAge: TimeInterval = 86400) {
        self.cacheDirectory = cacheDirectory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("syntaxer")
        self.maxCacheSize = maxCacheSize
        self.maxCacheAge = maxCacheAge
        
        // Ensure cache directory exists
        try? FileManager.default.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)
    }
    
    public func getCachedCode(for dslCode: String) async -> String? {
        let hash = computeHash(for: dslCode)
        let cacheFile = cacheDirectory.appendingPathComponent("\(hash).json")
        
        guard FileManager.default.fileExists(atPath: cacheFile.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: cacheFile)
            let entry = try JSONDecoder().decode(CacheEntry.self, from: data)
            
            // Check if cache is still valid
            if Date().timeIntervalSince(entry.timestamp) > maxCacheAge {
                try? FileManager.default.removeItem(at: cacheFile)
                return nil
            }
            
            // Verify hash matches
            if entry.hash == hash && entry.dslCode == dslCode {
                return entry.generatedCode
            }
        } catch {
            // Invalid cache entry, remove it
            try? FileManager.default.removeItem(at: cacheFile)
        }
        
        return nil
    }
    
    public func cacheCode(dslCode: String, generatedCode: String) async {
        let hash = computeHash(for: dslCode)
        let entry = CacheEntry(
            dslCode: dslCode,
            generatedCode: generatedCode,
            timestamp: Date(),
            hash: hash
        )
        
        let cacheFile = cacheDirectory.appendingPathComponent("\(hash).json")
        
        do {
            let data = try JSONEncoder().encode(entry)
            try data.write(to: cacheFile)
            
            // Clean up old cache entries if needed
            await cleanupCacheIfNeeded()
        } catch {
            // Silently fail caching
        }
    }
    
    private func computeHash(for input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func cleanupCacheIfNeeded() async {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.creationDateKey])
            
            if files.count > maxCacheSize {
                // Sort by creation date and remove oldest files
                let sortedFiles = try files.sorted { file1, file2 in
                    let date1 = try file1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                    let date2 = try file2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                    return date1 < date2
                }
                
                let filesToRemove = sortedFiles.prefix(files.count - maxCacheSize)
                for file in filesToRemove {
                    try? FileManager.default.removeItem(at: file)
                }
            }
        } catch {
            // Silently fail cleanup
        }
    }
    
    public func clearCache() async {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}