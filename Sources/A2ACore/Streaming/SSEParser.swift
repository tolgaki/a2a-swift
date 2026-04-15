// SSEParser.swift
// A2ACore
//
// Server-Sent Events (SSE) parser shared between client and server.

import Foundation

/// Parser for Server-Sent Events (SSE) format.
///
/// This parser is designed to be used within a single async context.
/// Each streaming connection should create its own parser instance.
///
/// Handles both standard SSE (blank-line delimited) and servers like the
/// Graph RP that send consecutive `data:` lines without blank separators.
public final class SSEParser {
    private var currentEvent: String?
    private var currentData: [String] = []
    private var currentId: String?

    public struct SSEEvent: Sendable {
        public let event: String?
        public let data: String
        public let id: String?

        public init(event: String?, data: String, id: String?) {
            self.event = event
            self.data = data
            self.id = id
        }
    }

    public init() {}

    /// Parses a single line of SSE input.
    ///
    /// - Parameter line: The line to parse.
    /// - Returns: An SSEEvent if the line completes an event, nil otherwise.
    /// - Note: This method is not thread-safe. Use one parser per stream.
    public func parse(line: String) -> SSEEvent? {
        // Empty line signals end of event (standard SSE)
        if line.isEmpty {
            guard !currentData.isEmpty else { return nil }
            return emitEvent()
        }

        // Parse field — per the SSE spec, only strip a single leading space after the colon
        if line.hasPrefix("data:") {
            let value = Self.stripSingleLeadingSpace(String(line.dropFirst(5)))
            // If we already have buffered data, emit it first — the server
            // sent consecutive data: lines without blank-line separators.
            if !currentData.isEmpty {
                let event = emitEvent()
                currentData.append(value)
                return event
            }
            currentData.append(value)
        } else if line.hasPrefix("event:") {
            currentEvent = Self.stripSingleLeadingSpace(String(line.dropFirst(6)))
        } else if line.hasPrefix("id:") {
            currentId = Self.stripSingleLeadingSpace(String(line.dropFirst(3)))
        }
        // Ignore retry: and comments (lines starting with :)

        return nil
    }

    /// Emits the currently buffered event and resets state.
    private func emitEvent() -> SSEEvent {
        let event = SSEEvent(
            event: currentEvent,
            data: currentData.joined(separator: "\n"),
            id: currentId
        )
        currentEvent = nil
        currentData = []
        currentId = nil
        return event
    }

    /// Strips a single leading U+0020 SPACE character per the SSE spec.
    private static func stripSingleLeadingSpace(_ value: String) -> String {
        if value.hasPrefix(" ") {
            return String(value.dropFirst())
        }
        return value
    }

    /// Resets the parser state.
    public func reset() {
        currentEvent = nil
        currentData = []
        currentId = nil
    }
}

/// Alias for SSE event.
public typealias SSEEvent = SSEParser.SSEEvent
