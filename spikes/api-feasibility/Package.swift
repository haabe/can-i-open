// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "api-feasibility",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "api-feasibility",
            path: "Sources"
        )
    ]
)
