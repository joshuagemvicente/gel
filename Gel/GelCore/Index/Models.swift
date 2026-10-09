import Foundation
import CoreGraphics

public enum DocKind: String, Codable, CaseIterable {
    case pdf, image, docx, text

    public static func from(url: URL) -> DocKind? {
        switch url.pathExtension.lowercased() {
        case "pdf": return .pdf
        case "jpg", "jpeg", "png", "heic", "tif", "tiff": return .image
        case "docx": return .docx
        case "txt", "md": return .text
        default: return nil
        }
    }

    public var label: String {
        switch self {
        case .pdf: return "PDF"
        case .image: return "Scan"
        case .docx: return "DOCX"
        case .text: return "Text"
        }
    }
}

public struct DocumentRecord: Identifiable, Hashable, Codable {
    public var id: Int64
    public var path: String
    public var kind: DocKind
    public var pageCount: Int
    public var modifiedAt: Date
    public var indexedAt: Date
    /// True when at least one page had no text layer and was read with OCR.
    public var hasOCR: Bool

    public var url: URL { URL(fileURLWithPath: path) }
    public var name: String { url.lastPathComponent }
}

/// One OCR'd line with its position. `rect` is normalized (0–1) with a bottom-left origin, as Vision reports it.
public struct PageLine: Codable, Hashable {
    public var text: String
    public var rect: CGRect
    /// Offset of this line's first character within the page text.
    public var start: Int
}

public struct PageContent: Codable, Hashable {
    public var page: Int
    public var text: String
    public var lines: [PageLine]?
    public var isOCR: Bool { lines != nil }
}

public struct Chunk: Hashable, Codable {
    public var id: Int64
    public var docId: Int64
    public var page: Int
    public var start: Int
    public var length: Int
    public var text: String
}

public struct SearchHit: Hashable {
    public var chunk: Chunk
    public var document: DocumentRecord
    public var score: Double
}

public struct Citation: Codable, Hashable, Identifiable {
    /// The number shown in the answer, e.g. 1 for "[1]".
    public var id: Int
    public var docId: Int64
    public var path: String
    public var page: Int
    public var start: Int
    public var length: Int
    public var snippet: String

    public var fileName: String { URL(fileURLWithPath: path).lastPathComponent }
    public var label: String {
        let base = (fileName as NSString).deletingPathExtension
        return "\(id) · \(base) p.\(page + 1)"
    }
}

public enum ProviderKind: String, Codable {
    case local, cloud
}

public struct AnswerResult: Codable, Hashable, Identifiable {
    public var id: Int64
    public var date: Date
    public var question: String
    public var text: String
    public var citations: [Citation]
    public var provider: ProviderKind
    public var model: String
    /// The exact (redacted) prompt sent to the cloud, for the "What was sent" view. Nil for local answers.
    public var sentPayload: String?
}
