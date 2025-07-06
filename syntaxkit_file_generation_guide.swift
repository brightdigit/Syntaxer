import SyntaxKit

/*
 SyntaxKit Complete File Generation Guide
 ========================================
 
 This guide demonstrates how to create complete Swift source files using SyntaxKit,
 including imports, attributes, and various Swift constructs.
 */

// MARK: - 1. Creating Import Statements

// Basic import
let basicImport = Import("Foundation")

// Import with access modifier (not commonly used, but supported)
let publicImport = Import("SwiftUI").access(.public)

// Multiple imports in a file
let importsExample = Group {
    Import("Foundation")
    Import("SwiftUI")
    Import("Combine")
    Import("CoreData")
}

// MARK: - 2. Creating Complete Swift Source Files

// The Group type is used to create complete source files
// It acts as a container for multiple code blocks
let completeSourceFile = Group {
    // Imports go first
    Import("Foundation")
    Import("SwiftUI")
    
    // Then your types and code
    Struct("MyModel") {
        Variable(.let, name: "id", type: "UUID")
        Variable(.var, name: "name", type: "String")
    }
    
    Class("MyController") {
        Variable(.private, .var, name: "model", type: "MyModel")
    }
}

// MARK: - 3. Adding Attributes (including @main)

// Struct with @main attribute
let mainAppStruct = Struct("MyApp")
    .attribute("main")
    .inherits("App") {
        Variable(.var, name: "body", type: "some Scene") {
            Return(Literal("WindowGroup { ContentView() }"))
        }
    }

// Various attribute examples
let attributeExamples = Group {
    // Property wrapper
    Struct("Wrapper")
        .attribute("propertyWrapper") {
            Variable(.var, name: "wrappedValue", type: "String")
        }
    
    // Observable
    Class("ViewModel")
        .attribute("Observable")
        .attribute("MainActor") {
            Variable(.var, name: "count", type: "Int")
        }
    
    // Result builder
    Struct("Builder")
        .attribute("resultBuilder") {
            // Implementation
        }
    
    // Available attribute with platform
    Function("newFeature")
        .attribute("available", arguments: ["iOS 17.0", "*"]) {
            // Implementation
        }
}

// MARK: - 4. Complete File Generation Patterns

// Pattern 1: Basic app structure
let swiftUIApp = Group {
    Import("SwiftUI")
    
    Struct("MyApp")
        .attribute("main")
        .inherits("App") {
            Variable(.var, name: "body", type: "some Scene") {
                Return(Literal("WindowGroup { ContentView() }"))
            }
        }
    
    Struct("ContentView")
        .inherits("View") {
            Variable(.var, name: "body", type: "some View") {
                Return(Literal("Text(\"Hello, World!\")"))
            }
        }
}

// Pattern 2: Model file with extensions
let modelFile = Group {
    Import("Foundation")
    
    // Main type
    Struct("User")
        .inherits("Codable", "Identifiable") {
            Variable(.let, name: "id", type: "UUID")
            Variable(.var, name: "name", type: "String")
            Variable(.var, name: "email", type: "String")
        }
    
    // Extension for computed properties
    Extension("User") {
        Variable(.var, name: "displayName", type: "String") {
            Return(Literal("\"\\(name) <\\(email)>\""))
        }
    }
    
    // Extension for conformance
    Extension("User")
        .inherits("CustomStringConvertible") {
            Variable(.var, name: "description", type: "String") {
                Return(Literal("displayName"))
            }
        }
}

// Pattern 3: Complete test file
let testFile = Group {
    Import("XCTest")
    // Special syntax for @testable import
    Attribute("testable").argument("MyModule")
    
    Class("UserTests")
        .inherits("XCTestCase") {
            Function("testUserCreation") {
                Variable(.let, name: "user", type: "User")
                    .defaultValue("User(id: UUID(), name: \"Test\", email: \"test@example.com\")")
                Literal("XCTAssertEqual(user.name, \"Test\")")
            }
        }
}

// MARK: - 5. Advanced Features

// Using attributes on properties
let propertyAttributes = Struct("Model") {
    Variable(.var, name: "published", type: "String")
        .attribute("Published")
    
    Variable(.var, name: "managed", type: "String")
        .attribute("NSManaged")
    
    Variable(.var, name: "wrapped", type: "Int")
        .attribute("Clamped", arguments: ["0...100"])
}

// Creating a package manifest style file
let packageStyle = Group {
    Import("PackageDescription")
    
    Variable(.let, name: "package", type: "Package")
        .defaultValue("""
        Package(
            name: "MyPackage",
            products: [],
            dependencies: [],
            targets: []
        )
        """)
}

// MARK: - Usage

// To generate the actual Swift code:
let generatedCode = completeSourceFile.generateCode()
print(generatedCode)

// MARK: - Notes

/*
 Key Types for File Generation:
 
 1. Import(_:) - Creates import statements
 2. Group { } - Container for multiple code blocks, represents a complete file
 3. .attribute(_:arguments:) - Adds attributes like @main, @Observable, etc.
 4. Struct/Class/Enum/Protocol - Type declarations
 5. Extension - Type extensions
 6. Variable - Properties and variables
 7. Function - Methods and functions
 
 The Group type is essential for creating complete files as it allows
 you to combine multiple declarations into a single source file.
 
 Limitations:
 - SyntaxKit focuses on code structure generation
 - Some complex attribute syntaxes might need string literals
 - The generated code uses SwiftSyntax for formatting
 */

// MARK: - Practical Example: Complete API Service File

let apiServiceFile = Group {
    // File header imports
    Import("Foundation")
    Import("Combine")
    
    // API Error type
    Enum("APIError")
        .inherits("LocalizedError") {
            Case("invalidURL")
            Case("requestFailed").associatedValue("Error")
            Case("invalidResponse")
            Case("decodingFailed").associatedValue("Error")
            
            Variable(.var, name: "errorDescription", type: "String?") {
                Switch("self") {
                    Case("invalidURL") {
                        Return(Literal("\"Invalid URL\""))
                    }
                    Case("requestFailed(let error)") {
                        Return(Literal("\"Request failed: \\(error.localizedDescription)\""))
                    }
                    Case("invalidResponse") {
                        Return(Literal("\"Invalid response from server\""))
                    }
                    Case("decodingFailed(let error)") {
                        Return(Literal("\"Failed to decode response: \\(error.localizedDescription)\""))
                    }
                }
            }
        }
    
    // API Service
    Class("APIService")
        .attribute("final") {
            Variable(.private, .let, name: "baseURL", type: "URL")
            Variable(.private, .let, name: "session", type: "URLSession")
            Variable(.private, .let, name: "decoder", type: "JSONDecoder")
            
            Function("init", parameters: [
                ("baseURL", "URL"),
                ("session", "URLSession", ".shared")
            ]) {
                Assignment("self.baseURL", Literal("baseURL"))
                Assignment("self.session", Literal("session"))
                Assignment("self.decoder", Literal("JSONDecoder()"))
                Assignment("decoder.keyDecodingStrategy", Literal(".convertFromSnakeCase"))
            }
        }
}

print("\n=== Complete API Service File ===")
print(apiServiceFile.generateCode())