import Foundation
import PDFKit
import AppKit
import Vision

public enum Redactor {

    public struct TextResult {
        public var text: String
        /// Placeholder → original value. Stays in memory on this Mac; never sent anywhere.
        public var mapping: [String: String]
        public var counts: [String: Int]
    }

    /// Replaces each finding with a consistent placeholder, e.g. every occurrence of one SSS number → [SSS_1].
    public static func redactText(_ text: String, findings: [Finding]) -> TextResult {
        let ns = NSMutableString(string: text)
        var valueToken: [String: String] = [:]
        var perType: [String: Int] = [:]
        var mapping: [String: String] = [:]
        var counts: [String: Int] = [:]
        // Assign numbers in reading order, then replace from the end so ranges stay valid.
        for f in findings.sorted(by: { $0.range.location < $1.range.location }) {
            let key = f.type + "|" + f.text.lowercased()
            if valueToken[key] == nil {
                perType[f.type, default: 0] += 1
                let token = "[\(f.type)_\(perType[f.type]!)]"
                valueToken[key] = token
                mapping[token] = f.text
            }
            counts[f.category, default: 0] += 1
        }
        for f in findings.sorted(by: { $0.range.location > $1.range.location }) {
            guard f.range.location + f.range.length <= ns.length else { continue }
            ns.replaceCharacters(in: f.range, with: valueToken[f.type + "|" + f.text.lowercased()] ?? "[REDACTED]")
        }
        return TextResult(text: ns as String, mapping: mapping, counts: counts)
    }

    /// The gate in front of every cloud call (no LLM, no network). It takes no pack argument on purpose: text that
    /// leaves the Mac is screened by **every** installed pack, not the active ones, plus the fast name layer, the
    /// strict name pass and bare dates (D-072). Returns the placeholder → value mapping too, so a cloud answer can
    /// be shown with real values locally; the mapping never leaves the Mac.
    public static func cloudGate(_ text: String) throws -> TextResult {
        let detector = PIIDetector.shared
        let fast = detector.detectFast(text, packs: detector.packStore.allPackIds)
        let strict = detector.strictNameFindings(text) + detector.strictDateFindings(text)
        return redactText(text, findings: PIIDetector.mergeStrict(fast + strict, in: text))
    }

    /// `cloudGate` without the mapping.
    public static func cloudSafe(_ text: String) throws -> String {
        try cloudGate(text).text
    }

    /// Swaps placeholders back to real values (longest tokens first so [NAME_12] isn't hit by [NAME_1]).
    public static func rehydrate(_ text: String, mapping: [String: String]) -> String {
        var out = text
        for (token, value) in mapping.sorted(by: { $0.key.count > $1.key.count }) {
            out = out.replacingOccurrences(of: token, with: value)
        }
        return out
    }

    // MARK: - Burned-in PDF

    public struct FileResult {
        public var output: URL
        public var counts: [String: Int]
    }

    public static func outputURL(for source: URL, ext: String) -> URL {
        let dir = source.deletingLastPathComponent().appendingPathComponent("Redacted", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let base = source.deletingPathExtension().lastPathComponent + "_REDACTED"
        var url = dir.appendingPathComponent(base + "." + ext)
        var n = 2
        while FileManager.default.fileExists(atPath: url.path) {
            url = dir.appendingPathComponent("\(base)-\(n).\(ext)")
            n += 1
        }
        return url
    }

    /// Redacts a file. PDFs and scans become an image-only PDF with black boxes flattened into each page, so the
    /// original text can't be recovered. DOCX/TXT become a text file with placeholders.
    /// `keep` lets the user un-tick findings in the preview (matched by text, case-insensitive).
    public static func redactFile(_ url: URL, findings: [Finding], keep: Set<String> = []) throws -> FileResult {
        let active = findings.filter { !keep.contains($0.text.lowercased()) }
        let values = Array(Set(active.map(\.text))).sorted { $0.count > $1.count }
        let counts = Dictionary(grouping: active, by: \.category).mapValues(\.count)
        guard let kind = DocKind.from(url: url) else { throw TextExtraction.ExtractionError.unreadable(url.lastPathComponent) }

        switch kind {
        case .docx, .text:
            let pages = try TextExtraction.extract(url: url, kind: kind)
            let text = pages.map(\.text).joined(separator: "\n")
            // Keep each finding's real type ([SSS_1], not [OTHER_1]) when locating values in the joined text.
            var typeFor: [String: Finding] = [:]
            for f in active where typeFor[f.text.lowercased()] == nil { typeFor[f.text.lowercased()] = f }
            let located = values.flatMap { v -> [Finding] in
                let f = typeFor[v.lowercased()]
                return PIIDetector.locate(v, in: text, type: "OTHER", layer: 1).map { found in
                    var g = found
                    if let f { g.type = f.type; g.label = f.label; g.category = f.category }
                    return g
                }
            }
            let result = redactText(text, findings: PIIDetector.merge(located))
            let out = outputURL(for: url, ext: "txt")
            try result.text.write(to: out, atomically: true, encoding: .utf8)
            return FileResult(output: out, counts: counts)

        case .image, .pdf:
            // Same renderer as the review screen's "After" page, so the saved copy is exactly what was previewed.
            let pages = try renderPages(url, findings: findings, keep: keep)
            let out = PDFDocument()
            for p in pages {
                if let page = PDFPage(image: NSImage(cgImage: p.redacted, size: NSSize(width: p.size.width, height: p.size.height))) {
                    out.insert(page, at: out.pageCount)
                }
            }
            let outURL = outputURL(for: url, ext: "pdf")
            guard out.write(to: outURL) else { throw TextExtraction.ExtractionError.unreadable(outURL.lastPathComponent) }
            return FileResult(output: outURL, counts: counts)
        }
    }

    // MARK: - Preview (Before | After)

    /// One page for the review screen: the original, the redacted copy, and where every finding is.
    public struct RenderedPage: Identifiable {
        public struct Box: Hashable {
            /// Normalized 0–1 with a top-left origin (ready for a SwiftUI overlay).
            public var rect: CGRect
            /// The `Finding.text` that produced this box (match by `value.lowercased()`, like `keep`).
            public var value: String
            public var category: String
            public var label: String
            public var kept: Bool
        }
        public var id: Int { index }
        public var index: Int
        /// Page size in points.
        public var size: CGSize
        public var original: CGImage
        public var redacted: CGImage
        public var boxes: [Box]
    }

    /// Renders every page of a PDF or image with boxes for **all** findings (`kept` marks the unticked ones) and the
    /// redacted image with only the ticked ones blacked out. DOCX/TXT have no pages: returns [].
    public static func renderPages(_ url: URL, findings: [Finding], keep: Set<String> = []) throws -> [RenderedPage] {
        guard let kind = DocKind.from(url: url) else { throw TextExtraction.ExtractionError.unreadable(url.lastPathComponent) }
        let values = Array(Set(findings.map(\.text))).sorted { $0.count > $1.count }
        var info: [String: Finding] = [:]
        for f in findings where info[f.text.lowercased()] == nil { info[f.text.lowercased()] = f }
        func page(_ index: Int, image: CGImage, size: CGSize, pixelBoxes: [(CGRect, String)]) -> RenderedPage {
            let w = CGFloat(image.width), h = CGFloat(image.height)
            var seen = Set<String>()
            var boxes: [RenderedPage.Box] = []
            for (r, v) in pixelBoxes {
                let key = "\(Int(r.minX))-\(Int(r.minY))-\(Int(r.width))-\(v)"
                guard seen.insert(key).inserted else { continue }
                let f = info[v.lowercased()]
                boxes.append(.init(rect: CGRect(x: r.minX / w, y: 1 - r.maxY / h, width: r.width / w, height: r.height / h),
                                   value: v, category: f?.category ?? "other", label: f?.label ?? "personal detail",
                                   kept: keep.contains(v.lowercased())))
            }
            return RenderedPage(index: index, size: size, original: image, redacted: redactedImage(original: image, boxes: boxes, keep: keep), boxes: boxes)
        }
        switch kind {
        case .docx, .text:
            return []
        case .image:
            guard let image = TextExtraction.loadImage(url: url) else { throw TextExtraction.ExtractionError.unreadable(url.lastPathComponent) }
            let size = CGSize(width: CGFloat(image.width) / 2, height: CGFloat(image.height) / 2)
            return [page(0, image: image, size: size, pixelBoxes: try ocrBoxes(image: image, values: values))]
        case .pdf:
            guard let pdf = PDFDocument(url: url), !pdf.isLocked else { throw TextExtraction.ExtractionError.unreadable(url.lastPathComponent) }
            let scale: CGFloat = 2
            var pages: [RenderedPage] = []
            for i in 0..<pdf.pageCount {
                guard let pdfPage = pdf.page(at: i), let image = TextExtraction.render(page: pdfPage, scale: scale) else { continue }
                let bounds = pdfPage.bounds(for: .mediaBox)
                var boxes: [(CGRect, String)] = []
                let pageText = pdfPage.string ?? ""
                if !pageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // Text layer: locate each value with PDFKit selections.
                    let ns = pageText as NSString
                    for v in values {
                        var search = NSRange(location: 0, length: ns.length)
                        while true {
                            let r = ns.range(of: v, options: .caseInsensitive, range: search)
                            if r.location == NSNotFound { break }
                            if let sel = pdfPage.selection(for: r) {
                                for line in sel.selectionsByLine() {
                                    let b = line.bounds(for: pdfPage)
                                    boxes.append((CGRect(x: (b.minX - bounds.minX) * scale, y: (b.minY - bounds.minY) * scale,
                                                         width: b.width * scale, height: b.height * scale), v))
                                }
                            }
                            let next = r.location + r.length
                            search = NSRange(location: next, length: ns.length - next)
                        }
                    }
                }
                // Always OCR too: a scan with a small text stamp has most of its text only in pixels (Q1).
                boxes += try ocrBoxes(image: image, values: values)
                pages.append(page(i, image: image, size: bounds.size, pixelBoxes: boxes))
            }
            return pages
        }
    }

    /// The "After" image for a page: black boxes on every box whose value isn't in `keep`. Fast (no OCR), so the
    /// review screen can call it on every toggle.
    public static func redactedImage(original: CGImage, boxes: [RenderedPage.Box], keep: Set<String>) -> CGImage {
        let w = CGFloat(original.width), h = CGFloat(original.height)
        let rects = boxes.filter { !keep.contains($0.value.lowercased()) }.map {
            CGRect(x: $0.rect.minX * w, y: (1 - $0.rect.maxY) * h, width: $0.rect.width * w, height: $0.rect.height * h)
        }
        return draw(boxes: rects, on: original)
    }

    /// OCR the image, box every occurrence of each value (word-precise via Vision), and flatten black boxes.
    static func burn(image: CGImage, values: [String]) throws -> CGImage {
        draw(boxes: try ocrBoxes(image: image, values: values).map(\.0), on: image)
    }

    /// Pixel-space boxes (bottom-left origin) for every occurrence of each value, word-precise via Vision.
    static func ocrBoxes(image: CGImage, values: [String]) throws -> [(CGRect, String)] {
        let w = CGFloat(image.width), h = CGFloat(image.height)
        var rects: [(CGRect, String)] = []
        for line in try OCR.recognizeLines(image) {
            let lineText = line.candidate.string
            for v in values {
                for part in v.components(separatedBy: "\n") where part.count >= 2 {
                    var searchStart = lineText.startIndex
                    while let r = lineText.range(of: part, options: .caseInsensitive, range: searchStart..<lineText.endIndex) {
                        // Whole words only: a fragment like "Team" must not black out part of "team of 5".
                        let before = r.lowerBound > lineText.startIndex ? lineText[lineText.index(before: r.lowerBound)] : " "
                        let after = r.upperBound < lineText.endIndex ? lineText[r.upperBound] : " "
                        let wholeWord = !(before.isLetter || before.isNumber) && !(after.isLetter || after.isNumber)
                        if wholeWord, part.count >= 3, let box = try? line.candidate.boundingBox(for: r)?.boundingBox {
                            rects.append((CGRect(x: box.minX * w, y: box.minY * h, width: box.width * w, height: box.height * h), v))
                        }
                        searchStart = r.upperBound
                    }
                }
            }
        }
        return rects
    }

    static func draw(boxes: [CGRect], on image: CGImage) -> CGImage {
        let w = image.width, h = image.height
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return image }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        ctx.setFillColor(NSColor.black.cgColor)
        for r in boxes { ctx.fill(r.insetBy(dx: -3, dy: -3)) }
        return ctx.makeImage() ?? image
    }
}
