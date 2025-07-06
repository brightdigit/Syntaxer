import SyntaxKit

// Example 1: Creating import statements
let foundationImport = Import("Foundation")
let swiftUIImport = Import("SwiftUI")

// Example 2: Creating a complete Swift source file with imports
let completeFile = Group {
    // Add imports at the top
    Import("Foundation")
    Import("SwiftUI")
    
    // Add a struct with @main attribute
    Struct("MyApp")
        .attribute("main")
        .inherits("App") {
            // Body property for SwiftUI App
            Variable(.var, name: "body", type: "some Scene") {
                // WindowGroup content
                Return(Literal("WindowGroup { ContentView() }"))
            }
        }
    
    // Add another struct
    Struct("ContentView")
        .inherits("View") {
            Variable(.var, name: "body", type: "some View") {
                Return(Literal("Text(\"Hello, World!\")"))
            }
        }
}

// Example 3: Creating a more complex file with multiple imports and types
let dataModelFile = Group {
    // Multiple imports
    Import("Foundation")
    Import("CoreData")
    Import("Combine")
    
    // Type alias
    TypeAlias("UserID", to: "UUID")
    
    // Protocol definition
    Protocol("Identifiable") {
        Variable(.var, name: "id", type: "UserID")
    }
    
    // Struct with attributes and conformance
    Struct("User")
        .attribute("objc")
        .inherits("NSManagedObject", "Identifiable") {
            Variable(.var, name: "id", type: "UserID")
                .attribute("NSManaged")
            Variable(.var, name: "name", type: "String")
                .attribute("NSManaged")
            Variable(.var, name: "email", type: "String")
                .attribute("NSManaged")
            Variable(.var, name: "createdAt", type: "Date")
                .attribute("NSManaged")
            
            Function("displayName") {
                Return(Literal("\"\\(name) <\\(email)>\""))
            }
        }
    
    // Extension
    Extension("User") {
        Function("updateEmail", parameters: [
            ("newEmail", "String")
        ]) {
            Assignment("email", Literal("newEmail"))
        }
    }
}

// Example 4: Creating a file with various attributes
let attributeExamples = Group {
    Import("SwiftUI")
    Import("Observation")
    
    // Observable class
    Class("ViewModel")
        .attribute("Observable")
        .attribute("MainActor") {
            Variable(.var, name: "count", type: "Int")
                .defaultValue("0")
            Variable(.var, name: "items", type: "[String]")
                .defaultValue("[]")
                .attribute("Published")
            
            Function("increment") {
                Assignment("count", Literal("count + 1"))
            }
        }
    
    // Property wrapper example
    Struct("Clamped")
        .attribute("propertyWrapper") {
            Variable(.private, .var, name: "value", type: "Int")
            Variable(.let, name: "range", type: "ClosedRange<Int>")
            
            Variable(.var, name: "wrappedValue", type: "Int") {
                Getter {
                    Return(Literal("value"))
                }
                Setter {
                    Assignment("value", Literal("min(max(range.lowerBound, newValue), range.upperBound)"))
                }
            }
            
            Function("init", parameters: [
                ("wrappedValue", "Int"),
                ("range", "ClosedRange<Int>")
            ]) {
                Assignment("self.value", Literal("min(max(range.lowerBound, wrappedValue), range.upperBound)"))
                Assignment("self.range", Literal("range"))
            }
        }
}

// Example 5: Generating the code
print("=== Complete SwiftUI App File ===")
print(completeFile.generateCode())
print("\n=== Data Model File ===")
print(dataModelFile.generateCode())
print("\n=== Attribute Examples ===")
print(attributeExamples.generateCode())

// Example 6: Building a file programmatically
func createSwiftFile(
    imports: [String],
    types: [CodeBlock]
) -> Group {
    Group {
        // Add all imports
        for moduleName in imports {
            Import(moduleName)
        }
        
        // Add all types
        for type in types {
            type
        }
    }
}

// Usage
let myFile = createSwiftFile(
    imports: ["Foundation", "Combine"],
    types: [
        Struct("Publisher") {
            Variable(.let, name: "subject", type: "PassthroughSubject<String, Never>")
        },
        Class("Subscriber") {
            Variable(.var, name: "cancellables", type: "Set<AnyCancellable>")
        }
    ]
)

print("\n=== Programmatically Created File ===")
print(myFile.generateCode())