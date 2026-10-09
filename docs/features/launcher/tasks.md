# U2 · Launcher — Tasks

Status: `[x]` done and verified · `[~]` built, not verified · `[ ]` not started.

- [~] **T1 Panel and hotkey.** `LauncherPanel` (`NSPanel` subclass per [context](context.md)), `LauncherController` that positions it on the active screen; KeyboardShortcuts `toggleLauncher` = ⌥Space registered at launch. Files: `Gel/Gel/Launcher/LauncherPanel.swift`, `LauncherController.swift`.
  **Verify:** from Finder, Chrome and a full-screen app, ⌥Space shows the panel focused; Esc and an outside click close it.
- [x] **T2 Input and run.** `LauncherView` with the field, Enter → `QueryEngine.shared.ask`, streamed tokens appended on the main actor, states from [design.md](design.md).
  **Verify:** ask the demo question with demo data indexed → the answer streams and names Reyes, Santos, Cruz.
- [x] **T3 Chips and badge.** `CitationChip` row and `ProviderBadge` from `AnswerResult`; chip click → `AppDelegate.showMainWindow(module: .library)` with `pendingCitation` set, then close the panel.
  **Verify:** clicking chip 1 opens the Library viewer on the cited page highlighted (needs library-viewer T3).
- [~] **T4 Error and empty states.** Nothing indexed, local unavailable (Retry re-runs), not found.
  **Verify:** stop Ollama with no cloud configured → "Local model unavailable · Retry"; start it → Retry answers.
- [~] **T5 Voice hook.** Right-⌥ hold/release wiring to the voice feature's recorder and transcript (voice T-tasks provide the recorder).
  **Verify:** hold ⌥, speak the demo question, release → transcript fills and runs.
- [~] **T6 Motion polish.** Appear/disappear animation, streaming height animation, Reduce Motion respected.
  **Verify:** visual check with Reduce Motion on and off.

Done when: all [spec.md](spec.md) acceptance criteria are observed passing.
- [~] **T7 E1 run ids.** Run id per question; cancel the inner stream; drop tokens from old runs. Files: `LauncherController.swift`, `ModelRouter.swift`. **Verify:** ask twice quickly → second answer contains no text from the first.
- [~] **T8 Q7 focus.** **Verify:** in Chrome, ⌥Space → Esc → typing goes to Chrome; the main window didn't come forward.
