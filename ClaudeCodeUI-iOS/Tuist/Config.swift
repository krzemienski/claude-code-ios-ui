import ProjectDescription

let config = Config(
    compatibleXcodeVersions: [.all],
    cloud: nil,
    swiftVersion: "5.9",
    plugins: [],
    generationOptions: .options(
        resolveDependenciesWithSystemScm: false,
        disablePackageVersionLocking: false
    )
)