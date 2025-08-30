// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import ProjectDescription
    import ProjectDescriptionHelpers

    let packageSettings = PackageSettings(
        productTypes: [:]
    )
#endif

let package = Package(
    name: "ClaudeCodeUI",
    platforms: [.iOS(.v17)],
    dependencies: [
        // WebSocket library for improved reliability and features
        .package(url: "https://github.com/daltoniam/Starscream.git", exact: "4.0.6")
    ]
)