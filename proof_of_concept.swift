// This example shows that the CLI tool works
// It processes the DSL code and outputs the result

let code = Struct("Person") {
    Variable(.var, name: "firstName", type: "String")
    Variable(.var, name: "lastName", type: "String")
    Variable(.var, name: "age", type: "Int")
}

// The tool will process this and output the result