import Foundation

enum OpenRouterError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case http(status: Int, body: String)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add your OpenRouter API key in Settings."
        case .invalidResponse:
            return "Received an unexpected response from OpenRouter."
        case .http(let status, let body):
            return "OpenRouter error \(status): \(body)"
        case .decoding(let error):
            return "Could not decode response: \(error.localizedDescription)"
        }
    }
}

struct ChatRequestMessage: Encodable {
    let role: String
    let content: String
}

struct ChatServerTool: Encodable {
    let type: String
}

struct ChatRequest: Encodable {
    let model: String
    let messages: [ChatRequestMessage]
    let stream: Bool
    let tools: [ChatServerTool]?
}

struct OpenRouterService {
    static let shared = OpenRouterService()

    private let baseURL = URL(string: "https://openrouter.ai/api/v1")!
    private let referer = "https://openchat.app"
    private let appTitle = "OpenChat iOS"

    private func makeRequest(path: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        let key = AppSettings.shared.apiKey
        guard !key.isEmpty else { throw OpenRouterError.missingAPIKey }
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = method
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(referer, forHTTPHeaderField: "HTTP-Referer")
        req.setValue(appTitle, forHTTPHeaderField: "X-Title")
        req.httpBody = body
        return req
    }

    // MARK: - Models

    func fetchModels() async throws -> [OpenRouterModel] {
        let req = try makeRequest(path: "models")
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw OpenRouterError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw OpenRouterError.http(status: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }
        do {
            let decoded = try JSONDecoder().decode(OpenRouterModelsResponse.self, from: data)
            await ModelCache.shared.save(decoded.data)
            return decoded.data
        } catch {
            throw OpenRouterError.decoding(error)
        }
    }

    // MARK: - Streaming chat completions

    /// Streams content deltas from a chat completion. Yields incremental text strings.
    func streamChat(
        model: String,
        messages: [ChatRequestMessage],
        webSearch: Bool,
        webFetch: Bool
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var tools: [ChatServerTool] = []
                    if webSearch { tools.append(ChatServerTool(type: "openrouter:web_search")) }
                    if webFetch { tools.append(ChatServerTool(type: "openrouter:web_fetch")) }
                    let body = ChatRequest(
                        model: model,
                        messages: messages,
                        stream: true,
                        tools: tools.isEmpty ? nil : tools
                    )
                    let bodyData = try JSONEncoder().encode(body)
                    var req = try makeRequest(path: "chat/completions", method: "POST", body: bodyData)
                    req.setValue("text/event-stream", forHTTPHeaderField: "Accept")

                    let (bytes, response) = try await URLSession.shared.bytes(for: req)
                    guard let http = response as? HTTPURLResponse else {
                        throw OpenRouterError.invalidResponse
                    }
                    guard (200..<300).contains(http.statusCode) else {
                        var collected = Data()
                        for try await byte in bytes { collected.append(byte) }
                        throw OpenRouterError.http(
                            status: http.statusCode,
                            body: String(data: collected, encoding: .utf8) ?? ""
                        )
                    }

                    for try await line in bytes.lines {
                        if Task.isCancelled { break }
                        guard line.hasPrefix("data:") else { continue }
                        let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                        if payload.isEmpty || payload.hasPrefix(":") { continue }
                        if payload == "[DONE]" { break }
                        if let delta = parseDeltaContent(from: payload), !delta.isEmpty {
                            continuation.yield(delta)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func parseDeltaContent(from json: String) -> String? {
        guard let data = json.data(using: .utf8) else { return nil }
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        guard let choices = obj["choices"] as? [[String: Any]], let first = choices.first else { return nil }
        if let delta = first["delta"] as? [String: Any], let content = delta["content"] as? String {
            return content
        }
        if let message = first["message"] as? [String: Any], let content = message["content"] as? String {
            return content
        }
        return nil
    }
}
