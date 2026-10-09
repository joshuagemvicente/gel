# S6 · Demo Day run sheet and QA — Context

## Why it exists

Technical execution is 20% of the score: "does it actually work, reliably enough for a live demonstration?" A solo presenter can't debug on stage, so the stage state, the offline proof and the recovery moves are decided in advance and tested by hand.

## Where it sits

- **Upstream:** [S4 pitch-script](../pitch-script/spec.md) (beats and order), demo beats in `docs/project/demo-and-submission.md`, each feature's `spec.md` acceptance criteria, [S3](../demo-video/spec.md) (backup video).
- **Downstream:** bug notes go to the build session (`docs/features/<feature>/tasks.md`); rehearsal times feed S4; failure modes feed S4 recovery lines and S5 answers.
- **Owner:** Claude writes `runsheet.md` and `qa-test-plan.md`; the user executes and records.

## Current state

Nothing written. Most UI features aren't built yet; test cases are written against the specs and finalized at the 06:00 freeze.

## Facts and gotchas

- Oct 10 schedule: arrive 12:00 · AV check 12:15 · opening 13:00 (finalists announced) · pitching 13:40–15:20 and 15:40–17:00 · awards 17:45. Wi-Fi, power, HDMI and USB-C are provided; demo on our own laptop.
- Machine: M2, 16 GB. Chat model + embeddings + WhisperKit ≈ 6–7 GB, so quit other heavy apps. The first Ollama call after idle is slow (model load): warm it right before going on stage.
- Ollama unloads idle models after ~5 min by default; check whether `OLLAMA_KEEP_ALIVE` is set (`docs/project/conventions.md`) or re-warm just before the pitch.
- Mirrored vs extended display changes where the top-center launcher appears; macOS may change resolution when the projector connects.
- Accessibility and Microphone permissions are tied to the app binary; a rebuild after the morning can drop them. Don't rebuild after the final QA pass.
- chatgpt.com must be loaded before Wi-Fi goes off, or the leak beat turns Wi-Fi back on first (script decides).
- Voice in a noisy hall: hold the mic close or fall back to typing the question (the script says when).
- No commits after 10:00: QA results written after the freeze stay local.

## Related

[spec](spec.md) · [tasks](tasks.md) · [S4 pitch-script](../pitch-script/spec.md) · [S3 demo-video](../demo-video/spec.md)
