# a2a-swift

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-macOS%2014%20%7C%20iOS%2017%20%7C%20tvOS%2017%20%7C%20watchOS%2010%20%7C%20visionOS%201-blue.svg)](https://swift.org)

Swift implementation of the **[Agent2Agent (A2A) Protocol v1.0](https://a2a-protocol.org/latest/)** — client and server in a single package.

## Products

This package ships three library products:

| Product | Purpose | Transitive deps |
| --- | --- | --- |
| `A2ACore` | Wire types, models, errors, SSE parser. Shared by client and server. | none |
| `A2AClient` | HTTP+JSON and JSON-RPC 2.0 client transports. | `A2ACore` |
| `A2AServer` | Hummingbird-based server runtime. | `A2ACore` + Hummingbird |

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
            // Client-only (iOS apps):
            .product(name: "A2AClient", package: "a2a-swift"),
            // Server:
            // .product(name: "A2AServer", package: "a2a-swift"),
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

## Quickstart — server

```swift
import A2ACore
import A2AServer

struct EchoHandler: A2AHandler {
    func handleMessage(_ message: Message, auth: AuthContext?) async throws -> SendMessageResponse {
        .message(Message(
            messageId: UUID().uuidString,
            role: .agent,
            parts: [.text("echo: \(message.textContent)")]
        ))
    }

    func agentCard(baseURL: String) -> AgentCard {
        AgentCard(
            name: "Echo",
            description: "Echoes the user's message back.",
            supportedInterfaces: [
                AgentInterface(url: baseURL, protocolBinding: AgentInterface.httpJSON, protocolVersion: "1.0"),
            ],
            version: "1.0"
        )
    }
}

try await A2AServer(handler: EchoHandler())
    .bind("127.0.0.1:8080")
    .run()
```

That's it. The server automatically:

- Exposes **both** `GET /.well-known/agent-card.json` (spec §8.2) and `GET /.well-known/agent.json` (legacy fallback).
- Registers all 11 REST routes per spec §5.3.
- Registers a single `POST /` JSON-RPC 2.0 dispatcher.
- Handles `getTask`, `listTasks`, `cancelTask`, and push notification CRUD against an in-memory `TaskStore` / `WebhookStore` — your handler only has to implement `handleMessage`.
- Fans out task events to registered webhooks with exponential backoff retries.

### Advanced server usage

```swift
let server = A2AServer(
    handler: myHandler,
    taskStore: RedisTaskStore(...),           // plug in your own backend
    webhookStore: PostgresWebhookStore(...),
    authenticator: EntraAuthenticator(tenantId: "...")
)
.bind("0.0.0.0:8443")
.requireAuthentication(true)
```

## Spec compliance

All 11 core A2A v1.0 operations are implemented on both the client and server, over both transport bindings:

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

### Compliance test coverage

`A2AInteropTests` boots an `A2AServer` in-process on an ephemeral port and runs the `A2AClient` against it over **both** REST and JSON-RPC. Every core operation has two tests (one per binding). 136 total tests in the suite, all green.

## Authentication

The server ships with two authenticators:

- `NoOpBearerAuthenticator` — accepts any non-empty `Bearer <token>` and passes the raw token to the handler. **Default.** Suitable for Microsoft Entra, Auth0, Keycloak, AWS Cognito, or any other identity provider — the handler brings its own validation.
- `APIKeyAuthenticator` — validates an `X-API-Key` header against an allowlist or a closure.

No JWT library is bundled. A2A deliberately doesn't mandate a token shape; the server lets consumers plug in whatever validation suits their identity provider.

## Examples

15 executable targets in `Examples/`:

### Server examples

| Target | What it demonstrates |
| --- | --- |
| `EchoAgent` | Minimal 5-line server handler |
| `StreamingAgent` | Full SSE lifecycle with chunked artifacts |
| `CustomHandler` | Multi-skill routing + artifact responses |
| `PushNotificationsAgent` | Webhook CRUD + dispatch |
| `MultiAgent` | Coordinator + worker in one process (uses both `A2AClient` and `A2AServer`) |

### Client examples

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
| `TravelPlannerAgent` | Multi-agent orchestration with skill routing |
| `SmartTravelPlanner` | LLM-style intent routing on top of the orchestrator |

Run any example with `swift run <TargetName>`.

## Relationship to `a2a-client-swift`

`a2a-swift` is a strict superset of [`a2a-client-swift 1.0.19`](https://github.com/tolgaki/a2a-client-swift). The entire client codebase was lifted verbatim into `A2ACore` + `A2AClient`. No client APIs changed.

`a2a-client-swift 1.0.20` ships as a thin re-export shim that depends on `a2a-swift`, giving existing consumers a zero-code-change upgrade path. After a short transition period, `a2a-client-swift` will be archived and `a2a-swift` becomes the single source of truth.

## License

Apache License 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
