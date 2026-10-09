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

    /// The gate in front of every cloud call: pattern + name detection (no LLM, no network), then placeholders.
    public static func cloudSafe(_ text: String, packs: [String] = GelSettings.shared.activePacks) throws -> String {
        try cloudSafeWithMapping(text, packs: packs).text
    }

    /// Same gate, also returning the placeholder → value mapping so a cloud answer can be shown with real values
    /// locally. The mapping never leaves the Mac.
    public static func cloudSafeWithMapping(_ text: String, packs: [String] = GelSettings.shared.activePacks) throws -> TextResult {
        redactText(text, findings: PIIDetector.shared.detectFast(text, packs: packs))
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

        case .image:
            guard let image = TextExtraction.loadImage(url: url) else { throw TextExtraction.ExtractionError.unreadable(url.lastPathComponent) }
            let redacted = try burn(image: image, values: values)
            let doc = PDFDocument()
            let size = NSSize(width: CGFloat(image.width) / 2, height: CGFloat(image.height) / 2)
            if let page = PDFPage(image: NSImage(cgImage: redacted, size: size)) { doc.insert(page, at: 0) }
            let out = outputURL(for: url, ext: "pdf")
            guard doc.write(to: out) else { throw TextExtraction.ExtractionError.unreadable(out.lastPathComponent) }
            return FileResult(output: out, counts: counts)

        case .pdf:
            guard let pdf = PDFDocument(url: url) else { throw TextExtraction.ExtractionError.unreadable(url.lastPathComponent) }
            let out = PDFDocument()
            let scale: CGFloat = 2
            for i in 0..<pdf.pageCount {
                guard let page = pdf.page(at: i), let image = TextExtraction.render(page: page, scale: scale) else { continue }
                let bounds = page.bounds(for: .mediaBox)
                let pageText = page.string ?? ""
                let burned: CGImage
                if pageText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 20 {
                    // Text layer: locate each value with PDFKit selections.
                    var rects: [CGRect] = []
                    let ns = pageText as NSString
                    for v in values {
                        var search = NSRange(location: 0, length: ns.length)
                        while true {
                            let r = ns.range(of: v, options: .caseInsensitive, range: search)
                            if r.location == NSNotFound { break }
                            if let sel = page.selection(for: r) {
                                for line in sel.selectionsByLine() {
                                    let b = line.bounds(for: page)
                                    rects.append(CGRect(x: (b.minX - bounds.minX) * scale, y: (b.minY - bounds.minY) * scale,
                                                        width: b.width * scale, height: b.height * scale))
                                }
                            }
                            let next = r.location + r.length
                            search = NSRange(location: next, length: ns.length - next)
                        }
                    }
                    burned = draw(boxes: rects, on: image)
                } else {
                    burned = try burn(image: image, values: values)
                }
                if let newPage = PDFPage(image: NSImage(cgImage: burned, size: NSSize(width: bounds.width, height: bounds.height))) {
                    out.insert(newPage, at: out.pageCount)
                }
            }
            let outURL = outputURL(for: url, ext: "pdf")
            guard out.write(to: outURL) else { throw TextExtraction.ExtractionError.unreadable(outURL.lastPathComponent) }
            return FileResult(output: outURL, counts: counts)
        }
    }

    /// OCR the image, box every occurrence of each value (word-precise via Vision), and flatten black boxes.
    static func burn(image: CGImage, values: [String]) throws -> CGImage {
        let w = CGFloat(image.width), h = CGFloat(image.height)
        var rects: [CGRect] = []
        for line in try OCR.recognizeLines(image) {
            let lineText = line.candidate.string
            for v in values {
                for part in v.components(separatedBy: "\n") where part.count >= 2 {
                    var searchStart = lineText.startIndex
                    while let r = lineText.range(of: part, options: .caseInsensitive, range: searchStart..<lineText.endIndex) {
                        if let box = try? line.candidate.boundingBox(for: r)?.boundingBox {
                            rects.append(CGRect(x: box.minX * w, y: box.minY * h, width: box.width * w, height: box.height * h))
                        }
                        searchStart = r.upperBound
                    }
                }
            }
        }
        return draw(boxes: rects, on: image)
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
