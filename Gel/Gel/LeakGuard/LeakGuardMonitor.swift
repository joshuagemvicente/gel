import AppKit
import SwiftUI
import GelCore

/// Watches the clipboard and warns when personal data is about to be pasted into a browser or AI app.
/// Detection is layers 1–2 only (instant, offline). Clipboard text is never logged or stored.
@MainActor
final class LeakGuardMonitor: ObservableObject {
    struct Alert: Equatable {
        var summary: String
        var app: String
        var blocked: Bool
        var organization: String?
    }

    @Published var alert: Alert?

    private var lastChange = NSPasteboard.general.changeCount
    private var findings: [Finding] = []
    private var clipText: String?
    private var alertedForChange = -1
    private var timer: Timer?
    private var panel: NSPanel?
    private var hideWork: DispatchWorkItem?

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task { @MainActor in self.poll() }
        }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { _ in
            Task { @MainActor in self.evaluate() }
        }
    }

    private var watched: [String: String] {
        if let ids = AppState.shared.policy?.watchedApps {
            return Dictionary(uniqueKeysWithValues: ids.map { ($0, LeakGuardDefaults.watchedApps[$0] ?? $0) })
        }
        return LeakGuardDefaults.watchedApps
    }

    private func poll() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChange else { return }
        lastChange = pb.changeCount
        guard !AppState.shared.leakGuardPaused, let text = pb.string(forType: .string), !text.isEmpty else {
            findings = []; clipText = nil; return
        }
        // Ignore our own redacted paste.
        if text.contains("_1]") && PIIDetector.shared.detectFast(text).isEmpty { findings = []; clipText = nil; return }
        clipText = text
        findings = PIIDetector.shared.detectFast(text)
        evaluate()
    }

    private func evaluate() {
        guard !AppState.shared.leakGuardPaused, !findings.isEmpty, alertedForChange != lastChange,
              let front = NSWorkspace.shared.frontmostApplication, let id = front.bundleIdentifier,
              let appName = watched[id] else { return }
        alertedForChange = lastChange
        let policy = AppState.shared.policy
        let blocked = policy?.blocks(findings) ?? false
        if blocked, let text = clipText {
            // Block mode: the redacted text replaces the clipboard so a plain ⌘V can't paste the raw data.
            setClipboard(Redactor.redactText(text, findings: findings).text)
        }
        Store.shared.logEvent(kind: "leak_caught", app: appName)
        for (category, n) in Dictionary(grouping: findings, by: \.category).mapValues(\.count) {
            Store.shared.logEvent(kind: "leak_item", category: category, count: n, app: appName)
        }
        NotificationCenter.default.post(name: .gelActivityChanged, object: nil)
        show(Alert(summary: PIIDetector.summary(findings), app: appName, blocked: blocked, organization: policy?.organization))
    }

    /// ⌥⌘V: put the redacted text on the clipboard and paste it into the frontmost app.
    func safePaste() {
        guard let text = clipText ?? NSPasteboard.general.string(forType: .string) else { return }
        let f = findings.isEmpty ? PIIDetector.shared.detectFast(text) : findings
        setClipboard(Redactor.redactText(text, findings: f).text)
        hide()
        if AXIsProcessTrusted() {
            let src = CGEventSource(stateID: .combinedSessionState)
            let down = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: true)
            let up = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: false)
            down?.flags = .maskCommand; up?.flags = .maskCommand
            down?.post(tap: .cghidEventTap); up?.post(tap: .cghidEventTap)
        } else {
            AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary)
            show(Alert(summary: "Redacted text is on the clipboard. Press ⌘V to paste it.", app: "", blocked: false, organization: nil))
        }
    }

    private func setClipboard(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        lastChange = pb.changeCount
        alertedForChange = lastChange
        findings = []
        clipText = nil
    }

    // MARK: - Overlay

    private func show(_ a: Alert) {
        alert = a
        if panel == nil {
            let p = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 380, height: 120),
                            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            p.level = .statusBar
            p.isOpaque = false
            p.backgroundColor = .clear
            p.hasShadow = true
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            let host = NSHostingView(rootView: LeakOverlay(monitor: self))
            host.sizingOptions = [.preferredContentSize]
            p.contentView = host
            panel = p
        }
        if let screen = NSScreen.main, let panel {
            let f = screen.visibleFrame
            panel.setFrameTopLeftPoint(NSPoint(x: f.maxX - 400, y: f.maxY - 12))
            panel.orderFrontRegardless()
        }
        hideWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.hide() }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 12, execute: work)
    }

    func hide() {
        panel?.orderOut(nil)
        alert = nil
    }
}

struct LeakOverlay: View {
    @ObservedObject var monitor: LeakGuardMonitor

    var body: some View {
        if let a = monitor.alert {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill").foregroundStyle(Theme.accent)
                    Text(a.app.isEmpty ? "Gel" : "Gel caught a leak in \(a.app)").font(.system(size: 12, weight: .semibold))
                }
                Text(a.app.isEmpty ? a.summary : "This would leak: \(a.summary)")
                    .font(.system(size: 13)).fixedSize(horizontal: false, vertical: true)
                if !a.app.isEmpty {
                    HStack {
                        Button("Paste redacted  ⌥⌘V") { monitor.safePaste() }.buttonStyle(.borderedProminent).tint(Theme.accent)
                        if a.blocked {
                            Text("Blocked by \(a.organization ?? "your organization")").font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                        } else {
                            Button("Ignore") { monitor.hide() }
                        }
                    }
                }
            }
            .padding(16)
            .frame(width: 380, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.hairline))
        }
    }
}
