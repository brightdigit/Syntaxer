import SyntaxKit

// Example: Generate a complete API client file
let apiClientFile = Group {
    // Imports
    Import("Foundation")
    Import("Combine")
    
    // Error enum
    Enum("APIError")
        .inherits("Error") {
            Case("invalidURL")
            Case("noData")
            Case("decodingError").associatedValue("Error")
            Case("networkError").associatedValue("Error")
            Case("httpError").associatedValue("statusCode", "Int")
        }
    
    // Response protocol
    Protocol("APIResponse")
        .inherits("Codable") {
            Variable(.var, name: "status", type: "String")
            Variable(.var, name: "data", type: "Data?")
        }
    
    // Main API client
    Class("APIClient")
        .attribute("final") {
            // Properties
            Variable(.private, .let, name: "session", type: "URLSession")
                .defaultValue(".shared")
            Variable(.private, .let, name: "baseURL", type: "URL")
            Variable(.private, .let, name: "decoder", type: "JSONDecoder")
                .defaultValue("JSONDecoder()")
            
            // Initializer
            Function("init", parameters: [("baseURL", "URL")]) {
                Assignment("self.baseURL", Literal("baseURL"))
            }
            
            // Generic request method
            Function("request", genericParams: ["T: Codable"], parameters: [
                ("endpoint", "String"),
                ("method", "String", ".init(\"GET\")"),
                ("body", "Data?", "nil")
            ], returns: "AnyPublisher<T, APIError>") {
                // Implementation would go here
                Return(Literal("Just(T()).setFailureType(to: APIError.self).eraseToAnyPublisher()"))
            }
        }
}

// Example: Generate a SwiftUI view model with Combine
let viewModelFile = Group {
    Import("SwiftUI")
    Import("Combine")
    Import("Observation")
    
    // View state enum
    Enum("ViewState") {
        Case("idle")
        Case("loading")
        Case("loaded").associatedValue("data", "[Item]")
        Case("error").associatedValue("Error")
    }
    
    // Item model
    Struct("Item")
        .inherits("Identifiable", "Codable") {
            Variable(.let, name: "id", type: "UUID")
            Variable(.var, name: "title", type: "String")
            Variable(.var, name: "description", type: "String")
            Variable(.var, name: "isCompleted", type: "Bool")
                .defaultValue("false")
        }
    
    // View Model
    Class("ItemListViewModel")
        .attribute("Observable")
        .attribute("MainActor") {
            // Properties
            Variable(.private(set), .var, name: "state", type: "ViewState")
                .defaultValue(".idle")
            Variable(.private, .var, name: "cancellables", type: "Set<AnyCancellable>")
                .defaultValue(".init()")
            Variable(.private, .let, name: "apiClient", type: "APIClient")
            
            // Initializer
            Function("init", parameters: [("apiClient", "APIClient")]) {
                Assignment("self.apiClient", Literal("apiClient"))
            }
            
            // Methods
            Function("loadItems") {
                Assignment("state", Literal(".loading"))
                // API call implementation
            }
            
            Function("toggleItem", parameters: [("item", "Item")]) {
                // Toggle implementation
            }
            
            Function("deleteItem", parameters: [("item", "Item")]) {
                // Delete implementation
            }
        }
}

// Example: Generate a Core Data model
let coreDataModelFile = Group {
    Import("Foundation")
    Import("CoreData")
    
    // Core Data managed object
    Class("TodoItem")
        .attribute("objc(TodoItem)")
        .access(.public)
        .inherits("NSManagedObject") {
            // Nothing in body - properties are in extension
        }
    
    // Extension with Core Data properties
    Extension("TodoItem") {
        Variable(.var, name: "id", type: "UUID?")
            .attribute("NSManaged")
            .access(.public)
        Variable(.var, name: "title", type: "String?")
            .attribute("NSManaged")
            .access(.public)
        Variable(.var, name: "createdAt", type: "Date?")
            .attribute("NSManaged")
            .access(.public)
        Variable(.var, name: "isCompleted", type: "Bool")
            .attribute("NSManaged")
            .access(.public)
    }
    
    // Convenience extension
    Extension("TodoItem") {
        Function("fetchRequest", isStatic: true, returns: "NSFetchRequest<TodoItem>") {
            Return(Literal("NSFetchRequest<TodoItem>(entityName: \"TodoItem\")"))
        }
    }
}

// Example: Generate a test file
let testFile = Group {
    Import("XCTest")
    Import("Combine")
    Attribute("testable").argument("MyApp")
    
    Class("APIClientTests")
        .inherits("XCTestCase") {
            Variable(.private, .var, name: "sut", type: "APIClient!")
            Variable(.private, .var, name: "cancellables", type: "Set<AnyCancellable>!")
            
            Function("setUp", isOverride: true) {
                Literal("super.setUp()")
                Assignment("sut", Literal("APIClient(baseURL: URL(string: \"https://api.example.com\")!)"))
                Assignment("cancellables", Literal("Set<AnyCancellable>()"))
            }
            
            Function("tearDown", isOverride: true) {
                Assignment("sut", Literal("nil"))
                Assignment("cancellables", Literal("nil"))
                Literal("super.tearDown()")
            }
            
            Function("testExample") {
                // Test implementation
                Literal("XCTAssertNotNil(sut)")
            }
        }
}

// Print all generated files
print("=== API Client File ===")
print(apiClientFile.generateCode())
print("\n=== View Model File ===")
print(viewModelFile.generateCode())
print("\n=== Core Data Model File ===")
print(coreDataModelFile.generateCode())
print("\n=== Test File ===")
print(testFile.generateCode())