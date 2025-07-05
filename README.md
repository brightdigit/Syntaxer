# Syntaxer

A command line tool and web-based code generator that uses the SyntaxKit library to convert Swift DSL code to generated Swift code.

## Installation

Build the tool using Swift Package Manager:

```bash
swift build -c release
```

The executable will be located at `.build/release/syntaxer`

## Usage

```bash
syntaxer <input-file> [--output <output-file>]
```

- `<input-file>`: Path to the Swift file containing SyntaxKit DSL code
- `--output`, `-o`: Optional output file path (defaults to stdout)

## Example

Create a DSL file (e.g., `example.swift`):

```swift
let code = Struct("Person") {
    Variable("name").type("String")
    Variable("age").type("Int")
    
    Function("greet") {
        Return(Literal("Hello, my name is \\(name)"))
    }
}
```

Convert it to Swift code:

```bash
syntaxer example.swift -o output.swift
```

## Note

The current implementation creates a temporary Swift package to evaluate the DSL code, which ensures proper compilation and execution with all dependencies. This approach may take a few seconds to complete due to the package resolution and build process.

## Requirements

- Swift 6.2 or later
- macOS 13.0 or later
- SyntaxKit library (automatically fetched as a dependency)