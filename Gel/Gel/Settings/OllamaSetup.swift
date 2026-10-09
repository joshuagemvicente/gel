import AppKit
import Security
import GelCore

/// Finds, starts and installs Ollama for Settings › Models (U11). Nothing here runs without a click.
@MainActor
final class OllamaSetup: ObservableObject {
    static let shared = OllamaSetup()

    enum State: Equatable { case checking, notInstalled, stopped, running(version: String) }

    enum Install: Equatable {
        case idle, confirming
        case downloading(received: Int64, total: Int64)
        case verifying, opening
        case failed(String)

        var isBusy: Bool {
            switch self {
            case .downloading, .verifying, .opening: return true
            default: return false
            }
        }
    }

    @Published private(set) var state: State = .checking
    @Published private(set) var installedModels: [String] = []
    @Published private(set) var starting = false
    @Published private(set) var startError: String?
    @Published var install: Install = .idle

    static let downloadURL = URL(string: "https://ollama.com/download/Ollama-darwin.zip")!
    static let downloadPage = URL(string: "https://ollama.com/download")!
    static let approxDownloadMB = 206
    nonisolated private static let bundleID = "com.electron.ollama"
    /// Ollama's Developer ID (Infra Technologies, Inc), read from the notarized app on 2026-10-10.
    nonisolated private static let teamID = "3MU9H2V9Y9"
    private static let binaryPaths = ["/opt/homebrew/bin/ollama", "/usr/local/bin/ollama"]

    private var downloader: AppDownloader?

    // MARK: - Detection

    private var env: [String: String] { ProcessInfo.processInfo.environment }

    /// DEBUG only: behave as if Ollama were absent, so the install flow can be tried on a Mac that has it (U11 AC2).
    private var pretendMissing: Bool {
        #if DEBUG
        return env["GEL_DEBUG_PRETEND_NO_OLLAMA"] == "1"
        #else
        return false
        #endif
    }

    /// Where Install puts Ollama.app: /Applications, or ~/Applications when that isn't writable.
    var destinationFolder: URL {
        #if DEBUG
        if let dir = env["GEL_DEBUG_OLLAMA_INSTALL_DIR"], !dir.isEmpty { return URL(fileURLWithPath: dir, isDirectory: true) }
        #endif
        if FileManager.default.isWritableFile(atPath: "/Applications") { return URL(fileURLWithPath: "/Applications", isDirectory: true) }
        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true)
    }

    private var appURL: URL? {
        let fm = FileManager.default
        if pretendMissing {
            let scratch = destinationFolder.appendingPathComponent("Ollama.app")
            return fm.fileExists(atPath: scratch.path) ? scratch : nil
        }
        let candidates = [URL(fileURLWithPath: "/Applications/Ollama.app"),
                          fm.homeDirectoryForCurrentUser.appendingPathComponent("Applications/Ollama.app")]
        if let found = candidates.first(where: { fm.fileExists(atPath: $0.path) }) { return found }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.bundleID)
    }

    private var binaryPath: String? {
        pretendMissing ? nil : Self.binaryPaths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    var isInstalled: Bool { appURL != nil || binaryPath != nil }

    func refresh() async {
        let version = await OllamaAPI.version()
        let models = await OllamaAPI.installedModels() ?? []
        let next: State
        if !isInstalled { next = .notInstalled }
        else if let version { next = .running(version: version) }
        else { next = .stopped }
        if state != next { state = next }
        if installedModels != models { installedModels = models }
    }

    // MARK: - Start

    /// Opens Ollama.app when there is one, otherwise runs Homebrew's `ollama serve`, then waits up to 20 s for it.
    func start() {
        guard !starting else { return }
        starting = true
        startError = nil
        Task {
            defer { starting = false }
            if let app = appURL {
                let config = NSWorkspace.OpenConfiguration()
                config.activates = false
                _ = try? await NSWorkspace.shared.openApplication(at: app, configuration: config)
            } else if let binary = binaryPath {
                let p = Process()
                p.executableURL = URL(fileURLWithPath: binary)
                p.arguments = ["serve"]
                p.standardOutput = FileHandle.nullDevice
                p.standardError = FileHandle.nullDevice
                do { try p.run() } catch { startError = "Couldn't start Ollama: \(error.localizedDescription)"; return }
            }
            for _ in 0..<20 {
                if await OllamaAPI.version() != nil { break }
                try? await Task.sleep(for: .seconds(1))
            }
            await refresh()
            AppState.shared.refreshHealth()
            if case .stopped = state { startError = "Ollama didn't start within 20 seconds. Try opening it yourself." }
        }
    }

    // MARK: - Install

    func cancelInstall() {
        downloader?.cancel()
        downloader = nil
        install = .idle
    }

    /// Download → unzip → check the signature → move into place → open. Any failure installs nothing.
    func runInstall() {
        guard !install.isBusy else { return }
        install = .downloading(received: 0, total: Int64(Self.approxDownloadMB) * 1_000_000)
        let downloader = AppDownloader()
        self.downloader = downloader
        let destination = destinationFolder
        Task {
            let work = FileManager.default.temporaryDirectory.appendingPathComponent("gel-ollama-\(UUID().uuidString)", isDirectory: true)
            defer { try? FileManager.default.removeItem(at: work) }
            do {
                try FileManager.default.createDirectory(at: work, withIntermediateDirectories: true)
                let zip = work.appendingPathComponent("Ollama-darwin.zip")
                try await downloader.download(Self.downloadURL, to: zip) { received, total in
                    Task { @MainActor in
                        guard case .downloading = OllamaSetup.shared.install else { return }
                        OllamaSetup.shared.install = .downloading(received: received, total: total)
                    }
                }
                guard self.downloader === downloader else { return }  // cancelled
                install = .verifying
                let unpacked = work.appendingPathComponent("unpacked", isDirectory: true)
                try await Self.unzip(zip, to: unpacked)
                let app = unpacked.appendingPathComponent("Ollama.app")
                #if DEBUG
                // U11 AC2: change one file inside the bundle, so the signature check must refuse it.
                if env["GEL_DEBUG_OLLAMA_TAMPER"] == "1" {
                    try Data("tampered".utf8).write(to: app.appendingPathComponent("Contents/Resources/icon.icns"))
                }
                #endif
                try Self.verifySignature(of: app)
                install = .opening
                try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
                let target = destination.appendingPathComponent("Ollama.app")
                if FileManager.default.fileExists(atPath: target.path) {
                    throw SetupError("An Ollama.app is already in \(destination.path).")
                }
                try FileManager.default.moveItem(at: app, to: target)
                self.downloader = nil
                install = .idle
                await refresh()
                start()
            } catch is CancellationError {
                install = .idle
            } catch {
                guard self.downloader === downloader else { return }
                self.downloader = nil
                install = .failed(error.localizedDescription)
            }
        }
    }

    private static func unzip(_ zip: URL, to folder: URL) async throws {
        try await Task.detached {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            p.arguments = ["-x", "-k", zip.path, folder.path]
            try p.run()
            p.waitUntilExit()
            guard p.terminationStatus == 0 else { throw SetupError("The download couldn't be unpacked.") }
        }.value
        guard FileManager.default.fileExists(atPath: folder.appendingPathComponent("Ollama.app").path) else {
            throw SetupError("The download didn't contain Ollama.app.")
        }
    }

    /// The app must be intact (strict check of every nested binary) and signed by Ollama's Developer ID.
    nonisolated static func verifySignature(of app: URL) throws {
        var code: SecStaticCode?
        guard SecStaticCodeCreateWithPath(app as CFURL, [], &code) == errSecSuccess, let code else {
            throw SetupError("Couldn't read the app's signature.")
        }
        var requirement: SecRequirement?
        let text = "identifier \"\(bundleID)\" and anchor apple generic and certificate leaf[subject.OU] = \"\(teamID)\""
        guard SecRequirementCreateWithString(text as CFString, [], &requirement) == errSecSuccess else {
            throw SetupError("Couldn't build the signature check.")
        }
        let flags = SecCSFlags(rawValue: kSecCSCheckAllArchitectures | kSecCSStrictValidate | kSecCSCheckNestedCode)
        let status = SecStaticCodeCheckValidity(code, flags, requirement)
        guard status == errSecSuccess else {
            throw SetupError("The downloaded app isn't signed by Ollama (code \(status)), so Gel didn't install it.")
        }
    }
}

struct SetupError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}

/// A file download with byte progress and cancellation.
final class AppDownloader: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private var session: URLSession?
    private var continuation: CheckedContinuation<Void, Error>?
    private var destination: URL?
    private var onProgress: ((Int64, Int64) -> Void)?
    private var lastReport = Date.distantPast

    func download(_ url: URL, to destination: URL, onProgress: @escaping (Int64, Int64) -> Void) async throws {
        self.destination = destination
        self.onProgress = onProgress
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            continuation = c
            let session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil)
            self.session = session
            session.downloadTask(with: url).resume()
        }
    }

    func cancel() {
        session?.invalidateAndCancel()
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        // A few updates a second is plenty; each one re-renders the sheet.
        guard Date().timeIntervalSince(lastReport) > 0.2 else { return }
        lastReport = Date()
        onProgress?(totalBytesWritten, max(totalBytesExpectedToWrite, totalBytesWritten))
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let destination else { return }
        let status = (downloadTask.response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            finish(SetupError("Download failed (HTTP \(status)).")); return
        }
        do {
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.moveItem(at: location, to: destination)
            finish(nil)
        } catch { finish(error) }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }
        finish((error as? URLError)?.code == .cancelled ? CancellationError() : error)
    }

    private func finish(_ error: Error?) {
        guard let c = continuation else { return }
        continuation = nil
        session?.finishTasksAndInvalidate()
        if let error { c.resume(throwing: error) } else { c.resume() }
    }
}
