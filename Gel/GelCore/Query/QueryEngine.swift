import Foundation

/// Answers a question from the indexed files: hybrid search (vectors + keywords), then a cited answer from the LLM.
public final class QueryEngine {
    public static let shared = QueryEngine()
    public let store: Store
    public let embedder: Embedder
    public let router: ModelRouter

    public init(store: Store = .shared, embedder: Embedder = Embedder(), router: ModelRouter = .shared) {
        self.store = store
        self.embedder = embedder
        self.router = router
    }

    public static let notFound = "Hindi ko nakita sa files. (I couldn't find it in your files.)"

    /// One numbered source in the prompt: a file and up to two of its best passages, in page order.
    public struct Source {
        public var document: DocumentRecord
        public var passages: [SearchHit]
        /// The highest-scoring passage; citations highlight this one.
        public var best: SearchHit
        public var score: Double
    }

    /// Hybrid search: reciprocal-rank fusion of vector and keyword results (keywords weighted 2×), then the best
    /// files ranked by the sum of their top passages, so files with several relevant passages win.
    public func search(_ question: String, files: Int = 5, perFile: Int = 2) async throws -> [Source] {
        // If embeddings are unavailable (Ollama down), fall back to keyword search alone so the cloud
        // fallback can still answer from the right passages.
        let qv = (try? await embedder.embed(["Question: " + question]).first) ?? nil
        let vector = qv.map { store.vectorSearch($0, limit: 40) } ?? []
        let keyword = store.keywordSearch(question, limit: 40)
        var fused: [Int64: Double] = [:]
        for (rank, hit) in vector.enumerated() { fused[hit.chunkId, default: 0] += 1.0 / Double(60 + rank) }
        for (rank, hit) in keyword.enumerated() { fused[hit.chunkId, default: 0] += 2.0 / Double(60 + rank) }
        var byFile: [Int64: [SearchHit]] = [:]
        for (chunkId, score) in fused.sorted(by: { $0.value > $1.value }) {
            guard let chunk = store.chunk(id: chunkId), let doc = store.document(id: chunk.docId) else { continue }
            if byFile[doc.id, default: []].count < perFile {
                byFile[doc.id, default: []].append(SearchHit(chunk: chunk, document: doc, score: score))
            }
        }
        let sources = byFile.values.compactMap { hits -> Source? in
            guard let best = hits.first else { return nil }
            let ordered = hits.sorted { ($0.chunk.page, $0.chunk.start) < ($1.chunk.page, $1.chunk.start) }
            return Source(document: best.document, passages: ordered, best: best, score: hits.reduce(0) { $0 + $1.score })
        }
        return Array(sources.sorted { $0.score > $1.score }.prefix(files))
    }

    public static func systemPrompt() -> String {
        """
        You are Gel, a private assistant that answers questions about the user's own files on their Mac.
        Rules:
        - Use ONLY the numbered sources. Never use outside knowledge.
        - Answer in the same language as the question (Filipino, English, or Taglish).
        - Be brief: at most 5 short sentences or a short bulleted list.
        - After every fact, cite its source number in square brackets, like [1] or [2][3].
        - For years of experience, compute end year minus start year for each role and add them up (2017–2024 = 7 years; 2016–2019 plus 2019–2025 = 9 years; \"Present\" means 2026).
        - List every person or item in the sources that matches, and only those that match; leave out non-matches.
        - Only if NONE of the sources answer the question, reply exactly: \(notFound) Never add that sentence to an answer that has facts.
        """
    }

    public static func userPrompt(question: String, sources: [Source]) -> String {
        var s = "Sources:\n"
        for (i, src) in sources.enumerated() {
            let pages = Array(Set(src.passages.map { $0.chunk.page + 1 })).sorted().map(String.init).joined(separator: ", ")
            let text = src.passages.map { $0.chunk.text.trimmingCharacters(in: .whitespacesAndNewlines) }.joined(separator: "\n…\n")
            s += "\n[\(i + 1)] \(src.document.name) (page \(pages)):\n\(text)\n"
        }
        s += "\nQuestion: \(question)"
        return s
    }

    /// Streams tokens through `onToken`; returns the final answer with citations resolved to files and pages.
    public func ask(_ question: String, onToken: @escaping (String) -> Void = { _ in }) async throws -> AnswerResult {
        let sources = try await search(question)
        guard !sources.isEmpty else {
            return finish(question: question, text: Self.notFound, sources: [], provider: .local,
                          model: GelSettings.shared.localModel, sent: nil)
        }
        let messages: [ChatMessage] = [.system(Self.systemPrompt()), .user(Self.userPrompt(question: question, sources: sources))]
        let result = try await router.chat(messages, temperature: 0, onToken: onToken) { content in
            try Redactor.cloudSafe(content)
        }
        return finish(question: question, text: result.text, sources: sources, provider: result.provider,
                      model: result.model, sent: result.sentPayload)
    }

    private func finish(question: String, text: String, sources: [Source], provider: ProviderKind,
                        model: String, sent: String?) -> AnswerResult {
        var citations: [Citation] = []
        for n in Self.citationNumbers(in: text) where n >= 1 && n <= sources.count {
            let h = sources[n - 1].best
            citations.append(Citation(id: n, docId: h.document.id, path: h.document.path, page: h.chunk.page,
                                      start: h.chunk.start, length: h.chunk.length,
                                      snippet: String(h.chunk.text.prefix(240))))
        }
        var cleaned = text
        if !citations.isEmpty {
            cleaned = cleaned.replacingOccurrences(of: Self.notFound, with: "")
                .replacingOccurrences(of: "Hindi ko nakita sa files.", with: "")
        }
        var answer = AnswerResult(id: 0, date: Date(), question: question, text: cleaned.trimmingCharacters(in: .whitespacesAndNewlines),
                                  citations: citations, provider: provider, model: model, sentPayload: sent)
        answer.id = store.saveAnswer(answer)
        store.logEvent(kind: "query", provider: provider.rawValue)
        return answer
    }

    /// Distinct citation numbers in order of first appearance: "[2] … [1][2]" → [2, 1].
    public static func citationNumbers(in text: String) -> [Int] {
        guard let re = try? NSRegularExpression(pattern: "\\[(\\d{1,2})\\]") else { return [] }
        var seen: [Int] = []
        for m in re.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            if let r = Range(m.range(at: 1), in: text), let n = Int(text[r]), !seen.contains(n) { seen.append(n) }
        }
        return seen
    }
}
