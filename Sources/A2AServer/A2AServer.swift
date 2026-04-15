// A2AServer.swift
// A2AServer
//
// Agent2Agent Protocol - Server runtime.
//
// This target is a placeholder in the 1.1.0-lift release. The actual
// Hummingbird-based server is built out in a follow-up PR. The module
// currently only re-exports A2ACore and exposes a version constant so
// consumers can feature-detect.

import Foundation
@_exported import A2ACore

/// A2A Server library version information.
public enum A2AServerVersion {
    /// The library version.
    public static let version = "1.1.0"

    /// The A2A protocol version supported.
    public static let protocolVersion = "1.0"
}
