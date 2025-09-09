import ProjectDescription

let project = Project(
    name: "ClaudeCodeUI",
    settings: .settings(
        base: [
            "ENABLE_TESTABILITY": "YES",
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
            "GCC_PREPROCESSOR_DEFINITIONS": "DEBUG=1",
            "SWIFT_OPTIMIZATION_LEVEL": "-Onone"
        ],
        configurations: [
            .debug(name: "Debug", xcconfig: nil),
            .release(name: "Release", xcconfig: nil)
        ]
    ),
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
                "Resources/**/*.{storyboard,xib,xcassets,json,png,jpg,jpeg,gif,pdf,ttf,otf,strings,stringsdict}",
                "Core/Data/*.xcdatamodeld"
            ],
            dependencies: [
                .external(name: "Starscream")
            ],
            settings: .settings(
                base: [
                    "ENABLE_TESTABILITY": "YES"
                ]
            )
        ),
        .target(
            name: "ClaudeCodeUITests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.claudecode.ui.tests",
            deploymentTargets: .iOS("17.0"),
            sources: ["ClaudeCodeUITests/**"],
            resources: [
                "Tests/Fixtures/**/*.json"
            ],
            dependencies: [
                .target(name: "ClaudeCodeUI"),
                .external(name: "Starscream")
            ],
            settings: .settings(
                base: [
                    "ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES": "YES"
                ]
            )
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
            ],
            settings: .settings(
                base: [
                    "ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES": "YES"
                ]
            )
        ),
        .target(
            name: "ClaudeCodeUIIntegrationTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.claudecode.ui.integrationtests",
            deploymentTargets: .iOS("17.0"),
            sources: ["ClaudeCodeUIIntegrationTests/**"],
            resources: [
                "Tests/Fixtures/**/*.json"
            ],
            dependencies: [
                .target(name: "ClaudeCodeUI"),
                .external(name: "Starscream")
            ],
            settings: .settings(
                base: [
                    "ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES": "YES"
                ]
            )
        )
    ],
    schemes: [
        .scheme(
            name: "ClaudeCodeUI-Tests",
            shared: true,
            buildAction: .buildAction(
                targets: ["ClaudeCodeUI", "ClaudeCodeUITests", "ClaudeCodeUIIntegrationTests"]
            ),
            testAction: .targets(
                ["ClaudeCodeUITests", "ClaudeCodeUIIntegrationTests"],
                options: .options(
                    coverage: true
                )
            ),
            runAction: .runAction(
                executable: "ClaudeCodeUI"
            )
        )
    ]
)