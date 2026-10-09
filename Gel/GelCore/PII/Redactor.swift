import Foundation
import PDFKit
import AppKit
import Vision

/// What a redaction writes in place of a value (R5, D-073). The cloud gate always uses placeholders.
public enum RedactionMode: String, Codable, CaseIterable, Sendable {
    /// Black boxes on pages, `[SSS_1]` placeholders in text.
    case blackout
    /// Type-aware fakes from `DummyData`, drawn into white boxes on pages.
    case dummy

    public var label: String { self == .blackout ? "Black out" : "Replace with dummy data" }
    /// For the Redactions list and records.
    public var recordLabel: String { self == .blackout ? "blacked out" : "dummy data" }
}

public enum Redactor {

    public struct TextResult {
        public var text: String
        /// Placeholder (or fake) → original value. Stays in memory on this Mac; never sent anywhere.
        public var mapping: [String: String]
        public var counts: [String: Int]
    }

    /// Replaces each finding with a consistent placeholder, e.g. every occurrence of one SSS number → [SSS_1].
    /// In `.dummy` mode each value becomes its fake from `replacements` (lowercased value → fake); values without
    /// one get a fresh fake, so the result is still consistent within this text.
    public static func redactText(_ text: String, findings: [Finding], mode: RedactionMode = .blackout,
                                  replacements: [String: String] = [:]) -> TextResult {
        let ns = NSMutableString(string: text)
        var valueToken: [String: String] = [:]
        var perType: [String: Int] = [:]
        var mapping: [String: String] = [:]
        var counts: [String: Int] = [:]
        let fakes = mode == .dummy ? DummyData.replacements(for: findings, existing: replacements) : [:]
        // Assign numbers in reading order, then replace from the end so ranges stay valid.
        for f in findings.sorted(by: { $0.range.location < $1.range.location }) {
            let key = f.type + "|" + f.text.lowercased()
            if valueToken[key] == nil {
                perType[f.type, default: 0] += 1
                let token = mode == .dummy ? (fakes[f.text.lowercased()] ?? "[\(f.type)_\(perType[f.type]!)]")
                    : "[\(f.type)_\(perType[f.type]!)]"
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
    /// `.dummy` mode draws fakes instead (white box + text on pages, fake values in text); pass the same
    /// `replacements` the preview used so the saved copy equals what was shown.
    public static func redactFile(_ url: URL, findings: [Finding], keep: Set<String> = [], mode: RedactionMode = .blackout,
                                  replacements: [String: String] = [:]) throws -> FileResult {
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
            let result = redactText(text, findings: PIIDetector.merge(located), mode: mode, replacements: replacements)
            let out = outputURL(for: url, ext: "txt")
            try result.text.write(to: out, atomically: true, encoding: .utf8)
            return FileResult(output: out, counts: counts)

        case .image, .pdf:
            // Same renderer as the review screen's "After" page, so the saved copy is exactly what was previewed.
            let pages = try renderPages(url, findings: findings, keep: keep, mode: mode, replacements: replacements)
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
    public static func renderPages(_ url: URL, findings: [Finding], keep: Set<String> = [], mode: RedactionMode = .blackout,
                                   replacements: [String: String] = [:]) throws -> [RenderedPage] {
        guard let kind = DocKind.from(url: url) else { throw TextExtraction.ExtractionError.unreadable(url.lastPathComponent) }
        let values = Array(Set(findings.map(\.text))).sorted { $0.count > $1.count }
        let replacements = mode == .dummy ? DummyData.replacements(for: findings, existing: replacements) : replacements
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
            return RenderedPage(index: index, size: size, original: image,
                                redacted: redactedImage(original: image, boxes: boxes, keep: keep, mode: mode, replacements: replacements),
                                boxes: boxes)
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

    /// The "After" image for a page: black boxes on every box whose value isn't in `keep`, or in `.dummy` mode a
    /// white box with the value's fake drawn in. Fast (no OCR), so the review screen can call it on every toggle.
    /// A value with several boxes on the page (a name wrapped over two lines) gets its fake split across them in
    /// reading order.
    public static func redactedImage(original: CGImage, boxes: [RenderedPage.Box], keep: Set<String>,
                                     mode: RedactionMode = .blackout, replacements: [String: String] = [:]) -> CGImage {
        let w = CGFloat(original.width), h = CGFloat(original.height)
        let active = boxes.filter { !keep.contains($0.value.lowercased()) }
        func pixelRect(_ b: RenderedPage.Box) -> CGRect {
            CGRect(x: b.rect.minX * w, y: (1 - b.rect.maxY) * h, width: b.rect.width * w, height: b.rect.height * h)
        }
        guard mode == .dummy else { return draw(boxes: active.map { (pixelRect($0), nil) }, on: original) }
        var out: [(rect: CGRect, text: String?)] = []
        for (key, group) in Dictionary(grouping: active, by: { $0.value.lowercased() }) {
            guard let fake = replacements[key] else { out += group.map { (pixelRect($0), nil) }; continue }
            // The text layer and OCR usually box the same words with slightly different edges: merge boxes that
            // overlap, so one occurrence gets one white box and one fake (not a second box over the text).
            var merged: [CGRect] = []
            for b in group.map(pixelRect) {
                if let i = merged.firstIndex(where: { r in
                    let x = r.intersection(b)
                    return x.width > 0.5 * min(r.width, b.width) && x.height > 0.5 * min(r.height, b.height)
                }) {
                    merged[i] = merged[i].union(b)
                } else {
                    merged.append(b)
                }
            }
            // Reading order in pixel space (bottom-left origin): top-to-bottom, then left-to-right.
            let ordered = merged.sorted { ($0.maxY, -$0.minX) > ($1.maxY, -$1.minX) }
            if ordered.count == 1 {
                out.append((ordered[0], fake))
            } else {
                let words = fake.split(separator: " ").map(String.init)
                let per = max(1, Int((Double(words.count) / Double(ordered.count)).rounded(.up)))
                for (i, rect) in ordered.enumerated() {
                    out.append((rect, words.dropFirst(i * per).prefix(per).joined(separator: " ")))
                }
            }
        }
        return draw(boxes: out, on: original)
    }

    /// OCR the image, box every occurrence of each value (word-precise via Vision), and flatten black boxes.
    static func burn(image: CGImage, values: [String]) throws -> CGImage {
        draw(boxes: try ocrBoxes(image: image, values: values).map { ($0.0, nil) }, on: image)
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

    /// Flattens boxes into the image: a black box when `text` is nil, otherwise a white box with `text` drawn in a
    /// system font fitted to the box height (shrunk, then truncated with an ellipsis, when it is too wide).
    static func draw(boxes: [(rect: CGRect, text: String?)], on image: CGImage) -> CGImage {
        let w = image.width, h = image.height
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return image }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        // Fills first, text last, so a neighbouring box can never paint over a fake already drawn.
        for (rect, text) in boxes {
            ctx.setFillColor(text == nil ? NSColor.black.cgColor : NSColor.white.cgColor)
            ctx.fill(rect.insetBy(dx: -3, dy: -3))
        }
        for (rect, text) in boxes {
            if let text, !text.isEmpty { drawText(text, in: rect, on: ctx) }
        }
        return ctx.makeImage() ?? image
    }

    private static func drawText(_ text: String, in rect: CGRect, on ctx: CGContext) {
        let maxWidth = max(rect.width - 4, 4)
        var size = max(rect.height * 0.72, 6)
        func line(_ size: CGFloat) -> CTLine {
            let font = CTFontCreateWithName("Helvetica" as CFString, size, nil)
            let attributed = NSAttributedString(string: text, attributes: [
                .font: font, .foregroundColor: NSColor.black.cgColor,
            ])
            return CTLineCreateWithAttributedString(attributed)
        }
        var ctLine = line(size)
        var width = CGFloat(CTLineGetTypographicBounds(ctLine, nil, nil, nil))
        if width > maxWidth {
            size = max(size * maxWidth / width, rect.height * 0.4)
            ctLine = line(size)
            width = CGFloat(CTLineGetTypographicBounds(ctLine, nil, nil, nil))
            if width > maxWidth, let truncated = CTLineCreateTruncatedLine(ctLine, Double(maxWidth), .end, nil) {
                ctLine = truncated
            }
        }
        var ascent: CGFloat = 0, descent: CGFloat = 0
        _ = CTLineGetTypographicBounds(ctLine, &ascent, &descent, nil)
        ctx.saveGState()
        ctx.textMatrix = .identity
        ctx.textPosition = CGPoint(x: rect.minX + 2, y: rect.midY - (ascent - descent) / 2)
        CTLineDraw(ctLine, ctx)
        ctx.restoreGState()
    }
}
