# a2a-swift — Design Notes

This document records the architectural decisions made while designing `a2a-swift` and notes deferred items for future releases.

## Goals

1. Ship a **single Swift package** that supports both client and server roles for the A2A Protocol v1.0, fully spec-compliant.
2. Preserve the existing `a2a-client-swift 1.0.19` client verbatim — no rewrite, no API break.
3. Give server consumers a lean dependency graph (Hummingbird + NIO only); keep client-only consumers (iOS apps) free of server-side transitive pulls.

## Target layout

| Target | Depends on | Role |
| --- | --- | --- |
| `A2ACore` | Foundation only | Wire types, models, errors, SSE parser |
| `A2AClient` | `A2ACore` | `URLSession`-backed REST + JSON-RPC client |
| `A2AServer` | `A2ACore` (+ Hummingbird, pending) | Server runtime |

`A2ACore` re-exports all public wire types. Both `A2AClient` and `A2AServer` use `@_exported import A2ACore` so consumers only need a single `import A2AClient` or `import A2AServer`.

## Deployment target

`.macOS(.v14)` for the whole package. Drops `a2a-client-swift`'s `.macOS(.v12)` to enable Hummingbird 2.x on the server side. iOS/tvOS/watchOS/visionOS targets match (v17/v17/v10/v1).

## Lift choices

### Why lift `a2a-client-swift` instead of depending on it

The server needs the wire types (`AgentCard`, `Task`, `Message`, `Part`, errors) to emit them over the wire. Depending on `a2a-client-swift` would drag `URLSession`-based transports and the client's `AuthenticationProvider` into the server's transitive graph — a layering inversion. Extracting the shared types to `A2ACore` is the clean split; the 1.0.19 code is preserved verbatim.

### Why SSEParser moved to A2ACore

Both client and server need to parse Server-Sent Events. The parser has no A2A-specific dependencies — it's generic SSE — so it belongs in Core. Moved to `A2ACore/Streaming/SSEParser.swift` as a `public` type. The previous file-private location inside `HTTPTransport.swift` is replaced by a comment pointer.

### Why JSONKeyCasing moved to A2ACore

Same reasoning: encoding/decoding format is a shared concern between client and server. Moved out of `A2AClientConfiguration.swift` into `A2ACore/Transport/Endpoint.swift`.

## Planned server architecture (not in 1.1.0-alpha)

### Public surface

```swift
public actor A2AServer<Handler: A2AHandler> {
    public init(handler: Handler)
    public func bind(_ address: String) -> Self
    public func rpcPath(_ path: String) -> Self
    public func restPrefix(_ prefix: String?) -> Self
    public func taskStore(_ store: any TaskStore) -> Self
    public func webhookStore(_ store: any WebhookStore) -> Self
    public func authenticator(_ auth: any Authenticator) -> Self
    public func run() async throws
}

public protocol A2AHandler: Sendable {
    func handleMessage(_ message: Message, auth: AuthContext?) async throws -> SendMessageResponse
    func agentCard(baseURL: String) -> AgentCard
    // Everything else defaulted
}
```

### HTTP framework

Hummingbird 2.x, chosen for Sendable-strict support, lean weight, and native `AsyncSequence` response bodies for SSE. The server declares `.macOS(.v14)` platform minimum.

### Auth

Two protocols, zero third-party dependencies:

- `Authenticator` protocol with `authenticate(headers:) -> AuthContext?`
- `NoOpBearerAuthenticator` — accepts any `Bearer <token>`, hands raw token to handler. No verification.
- `APIKeyAuthenticator` — allowlist or closure-based `X-API-Key` validation.

No JWT library is bundled. A2A deliberately doesn't mandate JWT — Microsoft Entra, Auth0, Keycloak, AWS Cognito all use different token shapes. Handlers bring their own validation in ~20 lines of user code.

### Storage

`TaskStore` and `WebhookStore` protocols with `actor`-based in-memory defaults. Plug-in backends (Postgres, Redis) are user-supplied.

### Streaming

`AsyncThrowingStream<StreamResponse, Error>` from the handler, framed as `data: {json}\n\n` by the framework. Keepalive every 15s. Honors client disconnect.

## Deferred for future releases

- **Full server implementation** — handler protocol, router, dispatchers, SSE encoder, webhook delivery, auth enforcement, task registry
- **Examples** — 6 new server examples + 9 client examples lifted from `a2a-client-swift`
- **TCK conformance CI job** — the language-agnostic A2A TCK is Python-based. Will be wired into CI once the server is functional.
- **gRPC transport** — spec allows it; not planned initially.
- **Durable webhook queue** — in-memory retries only; consumers with at-least-once requirements bring their own queue.

## Testing strategy

- `A2ACoreTests` — model round-trip tests, SSE parser tests, security scheme tests (lifted from a2a-client-swift)
- `A2AClientTests` — transport tests with `URLProtocol` mocks (lifted)
- `A2AInteropTests` (planned) — boots the server in-process on an ephemeral port and runs the client against it. All 11 operations × both bindings = 22 baseline tests.

## Versioning

`a2a-swift 1.1.0-alpha` → `1.1.0` once the server is functional. Starts at `1.1.0` because `1.0.x` is reserved for the lifted client code (which already reached `1.0.19` in the old repo).

`a2a-client-swift 1.0.20` will ship as a re-export shim depending on `a2a-swift 1.1.0`, then the old repo is archived after ~60 days.
