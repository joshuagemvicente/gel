# S6 · Demo Day run sheet and QA — Tasks

Legend: `[x]` done and verified · `[~]` done, not verified · `[ ]` not started. Owner in brackets.

- [ ] **T1 Draft both files.** [Claude] `runsheet.md` and `qa-test-plan.md` per [spec](spec.md), written against the feature specs. **Verify:** user reads them on their phone and finds every step clear.
- [ ] **T2 Freeze pass (~06:00).** [Claude] Mark cases for cut features "cut"; align steps with the actual UI (button names, shortcuts). **Verify:** every step matches what's on screen (user spot-checks 3 cases).
- [ ] **T3 QA run 1 (before recording, ~05:30–06:00).** [user] Run QA-01–QA-13 with Wi-Fi off; log results; file bug notes. **Verify:** results table filled.
- [ ] **T4 Bug hand-off.** [Claude] Turn failed cases into tasks in the matching `docs/features/<feature>/tasks.md` for the build session. **Verify:** each failure has a task or an agreed workaround.
- [ ] **T5 QA run 2 + rehearsal (10:00–11:30).** [user] Full run with Wi-Fi off plus QA-14 with a stopwatch, twice. **Verify:** results and times logged; S4 trimmed if over 4:40.
- [ ] **T6 Recovery playbook final.** [Claude] Add every failure seen in runs 1–2. **Verify:** user agrees each recovery is doable in ≤ 10 s.
- [ ] **T7 Day-of execution.** [user] AV check at 12:15, pre-flight at T-15. **Verify:** checklists ticked on the phone.

Done when: all [spec.md](spec.md) acceptance criteria hold.
