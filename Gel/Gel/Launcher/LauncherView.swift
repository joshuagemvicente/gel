import SwiftUI
import GelCore

struct LauncherView: View {
    @ObservedObject var model: LauncherModel
    @ObservedObject var voice = VoiceRecorder.shared
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            inputRow
            if model.phase != .idle && model.phase != .recording { Divider().overlay(Theme.hairline) ; answerArea }
            if model.phase == .idle {
                Text("⏎ ask  ·  esc close  ·  hold right ⌥ to talk")
                    .font(.system(size: 10.5)).foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 20).padding(.bottom, 10)
            }
        }
        .frame(width: 640)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.hairline))
        .onChange(of: model.focusTick) { _, _ in focused = true }
        .onAppear { focused = true }
    }

    private var inputRow: some View {
        HStack(spacing: 12) {
            leadingGlyph.frame(width: 20)
            if model.phase == .recording {
                LevelMeter(level: voice.level)
                Text("Listening… release ⌥ to ask").foregroundStyle(Theme.textSecondary)
                Spacer()
            } else {
                TextField("Ask your files… hold ⌥ to talk", text: $model.query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 17))
                    .focused($focused)
                    .onSubmit { model.run() }
            }
            Image(systemName: model.phase == .recording ? "mic.fill" : "mic")
                .foregroundStyle(model.phase == .recording ? Theme.accent : micColor)
                .help(micHelp)
        }
        .padding(.horizontal, 18).frame(height: 54)
    }

    @ViewBuilder private var leadingGlyph: some View {
        switch model.phase {
        case .recording: Circle().fill(Theme.danger).frame(width: 9, height: 9)
        case .transcribing, .waiting: ProgressView().controlSize(.small)
        default: Image(systemName: "magnifyingglass").foregroundStyle(Theme.textSecondary)
        }
    }

    private var micColor: Color {
        if case .unavailable = voice.state { return Theme.textSecondary.opacity(0.4) }
        return Theme.textSecondary
    }

    private var micHelp: String {
        switch voice.state {
        case .loading: return "Loading the voice model…"
        case .unavailable(let why): return why
        default: return "Hold right ⌥ to talk"
        }
    }

    @ViewBuilder private var answerArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch model.phase {
            case .transcribing:
                Text("Transcribing…").foregroundStyle(Theme.textSecondary)
            case .waiting:
                Shimmer()
            case .error(let message):
                HStack {
                    Text(message).foregroundStyle(Theme.danger).font(.system(size: 13))
                    Spacer()
                    if message.hasPrefix("Nothing indexed") {
                        Button("Choose a folder") { model.openSettings() }
                    } else {
                        Button("Retry") { model.run() }
                    }
                }
            default:
                Text(markdown(model.answerText))
                    .font(.system(size: 14))
                    .foregroundStyle(model.answerText.hasPrefix("Hindi ko nakita") ? Theme.textSecondary : Theme.textPrimary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                if let a = model.answer {
                    if !a.citations.isEmpty {
                        FlowLayout { ForEach(a.citations) { c in CitationChip(citation: c) { model.open(c) } } }
                    }
                    HStack {
                        Button("Open in Gel") { model.openInGel() }.buttonStyle(.link).font(.system(size: 11))
                        Spacer()
                        ProviderBadge(provider: a.provider, model: a.model)
                    }
                }
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .animation(.easeOut(duration: 0.2), value: model.answerText)
    }

    private func markdown(_ s: String) -> AttributedString {
        (try? AttributedString(markdown: s, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(s)
    }
}

struct LevelMeter: View {
    var level: Float
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5) { i in
                Capsule().fill(Theme.accent)
                    .frame(width: 4, height: 6 + CGFloat(max(0, min(1, level * Float(5 - abs(2 - i)) / 3))) * 16)
            }
        }
        .frame(height: 24)
        .animation(.easeOut(duration: 0.08), value: level)
    }
}

struct Shimmer: View {
    @State private var phase: CGFloat = -1
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 4).frame(height: 10)
            RoundedRectangle(cornerRadius: 4).frame(width: 360, height: 10)
        }
        .foregroundStyle(Theme.hairline)
        .overlay(
            LinearGradient(colors: [.clear, Theme.card.opacity(0.8), .clear], startPoint: .leading, endPoint: .trailing)
                .offset(x: phase * 400)
        )
        .clipped()
        .onAppear { withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) { phase = 1 } }
    }
}
