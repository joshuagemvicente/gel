import Foundation

/// Progress of one `ollama pull`, summed over every layer reported so far.
public struct PullProgress: Equatable, Sendable {
    public var status: String = ""
    public var completed: Int64 = 0
    public var total: Int64 = 0
    public var done = false

    public var fraction: Double { total > 0 ? min(1, Double(completed) / Double(total)) : 0 }
}

public enum OllamaError: LocalizedError, Equatable {
    case unreachable
    case server(String)
    case incomplete

    public var errorDescription: String? {
        switch self {
        case .unreachable: return "Ollama isn't running."
        case .server(let message): return message
        case .incomplete: return "The download stopped before it finished."
        }
    }
}

/// Folds `/api/pull` NDJSON lines (`{status, digest, total, completed}`, one series per layer) into one progress value.
public struct PullAggregator {
    private var layers: [String: (completed: Int64, total: Int64)] = [:]
    private var order: [String] = []
    public private(set) var progress = PullProgress()

    public init() {}

    /// Consumes one line. Throws `OllamaError.server` for an `{"error": …}` line; ignores blank or non-JSON lines.
    @discardableResult
    public mutating func consume(_ line: String) throws -> PullProgress {
        guard let data = line.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return progress }
        if let error = obj["error"] as? String { throw OllamaError.server(error) }
        let status = obj["status"] as? String ?? progress.status
        progress.status = status
        if let digest = obj["digest"] as? String, let total = (obj["total"] as? NSNumber)?.int64Value {
            if layers[digest] == nil { order.append(digest) }
            let completed = (obj["completed"] as? NSNumber)?.int64Value ?? layers[digest]?.completed ?? 0
            layers[digest] = (completed, total)
        }
        progress.total = layers.values.reduce(0) { $0 + $1.total }
        progress.completed = layers.values.reduce(0) { $0 + $1.completed }
        if status == "success" {
            progress.done = true
            progress.completed = progress.total
        }
        return progress
    }
}

/// The few Ollama endpoints model setup needs, beyond chat (which goes through `OpenAICompatibleClient`).
public enum OllamaAPI {
    /// `GET /api/version` → "0.34.4", or nil when Ollama isn't answering.
    public static func version(baseURL: String = GelSettings.shared.localBaseURL,
                               session: URLSession = .shared) async -> String? {
        guard let url = URL(string: baseURL + "/api/version") else { return nil }
        var r = URLRequest(url: url)
        r.timeoutInterval = 2
        guard let (data, response) = try? await session.data(for: r),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return obj["version"] as? String
    }

    /// Names of the installed models (`GET /api/tags`), or nil when Ollama isn't answering.
    public static func installedModels(baseURL: String = GelSettings.shared.localBaseURL,
                                       session: URLSession = .shared) async -> [String]? {
        guard let url = URL(string: baseURL + "/api/tags") else { return nil }
        var r = URLRequest(url: url)
        r.timeoutInterval = 2
        guard let (data, response) = try? await session.data(for: r),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let models = obj["models"] as? [[String: Any]] else { return nil }
        return Array(Set(models.compactMap { $0["name"] as? String } + models.compactMap { $0["model"] as? String })).sorted()
    }

    /// Downloads a model with `POST /api/pull`, reporting progress per line. Cancelling the calling task stops the
    /// request (throws `CancellationError`); Ollama keeps the finished layers, so the next pull resumes.
    public static func pull(_ model: String,
                            baseURL: String = GelSettings.shared.localBaseURL,
                            session: URLSession = .shared,
                            onProgress: @escaping @Sendable (PullProgress) -> Void) async throws {
        guard let url = URL(string: baseURL + "/api/pull") else { throw OllamaError.unreachable }
        var r = URLRequest(url: url)
        r.httpMethod = "POST"
        r.timeoutInterval = 60 * 60
        r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        r.httpBody = try JSONSerialization.data(withJSONObject: ["model": model, "stream": true])
        let (bytes, response): (URLSession.AsyncBytes, URLResponse)
        do { (bytes, response) = try await session.bytes(for: r) } catch {
            try Task.checkCancellation()
            throw OllamaError.unreachable
        }
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            var body = ""
            for try await line in bytes.lines { body += line }
            var agg = PullAggregator()
            try agg.consume(body)
            throw OllamaError.server(body.isEmpty ? "Ollama refused the download." : body)
        }
        var agg = PullAggregator()
        for try await line in bytes.lines {
            try Task.checkCancellation()
            onProgress(try agg.consume(line))
        }
        try Task.checkCancellation()
        guard agg.progress.done else { throw OllamaError.incomplete }
    }
}
