// Test DSL code to benchmark performance
import SyntaxKit

Function(.public, name: "generateUser", returnType: "User") {
    Parameter(name: "id", type: "Int")
    Parameter(name: "name", type: "String")
    Parameter(name: "email", type: "String")
    
    Return(Init("User") {
        ParameterExp(name: "id", value: "id")
        ParameterExp(name: "name", value: "name")
        ParameterExp(name: "email", value: "email")
        ParameterExp(name: "createdAt", value: "Date()")
    })
}

Struct("User") {
    Property(.let, name: "id", type: "Int")
    Property(.let, name: "name", type: "String")
    Property(.let, name: "email", type: "String")
    Property(.let, name: "createdAt", type: "Date")
    
    Function(.public, name: "displayName", returnType: "String") {
        Return("\"\\(name) (\\(email))\"")
    }
}