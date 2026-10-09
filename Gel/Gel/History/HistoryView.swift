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
                ModuleHeader(title: "History", subtitle: answers.isEmpty ? "Every answer keeps its sources" : "\(answers.count) question\(answers.count == 1 ? "" : "s") · every answer keeps its sources")
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
                                    HStack(spacing: 8) {
                                        Text(a.date, style: .time).font(.system(size: 11).monospacedDigit()).foregroundStyle(Theme.textSecondary)
                                            .frame(width: 58, alignment: .leading)
                                        Text(a.question).lineLimit(1).font(.system(size: 12.5))
                                        Spacer()
                                        Image(systemName: a.provider == .local ? "cpu" : "cloud")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundStyle(a.provider == .local ? Theme.accent : Theme.textSecondary)
                                            .help(a.provider == .local ? "Answered on this Mac" : "Answered by cloud fallback")
                                    }
                                    .padding(.vertical, 3)
                                    .tag(a.id)
                                }
                            }
                        }
                    }
                    .frame(width: 360)
                    .scrollContentBackground(.hidden)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.hairline))
                    ZStack { detail.id(selected).transition(.rise(6)) }
                        .animation(Motion.smooth, value: selected)
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
                    HStack(spacing: 8) {
                        Text(a.date.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                        Spacer()
                        ProviderBadge(provider: a.provider, model: a.model)
                    }
                    Text(a.question).font(.system(size: 18, weight: .semibold)).tracking(-0.2)
                    Text((try? AttributedString(markdown: a.text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(a.text))
                        .font(.system(size: 13.5)).lineSpacing(2).textSelection(.enabled)
                    if !a.citations.isEmpty {
                        SectionLabel(text: "Sources").padding(.top, 4)
                        FlowLayout {
                            ForEach(Array(a.citations.enumerated()), id: \.element.id) { i, c in
                                CitationChip(citation: c) { state.open(citation: c) }.staggeredAppear(i)
                            }
                        }
                    }
                    if let sent = a.sentPayload {
                        DisclosureGroup {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("This is exactly what left your Mac. Personal data was replaced with placeholders.", systemImage: "lock.open")
                                    .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                                Text(sent).font(.system(size: 11, design: .monospaced)).textSelection(.enabled)
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Theme.canvas, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Theme.hairline))
                            }
                            .padding(.top, 6)
                        } label: {
                            Label("What was sent", systemImage: "cloud").font(.system(size: 12.5, weight: .medium))
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.hairline))
        } else {
            EmptyStateView(symbol: "text.bubble", title: "Select a question", hint: "Answers keep their sources and show where they ran.")
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.hairline))
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
