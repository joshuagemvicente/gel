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

    var body: some View {
        VStack(spacing: 18) {
            switch step {
            case 0: whoStep
            case 1: folderStep
            default: indexingStep
            }
            Spacer(minLength: 0)
            HStack {
                if step > 0 && step < 2 { Button("Back") { step -= 1 } }
                Spacer()
                HStack(spacing: 6) { ForEach(0..<3) { Circle().fill($0 == step ? Theme.accent : Theme.hairline).frame(width: 7, height: 7) } }
                Spacer()
                primaryButton
            }
        }
        .padding(28)
        .frame(width: 560, height: 420)
        .background(Theme.canvas)
    }

    private var whoStep: some View {
        VStack(spacing: 14) {
            HStack { Image(systemName: "drop.fill").foregroundStyle(Theme.accent); Text("Gel").font(.system(size: 24, weight: .semibold)) }
            Text("Your private AI layer. Everything stays on this Mac.").foregroundStyle(Theme.textSecondary)
            Text("Who is this for?").font(.system(size: 15, weight: .semibold)).padding(.top, 10)
            HStack(spacing: 14) {
                choice("briefcase", "Work: HR", "201 files, IDs, payslips", $work)
                choice("house", "Personal", "IDs, bank and GCash, cards", $personal)
            }
        }
    }

    private func choice(_ symbol: String, _ title: String, _ subtitle: String, _ on: Binding<Bool>) -> some View {
        Button { on.wrappedValue.toggle() } label: {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: symbol).font(.system(size: 20))
                Text(title).font(.system(size: 14, weight: .semibold))
                Text(subtitle).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            }
            .frame(width: 200, height: 110, alignment: .leading)
            .padding(14)
            .background(on.wrappedValue ? Theme.accentSoft : Theme.card, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(on.wrappedValue ? Theme.accent : Theme.hairline, lineWidth: on.wrappedValue ? 2 : 1))
        }
        .buttonStyle(.plain)
    }

    private var folderStep: some View {
        VStack(spacing: 12) {
            Text("Choose the folder Gel should read").font(.system(size: 17, weight: .semibold))
            Text("Gel reads it on this Mac. Nothing is uploaded.").foregroundStyle(Theme.textSecondary)
            Button("Choose folder…") { choose() }.controlSize(.large)
            if let p = state.folderPath {
                Text(p).font(.system(size: 11, design: .monospaced)).lineLimit(1).truncationMode(.middle)
                    .padding(.horizontal, 10).padding(.vertical, 4).background(Theme.card, in: Capsule())
            }
            if let demo = demoFolder {
                Button("Use demo-data/HR Files") { state.setFolder(demo) }.buttonStyle(.link)
            }
        }
        .padding(.top, 30)
    }

    private var indexingStep: some View {
        VStack(spacing: 12) {
            Text("Reading your files").font(.system(size: 17, weight: .semibold))
            if let p = state.indexProgress {
                ProgressView(value: Double(p.done), total: Double(max(p.total, 1))).frame(width: 360)
                Text("Reading \(p.done + 1) of \(p.total) · \(p.current)").font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
            } else {
                Text("\(Store.shared.documents().count) files ready.").foregroundStyle(Theme.textSecondary)
            }
            Text("Scanned pages take a little longer.").font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
        }
        .padding(.top, 40)
    }

    @ViewBuilder private var primaryButton: some View {
        switch step {
        case 0:
            Button("Continue") {
                state.setPacks((work ? ["hr"] : []) + (personal ? ["personal"] : []))
                step = 1
            }.buttonStyle(.borderedProminent).tint(Theme.accent).disabled(!work && !personal)
        case 1:
            Button("Continue") { step = 2 }.buttonStyle(.borderedProminent).tint(Theme.accent).disabled(state.folderPath == nil)
        default:
            HStack {
                if state.indexProgress != nil { Button("Continue in background") { finish() } }
                Button("Done") { finish() }.buttonStyle(.borderedProminent).tint(Theme.accent).disabled(state.indexProgress != nil)
            }
        }
    }

    private func choose() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        if panel.runModal() == .OK, let url = panel.url { state.setFolder(url) }
    }

    private func finish() {
        GelSettings.shared.onboardingDone = true
        state.showOnboarding = false
    }
}
