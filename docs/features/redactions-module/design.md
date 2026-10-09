# U8 · Redactions & Leak Guard module — Design

## Redact sheet (720 × 560)

```
Redact 3 files
Scanning… Resume_REYES.pdf (2 of 3)  ▓▓▓▓▓░░░        AI check: on this Mac

GOVERNMENT ID · 6                                    [✓ all]
  ✓ 34-5678901-2        SSS number       Resume_REYES.pdf
  ✓ 123-456-789-000     TIN              Resume_REYES.pdf
  …
SALARY · 2
  ✓ ₱28,500.00          salary           Santos_Rodel_Resume.pdf
ADDRESS · 3  ·  NAME · 5  ·  CONTACT · 4  (collapsed groups)

                                   [ Cancel ]   [ Redact 3 files ]
```

- Groups collapsible, each with a group checkbox; values in monospaced 12 pt; the caption shows where the AI check ran: "on this Mac", "via cloud fallback (redacted text)", or "unavailable — review manually".
- After writing: a results list with each output name and **Reveal in Finder**.

## Module view

Three sections stacked:

1. **Redacted files**: rows: date, `source → output`, counts summary ("3 government IDs, 1 salary"), open/reveal buttons.
2. **Leak Guard log**: rows: time, app, summary; caption above: "Counts only. Gel never stores what you copied."
3. **Report**: date range pickers (default last 30 days) + **Export report** (accent) → reveals the CSV and PDF.

Empty states: "No redactions yet. Select files in Library and click Redact." / "No leaks caught yet."
