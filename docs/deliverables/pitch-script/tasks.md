# S4 · Pitch script — Tasks

Legend: `[x]` done and verified · `[~]` done, not verified · `[ ]` not started. Owner in brackets.

- [ ] **T1 Draft.** [Claude] Write `script.md` per [spec](spec.md) against the planned beats. **Verify:** word counts per block within budget (± 10%).
- [ ] **T2 Voice pass.** [user → Claude] User reads it aloud once and flags lines that don't sound like them; Claude rewrites them. **Verify:** user agrees.
- [ ] **T3 Freeze pass (after 06:00).** [Claude] Drop or substitute beats for anything cut at the freeze; update recovery lines to match real failure modes seen in S6. **Verify:** every beat maps to a passing S6 test case.
- [ ] **T4 Cue card.** [Claude] One-page cue card at the end of `script.md`. **Verify:** fits one phone screen at readable size.
- [ ] **T5 Timed rehearsals (10:00–11:30).** [user] Two full runs with the real demo, timed; times written into S6's rehearsal log. **Verify:** both runs 4:15–4:40; if not, Claude trims.

Done when: all [spec.md](spec.md) acceptance criteria hold.
