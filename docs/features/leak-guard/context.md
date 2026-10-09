# F5 · Leak Guard — Context

## Why it exists

People paste employee records into ChatGPT. Leak Guard catches that moment (demo beat 4) and, with the Personal pack, the consumer reveal (beat 5) ([demo-and-submission](../../project/demo-and-submission.md)). It is the clearest "only possible locally" feature: checking every clipboard copy would be invasive and costly with a cloud API. Serves **Innovation** and **Local AI implementation** ([context](../../project/context.md)).

## Where it sits

- **Upstream:** [detection-redaction](../detection-redaction/spec.md) (`detectFast`, `summary`, `redactText`), [packs](../packs/spec.md) (active types), [policy-dpo-report](../policy-dpo-report/spec.md) (watched apps, warn/block, organization name).
- **Downstream:** [home](../home/spec.md) and [redactions-module](../redactions-module/spec.md) (Leak Guard log via `leak_caught`/`leak_item` events), DPO report totals.
- **Lifecycle owner:** [app-shell](../app-shell/spec.md) starts it; the menu bar toggles pause.

## Current state

- Built in `GelCore`: `PIIDetector.detectFast`, `PIIDetector.summary`, `Redactor.redactText` (`PII/`); `LeakGuardDefaults.watchedApps`, `TeamPolicy.action(for:)`, `TeamPolicy.blocks(_:)` (`Policy/TeamPolicy.swift`); `Store.logEvent`.
- `DPOReport.totals` already reads `leak_caught` and `leak_item` events.
- **Not built (app target):** clipboard watcher, frontmost-app tracking, overlay panel, ⌥⌘V hotkey, CGEvent paste, pause toggle, Accessibility check.

## Facts and gotchas

- `NSPasteboard` has no change notification; poll `changeCount` (0.5 s).
- Default watched bundle IDs: `com.google.Chrome`, `com.apple.Safari`, `company.thebrowser.Browser` (Arc), `com.microsoft.edgemac`, `com.brave.Browser`, `org.mozilla.firefox`, `com.openai.chat`, `com.anthropic.claudefordesktop`.
- Synthesizing ⌘V needs Accessibility (`AXIsProcessTrustedWithOptions`); without it, `CGEvent.post` silently does nothing.
- KeyboardShortcuts (already a package dependency) handles the global ⌥⌘V hotkey without extra permissions.
- The app is unsandboxed and ad-hoc signed; Accessibility grants are tied to the binary path, so rebuilding to a new path may need re-granting.
- Demo samples: `demo-data/clipboard-samples/` has an employee record, a resume snippet, a passport + bank snippet, and a clean paragraph.

## Related

[spec](spec.md) · [tasks](tasks.md) · [interfaces](interfaces.md) · [policy-dpo-report](../policy-dpo-report/spec.md)
