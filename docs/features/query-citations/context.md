# F3 · Query and citations — Context

## Why it exists

Demo beats 1–2: a Taglish question answered offline with chips, then one click to the highlighted page. Citations are also the answer to the judge's "a 4B model makes mistakes" ([demo-and-submission](../../project/demo-and-submission.md)). Serves **Problem & usefulness** and **Local AI implementation** ([context](../../project/context.md)).

## Where it sits

- **Upstream:** [indexing](../indexing/spec.md) (chunks, vectors, FTS5), [model-fallback](../model-fallback/spec.md) (`ModelRouter.chat`), [voice](../voice/spec.md) (spoken questions).
- **Downstream:** [launcher](../launcher/spec.md) (streams the answer, chips), [library-viewer](../library-viewer/spec.md) (opens `Citation` page + range), [history](../history/spec.md) (saved answers), [home](../home/spec.md) (`query` events → local share).

## Current state

Built in `Gel/GelCore/Query/QueryEngine.swift`: `search` (vector top 40 + BM25 top 40, RRF k = 60, ≤ 2 chunks per file, top 8), `systemPrompt`, `userPrompt`, `ask` (streams via `ModelRouter.chat`, cloud gate `Redactor.cloudSafe`), `citationNumbers`, history save and `query` event. Store side: `vectorSearch`, `keywordSearch`, `saveAnswer`, `history` in `Index/Store.swift`. Unit test `testCitationNumbers` passes. `gelcli ask` / `gelcli search` drive it.

**Missing:** end-to-end run on the demo data (the demo question has not been asked yet); measured timings; viewer highlight (app side).

## Facts and gotchas

- Local model `qwen3:4b-instruct-2507-q4_K_M`: ~24 tokens/s on the M2; first request after a cold load took ~34 s, so `ModelRouter.warmUp()` runs at launch and `keep_alive` is 60 min ([decisions D-009](../../project/decisions.md)).
- The demo question needs **many files** (every resume with payroll experience), hence the 2-per-file cap; Reyes's payroll line is on **page 2** of `Resume_REYES.pdf`, Santos in `Santos_Rodel_Resume.pdf`, Cruz in `CV - Patricia Anne Cruz.pdf`. Near-misses (< 5 years): Tolentino, Aguilar.
- The model must compute years from ranges like "2017–2024"; the system prompt asks it to do so carefully.
- **With Ollama down, `search` fails** (the question embedding needs `bge-m3`), so `ask` throws before the cloud fallback can answer. See tasks T6.
- Keyword search drops terms shorter than 3 characters and quotes each term, so user text can't break FTS5 syntax.

## Related

[spec](spec.md) · [tasks](tasks.md) · [interfaces](interfaces.md) · [model-fallback](../model-fallback/spec.md)
