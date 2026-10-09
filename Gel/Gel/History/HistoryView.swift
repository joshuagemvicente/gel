import SwiftUI
import GelCore

struct HistoryView: View {
    @EnvironmentObject var state: AppState
    @State private var answers: [AnswerResult] = []
    @State private var selected: Int64?
    @State private var search = ""

    private var filtered: [AnswerResult] {
        search.isEmpty ? answers : answers.filter { $0.question.localizedCaseInsensitiveContains(search) }
    }

    private var groups: [(String, [AnswerResult])] {
        let cal = Calendar.current
        let df = DateFormatter(); df.dateFormat = "MMM d"
        var order: [String] = []
        var map: [String: [AnswerResult]] = [:]
        for a in filtered {
            let key = cal.isDateInToday(a.date) ? "TODAY" : (cal.isDateInYesterday(a.date) ? "YESTERDAY" : df.string(from: a.date).uppercased())
            if map[key] == nil { order.append(key) }
            map[key, default: []].append(a)
        }
        return order.map { ($0, map[$0]!) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ModuleHeader(title: "History")
                Spacer()
                TextField("Search questions", text: $search).textFieldStyle(.roundedBorder).frame(width: 240)
            }
            if answers.isEmpty {
                EmptyStateView(symbol: "clock.arrow.circlepath", title: "No questions yet", hint: "Press ⌥Space to ask your files.")
            } else {
                HStack(alignment: .top, spacing: 14) {
                    List(selection: $selected) {
                        ForEach(groups, id: \.0) { title, items in
                            Section(title) {
                                ForEach(items) { a in
                                    HStack {
                                        Text(a.date, style: .time).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                                        Text(a.question).lineLimit(1).font(.system(size: 12.5))
                                        Spacer()
                                        Text(a.provider == .local ? "Local" : "Cloud").font(.system(size: 10))
                                            .foregroundStyle(a.provider == .local ? Theme.accent : Theme.textSecondary)
                                    }
                                    .tag(a.id)
                                }
                            }
                        }
                    }
                    .frame(width: 360)
                    .scrollContentBackground(.hidden)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                    detail
                }
            }
        }
        .padding(28)
        .onAppear(perform: reload)
        .onChange(of: state.activityVersion) { _, _ in reload() }
    }

    @ViewBuilder private var detail: some View {
        if let a = answers.first(where: { $0.id == selected }) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(a.question).font(.system(size: 16, weight: .semibold))
                    Text((try? AttributedString(markdown: a.text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(a.text))
                        .font(.system(size: 13.5)).textSelection(.enabled)
                    if !a.citations.isEmpty {
                        FlowLayout { ForEach(a.citations) { c in CitationChip(citation: c) { state.open(citation: c) } } }
                    }
                    ProviderBadge(provider: a.provider, model: a.model)
                    if let sent = a.sentPayload {
                        DisclosureGroup("What was sent") {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("This is exactly what left your Mac. Personal data was replaced with placeholders.")
                                    .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                                Text(sent).font(.system(size: 11, design: .monospaced)).textSelection(.enabled)
                            }
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
        } else {
            EmptyStateView(symbol: "text.bubble", title: "Select a question", hint: "Answers keep their sources and show where they ran.")
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func reload() {
        answers = Store.shared.history()
        if let id = state.pendingHistoryId {
            selected = id
            state.pendingHistoryId = nil
        } else if selected == nil {
            selected = answers.first?.id
        }
    }
}
