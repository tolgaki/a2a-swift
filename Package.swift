// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "a2a-swift",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "A2ACore", targets: ["A2ACore"]),
        .library(name: "A2AClient", targets: ["A2AClient"]),
        .library(name: "A2AServer", targets: ["A2AServer"]),
    ],
    targets: [
        .target(
            name: "A2ACore",
            path: "Sources/A2ACore"
        ),
        .target(
            name: "A2AClient",
            dependencies: ["A2ACore"],
            path: "Sources/A2AClient"
        ),
        .target(
            name: "A2AServer",
            dependencies: ["A2ACore"],
            path: "Sources/A2AServer"
        ),
        .testTarget(
            name: "A2ACoreTests",
            dependencies: ["A2ACore"],
            path: "Tests/A2ACoreTests"
        ),
        .testTarget(
            name: "A2AClientTests",
            dependencies: ["A2ACore", "A2AClient"],
            path: "Tests/A2AClientTests"
        ),
    ]
)
