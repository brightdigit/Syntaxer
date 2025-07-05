// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Syntaxer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "syntaxer",
            targets: ["Syntaxer"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/brightdigit/SyntaxKit.git", from: "0.0.1"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "Syntaxer",
            dependencies: [
                .product(name: "SyntaxKit", package: "SyntaxKit"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
    ]
)
