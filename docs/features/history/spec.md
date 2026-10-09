# U7 · History — Spec

**Goal:** every past answer, with its sources and provider, one click away.

## Behaviour

- List from `Store.history()`, grouped by day (Today, Yesterday, then dates), newest first; a search field filters by question text.
- Row: time, question, provider badge.
- Selecting a row shows the full answer, its citation chips (open the Library viewer), the model name, and for cloud answers a **What was sent** disclosure with the exact redacted payload (`sentPayload`).
- "Open in Gel" from the launcher selects that answer here.

## Acceptance criteria

- [ ] Answers from the launcher and `gelcli ask` appear here grouped by day.
- [ ] A cloud answer's "What was sent" shows placeholders, not raw IDs.
