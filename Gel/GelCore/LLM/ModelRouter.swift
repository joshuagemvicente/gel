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
        /// Placeholder → value mapping from the redaction gate (cloud only; stays on this Mac).
        public var mapping: [String: String] = [:]
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

    /// Required local models that Ollama doesn't have installed (empty = all present). Nil if Ollama is unreachable.
    public func missingLocalModels() async -> [String]? {
        guard let url = URL(string: settings.localBaseURL + "/api/tags") else { return nil }
        var r = URLRequest(url: url)
        r.timeoutInterval = 2
        guard let (data, response) = try? await URLSession.shared.data(for: r),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let models = obj["models"] as? [[String: Any]] else { return nil }
        let names = Set(models.compactMap { $0["name"] as? String } + models.compactMap { $0["model"] as? String })
        func installed(_ m: String) -> Bool { names.contains(m) || names.contains(m + ":latest") }
        return [settings.localModel, settings.embedModel].filter { !installed($0) }
    }

    /// Healthy = Ollama answers and both the chat and embedding models are installed (Q5).
    public func localIsHealthy() async -> Bool {
        guard let missing = await missingLocalModels() else { return false }
        return missing.isEmpty
    }

    public func ollamaReachable() async -> Bool {
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
                     redactForCloud: (String) throws -> Redactor.TextResult) async throws -> RouteResult {
        var localError: Error?
        if !isInCloudCooldown {
            let state = StreamState()
            do {
                let cold = await !localModelLoaded()
                var firstLimit = cold ? max(45, settings.firstTokenTimeout) : settings.firstTokenTimeout
                // Nothing to fall back to: giving up early only turns a slow answer into an error (D-064).
                if cloudClient == nil { firstLimit = settings.totalTimeout + (cold ? 45 : 0) }
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

        let (redacted, mapping) = try Self.redact(messages, with: redactForCloud)
        let payload = redacted.map { "[\($0.role)]\n\($0.content)" }.joined(separator: "\n\n")
        let text = try await streamWithTimeouts(cloud, redacted, maxTokens: maxTokens, temperature: temperature, firstToken: 20, total: 60,
                                                state: StreamState(), onToken: onToken)
        Store.shared.logEvent(kind: "cloud_call", category: "chat", count: payload.count, provider: "cloud")
        return RouteResult(text: text, provider: .cloud, model: cloud.model, sentPayload: payload, mapping: mapping)
    }

    /// Non-streaming JSON task (personal-data detection, layer 3). Same fallback and redaction rules as `chat`.
    public func completeJSON(_ messages: [ChatMessage], redactForCloud: (String) throws -> Redactor.TextResult,
                             timeout: TimeInterval = 25) async throws -> RouteResult {
        if !isInCloudCooldown {
            do {
                let text = try await localClient.complete(messages, json: true, timeout: timeout)
                return RouteResult(text: text, provider: .local, model: settings.localModel, sentPayload: nil)
            } catch {}
        }
        guard let cloud = cloudClient else { throw LLMError.notConfigured }
        startCooldown()
        let (redacted, mapping) = try Self.redact(messages, with: redactForCloud)
        let payload = redacted.map { "[\($0.role)]\n\($0.content)" }.joined(separator: "\n\n")
        let text = try await cloud.complete(redacted, json: false, timeout: 45)
        Store.shared.logEvent(kind: "cloud_call", category: "detect", count: payload.count, provider: "cloud")
        return RouteResult(text: text, provider: .cloud, model: cloud.model, sentPayload: payload, mapping: mapping)
    }

    /// The redaction gate over every message. Any error means no cloud request at all.
    static func redact(_ messages: [ChatMessage], with gate: (String) throws -> Redactor.TextResult) throws -> ([ChatMessage], [String: String]) {
        var mapping: [String: String] = [:]
        var out: [ChatMessage] = []
        do {
            for m in messages {
                let r = try gate(m.content)
                for (k, v) in r.mapping where mapping[k] == nil { mapping[k] = v }
                out.append(ChatMessage(role: m.role, content: r.text))
            }
        } catch { throw LLMError.redactionFailed }
        return (out, mapping)
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
            if Task.isCancelled { task.cancel(); throw CancellationError() }
            try? await Task.sleep(nanoseconds: 100_000_000)
            if Task.isCancelled { task.cancel(); throw CancellationError() }
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
