# S8 · Pitch deck — Tasks

Legend: `[x]` done and verified · `[~]` done, not verified · `[ ]` not started. Owner in brackets.

- [x] **T1 Connect Canva.** _(Connected ~05:20.)_  _(Oct 10 ~04:50: Canva is enabled for the session but stuck at "pending"; the user chose the PPTX fallback meanwhile.)_ [user] Click Connect on the Canva connector and sign in. **Verify:** Claude can list the Canva tools.
- [x] **T2 Outline.** _(`deck-outline.md` v1.)_ [Claude] `deck-outline.md`: final text for slides 1–8 and A1–A4, sources, a speaker cue per slide. **Verify:** word limits met; every number traced to the report or `decisions.md`.
- [x] **T3 Build in Canva.** _(Built natively with Canva create-design from the outline; Canva rewrote slides 5, 7, 9–12, so Claude restored the outline wording, fixed dark-on-dark contrast, read every edited page back and checked thumbnails; user approved the save. Link in `deck-outline.md`.)_ Earlier fallback: _(Fallback used: editable PPTX built with pptxgenjs from the outline, `media/deck/gel-pitch.pptx` (+ `build.js`); validator passed; all 12 slides rendered and checked, overflow fixed on slides 5, 6, 8. User imports it into Canva (drag the .pptx onto canva.com) to restyle.)_ [Claude] Create the 16:9 design from the outline and [design.md](design.md) with the Canva connector. **Verify:** Claude reads back every page's text from Canva and it matches the outline.
- [ ] **T4 Review.** [user] Open the Canva link, note changes; Claude applies them. **Verify:** user approves.
- [~] **T5 Script cues.** _(8 `[SLIDE n]` cues in S4 `script.md`; deck added to its stage state. Timing to re-check in rehearsal.)_ [Claude] Add `[SLIDE n]` cues to S4 `script.md` and a deck line to S6 pre-flight. **Verify:** S4 timing still 4:15–4:40 on rehearsal.
- [ ] **T6 Freeze pass (~06:00).** [Claude] Remove proof points or claims for anything not verified. **Verify:** each claim maps to a passing QA case.
- [~] **T7 Export for offline.** _(`media/deck/gel-pitch.pdf` exported via LibreOffice; user still to open it full screen with Wi-Fi off.)_ [Claude via Canva export, or user] PDF + PPTX into `media/deck/`. **Verify:** user opens the PDF full screen with Wi-Fi off.

Done when: all [spec.md](spec.md) acceptance criteria hold.
