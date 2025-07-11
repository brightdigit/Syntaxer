import ArgumentParser
import Foundation
import SyntaxerCore

struct PrepareCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "prepare",
        abstract: "Pre-build template and cache dependencies for faster code generation"
    )
    
    @Flag(name: .long, help: "Clear existing cache and templates before preparing")
    var clean = false
    
    @Flag(name: .long, help: "Show detailed progress information")
    var verbose = false
    
    func run() async throws {
        if verbose {
            print("🚀 Preparing Syntaxer for optimal performance...")
        }
        
        let templateManager = TemplateManager()
        let optimizedGenerator = OptimizedCodeGenerator()
        let cacheManager = CacheManager()
        
        // Clear if requested
        if clean {
            if verbose {
                print("🧹 Clearing existing cache and templates...")
            }
            await templateManager.clearTemplate()
            await cacheManager.clearCache()
        }
        
        // Prepare template
        if verbose {
            print("🔨 Building template package...")
        }
        let templateStart = Date()
        try await templateManager.ensureTemplate()
        let templateTime = Date().timeIntervalSince(templateStart)
        if verbose {
            print("✅ Template ready in \(String(format: "%.2f", templateTime))s")
        }
        
        // Cache SyntaxKit
        if verbose {
            print("📦 Caching SyntaxKit dependency...")
        }
        let cacheStart = Date()
        try await optimizedGenerator.ensureSyntaxKitCache()
        let cacheTime = Date().timeIntervalSince(cacheStart)
        if verbose {
            print("✅ SyntaxKit cached in \(String(format: "%.2f", cacheTime))s")
        }
        
        // Test generation
        if verbose {
            print("🧪 Testing optimized generation...")
        }
        let testDSL = """
        Function(.public, name: "test") {
            Return("\"Hello from optimized Syntaxer!\"")
        }
        """
        
        let service = CodeGenerationService()
        let testStart = Date()
        let result = try await service.generateCode(
            from: testDSL,
            options: .init(useCache: true, useTemplate: true)
        )
        let testTime = Date().timeIntervalSince(testStart)
        
        if verbose {
            print("✅ Test generation completed in \(String(format: "%.2f", testTime))s")
            print("\nGenerated code:")
            print(result)
        }
        
        print("\n✨ Syntaxer is now optimized and ready for fast code generation!")
        print("   Template prepared: ✓")
        print("   Dependencies cached: ✓")
        print("   Expected speedup: 90%+ for subsequent generations")
    }
}