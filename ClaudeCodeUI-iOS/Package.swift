// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ClaudeCodeUI",
    platforms: [
        .iOS(.v16)  // iOS 16 is supported by Swift 5.7
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
            path: ".",
            exclude: [
                "Info.plist",
                "ClaudeCodeUI.xcodeproj",
                "Documentation",
                "Assets.xcassets",
                "Base.lproj",
                "Preview Content",
                "Dockerfile",
                "build-linux.sh",
                "compile-check.sh",
                "Sources"  // Exclude the duplicate Sources folder
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