import Foundation

/// Calls Ollama's embedding endpoint. Vectors are L2-normalized so the store can use a plain dot product.
public final class Embedder {
    public var baseURL: String
    public var model: String

    public init(baseURL: String = GelSettings.shared.localBaseURL, model: String = GelSettings.shared.embedModel) {
        self.baseURL = baseURL
        self.model = model
    }

    public func embed(_ texts: [String]) async throws -> [[Float]] {
        guard !texts.isEmpty else { return [] }
        var request = URLRequest(url: URL(string: baseURL + "/api/embed")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120
        request.httpBody = try JSONSerialization.data(withJSONObject: ["model": model, "input": texts, "keep_alive": "60m"])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200,
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let raw = json["embeddings"] as? [[Double]] else {
            throw LLMError.badResponse(String(data: data, encoding: .utf8) ?? "embedding failed")
        }
        return raw.map { v in
            let f = v.map { Float($0) }
            let norm = sqrt(f.reduce(0) { $0 + $1 * $1 })
            return norm > 0 ? f.map { $0 / norm } : f
        }
    }
}

public struct IndexProgress: Equatable {
    public var done: Int
    public var total: Int
    public var current: String
    public var isRunning: Bool { done < total }
}

/// Indexes one folder: extracts text (OCR for scans), chunks it, embeds the chunks and saves everything locally.
public final class Indexer {
    public let store: Store
    public let embedder: Embedder

    public init(store: Store = .shared, embedder: Embedder = Embedder()) {
        self.store = store
        self.embedder = embedder
    }

    public static func supportedFiles(in folder: URL) -> [URL] {
        guard let e = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: [.contentModificationDateKey],
                                                     options: [.skipsHiddenFiles]) else { return [] }
        var urls: [URL] = []
        for case let url as URL in e where DocKind.from(url: url) != nil {
            // Skip Gel's own redacted outputs so they don't get re-indexed.
            if url.pathComponents.contains("Redacted") { continue }
            urls.append(url)
        }
        return urls.sorted { $0.path < $1.path }
    }

    private static func modified(_ url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
    }

    /// Returns the files that are new or changed since they were last indexed.
    public func pending(in folder: URL) -> [URL] {
        Self.supportedFiles(in: folder).filter { url in
            guard let doc = store.document(path: url.path) else { return true }
            return abs(doc.modifiedAt.timeIntervalSince(Self.modified(url))) > 1
        }
    }

    /// Removes index entries for files that no longer exist in the folder.
    public func pruneMissing(in folder: URL) {
        let present = Set(Self.supportedFiles(in: folder).map(\.path))
        for doc in store.documents() where doc.path.hasPrefix(folder.path) && !present.contains(doc.path) {
            try? store.removeDocument(id: doc.id)
        }
    }

    public func index(folder: URL, progress: ((IndexProgress) -> Void)? = nil) async throws -> Int {
        pruneMissing(in: folder)
        let files = pending(in: folder)
        for (i, url) in files.enumerated() {
            progress?(IndexProgress(done: i, total: files.count, current: url.lastPathComponent))
            do { try await index(file: url) } catch { NSLog("Gel: failed to index \(url.lastPathComponent): \(error)") }
        }
        progress?(IndexProgress(done: files.count, total: files.count, current: ""))
        return files.count
    }

    public func index(file url: URL) async throws {
        guard let kind = DocKind.from(url: url) else { return }
        let pages = try TextExtraction.extract(url: url, kind: kind)
        var pieces: [(page: Int, start: Int, length: Int, text: String)] = []
        for page in pages {
            let ns = page.text as NSString
            for c in Chunker.chunks(for: page.text) {
                pieces.append((page.page, c.start, c.length, ns.substring(with: NSRange(location: c.start, length: c.length))))
            }
        }
        // Embed with the file name and page as light context; store the raw text.
        var vectors: [[Float]] = []
        let batchSize = 16
        for batchStart in stride(from: 0, to: pieces.count, by: batchSize) {
            let batch = pieces[batchStart..<min(batchStart + batchSize, pieces.count)]
            let inputs = batch.map { "File: \(url.lastPathComponent) (page \($0.page + 1))\n\($0.text)" }
            vectors += try await embedder.embed(inputs)
        }
        let chunks = zip(pieces, vectors).map { (page: $0.page, start: $0.start, length: $0.length, text: $0.text, vector: $1) }
        try store.save(path: url.path, kind: kind, modified: Self.modified(url), pages: pages, chunks: chunks)
    }
}
