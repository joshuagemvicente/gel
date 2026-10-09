import Foundation

/// Local first, always. Every LLM task goes to Ollama; if it is unreachable, errors, or misses the timeouts,
/// the task is retried once against the user's OpenAI-compatible endpoint — with every message redacted first.
public final class ModelRouter {
    public static let shared = ModelRouter()

    public struct RouteResult {
        public var text: String
        public var provider: ProviderKind
        public var model: String
        /// Exactly what was sent to the cloud (already redacted). Nil when the local model answered.
        public var sentPayload: String?
    }

    private let settings = GelSettings.shared
    private let cooldown: TimeInterval = 60
    private var cloudUntil: Date?
    private let lock = NSLock()

    /// Set by the app from the team policy; when false, the cloud fallback is never used.
    public var cloudAllowedByPolicy = true

    public var localClient: OpenAICompatibleClient {
        OpenAICompatibleClient(baseURL: settings.localBaseURL + "/v1", model: settings.localModel)
    }

    public var cloudClient: OpenAICompatibleClient? {
        guard cloudAllowedByPolicy, let c = settings.cloudConfig else { return nil }
        return OpenAICompatibleClient(baseURL: c.baseURL, apiKey: c.apiKey, model: c.model)
    }

    private func startCooldown() {
        lock.lock(); cloudUntil = Date().addingTimeInterval(cooldown); lock.unlock()
    }

    public var isInCloudCooldown: Bool {
        lock.lock(); defer { lock.unlock() }
        return (cloudUntil ?? .distantPast) > Date()
    }

    // MARK: - Health

    public func localIsHealthy() async -> Bool {
        guard let url = URL(string: settings.localBaseURL + "/api/version") else { return false }
        var r = URLRequest(url: url)
        r.timeoutInterval = 2
        return ((try? await URLSession.shared.data(for: r))?.1 as? HTTPURLResponse)?.statusCode == 200
    }

    /// True when Ollama reports the chat model as loaded in memory (`GET /api/ps`).
    public func localModelLoaded() async -> Bool {
        guard let url = URL(string: settings.localBaseURL + "/api/ps") else { return false }
        var r = URLRequest(url: url)
        r.timeoutInterval = 2
        guard let (data, _) = try? await URLSession.shared.data(for: r),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let models = obj["models"] as? [[String: Any]] else { return false }
        return models.contains { ($0["name"] as? String) == settings.localModel || ($0["model"] as? String) == settings.localModel }
    }

    /// Loads the chat model into memory and keeps it there for an hour, so the first question isn't slow.
    public func warmUp() async {
        guard let url = URL(string: settings.localBaseURL + "/api/generate") else { return }
        var r = URLRequest(url: url)
        r.httpMethod = "POST"
        r.timeoutInterval = 120
        r.httpBody = try? JSONSerialization.data(withJSONObject: ["model": settings.localModel, "prompt": "", "keep_alive": "60m"])
        _ = try? await URLSession.shared.data(for: r)
    }

    // MARK: - Chat

    /// Streams an answer. `redactForCloud` must remove personal data; if it throws, no cloud call is made.
    public func chat(_ messages: [ChatMessage], maxTokens: Int = 600, temperature: Double = 0.2,
                     onToken: @escaping (String) -> Void,
                     redactForCloud: (String) throws -> String) async throws -> RouteResult {
        var localError: Error?
        if !isInCloudCooldown {
            let state = StreamState()
            do {
                let cold = await !localModelLoaded()
                let firstLimit = cold ? max(45, settings.firstTokenTimeout) : settings.firstTokenTimeout
                let text = try await streamWithTimeouts(localClient, messages, maxTokens: maxTokens, temperature: temperature,
                                                        firstToken: firstLimit, total: settings.totalTimeout + (cold ? 45 : 0),
                                                        state: state, onToken: onToken)
                return RouteResult(text: text, provider: .local, model: settings.localModel, sentPayload: nil)
            } catch {
                // Tokens already shown to the user: don't switch providers mid-answer.
                if state.emitted { throw error }
                localError = error
            }
        }
        // No cloud configured: report it plainly instead of a raw network error.
        guard let cloud = cloudClient else { throw LLMError.notConfigured }
        startCooldown()

        let redacted: [ChatMessage]
        do { redacted = try messages.map { ChatMessage(role: $0.role, content: try redactForCloud($0.content)) } }
        catch { throw LLMError.redactionFailed }
        let payload = redacted.map { "[\($0.role)]\n\($0.content)" }.joined(separator: "\n\n")
        let text = try await streamWithTimeouts(cloud, redacted, maxTokens: maxTokens, temperature: temperature, firstToken: 20, total: 60,
                                                state: StreamState(), onToken: onToken)
        Store.shared.logEvent(kind: "cloud_call", category: "chat", count: payload.count, provider: "cloud")
        return RouteResult(text: text, provider: .cloud, model: cloud.model, sentPayload: payload)
    }

    /// Non-streaming JSON task (personal-data detection, layer 3). Same fallback and redaction rules as `chat`.
    public func completeJSON(_ messages: [ChatMessage], redactForCloud: (String) throws -> String,
                             timeout: TimeInterval = 25) async throws -> RouteResult {
        if !isInCloudCooldown {
            do {
                let text = try await localClient.complete(messages, json: true, timeout: timeout)
                return RouteResult(text: text, provider: .local, model: settings.localModel, sentPayload: nil)
            } catch {}
        }
        guard let cloud = cloudClient else { throw LLMError.notConfigured }
        startCooldown()
        let redacted: [ChatMessage]
        do { redacted = try messages.map { ChatMessage(role: $0.role, content: try redactForCloud($0.content)) } }
        catch { throw LLMError.redactionFailed }
        let payload = redacted.map { "[\($0.role)]\n\($0.content)" }.joined(separator: "\n\n")
        let text = try await cloud.complete(redacted, json: false, timeout: 45)
        Store.shared.logEvent(kind: "cloud_call", category: "detect", count: payload.count, provider: "cloud")
        return RouteResult(text: text, provider: .cloud, model: cloud.model, sentPayload: payload)
    }

    final class StreamState {
        private let lock = NSLock()
        private var _text = ""
        private var _firstAt: Date?
        private var _error: Error?
        private var _done = false
        var emitted: Bool { lock.lock(); defer { lock.unlock() }; return _firstAt != nil }
        func append(_ s: String) { lock.lock(); if _firstAt == nil { _firstAt = Date() }; _text += s; lock.unlock() }
        func finish(_ e: Error?) { lock.lock(); _error = e; _done = true; lock.unlock() }
        var snapshot: (text: String, first: Date?, error: Error?, done: Bool) {
            lock.lock(); defer { lock.unlock() }
            return (_text, _firstAt, _error, _done)
        }
    }

    private func streamWithTimeouts(_ client: OpenAICompatibleClient, _ messages: [ChatMessage], maxTokens: Int, temperature: Double,
                                    firstToken: TimeInterval, total: TimeInterval, state: StreamState,
                                    onToken: @escaping (String) -> Void) async throws -> String {
        let start = Date()
        let task = Task {
            do {
                for try await token in client.stream(messages, temperature: temperature, maxTokens: maxTokens) {
                    state.append(token)
                    onToken(token)
                }
                state.finish(nil)
            } catch {
                state.finish(error)
            }
        }
        while true {
            try await Task.sleep(nanoseconds: 100_000_000)
            let s = state.snapshot
            if s.done { break }
            let elapsed = Date().timeIntervalSince(start)
            if s.first == nil && elapsed > firstToken {
                task.cancel()
                throw LLMError.timeout("no response in \(Int(firstToken)) s")
            }
            if elapsed > total {
                task.cancel()
                if s.text.isEmpty { throw LLMError.timeout("over \(Int(total)) s") }
                break
            }
        }
        let s = state.snapshot
        if let e = s.error, s.text.isEmpty { throw e }
        let cleaned = Self.stripThinking(s.text)
        if cleaned.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { throw LLMError.badResponse("empty answer") }
        return cleaned
    }

    /// Removes `<think>…</think>` blocks some models emit before the answer.
    public static func stripThinking(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "<think>[\\s\\S]*?</think>\\s*") else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
    }
}
