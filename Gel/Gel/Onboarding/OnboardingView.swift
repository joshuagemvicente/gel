import SwiftUI
import GelCore

struct OnboardingView: View {
    @EnvironmentObject var state: AppState
    @State private var step = 0
    @State private var work = true
    @State private var personal = false

    private var demoFolder: URL? {
        // Dev convenience: suggest the repo's demo folder when it exists.
        let candidates = [Bundle.main.bundleURL.deletingLastPathComponent(), URL(fileURLWithPath: FileManager.default.currentDirectoryPath)]
        for base in candidates {
            var dir = base
            for _ in 0..<6 {
                let c = dir.appendingPathComponent("demo-data/HR Files")
                if FileManager.default.fileExists(atPath: c.path) { return c }
                dir = dir.deletingLastPathComponent()
            }
        }
        return nil
    }

    @State private var forward = true
    @State private var heroDropped = false

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Group {
                    switch step {
                    case 0: whoStep
                    case 1: folderStep
                    default: indexingStep
                    }
                }
                .id(step)
                .transition(.push(forward: forward))
            }
            .frame(maxWidth: .infinity)
            Spacer(minLength: 0)
            HStack {
                if step > 0 && step < 2 {
                    Button("Back") { go(to: step - 1) }.buttonStyle(.gelSecondary)
                }
                Spacer()
                pageIndicator
                Spacer()
                primaryButton
            }
        }
        .padding(28)
        .frame(width: 560, height: 440)
        .background(Theme.canvas)
        .animation(Motion.smooth, value: step)
    }

    private func go(to next: Int) {
        forward = next > step
        withAnimation(Motion.smooth) { step = next }
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { i in
                Capsule().fill(i == step ? Theme.accent : Theme.hairline)
                    .frame(width: i == step ? 18 : 7, height: 7)
            }
        }
        .animation(Motion.snappy, value: step)
        .accessibilityElement()
        .accessibilityLabel("Step \(step + 1) of 3")
    }

    private var whoStep: some View {
        VStack(spacing: 12) {
            GelMark(size: 56)
                .offset(y: heroDropped || Motion.reduce ? 0 : -16)
                .opacity(heroDropped ? 1 : 0)
                .onAppear { withAnimation(Motion.pop.delay(0.05)) { heroDropped = true } }
            Text("Gel").font(.system(size: 28, weight: .semibold)).tracking(-0.5)
            Text("Your private AI layer. Everything stays on this Mac.").foregroundStyle(Theme.textSecondary)
            Text("Who is this for?").font(.system(size: 15, weight: .semibold)).padding(.top, 10)
            HStack(spacing: 14) {
                choice("briefcase", "Work: HR", "201 files, IDs, payslips", $work)
                choice("house", "Personal", "IDs, bank and GCash, cards", $personal)
            }
        }
    }

    private func choice(_ symbol: String, _ title: String, _ subtitle: String, _ on: Binding<Bool>) -> some View {
        ChoiceCard(symbol: symbol, title: title, subtitle: subtitle, on: on)
    }

    private var folderStep: some View {
        VStack(spacing: 14) {
            IconChip(symbol: "folder", size: 48)
            Text("Choose the folders Gel should read").font(.system(size: 17, weight: .semibold))
            Text("Gel reads it on this Mac. Nothing is uploaded.").foregroundStyle(Theme.textSecondary)
            Button("Choose folders…") { choose() }.buttonStyle(GelButtonStyle(kind: .secondary, large: true))
            ForEach(state.folderPaths, id: \.self) { p in
                HStack(spacing: 6) {
                    Label(p, systemImage: "checkmark.circle.fill")
                        .font(.system(size: 11, design: .monospaced)).lineLimit(1).truncationMode(.middle)
                        .foregroundStyle(Theme.textPrimary)
                    Button { state.removeFolder(p) } label: {
                        Image(systemName: "xmark").font(.system(size: 8, weight: .bold)).foregroundStyle(Theme.textSecondary)
                            .frame(width: 14, height: 14).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove \(URL(fileURLWithPath: p).lastPathComponent)")
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Theme.card, in: Capsule())
                .overlay(Capsule().strokeBorder(Theme.hairline))
                .frame(maxWidth: 440)
                .transition(.popIn)
            }
            ForEach(state.folderNotes, id: \.self) { note in
                Text(note).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            }
            if let demo = demoFolder {
                Button("Use demo-data/HR Files") { state.addFolders([demo]) }.buttonStyle(.link)
            }
        }
        .padding(.top, 24)
        .animation(Motion.pop, value: state.folderPaths)
    }

    private var indexingStep: some View {
        VStack(spacing: 12) {
            if let p = state.indexProgress {
                GelMark(size: 44).padding(.bottom, 4)
                Text("Reading your files").font(.system(size: 17, weight: .semibold))
                GelProgressBar(value: Double(p.done), total: Double(p.total), height: 6, animated: false).frame(width: 360)
                Text("Reading \(min(p.done + 1, p.total)) of \(p.total)")
                    .font(.system(size: 12).monospacedDigit()).foregroundStyle(Theme.textSecondary)
                Text(p.current).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                    .lineLimit(1).truncationMode(.middle).frame(maxWidth: 360)
                Text("Scanned pages take a little longer.").font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40)).foregroundStyle(Theme.accent)
                    .transition(.popIn)
                Text("\(Store.shared.documents().count) files ready").font(.system(size: 17, weight: .semibold))
                HStack(spacing: 4) {
                    Text("Press")
                    KeyHint(key: "⌥ Space", text: "anywhere to ask them.")
                }
                .font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.top, 36)
        .animation(Motion.smooth, value: state.indexProgress == nil)
    }

    @ViewBuilder private var primaryButton: some View {
        switch step {
        case 0:
            Button("Continue") {
                state.setPacks((work ? ["hr"] : []) + (personal ? ["personal"] : []))
                go(to: 1)
            }.buttonStyle(.gelPrimary).disabled(!work && !personal)
        case 1:
            Button("Continue") { go(to: 2) }.buttonStyle(.gelPrimary).disabled(state.folderPaths.isEmpty)
        default:
            HStack {
                if state.indexProgress != nil { Button("Continue in background") { finish() }.buttonStyle(.gelSecondary) }
                Button("Done") { finish() }.buttonStyle(.gelPrimary).disabled(state.indexProgress != nil)
            }
        }
    }

    private func choose() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.message = "Choose one or more folders. ⌘-click to select several."
        if panel.runModal() == .OK { state.addFolders(panel.urls) }
    }

    private func finish() {
        GelSettings.shared.onboardingDone = true
        state.showOnboarding = false
    }
}

private struct ChoiceCard: View {
    var symbol: String
    var title: String
    var subtitle: String
    @Binding var on: Bool
    @State private var hovering = false

    var body: some View {
        Button { withAnimation(Motion.pop) { on.toggle() } } label: {
            VStack(alignment: .leading, spacing: 6) {
                IconChip(symbol: symbol, tint: on ? Theme.accent : Theme.textSecondary,
                         background: on ? Theme.accentSoft : Theme.hairline.opacity(0.5), size: 32)
                Spacer(minLength: 0)
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                Text(subtitle).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            }
            .frame(width: 200, height: 100, alignment: .leading)
            .padding(14)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(on ? Theme.accent : Theme.hairline, lineWidth: on ? 2 : 1))
            .overlay(alignment: .topTrailing) {
                if on {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18)).foregroundStyle(Theme.accent)
                        .padding(10)
                        .transition(.popIn)
                }
            }
            .shadow(color: hovering ? Theme.shadow : .clear, radius: 8, y: 3)
            .offset(y: hovering && !Motion.reduce ? -1 : 0)
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PressableStyle(scale: 0.98))
        .onHover { h in withAnimation(Motion.snappy) { hovering = h } }
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
