// SendMessageTypes.swift
// A2ACore
//
// Wire types for SendMessage. Shared between client (which encodes the
// request and decodes the response) and server (vice versa).

import Foundation

/// Request for sending a message.
public struct SendMessageRequest: Codable, Sendable {
    /// Optional tenant identifier.
    public let tenant: String?

    /// The message to send.
    public let message: Message

    /// Optional configuration for the send operation.
    public let configuration: MessageSendConfiguration?

    /// Optional metadata for the request.
    public let metadata: [String: AnyCodable]?

    public init(
        tenant: String? = nil,
        message: Message,
        configuration: MessageSendConfiguration? = nil,
        metadata: [String: AnyCodable]? = nil
    ) {
        self.tenant = tenant
        self.message = message
        self.configuration = configuration
        self.metadata = metadata
    }
}

/// Response from sending a message.
///
/// The agent can respond with either a Task (for long-running operations)
/// or a Message (for immediate responses).
public enum SendMessageResponse: Codable, Sendable {
    /// A task was created for the request.
    case task(A2ATask)

    /// An immediate message response.
    case message(Message)

    private enum CodingKeys: String, CodingKey {
        case type
        case task
        case message
    }

    private enum DiscriminatorKeys: String, CodingKey {
        case status  // Present in A2ATask but not Message
        case role    // Present in Message but not A2ATask
    }

    public init(from decoder: Decoder) throws {
        // Use discriminating fields to determine the type.
        // A2ATask has a required "status" field; Message has a required "role" field.
        let discriminator = try decoder.container(keyedBy: DiscriminatorKeys.self)

        if discriminator.contains(.status) {
            let task = try A2ATask(from: decoder)
            self = .task(task)
            return
        }

        if discriminator.contains(.role) {
            let message = try Message(from: decoder)
            self = .message(message)
            return
        }

        // Fallback: try wrapped format with explicit type field
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.task) {
            let task = try container.decode(A2ATask.self, forKey: .task)
            self = .task(task)
        } else if container.contains(.message) {
            let message = try container.decode(Message.self, forKey: .message)
            self = .message(message)
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unable to decode SendMessageResponse: missing 'status' (Task) or 'role' (Message) field"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .task(let task):
            try task.encode(to: encoder)
        case .message(let message):
            try message.encode(to: encoder)
        }
    }
}

// MARK: - Convenience Extensions

extension SendMessageResponse {
    /// Returns the task if this response contains one.
    public var task: A2ATask? {
        if case .task(let task) = self {
            return task
        }
        return nil
    }

    /// Returns the message if this response contains one.
    public var message: Message? {
        if case .message(let message) = self {
            return message
        }
        return nil
    }

    /// Returns whether this response is a task.
    public var isTask: Bool {
        if case .task = self {
            return true
        }
        return false
    }

    /// Returns whether this response is a message.
    public var isMessage: Bool {
        if case .message = self {
            return true
        }
        return false
    }
}
