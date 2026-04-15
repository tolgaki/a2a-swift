# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-04-15

### Breaking (client consumers are unaffected)

- **`A2AServer` target and product removed.** The server runtime has been moved to a separate repository, [`a2a-swift-server`](https://github.com/tolgaki/a2a-swift-server), so that client-only consumers no longer pull Hummingbird + SwiftNIO + ~20 transitive packages through their SPM graph.
- **`A2AInteropTests` target removed.** Lives in `a2a-swift-server` now — it needs both client and server.
- **Server-side example targets removed**: `EchoAgent`, `CustomHandler`, `StreamingAgent`, `PushNotificationsAgent`, `MultiAgent`. All lifted unchanged into `a2a-swift-server`.
- **Package-level dependency on `hummingbird` removed.** `a2a-swift 1.2.0` has **zero third-party dependencies**.

### Migration for server consumers

If you were importing `A2AServer` from `a2a-swift 1.1.0`:

```swift
// Before
.package(url: "https://github.com/tolgaki/a2a-swift.git", from: "1.1.0"),
.target(dependencies: [
    .product(name: "A2AServer", package: "a2a-swift")
])

// After
.package(url: "https://github.com/tolgaki/a2a-swift-server.git", from: "1.1.0"),
.target(dependencies: [
    .product(name: "A2AServer", package: "a2a-swift-server")
])
```

All API surfaces (`A2AHandler`, `A2AServer` actor, `TaskStore`, `Authenticator`, etc.) are unchanged — only the package name changes. Your `import A2AServer` statements keep working.

### Rationale

An iOS app importing `A2AClient` from `a2a-swift 1.1.0` was resolving 25 packages in total (Hummingbird plus its full NIO/log/metrics/crypto/certificates transitive graph), even though `A2AClient` itself has zero dependencies beyond `A2ACore`. SPM resolves package-level dependencies transitively regardless of which targets are actually reachable from the consumer's graph. The cleanest fix is to remove Hummingbird from `a2a-swift`'s manifest entirely.

After the split, an iOS app importing `A2AClient` resolves **one** package: `a2a-swift`. Zero transitive packages.

## [1.1.0] - 2026-04-14

First stable release of `a2a-swift` as a unified package providing both client and server support for the A2A Protocol v1.0.

### Added

- **`A2AServer` target** — Hummingbird 2.x-based server runtime with:
  - `A2AHandler` protocol — required methods: `handleMessage`, `agentCard(baseURL:)`. Everything else (streaming, task cancel, extended card) is defaulted.
  - `A2ADispatcher` — transport-agnostic dispatch layer used by both REST and JSON-RPC routers.
  - REST dispatcher — registers all 11 operations at spec §5.3 paths plus `/.well-known/agent-card.json` and `/.well-known/agent.json` discovery routes. AIP-193 error response shaping (`{"error":{"code":…,"status":"…","message":"…"}}`).
  - JSON-RPC dispatcher — single `POST /` route that multiplexes all 11 operations by method name. JSON-RPC 2.0 error envelopes.
  - SSE encoder for streaming operations (`/message:stream`, `/tasks/{id}:subscribe`) supporting both bare-event (REST) and JSON-RPC-wrapped (RPC) framing.
  - `TaskStore` and `WebhookStore` protocols with in-memory `actor`-based defaults (`InMemoryTaskStore`, `InMemoryWebhookStore`).
  - `TaskRegistry` for tracking in-flight Swift Tasks so `cancelTask` actually interrupts background work.
  - `WebhookDispatcher` with exponential backoff retries (500ms → 30s, 3 attempts) for push notification delivery.
  - `Authenticator` protocol + two built-ins: `NoOpBearerAuthenticator` (default, hands the raw bearer to the handler) and `APIKeyAuthenticator`. Zero third-party auth dependencies — consumers bring their own JWT/introspection validation for AAD/Entra, Auth0, Keycloak, etc.
  - `A2AServer` public actor with a builder API (`.bind`, `.rpcPath`, `.restPrefix`, `.taskStore`, `.webhookStore`, `.authenticator`, `.requireAuthentication`).

- **`A2AInteropTests` target** — boots an `A2AServer` in-process on an ephemeral port and runs the full `A2AClient` against it. 17 tests covering every core operation over both REST and JSON-RPC, plus discovery, task CRUD, push notification CRUD, and streaming lifecycle.

- **6 new server examples**: `EchoAgent`, `CustomHandler`, `StreamingAgent`, `PushNotificationsAgent`, `MultiAgent`, `SimpleClient`.

- **9 lifted client examples**: `HelloAgent`, `AgentInspector`, `StreamingNarrator`, `MultimodalMessenger`, `TaskLifecycleDemo`, `AuthShowcase`, `PushNotificationDemo`, `TravelPlannerAgent`, `SmartTravelPlanner` — all lifted verbatim from `a2a-client-swift 1.0.19` with updated `import A2AClient`.

### Fixed

- **Push notification CRUD over JSON-RPC** — `A2AClient.getPushNotificationConfig` and `listPushNotificationConfigs` now pass `taskId` / `id` as query items so the JSON-RPC transport can re-materialize them in `params`. Previously the methods sent empty `params: {}` over JSON-RPC, causing the server to reject the request.
- **REST push notification CRUD body format** — server now accepts both the flat `PushNotificationConfig` and the wrapped `CreatePushNotificationConfigParams` shapes in the POST body.

### Migrated from a2a-client-swift 1.0.19

- All models (`AgentCard`, `Task`, `Message`, `Part`, `TaskState`, `Artifact`, `SecurityScheme`, `PushNotificationConfig`, `Errors`) moved to `A2ACore/Models/`.
- `SendMessageRequest` and `SendMessageResponse` moved to `A2ACore/Models/SendMessageTypes.swift` so the server can emit them as wire types.
- `StreamingEvents` moved to `A2ACore/Streaming/`.
- `SSEParser` extracted from `HTTPTransport` and moved to `A2ACore/Streaming/SSEParser.swift` as a public type, reused by both client and server.
- `A2AEndpoint`, `HTTPMethod`, `A2AServiceParameters`, `JSONKeyCasing` moved to `A2ACore/Transport/Endpoint.swift` — the server uses the same endpoint definitions the client does.
- `AnyCodable` moved to `A2ACore/Extensions/`.
- Client transports (`HTTPTransport`, `JSONRPCTransport`), client (`A2AClient`, `A2AClientConfiguration`), and authentication providers remain in `A2AClient/` and now import `A2ACore`.
- 119 tests lifted from `a2a-client-swift` pass unchanged.

### Test results

- `A2ACoreTests`: 49 model/streaming tests pass.
- `A2AClientTests`: 10 auth tests, 11 transport tests pass.
- `A2AInteropTests`: 17 full-stack tests pass.
- **Total: 136/136 tests pass** on macOS 14 with Swift 6.0.

### Deferred

- TCK conformance CI job — the A2A TCK is Python-based; wiring it up is a follow-up.
- gRPC transport binding.
- Durable webhook queue (in-memory retry only in 1.1.0).
- Persistent store backends (Postgres, Redis) — available via the `TaskStore` / `WebhookStore` protocols for consumers.

## [1.1.0-alpha] - 2026-04-14

Initial lift from `a2a-client-swift 1.0.19`. See git history for details.

[1.2.0]: https://github.com/tolgaki/a2a-swift/releases/tag/1.2.0
[1.1.0]: https://github.com/tolgaki/a2a-swift/releases/tag/1.1.0
[1.1.0-alpha]: https://github.com/tolgaki/a2a-swift/releases/tag/1.1.0-alpha
