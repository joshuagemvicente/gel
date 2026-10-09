import AppKit
import SwiftUI
import Combine
import GelCore

/// Borderless floating panel that can take keyboard focus without activating the whole app.
final class LauncherPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    var onEscape: (() -> Void)?
    var onOptionChange: ((Bool) -> Void)?

    override func cancelOperation(_ sender: Any?) { onEscape?() }

    override func sendEvent(_ event: NSEvent) {
        // Right ⌥ (keyCode 61) held = push-to-talk, while the launcher is key.
        if event.type == .flagsChanged, event.keyCode == 61 {
            onOptionChange?(event.modifierFlags.contains(.option))
        }
        super.sendEvent(event)
    }
}

@MainActor
final class LauncherController: NSObject, NSWindowDelegate {
    private var panel: LauncherPanel?
    private var host: NSHostingView<LauncherView>?
    private var sizeWatch: AnyCancellable?
    let model = LauncherModel()

    var isVisible: Bool { panel?.isVisible ?? false }

    func toggle() { isVisible ? hide() : show() }

    func show() {
        if panel == nil { build() }
        guard let panel else { return }
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
        if let frame = screen?.visibleFrame {
            let width: CGFloat = 640
            let x = frame.midX - width / 2
            let top = frame.maxY - frame.height * 0.22
            panel.setFrameTopLeftPoint(NSPoint(x: x, y: top))
        }
        model.prepareForShow()
        fitToContent()
        panel.alphaValue = 0
        // Q7: a non-activating panel takes keyboard focus without activating Gel, so the main window stays put
        // and focus returns to the previous app (e.g. Chrome) when the launcher closes.
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : 0.15
            panel.animator().alphaValue = 1
        }
    }

    func hide() {
        guard let panel, panel.isVisible else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : 0.1
            panel.animator().alphaValue = 0
        }, completionHandler: { panel.orderOut(nil) })
    }

    private func build() {
        let p = LauncherPanel(contentRect: NSRect(x: 0, y: 0, width: 640, height: 80),
                              styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
                              backing: .buffered, defer: false)
        p.level = .floating
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.isMovableByWindowBackground = true
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        p.hidesOnDeactivate = false
        p.delegate = self
        p.onEscape = { [weak self] in self?.hide() }
        p.onOptionChange = { [weak self] down in self?.model.optionKey(down: down) }
        model.close = { [weak self] in self?.hide() }
        let host = NSHostingView(rootView: LauncherView(model: model))
        p.contentView = host
        self.host = host
        panel = p
        // Grow/shrink with the answer, keeping the top edge fixed (the panel hangs from the Spotlight position).
        sizeWatch = model.objectWillChange.merge(with: VoiceRecorder.shared.objectWillChange)
            .debounce(for: .milliseconds(16), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.fitToContent() }
    }

    private func fitToContent() {
        guard let panel, let host else { return }
        host.layoutSubtreeIfNeeded()
        let height = min(max(host.fittingSize.height, 54), (panel.screen?.visibleFrame.height ?? 900) * 0.7)
        var frame = panel.frame
        guard abs(frame.height - height) > 0.5 else { return }
        frame.origin.y += frame.height - height
        frame.size.height = height
        // Instant on purpose: animating the frame while SwiftUI animations run loops AppKit's constraint pass (D-047).
        panel.setFrame(frame, display: true, animate: false)
    }

    func windowDidResignKey(_ notification: Notification) { hide() }
}

@MainActor
final class LauncherModel: ObservableObject {
    enum Phase: Equatable { case idle, recording, transcribing, waiting, streaming, done, error(String) }

    @Published var query = ""
    @Published var answerText = ""
    @Published var answer: AnswerResult?
    @Published var phase: Phase = .idle
    @Published var focusTick = 0
    var close: (() -> Void)?
    private var task: Task<Void, Never>?
    /// E1: each question gets its own run id; tokens from an older run are dropped.
    private var runId = 0
    let voice = VoiceRecorder.shared

    func prepareForShow() {
        focusTick += 1
        if case .error = phase { phase = .idle }
    }

    func optionKey(down: Bool) {
        if down {
            guard voice.state == .ready, phase != .recording else { return }
            voice.start()
            if voice.state == .recording { phase = .recording }
        } else if phase == .recording {
            phase = .transcribing
            Task {
                if let text = await voice.stop() {
                    query = text
                    run()
                } else {
                    phase = .idle
                }
            }
        }
    }

    func run() {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        if Store.shared.documents().isEmpty {
            phase = .error("Nothing indexed yet · Choose a folder in Settings")
            return
        }
        task?.cancel()
        runId += 1
        let run = runId
        answer = nil
        answerText = ""
        phase = .waiting
        task = Task {
            do {
                let result = try await QueryEngine.shared.ask(q) { token in
                    Task { @MainActor in
                        guard run == self.runId else { return }
                        self.answerText += token
                        if self.phase == .waiting { self.phase = .streaming }
                    }
                }
                guard run == runId else { return }
                // Replace the streamed text with the cleaned final answer.
                answer = result
                answerText = result.text
                phase = .done
                NotificationCenter.default.post(name: .gelActivityChanged, object: nil)
                AppState.shared.refreshHealth()
            } catch is CancellationError {
                return
            } catch {
                guard run == runId else { return }
                phase = .error((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
            }
        }
    }

    func open(_ citation: Citation) {
        close?()
        AppState.shared.open(citation: citation)
    }

    func openInGel() {
        guard let a = answer else { return }
        close?()
        AppState.shared.pendingHistoryId = a.id
        AppState.shared.open(module: .history)
    }

    func openSettings() {
        close?()
        AppState.shared.open(module: .settings)
    }
}
