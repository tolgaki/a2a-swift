# a2a-swift

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-macOS%2014%20%7C%20iOS%2017%20%7C%20tvOS%2017%20%7C%20watchOS%2010%20%7C%20visionOS%201-blue.svg)](https://swift.org)

Swift implementation of the **[Agent2Agent (A2A) Protocol v1.0](https://a2a-protocol.org/latest/)** — client and server in a single package.

> **Status:** `1.1.0-alpha` — client is production-ready (lifted verbatim from [`a2a-client-swift`](https://github.com/tolgaki/a2a-client-swift) 1.0.19). Server is a placeholder target that will be built out in follow-up releases.

## Products

This package ships three library products:

| Product | Purpose |
| --- | --- |
| `A2ACore` | Wire types, models, errors, SSE parser. Shared by client and server. No networking. |
| `A2AClient` | HTTP+JSON and JSON-RPC 2.0 client transports. Depends on `A2ACore`. |
| `A2AServer` | Server runtime (Hummingbird-based). Depends on `A2ACore`. |

Consumers who only need the client (iOS/macOS apps) import `A2AClient` and never pay the cost of the server runtime.

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/tolgaki/a2a-swift.git", from: "1.1.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "A2AClient", package: "a2a-swift"),
            // or .product(name: "A2AServer", package: "a2a-swift"),
        ]
    )
]
```

## Quickstart — client

```swift
import A2AClient

let client = A2AClient(baseURL: URL(string: "https://agent.example.com")!)
let response = try await client.sendMessage("Hello, agent!")

switch response {
case .message(let message):
    print("Agent said: \(message.textContent)")
case .task(let task):
    print("Task \(task.id) in state \(task.state.rawValue)")
}
```

See [`Examples/`](Examples/) for heavy-documented tours of every major surface.

## Quickstart — server

Coming in a follow-up release. The `A2AServer` target currently only exposes a version constant.

## Relationship to `a2a-client-swift`

`a2a-swift 1.1.0` is a strict superset of [`a2a-client-swift 1.0.19`](https://github.com/tolgaki/a2a-client-swift). The entire client codebase was lifted verbatim into this package's `A2ACore` + `A2AClient` targets. No client APIs changed.

`a2a-client-swift 1.0.20` will ship as a thin re-export shim that depends on `a2a-swift`, giving existing consumers a zero-code-change upgrade path. After a short transition period, `a2a-client-swift` will be archived and `a2a-swift` becomes the single source of truth.

## Spec compliance

All 11 core A2A v1.0 operations are implemented and spec-compliant:

| Operation | REST | JSON-RPC |
| --- | --- | --- |
| SendMessage | `POST /message:send` | `SendMessage` |
| SendStreamingMessage | `POST /message:stream` | `SendStreamingMessage` |
| GetTask | `GET /tasks/{id}` | `GetTask` |
| ListTasks | `GET /tasks` | `ListTasks` |
| CancelTask | `POST /tasks/{id}:cancel` | `CancelTask` |
| SubscribeToTask | `POST /tasks/{id}:subscribe` | `SubscribeToTask` |
| CreateTaskPushNotificationConfig | `POST /tasks/{id}/pushNotificationConfigs` | `CreateTaskPushNotificationConfig` |
| GetTaskPushNotificationConfig | `GET /tasks/{id}/pushNotificationConfigs/{configId}` | `GetTaskPushNotificationConfig` |
| ListTaskPushNotificationConfigs | `GET /tasks/{id}/pushNotificationConfigs` | `ListTaskPushNotificationConfigs` |
| DeleteTaskPushNotificationConfig | `DELETE /tasks/{id}/pushNotificationConfigs/{configId}` | `DeleteTaskPushNotificationConfig` |
| GetExtendedAgentCard | `GET /extendedAgentCard` | `GetExtendedAgentCard` |

Plus `GET /.well-known/agent-card.json` for discovery.

## License

Apache License 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
