# U11 · Model setup — Context

## Why it exists

The DMG build (demo-download addendum) goes to people who don't have Ollama. Today Gel shows "Local model unavailable", and Settings tells them to run `ollama pull …` or `brew services start ollama`. Most of them have neither Terminal habits nor Homebrew, so they stop there. The user asked for model presets with specs, plus installing Ollama when it's missing, so developers and users can fix this from Settings.

## Where it sits

Settings › Models (U4) only. No onboarding step and no footer "Fix" button (decided in the grilling, Q4). Download progress also shows in the sidebar status footer (Q10).

## Current state (before this feature)

- `GelSettings.localModel` (default `qwen3:4b-instruct-2507-q4_K_M`) and `embedModel` (`bge-m3`) live in UserDefaults; `GEL_LOCAL_MODEL` overrides the chat model.
- `ModelRouter.missingLocalModels()` (`/api/tags`), `ollamaReachable()` (`/api/version`) and `warmUp()` exist. `AppState.missingModels` and `localStatus` drive the footer and Settings.
- Settings › Models shows the two names read-only, a status line with the shell command to run, and a Warm up button.

## Facts and gotchas (checked 2026-10-10 00:35)

- `https://ollama.com/download/Ollama-darwin.zip` redirects to GitHub's latest release (v0.40.2), **206 MB**. It contains `Ollama.app`.
- Registry sizes (sum of manifest layers): `llama3.2:3b` 2.02 GB, `qwen3:4b-instruct-2507-q4_K_M` 2.5 GB, `gemma3:12b` 8.16 GB. Fallback candidates: `gemma3:4b` 3.35 GB, `qwen2.5:7b` 4.68 GB.
- This Mac: Apple M2, 16 GB RAM, Homebrew Ollama 0.34.4 at `/opt/homebrew/bin/ollama`, no `/Applications/Ollama.app`. Installed models: the default Qwen3 4B, `qwen3:4b`, `bge-m3`.
- Gel is **not sandboxed** (`Gel.entitlements`), so it can download, unzip with `/usr/bin/ditto` and launch apps.
- `POST /api/pull {"model", "stream": true}` streams NDJSON lines `{status, digest, total, completed}`, one series per layer. Cancelling the request leaves partial blobs that the next pull resumes.
- Ollama's first launch may show its own welcome window and offer to install its CLI (needs an admin password). That's Ollama's UI, not Gel's.
- Changing the chat model needs no re-index; only the embedding model would, and it stays fixed (Q3).

## Related docs

[spec](spec.md) · [design](design.md) · [tasks](tasks.md) · [settings](../settings/spec.md) · [model-fallback](../model-fallback/spec.md) · [demo-download](../../deliverables/demo-download/spec.md)
