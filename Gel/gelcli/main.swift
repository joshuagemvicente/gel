import Foundation
import GelCore

// gelcli — exercise Gel's core from the terminal.
//   gelcli index <folder>
//   gelcli search "<question>"
//   gelcli ask "<question>"
//   gelcli detect [--full] [--packs hr,personal] (<text> | --file <path>)
//   gelcli redact <file>
//   gelcli stats

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
        let folder = URL(fileURLWithPath: args[1])
        let start = Date()
        let n = try await Indexer().index(folder: folder) { p in
            if !p.current.isEmpty { print("[\(p.done + 1)/\(p.total)] \(p.current)") }
        }
        print(String(format: "Indexed %d file(s) in %.1f s · %d documents, %d chunks", n, Date().timeIntervalSince(start),
                     Store.shared.documents().count, Store.shared.chunkCount))

    case "search":
        let q = args.dropFirst().joined(separator: " ")
        for h in try await QueryEngine.shared.search(q) {
            print(String(format: "%.4f  %@ p.%d  %@", h.score, h.document.name, h.chunk.page + 1,
                         String(h.chunk.text.prefix(90)).replacingOccurrences(of: "\n", with: " ")))
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
            if let kind = DocKind.from(url: URL(fileURLWithPath: path)) {
                text = try TextExtraction.extract(url: URL(fileURLWithPath: path), kind: kind).map(\.text).joined(separator: "\n")
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
        let url = URL(fileURLWithPath: args[1])
        guard let kind = DocKind.from(url: url) else { print("unsupported file"); return }
        let text = try TextExtraction.extract(url: url, kind: kind).map(\.text).joined(separator: "\n")
        let r = await PIIDetector.shared.detectFull(text, packs: packs)
        let out = try Redactor.redactFile(url, findings: r.findings)
        print("\(r.findings.count) finding(s): \(PIIDetector.summary(r.findings))")
        print("→ \(out.output.path)")

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
