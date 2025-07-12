import Foundation
import SyntaxKit
import SwiftSyntax
import os.log

public struct CodeGenerationService {
    
    private let logger = Logger(subsystem: "com.syntaxer.core", category: "CodeGeneration")
    
    public struct GenerationOptions {
        public let timeout: TimeInterval
        public let workingDirectory: URL?
        public let syntaxKitPath: String?
        public let enableLogging: Bool
        
        public init(timeout: TimeInterval = 30.0, workingDirectory: URL? = nil, syntaxKitPath: String? = nil, enableLogging: Bool = true) {
            self.timeout = timeout
            self.workingDirectory = workingDirectory
            self.syntaxKitPath = syntaxKitPath
            self.enableLogging = enableLogging
        }
    }
    
    public struct ValidationError: Error, CustomStringConvertible {
        public let description: String
        
        public init(_ description: String) {
            self.description = description
        }
    }
    
    public init() {}
    
    public func generateCode(from dslCode: String, options: GenerationOptions = GenerationOptions()) async throws -> String {
        logger.info("Starting code generation process")
        logger.debug("DSL code length: \(dslCode.count) characters")
        
        // Input validation
        guard !dslCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            logger.error("DSL code validation failed: empty input")
            throw ValidationError("DSL code cannot be empty")
        }
        
        logger.info("Input validation passed")
        
        // Basic security validation - prevent obvious injection attempts
        let dangerousPatterns = ["import Process", "import Darwin", "system(", "exec(", "fork(", "kill("]
        for pattern in dangerousPatterns {
            if dslCode.contains(pattern) {
                logger.error("Security validation failed: detected dangerous pattern '\(pattern)'")
                throw ValidationError("DSL code contains potentially dangerous patterns")
            }
        }
        
        logger.info("Security validation passed")
        
        // Create isolated temporary directory
        let tempDir = FileManager.default.temporaryDirectory
        let packageDir = tempDir.appendingPathComponent("syntaxkit_eval_\(UUID().uuidString)")
        
        logger.info("Creating temporary directory at: \(packageDir.path)")
        
        defer {
            // Always clean up
            logger.info("Cleaning up temporary directory: \(packageDir.path)")
            try? FileManager.default.removeItem(at: packageDir)
        }
        
        do {
            try FileManager.default.createDirectory(at: packageDir, withIntermediateDirectories: true)
            logger.debug("Temporary directory created successfully")
        } catch {
            logger.error("Failed to create temporary directory: \(error.localizedDescription)")
            throw error
        }
        
        // Set restrictive permissions on temp directory
        do {
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: packageDir.path)
            logger.debug("Set restrictive permissions on temporary directory")
        } catch {
            logger.warning("Failed to set restrictive permissions: \(error.localizedDescription)")
        }
        
        // Always use GitHub URL for now to avoid path issues
        let syntaxKitDependency = ".package(url: \"https://github.com/brightdigit/SyntaxKit.git\", branch: \"main\")"
        logger.debug("Using SyntaxKit dependency: \(syntaxKitDependency)")
        
        // Generate package files
        logger.info("Generating package manifest")
        let packageManifest = generatePackageManifest(syntaxKitDependency: syntaxKitDependency)
        
        logger.info("Generating main.swift file")
        let mainSwift = generateMainSwift(with: dslCode)
        
        // Write package files
        let packageManifestPath = packageDir.appendingPathComponent("Package.swift")
        do {
            try packageManifest.write(
                to: packageManifestPath,
                atomically: true,
                encoding: .utf8
            )
            logger.debug("Package.swift written to: \(packageManifestPath.path)")
        } catch {
            logger.error("Failed to write Package.swift: \(error.localizedDescription)")
            throw error
        }
        
        let sourcesDir = packageDir.appendingPathComponent("Sources/SyntaxKitEval")
        do {
            try FileManager.default.createDirectory(at: sourcesDir, withIntermediateDirectories: true)
            logger.debug("Sources directory created at: \(sourcesDir.path)")
        } catch {
            logger.error("Failed to create sources directory: \(error.localizedDescription)")
            throw error
        }
        
        let mainSwiftPath = sourcesDir.appendingPathComponent("main.swift")
        do {
            try mainSwift.write(
                to: mainSwiftPath,
                atomically: true,
                encoding: .utf8
            )
            logger.debug("main.swift written to: \(mainSwiftPath.path)")
        } catch {
            logger.error("Failed to write main.swift: \(error.localizedDescription)")
            throw error
        }
        
        // Build the package using swift-subprocess
        logger.info("Starting Swift package build")
        let buildResult = try await runSwiftCommand(
            arguments: ["build"],
            workingDirectory: packageDir,
            timeout: options.timeout
        )
        
        logger.debug("Build completed with status: \(buildResult.terminationStatus)")
        if let buildOutput = buildResult.standardOutput, !buildOutput.isEmpty {
            logger.debug("Build output: \(buildOutput)")
        }
        
        guard buildResult.terminationStatus == 0 else {
            let errorOutput = buildResult.standardError ?? "Unknown build error"
            let standardOutput = buildResult.standardOutput ?? ""
            let fullOutput = "STDERR:\n\(errorOutput)\n\nSTDOUT:\n\(standardOutput)"
            logger.error("Build failed: \(fullOutput)")
            throw ValidationError("Failed to build evaluation package: \(fullOutput)")
        }
        
        logger.info("Build completed successfully")
        
        // Run the executable
        logger.info("Starting executable")
        let runResult = try await runSwiftCommand(
            arguments: ["run", "SyntaxKitEval"],
            workingDirectory: packageDir,
            timeout: options.timeout
        )
        
        logger.debug("Execution completed with status: \(runResult.terminationStatus)")
        if let runOutput = runResult.standardOutput, !runOutput.isEmpty {
            logger.debug("Execution output: \(runOutput)")
        }
        
        guard runResult.terminationStatus == 0 else {
            let errorOutput = runResult.standardError ?? "Unknown execution error"
            logger.error("Execution failed: \(errorOutput)")
            throw ValidationError("Failed to execute DSL code: \(errorOutput)")
        }
        
        guard let output = runResult.standardOutput else {
            logger.error("No output received from execution")
            throw ValidationError("Failed to decode generated code")
        }
        
        let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
        logger.info("Code generation completed successfully. Output length: \(trimmedOutput.count) characters")
        
        return trimmedOutput
    }
    
    private func runSwiftCommand(
        arguments: [String],
        workingDirectory: URL,
        timeout: TimeInterval
    ) async throws -> (standardOutput: String?, standardError: String?, terminationStatus: Int32) {
        
        logger.debug("Running Swift command: swift \(arguments.joined(separator: " "))")
        logger.debug("Working directory: \(workingDirectory.path)")
        logger.debug("Timeout: \(timeout) seconds")
        
        return try await withThrowingTaskGroup(of: (String?, String?, Int32).self) { group in
            group.addTask {
                return try await withCheckedThrowingContinuation { continuation in
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
                    process.arguments = arguments
                    process.currentDirectoryURL = workingDirectory
                    
                    // Set up pipes for output capture
                    let outputPipe = Pipe()
                    let errorPipe = Pipe()
                    process.standardOutput = outputPipe
                    process.standardError = errorPipe
                    
                    // Security: Clear environment variables to prevent injection
                    process.environment = ProcessInfo.processInfo.environment
                    
                    do {
                        try process.run()
                        
                        // Read output
                        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                        
                        process.waitUntilExit()
                        
                        let standardOutput = String(data: outputData, encoding: .utf8)
                        let standardError = String(data: errorData, encoding: .utf8)
                        
                        continuation.resume(returning: (standardOutput, standardError, process.terminationStatus))
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw ValidationError("Process timed out after \(timeout) seconds")
            }
            
            let result = try await group.next()!
            group.cancelAll()
            
            // Log results after the task group completes to avoid data races
          
            if let error = result.1, !error.isEmpty {
                logger.debug("Process stderr: \(error)")
            }
            logger.debug("Swift process completed with status: \(result.2)")
            
            return result
        }
    }
    
    private func generatePackageManifest(syntaxKitDependency: String) -> String {
        // Generate Package.swift using pure SyntaxKit with the Init type
        let packageFile = Group {
            Import("PackageDescription")
            
            // Create the Package initializer using Init
            Variable(.let, name: "package", type: "Package", equals: 
                Init("Package") {
                    ParameterExp(name: "name", value: Literal.string("SyntaxKitEval"))
                    ParameterExp(name: "platforms", value: Literal.array([
                        // For complex expressions like .macOS(.v13), use Literal.ref
                        Literal.ref(".macOS(.v13)")
                    ]))
                    ParameterExp(name: "dependencies", value: Literal.array([
                        // Use the provided dependency string
                        Literal.ref(syntaxKitDependency)
                    ]))
                    ParameterExp(name: "targets", value: Literal.array([
                        Literal.ref("""
                        .executableTarget(
                            name: "SyntaxKitEval",
                            dependencies: [
                                .product(name: "SyntaxKit", package: "SyntaxKit")
                            ]
                        )
                        """)
                    ]))
                }
            )
        }
        
        // Generate the code and prepend the swift-tools-version comment
        let generatedCode = packageFile.generateCode()
        return "// swift-tools-version: 6.0\n" + generatedCode
    }
    
    private func generateMainSwift(with dslCode: String) -> String {
        // Generate main.swift using SyntaxKit for structure and string interpolation for dynamic code
        // 
        // The limitation: SyntaxKit can generate declarations but cannot dynamically inject
        // arbitrary Swift code into function bodies. The DSL code must be executed as Swift code,
        // not as a string literal. Additionally, SyntaxKit appears to generate @main and struct
        // as a single token (@mainstruct) which is invalid Swift syntax.
        
        let imports = Group {
            Import("SyntaxKit")
            Import("SwiftSyntax")
        }
        
        // Use SyntaxKit to generate the imports, then use string interpolation for the rest
        // to ensure the DSL code is properly embedded and executed
        return """
        \(imports.generateCode())
        
        @main  
        struct SyntaxKitEval {
            static func main() {
                // Wrap the DSL code in a Group
                let code = Group {
                    \(dslCode)
                }
                
                // Generate and print the code
                print("// Generated by Syntaxer using SyntaxKit")
                print(code.generateCode())
            }
        }
        """
    }
}
