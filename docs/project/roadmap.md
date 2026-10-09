# Roadmap

Build order across features. Each line names a feature folder; its `tasks.md` holds the tasks, verify steps and status. Times are targets for Oct 9–10 (PHT).

## Phase 0 · Setup — done

Ollama + models pulled and timed; XcodeGen project builds (`GelCore`, `Gel`, `gelcli`, `GelCoreTests`); synthetic `demo-data/` generated.

## Phase 1 · Engine verification — next (target 11:30 PM)

Engine code exists; verify it end-to-end against `demo-data/` with `gelcli` before building UI on top.

1. [indexing](../features/indexing/tasks.md)
2. [query-citations](../features/query-citations/tasks.md) — record real timings in [decisions](decisions.md)
3. [detection-redaction](../features/detection-redaction/tasks.md)
4. [packs](../features/packs/tasks.md)
5. [model-fallback](../features/model-fallback/tasks.md) — the cloud parts wait for the user's endpoint
6. [policy-dpo-report](../features/policy-dpo-report/tasks.md) — engine parts only

## Phase 2 · App shell and core UI (target 1:30 AM)

1. [app-shell](../features/app-shell/tasks.md)
2. [settings](../features/settings/tasks.md)
3. [library-viewer](../features/library-viewer/tasks.md)
4. [launcher](../features/launcher/tasks.md)
5. [onboarding](../features/onboarding/tasks.md)

## Phase 3 · Voice, redaction, Leak Guard (target 3:30 AM)

1. [voice](../features/voice/tasks.md)
2. [redactions-module](../features/redactions-module/tasks.md) — redact sheet (T1–T2)
3. [leak-guard](../features/leak-guard/tasks.md)

**3:30 AM checkpoint:** behind schedule → apply the cut order.

## Phase 4 · Polish and B2B (target 6:00 AM)

1. [home](../features/home/tasks.md)
2. [history](../features/history/tasks.md)
3. [redactions-module](../features/redactions-module/tasks.md) — module view and export (T3–T4)
4. [policy-dpo-report](../features/policy-dpo-report/tasks.md) — locked settings, block mode
5. [app-shell](../features/app-shell/tasks.md) — theme pass, icon (T5–T6)
6. Rehearsal: the full [demo script](demo-and-submission.md) with Wi-Fi off; fallback run with Ollama stopped.

## Phase 5 · Submission (6:00–10:00 AM)

README (setup for judges incl. `brew install xcodegen ollama`, why local, local vs internet, disclosures) · demo video and post (user) · repo public (currently private) · submit once (user). Checklist: [demo-and-submission](demo-and-submission.md). Each of these has a spec, owner and timeline in [deliverables](../deliverables/README.md) (S1–S7); the chain is video → X post → URL → form → submit.

## Cut order (first cut first)

1. F6 Finder selection (already cut) · 2. history · 3. DPO report PDF (keep CSV) · 4. block mode (keep warn) · 5. redactions-module view (export moves to Settings) · 6. DOCX support · 7. automatic leak overlay (keep ⌥⌘V) · 8. voice (typed only).

**Never cut:** citations (F3), redaction (F4), the cloud redaction gate (M1), launcher (U2), Library viewer (U3), Personal pack (F7).

## Waiting on the user

Cloud endpoint (URL, key, model — entered in Settings, never in chat or the repo) · permission prompts on first run · demo video, post, making the repo public, submitting.
