# U1 · App shell — Context

## Why it exists

Every UI feature (launcher, Library, Settings, Home, History, Redactions, onboarding) lives inside this shell, and the background services (folder rescan, model warm-up, Leak Guard, health checks) start here. The demo uses the menu bar twice: the local/cloud status line and the Pack submenu for the consumer reveal ([demo script](../../project/demo-and-submission.md)). Polish here serves **Product & Demo Quality (15%)** and the WhiteCloak award.

## Where it sits

- **Upstream:** the `GelCore` engine (indexing, query-citations, detection-redaction, model-fallback, packs, policy-dpo-report).
- **Downstream:** launcher, library-viewer, settings, onboarding, home, history, redactions-module, leak-guard (overlay), voice (WhisperKit loading).

## Current state

- `Gel/Gel/GelApp.swift` is a placeholder (`WindowGroup { Text("Gel") }`).
- `Gel/project.yml` already declares the app target with WhisperKit and KeyboardShortcuts, `Gel/Info.plist` properties (microphone and Apple Events usage strings), and `Gel/Gel/Gel.entitlements` (no sandbox, audio input).
- Engine singletons ready to use: `Store.shared`, `QueryEngine.shared`, `ModelRouter.shared`, `PIIDetector.shared`, `PackStore.shared`, `GelSettings.shared`, `TeamPolicy.load()`, `DPOReport.totals()`, `Indexer()`.

## Facts and gotchas

- **Window control from AppKit:** the menu bar, launcher chips and hotkeys must be able to show the main window and switch its module. Manage the main window as an `NSWindow` hosting the SwiftUI root (owned by the app delegate), rather than relying on `WindowGroup` + `openWindow`, which can't be driven from AppKit code reliably.
- Return `false` from `applicationShouldTerminateAfterLastWindowClosed` so closing the window keeps Gel in the menu bar.
- Swift language mode 5 with minimal concurrency checking ([decisions](../../project/decisions.md) D-015). Mark UI types `@MainActor`; hop to the main actor when engine callbacks update state.
- Ollama may take ~20 s to load the model the first time; `ModelRouter.warmUp()` at launch hides that.
- The ChatGPT desktop app also uses ⌥Space; the launcher keeps ⌥Space and the demo uses chatgpt.com (D-019).

## Related docs

[spec](spec.md) · [design](design.md) · [tasks](tasks.md) · [architecture](../../project/architecture.md)
