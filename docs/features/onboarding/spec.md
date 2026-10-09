# U5 · Onboarding — Spec

**Goal:** a first-time user goes from launch to a searchable folder in under a minute, with the right pack on.

## Behaviour

One sheet over the main window on first launch (`GelSettings.onboardingDone == false`), three steps:

1. **Welcome:** Gel mark + "Your private AI layer. Everything stays on this Mac." **Who is this for?** two selectable cards: **Work: HR** (pack `hr`) and **Personal** (pack `personal`); multi-select allowed; at least one required.
2. **Folder:** "Choose the folder Gel should read" → `NSOpenPanel`. Suggest `demo-data/HR Files` when it exists next to the app's repo (dev convenience only).
3. **Indexing:** progress ("Reading 12 of 58 · Resume_REYES.pdf"), with a note that scans take longer. **Done** enables when indexing finishes (or **Continue in background**).

Then set `activePacks`, `folderPath`, `onboardingDone = true`. Permissions are requested later, when first needed (microphone on first hold-to-talk; Accessibility on first ⌥⌘V).

## Acceptance criteria

- [ ] On a fresh `GEL_HOME`/defaults, the sheet appears; completing it indexes the folder and never shows again.
- [ ] Choosing Personal only sets `activePacks == ["personal"]`.
