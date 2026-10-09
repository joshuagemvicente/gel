# F3 · Query and citations — Interfaces

## Exposed (`Gel/GelCore/Query/QueryEngine.swift`)

```swift
public final class QueryEngine {
    public static let shared: QueryEngine
    public init(store: Store = .shared, embedder: Embedder = Embedder(), router: ModelRouter = .shared)
    public static let notFound: String     // "I couldn't find that in your files."

    public func search(_ question: String, limit: Int = 8, perDoc: Int = 2) async throws -> [SearchHit]
    public static func systemPrompt() -> String
    public static func userPrompt(question: String, hits: [SearchHit]) -> String
    /// Streams tokens through onToken (called off the main thread); returns the saved answer.
    public func ask(_ question: String, onToken: @escaping (String) -> Void = { _ in }) async throws -> AnswerResult
    public static func citationNumbers(in text: String) -> [Int]
}
```

## Data types (`Index/Models.swift`)

```swift
public struct SearchHit { public var chunk: Chunk; public var document: DocumentRecord; public var score: Double }
public struct Citation: Codable, Hashable, Identifiable {
    public var id: Int            // the number shown, e.g. 1 for "[1]"
    public var docId: Int64; public var path: String; public var page: Int
    public var start: Int; public var length: Int; public var snippet: String
    public var fileName: String   // computed
    public var label: String      // "1 · Resume_REYES p.2"
}
public enum ProviderKind: String, Codable { case local, cloud }
public struct AnswerResult: Codable, Hashable, Identifiable {
    public var id: Int64; public var date: Date; public var question: String; public var text: String
    public var citations: [Citation]; public var provider: ProviderKind; public var model: String
    public var sentPayload: String?   // redacted prompt sent to the cloud; nil when local
}
```

## Consumed

- `Store.vectorSearch(_:limit:)`, `Store.keywordSearch(_:limit:)`, `Store.chunk(id:)`, `Store.document(id:)`, `Store.saveAnswer(_:)`, `Store.logEvent(kind: "query", provider:)`.
- `Embedder.embed(_:)` ([indexing](../indexing/interfaces.md)).
- `ModelRouter.chat(_:maxTokens:onToken:redactForCloud:)` with `redactForCloud = Redactor.cloudSafe` ([model-fallback](../model-fallback/interfaces.md), [detection-redaction](../detection-redaction/interfaces.md)).

## Invariants

- Citation `start`/`length` are the chunk's UTF-16 range on page `page` (0-based); the viewer highlights exactly that range.
- Citation numbers outside `1…hits.count` are dropped.
- Every `ask` writes one `history` row and one `query` event (provider only, no content).
- `onToken` may be called from a background task: UI callers hop to the main actor.

## Callers

`gelcli ask|search`; [launcher](../launcher/spec.md); [history](../history/spec.md) and [library-viewer](../library-viewer/spec.md) read `AnswerResult`/`Citation`.
