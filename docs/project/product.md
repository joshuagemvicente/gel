# Product

## One line

**Gel is a private AI layer for your Mac:** ask your own files questions out loud in Taglish, get answers with highlighted citations, and keep personal data out of cloud AI. All AI runs on the Mac; a user-supplied OpenAI-compatible endpoint is a fallback for LLM tasks only, and it only ever receives redacted text.

Name styling: **Gel** in UI, README and pitch; `gel` in code identifiers; bundle ID `com.joshuagemvicente.gel`.

## Who it's for

- **B2B first (priority):** HR, recruiting and payroll teams at Philippine SMEs and BPOs, the launch market and the demo story. Then finance/KYC and legal teams.
- **B2C:** anyone who keeps IDs, bank statements or medical records on their Mac, through a free Personal pack.

## The problem

Staff paste employee and customer records into ChatGPT to summarize and shortlist; individuals paste IDs and bank statements. Those carry government ID numbers, salaries, account numbers and addresses covered by the Data Privacy Act. Spotlight finds files but can't answer questions or cite a scanned page, and nothing stops the paste.

## Why local (the required answer)

HR files and personal documents contain government ID numbers, salaries, account numbers and home addresses protected by the Data Privacy Act; sending them to a cloud AI is the exact risk companies and individuals need to avoid. Running speech, search, OCR and the LLM on the Mac keeps sensitive files on it, works offline, and makes checking every clipboard copy free. When the local model fails, the cloud fallback only ever sees redacted text.

## What it does (capabilities → feature specs)

| Capability | Spec |
| --- | --- |
| Index one chosen folder of PDFs, scans and DOCX, including OCR | F1 |
| Ask by voice (hold-to-talk, Taglish) or by typing | F2, UI features |
| Cited answers; a citation opens the page highlighted | F3, UI features |
| Detect and redact personal data; burned-in PDFs | F4 |
| Catch personal data on the clipboard before it reaches an AI app; safe paste | F5 |
| Packs: HR (full), Personal (light); more later as JSON | F7 |
| Team policy (warn/block, locked settings) and DPO report | F8 |
| Local-first LLM with redacted cloud fallback | model-fallback |

## Two surfaces

1. **Launcher**: top-center panel on ⌥Space (where Spotlight/Raycast sit) for quick voice or typed questions and short cited answers.
2. **Main window**: a Wispr Flow-style Dock app with a module sidebar (Home, History, Library + viewer, Redactions & Leak Guard, Settings) and a menu bar icon.

Details: `docs/features/app-shell/`, `launcher/`, `library-viewer/`, `settings/`, `onboarding/`, `home/`, `history/`, `redactions-module/`.

## Packs and go-to-market

A **pack** is configuration, not code: data types with patterns, sample questions and demo files.

| Pack | Audience | Catches | Hackathon |
| --- | --- | --- | --- |
| Core (always on) | everyone | emails, phone numbers, birth dates, addresses | built |
| HR | B2B | SSS, TIN, PhilHealth, Pag-IBIG, PhilSys, salaries, payroll accounts | full |
| Personal | B2C | PhilSys, passport, driver's license, bank/GCash, cards (Luhn), amounts | light |
| Finance/KYC, Legal | B2B | — | after the hackathon |

- **B2B layer shown in the hackathon:** team policy file (warn/block per data type, watched apps, locked settings) and the counts-only DPO report.
- **B2C path:** a free Personal app; people bring it to work, which creates demand for team plans.
- **Business model (pitch only):** per-seat team plans; free Personal app. After the hackathon: embed the model runtime (drop the Ollama dependency), notarized download, Homebrew cask.

## Out of scope

Windows/AMD builds, multi-user sync, cloud embeddings or cloud speech-to-text, editing original files, App Store sandboxing, compliance certification, a mobile app, Finder-selection commands (F6, cut).
