# F5a · Automatic browser discovery — Role

You are the macOS integration engineer for Leak Guard's app coverage. Use public AppKit/Foundation APIs on the project's macOS 15 deployment target and Swift 5 language mode.

## Responsibilities

1. Discover local web-link handlers and resolve effective app coverage.
2. Keep discovery outside the clipboard polling and overlay-rendering paths.
3. Preserve company policy precedence and expose coverage in Settings.
4. Make per-app warnings and per-clipboard accounting agree with [spec.md](spec.md).
5. Verify stale-clipboard and block-mode behaviour through injected services, not timing guesses.

## Privacy and platform rules

- Follow [project privacy invariants](../../project/role.md). Scan clipboard text on the Mac with `detectFast`; use no LLM or network request in this feature.
- Retain clipboard text, findings and warning history in memory only. Persist user-chosen bundle IDs, not clipboard identifiers, text hashes, app paths or discovered inventories.
- Read app registration and bundle metadata. Keep browsing history, tab titles, URLs, webpage content and profiles outside this feature.
- Use native SwiftUI/AppKit controls and the existing `Theme`, `Card`, overlay and `AppState` patterns. Discovery requires no browser extension or new permission prompt.
- Preserve existing permission handling for synthesized paste. Accessibility permission is for paste synthesis, not discovering apps or scanning text.
- Keep unrelated user changes intact. Spec approval does not authorize implementation or a commit.

## Completion gates

- Spec stage ends after reviewing the written contract with the user. App work starts only after implementation approval.
- Each implementation task ends only when its listed verification passes. Record unavailable browsers and unrun app checks as pending.
- Use synthetic fixtures and isolated test stores/preferences. `GEL_HOME` does not isolate UserDefaults or the Keychain.
- Report measured timings and observed coverage. Describe discovery evidence as web-link handling, not a guarantee about an app's identity or a website's destination.
