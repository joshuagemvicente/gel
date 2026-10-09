# U2 · Launcher — Design

## Layout (640 pt wide, top edge ~22% down the screen)

```
┌──────────────────────────────────────────────────────────────┐
│  ◌  Sino sa applicants ang may 5+ years sa payroll?      🎙   │  ← input, 52 pt tall, 17 pt text
├──────────────────────────────────────────────────────────────┤
│  3 applicants have 5+ years in payroll: Kristine Joy Reyes    │  ← answer, 14 pt, streams in
│  [1], Rodel Santos [2] and Patricia Anne Cruz [3].            │
│                                                              │
│  (1 · Resume_REYES p.2) (2 · Santos_Rodel_Resume p.1)  …      │  ← CitationChip row (wraps)
│                                          ( Local · qwen3 4B ) │  ← ProviderBadge, right-aligned
└──────────────────────────────────────────────────────────────┘
```

- Panel: `card` fill with 16 pt corner radius, soft shadow, hairline border; the answer area appears only after Enter.
- Leading glyph: `magnifyingglass`, replaced by a pulsing dot while recording and a small spinner-free shimmer while waiting.
- Mic glyph `mic` at the trailing edge; `mic.fill` in accent while recording, with a 5-bar level meter replacing the placeholder text.

## Citation markers

`[n]` markers in the answer text are drawn as **number pills**, never raw brackets:

```
3 applicants have 5+ years in payroll: Kristine Joy Reyes ⁽1⁾,
Rodel Santos ⁽2⁾ and Patricia Anne Cruz ⁽3⁾.      ⁽n⁾ = pill
```

- Pill: the number in 10 pt semibold, `accent` text on `accentSoft`, raised 2 pt, a thin space on each side. A run like `[1][2][3]` or `[1, 2, 3]` becomes adjacent pills `1 2 3`.
- Click opens the source exactly like chip n (same file, page and highlight). Hover shows the pointing hand.
- A number with no matching source (the model wrote `[8]` with 7 sources) is removed from the text.
- Same component in History (`AnswerText`), so both read the same.

## States

| State | Shows |
| --- | --- |
| Idle | Placeholder "Ask your files… hold ⌥ to talk" |
| Recording | Level meter + "Listening… release ⌥ to ask" |
| Transcribing | "Transcribing…" in textSecondary |
| Waiting | Answer area with a 2-line shimmer |
| Streaming / done | Answer text, then chips + badge |
| Not found | The exact "I couldn't find that in your files." in textSecondary, no chips |
| Error | One line in danger color + action: "Local model unavailable · Retry", "Nothing indexed yet · Choose a folder" |

## Copy

- Placeholder: `Ask your files… hold ⌥ to talk`
- Footer hint (idle, caption): `⏎ ask · esc close · ⌥ hold to talk`
- Open in Gel link (after an answer, caption): `Open in Gel`

## Motion

Appear: scale 0.98 → 1 and fade in over 150 ms. Answer area height animates as text streams (no jumps). Disappear: fade out over 100 ms.
