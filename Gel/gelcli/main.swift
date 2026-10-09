import Foundation
import GelCore

// gelcli — exercise Gel's core from the terminal.
//   gelcli index <folder>
//   gelcli search "<question>"
//   gelcli ask "<question>"
//   gelcli detect [--full] [--packs hr,personal] (<text> | --file <path>)
//   gelcli redact <file>
//   gelcli stats
//   gelcli check <ground_truth.json>   recall of fast redaction per data type (text-layer files + scans)

let args = Array(CommandLine.arguments.dropFirst())
guard let command = args.first else {
    print("usage: gelcli index|search|ask|detect|redact|stats …")
    exit(1)
}

func value(after flag: String) -> String? {
    guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
    return args[i + 1]
}

let packs = value(after: "--packs")?.components(separatedBy: ",") ?? GelSettings.shared.activePacks

func run() async throws {
    switch command {
    case "index":
        guard args.count > 1 else { print("gelcli index <folder>"); return }
        let folder = URL(fileURLWithPath: args[1]).standardizedFileURL
        let start = Date()
        let n = try await Indexer().index(folder: folder) { p in
            if !p.current.isEmpty { print("[\(p.done + 1)/\(p.total)] \(p.current)") }
        }
        print(String(format: "Indexed %d file(s) in %.1f s · %d documents, %d chunks", n, Date().timeIntervalSince(start),
                     Store.shared.documents().count, Store.shared.chunkCount))

    case "search":
        let q = args.dropFirst().joined(separator: " ")
        for (i, src) in try await QueryEngine.shared.search(q).enumerated() {
            print(String(format: "[%d] %.4f  %@", i + 1, src.score, src.document.name))
            for h in src.passages {
                print(String(format: "      p.%d  %@", h.chunk.page + 1, String(h.chunk.text.prefix(80)).replacingOccurrences(of: "\n", with: " ")))
            }
        }

    case "ask":
        let q = args.dropFirst().joined(separator: " ")
        let start = Date()
        var first: Date?
        let answer = try await QueryEngine.shared.ask(q) { token in
            if first == nil { first = Date() }
            FileHandle.standardOutput.write(token.data(using: .utf8)!)
        }
        print("\n---")
        print("provider: \(answer.provider.rawValue) · model: \(answer.model)")
        print(String(format: "first token: %.1f s · total: %.1f s", (first ?? Date()).timeIntervalSince(start), Date().timeIntervalSince(start)))
        for c in answer.citations { print("  [\(c.id)] \(c.fileName) page \(c.page + 1)") }
        if let sent = answer.sentPayload { print("\nSENT TO CLOUD:\n\(sent)") }

    case "detect":
        var text = args.dropFirst().filter { !$0.hasPrefix("--") }.joined(separator: " ")
        if let path = value(after: "--file") {
            let fileURL = URL(fileURLWithPath: path).standardizedFileURL
            if let kind = DocKind.from(url: fileURL) {
                text = try TextExtraction.extract(url: fileURL, kind: kind).map(\.text).joined(separator: "\n")
            } else {
                text = try String(contentsOfFile: path, encoding: .utf8)
            }
        }
        let start = Date()
        let findings: [Finding]
        if args.contains("--full") {
            let r = await PIIDetector.shared.detectFull(text, packs: packs)
            findings = r.findings
            print("LLM pass: \(r.llmProvider?.rawValue ?? "unavailable")")
        } else {
            findings = PIIDetector.shared.detectFast(text, packs: packs)
        }
        print(String(format: "%d finding(s) in %.0f ms — %@", findings.count, Date().timeIntervalSince(start) * 1000,
                     PIIDetector.summary(findings)))
        for f in findings { print("  L\(f.layer) \(f.type.padding(toLength: 16, withPad: " ", startingAt: 0)) \(f.text)") }
        print("\nRedacted:\n" + Redactor.redactText(text, findings: findings).text)

    case "redact":
        guard args.count > 1 else { print("gelcli redact <file>"); return }
        let url = URL(fileURLWithPath: args[1]).standardizedFileURL
        guard let kind = DocKind.from(url: url) else { print("unsupported file"); return }
        let text = try TextExtraction.extract(url: url, kind: kind).map(\.text).joined(separator: "\n")
        let r = await PIIDetector.shared.detectFull(text, packs: packs)
        let out = try Redactor.redactFile(url, findings: r.findings)
        print("\(r.findings.count) finding(s): \(PIIDetector.summary(r.findings))")
        print("→ \(out.output.path)")

    case "check":
        guard args.count > 1 else { print("gelcli check <ground_truth.json>"); return }
        let gtURL = URL(fileURLWithPath: args[1]).standardizedFileURL
        let base = gtURL.deletingLastPathComponent()
        guard let obj = try JSONSerialization.jsonObject(with: Data(contentsOf: gtURL)) as? [String: Any],
              let entities = obj["entities"] as? [[String: Any]] else { print("bad ground truth"); return }
        let scans = (obj["scans"] as? [[String: Any]]) ?? []
        let checkPacks = value(after: "--packs")?.components(separatedBy: ",") ?? ["hr", "personal"]
        func squash(_ s: String) -> String { s.components(separatedBy: .whitespacesAndNewlines).joined(separator: " ") }
        // file -> redacted text (fast layers only)
        var cache: [String: String] = [:]
        func redacted(_ rel: String) -> String? {
            if let c = cache[rel] { return c }
            let url = base.appendingPathComponent(rel)
            guard let kind = DocKind.from(url: url), let pages = try? TextExtraction.extract(url: url, kind: kind) else { return nil }
            let text = pages.map(\.text).joined(separator: "\n")
            let out = squash(Redactor.redactText(text, findings: PIIDetector.shared.detectFast(text, packs: checkPacks)).text)
            cache[rel] = out
            return out
        }
        var byType: [String: (total: Int, removed: Int, misses: [String])] = [:]
        func record(_ type: String, _ value: String, _ text: String?, _ where_: String) {
            guard let text else { return }
            var e = byType[type] ?? (0, 0, [])
            e.total += 1
            if text.localizedCaseInsensitiveContains(squash(value)) { e.misses.append("\(value)  (\(where_))") } else { e.removed += 1 }
            byType[type] = e
        }
        for ent in entities {
            guard let file = ent["file"] as? String, let type = ent["type"] as? String, let v = ent["value"] as? String else { continue }
            record(type, v, redacted(file), (file as NSString).lastPathComponent)
        }
        // Scans: the source file's values should also be gone from the scan's OCR text.
        var scanTotals = (total: 0, removed: 0)
        for sc in scans {
            guard let scan = sc["scan"] as? String, let source = sc["source"] as? String, let text = redacted(scan) else { continue }
            for ent in entities where (ent["file"] as? String) == source {
                guard let v = ent["value"] as? String, let type = ent["type"] as? String, type != "NAME" else { continue }
                // OCR may read ₱ as P; compare digits-only for money and IDs.
                let digits = v.filter(\.isNumber)
                let present = digits.count >= 6 ? text.filter(\.isNumber).contains(digits) : text.localizedCaseInsensitiveContains(v)
                scanTotals.total += 1
                if !present { scanTotals.removed += 1 }
            }
        }
        print("type".padding(toLength: 18, withPad: " ", startingAt: 0) + "removed/total  recall")
        for (type, e) in byType.sorted(by: { $0.key < $1.key }) {
            print(type.padding(toLength: 18, withPad: " ", startingAt: 0) + String(format: "%4d/%-4d    %5.1f%%", e.removed, e.total, 100 * Double(e.removed) / Double(max(e.total, 1))))
        }
        print(String(format: "SCANS (non-name)  %4d/%-4d    %5.1f%%", scanTotals.removed, scanTotals.total, 100 * Double(scanTotals.removed) / Double(max(scanTotals.total, 1))))
        if args.contains("--misses") {
            for (type, e) in byType.sorted(by: { $0.key < $1.key }) where !e.misses.isEmpty {
                print("\n\(type) misses:"); e.misses.prefix(8).forEach { print("  \($0)") }
            }
        }

    case "stats":
        let t = DPOReport.totals()
        print("documents: \(Store.shared.documents().count), chunks: \(Store.shared.chunkCount)")
        print("leaks caught: \(t.leaksCaught), items protected: \(t.itemsProtected), redactions: \(t.redactions)")
        print("answers local/cloud: \(t.localAnswers)/\(t.cloudAnswers)")

    default:
        print("unknown command \(command)")
    }
}

let done = DispatchSemaphore(value: 0)
Task {
    do { try await run() } catch { print("error: \(error.localizedDescription)") }
    done.signal()
}
done.wait()
