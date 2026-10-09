import Foundation
import PDFKit
import Vision
import AppKit
import ImageIO

/// Pulls text out of PDFs, scans and DOCX files. Pages without a text layer are rendered and read with Vision OCR,
/// keeping each line's position so citations and redactions can be drawn on the page later.
public enum TextExtraction {
    /// Pages with fewer non-space text-layer characters than this are also OCR'd (Q1).
    public static let minTextLayerChars = 200

    public static func extract(url: URL, kind: DocKind) throws -> [PageContent] {
        switch kind {
        case .pdf: return try extractPDF(url: url)
        case .image:
            guard let image = loadImage(url: url) else { throw ExtractionError.unreadable(url.lastPathComponent) }
            let (text, lines) = try OCR.recognize(image)
            return [PageContent(page: 0, text: text, lines: lines)]
        case .docx:
            let attributed = try NSAttributedString(url: url, options: [.documentType: NSAttributedString.DocumentType.officeOpenXML],
                                                    documentAttributes: nil)
            return [PageContent(page: 0, text: attributed.string, lines: nil)]
        case .text:
            return [PageContent(page: 0, text: try String(contentsOf: url, encoding: .utf8), lines: nil)]
        }
    }

    public enum ExtractionError: Error, LocalizedError {
        case unreadable(String)
        public var errorDescription: String? {
            if case .unreadable(let name) = self { return "Couldn't read \(name)" }
            return nil
        }
    }

    static func extractPDF(url: URL) throws -> [PageContent] {
        guard let pdf = PDFDocument(url: url), !pdf.isLocked else { throw ExtractionError.unreadable(url.lastPathComponent) }
        var pages: [PageContent] = []
        for i in 0..<pdf.pageCount {
            guard let page = pdf.page(at: i) else { continue }
            let text = page.string ?? ""
            let textChars = text.filter { !$0.isWhitespace }.count
            if textChars >= minTextLayerChars {
                pages.append(PageContent(page: i, text: text, lines: nil))
            } else if let image = render(page: page, scale: 2) {
                // Scans often carry a tiny text layer ("Scanned with CamScanner"); OCR them anyway and keep both.
                let (ocrText, ocrLines) = try OCR.recognize(image)
                if textChars == 0 {
                    pages.append(PageContent(page: i, text: ocrText, lines: ocrLines))
                } else {
                    let prefix = text + "\n"
                    let shift = (prefix as NSString).length
                    let lines = ocrLines.map { PageLine(text: $0.text, rect: $0.rect, start: $0.start + shift) }
                    pages.append(PageContent(page: i, text: prefix + ocrText, lines: lines))
                }
            } else {
                pages.append(PageContent(page: i, text: text, lines: nil))
            }
        }
        return pages
    }

    public static func loadImage(url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [kCGImageSourceCreateThumbnailWithTransform: true,
                                        kCGImageSourceCreateThumbnailFromImageAlways: true,
                                        kCGImageSourceThumbnailMaxPixelSize: 4000]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
            ?? CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    /// Renders a PDF page to a bitmap at `scale` × its point size (white background).
    public static func render(page: PDFPage, scale: CGFloat) -> CGImage? {
        let bounds = page.bounds(for: .mediaBox)
        let width = Int(bounds.width * scale), height = Int(bounds.height * scale)
        guard width > 0, height > 0,
              let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        ctx.scaleBy(x: scale, y: scale)
        ctx.translateBy(x: -bounds.minX, y: -bounds.minY)
        page.draw(with: .mediaBox, to: ctx)
        return ctx.makeImage()
    }
}

public enum OCR {
    /// One recognized line plus the Vision candidate, so callers can ask for sub-range boxes (used by redaction).
    public struct Line {
        public var text: String
        public var rect: CGRect
        public var candidate: VNRecognizedText
    }

    public static func recognizeLines(_ image: CGImage) throws -> [Line] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let supported = (try? request.supportedRecognitionLanguages()) ?? []
        request.recognitionLanguages = ["en-US"] + supported.filter { $0.hasPrefix("fil") }
        try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
        let observations = request.results ?? []
        // Sort top-to-bottom, then left-to-right, so the page text reads naturally.
        let sorted = observations.sorted { a, b in
            if abs(a.boundingBox.midY - b.boundingBox.midY) > 0.01 { return a.boundingBox.midY > b.boundingBox.midY }
            return a.boundingBox.minX < b.boundingBox.minX
        }
        return sorted.compactMap { obs in
            guard let top = obs.topCandidates(1).first else { return nil }
            return Line(text: top.string, rect: obs.boundingBox, candidate: top)
        }
    }

    public static func recognize(_ image: CGImage) throws -> (String, [PageLine]) {
        var text = ""
        var lines: [PageLine] = []
        for line in try recognizeLines(image) {
            lines.append(PageLine(text: line.text, rect: line.rect, start: (text as NSString).length))
            text += line.text + "\n"
        }
        return (text, lines)
    }
}

/// Splits page text into overlapping chunks, keeping character offsets (in UTF-16 units, matching NSString/PDFKit).
public enum Chunker {
    public static func chunks(for text: String, target: Int = 700, overlap: Int = 120) -> [(start: Int, length: Int)] {
        let ns = text as NSString
        let total = ns.length
        guard total > 0 else { return [] }
        var result: [(Int, Int)] = []
        var start = 0
        while start < total {
            var end = min(start + target, total)
            if end < total {
                // Prefer to break at a newline, then a space, in the last 30% of the window.
                let window = NSRange(location: start + target * 7 / 10, length: end - (start + target * 7 / 10))
                let newline = ns.range(of: "\n", options: .backwards, range: window)
                let space = ns.range(of: " ", options: .backwards, range: window)
                if newline.location != NSNotFound { end = newline.location + 1 }
                else if space.location != NSNotFound { end = space.location + 1 }
            }
            let piece = ns.substring(with: NSRange(location: start, length: end - start))
            if !piece.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                result.append((start, end - start))
            }
            if end >= total { break }
            start = max(end - overlap, start + 1)
        }
        return result
    }
}
