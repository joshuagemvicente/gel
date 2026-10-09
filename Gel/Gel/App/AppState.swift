import SwiftUI
import GelCore

enum Module: String, CaseIterable, Identifiable {
    case home, history, library, redactions, settings
    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .history: return "History"
        case .library: return "Library"
        case .redactions: return "Redactions & Leak Guard"
        case .settings: return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .home: return "house"
        case .history: return "clock.arrow.circlepath"
        case .library: return "books.vertical"
        case .redactions: return "lock.shield"
        case .settings: return "gearshape"
        }
    }
}

enum LocalStatus: Equatable {
    case checking, healthy, cloudActive, unavailable

    var menuTitle: String {
        switch self {
        case .checking: return "Checking local model…"
        case .healthy: return "Local ✓  ·  answers run on this Mac"
        case .cloudActive: return "Cloud fallback active"
        case .unavailable: return "Local model unavailable"
        }
    }
}

extension Notification.Name {
    /// Posted after a query, redaction or caught leak so Home and lists refresh.
    static let gelActivityChanged = Notification.Name("GelActivityChanged")
}

struct ModelDownload: Equatable {
    var tag: String
    var title: String
    var completed: Int64
    var total: Int64
    var error: String?

    var fraction: Double { total > 0 ? min(1, Double(completed) / Double(total)) : 0 }
    var percent: Int { Int(fraction * 100) }
    var isRunning: Bool { error == nil }
}

/// The single source of UI state. Views observe it; engine work goes through GelCore.
@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var selectedModule: Module = .home
    @Published var indexProgress: IndexProgress?
    @Published var localStatus: LocalStatus = .checking
    @Published var policy: TeamPolicy?
    @Published var activePacks: [String] = GelSettings.shared.activePacks
    @Published var folderPaths: [String] = GelSettings.shared.folderPaths
    @Published var leakGuardPaused = false
    /// Set when a citation should be opened in the Library viewer.
    @Published var pendingCitation: Citation?
    /// Set when History should select a specific answer.
    @Published var pendingHistoryId: Int64?
    @Published var showOnboarding = !GelSettings.shared.onboardingDone
    @Published var documentsVersion = 0
    /// Listed folders that are missing or unreadable (E2); their part of the index is kept untouched.
    @Published var missingFolders: Set<String> = []
    /// Notes from the last add, e.g. "Already included in HR Files."
    @Published var folderNotes: [String] = []
    /// Files that couldn't be read in the last indexing pass (E8).
    @Published var unreadable: [(name: String, reason: String)] = []
    /// Required Ollama models that aren't installed (Q5); shown as "Model missing — run ollama pull …".
    @Published var missingModels: [String] = []
    @Published var activityVersion = 0
    /// The model download started from Settings › Models (U11); nil when none is running or failed.
    @Published var modelDownload: ModelDownload?

    private var rescanTimer: Timer?
    private var healthTimer: Timer?
    private var isIndexing = false
    private var downloadTask: Task<Void, Never>?

    var settings: GelSettings { .shared }

    // MARK: - Launch

    func start() {
        reloadPolicy()
        Indexer().pruneOutside(folderURLs)
        startRescan()
        Task { await ModelRouter.shared.warmUp() }
        refreshHealth()
        healthTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task { @MainActor in AppState.shared.refreshHealth() }
        }
        NotificationCenter.default.addObserver(forName: .gelActivityChanged, object: nil, queue: .main) { _ in
            Task { @MainActor in AppState.shared.activityVersion += 1 }
        }
    }

    func reloadPolicy() {
        policy = TeamPolicy.load()
        ModelRouter.shared.cloudAllowedByPolicy = policy?.allowCloudFallback ?? true
        if let required = policy?.requiredPacks {
            let merged = Array(Set(activePacks + required)).sorted()
            setPacks(merged)
        }
    }

    func refreshHealth() {
        Task {
            let missing = await ModelRouter.shared.missingLocalModels()
            let healthy = missing?.isEmpty == true
            let cooldown = ModelRouter.shared.isInCloudCooldown
            await MainActor.run {
                missingModels = missing ?? []
                if cooldown { localStatus = .cloudActive }
                else { localStatus = healthy ? .healthy : .unavailable }
            }
            await OllamaSetup.shared.refresh()
        }
    }

    // MARK: - Model download (U11)

    /// Downloads whatever `preset` still needs (bge-m3 first, then the chat model), then switches to it and warms it up.
    func useModel(_ preset: ModelPreset) {
        guard downloadTask == nil, !settings.localModelFromEnvironment else { return }
        let installed = OllamaSetup.shared.installedModels
        let needed = [(ModelCatalog.embeddingTag, ModelCatalog.embeddingBytes), (preset.tag, preset.downloadBytes)]
            .filter { !ModelCatalog.isInstalled($0.0, in: installed) }
        guard !needed.isEmpty else { return switchModel(to: preset) }
        let planned = needed.reduce(Int64(0)) { $0 + $1.1 }
        modelDownload = ModelDownload(tag: preset.tag, title: preset.name, completed: 0, total: planned)
        downloadTask = Task {
            var finished: Int64 = 0
            do {
                for (tag, expected) in needed {
                    let base = finished
                    try await OllamaAPI.pull(tag) { p in
                        // Publish whole-percent steps only: progress lines arrive many times a second.
                        let total = max(planned, base + p.total)
                        let completed = base + p.completed
                        Task { @MainActor in
                            guard var d = AppState.shared.modelDownload, d.tag == preset.tag, d.error == nil else { return }
                            let before = d.percent
                            d.completed = completed; d.total = total
                            if d.percent != before { AppState.shared.modelDownload = d }
                        }
                    }
                    finished += expected
                }
                guard !Task.isCancelled else { return }
                downloadTask = nil
                modelDownload = nil
                switchModel(to: preset)
            } catch {
                // Cancel already cleared the state (and a new download may own it now).
                guard !Task.isCancelled else { return }
                downloadTask = nil
                modelDownload?.error = error.localizedDescription
            }
            await OllamaSetup.shared.refresh()
        }
    }

    func cancelModelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        modelDownload = nil
    }

    func dismissModelDownloadError() { if modelDownload?.error != nil { modelDownload = nil } }

    private func switchModel(to preset: ModelPreset) {
        settings.localModel = preset.tag
        objectWillChange.send()
        Task {
            await ModelRouter.shared.warmUp()
            refreshHealth()
        }
    }

    // MARK: - Packs

    func isLocked(pack id: String) -> Bool { policy?.requiredPacks?.contains(id) ?? false }

    func setPacks(_ packs: [String]) {
        var result = packs
        for r in policy?.requiredPacks ?? [] where !result.contains(r) { result.append(r) }
        activePacks = result.sorted()
        settings.activePacks = activePacks
    }

    func toggle(pack id: String) {
        guard !isLocked(pack: id) else { return }
        if activePacks.contains(id) { setPacks(activePacks.filter { $0 != id }) } else { setPacks(activePacks + [id]) }
    }

    // MARK: - Folder and indexing

    var folderPathsLocked: Bool { settings.folderPathsFromEnvironment }
    private var folderURLs: [URL] { folderPaths.map { URL(fileURLWithPath: $0) } }

    /// Adds folders (duplicates and nested folders are folded in by `FolderList`) and indexes what's new.
    func addFolders(_ urls: [URL]) {
        guard !folderPathsLocked else { return }
        let (list, notes) = FolderList.adding(urls.map(\.path), to: folderPaths)
        folderNotes = notes.map { note in
            let name = { (p: String) in URL(fileURLWithPath: p).lastPathComponent }
            switch note {
            case .alreadyIncluded(_, let parent): return "Already included in \(name(parent))."
            case .replaced(let parent, let n): return "\(name(parent)) now includes \(n) folder\(n == 1 ? "" : "s") you'd added."
            }
        }
        guard list != folderPaths else { return }
        settings.folderPaths = list
        folderPaths = list
        documentsVersion += 1
        Task { await indexNow() }
    }

    /// Stops reading a folder: its documents leave the index. Files on disk are untouched.
    func removeFolder(_ path: String) {
        guard !folderPathsLocked else { return }
        folderPaths.removeAll { $0 == path }
        settings.folderPaths = folderPaths
        missingFolders.remove(path)
        folderNotes = []
        unreadable = []
        Indexer().pruneOutside(folderURLs)
        documentsVersion += 1
    }

    private func startRescan() {
        rescanTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            Task { @MainActor in await AppState.shared.indexNow(onlyIfPending: true) }
        }
        Task { await indexNow() }
    }

    func indexNow(onlyIfPending: Bool = false) async {
        guard !isIndexing, !folderPaths.isEmpty else { return }
        // E2: a missing folder (unplugged drive, renamed) is skipped and never prunes the index.
        let missing = Set(folderPaths.filter { !Indexer.folderExists(URL(fileURLWithPath: $0)) })
        if missing != missingFolders { missingFolders = missing }
        let reachable = folderURLs.filter { !missing.contains($0.path) }
        let indexer = Indexer()
        if onlyIfPending && reachable.allSatisfy({ indexer.pending(in: $0).isEmpty }) { return }
        isIndexing = true
        defer { isIndexing = false }
        let result = await indexer.index(folders: reachable) { progress in
            Task { @MainActor in
                // Publish only real changes (one per file), so bound UI doesn't re-layout on every tick.
                let next: IndexProgress? = progress.isRunning ? progress : nil
                if AppState.shared.indexProgress != next { AppState.shared.indexProgress = next }
            }
        }
        if !result.failures.isEmpty || !onlyIfPending { unreadable = result.failures }
        // A folder removed while this pass ran may have had files re-added; drop them.
        indexer.pruneOutside(folderURLs)
        if indexProgress != nil { indexProgress = nil }
        documentsVersion += 1
    }

    // MARK: - Navigation

    func open(citation: Citation) {
        pendingCitation = citation
        selectedModule = .library
        AppDelegate.shared?.showMainWindow()
    }

    func open(module: Module) {
        selectedModule = module
        AppDelegate.shared?.showMainWindow()
    }
}
