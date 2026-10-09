// Verification helper for demo-data (macOS only, no dependencies).
//   swift scripts/extract_text.swift pdf <file.pdf>...   -> PDFKit text layer per page
//   swift scripts/extract_text.swift ocr <image>...      -> Apple Vision OCR (accurate)
import AppKit
import Foundation
import PDFKit
import Vision

let args = Array(CommandLine.arguments.dropFirst())
guard let mode = args.first, ["pdf", "ocr"].contains(mode), args.count > 1 else {
    print("usage: extract_text.swift pdf|ocr <files...>")
    exit(2)
}

for path in args.dropFirst() {
    let url = URL(fileURLWithPath: path)
    if mode == "pdf" {
        guard let doc = PDFDocument(url: url) else { print("!! cannot open \(path)"); continue }
        for i in 0..<doc.pageCount {
            let text = doc.page(at: i)?.string ?? ""
            print("=== \(url.lastPathComponent) page \(i + 1) (\(text.count) chars)")
            print(text)
        }
    } else {
        guard let image = NSImage(contentsOf: url),
              let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("!! cannot open \(path)"); continue
        }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        try VNImageRequestHandler(cgImage: cg).perform([request])
        print("=== OCR \(url.lastPathComponent)")
        for obs in request.results ?? [] {
            print(obs.topCandidates(1).first?.string ?? "")
        }
    }
}
