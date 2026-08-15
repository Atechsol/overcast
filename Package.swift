// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Overcast",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Overcast",
            path: "Sources/Overcast"
        )
    ]
)
