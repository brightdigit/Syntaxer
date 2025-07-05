// Define a User model
Struct("User") {
    Variable(.let, name: "id", type: "UUID")
    Variable(.var, name: "username", type: "String")
    Variable(.var, name: "email", type: "String")
    Variable(.var, name: "isActive", type: "Bool")
}

// Define a Post model
Struct("Post") {
    Variable(.let, name: "id", type: "UUID")
    Variable(.let, name: "authorId", type: "UUID")
    Variable(.var, name: "title", type: "String")
    Variable(.var, name: "content", type: "String")
    Variable(.var, name: "publishedAt", type: "Date?")
}