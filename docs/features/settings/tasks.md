# U4 · Settings — Tasks

Status: `[x]` done and verified · `[~]` built, not verified · `[ ]` not started.

- [~] **T1 Folder card.** Choose (`NSOpenPanel`), Reindex now, stats. Files: `Gel/Gel/Settings/SettingsView.swift`.
  **Verify:** choose `demo-data/HR Files` → indexing starts → Library fills.
- [~] **T2 Packs card.** Toggles from `PackStore.shared.selectablePacks`; policy-required packs locked.
  **Verify:** toggling Personal changes `GelSettings.activePacks` and Leak Guard results immediately.
- [~] **T3 Models card.** Model names, Ollama health dot, warm-up button.
  **Verify:** stop/start Ollama → status updates.
- [~] **T4 Cloud fallback card.** Enable toggle, URL, Keychain-backed key field, model, timeouts, Test connection (`OpenAICompatibleClient(baseURL:apiKey:model:).listModels()`).
  **Verify:** with the user's endpoint, Test connection shows OK; with a wrong URL, the error text; `defaults read com.joshuagemvicente.gel` shows no key.
- [~] **T5 Hotkeys card.** `KeyboardShortcuts.Recorder` for the launcher; safe paste shown as ⌥⌘V.
  **Verify:** rebinding the launcher hotkey works immediately.
- [~] **T6 Permissions card.** Microphone and Accessibility status + deep links.
  **Verify:** statuses match System Settings after granting.
- [~] **T7 Policy card.** Show org or "Not managed"; Install sample policy / Remove policy; locked labels across Settings.
  **Verify:** install → HR toggle and cloud toggle (if governed) show "Managed by Bayanihan Outsourcing Corp."; remove → unlocked.

Done when: all [spec.md](spec.md) acceptance criteria are observed passing.
