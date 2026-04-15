// Endpoint.swift
// A2ACore
//
// Agent2Agent Protocol - Shared wire types used by both client and server.
// Spec: https://a2a-protocol.org/latest/specification/

import Foundation

/// HTTP methods used by the A2A protocol.
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// Represents an A2A API endpoint.
///
/// Endpoint definitions are shared between the client (which uses them to
/// build outbound requests) and the server (which uses them to register
/// routes). Paths are spec-relative per §5.3 of the A2A v1.0 specification
/// and do NOT include the `/v1/` prefix that some early drafts suggested.
public struct A2AEndpoint: Sendable, Equatable {
    /// The HTTP method to use.
    public let method: HTTPMethod

    /// The path relative to the base URL.
    public let path: String

    /// Whether this endpoint returns a streaming response.
    public let isStreaming: Bool

    /// The JSON-RPC method name for this endpoint (v1.0 PascalCase).
    public let jsonRPCMethod: String?

    /// The JSON-RPC method name for v0.3 (kebab-case).
    public let v03JsonRPCMethod: String?

    public init(method: HTTPMethod, path: String, isStreaming: Bool = false, jsonRPCMethod: String? = nil, v03JsonRPCMethod: String? = nil) {
        self.method = method
        self.path = path
        self.isStreaming = isStreaming
        self.jsonRPCMethod = jsonRPCMethod
        self.v03JsonRPCMethod = v03JsonRPCMethod
    }

    // MARK: - Standard A2A Endpoints (per spec §5.3)
    // Paths are relative to the interface URL from the agent card.
    // The tenant prefix (if any) is prepended by pathWithTenant().

    /// Send a message to the agent.
    /// Spec: POST /message:send
    public static let sendMessage = A2AEndpoint(method: .post, path: "/message:send", jsonRPCMethod: "SendMessage", v03JsonRPCMethod: "message/send")

    /// Send a streaming message to the agent.
    /// Spec: POST /message:stream
    public static let sendStreamingMessage = A2AEndpoint(method: .post, path: "/message:stream", isStreaming: true, jsonRPCMethod: "SendStreamingMessage", v03JsonRPCMethod: "message/stream")

    /// Get a task by ID.
    /// Spec: GET /tasks/{id}
    public static func getTask(id: String) -> A2AEndpoint {
        A2AEndpoint(method: .get, path: "/tasks/\(Self.sanitizePathComponent(id))", jsonRPCMethod: "GetTask", v03JsonRPCMethod: "tasks/get")
    }

    /// List tasks.
    /// Spec: GET /tasks
    public static let listTasks = A2AEndpoint(method: .get, path: "/tasks", jsonRPCMethod: "ListTasks", v03JsonRPCMethod: "tasks/list")

    /// Cancel a task.
    /// Spec: POST /tasks/{id}:cancel
    public static func cancelTask(id: String) -> A2AEndpoint {
        A2AEndpoint(method: .post, path: "/tasks/\(Self.sanitizePathComponent(id)):cancel", jsonRPCMethod: "CancelTask", v03JsonRPCMethod: "tasks/cancel")
    }

    /// Subscribe to task updates.
    /// Spec §5.3: POST /tasks/{id}:subscribe
    public static func subscribeToTask(id: String) -> A2AEndpoint {
        A2AEndpoint(method: .post, path: "/tasks/\(Self.sanitizePathComponent(id)):subscribe", isStreaming: true, jsonRPCMethod: "SubscribeToTask", v03JsonRPCMethod: "tasks/resubscribe")
    }

    /// Create push notification configuration.
    /// Spec: POST /tasks/{taskId}/pushNotificationConfigs
    public static func createPushNotificationConfig(taskId: String) -> A2AEndpoint {
        A2AEndpoint(method: .post, path: "/tasks/\(Self.sanitizePathComponent(taskId))/pushNotificationConfigs", jsonRPCMethod: "CreateTaskPushNotificationConfig", v03JsonRPCMethod: "tasks/pushNotificationConfig/set")
    }

    /// Get push notification configuration.
    /// Spec: GET /tasks/{taskId}/pushNotificationConfigs/{id}
    public static func getPushNotificationConfig(taskId: String, configId: String) -> A2AEndpoint {
        A2AEndpoint(method: .get, path: "/tasks/\(Self.sanitizePathComponent(taskId))/pushNotificationConfigs/\(Self.sanitizePathComponent(configId))", jsonRPCMethod: "GetTaskPushNotificationConfig", v03JsonRPCMethod: "tasks/pushNotificationConfig/get")
    }

    /// List push notification configurations.
    /// Spec: GET /tasks/{taskId}/pushNotificationConfigs
    public static func listPushNotificationConfigs(taskId: String) -> A2AEndpoint {
        A2AEndpoint(method: .get, path: "/tasks/\(Self.sanitizePathComponent(taskId))/pushNotificationConfigs", jsonRPCMethod: "ListTaskPushNotificationConfigs", v03JsonRPCMethod: "tasks/pushNotificationConfig/list")
    }

    /// Delete push notification configuration.
    /// Spec: DELETE /tasks/{taskId}/pushNotificationConfigs/{id}
    public static func deletePushNotificationConfig(taskId: String, configId: String) -> A2AEndpoint {
        A2AEndpoint(method: .delete, path: "/tasks/\(Self.sanitizePathComponent(taskId))/pushNotificationConfigs/\(Self.sanitizePathComponent(configId))", jsonRPCMethod: "DeleteTaskPushNotificationConfig", v03JsonRPCMethod: "tasks/pushNotificationConfig/delete")
    }

    /// Get extended agent card.
    /// Spec §11.3.4: GET /extendedAgentCard
    public static let getExtendedAgentCard = A2AEndpoint(method: .get, path: "/extendedAgentCard", jsonRPCMethod: "GetExtendedAgentCard", v03JsonRPCMethod: "agent/authenticatedExtendedCard")

    /// Returns the path with an optional tenant prefix prepended.
    ///
    /// - Parameter tenant: Optional tenant identifier. If set, the path becomes `/{tenant}{path}`.
    /// - Returns: The path with tenant prefix if applicable.
    public func pathWithTenant(_ tenant: String?) -> String {
        guard let tenant = tenant, !tenant.isEmpty else {
            return path
        }
        let sanitizedTenant = Self.sanitizePathComponent(tenant)
        return "/\(sanitizedTenant)\(path)"
    }

    // MARK: - Path Sanitization

    /// Sanitizes a path component to prevent path traversal attacks.
    /// Percent-encodes special characters and removes path separators.
    public static func sanitizePathComponent(_ component: String) -> String {
        // Remove any path separators and null bytes
        let sanitized = component
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: "\\", with: "")
            .replacingOccurrences(of: "\0", with: "")

        // Percent-encode for URL safety
        return sanitized.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? sanitized
    }

    // MARK: - Legacy Endpoint Aliases (Deprecated)

    /// Legacy endpoint - use createPushNotificationConfig instead.
    @available(*, deprecated, renamed: "createPushNotificationConfig(taskId:)")
    public static func setPushNotificationConfig(taskId: String, configId: String) -> A2AEndpoint {
        A2AEndpoint(method: .put, path: "/tasks/\(sanitizePathComponent(taskId))/pushNotificationConfigs/\(sanitizePathComponent(configId))", jsonRPCMethod: "CreateTaskPushNotificationConfig", v03JsonRPCMethod: "tasks/pushNotificationConfig/set")
    }
}

/// Coding user info key for the A2A protocol version.
/// When set to a version starting with "0.", enums encode as v0.3 lowercase values.
public let a2aProtocolVersionKey = CodingUserInfoKey(rawValue: "a2aProtocolVersion")!

/// Service parameters shared by client and server runtimes.
public struct A2AServiceParameters: Sendable {
    /// The A2A protocol version.
    public let version: String

    /// Comma-separated list of extension URIs.
    public let extensions: [String]?

    /// Optional tenant identifier for multi-tenant agents.
    public let tenant: String?

    /// JSON key casing convention.
    public let jsonKeyCasing: JSONKeyCasing

    public init(version: String = "1.0", extensions: [String]? = nil, tenant: String? = nil, jsonKeyCasing: JSONKeyCasing = .camelCase) {
        self.version = version
        self.extensions = extensions
        self.tenant = tenant
        self.jsonKeyCasing = jsonKeyCasing
    }

    /// HTTP header name for version.
    public static let versionHeader = "A2A-Version"

    /// HTTP header name for extensions.
    public static let extensionsHeader = "A2A-Extensions"

    /// Returns headers for these service parameters.
    public var headers: [String: String] {
        var headers = [A2AServiceParameters.versionHeader: version]
        if let extensions = extensions, !extensions.isEmpty {
            headers[A2AServiceParameters.extensionsHeader] = extensions.joined(separator: ",")
        }
        return headers
    }
}

/// JSON key casing options for encoding/decoding.
///
/// The A2A spec examples use snake_case (e.g. `message_id`, `context_id`),
/// while some implementations use camelCase (e.g. `messageId`, `contextId`).
/// This option controls which convention the library uses for JSON serialization.
public enum JSONKeyCasing: Sendable {
    /// Use camelCase keys (default).
    case camelCase

    /// Use snake_case keys.
    case snakeCase
}
