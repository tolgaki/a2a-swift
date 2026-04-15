# a2a-swift

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-macOS%2014%20%7C%20iOS%2017%20%7C%20tvOS%2017%20%7C%20watchOS%2010%20%7C%20visionOS%201-blue.svg)](https://swift.org)

Swift client library for the **[Agent2Agent (A2A) Protocol v1.0](https://a2a-protocol.org/latest/)**.

## What this package ships

| Product | Purpose | Transitive deps |
| --- | --- | --- |
| `A2ACore` | Wire types, models, errors, SSE parser. Used by both client and server. | **none** |
| `A2AClient` | HTTP+JSON and JSON-RPC 2.0 client transports. | **none** (beyond A2ACore) |

**Zero third-party dependencies.** An iOS or macOS app importing `A2AClient` pulls nothing beyond the Swift standard library and Foundation.

> **Need a server?** Use [`a2a-swift-server`](https://github.com/tolgaki/a2a-swift-server), which depends on this package and adds `A2AServer` built on Hummingbird. The two are intentionally split so client-only consumers never pull the server's transitive dependency graph (~20 packages).

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/tolgaki/a2a-swift.git", from: "1.2.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "A2AClient", package: "a2a-swift"),
        ]
    )
]
```

## Quickstart

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

## Spec compliance

All 11 core A2A v1.0 operations over both transport bindings:

| Operation | REST | JSON-RPC method |
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

## Examples

Client-side examples in `Examples/`:

| Target | What it demonstrates |
| --- | --- |
| `SimpleClient` | Minimal client that sends one message |
| `HelloAgent` | Bare-minimum quickstart |
| `AgentInspector` | Discovery + every `AgentCard` field |
| `MultimodalMessenger` | Multi-part messages (text / file / URL / data) |
| `StreamingNarrator` | All four `StreamingEvent` cases + chunked artifact assembly |
| `TaskLifecycleDemo` | Submit, poll, list, inspect, cancel |
| `PushNotificationDemo` | Webhook CRUD (client side) |
| `AuthShowcase` | Every built-in auth provider (offline-safe) |

Run any example with `swift run <TargetName>`.

## Relationship to `a2a-client-swift`

`a2a-swift` is the successor to [`a2a-client-swift`](https://github.com/tolgaki/a2a-client-swift). The entire 1.0.19 client codebase was lifted verbatim; no API changed.

`a2a-client-swift 1.0.20` ships as a re-export shim that transitively depends on this package, so existing `.package(url: "…a2a-client-swift…")` declarations keep working.

## Relationship to `a2a-swift-server`

`a2a-swift-server` depends on this package and provides `A2AServer` — a Hummingbird-based server runtime. The two are separate packages so client-only consumers don't pay the cost of the server's transitive dependency graph. If you need both, add both packages.

## License

Apache License 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
