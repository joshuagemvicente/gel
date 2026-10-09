# U4 · Settings — Spec

**Goal:** everything configurable in one calm module, with organization-managed items visibly locked.

## Sections

| Section | Controls | Notes |
| --- | --- | --- |
| Folders | A list of folders with **Add folders…** (multi-select), per-row remove, **Reindex now**, index stats; see [multi-folder](../multi-folder/spec.md) | Adding a folder indexes it immediately |
| Packs | A toggle per selectable pack with its description | Required packs from the policy are on and locked |
| Models | Local model and embedding model names, Ollama status (✓ / not running + how to start), warm-up button | Defaults from `GelSettings` |
| Cloud fallback | Enable toggle, Base URL, API key (secure field → Keychain), Model, first-token and total timeouts, **Test connection** (`GET {base}/models` → "OK · n models" or the error text) | Enable only when URL and model are set; locked if the policy disallows cloud |
| Hotkeys | Launcher hotkey recorder (KeyboardShortcuts), safe-paste hotkey (⌥⌘V) | |
| Permissions | Microphone and Accessibility status with **Open System Settings** buttons | Accessibility is needed for ⌥⌘V to paste |
| Policy | Current policy (organization or "Not managed"), **Install sample policy**, **Remove policy** | Sample = `TeamPolicy.sample` |

- **Locked items** show a lock glyph and "Managed by <organization>".
- The API key field never displays the stored key; it shows "Saved in Keychain" with a Replace button.

## Acceptance criteria

- [ ] Choosing `demo-data/HR Files` starts indexing and the Library fills.
- [ ] Test connection shows success for a valid endpoint and the exact error for an invalid one.
- [ ] The API key is stored in the Keychain and appears nowhere else (UserDefaults, database, logs).
- [ ] With the sample policy installed, the HR toggle and policy-governed controls are locked and labelled.
