// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ClaudeCodeUI",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ClaudeCodeUI",
            targets: ["ClaudeCodeUI"]),
    ],
    dependencies: [
        // Dependencies will be added as needed
    ],
    targets: [
        .target(
            name: "ClaudeCodeUI",
            dependencies: [],
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "ClaudeCodeUITests",
            dependencies: ["ClaudeCodeUI"],
            path: "Tests"
        ),
    ]
)