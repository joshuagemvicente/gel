# U1 · App shell — Tasks

Status: `[x]` done and verified · `[~]` built, not verified · `[ ]` not started.

- [x] **T1 App delegate and AppState.** `GelApp` with `@NSApplicationDelegateAdaptor`; `AppDelegate` owns `AppState` (`@MainActor ObservableObject`: settings snapshot, `indexProgress`, `localHealthy`, `cloudActive`, `policy`, `leakGuardPaused`, `selectedModule`, `pendingCitation`). Files: `Gel/Gel/GelApp.swift`, `Gel/Gel/App/AppDelegate.swift`, `Gel/Gel/App/AppState.swift`.
  **Verify:** app builds and launches from `open build/Build/Products/Debug/Gel.app`.
- [x] **T2 Main window with sidebar.** `NSWindow` hosting `MainView` (`NavigationSplitView`, five modules with placeholder views, Settings pinned bottom); `showMainWindow(module:)` on the delegate; window close keeps the app alive.
  **Verify:** close and reopen the window from the Dock icon and from the menu bar; module selection persists.
- [~] **T3 Menu bar.** `NSStatusItem` with the menu in [design.md](design.md); status line bound to `AppState`; Pack submenu toggles `GelSettings.activePacks` (locked packs disabled).
  **Verify:** stop Ollama (`brew services stop ollama`) → status shows "Local model unavailable" within 30 s; start it → "Local ✓".
- [~] **T4 Launch services.** Policy load + `ModelRouter.cloudAllowedByPolicy`; 5 s folder rescan calling `Indexer().index(folder:)` when `pending` is non-empty, publishing progress; `ModelRouter.warmUp()`; 30 s health timer.
  **Verify:** copy a PDF into the indexed folder while the app runs → `Store.shared.documents()` count rises within 10 s (Library shows it).
- [x] **T5 Theme and shared components.** Color tokens (asset colors or a `Theme` enum with light/dark), `Card`, `ProviderBadge`, `CitationChip`, `StatCard`, `LockedLabel`, `EmptyState`.
  **Verify:** a SwiftUI preview or debug screen renders each component in light and dark mode.
- [~] **T6 App icon.** Built by polish T2 (Gel drop on a warm squircle, `scripts/make_icon`). Originally: a generic droplet icon in the accent green (asset catalog `AppIcon`; add the catalog to `project.yml`).
  **Verify:** Dock shows the icon after a clean build.

Done when: all [spec.md](spec.md) acceptance criteria are observed passing.
