# U5 · Onboarding — Context

## Why it exists

The pack choice is the B2B/B2C fork in the product: **Work: HR** (B2B, priority) or **Personal** (B2C). Onboarding makes that choice explicit and gets a folder indexed so the launcher works on the first try. Judges may install Gel from the README, so a clean first run supports **Technical Execution (20%)**.

## Where it sits

- **Upstream:** app-shell (shows the sheet when `GelSettings.onboardingDone == false`), packs (`PackStore.selectablePacks`), indexing (`Indexer().index(folder:progress:)`).
- **Downstream:** everything; afterwards Settings owns these choices.

## Current state

- Nothing built in the app target. `GelSettings.onboardingDone`, `activePacks` and `folderPath` exist.

## Facts and gotchas

- Indexing the 58 demo HR files includes 10 scans (OCR) and embeddings for every chunk; show per-file progress and allow "Continue in background".
- For development, the repo's `demo-data/HR Files` is the natural folder; offering it as a suggestion is a dev convenience only (hide it when the folder doesn't exist).
- Testing a fresh first run: use a new `GEL_HOME` and reset defaults with `defaults delete com.joshuagemvicente.gel`.

## Related docs

[spec](spec.md) · [design](design.md) · [tasks](tasks.md) · [packs](../packs/spec.md) · [indexing](../indexing/spec.md)
