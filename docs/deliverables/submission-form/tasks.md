# S1 · Submission form — Tasks

Legend: `[x]` done and verified · `[~]` done, not verified · `[ ]` not started. Owner in brackets.

- [ ] **T1 Get the real field list.** _(Oct 9: the public event page has no form; the submit form needs a signed-in account, so this is the user's.)_ [user or Claude] Open the submit form on Cerebral Valley (logged in: user; public page: Claude can read it in the built-in browser) and record every field name, type (text/URL/file), limit and whether it's required in `answers.md` → Fields. **Verify:** the list matches the live form one to one.
- [~] **T2 Draft every answer.** _(v1 Oct 9 22:10, against the briefing's field list; waiting on T1 and the user's read.)_ [Claude] Write `answers.md` from the sources in [spec](spec.md); mark the video and X URL fields `<<pending S3/S2>>`. **Verify:** user reads it and agrees.
- [ ] **T3 Fix the README to match.** [Claude] Same model names (D-009), team 12M, no TBDs; the "Measured performance" table only holds measured rows. **Verify:** `grep -n "TBD\|TODO\|qwen3:4b\b" README.md` returns nothing that matters.
- [ ] **T4 Fill the links.** [user → Claude] User sends the S2 post URL (and video URL if separate); Claude fills them in. **Verify:** both open logged-out.
- [ ] **T5 Truth pass (~07:45).** [Claude] Re-read every `docs/features/*/tasks.md`; delete any claim about a feature not `[x]`; re-check numbers against `decisions.md`. **Verify:** a short "removed/changed" note at the bottom of `answers.md`.
- [ ] **T6 Make the repo public.** [user] `gh repo edit joshuagemvicente/app-hackathon --visibility public --accept-visibility-change-consequences`, or GitHub → Settings → Danger Zone. **Verify:** the repo opens in a logged-out window.
- [ ] **T7 Submit once (by 09:15).** [user] Paste field by field, re-read, submit. **Verify:** confirmation screen or email received; screenshot kept.

Done when: all [spec.md](spec.md) acceptance criteria hold and T7's confirmation exists.
