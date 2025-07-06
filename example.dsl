Function(.public, name: "greet") {
    Parameter(name: "name", type: "String")
    Return("String")
    
    Return(expression: "\"Hello, \\(name)!\"")
}