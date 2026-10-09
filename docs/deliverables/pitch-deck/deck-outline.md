# S8 · Deck outline (v1)

Status: **v1, Oct 10 early morning.** Source of truth for the Canva build. 16:9. Colours and type in [design.md](design.md). `⚠` = re-check at the 06:00 freeze.

Built file: `media/deck/gel-pitch.pptx` and `gel-pitch.pdf` (git-ignored; generator `media/deck/build.js`). Canva design (built natively from this outline, Oct 10 ~05:30; slides 5, 7, 9–12 corrected to this outline after generation): https://canva.link/c0mcwdfmixt0wc6 · offline export `media/deck/gel-pitch-canva.pdf`.

---

## Main deck (8 slides)

### 1 · Title (S4 block 1, 0:00)
- **Headline:** Gel
- **Sub:** Private AI for your files. Runs on your Mac.
- **Small:** Team 12M · AppBuildersPH Hackathon 2026
- **Visual:** Gel drop + wordmark, centred.
- **Cue:** on screen while you tell the Makati story.

### 2 · Stat: sensitive data (S4 block 1, end ~0:12)
- **Big number:** Nearly 40%
- **Line:** of interactions with AI tools involved sensitive data.
- **Source (small):** Cyberhaven Labs, 2026 AI Adoption & Risk Report · 222 companies · 2025 data
- **Cue:** advance on "Cyberhaven, a data-security firm…".

### 3 · Stat: bring your own AI (S4 block 2, 0:20)
- **Big number:** 83%
- **Line:** of Filipino AI users bring their own AI tools to work.
- **Sub-line:** HR files hold SSS and TIN numbers, salaries and addresses: Data Privacy Act data.
- **Source (small):** Microsoft & LinkedIn, 2024 Work Trend Index (Philippines)
- **Cue:** advance on "Microsoft and LinkedIn's 2024 survey…".

### 4 · Demo divider (S4 blocks 3–5, 0:45)
- **Headline:** Live demo
- **Sub:** Wi-Fi off. Everything runs on this Mac.
- **Visual:** small Wi-Fi-off glyph above the headline; Gel drop bottom-right.
- **Cue:** advance on "I'm Joshua, team 12M…", then ⌘Tab to the app.

### 5 · Why local (S4 block 6, 3:15)
- **Headline:** Why it has to be local
- **Four tiles:**
  - **Private:** files never leave the Mac
  - **Works offline:** you just saw it
  - **Free per copy:** every clipboard check, no API bill
  - **Fast:** 58 files indexed in 25.5 s on an M2
- **Source (small):** measured on our M2, 16 GB (58 demo files incl. 10 OCR scans)
- **Cue:** ⌘Tab back to the deck after the demo; advance on "So why run AI locally?".

### 6 · Cloud fallback (S4 block 6, end ~3:40)
- **Headline:** The cloud only sees placeholders
- **Diagram:** inside a "Your Mac" frame: `Your files` → `On-device AI (Whisper · BGE-M3 · Qwen3 4B)` → `Cited answer`. A dotted line from the AI box to `Redactor` → out of the frame to `Cloud (optional, off by default)`, with a chip `[SSS_1]` on the dotted line.
- **Cue:** advance on "If the local model fails…".

### 7 · Business (S4 block 7, 3:50)
- **Headline:** HR teams first. Everyone next.
- **Two columns:**
  - **Teams (paid, per seat):** admin policy (warn or block) · counts-only DPO report
  - **Personal (free):** IDs, bank statements, medical records
- **Footer:** Next: finance and legal packs. A pack is a config file, not code.
- `⚠` keep "admin policy" and "DPO report" only if policy-dpo-report is verified at the freeze; otherwise say "planned".
- **Cue:** advance on "HR teams pay first…".

### 8 · Close (S4 block 8, 4:15)
- **Headline:** Gel
- **Sub:** Private AI for your files. Runs on your Mac.
- **Proof points:** ✓ Works offline · ✓ Cites every answer · ✓ Stops leaks to ChatGPT `⚠` keep only those that pass QA
- **Ask (accent):** People's Choice: vote for 12M
- **Footer:** github.com/joshuagemvicente/app-hackathon · #AppBuildersPH
- **Cue:** stays up through Q&A.

---

## Appendix (Q&A only)

### A1 · Measured on our M2 (16 GB)
- Indexing 58 demo files incl. 10 OCR scans: 25.5 s
- Demo question: ~9–10 s to first word, ~16 s full answer (first time); 0.2 s / 6.3 s when repeated
- Fast detection recall on the demo set: 100% for IDs, cards, phones, emails, addresses, bank accounts, salaries
- Redacted outputs: no text layer; OCR finds 0 of 11 original values
- **Source:** `docs/project/decisions.md` D-030, D-036

### A2 · What runs where
- **On the Mac:** speech (Whisper large-v3 turbo, WhisperKit) · OCR (Apple Vision) · search (BGE-M3 + SQLite) · answers (Qwen3 4B Instruct, Ollama) · detection, redaction, Leak Guard
- **Needs internet:** first-time model download · optional cloud fallback (redacted text only)

### A3 · Privacy rules we never break
- Counts, never content, in logs and reports
- Redacted before anything leaves the Mac; if redaction fails, nothing is sent
- API key in the macOS Keychain
- Synthetic demo data only

### A4 · Sources
- Cyberhaven Labs, "2026 AI Adoption & Risk Report", Feb 2026: 39.7% of AI interactions involved sensitive data; 222 customer companies, 2025 data. Vendor research (Cyberhaven sells data-security software).
- Microsoft & LinkedIn, "2024 Work Trend Index", Philippines release, May 23, 2024: 83% of Filipino AI users bring their own AI tools (global 78%). Survey by Edelman, 31,000 people, 31 markets.
- Republic Act 10173 (Data Privacy Act of 2012), Sec. 3(l): government-issued identifiers are sensitive personal information.
