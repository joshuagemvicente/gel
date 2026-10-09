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
        var id = UUID()
    }

    /// The overlay dismisses itself after this long; its countdown bar drains over the same time.
    static let autoHide: TimeInterval = 12

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
            setClipboard(Redactor.redactText(text, findings: findings, mode: Self.pasteMode).text)
        }
        Store.shared.logEvent(kind: "leak_caught", app: appName)
        for (category, n) in Dictionary(grouping: findings, by: \.category).mapValues(\.count) {
            Store.shared.logEvent(kind: "leak_item", category: category, count: n, app: appName)
        }
        NotificationCenter.default.post(name: .gelActivityChanged, object: nil)
        show(Alert(summary: PIIDetector.summary(findings), app: appName, blocked: blocked, organization: policy?.organization))
    }

    /// Placeholders, or dummy data when the Settings toggle is on (R5).
    private static var pasteMode: RedactionMode { GelSettings.shared.leakGuardPasteDummy ? .dummy : .blackout }

    /// ⌥⌘V: put the redacted text on the clipboard and paste it into the frontmost app.
    func safePaste() {
        guard let text = clipText ?? NSPasteboard.general.string(forType: .string) else { return }
        let f = findings.isEmpty ? PIIDetector.shared.detectFast(text) : findings
        setClipboard(Redactor.redactText(text, findings: f, mode: Self.pasteMode).text)
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

    private var generation = 0
    /// Drives the slide inside SwiftUI. The panel frame never animates (D-047).
    @Published var presented = false

    /// Slides in from the right; `hide()` leaves the same way (fade only under Reduce Motion).
    private func show(_ a: Alert) {
        alert = a
        generation += 1
        if panel == nil {
            let p = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 380, height: 120),
                            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            p.level = .statusBar
            p.isOpaque = false
            p.backgroundColor = .clear
            p.hasShadow = false // the card draws its own shadow so it can slide inside the panel
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            let host = NSHostingView(rootView: LeakOverlay(monitor: self))
            host.sizingOptions = [.preferredContentSize]
            p.contentView = host
            panel = p
        }
        if let screen = NSScreen.main, let panel {
            let f = screen.visibleFrame
            // LeakOverlay pads the card by 20 pt for its shadow.
            panel.setFrameTopLeftPoint(NSPoint(x: f.maxX - 400 - 20, y: f.maxY - 12 + 20))
            panel.orderFrontRegardless()
        }
        if !presented {
            DispatchQueue.main.async { withAnimation(Motion.smooth) { self.presented = true } }
        }
        hideWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.hide() }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.autoHide, execute: work)
    }

    #if DEBUG
    /// Test-only (D-038): shows a sample overlay without touching the clipboard or logging an event.
    func debugShow(blocked: Bool) {
        show(Alert(summary: "2 names, 1 TIN, 1 phone number", app: "Chrome", blocked: blocked, organization: blocked ? "Bayanihan Outsourcing" : nil))
    }
    #endif

    func hide() {
        hideWork?.cancel()
        guard let panel, panel.isVisible else { alert = nil; presented = false; return }
        let gen = generation
        withAnimation(Motion.reduce ? Motion.fade : .easeIn(duration: 0.2)) { presented = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { [weak self] in
            // A newer alert may have arrived while this one was leaving.
            guard let self, self.generation == gen, !self.presented else { return }
            panel.orderOut(nil)
            self.alert = nil
        }
    }
}

struct LeakOverlay: View {
    @ObservedObject var monitor: LeakGuardMonitor

    var body: some View {
        if let a = monitor.alert {
            LeakCard(alert: a, monitor: monitor).id(a.id)
                .shadow(color: .black.opacity(0.22), radius: 14, y: 6)
                .offset(x: monitor.presented || Motion.reduce ? 0 : 40)
                .opacity(monitor.presented ? 1 : 0)
                .padding(20)
        }
    }
}

private struct LeakCard: View {
    let alert: LeakGuardMonitor.Alert
    let monitor: LeakGuardMonitor
    @State private var remaining: CGFloat = 1
    @State private var appeared = false

    private var isInfo: Bool { alert.app.isEmpty }
    private var tint: Color { isInfo ? Theme.accent : Theme.danger }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconChip(symbol: isInfo ? "checkmark.shield.fill" : "exclamationmark.shield.fill",
                     tint: tint, background: isInfo ? Theme.accentSoft : Theme.dangerSoft, size: 32)
                .symbolEffect(.bounce, value: appeared)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(isInfo ? "Gel" : "Gel caught a leak").font(.system(size: 13, weight: .semibold))
                    if !isInfo { Text("· \(alert.app)").font(.system(size: 13)).foregroundStyle(Theme.textSecondary) }
                    Spacer(minLength: 8)
                    Button { monitor.hide() } label: {
                        Image(systemName: "xmark").font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Theme.textSecondary)
                            .frame(width: 18, height: 18)
                            .hoverHighlight(radius: 9)
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("Dismiss")
                }
                Text(isInfo ? alert.summary : "This would leak: \(alert.summary)")
                    .font(.system(size: 12.5)).foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if !isInfo {
                    HStack(spacing: 8) {
                        Button { monitor.safePaste() } label: {
                            HStack(spacing: 6) {
                                Text("Paste redacted")
                                Text("⌥⌘V").font(.system(size: 11, weight: .medium)).opacity(0.75)
                            }
                        }
                        .buttonStyle(.gelPrimary)
                        if alert.blocked {
                            Label("Blocked by \(alert.organization ?? "your organization")", systemImage: "lock.fill")
                                .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                        } else {
                            Button("Ignore") { monitor.hide() }.buttonStyle(.gelSecondary)
                        }
                    }
                    .padding(.top, 6)
                }
            }
        }
        .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 16)
        .frame(width: 380, alignment: .leading)
        .background(Theme.card)
        .overlay(alignment: .leading) { Rectangle().fill(tint).frame(width: 3) }
        .overlay(alignment: .bottomLeading) {
            GeometryReader { geo in
                Rectangle().fill(tint.opacity(0.45)).frame(width: geo.size.width * remaining)
            }
            .frame(height: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.hairline))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(isInfo ? alert.summary : "Gel caught a leak in \(alert.app). This would leak: \(alert.summary)")
        .onAppear {
            appeared = true
            withAnimation(.linear(duration: LeakGuardMonitor.autoHide)) { remaining = 0 }
        }
    }
}
