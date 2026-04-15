// SimpleClient.swift
// A2A Client Example — minimal client that sends a message and prints the reply.
//
// Useful as a smoke test against any running A2A agent. Pairs naturally
// with the `EchoAgent` server example: run EchoAgent in one terminal,
// then run this client in another.
//
// Running the sample
// ------------------
//     export A2A_AGENT_URL="http://127.0.0.1:8080"
//     swift run SimpleClient

import Foundation
import A2AClient

@main
struct SimpleClient {
    static func main() async {
        let urlString = ProcessInfo.processInfo.environment["A2A_AGENT_URL"] ?? "http://127.0.0.1:8080"
        guard let url = URL(string: urlString) else {
            print("SimpleClient: invalid URL \(urlString)")
            return
        }
        let client = A2AClient(baseURL: url)
        print("SimpleClient → \(url.absoluteString)")

        do {
            let response = try await client.sendMessage("hello from SimpleClient")
            switch response {
            case .message(let message):
                print("agent replied: \(message.textContent)")
            case .task(let task):
                print("agent opened task \(task.id) in state \(task.state.rawValue)")
            }
        } catch let error as A2AError {
            print("A2A error: \(error.localizedDescription)")
        } catch {
            print("error: \(error.localizedDescription)")
        }
    }
}
