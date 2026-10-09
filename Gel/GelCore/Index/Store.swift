import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

public enum StoreError: Error, LocalizedError {
    case open(String), prepare(String), step(String)
    public var errorDescription: String? {
        switch self {
        case .open(let m): return "Could not open the index: \(m)"
        case .prepare(let m), .step(let m): return "Index error: \(m)"
        }
    }
}

/// SQLite-backed index: documents, pages, chunks (with embeddings), keyword search, history and events.
/// All access is serialized through a lock; the vector cache is kept in memory for brute-force cosine search.
public final class Store {
    public static let shared: Store = {
        do { return try Store(url: GelPaths.database) } catch { fatalError("\(error)") }
    }()

    private var db: OpaquePointer?
    private let lock = NSRecursiveLock()
    private var vectorCache: [(chunkId: Int64, docId: Int64, vector: [Float])]?

    public init(url: URL) throws {
        if sqlite3_open(url.path, &db) != SQLITE_OK {
            throw StoreError.open(String(cString: sqlite3_errmsg(db)))
        }
        try exec("PRAGMA journal_mode=WAL;")
        try exec("""
        CREATE TABLE IF NOT EXISTS documents(id INTEGER PRIMARY KEY, path TEXT UNIQUE, kind TEXT, page_count INT,
            modified REAL, indexed REAL, has_ocr INT);
        CREATE TABLE IF NOT EXISTS pages(doc_id INT, page INT, text TEXT, lines TEXT, PRIMARY KEY(doc_id, page));
        CREATE TABLE IF NOT EXISTS chunks(id INTEGER PRIMARY KEY, doc_id INT, page INT, start INT, length INT,
            text TEXT, embedding BLOB);
        CREATE INDEX IF NOT EXISTS chunks_doc ON chunks(doc_id);
        CREATE VIRTUAL TABLE IF NOT EXISTS chunks_fts USING fts5(text, chunk_id UNINDEXED, tokenize='unicode61');
        CREATE TABLE IF NOT EXISTS history(id INTEGER PRIMARY KEY, ts REAL, question TEXT, answer TEXT,
            citations TEXT, provider TEXT, model TEXT, sent TEXT);
        CREATE TABLE IF NOT EXISTS events(id INTEGER PRIMARY KEY, ts REAL, kind TEXT, category TEXT, count INT,
            app TEXT, provider TEXT);
        CREATE TABLE IF NOT EXISTS redactions(id INTEGER PRIMARY KEY, ts REAL, source TEXT, output TEXT, counts TEXT);
        """)
    }

    deinit { sqlite3_close(db) }

    // MARK: - Low-level helpers

    private func exec(_ sql: String) throws {
        lock.lock(); defer { lock.unlock() }
        var err: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &err) != SQLITE_OK {
            let message = err.map { String(cString: $0) } ?? "unknown"
            sqlite3_free(err)
            throw StoreError.step(message)
        }
    }

    private enum Value {
        case int(Int64), double(Double), text(String), blob(Data), null
    }

    private func bind(_ stmt: OpaquePointer?, _ values: [Value]) {
        for (i, v) in values.enumerated() {
            let idx = Int32(i + 1)
            switch v {
            case .int(let x): sqlite3_bind_int64(stmt, idx, x)
            case .double(let x): sqlite3_bind_double(stmt, idx, x)
            case .text(let s): sqlite3_bind_text(stmt, idx, s, -1, SQLITE_TRANSIENT)
            case .blob(let d): _ = d.withUnsafeBytes { sqlite3_bind_blob(stmt, idx, $0.baseAddress, Int32(d.count), SQLITE_TRANSIENT) }
            case .null: sqlite3_bind_null(stmt, idx)
            }
        }
    }

    @discardableResult
    private func run(_ sql: String, _ values: [Value] = []) throws -> Int64 {
        lock.lock(); defer { lock.unlock() }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw StoreError.prepare(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }
        bind(stmt, values)
        let rc = sqlite3_step(stmt)
        guard rc == SQLITE_DONE || rc == SQLITE_ROW else {
            throw StoreError.step(String(cString: sqlite3_errmsg(db)))
        }
        return sqlite3_last_insert_rowid(db)
    }

    private func query<T>(_ sql: String, _ values: [Value] = [], _ map: (OpaquePointer?) -> T) -> [T] {
        lock.lock(); defer { lock.unlock() }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        bind(stmt, values)
        var rows: [T] = []
        while sqlite3_step(stmt) == SQLITE_ROW { rows.append(map(stmt)) }
        return rows
    }

    private static func text(_ stmt: OpaquePointer?, _ col: Int32) -> String {
        guard let c = sqlite3_column_text(stmt, col) else { return "" }
        return String(cString: c)
    }

    private static func blob(_ stmt: OpaquePointer?, _ col: Int32) -> Data {
        let n = Int(sqlite3_column_bytes(stmt, col))
        guard n > 0, let p = sqlite3_column_blob(stmt, col) else { return Data() }
        return Data(bytes: p, count: n)
    }

    public func transaction(_ body: () throws -> Void) throws {
        lock.lock(); defer { lock.unlock() }
        try exec("BEGIN")
        do { try body(); try exec("COMMIT") } catch { try? exec("ROLLBACK"); throw error }
    }

    // MARK: - Documents

    private func mapDocument(_ s: OpaquePointer?) -> DocumentRecord {
        DocumentRecord(
            id: sqlite3_column_int64(s, 0),
            path: Self.text(s, 1),
            kind: DocKind(rawValue: Self.text(s, 2)) ?? .pdf,
            pageCount: Int(sqlite3_column_int(s, 3)),
            modifiedAt: Date(timeIntervalSince1970: sqlite3_column_double(s, 4)),
            indexedAt: Date(timeIntervalSince1970: sqlite3_column_double(s, 5)),
            hasOCR: sqlite3_column_int(s, 6) != 0)
    }

    public func documents() -> [DocumentRecord] {
        query("SELECT id, path, kind, page_count, modified, indexed, has_ocr FROM documents ORDER BY path", [], mapDocument)
    }

    public func document(id: Int64) -> DocumentRecord? {
        query("SELECT id, path, kind, page_count, modified, indexed, has_ocr FROM documents WHERE id=?", [.int(id)], mapDocument).first
    }

    public func document(path: String) -> DocumentRecord? {
        query("SELECT id, path, kind, page_count, modified, indexed, has_ocr FROM documents WHERE path=?", [.text(path)], mapDocument).first
    }

    public func removeDocument(id: Int64) throws {
        lock.lock(); defer { lock.unlock() }
        try run("DELETE FROM chunks_fts WHERE chunk_id IN (SELECT id FROM chunks WHERE doc_id=?)", [.int(id)])
        try run("DELETE FROM chunks WHERE doc_id=?", [.int(id)])
        try run("DELETE FROM pages WHERE doc_id=?", [.int(id)])
        try run("DELETE FROM documents WHERE id=?", [.int(id)])
        vectorCache = nil
    }

    /// Replaces a document's pages and chunks in one transaction.
    public func save(path: String, kind: DocKind, modified: Date, pages: [PageContent],
                     chunks: [(page: Int, start: Int, length: Int, text: String, vector: [Float])]) throws {
        lock.lock(); defer { lock.unlock() }
        try transaction {
            if let existing = document(path: path) { try removeDocument(id: existing.id) }
            let hasOCR = pages.contains { $0.isOCR }
            let docId = try run("INSERT INTO documents(path, kind, page_count, modified, indexed, has_ocr) VALUES(?,?,?,?,?,?)",
                                [.text(path), .text(kind.rawValue), .int(Int64(pages.count)),
                                 .double(modified.timeIntervalSince1970), .double(Date().timeIntervalSince1970),
                                 .int(hasOCR ? 1 : 0)])
            for p in pages {
                let lines = p.lines.flatMap { try? JSONEncoder().encode($0) }.flatMap { String(data: $0, encoding: .utf8) }
                try run("INSERT INTO pages(doc_id, page, text, lines) VALUES(?,?,?,?)",
                        [.int(docId), .int(Int64(p.page)), .text(p.text), lines.map { .text($0) } ?? .null])
            }
            for c in chunks {
                let blob = c.vector.withUnsafeBufferPointer { Data(buffer: $0) }
                let chunkId = try run("INSERT INTO chunks(doc_id, page, start, length, text, embedding) VALUES(?,?,?,?,?,?)",
                                      [.int(docId), .int(Int64(c.page)), .int(Int64(c.start)), .int(Int64(c.length)),
                                       .text(c.text), .blob(blob)])
                try run("INSERT INTO chunks_fts(text, chunk_id) VALUES(?,?)", [.text(c.text), .int(chunkId)])
            }
        }
        vectorCache = nil
    }

    public func page(docId: Int64, page: Int) -> PageContent? {
        query("SELECT page, text, lines FROM pages WHERE doc_id=? AND page=?", [.int(docId), .int(Int64(page))]) { s in
            let linesJSON = Self.text(s, 2)
            let lines = linesJSON.isEmpty ? nil : try? JSONDecoder().decode([PageLine].self, from: Data(linesJSON.utf8))
            return PageContent(page: Int(sqlite3_column_int(s, 0)), text: Self.text(s, 1), lines: lines)
        }.first
    }

    public func pages(docId: Int64) -> [PageContent] {
        query("SELECT page, text, lines FROM pages WHERE doc_id=? ORDER BY page", [.int(docId)]) { s in
            let linesJSON = Self.text(s, 2)
            let lines = linesJSON.isEmpty ? nil : try? JSONDecoder().decode([PageLine].self, from: Data(linesJSON.utf8))
            return PageContent(page: Int(sqlite3_column_int(s, 0)), text: Self.text(s, 1), lines: lines)
        }
    }

    public func chunk(id: Int64) -> Chunk? {
        query("SELECT id, doc_id, page, start, length, text FROM chunks WHERE id=?", [.int(id)], mapChunk).first
    }

    private func mapChunk(_ s: OpaquePointer?) -> Chunk {
        Chunk(id: sqlite3_column_int64(s, 0), docId: sqlite3_column_int64(s, 1), page: Int(sqlite3_column_int(s, 2)),
              start: Int(sqlite3_column_int(s, 3)), length: Int(sqlite3_column_int(s, 4)), text: Self.text(s, 5))
    }

    public var chunkCount: Int {
        query("SELECT COUNT(*) FROM chunks") { Int(sqlite3_column_int($0, 0)) }.first ?? 0
    }

    // MARK: - Search

    /// Cosine similarity against every chunk (vectors are stored normalized). Fast enough for a few thousand chunks.
    public func vectorSearch(_ queryVector: [Float], limit: Int) -> [(chunkId: Int64, score: Double)] {
        lock.lock()
        if vectorCache == nil {
            vectorCache = query("SELECT id, doc_id, embedding FROM chunks") { s in
                let data = Self.blob(s, 2)
                let vector = data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
                return (sqlite3_column_int64(s, 0), sqlite3_column_int64(s, 1), vector)
            }
        }
        let cache = vectorCache ?? []
        lock.unlock()
        var scored: [(Int64, Double)] = []
        scored.reserveCapacity(cache.count)
        for entry in cache where entry.vector.count == queryVector.count {
            var dot: Float = 0
            for i in 0..<queryVector.count { dot += entry.vector[i] * queryVector[i] }
            scored.append((entry.chunkId, Double(dot)))
        }
        return scored.sorted { $0.1 > $1.1 }.prefix(limit).map { (chunkId: $0.0, score: $0.1) }
    }

    /// English and Tagalog function words, plus "years": dates appear in every resume, so they only add noise.
    static let stopwords: Set<String> = [
        "the", "and", "for", "who", "what", "which", "whom", "whose", "how", "many", "much", "has", "have", "had",
        "with", "from", "this", "that", "are", "was", "were", "been", "does", "did", "than", "more", "least", "most",
        "year", "years", "yrs", "sino", "ano", "ang", "mga", "may", "kay", "niya", "nila", "ito", "iyan", "yung",
        "para", "kung", "lang", "din", "rin", "nga", "ilan", "saan", "kailan", "bakit", "paano", "naman", "ngayon",
    ]

    /// BM25 keyword search. The query is reduced to quoted terms OR'ed together, so user text can't break FTS syntax.
    public func keywordSearch(_ text: String, limit: Int) -> [(chunkId: Int64, score: Double)] {
        let terms = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 && !Self.stopwords.contains($0) }
        guard !terms.isEmpty else { return [] }
        let match = Set(terms).map { "\"\($0)\"" }.joined(separator: " OR ")
        return query("SELECT chunk_id, bm25(chunks_fts) FROM chunks_fts WHERE chunks_fts MATCH ? ORDER BY bm25(chunks_fts) LIMIT ?",
                     [.text(match), .int(Int64(limit))]) { s in
            (chunkId: sqlite3_column_int64(s, 0), score: -sqlite3_column_double(s, 1))
        }
    }

    // MARK: - History

    public func saveAnswer(_ a: AnswerResult) -> Int64 {
        let citations = (try? JSONEncoder().encode(a.citations)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        return (try? run("INSERT INTO history(ts, question, answer, citations, provider, model, sent) VALUES(?,?,?,?,?,?,?)",
                         [.double(a.date.timeIntervalSince1970), .text(a.question), .text(a.text), .text(citations),
                          .text(a.provider.rawValue), .text(a.model), a.sentPayload.map { .text($0) } ?? .null])) ?? 0
    }

    public func history(limit: Int = 200) -> [AnswerResult] {
        query("SELECT id, ts, question, answer, citations, provider, model, sent FROM history ORDER BY ts DESC LIMIT ?",
              [.int(Int64(limit))]) { s in
            let citations = (try? JSONDecoder().decode([Citation].self, from: Data(Self.text(s, 4).utf8))) ?? []
            let sent = Self.text(s, 7)
            return AnswerResult(id: sqlite3_column_int64(s, 0),
                                date: Date(timeIntervalSince1970: sqlite3_column_double(s, 1)),
                                question: Self.text(s, 2), text: Self.text(s, 3), citations: citations,
                                provider: ProviderKind(rawValue: Self.text(s, 5)) ?? .local, model: Self.text(s, 6),
                                sentPayload: sent.isEmpty ? nil : sent)
        }
    }

    // MARK: - Events (counts only, never content)

    public struct Event: Hashable {
        public var date: Date
        public var kind: String
        public var category: String
        public var count: Int
        public var app: String
        public var provider: String
    }

    public func logEvent(kind: String, category: String = "", count: Int = 1, app: String = "", provider: String = "") {
        _ = try? run("INSERT INTO events(ts, kind, category, count, app, provider) VALUES(?,?,?,?,?,?)",
                     [.double(Date().timeIntervalSince1970), .text(kind), .text(category), .int(Int64(count)),
                      .text(app), .text(provider)])
    }

    public func events(since: Date = .distantPast) -> [Event] {
        query("SELECT ts, kind, category, count, app, provider FROM events WHERE ts >= ? ORDER BY ts DESC",
              [.double(since.timeIntervalSince1970)]) { s in
            Event(date: Date(timeIntervalSince1970: sqlite3_column_double(s, 0)), kind: Self.text(s, 1),
                  category: Self.text(s, 2), count: Int(sqlite3_column_int(s, 3)), app: Self.text(s, 4),
                  provider: Self.text(s, 5))
        }
    }

    // MARK: - Redactions

    public struct RedactionRecord: Hashable, Identifiable {
        public var id: Int64
        public var date: Date
        public var source: String
        public var output: String
        public var counts: [String: Int]
    }

    public func saveRedaction(source: String, output: String, counts: [String: Int]) {
        let json = (try? JSONEncoder().encode(counts)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        _ = try? run("INSERT INTO redactions(ts, source, output, counts) VALUES(?,?,?,?)",
                     [.double(Date().timeIntervalSince1970), .text(source), .text(output), .text(json)])
    }

    public func redactions() -> [RedactionRecord] {
        query("SELECT id, ts, source, output, counts FROM redactions ORDER BY ts DESC") { s in
            RedactionRecord(id: sqlite3_column_int64(s, 0), date: Date(timeIntervalSince1970: sqlite3_column_double(s, 1)),
                            source: Self.text(s, 2), output: Self.text(s, 3),
                            counts: (try? JSONDecoder().decode([String: Int].self, from: Data(Self.text(s, 4).utf8))) ?? [:])
        }
    }
}
