let code = Struct("Person") {
    Variable(.var, name: "firstName", type: "String")
    Variable(.var, name: "lastName", type: "String")
    Variable(.var, name: "age", type: "Int")
    
    Function("fullName") {
        Return(Literal("\\(firstName) \\(lastName)"))
    }
}