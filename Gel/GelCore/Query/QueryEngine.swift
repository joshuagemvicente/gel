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

    /// Reciprocal-rank fusion of vector and keyword results, at most `perDoc` chunks per file so one long file
    /// can't crowd out the others (questions like "which applicants…" need many files).
    public func search(_ question: String, limit: Int = 8, perDoc: Int = 2) async throws -> [SearchHit] {
        let qv = try await embedder.embed(["Question: " + question]).first ?? []
        let vector = store.vectorSearch(qv, limit: 40)
        let keyword = store.keywordSearch(question, limit: 40)
        var fused: [Int64: Double] = [:]
        for (rank, hit) in vector.enumerated() { fused[hit.chunkId, default: 0] += 1.0 / Double(60 + rank) }
        for (rank, hit) in keyword.enumerated() { fused[hit.chunkId, default: 0] += 1.0 / Double(60 + rank) }
        var perDocCount: [Int64: Int] = [:]
        var hits: [SearchHit] = []
        for (chunkId, score) in fused.sorted(by: { $0.value > $1.value }) {
            guard let chunk = store.chunk(id: chunkId), let doc = store.document(id: chunk.docId) else { continue }
            if perDocCount[doc.id, default: 0] >= perDoc { continue }
            perDocCount[doc.id, default: 0] += 1
            hits.append(SearchHit(chunk: chunk, document: doc, score: score))
            if hits.count >= limit { break }
        }
        return hits
    }

    public static func systemPrompt() -> String {
        """
        You are Gel, a private assistant that answers questions about the user's own files on their Mac.
        Rules:
        - Use ONLY the numbered sources. Never use outside knowledge.
        - Answer in the same language as the question (Filipino, English, or Taglish).
        - Be brief: at most 5 short sentences or a short bulleted list.
        - After every fact, cite its source number in square brackets, like [1] or [2][3].
        - When the question needs a calculation (for example years of experience from date ranges), do it carefully from the dates in the sources.
        - If the sources do not contain the answer, reply exactly: \(notFound)
        """
    }

    public static func userPrompt(question: String, hits: [SearchHit]) -> String {
        var s = "Sources:\n"
        for (i, h) in hits.enumerated() {
            s += "\n[\(i + 1)] \(h.document.name), page \(h.chunk.page + 1):\n\(h.chunk.text.trimmingCharacters(in: .whitespacesAndNewlines))\n"
        }
        s += "\nQuestion: \(question)"
        return s
    }

    /// Streams tokens through `onToken`; returns the final answer with citations resolved to files and pages.
    public func ask(_ question: String, onToken: @escaping (String) -> Void = { _ in }) async throws -> AnswerResult {
        let hits = try await search(question)
        guard !hits.isEmpty else {
            return finish(question: question, text: Self.notFound, hits: [], provider: .local,
                          model: GelSettings.shared.localModel, sent: nil)
        }
        let messages: [ChatMessage] = [.system(Self.systemPrompt()), .user(Self.userPrompt(question: question, hits: hits))]
        let result = try await router.chat(messages, onToken: onToken) { content in
            try Redactor.cloudSafe(content)
        }
        return finish(question: question, text: result.text, hits: hits, provider: result.provider,
                      model: result.model, sent: result.sentPayload)
    }

    private func finish(question: String, text: String, hits: [SearchHit], provider: ProviderKind,
                        model: String, sent: String?) -> AnswerResult {
        let cited = Self.citationNumbers(in: text)
        var citations: [Citation] = []
        for n in cited where n >= 1 && n <= hits.count {
            let h = hits[n - 1]
            citations.append(Citation(id: n, docId: h.document.id, path: h.document.path, page: h.chunk.page,
                                      start: h.chunk.start, length: h.chunk.length,
                                      snippet: String(h.chunk.text.prefix(240))))
        }
        var answer = AnswerResult(id: 0, date: Date(), question: question, text: text.trimmingCharacters(in: .whitespacesAndNewlines),
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
