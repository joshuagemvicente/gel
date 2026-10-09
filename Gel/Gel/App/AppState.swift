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

/// The single source of UI state. Views observe it; engine work goes through GelCore.
@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var selectedModule: Module = .home
    @Published var indexProgress: IndexProgress?
    @Published var localStatus: LocalStatus = .checking
    @Published var policy: TeamPolicy?
    @Published var activePacks: [String] = GelSettings.shared.activePacks
    @Published var folderPath: String? = GelSettings.shared.folderPath
    @Published var leakGuardPaused = false
    /// Set when a citation should be opened in the Library viewer.
    @Published var pendingCitation: Citation?
    /// Set when History should select a specific answer.
    @Published var pendingHistoryId: Int64?
    @Published var showOnboarding = !GelSettings.shared.onboardingDone
    @Published var documentsVersion = 0
    @Published var activityVersion = 0

    private var rescanTimer: Timer?
    private var healthTimer: Timer?
    private var isIndexing = false

    var settings: GelSettings { .shared }

    // MARK: - Launch

    func start() {
        reloadPolicy()
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
            let healthy = await ModelRouter.shared.localIsHealthy()
            let cooldown = ModelRouter.shared.isInCloudCooldown
            await MainActor.run {
                if cooldown { localStatus = .cloudActive }
                else { localStatus = healthy ? .healthy : .unavailable }
            }
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

    func setFolder(_ url: URL) {
        settings.folderPath = url.path
        folderPath = url.path
        Task { await indexNow() }
    }

    private func startRescan() {
        rescanTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            Task { @MainActor in await AppState.shared.indexNow(onlyIfPending: true) }
        }
        Task { await indexNow() }
    }

    func indexNow(onlyIfPending: Bool = false) async {
        guard !isIndexing, let path = folderPath else { return }
        let folder = URL(fileURLWithPath: path)
        let indexer = Indexer()
        if onlyIfPending && indexer.pending(in: folder).isEmpty { return }
        isIndexing = true
        defer { isIndexing = false }
        do {
            _ = try await indexer.index(folder: folder) { progress in
                Task { @MainActor in
                    AppState.shared.indexProgress = progress.isRunning ? progress : nil
                }
            }
        } catch {
            NSLog("Gel: indexing failed: \(error)")
        }
        indexProgress = nil
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
