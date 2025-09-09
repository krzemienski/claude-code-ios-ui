// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftUITests",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [
        // ViewInspector for SwiftUI testing
        .package(url: "https://github.com/nalexn/ViewInspector.git", from: "0.9.11"),
        // SnapshotTesting for visual regression testing
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.15.0"),
        // SwiftUI Introspect for deeper testing
        .package(url: "https://github.com/siteline/SwiftUI-Introspect.git", from: "1.1.0")
    ],
    targets: [
        .testTarget(
            name: "SwiftUITests",
            dependencies: [
                "ViewInspector",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                .product(name: "SwiftUIIntrospect", package: "SwiftUI-Introspect")
            ]
        )
    ]
)