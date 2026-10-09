# Demo and submission

## Demo Day script (5 minutes + 3 minutes Q&A)

Time budget: ~40 s problem, ~3 min HR demo, 20 s consumer reveal, ~60 s why local + business model. Prioritize the live product over slides. All files shown are synthetic.

1. **Offline voice query.** Wi-Fi off on stage. ⌥Space, hold right ⌥: *"Sino sa applicants ang may 5+ years sa payroll?"* → launcher transcript, streamed answer naming Reyes, Santos, Cruz with chips and a **Local** badge.
2. **Verify the citation.** Click Reyes's chip → main window Library viewer at page 2 of a resume, passage highlighted.
3. **Redact from the Library.** Select the three resumes → Redact → preview of findings → burned-in PDFs listed under Redactions.
4. **Catch a leak.** Wi-Fi on. Copy an employee record, switch to chatgpt.com in Chrome (not the ChatGPT desktop app, which also uses ⌥Space) → overlay "This would leak 3 government ID numbers, 1 salary, 1 address", locked to **block** by the sample company policy → ⌥⌘V pastes placeholders. Home stats tick up; Export report (counts only).
5. **Consumer reveal (20 s).** "Same engine, for everyone." Menu bar → Pack → Personal; copy the passport + bank sample into chatgpt.com → Leak Guard catches it with no setup.
6. **Optional fallback.** Stop Ollama, ask again → **Cloud** badge; "What was sent" shows only placeholders.

Backup: a recorded run of the full chain in case the venue setup fails.

### Likely judge questions

- *Isn't this Spotlight + Raycast?* One chain from voice to cited answer to redaction to safe paste, built around Philippine personal data.
- *A 4B model makes mistakes.* Every answer cites its source and opens it highlighted, so the user verifies.
- *Doesn't the cloud fallback break the privacy promise?* Off until configured, redacted text only, badged, with "What was sent".
- *What if it over-redacts?* On purpose; the user un-ticks findings in the preview.
- *Who is it for / how does it make money?* HR teams first (legal duty, DPO); packs extend to finance, legal and consumers; per-seat team plans, free Personal app.
- *How fast is it?* Only numbers measured on this M2 (record them in `docs/project/decisions.md` as they're measured).

## Submission (deadline 10:00 AM Oct 10, once, no edits)

Team name: **12M**. Submit on https://cerebralvalley.ai/e/appbuildersph-hackathon-2026.

- [ ] Project name: Gel · short description (one line from `docs/project/product.md`)
- [ ] Team members (solo)
- [ ] Public GitHub repo (`joshuagemvicente/app-hackathon` — currently **private**, make public before 10:00 AM) with setup steps for judges
- [ ] Demo video (~1 min) and X/LinkedIn post tagging Devin/Cognition with #AppBuildersPH
- [ ] What runs locally / what needs internet (table below)
- [ ] Disclosures (below) and the why-local answer (`docs/project/product.md`)

### Runs locally vs needs internet

| Function | Local | Internet |
| --- | --- | --- |
| Speech-to-text | WhisperKit | no |
| OCR | Apple Vision | no |
| Embeddings / search | Ollama `bge-m3`, SQLite | no |
| Answers | Ollama `qwen3:4b-instruct-2507` | only as fallback to the user's endpoint, redacted |
| Personal-data detection | patterns, NaturalLanguage, local LLM | only the LLM pass as fallback, on pre-redacted text |
| Redaction, Leak Guard, reports | yes | no |
| First-time model downloads | — | once, during setup |

### Disclosures

- **Models:** Qwen3 4B Instruct 2507 (Q4_K_M), BGE-M3, Whisper large-v3 turbo (WhisperKit); cloud fallback model as configured by the user.
- **Frameworks/libraries:** Swift, SwiftUI, AppKit, PDFKit, Vision, NaturalLanguage, SQLite (FTS5), Ollama, WhisperKit, KeyboardShortcuts, XcodeGen; demo-data generator: Python, reportlab, python-docx, Pillow.
- **APIs/cloud services:** a user-supplied OpenAI-compatible endpoint, fallback only.
- **Existing code/assets:** none; all code written during the hackathon; demo data generated.
- **AI development tools:** Claude Code.
