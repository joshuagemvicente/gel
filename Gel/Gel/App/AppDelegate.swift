import AppKit
import SwiftUI
import KeyboardShortcuts
import GelCore

extension KeyboardShortcuts.Name {
    static let toggleLauncher = Self("toggleLauncher", default: .init(.space, modifiers: [.option]))
    static let safePaste = Self("safePaste", default: .init(.v, modifiers: [.option, .command]))
}

/// Owns the main window, the menu bar item, the launcher and the background services.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    static private(set) weak var shared: AppDelegate?

    private var mainWindow: NSWindow?
    private var statusItem: NSStatusItem?
    let launcher = LauncherController()
    let leakGuard = LeakGuardMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        NSApp.setActivationPolicy(.regular)
        OutputMuter.shared.restore()  // sound Gel muted before a crash mid-recording
        AppState.shared.start()
        setUpStatusItem()
        KeyboardShortcuts.onKeyUp(for: .toggleLauncher) { [weak self] in self?.launcher.toggle() }
        KeyboardShortcuts.onKeyUp(for: .safePaste) { [weak self] in self?.leakGuard.safePaste() }
        leakGuard.start()
        VoiceRecorder.shared.load()
        #if DEBUG
        installDebugHooks()
        #endif
        showMainWindow()
    }

    func applicationWillTerminate(_ notification: Notification) {
        OutputMuter.shared.restore()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }

    #if DEBUG
    /// Test-only hooks (D-038): `gel.debug.ask` {q}, `gel.debug.chip` {n}, `gel.debug.module` {name}, `gel.debug.appearance` {light|dark}, `gel.debug.leak` {blocked?}, `gel.debug.addFolders` {paths separated by ":"} (D-052), `gel.debug.holdToTalk` {down|up} (D-059). Not compiled into Release.
    private func installDebugHooks() {
        let center = DistributedNotificationCenter.default()
        center.addObserver(forName: Notification.Name("gel.debug.ask"), object: nil, queue: .main) { [weak self] note in
            let q = (note.object as? String) ?? ""
            Task { @MainActor in
                self?.launcher.show()
                self?.launcher.model.query = q
                self?.launcher.model.run()
            }
        }
        center.addObserver(forName: Notification.Name("gel.debug.module"), object: nil, queue: .main) { note in
            let name = (note.object as? String) ?? "home"
            Task { @MainActor in if let m = Module(rawValue: name) { AppState.shared.open(module: m) } }
        }
        center.addObserver(forName: Notification.Name("gel.debug.appearance"), object: nil, queue: .main) { note in
            let name = (note.object as? String) ?? ""
            Task { @MainActor in NSApp.appearance = name == "light" ? NSAppearance(named: .aqua) : (name == "dark" ? NSAppearance(named: .darkAqua) : nil) }
        }
        center.addObserver(forName: Notification.Name("gel.debug.leak"), object: nil, queue: .main) { [weak self] note in
            let blocked = (note.object as? String) == "blocked"
            Task { @MainActor in self?.leakGuard.debugShow(blocked: blocked) }
        }
        center.addObserver(forName: Notification.Name("gel.debug.holdToTalk"), object: nil, queue: .main) { [weak self] note in
            let down = (note.object as? String) == "down"
            Task { @MainActor in
                if down { self?.launcher.show() }
                self?.launcher.model.optionKey(down: down)
            }
        }
        center.addObserver(forName: Notification.Name("gel.debug.addFolders"), object: nil, queue: .main) { note in
            let paths = ((note.object as? String) ?? "").split(separator: ":").map { URL(fileURLWithPath: String($0)) }
            Task { @MainActor in AppState.shared.addFolders(paths) }
        }
        center.addObserver(forName: Notification.Name("gel.debug.redact"), object: nil, queue: .main) { note in
            // {paths joined by "|"}: opens the redact review in its own window (no Library selection needed).
            let urls = ((note.object as? String) ?? "").split(separator: "|").map { URL(fileURLWithPath: String($0)) }
            Task { @MainActor in
                let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1120, height: 860), styleMask: [.titled, .closable, .resizable],
                                 backing: .buffered, defer: false)
                w.title = "Redact (debug)"
                w.isReleasedWhenClosed = false
                w.contentView = NSHostingView(rootView: RedactSheet(urls: urls).tint(Theme.accent))
                w.center()
                w.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        center.addObserver(forName: Notification.Name("gel.debug.chip"), object: nil, queue: .main) { [weak self] note in
            let n = Int((note.object as? String) ?? "1") ?? 1
            Task { @MainActor in
                guard let model = self?.launcher.model, let c = model.answer?.citations.first(where: { $0.id == n }) ?? model.answer?.citations.first else { return }
                model.open(c)
            }
        }
    }
    #endif

    // MARK: - Main window

    func showMainWindow() {
        if mainWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1120, height: 720),
                                  styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                                  backing: .buffered, defer: false)
            window.title = "Gel"
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isReleasedWhenClosed = false
            window.minSize = NSSize(width: 980, height: 640)
            let hosting = NSHostingView(rootView: MainView().environmentObject(AppState.shared))
            // The window is user-sized. Without this, SwiftUI size changes during module transitions feed back into the
            // window's Auto Layout pass until AppKit traps ("more Update Constraints passes than views").
            hosting.sizingOptions = []
            window.contentView = hosting
            window.center()
            window.setFrameAutosaveName("GelMainWindow")
            mainWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        mainWindow?.makeKeyAndOrderFront(nil)
    }

    // MARK: - Menu bar

    private func setUpStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = BrandImage.menuBar
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        statusItem = item
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        let state = AppState.shared
        state.refreshHealth()
        menu.removeAllItems()
        let statusTitle = state.missingModels.isEmpty ? state.localStatus.menuTitle
            : "Model missing · open Settings › Models"
        let status = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Open launcher  (⌥Space)", action: #selector(openLauncher), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Open Gel", action: #selector(openMain), keyEquivalent: "").target = self
        menu.addItem(.separator())
        let packs = NSMenuItem(title: "Pack", action: nil, keyEquivalent: "")
        let packMenu = NSMenu()
        for pack in PackStore.shared.selectablePacks {
            let p = NSMenuItem(title: pack.name, action: #selector(togglePack(_:)), keyEquivalent: "")
            p.target = self
            p.representedObject = pack.id
            p.state = state.activePacks.contains(pack.id) ? .on : .off
            p.isEnabled = !state.isLocked(pack: pack.id)
            packMenu.addItem(p)
        }
        packs.submenu = packMenu
        menu.addItem(packs)
        let pause = NSMenuItem(title: "Pause Leak Guard", action: #selector(togglePause), keyEquivalent: "")
        pause.target = self
        pause.state = state.leakGuardPaused ? .on : .off
        menu.addItem(pause)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Gel", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        updateStatusIcon()
    }

    func updateStatusIcon() {
        let symbol: String?
        switch AppState.shared.localStatus {
        case .cloudActive: symbol = "cloud"
        case .unavailable: symbol = GelSettings.shared.cloudConfig == nil ? "exclamationmark.triangle" : nil
        default: symbol = nil
        }
        if let symbol {
            statusItem?.button?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Gel")
            statusItem?.button?.image?.isTemplate = true
        } else {
            statusItem?.button?.image = BrandImage.menuBar
        }
    }

    @objc private func openLauncher() { launcher.show() }
    @objc private func openMain() { showMainWindow() }
    @objc private func togglePause() { AppState.shared.leakGuardPaused.toggle() }
    @objc private func togglePack(_ sender: NSMenuItem) {
        if let id = sender.representedObject as? String { AppState.shared.toggle(pack: id) }
    }
}
