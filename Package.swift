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
    ],
    // No external dependencies. Consumers get A2AClient with zero
    // transitive package graph. For the server runtime, add
    // https://github.com/tolgaki/a2a-swift-server as a separate package.
    dependencies: [],
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

        // MARK: - Example executables (client-only)

        .executableTarget(
            name: "SimpleClient",
            dependencies: ["A2AClient"],
            path: "Examples/SimpleClient"
        ),
        .executableTarget(
            name: "HelloAgent",
            dependencies: ["A2AClient"],
            path: "Examples/HelloAgent"
        ),
        .executableTarget(
            name: "AgentInspector",
            dependencies: ["A2AClient"],
            path: "Examples/AgentInspector"
        ),
        .executableTarget(
            name: "StreamingNarrator",
            dependencies: ["A2AClient"],
            path: "Examples/StreamingNarrator"
        ),
        .executableTarget(
            name: "MultimodalMessenger",
            dependencies: ["A2AClient"],
            path: "Examples/MultimodalMessenger"
        ),
        .executableTarget(
            name: "TaskLifecycleDemo",
            dependencies: ["A2AClient"],
            path: "Examples/TaskLifecycleDemo"
        ),
        .executableTarget(
            name: "AuthShowcase",
            dependencies: ["A2AClient"],
            path: "Examples/AuthShowcase"
        ),
        .executableTarget(
            name: "PushNotificationDemo",
            dependencies: ["A2AClient"],
            path: "Examples/PushNotificationDemo"
        ),
    ]
)
