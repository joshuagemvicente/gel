# S5 · Judge Q&A — Context

## Why it exists

Each finalist gets **3 minutes of judge Q&A** after the pitch. Ten judges, announced on the day. Q&A decides close calls on usefulness and on how real the local AI is (half the score).

## Where it sits

- **Upstream:** [S4 pitch-script](../pitch-script/spec.md) (what was claimed on stage); `docs/project/product.md`, `context.md`, `architecture.md`; measured numbers in `decisions.md`; each feature's `tasks.md`.
- **Downstream:** the user's live answers; any "show me" answer relies on the stage state from [S6](../demo-day-runsheet/spec.md).
- **Owner:** Claude writes `qa.md`; the user practices.

## Current state

Six starter questions with one-line answers already exist in `docs/project/demo-and-submission.md` → Likely judge questions; `qa.md` replaces and expands them.

## Facts and gotchas

- Likely skeptic angles: "isn't this Spotlight/Raycast + a regex?", "a 4B model hallucinates", "the cloud fallback breaks the promise", "regexes miss things / over-redact", "screenshots bypass the clipboard", "Mac-only: what about Windows/AMD?", "who pays?", "did you build this in 24 h / with AI?", "how is it different from enterprise DLP tools?".
- Sponsors: AMD (ask about Windows/AMD and NPUs), Cognition (AI-assisted dev: we used Claude Code, disclosed), WhiteCloak (UX and polish).
- Honest current limits (from the README): one Mac, one folder, one user; no Windows/AMD build; no sync; no legal certification.
- Gel's privacy invariants (`docs/project/role.md`) are the strongest answers: counts not content, redact before the cloud, keys in the Keychain.

## Related

[spec](spec.md) · [tasks](tasks.md) · [S4 pitch-script](../pitch-script/spec.md)
