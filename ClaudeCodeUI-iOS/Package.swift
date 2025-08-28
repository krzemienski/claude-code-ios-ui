// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ClaudeCodeUI",
    platforms: [
        .iOS(.v17)  // Match the Xcode project deployment target
    ],
    products: [
        .library(
            name: "ClaudeCodeUI",
            targets: ["ClaudeCodeUI"]),
    ],
    dependencies: [
        // WebSocket library for improved reliability and features
        .package(url: "https://github.com/daltoniam/Starscream.git", exact: "4.0.6")
    ],
    targets: [
        .target(
            name: "ClaudeCodeUI",
            dependencies: [
                .product(name: "Starscream", package: "Starscream")
            ],
            path: ".",
            exclude: [
                "ClaudeCodeUI.xcodeproj",
                "Dockerfile",
                "build-linux.sh", 
                "compile-check.sh",
                "Sources",
                "Tests",
                "ClaudeCodeUIIntegrationTests",
                "ClaudeCodeUIUITests",
                "App",
                "Models", 
                "Resources",
                "Core/Data/ClaudeCodeOffline.xcdatamodeld",
                "Core/Network/REFRACTORING_PROPOSALS.md",
                "UI/README.md"
            ],
            sources: [
                "Core",
                "Features",
                "Design",
                "UI"
            ]
        ),
        .testTarget(
            name: "ClaudeCodeUITests",
            dependencies: ["ClaudeCodeUI"],
            path: "Tests"
        ),
    ]
)