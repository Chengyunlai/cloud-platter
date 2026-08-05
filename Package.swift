// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CloudPlatter",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "CloudPlatterCore", targets: ["CloudPlatterCore"]),
        .executable(name: "CloudPlatter", targets: ["CloudPlatterApp"]),
    ],
    targets: [
        .target(name: "CloudPlatterCore"),
        .executableTarget(
            name: "CloudPlatterApp",
            dependencies: ["CloudPlatterCore"]
        ),
        .testTarget(
            name: "CloudPlatterCoreTests",
            dependencies: ["CloudPlatterCore", "CloudPlatterApp"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
