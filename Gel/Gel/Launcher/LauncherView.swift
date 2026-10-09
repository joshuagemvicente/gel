import SwiftUI
import GelCore

struct LauncherView: View {
    @ObservedObject var model: LauncherModel
    @ObservedObject var voice = VoiceRecorder.shared
    @FocusState private var focused: Bool
    @State private var appeared = true
    @State private var errorTick = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            inputRow
            if model.phase != .idle && model.phase != .recording {
                Rectangle().fill(Theme.hairline).frame(height: 1)
                answerArea.transition(.rise(4))
            }
            if model.phase == .idle {
                HStack(spacing: 6) {
                    KeyHint(key: "⏎", text: "ask")
                    KeyHint(key: "esc", text: "close")
                    if let notice = idleNotice {
                        Text(notice).font(.system(size: 10.5)).foregroundStyle(Theme.textSecondary)
                    } else {
                        KeyHint(key: "right ⌥", text: "hold to talk")
                    }
                }
                .padding(.horizontal, 18).padding(.bottom, 12)
                .transition(.opacity)
            }
        }
        .frame(width: 640)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.hairline))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .scaleEffect(appeared || Motion.reduce ? 1 : 0.98, anchor: .top)
        .animation(Motion.smooth, value: model.phase)
        .onChange(of: model.focusTick) { _, _ in
            focused = true
            var t = Transaction(); t.disablesAnimations = true
            withTransaction(t) { appeared = false }
            DispatchQueue.main.async { withAnimation(Motion.smooth) { appeared = true } }
        }
        .onChange(of: model.phase) { _, new in
            if case .error = new { errorTick += 1 }
        }
        .onAppear { focused = true }
    }

    private var inputRow: some View {
        HStack(spacing: 12) {
            GelMark(size: 20, mode: markMode)
                .frame(width: 22)
                .animation(Motion.snappy, value: markMode)
            if model.phase == .recording {
                LevelMeter(level: voice.level)
                Text(voice.soundMuted ? "Listening… release ⌥ to ask · sound muted" : "Listening… release ⌥ to ask").foregroundStyle(Theme.textSecondary)
                    .transition(.opacity)
                Spacer()
            } else {
                TextField("Ask your files… hold ⌥ to talk", text: $model.query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 17))
                    .focused($focused)
                    .onSubmit { model.run() }
            }
            mic
        }
        .padding(.horizontal, 18).frame(height: 54)
    }

    private var markMode: GelMark.Mode {
        switch model.phase {
        case .recording: return .listening(voice.level)
        case .transcribing, .waiting, .streaming: return .thinking
        default: return .still
        }
    }

    private var mic: some View {
        let recording = model.phase == .recording
        return Image(systemName: recording ? "mic.fill" : "mic")
            .foregroundStyle(recording ? Theme.accent : micColor)
            .frame(width: 26, height: 26)
            .background {
                if recording {
                    Circle().fill(Theme.accentSoft)
                        .scaleEffect(Motion.reduce ? 1 : 1 + CGFloat(min(1, voice.level * 2)) * 0.45)
                        .animation(Motion.snappy, value: voice.level)
                        .transition(.opacity)
                }
            }
            .contentTransition(.symbolEffect(.replace))
            .help(micHelp)
            .accessibilityLabel(recording ? "Listening" : micHelp)
    }

    private var micColor: Color {
        if case .unavailable = voice.state { return Theme.textSecondary.opacity(0.4) }
        if voice.micDenied { return Theme.textSecondary.opacity(0.4) }
        return Theme.textSecondary
    }

    /// Replaces the hold-to-talk hint; same priority as `micHelp`, so the row and the tooltip agree.
    private var idleNotice: String? {
        if case .unavailable(let why) = voice.state { return why }
        return voice.micNotice
    }

    private var micHelp: String {
        if case .unavailable(let why) = voice.state { return why }
        if let notice = voice.micNotice { return notice }
        return voice.state == .loading ? "Loading the voice model…" : "Hold right ⌥ to talk"
    }

    @ViewBuilder private var answerArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch model.phase {
            case .transcribing:
                Text("Transcribing…").foregroundStyle(Theme.textSecondary)
                    .transition(.opacity)
            case .waiting:
                Shimmer().transition(.opacity)
            case .error(let message):
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill").foregroundStyle(Theme.danger)
                    Text(message).foregroundStyle(Theme.danger).font(.system(size: 13))
                    Spacer()
                    if message.hasPrefix("Nothing indexed") {
                        Button("Choose a folder") { model.openSettings() }.buttonStyle(.gelPrimary)
                    } else {
                        Button("Retry") { model.run() }.buttonStyle(.gelSecondary)
                    }
                }
                .shake(errorTick)
            default:
                AnswerText(text: model.answerText, citations: model.answer?.citations) { model.open($0) }
                    .font(.system(size: 14))
                    .lineSpacing(2)
                    .foregroundStyle(QueryEngine.isNotFound(model.answerText) ? Theme.textSecondary : Theme.textPrimary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                if let a = model.answer {
                    if !a.citations.isEmpty {
                        FlowLayout {
                            ForEach(Array(a.citations.enumerated()), id: \.element.id) { i, c in
                                CitationChip(citation: c) { model.open(c) }.staggeredAppear(i)
                            }
                        }
                    }
                    HStack {
                        Button { model.openInGel() } label: {
                            Label("Open in Gel", systemImage: "arrow.up.forward.app")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                                .padding(.horizontal, 6).padding(.vertical, 3)
                                .hoverHighlight(radius: 6)
                        }
                        .buttonStyle(PressableStyle())
                        Spacer()
                        ProviderBadge(provider: a.provider, model: a.model)
                            .staggeredAppear(a.citations.count)
                    }
                    .id(a.id)
                }
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// "⏎ ask" with the key drawn as a small keycap.
struct KeyHint: View {
    var key: String
    var text: String

    var body: some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 5).frame(minWidth: 18, minHeight: 16)
                .background(Theme.canvas, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).strokeBorder(Theme.hairline))
            Text(text).font(.system(size: 10.5))
        }
        .foregroundStyle(Theme.textSecondary)
        .padding(.trailing, 6)
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
        .animation(Motion.snappy, value: level)
    }
}

/// Skeleton lines with a highlight that sweeps across them (clipped to each line, so it works in light and dark).
struct Shimmer: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            line(1.0)
            line(0.86)
            line(0.58)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("Thinking")
        .onAppear {
            guard !Motion.reduce else { return }
            withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) { phase = 1 }
        }
    }

    private func line(_ fraction: CGFloat) -> some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Theme.hairline)
                .frame(width: geo.size.width * fraction)
                .overlay(alignment: .leading) {
                    if !Motion.reduce {
                        LinearGradient(colors: [.clear, Theme.textSecondary.opacity(0.22), .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: 160)
                            .offset(x: -160 + phase * (geo.size.width + 160))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .opacity(Motion.reduce ? 0.6 : 1)
        }
        .frame(height: 10)
    }
}
