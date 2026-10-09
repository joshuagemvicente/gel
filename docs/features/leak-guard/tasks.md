# F5 · Leak Guard — Tasks

Legend: `[x]` done and verified · `[~]` built, not verified · `[ ]` not started.

- [x] **T1 Fast detection + summary text.** Files: `GelCore/PII/PIIDetector.swift`. **Verify:** unit tests `testSummary`, `testCoreContactsAlwaysOn`, `testPersonalIDsAndMoney` pass.
- [x] **T2 Detection on the samples.** **Verify:** `cd Gel && GEL_HOME=/tmp/gel-dev build/Build/Products/Debug/gelcli detect --packs hr,personal --file "../demo-data/clipboard-samples/<file>.txt"` for each sample: employee record and resume give government-ID/salary findings; passport + bank gives passport and bank-account findings; the clean paragraph gives 0 findings (or names only — then tighten layer 2).
- [x] **T3 `LeakGuardMonitor`.** Poll `changeCount` every 0.5 s, read the string, `detectFast` with the active packs, track the frontmost app via `NSWorkspace.didActivateApplicationNotification`; fire once per change when findings exist and a watched app is frontmost (either order). Pausable. Files: `Gel/LeakGuard/LeakGuardMonitor.swift`. **Verify:** copy the employee sample, switch to Chrome → monitor publishes a trigger (log line) within 1 s; clean sample → none.
- [x] **T4 Overlay panel.** Non-activating floating `NSPanel`, top-right under the menu bar: "This would leak: <summary>", app name, **Paste redacted (⌥⌘V)**, **Ignore**; auto-hide 12 s; block mode disables Ignore ("Blocked by <organization>"). Files: `Gel/LeakGuard/LeakOverlay.swift`. **Verify:** overlay appears without stealing focus from Chrome's text field.
- [~] **T5 Safe paste.** Global ⌥⌘V (KeyboardShortcuts) → clipboard = `redactText(...).text` → CGEvent ⌘V if `AXIsProcessTrusted()`, else message "Press ⌘V to paste the redacted text". Files: `LeakGuardMonitor.swift`. **Verify:** in chatgpt.com, ⌥⌘V pastes placeholders; no raw IDs appear.
- [~] **T6 Block mode.** If `policy.blocks(findings)`, replace the clipboard with the redacted text immediately on trigger. **Verify:** with the sample policy, ⌘V in Chrome pastes placeholders.
- [x] **T7 Events.** On trigger: `logEvent(kind: "leak_caught", app:)` + one `leak_item` per category with counts. **Verify:** `gelcli stats` shows leaks caught incremented; `sqlite3 "$GEL_HOME/index.sqlite" "select * from events"` contains no clipboard text.
- [ ] **T8 Pack switch takes effect.** **Verify:** menu bar → Personal; passport sample now triggers; HR-only sample behaviour changes accordingly, no restart.

Done when: all [spec.md](spec.md) acceptance criteria observed passing.
- [~] **T9 E12 watched apps.** Extend `LeakGuardDefaults.watchedApps`. **Verify:** copy the employee record, switch to Slack (if installed) → overlay.
