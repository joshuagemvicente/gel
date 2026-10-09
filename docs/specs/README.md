# Gel specs

These files are the single source of truth for what Gel is and how to build it. Read them before writing code; update them before changing behaviour.

## Reading order

| File | Read it when you need to know… |
| --- | --- |
| [01-role.md](01-role.md) | Who you are on this project, the hard rules, and your working loop. Read first, every session. |
| [02-context.md](02-context.md) | The hackathon: rules, judging, deadline, hardware, what "Local AI" means here. |
| [03-product.md](03-product.md) | What Gel is, who it's for, packs, B2B/B2C, the two app surfaces. |
| [04-architecture.md](04-architecture.md) | Targets, folders, data flow, storage, model routing, key types. |
| [features/](features/) | One spec per feature, each with acceptance criteria. Read the one your task names. |
| [05-tasks.md](05-tasks.md) | The ordered task list and what's done. Pick work from here. |
| [06-decisions.md](06-decisions.md) | Why things are the way they are, including deviations from the original plan. |
| [07-demo-and-submission.md](07-demo-and-submission.md) | The Demo Day script and the submission checklist. |
| [08-conventions.md](08-conventions.md) | Build/test/CLI commands, environment variables, code style. |

## Feature specs

| ID | Spec | One line |
| --- | --- | --- |
| F1 | [F1-indexing.md](features/F1-indexing.md) | Extract, OCR, chunk, embed and store the chosen folder |
| F2 | [F2-voice.md](features/F2-voice.md) | Hold-to-talk Taglish transcription with WhisperKit |
| F3 | [F3-query-citations.md](features/F3-query-citations.md) | Hybrid search and a cited answer |
| F4 | [F4-detection-redaction.md](features/F4-detection-redaction.md) | Three-layer personal-data detection, placeholder text, burned-in PDFs |
| F5 | [F5-leak-guard.md](features/F5-leak-guard.md) | Clipboard watcher, leak overlay, safe paste |
| F6 | [F6-finder-selection.md](features/F6-finder-selection.md) | Cut. Replaced by the Library's Redact button |
| F7 | [F7-packs.md](features/F7-packs.md) | Configurable detection packs (HR, Personal, …) |
| F8 | [F8-policy-dpo-report.md](features/F8-policy-dpo-report.md) | Team policy file and counts-only compliance report |
| — | [model-provider-fallback.md](features/model-provider-fallback.md) | Local-first LLM routing with a redacted cloud fallback |
| — | [app-surfaces.md](features/app-surfaces.md) | Launcher, main window, modules, menu bar, look and feel |

The original planning doc (human-facing, with diagrams) is the Claude Doc "Gel — Hackathon Spec": https://claude.ai/code/artifact/5348f9fe-3344-441a-a5fb-87a8cd00c9f6. When it and these files disagree, these files win.
