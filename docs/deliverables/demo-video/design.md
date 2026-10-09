# S3 · Demo video — Design

## Recording setup (user, before S01)

- Display at its default "looks like" resolution; recording at native resolution, downscaled to 1080p in the edit.
- Do Not Disturb on; Dock hidden (⌥⌘D); desktop icons hidden; only Gel, Chrome (chatgpt.com, logged out or a neutral profile) and Finder open.
- Gel indexed on `demo-data/HR Files`, pack HR, sample policy loaded, Ollama warmed with one throwaway question.
- Cursor visible; move it slowly and pause 1 s before and after each click (clean cut points).

## Shots (one `.mov` each)

| Shot | Record this | Hold before/after | Used in beat |
| --- | --- | --- | --- |
| S01 | Gel main window Home, still, 5 s | — | 1 (hook background) |
| S02 | Open Control Center → turn Wi-Fi off → close; menu bar shows Wi-Fi off | 2 s | 2 |
| S03 | ⌥Space → hold right ⌥ → say *"Sino sa applicants ang may 5+ years sa payroll?"* → release → let the answer finish streaming | 3 s after the last token | 3 |
| S04 | Click the first citation chip → viewer opens on the highlighted page; hold | 3 s | 4 |
| S05 | Turn Wi-Fi on; open `demo-data/clipboard-samples/employee_record.txt`, select all, copy | 1 s | 5 |
| S06 | Switch to Chrome chatgpt.com → overlay appears → press ⌥⌘V → placeholders appear in the input; hold | 3 s | 5 |
| S07 | (Spare) Library → select resumes → Redact → preview → redacted PDF | 2 s | substitute |

Do two takes of S03 and S06; the best one is used.

## Captions

- Font: SF Pro Display Semibold (system); white text on a 70% black rounded box, bottom-center, 48 px at 1080p, max 2 lines, ≤ 8 words per line.
- One caption per beat; sentence case; no exclamation marks.
- Draft captions (finalized after recording, must match what's on screen):
  1. "HR files are full of government IDs."
  2. "Wi-Fi off. Everything below runs on this Mac."
  3. "Ask in Taglish. Get a cited answer."
  4. "Every answer opens its source."
  5. "Copy an employee record into ChatGPT…" → "Gel catches it and pastes a redacted copy."
- Speed tag: small `2×` pill top-right while sped up.

## Title and end cards

- No title card (the hook caption sits over S01 instead), to save seconds.
- End card, 4 s: warm off-white background, "Gel" large, "Private AI for your files. Runs on your Mac." below, then `Team 12M · github.com/joshuagemvicente/gel · #AppBuildersPH` in small text. Colors from `docs/features/app-shell/design.md`.

## Transitions

Hard cuts only; a 6-frame crossfade into the end card. No zooms unless a UI element is under ~3% of the frame (then a single slow 1.0→1.4 zoom on it).
