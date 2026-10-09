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
                ModuleHeader(title: "Redactions & Leak Guard")
                Text("Redacted files").font(.system(size: 13, weight: .semibold))
                if records.isEmpty {
                    Card { Text("No redactions yet. Select files in Library and click Redact.").foregroundStyle(Theme.textSecondary) }
                } else {
                    Card(padding: 0) {
                        VStack(spacing: 0) {
                            ForEach(records) { r in
                                HStack {
                                    Text(r.date, style: .time).font(.system(size: 11)).foregroundStyle(Theme.textSecondary).frame(width: 64, alignment: .leading)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(URL(fileURLWithPath: r.source).lastPathComponent) → \(URL(fileURLWithPath: r.output).lastPathComponent)")
                                            .font(.system(size: 12.5)).lineLimit(1).truncationMode(.middle)
                                        Text(r.counts.sorted { $0.value > $1.value }.map { "\($0.value) \($0.key)" }.joined(separator: ", "))
                                            .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                                    }
                                    Spacer()
                                    Button("Open") { NSWorkspace.shared.open(URL(fileURLWithPath: r.output)) }
                                    Button("Reveal") { NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: r.output)]) }
                                }
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                Divider().overlay(Theme.hairline)
                            }
                        }
                    }
                }
                Text("Leak Guard log").font(.system(size: 13, weight: .semibold)).padding(.top, 8)
                Text("Counts only. Gel never stores what you copied.").font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                if leaks.isEmpty {
                    Card { Text("No leaks caught yet.").foregroundStyle(Theme.textSecondary) }
                } else {
                    Card(padding: 0) {
                        VStack(spacing: 0) {
                            ForEach(leaks) { l in
                                HStack {
                                    Text(l.date, style: .time).font(.system(size: 11)).foregroundStyle(Theme.textSecondary).frame(width: 64, alignment: .leading)
                                    Text(l.app).font(.system(size: 12.5, weight: .medium)).frame(width: 90, alignment: .leading)
                                    Text(l.summary).font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 16).frame(height: 38)
                                Divider().overlay(Theme.hairline)
                            }
                        }
                    }
                }
                Text("Report for your Data Protection Officer").font(.system(size: 13, weight: .semibold)).padding(.top, 8)
                Card {
                    HStack {
                        DatePicker("Since", selection: $since, displayedComponents: .date).frame(width: 220)
                        Spacer()
                        Button("Export report") { export() }.buttonStyle(.borderedProminent).tint(Theme.accent)
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
    }

    @State private var scans: [FileScan] = []
    @State private var current = ""
    @State private var unticked = Set<String>()
    @State private var outputs: [URL] = []
    @State private var phase = 0 // 0 scanning, 1 review, 2 writing, 3 done
    @State private var error: String?
    @State private var task: Task<Void, Never>?

    private var allFindings: [(file: URL, finding: Finding)] {
        scans.flatMap { s in s.findings.map { (s.url, $0) } }
    }

    private var byCategory: [(String, [(file: URL, finding: Finding)])] {
        Dictionary(grouping: allFindings, by: { $0.finding.category }).sorted { $0.value.count > $1.value.count }
    }

    private var aiCaption: String {
        let providers = Set(scans.compactMap(\.provider))
        if providers.contains(.cloud) { return "AI check: via cloud fallback (redacted text)" }
        if providers.contains(.local) { return "AI check: on this Mac" }
        return phase == 0 ? "AI check: running on this Mac…" : "AI check: unavailable — review manually"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Redact \(urls.count) file\(urls.count == 1 ? "" : "s")").font(.system(size: 18, weight: .semibold))
            HStack {
                if phase == 0 {
                    ProgressView(value: Double(scans.count), total: Double(urls.count)).frame(width: 200)
                    Text("Scanning \(current) (\(min(scans.count + 1, urls.count)) of \(urls.count))").font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text(aiCaption).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            }
            if phase >= 1 && phase < 3 {
                List {
                    ForEach(byCategory, id: \.0) { category, items in
                        Section("\(category.uppercased()) · \(items.count)") {
                            ForEach(Array(uniqueValues(items).enumerated()), id: \.offset) { _, item in
                                Toggle(isOn: Binding(get: { !unticked.contains(item.value.lowercased()) },
                                                     set: { on in if on { unticked.remove(item.value.lowercased()) } else { unticked.insert(item.value.lowercased()) } })) {
                                    HStack {
                                        Text(item.value).font(.system(size: 12, design: .monospaced)).lineLimit(1)
                                        Spacer()
                                        Text(item.label).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                                        Text(item.file).font(.system(size: 11)).foregroundStyle(Theme.textSecondary).lineLimit(1).frame(width: 160, alignment: .trailing)
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(minHeight: 300)
            }
            if phase == 3 {
                Text("Saved \(outputs.count) redacted file\(outputs.count == 1 ? "" : "s"). Originals are unchanged.").foregroundStyle(Theme.accent)
                ForEach(outputs, id: \.self) { u in
                    HStack {
                        Text(u.lastPathComponent).font(.system(size: 12))
                        Spacer()
                        Button("Reveal in Finder") { NSWorkspace.shared.activateFileViewerSelecting([u]) }
                    }
                }
            }
            if let error { Text(error).foregroundStyle(Theme.danger).font(.system(size: 11)) }
            Spacer(minLength: 0)
            HStack {
                Spacer()
                Button(phase == 3 ? "Done" : "Cancel") { task?.cancel(); dismiss() }
                if phase == 1 {
                    Button("Redact \(urls.count) file\(urls.count == 1 ? "" : "s")") { write() }
                        .buttonStyle(.borderedProminent).tint(Theme.accent)
                }
                if phase == 2 { ProgressView().controlSize(.small) }
            }
        }
        .padding(24)
        .frame(width: 720, height: 560)
        .onAppear(perform: scan)
    }

    private func uniqueValues(_ items: [(file: URL, finding: Finding)]) -> [(value: String, label: String, file: String)] {
        var seen = Set<String>()
        var out: [(String, String, String)] = []
        for i in items where seen.insert(i.finding.text.lowercased()).inserted {
            out.append((i.finding.text, i.finding.label, i.file.lastPathComponent))
        }
        return out
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
                scans.append(FileScan(url: url, findings: result.findings, provider: result.llmProvider))
            }
            phase = 1
        }
    }

    private func write() {
        phase = 2
        Task {
            for s in scans {
                do {
                    let r = try Redactor.redactFile(s.url, findings: s.findings, keep: unticked)
                    outputs.append(r.output)
                    Store.shared.saveRedaction(source: s.url.path, output: r.output.path, counts: r.counts)
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
