# U2 · Launcher — Spec

**Goal:** an instant, Spotlight-position search bar where you ask by voice or text and get a short cited answer.

## Behaviour

- **Hotkey:** ⌥Space (KeyboardShortcuts name `toggleLauncher`, rebindable in Settings) toggles the launcher from any app. The demo's leak step uses chatgpt.com in Chrome, because the ChatGPT desktop app also uses ⌥Space.
- **Window:** borderless floating `NSPanel` (non-activating style, but becomes key so the field accepts typing), 640 pt wide, centered horizontally, top edge ~22% down the active screen. Esc or clicking outside closes it. Appears with a slight scale-and-fade.
- **Input:** one field, placeholder "Ask your files… hold ⌥ to talk", mic glyph on the right. Holding right ⌥ records (voice spec); the transcript fills the field and runs on release.
- **Run:** Enter runs `QueryEngine.ask`. The answer streams below the field (shimmer while waiting for the first token). Then a row of citation chips (`1 · Resume_REYES p.2`) and a provider badge (**Local · model** in green, **Cloud · model** in neutral).
- **Chips:** clicking a chip closes the launcher, opens the main window on the Library viewer at that file and page, highlighted (library-viewer spec).
- **Errors:** one inline line, e.g. "Local model unavailable · Retry", "Nothing indexed yet · Choose a folder".
- **History:** every answer is already saved by the engine; "Open in Gel" opens History on it.

## Acceptance criteria

- [ ] ⌥Space opens the launcher at top-center from any app in under 200 ms; Esc closes it.
- [ ] A typed question streams an answer with citation chips and the right provider badge.
- [ ] Clicking a chip opens the main window at the cited page with the passage highlighted.
- [ ] With nothing indexed, the launcher says so and offers to choose a folder.
