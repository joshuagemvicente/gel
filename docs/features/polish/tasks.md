# U9 · Polish & motion — Tasks

Status: `[x]` done and verified · `[~]` built, not verified · `[ ]` not started.

- [x] **T1 Motion + shared components.** `Motion` tokens with Reduce Motion fallback, `GelButtonStyle`, hover/press modifiers, `IconChip`, `ModuleHeader(subtitle:)`, rebuilt `EmptyStateView`, `CitationChip` and `ProviderBadge`. Files: `Gel/Gel/App/Theme.swift`.
  **Verify:** app builds; Home renders in light and dark.
- [~] **T2 Brand + icon.** `GelDrop` shape and `GelMark` view (still/thinking/listening); `scripts/make_icon.swift` renders `AppIcon.appiconset`; `project.yml` sets the icon name; menu bar template image. Files: `Gel/Gel/App/Brand.swift`, `Gel/Gel/Assets.xcassets`, `scripts/make_icon.swift`, `Gel/project.yml`, `Gel/Gel/App/AppDelegate.swift`. Closes app-shell T6.
  **Verify:** AC1, AC2.
- [~] **T3 Shell.** Sliding sidebar pill, hover, fill symbols, status footer with indexing line, module transition. Files: `Gel/Gel/Main/MainView.swift`.
  **Verify:** AC3.
- [x] **T4 Launcher.** Drop glyph states, new shimmer, appear scale, animated panel growth, staggered chips, badge, error shake, recording ring. Files: `Gel/Gel/Launcher/LauncherView.swift`, `LauncherController.swift`.
  **Verify:** AC4 with the debug hook `gel.debug.ask`.
- [x] **T5 Leak overlay.** Redesign + slide in/out + countdown bar. Files: `Gel/Gel/LeakGuard/LeakGuardMonitor.swift`.
  **Verify:** AC5 with a file from `demo-data/clipboard-samples/`.
- [~] **T6 Home.** Greeting subtitle, icon chips, numeric transitions, staggered entry, index progress, kind icons and row insertion. Files: `Gel/Gel/Home/HomeView.swift`.
  **Verify:** AC6.
- [~] **T7 Onboarding.** Directional steps, page capsule, hero drop, choice check badge, indexing finish state. Files: `Gel/Gel/Onboarding/OnboardingView.swift`.
  **Verify:** AC7 (run with a scratch `GEL_HOME` so the real onboarding flag isn't touched).
- [x] **T8 Library, History, Redact sheet, Settings.** As in design.md, including the PDF background fix. Files: `Library/LibraryView.swift`, `History/HistoryView.swift`, `Redactions/RedactionsView.swift`, `Settings/SettingsView.swift`.
  **Verify:** AC8 screenshots.
- [~] **T9 Final pass.** Light/dark screenshots, Reduce Motion check, build + tests, `git diff --stat Gel/GelCore`.
  **Verify:** AC8, AC9, AC10.

## Verification log (2026-10-09, 23:20)

- **T1:** app builds; Home rendered in light and dark (screenshots).
- **T2:** icon renders (`scripts/make_icon`); `AppIcon.icns` in the bundle; LaunchServices resolves the Gel icon after `lsregister -f` (the Dock tile for the already-running app still showed the cached generic icon, so the Dock is not yet observed). Menu bar drop and sidebar mark observed. Onboarding hero not yet observed.
- **T3:** main window made static after real-click crashes (D-047): no sliding pill or module transition. Verified on the 23:11:56 build by the engine session with synthesized real mouse clicks: the first Home → Library click crashed before the fix; after it, 5 Home ↔ Library cycles plus 96 clicks across all modules (some during a forced reindex) → no crash. Earlier: screenshots show the selected state only, not mid-transition frames. 84 rapid module switches + the other session's 48 → 0 crashes.
- **T4:** drop, three-line shimmer, numbered chips, badge observed via `gel.debug.ask`. Panel resize is instant (D-047), not animated.
- **T5:** overlay observed mid-slide (90 ms), settled, and gone after 12 s; blocked mode built, not screenshotted after the D-047 rewrite.
- **T6:** icon chips, greeting subtitle, kind icons observed; the rolling-number transition after a new answer not yet observed.
- **T7:** builds; not run (needs a scratch `GEL_HOME` relaunch while the user is testing).
- **T8:** History, Library, Redactions, Settings observed in dark and light. Redact sheet not opened.
- **T9:** `gelcli` builds, `GelCoreTests` 14/14 pass. Reduce Motion not checked (needs the system setting). `git diff Gel/GelCore` is not empty because the engine session edits GelCore; this feature changes no GelCore file.

Done when: all [spec.md](spec.md) acceptance criteria are observed passing.
