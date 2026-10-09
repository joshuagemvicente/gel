# Gel

Gel is a native macOS app: a private AI layer that answers questions about your own files with citations and keeps personal data out of cloud AI. Built for the AppBuildersPH Hackathon 2026 (theme: Local AI).

## Workflow: spec first

Every iteration follows this loop, in order:

1. **Spec.** Write or update the relevant file in `docs/specs/` (feature spec, `05-tasks.md`, `06-decisions.md`). Done when the acceptance criteria are concrete and checkable.
2. **Agree.** Ask the user to confirm the spec before writing code.
3. **Build.** Implement exactly what the spec says. A deviation you discover is logged in `06-decisions.md` the moment you make it.
4. **Verify.** Run the acceptance criteria (tests, `gelcli`, or the app) and tick them in `05-tasks.md` only when observed passing.

## Specs

Start at `docs/specs/README.md`. It gives the reading order and says which file answers which question (role, context, product, architecture, features, tasks, decisions, demo, conventions).

## Build

The Xcode project is generated: edit `Gel/project.yml`, then run `xcodegen generate` in `Gel/`. Never hand-edit `Gel.xcodeproj`. Build, test and CLI commands are in `docs/specs/08-conventions.md`.
