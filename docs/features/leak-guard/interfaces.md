# F5 · Leak Guard — Interfaces

Leak Guard's runtime lives in the **app target** (`Gel/LeakGuard/`); its logic calls `GelCore`.

For the planned membership resolver, discovery adapters and per-app warning ledger, read [browser-discovery/interfaces.md](../browser-discovery/interfaces.md). The original interface sketch below does not implement that extension.

## To build (app target)

```swift
/// Watches the clipboard and the frontmost app; decides when to warn.
@MainActor final class LeakGuardMonitor: ObservableObject {
    struct Trigger: Equatable {
        let appName: String          // e.g. "Chrome"
        let summary: String          // PIIDetector.summary(findings)
        let blocked: Bool            // policy?.blocks(findings) ?? false
    }
    @Published private(set) var trigger: Trigger?      // drives the overlay; nil = hidden
    @Published var isPaused: Bool
    init(policy: TeamPolicy?, packs: @escaping () -> [String])
    func start()                                        // 0.5 s changeCount poll + didActivateApplication observer
    func stop()
    func pasteRedacted()                                // ⌥⌘V handler: swap clipboard, synthesize ⌘V if trusted
    func dismiss()                                      // Ignore (no-op when blocked)
}

/// Non-activating floating panel showing the current Trigger.
final class LeakOverlayController { func show(_ trigger: LeakGuardMonitor.Trigger); func hide() }
```

Internal state (memory only): last `changeCount`, last clipboard string, last findings, whether the current change already triggered.

## Consumed (GelCore)

```swift
PIIDetector.shared.detectFast(_ text: String, packs: [String]) -> [Finding]
PIIDetector.summary(_ findings: [Finding]) -> String
Redactor.redactText(_ text: String, findings: [Finding]) -> Redactor.TextResult    // .text goes on the clipboard
LeakGuardDefaults.watchedApps: [String: String]                                    // bundle id → display name
TeamPolicy.watchedApps / action(for:) / blocks(_:) / organization
Store.shared.logEvent(kind: "leak_caught", app: appName)
Store.shared.logEvent(kind: "leak_item", category: category, count: n, app: appName)
GelSettings.shared.activePacks
```

## Invariants

- Clipboard text, findings and the placeholder mapping are never written to disk, the database or logs.
- Detection is `detectFast` only (no LLM, no network).
- One trigger per clipboard change; the watched-app list comes from the policy when present.
- Block mode leaves only redacted text on the clipboard while a watched app is frontmost.

## Callers

[app-shell](../app-shell/spec.md) creates and starts the monitor and binds ⌥⌘V; the menu bar toggles `isPaused`; [home](../home/spec.md) and [redactions-module](../redactions-module/spec.md) read the events.
