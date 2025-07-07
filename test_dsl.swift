import SyntaxKit

let code = Function("hello", returns: "String") { 
    Return { 
        Literal.string("Hello, World\!") 
    } 
}

print(code.generateCode())
