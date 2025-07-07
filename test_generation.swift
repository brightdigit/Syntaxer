import Foundation
import SyntaxerCore

// Test the code generation service directly
let service = CodeGenerationService()
let dslCode = """
Function("hello") { 
    Literal.string("Hello, World!") 
}
"""

let options = CodeGenerationService.GenerationOptions(timeout: 30.0)

Task {
    do {
        let result = try await service.generateCode(from: dslCode, options: options)
        print("✅ Generated code:")
        print(result)
    } catch {
        print("❌ Error: \(error)")
    }
    exit(0)
}

// Keep the run loop alive
RunLoop.main.run()