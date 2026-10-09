import SwiftUI
import GelCore

struct RedactionsView: View {
    @EnvironmentObject var state: AppState
    @State private var records: [Store.RedactionRecord] = []
    @State private var leaks: [LeakLog.Entry] = []
    @State private var since = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    @State private var exportError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ModuleHeader(title: "Redactions & Leak Guard", subtitle: "Counts only. Gel never stores what you copied.")
                SectionLabel(text: "Redacted files").padding(.top, 6)
                if records.isEmpty {
                    Card {
                        HStack(spacing: 10) {
                            IconChip(symbol: "eye.slash", tint: Theme.textSecondary, background: Theme.hairline.opacity(0.6))
                            Text("No redactions yet. Select files in Library and click Redact.").foregroundStyle(Theme.textSecondary)
                        }
                    }
                } else {
                    Card(padding: 6) {
                        VStack(spacing: 0) {
                            ForEach(records) { r in
                                HStack(spacing: 12) {
                                    IconChip(symbol: "doc.badge.checkmark", size: 24)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(URL(fileURLWithPath: r.source).lastPathComponent) → \(URL(fileURLWithPath: r.output).lastPathComponent)")
                                            .font(.system(size: 12.5)).lineLimit(1).truncationMode(.middle)
                                        Text((RedactionMode(rawValue: r.mode) ?? .blackout).recordLabel + " · "
                                             + r.counts.sorted { $0.value > $1.value }.map { "\($0.value) \($0.key)" }.joined(separator: ", "))
                                            .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                                    }
                                    Spacer()
                                    Text(r.date, style: .time).font(.system(size: 11).monospacedDigit()).foregroundStyle(Theme.textSecondary)
                                    Button("Open") { NSWorkspace.shared.open(URL(fileURLWithPath: r.output)) }.buttonStyle(.gelSecondary)
                                    Button { NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: r.output)]) } label: {
                                        Image(systemName: "magnifyingglass")
                                    }
                                    .buttonStyle(.gelSecondary).help("Reveal in Finder")
                                }
                                .padding(.horizontal, 10).padding(.vertical, 8)
                                .hoverHighlight()
                                if r.id != records.last?.id { Divider().overlay(Theme.hairline).padding(.leading, 46) }
                            }
                        }
                    }
                }
                SectionLabel(text: "Leak Guard log").padding(.top, 10)
                if leaks.isEmpty {
                    Card {
                        HStack(spacing: 10) {
                            IconChip(symbol: "checkmark.shield")
                            Text("No leaks caught yet.").foregroundStyle(Theme.textSecondary)
                        }
                    }
                } else {
                    Card(padding: 6) {
                        VStack(spacing: 0) {
                            ForEach(leaks) { l in
                                HStack(spacing: 12) {
                                    IconChip(symbol: "exclamationmark.shield", tint: Theme.danger, background: Theme.dangerSoft, size: 24)
                                    Text(l.app).font(.system(size: 12.5, weight: .medium)).frame(width: 90, alignment: .leading)
                                    Text(l.summary).font(.system(size: 12)).foregroundStyle(Theme.textSecondary).lineLimit(1)
                                    Spacer()
                                    Text(l.date, style: .time).font(.system(size: 11).monospacedDigit()).foregroundStyle(Theme.textSecondary)
                                }
                                .padding(.horizontal, 10).frame(height: 40)
                                .hoverHighlight()
                                if l.id != leaks.last?.id { Divider().overlay(Theme.hairline).padding(.leading, 46) }
                            }
                        }
                    }
                }
                SectionLabel(text: "Report for your Data Protection Officer").padding(.top, 10)
                Card {
                    HStack(spacing: 12) {
                        IconChip(symbol: "doc.text.below.ecg")
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Counts-only compliance report").font(.system(size: 13, weight: .medium))
                            Text("No document text, file names or clipboard content.").font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        DatePicker("Since", selection: $since, displayedComponents: .date).frame(width: 200)
                        Button("Export report") { export() }.buttonStyle(.gelPrimary)
                    }
                    if let exportError { Text(exportError).foregroundStyle(Theme.danger).font(.system(size: 11)) }
                }
            }
            .padding(28)
        }
        .onAppear(perform: reload)
        .onChange(of: state.activityVersion) { _, _ in reload() }
    }

    private func reload() {
        records = Store.shared.redactions()
        leaks = LeakLog.entries()
    }

    private func export() {
        do {
            let urls = try DPOReport.export(since: since, organization: state.policy?.organization)
            NSWorkspace.shared.activateFileViewerSelecting(urls)
            exportError = nil
        } catch {
            exportError = error.localizedDescription
        }
    }
}

/// Library → Redact: scan selected files (all three layers), review findings, then write burned-in outputs.
struct RedactSheet: View {
    let urls: [URL]
    @Environment(\.dismiss) private var dismiss

    struct FileScan: Identifiable {
        let id = UUID()
        var url: URL
        var findings: [Finding]
        var provider: ProviderKind?
        /// Extracted text, kept for "Add something Gel missed" (R6).
        var text: String
        /// Lowercased value → fake, fixed when the scan finishes so After and the saved copy agree (R5).
        var replacements: [String: String]
    }

    @State private var scans: [FileScan] = []
    @State private var mode: RedactionMode = .blackout
    @State private var current = ""
    @State private var unticked = Set<String>()
    @State private var outputs: [URL] = []
    @State private var phase = 0 // 0 scanning, 1 review, 2 writing, 3 done
    @State private var error: String?
    @State private var task: Task<Void, Never>?
    @State private var summary = RedactReview.Summary()

    private var aiCaption: String {
        let providers = Set(scans.compactMap(\.provider))
        if providers.contains(.cloud) { return "Checked by patterns and name detection on this Mac; the AI check ran via the cloud fallback (redacted text)." }
        if providers.contains(.local) { return "Checked on this Mac by patterns, name detection and the local AI." }
        return phase == 0 ? "Checking on this Mac…" : "AI check unavailable — review the list manually."
    }

    private var fileWord: String { "\(scans.count) file\(scans.count == 1 ? "" : "s")" }
    private var copyWord: String { "\(scans.count) cop\(scans.count == 1 ? "y" : "ies")" }
    private var itemWord: String { "\(summary.blackOut) item\(summary.blackOut == 1 ? "" : "s")" }

    private var title: AttributedString {
        switch phase {
        case 0: return AttributedString("Scanning \(urls.count) file\(urls.count == 1 ? "" : "s")")
        case 1, 2:
            guard summary.ready else { return AttributedString("Preparing the preview…") }
            let verb = mode == .dummy ? "replace" : "black out"
            let tail = mode == .dummy ? " with dummy data" : ""
            return (try? AttributedString(markdown: "Gel will \(verb) **\(summary.blackOut) of \(summary.total)** items in \(fileWord)\(tail).")) ?? AttributedString("")
        default: return AttributedString("Redaction complete")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                IconChip(symbol: phase == 3 ? "checkmark.seal" : "eye.slash", size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 18, weight: phase == 1 || phase == 2 ? .regular : .semibold))
                    if phase == 1 || phase == 2 {
                        Text("Untick anything you want to keep visible. Your original files are never changed; redacted copies are saved to a Redacted folder.")
                            .font(.system(size: 12)).foregroundStyle(Theme.textPrimary)
                    }
                    Text(aiCaption).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
            ZStack {
                switch phase {
                case 0: scanningList.transition(.opacity)
                case 1, 2:
                    RedactReview(files: scans.map { .init(url: $0.url, findings: $0.findings, replacements: $0.replacements) },
                                 unticked: $unticked, summary: $summary, mode: $mode, disabled: phase == 2,
                                 onAdd: addMissed)
                default: doneView.transition(.rise(6))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            if let error { Text(error).foregroundStyle(Theme.danger).font(.system(size: 11)) }
            HStack {
                Text("Originals are never changed.").font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                Spacer()
                if phase == 2 { ProgressView().controlSize(.small) }
                Button(phase == 3 ? "Done" : "Cancel") { task?.cancel(); dismiss() }
                    .buttonStyle(phase == 3 ? .gelPrimary : .gelSecondary)
                    .keyboardShortcut(phase == 3 ? .defaultAction : .cancelAction)
                if phase == 1 {
                    Button("\(mode == .dummy ? "Replace" : "Black out") \(itemWord) · Save \(copyWord)") { write() }
                        .buttonStyle(.gelPrimary)
                        .keyboardShortcut(.defaultAction)
                        .disabled(!summary.ready || scans.isEmpty)
                }
            }
        }
        .padding(24)
        .frame(minWidth: 1040, idealWidth: 1120, minHeight: 720, idealHeight: 860)
        .background(Theme.canvas)
        .animation(Motion.smooth, value: phase)
        .onAppear(perform: scan)
    }

    private var scanningList: some View {
        VStack(alignment: .leading, spacing: 10) {
            GelProgressBar(value: Double(scans.count), total: Double(urls.count))
            Card(padding: 6) {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(urls, id: \.self) { url in
                            let done = scans.contains { $0.url == url }
                            HStack(spacing: 10) {
                                ZStack {
                                    if done {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.accent).transition(.popIn)
                                    } else if url.lastPathComponent == current {
                                        ProgressView().controlSize(.small).transition(.opacity)
                                    } else {
                                        Image(systemName: "circle").foregroundStyle(Theme.hairline)
                                    }
                                }
                                .frame(width: 18)
                                Text(url.lastPathComponent).font(.system(size: 12.5)).lineLimit(1).truncationMode(.middle)
                                    .foregroundStyle(done || url.lastPathComponent == current ? Theme.textPrimary : Theme.textSecondary)
                                Spacer()
                                if let s = scans.first(where: { $0.url == url }) {
                                    Text("\(s.findings.count) found").font(.system(size: 11).monospacedDigit()).foregroundStyle(Theme.textSecondary)
                                        .transition(.opacity)
                                }
                            }
                            .padding(.horizontal, 10).frame(height: 32)
                            .animation(Motion.pop, value: done)
                        }
                    }
                }
            }
        }
    }

    private var doneView: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44)).foregroundStyle(Theme.accent)
                .padding(.top, 24)
            Text("Saved \(outputs.count) redacted file\(outputs.count == 1 ? "" : "s"). Originals are unchanged.")
                .font(.system(size: 14, weight: .medium))
            Card(padding: 6) {
                VStack(spacing: 0) {
                    ForEach(Array(outputs.enumerated()), id: \.element) { i, u in
                        HStack(spacing: 10) {
                            IconChip(symbol: "doc.badge.checkmark", size: 24)
                            Text(u.lastPathComponent).font(.system(size: 12.5)).lineLimit(1).truncationMode(.middle)
                            Spacer()
                            Button("Reveal in Finder") { NSWorkspace.shared.activateFileViewerSelecting([u]) }.buttonStyle(.gelSecondary)
                        }
                        .padding(.horizontal, 10).frame(height: 40)
                        .staggeredAppear(i, rise: 6)
                    }
                }
            }
            .frame(maxWidth: 520)
        }
        .frame(maxWidth: .infinity)
    }

    private func scan() {
        task = Task {
            for url in urls {
                if Task.isCancelled { return }
                current = url.lastPathComponent
                guard let kind = DocKind.from(url: url),
                      let pages = try? TextExtraction.extract(url: url, kind: kind) else { continue }
                let text = pages.map(\.text).joined(separator: "\n")
                let result = await PIIDetector.shared.detectFull(text)
                scans.append(FileScan(url: url, findings: result.findings, provider: result.llmProvider, text: text,
                                      replacements: DummyData.replacements(for: result.findings)))
            }
            phase = 1
        }
    }

    /// R6: literal matches first, then the local model, on every file in the sheet. Never the cloud.
    private func addMissed(_ query: String) async -> RedactReview.AddOutcome {
        var added = 0
        var unavailable = false
        for i in scans.indices {
            let s = scans[i]
            let literal = PIIDetector.customFindings(query, in: s.text)
            let prompted = await PIIDetector.shared.promptFindings(query, in: s.text)
            if prompted == nil { unavailable = true }
            let before = Set(s.findings.map { $0.text.lowercased() })
            let merged = PIIDetector.merge(s.findings + literal + (prompted ?? []))
            added += Set(merged.map { $0.text.lowercased() }).subtracting(before).count
            let replacements = DummyData.replacements(for: merged, existing: s.replacements)
            await MainActor.run {
                guard i < scans.count else { return }
                scans[i].findings = merged
                scans[i].replacements = replacements
            }
        }
        return RedactReview.AddOutcome(added: added, modelUnavailable: unavailable)
    }

    private func write() {
        phase = 2
        Task {
            for s in scans {
                do {
                    let r = try Redactor.redactFile(s.url, findings: s.findings, keep: unticked, mode: mode, replacements: s.replacements)
                    outputs.append(r.output)
                    Store.shared.saveRedaction(source: s.url.path, output: r.output.path, counts: r.counts, mode: mode.rawValue)
                    Store.shared.logEvent(kind: "redaction")
                    for (category, n) in r.counts { Store.shared.logEvent(kind: "redaction_item", category: category, count: n) }
                } catch {
                    self.error = "Couldn't redact \(s.url.lastPathComponent): \(error.localizedDescription)"
                }
            }
            NotificationCenter.default.post(name: .gelActivityChanged, object: nil)
            phase = 3
        }
    }
}
