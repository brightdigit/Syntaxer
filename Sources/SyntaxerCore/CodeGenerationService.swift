import Foundation
import SyntaxKit
import SwiftSyntax

public struct CodeGenerationService {
    
    public struct GenerationOptions {
        public let timeout: TimeInterval
        public let workingDirectory: URL?
        public let syntaxKitPath: String?
        
        public init(timeout: TimeInterval = 30.0, workingDirectory: URL? = nil, syntaxKitPath: String? = nil) {
            self.timeout = timeout
            self.workingDirectory = workingDirectory
            self.syntaxKitPath = syntaxKitPath
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
        // Input validation
        guard !dslCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError("DSL code cannot be empty")
        }
        
        // Basic security validation - prevent obvious injection attempts
        let dangerousPatterns = ["import Process", "import Darwin", "system(", "exec(", "fork(", "kill("]
        for pattern in dangerousPatterns {
            if dslCode.contains(pattern) {
                throw ValidationError("DSL code contains potentially dangerous patterns")
            }
        }
        
        // Create isolated temporary directory
        let tempDir = FileManager.default.temporaryDirectory
        let packageDir = tempDir.appendingPathComponent("syntaxkit_eval_\(UUID().uuidString)")
        
        defer {
            // Always clean up
            try? FileManager.default.removeItem(at: packageDir)
        }
        
        try FileManager.default.createDirectory(at: packageDir, withIntermediateDirectories: true)
        
        // Set restrictive permissions on temp directory
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: packageDir.path)
        
        // Always use GitHub URL for now to avoid path issues
        let syntaxKitDependency = ".package(url: \"https://github.com/brightdigit/SyntaxKit.git\", branch: \"syntaxer\")"
        
        // Generate package files
        let packageManifest = generatePackageManifest(syntaxKitDependency: syntaxKitDependency)
        let mainSwift = generateMainSwift(with: dslCode)
        
        // Write package files
        try packageManifest.write(
            to: packageDir.appendingPathComponent("Package.swift"),
            atomically: true,
            encoding: .utf8
        )
        
        let sourcesDir = packageDir.appendingPathComponent("Sources/SyntaxKitEval")
        try FileManager.default.createDirectory(at: sourcesDir, withIntermediateDirectories: true)
        
        try mainSwift.write(
            to: sourcesDir.appendingPathComponent("main.swift"),
            atomically: true,
            encoding: .utf8
        )
        
        // Build the package using swift-subprocess
        let buildResult = try await runSwiftCommand(
            arguments: ["build"],
            workingDirectory: packageDir,
            timeout: options.timeout
        )
        
        guard buildResult.terminationStatus == 0 else {
            let errorOutput = buildResult.standardError ?? "Unknown build error"
            let standardOutput = buildResult.standardOutput ?? ""
            let fullOutput = "STDERR:\n\(errorOutput)\n\nSTDOUT:\n\(standardOutput)"
            throw ValidationError("Failed to build evaluation package: \(fullOutput)")
        }
        
        // Run the executable
        let runResult = try await runSwiftCommand(
            arguments: ["run", "SyntaxKitEval"],
            workingDirectory: packageDir,
            timeout: options.timeout
        )
        
        guard runResult.terminationStatus == 0 else {
            let errorOutput = runResult.standardError ?? "Unknown execution error"
            throw ValidationError("Failed to execute DSL code: \(errorOutput)")
        }
        
        guard let output = runResult.standardOutput else {
            throw ValidationError("Failed to decode generated code")
        }
        
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func runSwiftCommand(
        arguments: [String],
        workingDirectory: URL,
        timeout: TimeInterval
    ) async throws -> (standardOutput: String?, standardError: String?, terminationStatus: Int32) {
        
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