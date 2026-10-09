import SwiftUI
import GelCore

struct HomeView: View {
    @EnvironmentObject var state: AppState
    @State private var totals = DPOReport.Totals()
    @State private var activity: [ActivityItem] = []
    @State private var docCount = 0
    @State private var chunkCount = 0

    struct ActivityItem: Identifiable, Equatable {
        enum Kind { case question, redaction, leak }
        var date: Date
        var text: String
        var kind: Kind
        var provider: ProviderKind?
        /// Stable across reloads so only genuinely new rows animate in.
        var id: String { "\(kind)-\(date.timeIntervalSince1970)-\(text)" }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let part = hour < 12 ? "Good morning" : (hour < 18 ? "Good afternoon" : "Good evening")
        return "\(part) · \(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))"
    }

    private var localShareText: String {
        totals.localAnswers + totals.cloudAnswers == 0 ? "—" : "\(Int((totals.localShare * 100).rounded()))%"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ModuleHeader(title: "Welcome back", subtitle: greeting)
                HStack(spacing: 14) {
                    StatCard(value: "\(totals.itemsProtected)", label: "items kept on device", symbol: "lock.shield",
                             numeric: Double(totals.itemsProtected))
                        .staggeredAppear(0, rise: 10)
                    StatCard(value: "\(totals.leaksCaught)", label: "leaks caught", symbol: "hand.raised",
                             numeric: Double(totals.leaksCaught))
                        .staggeredAppear(1, rise: 10)
                    StatCard(value: localShareText, label: "answers ran locally", symbol: "cpu", numeric: totals.localShare)
                        .staggeredAppear(2, rise: 10)
                    indexCard.frame(width: 220).staggeredAppear(3, rise: 10)
                }
                .fixedSize(horizontal: false, vertical: true)
                SectionLabel(text: "Today").padding(.top, 6)
                if activity.isEmpty {
                    Card {
                        HStack(spacing: 10) {
                            GelMark(size: 18)
                            Text("Nothing yet today.").foregroundStyle(Theme.textPrimary)
                            KeyHint(key: "⌥ Space", text: "ask your files")
                        }
                    }
                } else {
                    Card(padding: 6) {
                        VStack(spacing: 0) {
                            ForEach(activity) { item in
                                row(item)
                                    .transition(.asymmetric(insertion: .rise(-6), removal: .opacity))
                                if item.id != activity.last?.id { Divider().overlay(Theme.hairline).padding(.leading, 52) }
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

    private var folderLine: String {
        switch state.folderPaths.count {
        case 0: return "No folder yet"
        case 1: return URL(fileURLWithPath: state.folderPaths[0]).lastPathComponent
        case let n: return "\(n) folders"
        }
    }

    private var indexCard: some View {
        Card(fillHeight: true) {
            VStack(alignment: .leading, spacing: 10) {
                IconChip(symbol: "books.vertical")
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(docCount) files · \(chunkCount) passages").font(.system(size: 14, weight: .medium))
                        .contentTransition(.numericText(value: Double(chunkCount)))
                    // Fixed layout while indexing (see MainView.statusFooter).
                    let p = state.indexProgress
                    Text(p.map { "Reading \(min($0.done + 1, $0.total)) of \($0.total)…" }
                         ?? folderLine)
                        .font(.system(size: 11).monospacedDigit()).foregroundStyle(Theme.textSecondary).lineLimit(1)
                    GelProgressBar(value: Double(p?.done ?? 0), total: Double(p?.total ?? 1), animated: false)
                        .padding(.top, 2)
                        .opacity(p == nil ? 0 : 1)
                        .animation(Motion.smooth, value: p == nil)
                }
            }
        }
    }

    private func row(_ item: ActivityItem) -> some View {
        HStack(spacing: 12) {
            switch item.kind {
            case .question: IconChip(symbol: "text.bubble", size: 24)
            case .redaction: IconChip(symbol: "eye.slash", tint: Theme.textSecondary, background: Theme.hairline.opacity(0.6), size: 24)
            case .leak: IconChip(symbol: "exclamationmark.shield", tint: Theme.danger, background: Theme.dangerSoft, size: 24)
            }
            Text(item.text).font(.system(size: 13)).lineLimit(1).foregroundStyle(Theme.textPrimary)
            Spacer()
            if let p = item.provider { ProviderBadge(provider: p, model: "") }
            Text(item.date, style: .time).font(.system(size: 11).monospacedDigit()).foregroundStyle(Theme.textSecondary)
                .frame(width: 64, alignment: .trailing)
        }
        .padding(.horizontal, 10).frame(height: 44)
        .hoverHighlight()
    }

    private func reload() {
        let newTotals = DPOReport.totals()
        docCount = Store.shared.documents().count
        chunkCount = Store.shared.chunkCount
        let start = Calendar.current.startOfDay(for: Date())
        var items: [ActivityItem] = Store.shared.history(limit: 50).filter { $0.date >= start }
            .map { ActivityItem(date: $0.date, text: $0.question, kind: .question, provider: $0.provider) }
        items += Store.shared.redactions().filter { $0.date >= start }
            .map { ActivityItem(date: $0.date, text: "Redacted \(URL(fileURLWithPath: $0.source).lastPathComponent)", kind: .redaction, provider: nil) }
        items += LeakLog.entries(since: start).map { ActivityItem(date: $0.date, text: "Leak caught in \($0.app): \($0.summary)", kind: .leak, provider: nil) }
        let newActivity = Array(items.sorted { $0.date > $1.date }.prefix(12))
        withAnimation(Motion.smooth) {
            totals = newTotals
            if newActivity != activity { activity = newActivity }
        }
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
