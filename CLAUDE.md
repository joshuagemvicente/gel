# Gel

Gel is a native macOS app: a private AI layer that answers questions about your own files with citations and keeps personal data out of cloud AI. Built for the AppBuildersPH Hackathon 2026 (theme: Local AI).

## Workflow: spec first

Every iteration follows this loop, in order:

1. **Spec.** Write or update the feature's folder in `docs/features/<feature>/` (`role.md`, `context.md`, `spec.md`, `tasks.md`, plus `interfaces.md` or `design.md`). A new feature gets a new folder. Done when the acceptance criteria are concrete and checkable.
2. **Agree.** Ask the user to confirm the spec before writing code.
3. **Build.** Implement exactly what the spec says. A deviation you discover is logged in `docs/project/decisions.md` the moment you make it.
4. **Verify.** Run the acceptance criteria (tests, `gelcli`, or the app) and tick them in the feature's `tasks.md` only when observed passing.

## Docs

Start at `docs/README.md`: the layout, the reading order, and the feature table. Project-wide rules live in `docs/project/` (read `role.md` first every session); each feature's brief lives in `docs/features/<feature>/`.

## Build

The Xcode project is generated: edit `Gel/project.yml`, then run `xcodegen generate` in `Gel/`. Never hand-edit `Gel.xcodeproj`. Build, test and CLI commands are in `docs/project/conventions.md`.
