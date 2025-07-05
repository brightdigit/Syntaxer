// Check if this is actually returning a StructDeclSyntax
let code: StructDeclSyntax = Struct("Person") {
    Variable(.var, name: "firstName", type: "String")
    Variable(.var, name: "lastName", type: "String")
    Variable(.var, name: "age", type: "Int")
}