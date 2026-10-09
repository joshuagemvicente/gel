# U7 · History — Design

```
History                                        🔍 Search questions
┌ TODAY ───────────────────────────┐ ┌─────────────────────────────────────────┐
│ 10:42pm Sino sa applicants… Local│ │ Sino sa applicants ang may 5+ years…    │
│ 10:31pm Ano ang basic salary… Cloud│ │                                         │
├ YESTERDAY ───────────────────────┤ │ 3 applicants have 5+ years in payroll:  │
│ …                                 │ │ … ⁽1⁾ … ⁽2⁾ … ⁽3⁾  (citation pills)      │
└───────────────────────────────────┘ │ (1 · Resume_REYES p.2) (2 · …) (3 · …)  │
                                      │ Local · qwen3 4B                         │
                                      │ ▸ What was sent   (cloud answers only)   │
                                      └─────────────────────────────────────────┘
```

- Answer text uses the shared `AnswerText`, so `[n]` shows as clickable number pills ([launcher design](../launcher/design.md#citation-markers)).
- List 340 pt wide, day headers in caption caps (TODAY, YESTERDAY, OCT 7).
- "What was sent" is a disclosure group showing the payload in a monospaced, selectable text block with a caption: "This is exactly what left your Mac. Personal data was replaced with placeholders."
- Empty state: "No questions yet. Press ⌥Space to ask your files."
