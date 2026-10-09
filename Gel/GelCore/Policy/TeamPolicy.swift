import Foundation
import AppKit

/// Organization-managed settings, read from Application Support/Gel/policy.json (later deployed via MDM).
public struct TeamPolicy: Codable, Equatable {
    public var organization: String
    /// Packs that are always on and can't be turned off.
    public var requiredPacks: [String]?
    /// Bundle IDs Leak Guard watches. Nil = Gel's default list.
    public var watchedApps: [String]?
    /// Data type id or category → "warn" or "block".
    public var actions: [String: String]?
    public var allowCloudFallback: Bool?

    public static func load(from url: URL = GelPaths.policy) -> TeamPolicy? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(TeamPolicy.self, from: data)
    }

    public func action(for finding: Finding) -> String {
        actions?[finding.type] ?? actions?[finding.category] ?? "warn"
    }

    public func blocks(_ findings: [Finding]) -> Bool {
        findings.contains { action(for: $0) == "block" }
    }

    public static let sample = TeamPolicy(
        organization: "Bayanihan Outsourcing Corp.",
        requiredPacks: ["hr"],
        watchedApps: nil,
        actions: ["government ID": "block", "salary": "block", "bank account": "block"],
        allowCloudFallback: true)
}

public enum LeakGuardDefaults {
    public static let watchedApps: [String: String] = [
        "com.google.Chrome": "Chrome",
        "com.apple.Safari": "Safari",
        "company.thebrowser.Browser": "Arc",
        "com.microsoft.edgemac": "Edge",
        "com.brave.Browser": "Brave",
        "org.mozilla.firefox": "Firefox",
        "com.openai.chat": "ChatGPT",
        "com.anthropic.claudefordesktop": "Claude",
        // Chat apps where people paste work data (bundle IDs not all verified on this Mac; see D-042).
        "com.tinyspeck.slackmacgap": "Slack",
        "com.microsoft.teams2": "Microsoft Teams",
        "com.microsoft.teams": "Microsoft Teams",
        "com.facebook.archon.developerID": "Messenger",
        "ru.keepcoder.Telegram": "Telegram",
        "org.telegram.desktop": "Telegram",
        "com.viber.osx": "Viber",
        "net.whatsapp.WhatsApp": "WhatsApp",
        "com.hnc.Discord": "Discord",
    ]
}

/// Counts-only report for the organization's Data Protection Officer.
public enum DPOReport {
    public static func csv(since: Date, store: Store = .shared) -> String {
        let events = store.events(since: since)
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withFullDate]
        var rows = ["date,event,category,app,provider,count"]
        let grouped = Dictionary(grouping: events) { e in
            [df.string(from: e.date), e.kind, e.category, e.app, e.provider].joined(separator: "|")
        }
        for (key, list) in grouped.sorted(by: { $0.key > $1.key }) {
            let parts = key.components(separatedBy: "|")
            let total = list.reduce(0) { $0 + ($1.kind == "cloud_call" ? 1 : $1.count) }
            rows.append((parts.map { "\"\($0)\"" } + ["\(total)"]).joined(separator: ","))
        }
        return rows.joined(separator: "\n") + "\n"
    }

    public struct Totals {
        public var leaksCaught = 0
        public var itemsProtected = 0
        public var redactions = 0
        public var localAnswers = 0
        public var cloudAnswers = 0
        public var byCategory: [String: Int] = [:]
        public init() {}
        public var localShare: Double {
            let total = localAnswers + cloudAnswers
            return total == 0 ? 1 : Double(localAnswers) / Double(total)
        }
    }

    public static func totals(since: Date = .distantPast, store: Store = .shared) -> Totals {
        var t = Totals()
        for e in store.events(since: since) {
            switch e.kind {
            case "leak_caught": t.leaksCaught += 1
            case "leak_item": t.itemsProtected += e.count; t.byCategory[e.category, default: 0] += e.count
            case "redaction_item": t.itemsProtected += e.count; t.byCategory[e.category, default: 0] += e.count
            case "redaction": t.redactions += 1
            case "query": if e.provider == "cloud" { t.cloudAnswers += 1 } else { t.localAnswers += 1 }
            default: break
            }
        }
        return t
    }

    /// Writes the CSV plus a one-page PDF summary into Application Support/Gel/Reports and returns both URLs.
    public static func export(since: Date, organization: String?) throws -> [URL] {
        let stamp = ISO8601DateFormatter().string(from: Date()).prefix(10)
        let csvURL = GelPaths.reports.appendingPathComponent("Gel-DPO-report-\(stamp).csv")
        try csv(since: since).write(to: csvURL, atomically: true, encoding: .utf8)

        let t = totals(since: since)
        let df = DateFormatter()
        df.dateStyle = .medium
        var lines = [
            "Gel · Data Protection Officer report",
            organization.map { "Organization: \($0)" } ?? "Organization: (not managed)",
            "Period: \(df.string(from: since)) to \(df.string(from: Date()))",
            "",
            "Leaks caught before reaching an AI app: \(t.leaksCaught)",
            "Personal-data items kept on device: \(t.itemsProtected)",
            "Files redacted: \(t.redactions)",
            "Answers generated on this Mac: \(t.localAnswers)",
            "Answers via cloud fallback (redacted input only): \(t.cloudAnswers)",
            "",
            "By category:",
        ]
        for (k, v) in t.byCategory.sorted(by: { $0.value > $1.value }) { lines.append("  \(k): \(v)") }
        lines += ["", "This report contains counts only. It never includes document content, file names or clipboard text."]
        let pdfURL = GelPaths.reports.appendingPathComponent("Gel-DPO-report-\(stamp).pdf")
        try writePDF(lines: lines, to: pdfURL)
        return [csvURL, pdfURL]
    }

    static func writePDF(lines: [String], to url: URL) throws {
        var box = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let ctx = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
        ctx.beginPDFPage(nil)
        let ns = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ns
        var y: CGFloat = 730
        for (i, line) in lines.enumerated() {
            let font = i == 0 ? NSFont.boldSystemFont(ofSize: 18) : NSFont.systemFont(ofSize: 12)
            (line as NSString).draw(at: CGPoint(x: 56, y: y), withAttributes: [.font: font, .foregroundColor: NSColor.black])
            y -= i == 0 ? 30 : 18
        }
        NSGraphicsContext.restoreGraphicsState()
        ctx.endPDFPage()
        ctx.closePDF()
    }
}
