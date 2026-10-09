import Foundation
import PDFKit

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

public struct IndexResult {
    public var indexed: Int
    /// Files that couldn't be read (password-protected, corrupt…), with a short reason.
    public var failures: [(name: String, reason: String)]
}

public enum IndexError: Error, LocalizedError {
    case folderMissing(String)
    public var errorDescription: String? {
        if case .folderMissing(let p) = self { return "Folder not found: \(p)" }
        return nil
    }
}

public struct IndexProgress: Equatable {
    public var done: Int
    public var total: Int
    public var current: String
    public var isRunning: Bool { done < total }
}

/// Indexes the chosen folders: extracts text (OCR for scans), chunks it, embeds the chunks and saves everything locally.
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
        // The enumerator resolves symlinks in the folder's own path (/tmp → /private/tmp). Rebase what it returns onto
        // the folder as listed, so document paths stay under it and pruning matches.
        let given = FolderList.standardize(folder.path)
        let real = realpath(given, nil).map { p in defer { free(p) }; return String(cString: p) } ?? given
        var urls: [URL] = []
        for case var url as URL in e where DocKind.from(url: url) != nil {
            // Skip Gel's own redacted outputs so they don't get re-indexed.
            if url.pathComponents.contains("Redacted") { continue }
            if real != given, url.path.hasPrefix(real + "/") {
                url = URL(fileURLWithPath: given + url.path.dropFirst(real.count))
            }
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

    public static func folderExists(_ folder: URL) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: folder.path, isDirectory: &isDir) && isDir.boolValue
            && FileManager.default.isReadableFile(atPath: folder.path)
    }

    /// Removes documents that live outside every listed folder (after a folder is removed from the list).
    public func pruneOutside(_ folders: [URL]) {
        let paths = folders.map { FolderList.standardize($0.path) }
        for doc in store.documents() where !paths.contains(where: { FolderList.contains($0, doc.path) }) {
            try? store.removeDocument(id: doc.id)
        }
    }

    /// Removes index entries for files that no longer exist in the folder. Never runs when the folder itself is
    /// missing (unplugged drive, renamed folder), so a temporary outage can't wipe the index.
    public func pruneMissing(in folder: URL) {
        guard Self.folderExists(folder) else { return }
        let present = Set(Self.supportedFiles(in: folder).map(\.path))
        let root = FolderList.standardize(folder.path)
        for doc in store.documents() where FolderList.contains(root, doc.path) && !present.contains(doc.path) {
            try? store.removeDocument(id: doc.id)
        }
    }

    @discardableResult
    public func index(folder: URL, progress: ((IndexProgress) -> Void)? = nil) async throws -> IndexResult {
        guard Self.folderExists(folder) else { throw IndexError.folderMissing(folder.path) }
        return await index(folders: [folder], progress: progress)
    }

    /// Indexes every reachable folder in one pass, so progress counts files across all of them. A missing folder is
    /// skipped and nothing under it is pruned (E2).
    @discardableResult
    public func index(folders: [URL], progress: ((IndexProgress) -> Void)? = nil) async -> IndexResult {
        let reachable = folders.filter { Self.folderExists($0) }
        for folder in reachable { pruneMissing(in: folder) }
        let files = reachable.flatMap { pending(in: $0) }
        var failures: [(name: String, reason: String)] = []
        for (i, url) in files.enumerated() {
            progress?(IndexProgress(done: i, total: files.count, current: url.lastPathComponent))
            do { try await index(file: url) } catch {
                NSLog("Gel: failed to index \(url.lastPathComponent): \(error)")
                failures.append((url.lastPathComponent, Self.reason(for: error, url: url)))
            }
        }
        progress?(IndexProgress(done: files.count, total: files.count, current: ""))
        return IndexResult(indexed: files.count - failures.count, failures: failures)
    }

    static func reason(for error: Error, url: URL) -> String {
        if url.pathExtension.lowercased() == "pdf", let pdf = PDFDocument(url: url), pdf.isLocked { return "password-protected" }
        if error is TextExtraction.ExtractionError { return "unreadable or corrupt" }
        if error is LLMError || (error as NSError).domain == NSURLErrorDomain { return "embedding failed (is Ollama running?)" }
        return "couldn't be read"
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
