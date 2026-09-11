// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SpeakRate",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "SpeakRateCore",
            path: "Sources/SpeakRateCore"
        ),
        .executableTarget(
            name: "SpeakRate",
            dependencies: ["SpeakRateCore"],
            path: "Sources/SpeakRate"
        ),
        .testTarget(
            name: "SpeakRateCoreTests",
            dependencies: ["SpeakRateCore"],
            path: "Tests/SpeakRateCoreTests"
        )
    ]
)
