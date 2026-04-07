// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CanIOpen",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "CanIOpen",
            path: "Sources"
        )
    ]
)
