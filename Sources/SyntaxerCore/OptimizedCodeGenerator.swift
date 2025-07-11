import Foundation
import Subprocess
#if canImport(System)
import System
#else
import SystemPackage
#endif

public struct OptimizedCodeGenerator: Sendable {
    private let syntaxKitCacheDir: URL
    private let metrics = PerformanceMetrics()
    
    public init() {
        self.syntaxKitCacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("syntaxer_deps/SyntaxKit")
    }
    
    public func ensureSyntaxKitCache() async throws {
        guard !FileManager.default.fileExists(atPath: syntaxKitCacheDir.path) else {
            return
        }
        
        let startTime = Date()
        
        // Clone SyntaxKit to cache directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("syntaxkit_clone_\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Clone the repository
        let cloneResult = try await run(
            .path("/usr/bin/git"),
            arguments: ["clone", "https://github.com/brightdigit/SyntaxKit.git", syntaxKitCacheDir.path],
            environment: .inherit,
            workingDirectory: FilePath(tempDir.path()),
            output: .string,
            error: .string
        )
        
        guard case .exited(let code) = cloneResult.terminationStatus, code == 0 else {
            throw CodeGenerationService.ValidationError("Failed to clone SyntaxKit: \(cloneResult.standardError ?? "Unknown error")")
        }
        
        await metrics.record(metric: "syntaxkit_clone", duration: Date().timeIntervalSince(startTime))
    }
    
    public func generateOptimizedPackageManifest(syntaxKitPath: String? = nil) -> String {
        let dependency: String
        if let customPath = syntaxKitPath {
            dependency = ".package(path: \"\(customPath)\")"
        } else if FileManager.default.fileExists(atPath: syntaxKitCacheDir.path) {
            dependency = ".package(path: \"\(syntaxKitCacheDir.path)\")"
        } else {
            dependency = ".package(url: \"https://github.com/brightdigit/SyntaxKit.git\", branch: \"main\")"
        }
        
        return """
        // swift-tools-version: 6.0
        import PackageDescription
        
        let package = Package(
            name: "SyntaxKitEval",
            platforms: [.macOS(.v13)],
            dependencies: [\(dependency)],
            targets: [
                .executableTarget(
                    name: "SyntaxKitEval",
                    dependencies: [
                        .product(name: "SyntaxKit", package: "SyntaxKit")
                    ],
                    swiftSettings: [
                        .unsafeFlags(["-O", "-whole-module-optimization"], .when(configuration: .release))
                    ]
                )
            ]
        )
        """
    }
    
    public func runWithMetrics(_ command: String, arguments: [String], workingDirectory: URL, timeout: TimeInterval) async throws -> (output: String?, error: String?, status: Int32) {
        let startTime = Date()
        
        let result = try await withThrowingTaskGroup(of: (String?, String?, Int32).self) { group in
            group.addTask {
                let result = try await run(
                    .path(FilePath(command)),
                    arguments: Arguments(arguments),
                    environment: .custom([:]),
                    workingDirectory: FilePath(workingDirectory.path()),
                    output: .string,
                    error: .string
                )
                
                let status: Int32
                switch result.terminationStatus {
                case .exited(let code):
                    status = Int32(code)
                case .unhandledException(let code):
                    status = Int32(code)
                }
                
                return (result.standardOutput, result.standardError, status)
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw CodeGenerationService.ValidationError("Process timed out after \(timeout) seconds")
            }
            
            let result = try await group.next()!
            group.cancelAll()
            
            let duration = Date().timeIntervalSince(startTime)
            let metricName = arguments.first == "build" ? "swift_build" : "swift_run"
            await metrics.record(metric: metricName, duration: duration)
            
            return result
        }
        
        return result
    }
    
    public func getMetricsSummary() async -> [String: MetricSummary] {
        return await metrics.getMetricsSummary()
    }
}