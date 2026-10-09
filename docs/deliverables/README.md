# Gel deliverables

The non-code work the hackathon requires or rewards: the submission, the video and post, and everything for Demo Day. Same format and loop as `docs/features/`: each folder is written and agreed **before** its content is produced.

## Layout

```
docs/deliverables/<deliverable>/
  role.md      the expertise and rules for producing this deliverable
  context.md   why it exists, what it depends on, current state, gotchas
  spec.md      what the finished deliverable contains + acceptance criteria (the contract)
  tasks.md     ordered tasks, each with an owner and a verify step
  design.md    visual deliverables only: format, layout, copy style
```

Each deliverable's finished content goes in the file its `spec.md` names (for example `submission-form/answers.md`).

**Public vs private (user decision, Oct 9):** every spec file is public in the repo. The *outputs* of S4–S7 (`script.md`, `qa.md`, `runsheet.md`, `qa-test-plan.md`, `peoples-choice.md`, `closing-screen.html`) are git-ignored and stay on this Mac. S1–S3 outputs (`answers.md`, `post.md`, `cut-list.md`) are committed. Video files live in git-ignored `media/`. The demo video is **captions only: no voiceover, no music.**

## Deliverables

| ID | Folder | One line | Claude does | The user does | State |
| --- | --- | --- | --- | --- | --- |
| S1 | [submission-form](submission-form/) | Final answers for every Cerebral Valley field | Writes every answer, runs the truth pass | Pastes and submits once | spec drafted |
| S2 | [x-post](x-post/) | The required X video post | Writes the post text and alt text | Posts it, sends back the URL | spec drafted |
| S3 | [demo-video](demo-video/) | ~1-minute demo video | Writes the shot list, edits the raw footage, exports | Records the raw takes, approves the cut | spec drafted |
| S4 | [pitch-script](pitch-script/) | The 5-minute spoken pitch with the live demo | Writes the timed script | Rehearses and delivers it | spec drafted |
| S5 | [judge-qa](judge-qa/) | Likely judge questions with short answers | Writes questions and answers | Practices them | spec drafted |
| S6 | [demo-day-runsheet](demo-day-runsheet/) | Run sheet, Wi-Fi-off checklist, manual QA test plan | Writes the sheets and test cases | Runs every test by hand, records results | spec drafted |
| S7 | [peoples-choice](peoples-choice/) | Audience-vote plan: the ask, closing screen, hallway demo | Writes the copy and builds the closing screen | Delivers the ask, runs hallway demos | spec drafted |
| S8 | [demo-download](demo-download/) | Local downloadable macOS app ZIP with synthetic files and setup steps | Builds, verifies and packages the app | Installs models and runs the manual demo | ZIP verified; manual UI checks pending |

LinkedIn is out of scope: the user posts on X only.

## Hard rules for every deliverable

1. **Claude never posts, submits or publishes.** Claude produces text and files; the user posts on X, submits the form and makes the repo public. ([project role](../project/role.md))
2. **Only claim what is built and observed working.** Every feature named in a deliverable must be ticked `[x]` in its `docs/features/<feature>/tasks.md`, or be described as planned. A cut feature (roadmap → Cut order) is removed from every deliverable.
3. **Honest numbers.** Speeds, counts and timings come from `docs/project/decisions.md` measurements on the M2. None measured → no number. Sped-up video is labelled. Fake benchmarks can disqualify the team.
4. **Synthetic data only on screen.** Only `demo-data/` files appear; no real names, accounts, emails, API keys, notifications or browser profiles in any recording or screen.
5. **No commits after 10:00 AM, Oct 10.** Code freezes at the deadline. Anything changed after 10:00 (pitch edits, Q&A notes, QA results) stays uncommitted.
6. **Consistent facts.** Team **12M** (registered as "abububwebwe"), solo: Joshua Gem Vicente. Project **Gel**. Repo `github.com/joshuagemvicente/gel`. Model names exactly as in `docs/project/demo-and-submission.md` → Disclosures.

## Order and timeline (Sat Oct 10, PHT)

The pre-deadline items are a dependency chain: **video → X post → post URL → form → submit**.

| Time | What | Deliverable | Owner |
| --- | --- | --- | --- |
| Tonight | Drafts of S1, S2, S4, S5, S6, S7 from the agreed specs | all | Claude |
| 06:00 | Feature freeze for recording (roadmap Phase 4 ends) | S3 | user + build session |
| 06:00–06:30 | Record the raw takes from the shot list | S3 | user |
| 06:30–07:30 | Edit v1 → review → v2 export | S3 | Claude, user approves |
| 07:30–07:45 | Post on X with the video, copy the post URL | S2 | user |
| 07:45–08:30 | Truth pass on S1 and the README; make the repo public | S1 | Claude writes, user flips visibility |
| 08:30–09:15 | Submit once on Cerebral Valley (45 min buffer to 10:00) | S1 | user |
| **10:00** | **Deadline and code freeze** | — | — |
| 10:00–11:30 | Two timed pitch rehearsals + one full QA pass | S4, S5, S6 | user |
| 12:00 / 12:15 | Arrive at Cyberzone SM Makati / AV check | S6 | user |
| 13:00 | Finalists announced | — | — |
| 13:40–17:00 | Pitching; break 15:20–15:40 for hallway demos | S4, S5, S7 | user |

## Sources of truth

- Hackathon rules, judging, deadline: [project/context.md](../project/context.md)
- Product one-liner and why-local answer: [project/product.md](../project/product.md)
- Demo beats, disclosures, local-vs-internet table: [project/demo-and-submission.md](../project/demo-and-submission.md)
- What is actually built: each `docs/features/<feature>/tasks.md`
- Measured numbers: [project/decisions.md](../project/decisions.md)
