// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HabitCalKit",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "HabitCalKit", targets: ["HabitCalKit"])
    ],
    targets: [
        .target(name: "HabitCalKit"),
        .testTarget(name: "HabitCalKitTests", dependencies: ["HabitCalKit"], resources: [.copy("Fixtures")]),
    ]
)
