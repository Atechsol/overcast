// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Climeout",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Climeout",
            path: "Sources/Climeout"
        )
    ]
)
