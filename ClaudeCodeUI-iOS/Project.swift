import ProjectDescription

let project = Project(
    name: "ClaudeCodeUI",
    targets: [
        .target(
            name: "ClaudeCodeUI",
            destinations: .iOS,
            product: .app,
            bundleId: "com.claudecode.ui",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .file(path: "App/Info.plist"),
            sources: [
                "App/**",
                "Core/**",
                "Features/**",
                "Design/**",
                "Models/**",
                "UIComponents/**",
                "UI/**"
            ],
            resources: [
                "App/Resources/**/*.{storyboard,xib,xcassets,json,png,jpg,jpeg,gif,pdf,ttf,otf,strings,stringsdict}",
                "Resources/**/*.{storyboard,xib,xcassets,json,png,jpg,jpeg,gif,pdf,ttf,otf,strings,stringsdict}"
            ],
            dependencies: [
                .external(name: "Starscream")
            ]
        ),
        .target(
            name: "ClaudeCodeUITests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.claudecode.ui.tests",
            deploymentTargets: .iOS("17.0"),
            sources: ["ClaudeCodeUITests/**"],
            dependencies: [
                .target(name: "ClaudeCodeUI")
            ]
        ),
        .target(
            name: "ClaudeCodeUIUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "com.claudecode.ui.uitests",
            deploymentTargets: .iOS("17.0"),
            sources: ["ClaudeCodeUIUITests/**"],
            dependencies: [
                .target(name: "ClaudeCodeUI")
            ]
        ),
        .target(
            name: "ClaudeCodeUIIntegrationTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.claudecode.ui.integrationtests",
            deploymentTargets: .iOS("17.0"),
            sources: ["ClaudeCodeUIIntegrationTests/**"],
            dependencies: [
                .target(name: "ClaudeCodeUI")
            ]
        )
    ]
)