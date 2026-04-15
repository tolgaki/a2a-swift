# a2a-swift — RETIRED

> ⚠️ **This repository is retired and read-only.** It was a short-lived rename experiment that has been unwound.

## Use these instead

| What you want | Where it lives |
| --- | --- |
| **Swift A2A client** (iOS, macOS, watchOS, tvOS, visionOS) | [`tolgaki/a2a-client-swift`](https://github.com/tolgaki/a2a-client-swift) |
| **Swift A2A server** (Hummingbird-based) | [`tolgaki/a2a-swift-server`](https://github.com/tolgaki/a2a-swift-server) |

## What happened

For a brief moment (April 14–15, 2026) this repo was published as `a2a-swift 1.1.0` (with both client and server) and then `1.2.0` (client only, with the server moved to `a2a-swift-server`). Both were rename experiments based on the Rust `a2a-rs` workspace structure.

The experiment didn't work out:

1. **`a2a-swift 1.1.0`** — putting client and server in one Swift package leaked Hummingbird's full transitive dependency graph (~25 packages) into every iOS app that imported `A2AClient`, because SPM resolves package-level dependencies regardless of which targets actually use them.
2. **`a2a-swift 1.2.0`** — splitting the server into a separate repo fixed the dependency leak, but left a rename overhead with no benefit. The original `a2a-client-swift` was already a fine self-contained client — there was no reason to lift it out.

Rather than live with three repos plus a shim, we reverted to the simpler shape:

- **`a2a-client-swift`** is the canonical Swift A2A client. (It always was.)
- **`a2a-swift-server`** depends on it for wire types and adds the server runtime.

Both `a2a-swift 1.1.0` and `a2a-swift 1.2.0` tags will remain in this repository indefinitely so any historical `Package.resolved` files keep resolving — but no new releases will be cut here. **All future development happens in the two repositories above.**

## License

Apache License 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
