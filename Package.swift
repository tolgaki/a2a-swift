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
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.5.0"),
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
            dependencies: [
                "A2ACore",
                .product(name: "Hummingbird", package: "hummingbird"),
            ],
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
        .testTarget(
            name: "A2AInteropTests",
            dependencies: ["A2ACore", "A2AClient", "A2AServer"],
            path: "Tests/A2AInteropTests"
        ),

        // MARK: - Example executables

        // New server examples
        .executableTarget(
            name: "EchoAgent",
            dependencies: ["A2AServer"],
            path: "Examples/EchoAgent"
        ),
        .executableTarget(
            name: "CustomHandler",
            dependencies: ["A2AServer"],
            path: "Examples/CustomHandler"
        ),
        .executableTarget(
            name: "StreamingAgent",
            dependencies: ["A2AServer"],
            path: "Examples/StreamingAgent"
        ),
        .executableTarget(
            name: "PushNotificationsAgent",
            dependencies: ["A2AServer", "A2AClient"],
            path: "Examples/PushNotificationsAgent"
        ),
        .executableTarget(
            name: "MultiAgent",
            dependencies: ["A2AServer", "A2AClient"],
            path: "Examples/MultiAgent"
        ),
        .executableTarget(
            name: "SimpleClient",
            dependencies: ["A2AClient"],
            path: "Examples/SimpleClient"
        ),

        // Lifted client examples
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
