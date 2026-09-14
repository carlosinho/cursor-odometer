// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CursorOdometer",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "OdometerCore"),
        .executableTarget(name: "CursorOdometer", dependencies: ["OdometerCore"]),
        .testTarget(name: "OdometerCoreTests", dependencies: ["OdometerCore"]),
    ]
)
