import ArgumentParser
import Foundation
import SyntaxKit
import SwiftSyntax

@main
struct Syntaxer: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "syntaxer",
        abstract: "Generate Swift code from SyntaxKit DSL - CLI and web-based code generator",
        version: "1.0.0"
    )
    
    @Argument(help: "Path to the Swift file containing DSL code")
    var inputFile: String
    
    @Option(name: .shortAndLong, help: "Output file path (defaults to stdout)")
    var output: String?
    
    func run() async throws {
        let fileURL = URL(fileURLWithPath: inputFile)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw ValidationError("Input file does not exist: \(inputFile)")
        }
        
        let dslCode = try String(contentsOf: fileURL, encoding: .utf8)
        
        // Create a more sophisticated approach using the SyntaxKit library directly
        // We'll need to dynamically evaluate the DSL code
        let generatedCode = try await generateCode(from: dslCode)
        
        // Output the generated code
        if let outputPath = output {
            try generatedCode.write(toFile: outputPath, atomically: true, encoding: .utf8)
            print("Generated Swift code written to: \(outputPath)")
        } else {
            print(generatedCode)
        }
    }
    
    private func generateCode(from dslCode: String) async throws -> String {
        // Create a subprocess to execute the DSL code
        let tempDir = FileManager.default.temporaryDirectory
        let packageDir = tempDir.appendingPathComponent("syntaxkit_eval_\(UUID().uuidString)")
        
        try FileManager.default.createDirectory(at: packageDir, withIntermediateDirectories: true)
        
        // Generate Package.swift using SyntaxKit
        let packageManifest = generatePackageManifest()
        
        // Generate main.swift using SyntaxKit
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
        
        // Build and run the package
        let buildProcess = Process()
        buildProcess.currentDirectoryURL = packageDir
        buildProcess.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        buildProcess.arguments = ["build"]
        
        try buildProcess.run()
        buildProcess.waitUntilExit()
        
        guard buildProcess.terminationStatus == 0 else {
            throw ValidationError("Failed to build evaluation package")
        }
        
        // Run the executable
        let runProcess = Process()
        runProcess.currentDirectoryURL = packageDir
        runProcess.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        runProcess.arguments = ["run", "SyntaxKitEval"]
        
        let pipe = Pipe()
        runProcess.standardOutput = pipe
        runProcess.standardError = pipe
        
        try runProcess.run()
        runProcess.waitUntilExit()
        
        // Clean up
        try? FileManager.default.removeItem(at: packageDir)
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            throw ValidationError("Failed to generate code")
        }
        
        guard runProcess.terminationStatus == 0 else {
            throw ValidationError("Failed to execute DSL code: \(output)")
        }
        
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func generatePackageManifest() -> String {
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
                        // For method calls with parameters, use Literal.ref
                        Literal.ref(".package(url: \"https://github.com/brightdigit/SyntaxKit.git\", from: \"0.0.1\")")
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
        return "// swift-tools-version: 6.2\n" + generatedCode
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

extension Syntaxer {
    struct ValidationError: Error, CustomStringConvertible {
        let description: String
        
        init(_ description: String) {
            self.description = description
        }
    }
}
