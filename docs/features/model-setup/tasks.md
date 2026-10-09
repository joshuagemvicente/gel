# U11 · Model setup — Tasks

Status: `[x]` done and verified · `[~]` built, not verified · `[ ]` not started.

- [x] **T1 Measure presets.** Pull `llama3.2:3b` and `gemma3:12b`. Run the demo question 3× per preset with `GEL_LOCAL_MODEL=<tag> gelcli ask …` (warm model). Record the median first token and total, and check the citations. Swap any preset that fails (spec, Q12). Log a decisions.md row with the numbers.
  **Verify:** AC3 numbers. Done 2026-10-10: only Qwen3 4B passed. Four candidates were dropped and the no-cloud first-token limit changed (D-064, D-065).
- [x] **T2 Catalog + pull client (GelCore).** `ModelCatalog` (the presets, embedding info, the RAM and disk checks) and `OllamaClient.pull(model:progress:)` streaming `/api/pull` with cancellation, plus `version()`. Unit tests: NDJSON progress aggregation across layers, and cancellation. Files: `Gel/GelCore/LLM/ModelCatalog.swift`, `Gel/GelCore/LLM/OllamaPull.swift`, tests.
  **Verify:** `GelCoreTests` pass. Done: 40/40, including 9 in `ModelSetupTests` (aggregation, error line, garbage lines, stubbed stream to success, incomplete stream, cancellation, catalog guards, env lock).
- [~] **T3 Ollama detect / start / install (app).** `OllamaSetup`: state detection, Start (app or `ollama serve`), and install (download, ditto, signature + Team ID check, move, launch), plus the DEBUG env hooks. Files: `Gel/Gel/Settings/OllamaSetup.swift`.
  **Verify:** AC1, AC2.
- [~] **T4 Download state in AppState + footer.** `AppState.modelDownload` (title, fraction, error) and `useModel(_:)` (bge-m3 first, then the chat model, then switch, warm up, refresh health). The footer line goes in `MainView`. The menu bar text changes. Files: `App/AppState.swift`, `Main/MainView.swift`, `App/AppDelegate.swift`.
  **Verify:** AC4, AC5, AC6.
- [~] **T5 Settings UI.** The Models card (state row, preset cards, embeddings line), the install sheet, and the guards. Files: `Settings/SettingsView.swift`, `Settings/ModelPresetsView.swift`.
  **Verify:** AC3, AC7; screenshots in light and dark.
- [ ] **T6 Final pass.** Build `Gel` and `gelcli`, run the tests, click through all modules during a download, update `docs/README.md` status.
  **Verify:** AC8.
