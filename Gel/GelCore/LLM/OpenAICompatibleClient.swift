import Foundation

public struct ChatMessage: Codable, Hashable {
    public var role: String
    public var content: String
    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
    public static func system(_ s: String) -> ChatMessage { ChatMessage(role: "system", content: s) }
    public static func user(_ s: String) -> ChatMessage { ChatMessage(role: "user", content: s) }
}

public enum LLMError: Error, LocalizedError {
    case badResponse(String)
    case timeout(String)
    case unavailable(String)
    case redactionFailed
    case notConfigured

    public var errorDescription: String? {
        switch self {
        case .badResponse(let m): return "The model returned an error: \(m.prefix(200))"
        case .timeout(let m): return "The model took too long (\(m))."
        case .unavailable(let m): return m
        case .redactionFailed: return "Redaction failed, so nothing was sent to the cloud."
        case .notConfigured: return "Local model unavailable. Start Ollama or set a cloud fallback in Settings."
        }
    }
}

/// Minimal client for any OpenAI-compatible chat API. Gel points it at Ollama (`http://localhost:11434/v1`)
/// for local inference and at the user's endpoint for the cloud fallback.
public final class OpenAICompatibleClient {
    public let baseURL: String
    public let apiKey: String
    public let model: String

    public init(baseURL: String, apiKey: String = "", model: String) {
        self.baseURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        self.apiKey = apiKey
        self.model = model
    }

    private func request(path: String, body: [String: Any]?, timeout: TimeInterval) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else { throw LLMError.unavailable("Invalid URL: \(baseURL)") }
        var r = URLRequest(url: url)
        r.timeoutInterval = timeout
        r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty { r.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization") }
        if let body {
            r.httpMethod = "POST"
            r.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        return r
    }

    private func body(_ messages: [ChatMessage], stream: Bool, temperature: Double, maxTokens: Int, json: Bool) -> [String: Any] {
        var b: [String: Any] = [
            "model": model,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "stream": stream,
            "temperature": temperature,
            "max_tokens": maxTokens,
        ]
        if json { b["response_format"] = ["type": "json_object"] }
        return b
    }

    /// Streams content deltas from `POST /chat/completions` (server-sent events).
    public func stream(_ messages: [ChatMessage], temperature: Double = 0.2, maxTokens: Int = 600) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let req = try request(path: "/chat/completions",
                                          body: body(messages, stream: true, temperature: temperature, maxTokens: maxTokens, json: false),
                                          timeout: 120)
                    let (bytes, response) = try await URLSession.shared.bytes(for: req)
                    guard let http = response as? HTTPURLResponse else { throw LLMError.badResponse("no response") }
                    guard http.statusCode == 200 else {
                        var text = ""
                        for try await line in bytes.lines { text += line; if text.count > 500 { break } }
                        throw LLMError.badResponse("HTTP \(http.statusCode) \(text)")
                    }
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data:") else { continue }
                        let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                        if payload == "[DONE]" { break }
                        guard let obj = try? JSONSerialization.jsonObject(with: Data(payload.utf8)) as? [String: Any],
                              let choices = obj["choices"] as? [[String: Any]],
                              let delta = choices.first?["delta"] as? [String: Any],
                              let content = delta["content"] as? String, !content.isEmpty else { continue }
                        continuation.yield(content)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Non-streaming completion, used for JSON tasks like personal-data detection.
    public func complete(_ messages: [ChatMessage], temperature: Double = 0, maxTokens: Int = 800,
                         json: Bool = false, timeout: TimeInterval = 30) async throws -> String {
        let req = try request(path: "/chat/completions",
                              body: body(messages, stream: false, temperature: temperature, maxTokens: maxTokens, json: json),
                              timeout: timeout)
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw LLMError.badResponse("HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0) \(String(data: data, encoding: .utf8) ?? "")")
        }
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = obj["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw LLMError.badResponse(String(data: data, encoding: .utf8) ?? "")
        }
        return content
    }

    /// `GET /models`, used by the "Test connection" button.
    public func listModels() async throws -> [String] {
        let (data, response) = try await URLSession.shared.data(for: try request(path: "/models", body: nil, timeout: 10))
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw LLMError.badResponse("HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0) \(String(data: data, encoding: .utf8) ?? "")")
        }
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return (obj?["data"] as? [[String: Any]])?.compactMap { $0["id"] as? String } ?? []
    }
}
