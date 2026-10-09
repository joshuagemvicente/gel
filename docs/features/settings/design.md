# U4 · Settings — Design

## Layout

A single scrolling column (max width 640 pt) of `Card`s, one per section, in this order: Folder, Packs, Models, Cloud fallback, Hotkeys, Permissions, Policy. Each card: section title (15 pt semibold), one-line description (textSecondary), then controls.

```
┌ Cloud fallback ─────────────────────────────────────────────┐
│ Used only if the local model fails. Gets redacted text only. │
│ [ ] Enable cloud fallback                                    │
│ Base URL   [ https://…/v1                              ]     │
│ API key    Saved in Keychain   (Replace)                     │
│ Model      [ claude-…                                  ]     │
│ Timeouts   First token [ 8 ] s   Total [ 30 ] s              │
│ (Test connection)   ✓ OK · 12 models                         │
└─────────────────────────────────────────────────────────────┘
```

## Copy

| Section | Description line |
| --- | --- |
| Folder | Gel reads this folder and its subfolders. Files never leave your Mac. |
| Packs | Choose what personal data Gel looks for. |
| Models | These run on this Mac through Ollama. |
| Cloud fallback | Used only if the local model fails. It receives redacted text only. |
| Hotkeys | Open the launcher and paste safely from anywhere. |
| Permissions | Gel asks only for what a feature needs. |
| Policy | Your organization can manage some settings. |

## States

- Locked control: dimmed, lock glyph, `LockedLabel` under it.
- Env override: caption "Set by environment variable" under the field, field read-only.
- Ollama not running: red dot + "Ollama isn't running. Start it with `brew services start ollama`."
- Test connection: idle → spinner (inline, 16 pt) → ✓ OK · n models (accent) or ✕ <error> (danger, selectable text).
