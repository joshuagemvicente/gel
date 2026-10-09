# M1 · Model provider and cloud fallback — Interfaces

## Exposed (`Gel/GelCore/LLM/`)

```swift
public struct ChatMessage: Codable, Hashable {
    public var role: String; public var content: String
    public init(role: String, content: String)
    public static func system(_ s: String) -> ChatMessage
    public static func user(_ s: String) -> ChatMessage
}

public enum LLMError: Error, LocalizedError {
    case badResponse(String), timeout(String), unavailable(String), redactionFailed, notConfigured
}

public final class OpenAICompatibleClient {
    public let baseURL: String; public let apiKey: String; public let model: String
    public init(baseURL: String, apiKey: String = "", model: String)
    public func stream(_ messages: [ChatMessage], temperature: Double = 0.2, maxTokens: Int = 600) -> AsyncThrowingStream<String, Error>
    public func complete(_ messages: [ChatMessage], temperature: Double = 0, maxTokens: Int = 800,
                         json: Bool = false, timeout: TimeInterval = 30) async throws -> String
    public func listModels() async throws -> [String]          // GET {base}/models — "Test connection"
}

public final class ModelRouter {
    public static let shared: ModelRouter
    public struct RouteResult { public var text: String; public var provider: ProviderKind; public var model: String; public var sentPayload: String? }
    public var cloudAllowedByPolicy: Bool                       // set by the app from TeamPolicy
    public var localClient: OpenAICompatibleClient              // {localBaseURL}/v1, localModel
    public var cloudClient: OpenAICompatibleClient?             // nil unless configured and allowed
    public var isInCloudCooldown: Bool
    public func localIsHealthy() async -> Bool                  // GET {local}/api/version, 2 s
    public func warmUp() async                                  // POST /api/generate, keep_alive 60m
    public func chat(_ messages: [ChatMessage], maxTokens: Int = 600,
                     onToken: @escaping (String) -> Void,
                     redactForCloud: (String) throws -> String) async throws -> RouteResult
    public func completeJSON(_ messages: [ChatMessage], redactForCloud: (String) throws -> String,
                             timeout: TimeInterval = 25) async throws -> RouteResult
    public static func stripThinking(_ text: String) -> String
}
```

Settings (`Gel/GelCore/Support/Settings.swift`):

```swift
GelSettings.shared.localBaseURL      // "http://localhost:11434"
GelSettings.shared.localModel        // "qwen3:4b-instruct-2507-q4_K_M"
GelSettings.shared.cloudEnabled / cloudBaseURL / cloudModel   // UserDefaults (env overrides)
GelSettings.shared.cloudAPIKey       // Keychain (env override GEL_CLOUD_API_KEY)
GelSettings.shared.firstTokenTimeout // 8 s
GelSettings.shared.totalTimeout      // 30 s
GelSettings.shared.cloudConfig: CloudConfig?   // nil unless enabled + URL + model
```

## Invariants

- Cloud messages are exactly `redactForCloud(original)`; `sentPayload` records them (`[role]\ncontent` blocks) for "What was sent".
- If `redactForCloud` throws, the router throws `LLMError.redactionFailed` and sends nothing.
- Once a local stream has emitted a token, errors are rethrown; no provider switch.
- After any fallback, `isInCloudCooldown` is true for 60 s.
- Each cloud call logs `cloud_call` with the payload character count only.
- `onToken` runs on a background task; UI callers hop to the main actor.

## Callers

[query-citations](../query-citations/interfaces.md) (`chat` with `Redactor.cloudSafe`), [detection-redaction](../detection-redaction/interfaces.md) (`completeJSON`), app: [app-shell](../app-shell/spec.md) (`warmUp`, `localIsHealthy`, `cloudAllowedByPolicy`, `isInCloudCooldown`), [settings](../settings/spec.md) (`listModels` via a client built from the form values).
