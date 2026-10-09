# F5 · Leak Guard and safe paste — Spec

**Goal:** catch personal data on the clipboard at the moment it's about to reach an AI app, and offer a redacted paste instead.

**Planned extension:** [Automatic browser discovery](../browser-discovery/README.md) specifies dynamic app membership, user additions/exclusions, per-app warnings and one-incident accounting. It replaces the static-only membership and global once-per-change warning rules below when implemented. Runtime implementation still requires approval; the other Leak Guard fundamentals remain in this brief.

## Behaviour

- **Watch:** poll `NSPasteboard.general.changeCount` every 0.5 s. On change, read the string and run `detectFast` (layers 1+2 only: no LLM, no network, target < 100 ms). Keep the latest findings in memory only.
- **Watched apps:** the policy's `watchedApps` or, by default, `LeakGuardDefaults.watchedApps` (Chrome, Safari, Arc, Edge, Brave, Firefox, ChatGPT, Claude).
- **Trigger:** show the overlay when (a) the clipboard changes while a watched app is frontmost and findings exist, or (b) a watched app becomes frontmost (`NSWorkspace.didActivateApplicationNotification`) while the clipboard holds findings. Show once per clipboard change.
- **Overlay:** a non-activating floating panel (doesn't steal focus), top-right under the menu bar. Text: "This would leak: <summary>" (e.g. "3 government ID numbers, 1 salary, 1 address"), the app name, and buttons **Paste redacted (⌥⌘V)** and **Ignore**. Auto-hides after 12 s. In **block** mode ([policy-dpo-report](../policy-dpo-report/spec.md)) the Ignore button reads "Blocked by <organization>" and is disabled.
- **Safe paste (⌥⌘V, global):** replace the clipboard with `Redactor.redactText` output, then synthesize ⌘V with `CGEvent` (needs Accessibility permission). In block mode the redacted text stays on the clipboard so a normal ⌘V can't paste the raw text.
- **Logging:** one `leak_caught` event (app name, no content) plus `leak_item` events per category with counts.
- **Pause:** menu bar "Pause Leak Guard" toggles watching.
- **Permissions:** if Accessibility isn't granted, ⌥⌘V still replaces the clipboard and the overlay says "Press ⌘V to paste the redacted text".

## Watched apps (E12)

Default list adds chat apps where people paste work data: Slack (`com.tinyspeck.slackmacgap`), Microsoft Teams (`com.microsoft.teams2`, `com.microsoft.teams`), Messenger (`com.facebook.archon.developerID`), Telegram (`ru.keepcoder.Telegram`, `org.telegram.desktop`), Viber (`com.viber.osx`), WhatsApp (`net.whatsapp.WhatsApp`), Discord (`com.hnc.Discord`). A policy's `watchedApps` still replaces the list.

## Acceptance criteria

- [ ] Copying `demo-data/clipboard-samples` employee record text and switching to Chrome shows the overlay within 1 s with the right summary.
- [ ] ⌥⌘V pastes placeholder text into chatgpt.com's input; none of the raw IDs are pasted.
- [ ] The clean (non-PII) sample triggers no overlay.
- [ ] No network requests are made by this feature; clipboard text never appears in the database.

## Dummy data on paste (R5, D-073)

Settings › Hotkeys → **Paste dummy data instead of placeholders** (`GelSettings.leakGuardPasteDummy`, default off). When on, safe paste and block mode call `Redactor.redactText(…, mode: .dummy)`, so the clipboard carries type-aware fakes instead of `[SSS_1]`. Detection and the overlay are unchanged.
