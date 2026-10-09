# Gel docs

The single source of truth for what Gel is and how to build it. **Spec first:** a feature's folder is written and agreed before its code is.

## Layout

```
docs/
  project/                 applies to the whole project
    role.md                who you are, hard rules, working loop — read first, every session
    context.md             the hackathon: rules, judging, deadline, machine
    product.md             what Gel is, users, packs, B2B/B2C, the why-local answer
    architecture.md        targets, folder map, data flow, storage, model routing, demo data
    roadmap.md             build order by phase, cut order, what's waiting on the user
    decisions.md           decision log, including every deviation from a spec
    demo-and-submission.md Demo Day script, judge Q&A, submission checklist, disclosures
    conventions.md         build/test/CLI commands, env vars, code style, git
    test-scenarios.md      basic → edge-case walk-through with status; decides what to fix next
    manual-test-checklist.md  hands-on checklist for the user: steps, pass criteria, findings log
  features/<feature>/      one folder per feature
    role.md                the expertise and rules for building this feature
    context.md             why it exists, where it sits, current state in code, gotchas
    spec.md                behaviour + acceptance criteria (the contract)
    tasks.md               ordered tasks with verify steps and status
    interfaces.md          engine features: the public GelCore API
    design.md              UI features: layout, states, copy
  deliverables/<item>/     non-code hackathon work: submission, video, X post, pitch, Q&A, run sheet, People's Choice
                           same files (role, context, spec, tasks, design for visual items); index: deliverables/README.md
```

## Building a feature

1. Read `project/role.md`, then the feature's `role.md` → `context.md` → `spec.md` → `interfaces.md`/`design.md`.
2. Work through its `tasks.md` in order; tick a task only after its **Verify** step passed.
3. The feature is done when every acceptance criterion in its `spec.md` was observed passing.
4. A new feature gets a new folder with all of the files above before any code.

## Features

| ID | Folder | One line | State |
| --- | --- | --- | --- |
| F1 | [indexing](features/indexing/) | Extract, OCR, chunk, embed and store the chosen folder | engine built |
| F2 | [voice](features/voice/) | Hold-to-talk Taglish transcription (WhisperKit) | not started |
| F3 | [query-citations](features/query-citations/) | Hybrid search and a cited answer | engine built |
| F4 | [detection-redaction](features/detection-redaction/) | Three-layer personal-data detection, placeholders, burned-in PDFs | engine built |
| F5 | [leak-guard](features/leak-guard/) | Clipboard watcher, leak overlay, safe paste | detection built |
| F7 | [packs](features/packs/) | Configurable detection packs (HR, Personal) | engine built |
| F8 | [policy-dpo-report](features/policy-dpo-report/) | Team policy and counts-only DPO report | engine built |
| M1 | [model-fallback](features/model-fallback/) | Local-first LLM routing with a redacted cloud fallback | engine built |
| U1 | [app-shell](features/app-shell/) | Dock app, menu bar, launch services, shared look | not started |
| U2 | [launcher](features/launcher/) | ⌥Space panel, streamed cited answers | not started |
| U3 | [library-viewer](features/library-viewer/) | File list, PDF viewer, citation highlights | not started |
| U4 | [settings](features/settings/) | Folder, packs, models, cloud fallback, permissions, policy | not started |
| U5 | [onboarding](features/onboarding/) | First run: pack choice, folder, indexing | not started |
| U6 | [home](features/home/) | Privacy stats and today's activity | not started |
| U7 | [history](features/history/) | Past answers and "What was sent" | not started |
| U8 | [redactions-module](features/redactions-module/) | Redact flow, Leak Guard log, DPO export | not started |
| U9 | [polish](features/polish/) | App icon, brand mark, motion system, per-screen polish | built, partly verified |
| U10 | [multi-folder](features/multi-folder/) | Index a list of folders chosen in Settings, not just one | built, mostly verified |

F6 (Finder selection) was cut; see `project/decisions.md` D-007.

The human-facing planning doc with diagrams is the Claude Doc "Gel — Hackathon Spec" (https://claude.ai/code/artifact/5348f9fe-3344-441a-a5fb-87a8cd00c9f6). Where it and these files disagree, these files win.
