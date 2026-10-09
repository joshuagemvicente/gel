import SwiftUI
import GelCore

struct HomeView: View {
    @EnvironmentObject var state: AppState
    @State private var totals = DPOReport.Totals()
    @State private var activity: [ActivityItem] = []
    @State private var docCount = 0
    @State private var chunkCount = 0

    struct ActivityItem: Identifiable {
        let id = UUID()
        var date: Date
        var text: String
        var provider: ProviderKind?
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ModuleHeader(title: "Welcome back")
                HStack(spacing: 14) {
                    StatCard(value: "\(totals.itemsProtected)", label: "items kept on device")
                    StatCard(value: "\(totals.leaksCaught)", label: "leaks caught")
                    StatCard(value: totals.localAnswers + totals.cloudAnswers == 0 ? "—" : "\(Int((totals.localShare * 100).rounded()))%",
                             label: "answers ran locally")
                    Card {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Index").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.textSecondary)
                            Text("\(docCount) files · \(chunkCount) passages").font(.system(size: 14))
                            if let p = state.indexProgress {
                                Text("Indexing \(p.done + 1) of \(p.total)…").font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                            } else {
                                Text(state.folderPath.map { URL(fileURLWithPath: $0).lastPathComponent } ?? "No folder yet")
                                    .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                    .frame(width: 220)
                }
                Text("TODAY").font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.textSecondary).padding(.top, 6)
                if activity.isEmpty {
                    Card { Text("Nothing yet today. Press ⌥Space to ask your files.").foregroundStyle(Theme.textSecondary) }
                } else {
                    Card(padding: 0) {
                        VStack(spacing: 0) {
                            ForEach(activity) { item in
                                HStack(spacing: 14) {
                                    Text(item.date, style: .time).font(.system(size: 11)).foregroundStyle(Theme.textSecondary).frame(width: 64, alignment: .leading)
                                    Text(item.text).font(.system(size: 13)).lineLimit(1)
                                    Spacer()
                                    if let p = item.provider { ProviderBadge(provider: p, model: "") }
                                }
                                .padding(.horizontal, 16).frame(height: 44)
                                if item.id != activity.last?.id { Divider().overlay(Theme.hairline) }
                            }
                        }
                    }
                }
            }
            .padding(28)
        }
        .onAppear(perform: reload)
        .onChange(of: state.activityVersion) { _, _ in reload() }
        .onChange(of: state.documentsVersion) { _, _ in reload() }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in reload() }
    }

    private func reload() {
        totals = DPOReport.totals()
        docCount = Store.shared.documents().count
        chunkCount = Store.shared.chunkCount
        let start = Calendar.current.startOfDay(for: Date())
        var items: [ActivityItem] = Store.shared.history(limit: 50).filter { $0.date >= start }
            .map { ActivityItem(date: $0.date, text: $0.question, provider: $0.provider) }
        items += Store.shared.redactions().filter { $0.date >= start }
            .map { ActivityItem(date: $0.date, text: "Redacted \(URL(fileURLWithPath: $0.source).lastPathComponent)", provider: nil) }
        items += LeakLog.entries(since: start).map { ActivityItem(date: $0.date, text: "Leak caught in \($0.app): \($0.summary)", provider: nil) }
        activity = Array(items.sorted { $0.date > $1.date }.prefix(12))
    }
}

/// Leak Guard log rebuilt from counts-only events (`leak_caught` + following `leak_item` rows).
enum LeakLog {
    struct Entry: Identifiable { let id = UUID(); var date: Date; var app: String; var summary: String }

    static func entries(since: Date = .distantPast) -> [Entry] {
        let events = Store.shared.events(since: since).sorted { $0.date < $1.date }
        var out: [Entry] = []
        var current: (Date, String, [String: Int])?
        func flush() {
            if let c = current {
                let parts = c.2.sorted { $0.value > $1.value }.map { "\($0.value) \($0.key)" }
                out.append(Entry(date: c.0, app: c.1, summary: parts.joined(separator: ", ")))
            }
        }
        for e in events {
            if e.kind == "leak_caught" { flush(); current = (e.date, e.app, [:]) }
            else if e.kind == "leak_item", current != nil { current!.2[e.category, default: 0] += e.count }
        }
        flush()
        return out.reversed()
    }
}
