import ArgumentParser
import Foundation
import SyntaxKit
import SwiftSyntax
import SyntaxerCore

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
        
        // Use the shared CodeGenerationService
        let codeGenerationService = CodeGenerationService()
        let generatedCode = try await codeGenerationService.generateCode(from: dslCode)
        
        // Output the generated code
        if let outputPath = output {
            try generatedCode.write(toFile: outputPath, atomically: true, encoding: .utf8)
            print("Generated Swift code written to: \(outputPath)")
        } else {
            print(generatedCode)
        }
    }
    
}

