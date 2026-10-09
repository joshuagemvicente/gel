import SwiftUI
import AVFoundation
import KeyboardShortcuts
import GelCore

struct SettingsView: View {
    @EnvironmentObject var state: AppState
    @State private var cloudEnabled = GelSettings.shared.cloudEnabled
    @State private var baseURL = GelSettings.shared.cloudBaseURL
    @State private var cloudModel = GelSettings.shared.cloudModel
    @State private var newKey = ""
    @State private var hasKey = !GelSettings.shared.cloudAPIKey.isEmpty
    @State private var firstToken = GelSettings.shared.firstTokenTimeout
    @State private var total = GelSettings.shared.totalTimeout
    @State private var testResult: (ok: Bool, text: String)?
    @State private var testing = false
    @State private var micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    @State private var axTrusted = AXIsProcessTrusted()

    private let env = ProcessInfo.processInfo.environment
    private var org: String? { state.policy?.organization }
    private var cloudLocked: Bool { state.policy?.allowCloudFallback == false }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ModuleHeader(title: "Settings").padding(.bottom, 6)
                folderCard
                packsCard
                modelsCard
                cloudCard
                hotkeysCard
                permissionsCard
                policyCard
            }
            .frame(maxWidth: 640, alignment: .leading)
            .padding(28)
        }
        .onAppear { refreshPermissions() }
    }

    private func section<C: View>(_ title: String, _ subtitle: String, @ViewBuilder _ content: () -> C) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text(title).font(.system(size: 15, weight: .semibold))
                Text(subtitle).font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
                content()
            }
        }
    }

    private var folderCard: some View {
        section("Folder", "Gel reads this folder and its subfolders. Files never leave your Mac.") {
            HStack {
                Text(state.folderPath ?? "No folder chosen").font(.system(size: 12, design: .monospaced)).lineLimit(1).truncationMode(.middle)
                Spacer()
                Button("Choose…") { chooseFolder() }
                Button("Reindex now") { Task { await state.indexNow() } }.disabled(state.folderPath == nil)
            }
            Text("\(Store.shared.documents().count) files · \(Store.shared.chunkCount) passages indexed")
                .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
        }
    }

    private var packsCard: some View {
        section("Packs", "Choose what personal data Gel looks for.") {
            ForEach(PackStore.shared.selectablePacks) { pack in
                VStack(alignment: .leading, spacing: 2) {
                    Toggle(isOn: Binding(get: { state.activePacks.contains(pack.id) }, set: { _ in state.toggle(pack: pack.id) })) {
                        VStack(alignment: .leading) {
                            Text(pack.name).font(.system(size: 13, weight: .medium))
                            Text(pack.description).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .disabled(state.isLocked(pack: pack.id))
                    if state.isLocked(pack: pack.id), let org { LockedLabel(organization: org) }
                }
            }
        }
    }

    private var modelsCard: some View {
        section("Models", "These run on this Mac through Ollama.") {
            LabeledContent("Chat model", value: GelSettings.shared.localModel)
            LabeledContent("Embedding model", value: GelSettings.shared.embedModel)
            HStack {
                Circle().fill(state.localStatus == .unavailable ? Theme.danger : Theme.accent).frame(width: 8, height: 8)
                Text(state.localStatus == .unavailable ? "Ollama isn't running. Start it with `brew services start ollama`." : "Ollama is running.")
                    .font(.system(size: 12))
                Spacer()
                Button("Warm up") { Task { await ModelRouter.shared.warmUp(); state.refreshHealth() } }
            }
        }
    }

    private var cloudCard: some View {
        section("Cloud fallback", "Used only if the local model fails. It receives redacted text only.") {
            if env["GEL_CLOUD_BASE_URL"] != nil {
                Text("Set by environment variables (GEL_CLOUD_*).").font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            }
            Toggle("Enable cloud fallback", isOn: $cloudEnabled)
                .disabled(cloudLocked || baseURL.isEmpty || cloudModel.isEmpty)
                .onChange(of: cloudEnabled) { _, v in GelSettings.shared.cloudEnabled = v }
            if cloudLocked, let org { LockedLabel(organization: org) }
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    Text("Base URL").foregroundStyle(Theme.textSecondary)
                    TextField("https://…/v1", text: $baseURL).textFieldStyle(.roundedBorder)
                        .onSubmit { GelSettings.shared.cloudBaseURL = baseURL }
                        .onChange(of: baseURL) { _, v in GelSettings.shared.cloudBaseURL = v }
                }
                GridRow {
                    Text("API key").foregroundStyle(Theme.textSecondary)
                    HStack {
                        SecureField(hasKey ? "Saved in Keychain — type to replace" : "Paste key", text: $newKey).textFieldStyle(.roundedBorder)
                        Button("Save") {
                            GelSettings.shared.cloudAPIKey = newKey
                            hasKey = !newKey.isEmpty
                            newKey = ""
                        }.disabled(newKey.isEmpty)
                    }
                }
                GridRow {
                    Text("Model").foregroundStyle(Theme.textSecondary)
                    TextField("model id", text: $cloudModel).textFieldStyle(.roundedBorder)
                        .onChange(of: cloudModel) { _, v in GelSettings.shared.cloudModel = v }
                }
                GridRow {
                    Text("Timeouts").foregroundStyle(Theme.textSecondary)
                    HStack {
                        Text("First token"); TextField("", value: $firstToken, format: .number).frame(width: 44)
                            .onChange(of: firstToken) { _, v in GelSettings.shared.firstTokenTimeout = v }
                        Text("s   Total"); TextField("", value: $total, format: .number).frame(width: 44)
                            .onChange(of: total) { _, v in GelSettings.shared.totalTimeout = v }
                        Text("s")
                    }
                }
            }
            .font(.system(size: 12))
            .disabled(cloudLocked)
            HStack {
                Button("Test connection") { test() }.disabled(baseURL.isEmpty || testing)
                if testing { ProgressView().controlSize(.small) }
                if let r = testResult {
                    Text(r.text).font(.system(size: 11)).foregroundStyle(r.ok ? Theme.accent : Theme.danger).textSelection(.enabled)
                }
            }
        }
    }

    private var hotkeysCard: some View {
        section("Hotkeys", "Open the launcher and paste safely from anywhere.") {
            KeyboardShortcuts.Recorder("Launcher", name: .toggleLauncher)
            KeyboardShortcuts.Recorder("Safe paste (redacted)", name: .safePaste)
        }
    }

    private var permissionsCard: some View {
        section("Permissions", "Gel asks only for what a feature needs.") {
            permissionRow("Microphone", granted: micStatus == .authorized, detail: "for hold-to-talk",
                          link: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
            permissionRow("Accessibility", granted: axTrusted, detail: "for ⌥⌘V safe paste",
                          link: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
            Button("Refresh") { refreshPermissions() }.buttonStyle(.link).font(.system(size: 11))
        }
    }

    private func permissionRow(_ name: String, granted: Bool, detail: String, link: String) -> some View {
        HStack {
            Image(systemName: granted ? "checkmark.circle.fill" : "circle").foregroundStyle(granted ? Theme.accent : Theme.textSecondary)
            Text(name).font(.system(size: 13))
            Text(detail).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            Spacer()
            if !granted { Button("Open System Settings") { NSWorkspace.shared.open(URL(string: link)!) } }
        }
    }

    private var policyCard: some View {
        section("Policy", "Your organization can manage some settings.") {
            Text(org.map { "Managed by \($0)" } ?? "Not managed").font(.system(size: 13, weight: .medium))
            HStack {
                Button("Install sample policy") {
                    if let data = try? JSONEncoder().encode(TeamPolicy.sample) { try? data.write(to: GelPaths.policy) }
                    state.reloadPolicy()
                }
                Button("Remove policy") {
                    try? FileManager.default.removeItem(at: GelPaths.policy)
                    state.reloadPolicy()
                }.disabled(state.policy == nil)
            }
        }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url { state.setFolder(url) }
    }

    private func test() {
        testing = true
        testResult = nil
        let client = OpenAICompatibleClient(baseURL: baseURL, apiKey: GelSettings.shared.cloudAPIKey, model: cloudModel)
        Task {
            do {
                let models = try await client.listModels()
                testResult = (true, "✓ OK · \(models.count) models")
            } catch {
                testResult = (false, "✕ " + ((error as? LocalizedError)?.errorDescription ?? error.localizedDescription))
            }
            testing = false
        }
    }

    private func refreshPermissions() {
        micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        axTrusted = AXIsProcessTrusted()
    }
}
