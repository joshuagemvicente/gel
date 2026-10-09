# F1 · Indexing — Interfaces

All in `GelCore` (`Gel/GelCore/Index/`).

## Exposed

```swift
public enum DocKind: String, Codable, CaseIterable { case pdf, image, docx, text
    public static func from(url: URL) -> DocKind?          // by extension; nil = unsupported
    public var label: String }                              // "PDF", "Scan", "DOCX", "Text"

public enum TextExtraction {
    public static func extract(url: URL, kind: DocKind) throws -> [PageContent]
    public static func loadImage(url: URL) -> CGImage?
    public static func render(page: PDFPage, scale: CGFloat) -> CGImage?   // white background
}

public enum OCR {
    public struct Line { public var text: String; public var rect: CGRect; public var candidate: VNRecognizedText }
    public static func recognizeLines(_ image: CGImage) throws -> [Line]   // top-to-bottom, left-to-right
    public static func recognize(_ image: CGImage) throws -> (String, [PageLine])
}

public enum Chunker {
    public static func chunks(for text: String, target: Int = 700, overlap: Int = 120) -> [(start: Int, length: Int)]
}

public final class Embedder {
    public init(baseURL: String = GelSettings.shared.localBaseURL, model: String = GelSettings.shared.embedModel)
    public func embed(_ texts: [String]) async throws -> [[Float]]          // L2-normalized
}

public struct IndexProgress: Equatable { public var done: Int; public var total: Int; public var current: String; public var isRunning: Bool }

public final class Indexer {
    public init(store: Store = .shared, embedder: Embedder = Embedder())
    public static func supportedFiles(in folder: URL) -> [URL]            // skips hidden files and "Redacted" folders
    public func pending(in folder: URL) -> [URL]                          // new or modification date changed
    public func pruneMissing(in folder: URL)
    public func index(folder: URL, progress: ((IndexProgress) -> Void)? = nil) async throws -> Int
    public func index(file url: URL) async throws
}
```

Store calls used here (`Store.swift`): `save(path:kind:modified:pages:chunks:)`, `document(path:)`, `documents()`, `removeDocument(id:)`, `page(docId:page:)`, `pages(docId:)`, `chunk(id:)`, `chunkCount`.

## Data types

```swift
public struct PageContent { public var page: Int; public var text: String; public var lines: [PageLine]?; public var isOCR: Bool }
public struct PageLine    { public var text: String; public var rect: CGRect; public var start: Int }
public struct Chunk       { public var id: Int64; public var docId: Int64; public var page: Int; public var start: Int; public var length: Int; public var text: String }
public struct DocumentRecord { public var id: Int64; public var path: String; public var kind: DocKind; public var pageCount: Int
                               public var modifiedAt: Date; public var indexedAt: Date; public var hasOCR: Bool }
```

## Invariants

- `page` is 0-based. `start`/`length` are UTF-16 offsets into that page's `text`.
- `PageLine.rect` is normalized (0–1), bottom-left origin (Vision convention). `PageLine.start` is the line's offset in the page text; lines are joined with `"\n"`.
- Stored vectors are L2-normalized Float32 (cosine = dot product).
- `Store.save` replaces a document's pages and chunks atomically and invalidates the vector cache.

## Callers

`gelcli index`; the app's folder rescan and Settings → Reindex ([app-shell](../app-shell/spec.md), [settings](../settings/spec.md)); [onboarding](../onboarding/spec.md). Consumers of the data: [query-citations](../query-citations/interfaces.md), [library-viewer](../library-viewer/spec.md), [detection-redaction](../detection-redaction/interfaces.md) (`TextExtraction`, `OCR`).
