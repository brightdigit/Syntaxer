import SyntaxKit

// SyntaxKit Expression Examples
// ============================

// MARK: - 1. Function Calls

// Note: FunctionCallExp is internal, so we use method calls on property access
// or through the Literal type for basic expressions

// Example of method calls through property access
let propertyWithCall = Group {
    Variable(.let, name: "result", type: "String")
        .defaultValue("user.name.uppercased()")
    
    Variable(.let, name: "count", type: "Int")
        .defaultValue("items.count")
}

// MARK: - 2. Array Literals

// Using Literal.array for array expressions
let arrayExamples = Group {
    // Simple array literal
    Variable(.let, name: "numbers", type: "[Int]")
        .defaultValue("[1, 2, 3, 4, 5]")
    
    // Array with string literals
    Variable(.let, name: "names", type: "[String]")
        .defaultValue("[\"Alice\", \"Bob\", \"Charlie\"]")
    
    // Empty array
    Variable(.let, name: "empty", type: "[String]")
        .defaultValue("[]")
    
    // Using Literal enum for array construction
    Function("makeArray") {
        Return(Literal.array([
            .integer(1),
            .integer(2),
            .integer(3)
        ]))
    }
    
    // Nested arrays
    Function("makeNestedArray") {
        Return(Literal.array([
            .array([.integer(1), .integer(2)]),
            .array([.integer(3), .integer(4)]),
            .array([.integer(5), .integer(6)])
        ]))
    }
}

// MARK: - 3. Dictionary Literals

// Using Literal.dictionary for dictionary expressions
let dictionaryExamples = Group {
    // Simple dictionary literal
    Variable(.let, name: "ages", type: "[String: Int]")
        .defaultValue("[\"Alice\": 30, \"Bob\": 25]")
    
    // Empty dictionary
    Variable(.let, name: "emptyDict", type: "[String: Any]")
        .defaultValue("[:]")
    
    // Using Literal enum for dictionary construction
    Function("makeDict") {
        Return(Literal.dictionary([
            (.string("name"), .string("John")),
            (.string("age"), .integer(30)),
            (.string("active"), .boolean(true))
        ]))
    }
    
    // Nested dictionary
    Function("makeNestedDict") {
        Return(Literal.dictionary([
            (.string("user"), .dictionary([
                (.string("id"), .integer(123)),
                (.string("name"), .string("Alice"))
            ])),
            (.string("settings"), .dictionary([
                (.string("darkMode"), .boolean(true)),
                (.string("notifications"), .boolean(false))
            ]))
        ]))
    }
}

// MARK: - 4. Property Access

// Property access is achieved through dot notation in string literals
let propertyAccessExamples = Group {
    // Simple property access
    Variable(.let, name: "userName", type: "String")
        .defaultValue("user.name")
    
    // Chained property access
    Variable(.let, name: "city", type: "String")
        .defaultValue("user.address.city")
    
    // Property access with optional chaining
    Variable(.let, name: "optionalName", type: "String?")
        .defaultValue("user?.profile?.displayName")
    
    // Property access in functions
    Function("getUserEmail", parameters: [("user", "User")]) {
        Return(Literal("user.email"))
    }
}

// MARK: - 5. Complex Expressions

// Combining different expression types
let complexExamples = Group {
    Import("Foundation")
    
    Struct("DataProcessor") {
        // Array property
        Variable(.private, .var, name: "items", type: "[String]")
            .defaultValue("[]")
        
        // Dictionary property
        Variable(.private, .var, name: "cache", type: "[String: Any]")
            .defaultValue("[:]")
        
        // Function with array manipulation
        Function("addItem", parameters: [("item", "String")]) {
            Literal("items.append(item)")
        }
        
        // Function with dictionary access
        Function("getCached", parameters: [("key", "String")], returns: "Any?") {
            Return(Literal("cache[key]"))
        }
        
        // Function returning array literal
        Function("getDefaultItems", returns: "[String]") {
            Return(Literal.array([
                .string("default1"),
                .string("default2"),
                .string("default3")
            ]))
        }
        
        // Function with complex expression
        Function("processData") {
            // Multiple statements
            Assignment("cache", Literal("[:]"))
            Literal("items = items.map { $0.uppercased() }")
            Literal("print(\"Processed \\(items.count) items\")")
        }
    }
}

// MARK: - 6. Literal Types Reference

let literalTypesDemo = Group {
    Function("demonstrateLiterals") {
        // String literal
        Variable(.let, name: "str")
            .defaultValue(Literal.string("Hello, World!"))
        
        // Integer literal
        Variable(.let, name: "num")
            .defaultValue(Literal.integer(42))
        
        // Float literal
        Variable(.let, name: "pi")
            .defaultValue(Literal.float(3.14159))
        
        // Boolean literal
        Variable(.let, name: "flag")
            .defaultValue(Literal.boolean(true))
        
        // Nil literal
        Variable(.let, name: "optional", type: "String?")
            .defaultValue(Literal.nil)
        
        // Reference (variable/identifier)
        Variable(.let, name: "copy")
            .defaultValue(Literal.ref("originalValue"))
        
        // Tuple literal
        Variable(.let, name: "tuple")
            .defaultValue(Literal.tuple([
                .string("John"),
                .integer(30),
                .boolean(true)
            ]))
    }
}

// MARK: - 7. Practical Example: API Response Handler

let apiResponseHandler = Group {
    Import("Foundation")
    
    Struct("APIResponse") {
        Variable(.let, name: "data", type: "[String: Any]")
        Variable(.let, name: "status", type: "Int")
        Variable(.let, name: "headers", type: "[String: String]")
        
        // Computed property using property access
        Variable(.var, name: "isSuccess", type: "Bool") {
            Return(Literal("status >= 200 && status < 300"))
        }
        
        // Method returning dictionary literal
        Function("errorResponse", isStatic: true, returns: "APIResponse") {
            Return(Literal("""
                APIResponse(
                    data: ["error": "Not Found"],
                    status: 404,
                    headers: [:]
                )
                """))
        }
        
        // Method using array operations
        Function("extractErrors", returns: "[String]") {
            Return(Literal("""
                (data["errors"] as? [String]) ?? []
                """))
        }
    }
}

// Print examples
print("=== Property With Call ===")
print(propertyWithCall.generateCode())
print("\n=== Array Examples ===")
print(arrayExamples.generateCode())
print("\n=== Dictionary Examples ===")
print(dictionaryExamples.generateCode())
print("\n=== Property Access Examples ===")
print(propertyAccessExamples.generateCode())
print("\n=== Complex Examples ===")
print(complexExamples.generateCode())
print("\n=== Literal Types Demo ===")
print(literalTypesDemo.generateCode())
print("\n=== API Response Handler ===")
print(apiResponseHandler.generateCode())