import SwiftUI
import GelCore

/// Settings › Models (U11): Ollama's state with one action, three preset cards and the embedding model.
/// Lives in the main window, so nothing here animates (D-047) and progress never inserts views.
struct ModelsSection: View {
    @EnvironmentObject var state: AppState
    @ObservedObject private var setup = OllamaSetup.shared
    @State private var showInstall = false

    private var current: String { GelSettings.shared.localModel }
    private var envLocked: Bool { GelSettings.shared.localModelFromEnvironment }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ollamaRow
            SectionLabel(text: "Chat model").padding(.top, 4)
            if envLocked {
                note("lock.fill", "Set by environment (GEL_LOCAL_MODEL): \(current)")
            } else if ModelCatalog.preset(for: current) == nil {
                note("slider.horizontal.3", "Using a custom model: \(current)")
            }
            VStack(spacing: 8) {
                ForEach(ModelCatalog.presets) { preset in
                    PresetCard(preset: preset, current: current, envLocked: envLocked,
                               running: isRunning, installed: setup.installedModels)
                }
            }
            Text("Speed: the demo question on an M2 with 16 GB, model loaded. Larger models we tried were slower and less accurate.")
                .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            Rectangle().fill(Theme.hairline).frame(height: 1)
            embeddingRow
        }
        .sheet(isPresented: $showInstall) { InstallOllamaSheet().tint(Theme.accent) }
        .task { await setup.refresh() }
    }

    private var isRunning: Bool { if case .running = setup.state { return true } else { return false } }

    @ViewBuilder private var ollamaRow: some View {
        HStack(spacing: 8) {
            switch setup.state {
            case .checking:
                StatusDot(color: Theme.textSecondary, pulsing: true)
                Text("Checking Ollama…").font(.system(size: 12))
                Spacer()
            case .running(let version):
                StatusDot(color: Theme.accent)
                Text("Ollama is running · v\(version)").font(.system(size: 12))
                Spacer()
            case .stopped:
                StatusDot(color: Theme.danger)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ollama is installed but not running.").font(.system(size: 12))
                    if let error = setup.startError {
                        Text(error).font(.system(size: 11)).foregroundStyle(Theme.danger)
                    }
                }
                Spacer()
                Button(setup.starting ? "Starting…" : "Start Ollama") { setup.start() }
                    .buttonStyle(.gelPrimary).disabled(setup.starting)
            case .notInstalled:
                StatusDot(color: Theme.danger)
                Text("Ollama isn't installed. Gel uses it to run AI on this Mac.").font(.system(size: 12))
                Spacer()
                Button("Install Ollama…") {
                    if !setup.install.isBusy { setup.install = .confirming }
                    showInstall = true
                }
                .buttonStyle(.gelPrimary)
            }
        }
        .frame(minHeight: 28)
    }

    private var embeddingRow: some View {
        let downloaded = ModelCatalog.isInstalled(ModelCatalog.embeddingTag, in: setup.installedModels)
        return HStack(spacing: 8) {
            Text("Embeddings").font(.system(size: 12, weight: .medium))
            Text("\(ModelCatalog.embeddingTag) · \(gigabytes(ModelCatalog.embeddingBytes))")
                .font(.system(size: 12).monospacedDigit()).foregroundStyle(Theme.textSecondary)
            if isRunning {
                if downloaded {
                    Label("downloaded", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 11)).foregroundStyle(Theme.accent)
                } else {
                    Text("downloads with your first model").font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
            Button("Warm up") { Task { await ModelRouter.shared.warmUp(); state.refreshHealth() } }
                .buttonStyle(.gelSecondary).disabled(!isRunning)
                .help("Load the chat model now so the first answer is quick.")
        }
    }

    private func note(_ symbol: String, _ text: String) -> some View {
        Label(text, systemImage: symbol).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
    }
}

/// One preset: tier, name, specs, warnings, and the action (or the download in progress) in a fixed-height row.
private struct PresetCard: View {
    @EnvironmentObject var state: AppState
    let preset: ModelPreset
    let current: String
    let envLocked: Bool
    let running: Bool
    let installed: [String]

    private var isCurrent: Bool { preset.tag == current || preset.tag + ":latest" == current }
    private var isInstalled: Bool { ModelCatalog.isInstalled(preset.tag, in: installed) }
    private var download: ModelDownload? { state.modelDownload?.tag == preset.tag ? state.modelDownload : nil }
    private var otherDownloadRunning: Bool { state.modelDownload.map { $0.tag != preset.tag && $0.isRunning } ?? false }

    /// Bytes this card would still download (the embedding model comes along if it's missing).
    private var missingBytes: Int64 {
        var n: Int64 = isInstalled ? 0 : preset.downloadBytes
        if !ModelCatalog.isInstalled(ModelCatalog.embeddingTag, in: installed) { n += ModelCatalog.embeddingBytes }
        return n
    }

    private var memoryGB: Int {
        #if DEBUG
        if let v = ProcessInfo.processInfo.environment["GEL_DEBUG_RAM_GB"].flatMap(Int.init) { return v }
        #endif
        return ModelCatalog.physicalMemoryGB
    }

    private var freeBytes: Int64? {
        #if DEBUG
        if let v = ProcessInfo.processInfo.environment["GEL_DEBUG_FREE_DISK_GB"].flatMap(Double.init) { return Int64(v * 1e9) }
        #endif
        return ModelCatalog.freeDiskBytes()
    }

    private var diskShort: Bool {
        guard running, missingBytes > 0, let free = freeBytes else { return false }
        return ModelCatalog.lacksDisk(needed: missingBytes, free: free)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(tierCaption).font(.system(size: 10, weight: .semibold)).tracking(0.5)
                    .foregroundStyle(Theme.accent)
                Text(preset.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                Text("\(gigabytes(preset.downloadBytes)) download · \(preset.recommendedRAMGB) GB RAM · \(speed)")
                    .font(.system(size: 11).monospacedDigit()).foregroundStyle(Theme.textSecondary)
                if ModelCatalog.lacksRAM(preset, memoryGB: memoryGB) {
                    warning("Needs \(preset.recommendedRAMGB) GB · this Mac has \(memoryGB) GB")
                }
                if diskShort, let free = freeBytes {
                    warning("Needs \(gigabytes(missingBytes + ModelCatalog.diskMargin)) free · \(gigabytes(free)) available")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            action.frame(width: 220, height: 44, alignment: .trailing)
        }
        .padding(12)
        .background(isCurrent ? Theme.accentSoft : Theme.canvas, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
            .strokeBorder(isCurrent ? Theme.accent.opacity(0.5) : Theme.hairline))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(preset.name), \(tierCaption)")
    }

    private var tierCaption: String {
        switch preset.tier {
        case .light: return "LIGHT"
        case .balanced: return "RECOMMENDED"
        case .quality: return "QUALITY"
        }
    }

    private var speed: String {
        guard let first = preset.firstWordsSeconds, let total = preset.totalSeconds else { return "Speed not measured yet" }
        return "≈ \(seconds(first)) to first words, \(seconds(total)) full answer"
    }

    @ViewBuilder private var action: some View {
        if let d = download, let error = d.error {
            VStack(alignment: .trailing, spacing: 4) {
                Text(error).font(.system(size: 11)).foregroundStyle(Theme.danger).lineLimit(2)
                Button("Retry") { state.dismissModelDownloadError(); state.useModel(preset) }
                    .buttonStyle(.gelSecondary).disabled(!running)
            }
        } else if let d = download {
            VStack(alignment: .trailing, spacing: 5) {
                GelProgressBar(value: d.fraction, total: 1, height: 4, animated: false)
                HStack(spacing: 6) {
                    Text("\(d.percent)% · \(gigabytes(d.completed, digits: 1)) of \(gigabytes(d.total))")
                        .font(.system(size: 11).monospacedDigit()).foregroundStyle(Theme.textSecondary)
                        .lineLimit(1).minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                    Button("Cancel") { state.cancelModelDownload() }.buttonStyle(.gelSecondary)
                }
            }
        } else if isCurrent && isInstalled {
            Label("In use", systemImage: "checkmark.circle.fill")
                .font(.system(size: 12, weight: .medium)).foregroundStyle(Theme.accent)
        } else {
            Button(isInstalled ? "Use" : (isCurrent ? "Download" : "Download & use")) { state.useModel(preset) }
                .buttonStyle(.gelPrimary)
                .disabled(envLocked || !running || otherDownloadRunning || diskShort)
                .help(!running ? "Start Ollama first" : envLocked ? "Set by environment (GEL_LOCAL_MODEL)" : "")
        }
    }

    private func warning(_ text: String) -> some View {
        Label(text, systemImage: "exclamationmark.triangle.fill")
            .font(.system(size: 11)).foregroundStyle(.orange)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func seconds(_ s: Double) -> String { s < 10 ? String(format: "%.1f s", s) : "\(Int(s.rounded())) s" }
}

/// Confirm → download → check signature → open. Sized for its content; cancel works until the move.
struct InstallOllamaSheet: View {
    @ObservedObject private var setup = OllamaSetup.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                IconChip(symbol: "arrow.down.app", size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 17, weight: .semibold))
                    Text("Ollama runs the AI models on this Mac.").font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
                }
            }
            content
            HStack {
                Spacer()
                buttons
            }
        }
        .padding(22)
        .frame(width: 440)
        .interactiveDismissDisabled(setup.install.isBusy)
        .onChange(of: setup.install) { old, new in
            if old == .opening && new == .idle { dismiss() }
        }
    }

    private var title: String {
        switch setup.install {
        case .downloading: return "Downloading Ollama…"
        case .verifying: return "Checking signature…"
        case .opening: return "Opening Ollama…"
        case .failed: return "Ollama wasn't installed"
        default: return "Install Ollama"
        }
    }

    @ViewBuilder private var content: some View {
        switch setup.install {
        case .downloading(let received, let total):
            VStack(alignment: .leading, spacing: 6) {
                GelProgressBar(value: Double(received), total: Double(max(total, 1)), height: 6, animated: false)
                Text("\(received / 1_000_000) of \(total / 1_000_000) MB")
                    .font(.system(size: 12).monospacedDigit()).foregroundStyle(Theme.textSecondary)
            }
        case .verifying:
            step("checkmark.shield", "Making sure the app is signed by Ollama…")
        case .opening:
            step("arrow.up.forward.app", "Moving it to \(setup.destinationFolder.path) and opening it…")
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 12)).foregroundStyle(Theme.danger)
                .fixedSize(horizontal: false, vertical: true)
        default:
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
                row("Source", "ollama.com (the official app)")
                row("Size", "about \(OllamaSetup.approxDownloadMB) MB")
                row("Location", setup.destinationFolder.path)
            }
            Label("None of your files are sent. This only downloads the Ollama app.", systemImage: "lock.shield")
                .font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
        }
    }

    @ViewBuilder private var buttons: some View {
        switch setup.install {
        case .downloading:
            Button("Cancel") { setup.cancelInstall(); dismiss() }.buttonStyle(.gelSecondary)
        case .verifying, .opening:
            Button("Cancel") {}.buttonStyle(.gelSecondary).disabled(true)
        case .failed:
            Button("Open download page") { NSWorkspace.shared.open(OllamaSetup.downloadPage) }.buttonStyle(.gelSecondary)
            Button("Close") { setup.install = .idle; dismiss() }.buttonStyle(.gelPrimary)
        default:
            Button("Cancel") { setup.install = .idle; dismiss() }.buttonStyle(.gelSecondary)
                .keyboardShortcut(.cancelAction)
            Button("Install") { setup.runInstall() }.buttonStyle(.gelPrimary)
                .keyboardShortcut(.defaultAction)
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label).font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
            Text(value).font(.system(size: 12)).textSelection(.enabled)
        }
    }

    private func step(_ symbol: String, _ text: String) -> some View {
        Label(text, systemImage: symbol).font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
    }
}

/// "2.5 GB" (or "1.1 GB" with one decimal for progress).
private func gigabytes(_ bytes: Int64, digits: Int = 1) -> String {
    String(format: "%.\(digits)f GB", Double(bytes) / 1e9)
}
