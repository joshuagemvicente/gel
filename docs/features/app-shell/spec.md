# U1 · App shell — Spec

**Goal:** Gel runs as a Dock app with a main window and a menu bar icon, starts its background services on launch, and looks warm and minimal everywhere.

## Behaviour

- **Presence:** Dock app (regular activation policy) with a main window and an `NSStatusItem`. Launching opens the main window; closing it keeps Gel running in the menu bar. Quit from the menu bar or ⌘Q.
- **State:** one `AppState` (`@MainActor`, `ObservableObject`) owns settings, index progress, the latest launcher answer, local/cloud health, the loaded policy and Leak Guard state. Views observe it; engine calls go through `GelCore`.
- **Launch sequence:** load the policy (`TeamPolicy.load`) and apply `ModelRouter.cloudAllowedByPolicy` → if onboarding isn't done, show onboarding → start the 5 s folder rescan (indexing spec) → `ModelRouter.warmUp()` → load WhisperKit in the background (voice spec) → start Leak Guard (leak-guard spec) → local health check every 30 s.
- **Menu bar menu:** status line (`Local ✓` / `Cloud fallback active` / `Local model unavailable`), Open launcher (⌥Space), Open Gel, Pack ▸ (checkable packs; locked ones disabled), Pause Leak Guard, Quit Gel. The icon changes to a cloud variant while the cloud cooldown is active.
- **Main window frame:** `NavigationSplitView` with sidebar modules in this order: Home, History, Library, Redactions & Leak Guard, Settings. Minimum 980 × 640. Selecting a module shows its view (each module has its own feature folder).

## Look and feel

Shared by every UI feature: see [design.md](design.md).

## Acceptance criteria

- [ ] Launching opens the main window with the five modules in the sidebar; closing it leaves the menu bar icon running.
- [ ] The menu bar status reflects reality within 30 s when Ollama is stopped and restarted.
- [ ] Pack switching from the menu bar changes `GelSettings.activePacks` immediately.
- [ ] The app builds and runs from `xcodebuild` without manual Xcode steps.
