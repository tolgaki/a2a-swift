# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0-alpha] - 2026-04-14

### Added

- **New unified package** combining client and server support for A2A Protocol v1.0.
- Three library products: `A2ACore` (wire types), `A2AClient` (HTTP+JSON and JSON-RPC transports), `A2AServer` (runtime — placeholder).
- `A2ACore/Streaming/SSEParser.swift` — SSE parser extracted from `HTTPTransport` and made public. Shared between client and server.
- `A2ACore/Transport/Endpoint.swift` — `A2AEndpoint`, `HTTPMethod`, `A2AServiceParameters`, `JSONKeyCasing` lifted into Core so server code can register routes against the same endpoint definitions the client uses.

### Migrated from a2a-client-swift 1.0.19

- All models (`AgentCard`, `Task`, `Message`, `Part`, `TaskState`, `Artifact`, `SecurityScheme`, `PushNotificationConfig`, `Errors`) moved to `A2ACore/Models/`.
- `StreamingEvents` moved to `A2ACore/Streaming/`.
- `AnyCodable` moved to `A2ACore/Extensions/`.
- Client transports (`HTTPTransport`, `JSONRPCTransport`), client (`A2AClient`, `A2AClientConfiguration`), and authentication providers remain in `A2AClient/` and now import `A2ACore`.
- 119 tests lifted from `a2a-client-swift` pass unchanged.

### Deferred

- `A2AServer` only ships a version constant in 1.1.0-alpha. Full server implementation (handler protocol, router, REST + JSON-RPC dispatchers, SSE encoder, webhook delivery, auth enforcement, task store) is planned for 1.1.0.
- Server examples: 6 new server examples + 9 lifted client examples.
- TCK conformance CI job.

[1.1.0-alpha]: https://github.com/tolgaki/a2a-swift/releases/tag/1.1.0-alpha
