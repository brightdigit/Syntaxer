import Foundation
import Subprocess
#if canImport(System)
import System
#else
import SystemPackage
#endif

public actor TemplateManager {
    private let templateDirectory: URL
    private let lockFile: URL
    private var isInitialized = false
    
    public init(templateDirectory: URL? = nil) {
        self.templateDirectory = templateDirectory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("syntaxer_template")
        self.lockFile = self.templateDirectory.appendingPathComponent(".lock")
    }
    
    public func ensureTemplate() async throws {
        if isInitialized && FileManager.default.fileExists(atPath: templateDirectory.path) {
            return
        }
        
        // Check if another process is already creating the template
        if FileManager.default.fileExists(atPath: lockFile.path) {
            // Wait for the other process to finish
            for _ in 0..<30 {
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                if !FileManager.default.fileExists(atPath: lockFile.path) {
                    break
                }
            }
        }
        
        // If template exists now, we're done
        if FileManager.default.fileExists(atPath: templateDirectory.appendingPathComponent(".build").path) {
            isInitialized = true
            return
        }
        
        // Create lock file
        FileManager.default.createFile(atPath: lockFile.path, contents: nil)
        defer { try? FileManager.default.removeItem(at: lockFile) }
        
        // Create template directory
        try FileManager.default.createDirectory(at: templateDirectory, withIntermediateDirectories: true)
        
        // Create Package.swift for template
        let packageManifest = """
        // swift-tools-version: 6.0
        import PackageDescription
        
        let package = Package(
            name: "SyntaxKitTemplate",
            platforms: [.macOS(.v13)],
            dependencies: [
                .package(url: "https://github.com/brightdigit/SyntaxKit.git", branch: "main")
            ],
            targets: [
                .target(
                    name: "SyntaxKitTemplate",
                    dependencies: [
                        .product(name: "SyntaxKit", package: "SyntaxKit")
                    ]
                )
            ]
        )
        """
        
        try packageManifest.write(
            to: templateDirectory.appendingPathComponent("Package.swift"),
            atomically: true,
            encoding: .utf8
        )
        
        // Create a minimal source file
        let sourcesDir = templateDirectory.appendingPathComponent("Sources/SyntaxKitTemplate")
        try FileManager.default.createDirectory(at: sourcesDir, withIntermediateDirectories: true)
        
        let templateSource = """
        import SyntaxKit
        import SwiftSyntax
        
        public struct Template {
            public static func prepare() {
                // This ensures all SyntaxKit dependencies are compiled
            }
        }
        """
        
        try templateSource.write(
            to: sourcesDir.appendingPathComponent("Template.swift"),
            atomically: true,
            encoding: .utf8
        )
        
        // Build the template package
        let result = try await run(
            .path("/usr/bin/swift"),
            arguments: ["build", "--configuration", "release"],
            environment: .custom([:]),
            workingDirectory: FilePath(templateDirectory.path()),
            output: .string,
            error: .string
        )
        
        guard case .exited(let code) = result.terminationStatus, code == 0 else {
            // Clean up on failure
            try? FileManager.default.removeItem(at: templateDirectory)
            throw CodeGenerationService.ValidationError("Failed to build template package: \(result.standardError ?? "Unknown error")")
        }
        
        isInitialized = true
    }
    
    public func copyTemplate(to destination: URL) async throws {
        try await ensureTemplate()
        
        // Copy only the necessary files
        let filesToCopy = [
            ".build/release/index",
            ".build/checkouts",
            ".build/workspace-state.json",
            ".build/repositories"
        ]
        
        // Create destination .build directory
        let destBuildDir = destination.appendingPathComponent(".build")
        try FileManager.default.createDirectory(at: destBuildDir, withIntermediateDirectories: true)
        
        for file in filesToCopy {
            let sourcePath = templateDirectory.appendingPathComponent(file)
            let destPath = destination.appendingPathComponent(file)
            
            if FileManager.default.fileExists(atPath: sourcePath.path) {
                // Create parent directory if needed
                let parentDir = destPath.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
                
                // Copy the file/directory
                try FileManager.default.copyItem(at: sourcePath, to: destPath)
            }
        }
    }
    
    public func clearTemplate() async {
        try? FileManager.default.removeItem(at: templateDirectory)
        isInitialized = false
    }
}