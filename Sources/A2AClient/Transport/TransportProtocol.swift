// TransportProtocol.swift
// A2AClient
//
// Agent2Agent Protocol - Client transport abstraction.
// The shared endpoint definitions live in A2ACore.

import Foundation
import A2ACore

/// Protocol defining the transport layer interface for A2A client communications.
///
/// Transport implementations handle the actual HTTP/network communication,
/// allowing for different binding types (HTTP/REST, JSON-RPC) and testing mocks.
public protocol A2ATransport: Sendable {
    /// Sends a request and returns a decoded response.
    func send<Request: Encodable, Response: Decodable>(
        request: Request,
        to endpoint: A2AEndpoint,
        responseType: Response.Type
    ) async throws -> Response

    /// Sends a request without expecting a response body.
    func send<Request: Encodable>(
        request: Request,
        to endpoint: A2AEndpoint
    ) async throws

    /// Opens a streaming connection and returns an async sequence of events.
    func stream<Request: Encodable>(
        request: Request,
        to endpoint: A2AEndpoint
    ) async throws -> AsyncThrowingStream<StreamingEvent, Error>

    /// Sends a GET request with query parameters and returns a decoded response.
    func get<Response: Decodable>(
        from endpoint: A2AEndpoint,
        queryItems: [URLQueryItem],
        responseType: Response.Type
    ) async throws -> Response

    /// Fetches data from a URL (used for agent card discovery).
    func fetch<Response: Decodable>(
        from url: URL,
        responseType: Response.Type
    ) async throws -> Response
}
