import SyntaxKit
import SwiftSyntax

let code = Struct("Person") {
    Variable(.var, name: "firstName", type: "String")
    Variable(.var, name: "lastName", type: "String") 
    Variable(.var, name: "age", type: "Int")
}

// Try to access the SwiftSyntax representation
print(type(of: code))