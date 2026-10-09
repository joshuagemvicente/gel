# U11 · Model setup — Spec

**Goal:** From Settings › Models, someone without Ollama or any model can install Ollama, start it, pick a recommended model and download it, all without Terminal. Every preset shows honest specs.

Approved by the user on 2026-10-10. Decisions come from the grilling that day (Q1–Q12).

## Behaviour

### Ollama state

Settings › Models detects one of three states and shows one action for it:

| State | How it's detected | Action |
|---|---|---|
| **Not installed** | No `Ollama.app` in `/Applications` or `~/Applications`, and no `ollama` binary at `/opt/homebrew/bin` or `/usr/local/bin` | **Install Ollama…** (confirm sheet) |
| **Installed, not running** | Installed, but `GET /api/version` fails | **Start Ollama**: opens `Ollama.app` if present, otherwise runs `<brew path>/ollama serve` in the background. Then it polls `/api/version` every second for up to 20 s. |
| **Running** | `/api/version` answers | "Ollama is running · v<version>" |

### Install Ollama (Q1, Q9)

1. A confirm sheet shows:
   - The source: ollama.com, the official app.
   - The size: about 206 MB.
   - The destination: `/Applications`, or `~/Applications` if `/Applications` isn't writable.
   - "None of your files are sent. This only downloads the Ollama app."
   - Buttons: **Install** and **Cancel**.
2. Gel downloads `https://ollama.com/download/Ollama-darwin.zip` with a progress bar (MB of MB) and a Cancel button.
3. Gel unzips with `/usr/bin/ditto -x -k` into a temporary folder.
4. Gel checks the signature: `Ollama.app` must pass a strict code-signature check, and its Team ID must match Ollama's (read once from the real app and pinned in code). If either check fails, Gel installs nothing, deletes the download and says why.
5. Gel moves the app to the destination and launches it, then continues as **Start Ollama**.
6. On any failure, the sheet shows the error and an **Open download page** button (`https://ollama.com/download`).

### Presets (Q2, Q5, Q6, revised by D-065)

**One** chat-model preset ships. The embedding model is not a choice (Q3).

| Tier | Name | Ollama tag | Download | Recommended RAM | Measured (M2 16 GB, model loaded) |
|---|---|---|---|---|---|
| Recommended | Qwen3 4B Instruct | `qwen3:4b-instruct-2507-q4_K_M` | 2.5 GB | 8 GB | ≈ 12.4 s to first words, 16.9 s full answer |

The planned Light (`llama3.2:3b`, then `gemma3:4b`) and Quality (`gemma3:12b`, then `qwen2.5:7b`) presets were measured in T1. All four were dropped under Q12 because they answered the demo question wrongly or timed out (D-065). The catalog is a list, so a preset that passes T1's check later can be added as another row.

- **Speed line:** the measured median from T1, logged in D-065.
- **RAM warning:** if `ProcessInfo.physicalMemory` is below the preset's recommended RAM, show amber text "Needs 8 GB · this Mac has 4 GB". The preset can still be used.
- **Card state:**
  - **In use:** the preset is the current `localModel`.
  - **Use:** downloaded, not in use.
  - **Download & use:** not downloaded.
  - **Downloading 42% · Cancel**
  - **Set by environment:** `GEL_LOCAL_MODEL` is set; every card is disabled.
- **Custom model:** if the current `localModel` isn't one of the presets (for example `qwen3:4b`), show "Using a custom model: `<tag>`" above the cards.
- **The embedding model** shows as a line: "Embeddings: bge-m3 · 1.2 GB · ✓ downloaded" or "will download with your first model".

### Use a preset (Q7)

One button does the whole job:

1. Ollama must be running. If not, the button is disabled with "Start Ollama first".
2. **Disk check:** if the free space on the home volume is less than the missing download plus 1 GB, show "Needs X GB free · Y GB available" and don't start.
3. If `bge-m3` is missing, pull it first, then the chat model. Both use `POST /api/pull` with streaming. Progress is the sum of `completed / total` across all layers.
4. On success: set `GelSettings.localModel` to the tag, run `warmUp()`, then `refreshHealth()`. Future answers use the new model, and the provider badge shows its name.
5. **Cancel** stops the request. The model stays unchanged, and partial layers resume next time.
6. On error, the card shows the error text and **Retry**.

Only one download runs at a time; other cards' buttons are disabled while it runs.

### Progress outside Settings (Q10)

The download lives in `AppState`, so it keeps running when you leave Settings. When the app isn't indexing, the sidebar footer shows "Downloading Gemma 3 12B · 42%" on the existing static 2 pt bar. Indexing progress takes precedence. Cancel is only in Settings.

### Status text

The old hints ("Run: ollama pull …", "brew services start ollama") are removed from Settings and the menu bar menu. The menu bar menu instead says "Model missing · open Settings › Models".

### DEBUG verification hooks (Q11)

Compiled only in DEBUG builds:

- `GEL_DEBUG_PRETEND_NO_OLLAMA=1` makes detection report **Not installed**.
- `GEL_DEBUG_OLLAMA_INSTALL_DIR=<path>` replaces the destination.

These let the real download, signature check and launch be tested without touching this Mac's Homebrew Ollama. A release build ignores both.

## Out of scope

- Deleting models.
- Choosing the embedding model.
- An onboarding step or a footer "Fix" button.
- Custom tags typed by the user.
- Updating an existing Ollama.
- Changing `localBaseURL`.
- `gelcli` commands.

## Acceptance criteria

- [ ] **AC1 States.** With Ollama running, Settings shows "Ollama is running · v0.34.4". With `brew services stop ollama`, it shows **Start Ollama**, and clicking it brings Ollama back within 20 s (the status turns green). With `GEL_DEBUG_PRETEND_NO_OLLAMA=1`, it shows **Install Ollama…**.
- [ ] **AC2 Install (scratch).** With both DEBUG variables set, Install shows the confirm sheet with source, size and the scratch destination. Confirming downloads about 206 MB with live progress, passes the signature and Team ID check, places `Ollama.app` in the scratch folder and launches it. Tampering with the bundle (changing one file in the unzipped app before the check) makes it refuse and delete the download.
- [ ] **AC3 Presets.** The Qwen3 4B card shows name, size, RAM and the measured speed from D-065, and says In use on this Mac.
- [ ] **AC4 Download & use.** (Verified by removing the Qwen3 4B model first, since it's the only preset.) Choosing a preset that isn't downloaded shows rising progress in the card and in the sidebar footer, survives switching to Home and back, then shows In use. After that, a launcher answer's provider badge names the new model.
- [ ] **AC5 Cancel and resume.** Cancelling mid-download leaves the model unchanged. Retrying resumes, so its first progress value is above 0%.
- [ ] **AC6 Embedding auto-pull.** After `ollama rm bge-m3`, Download & use pulls bge-m3 first, then the chat model. Search works afterwards.
- [ ] **AC7 Guards.** Setting `GEL_LOCAL_MODEL` locks the cards with "Set by environment". `GEL_DEBUG_RAM_GB=4` shows the amber RAM warning. `GEL_DEBUG_FREE_DISK_GB=2` with a missing model shows "Needs X GB free" and disables the button.
- [ ] **AC9 No-cloud wait (D-064).** With no cloud configured, a local answer whose first token takes over 15 s still arrives (Qwen2.5 7B at 19–23 s was observed answering through `gelcli`). With cloud configured, the 15 s limit still triggers the fallback.
- [ ] **AC8 No regressions.** `Gel` and `gelcli` build, `GelCoreTests` pass, and the main window shows no animation during downloads. Clicking through all modules while a download runs causes no crash.
