# Conventions

## Commands (run from `Gel/`)

```sh
xcodegen generate                                  # after any change to project.yml or adding/removing files (Gel.xcodeproj is git-ignored)
xcodebuild -project Gel.xcodeproj -scheme gelcli -derivedDataPath build -quiet build
xcodebuild -project Gel.xcodeproj -scheme Gel    -derivedDataPath build -quiet build
xcodebuild -project Gel.xcodeproj -scheme Gel    -derivedDataPath build test -only-testing:GelCoreTests
open build/Build/Products/Debug/Gel.app            # run the app
```

`gelcli` (use a scratch `GEL_HOME` so terminal runs don't touch the app's index):

```sh
export GEL_HOME=/tmp/gel-dev
CLI=build/Build/Products/Debug/gelcli
$CLI index "../demo-data/HR Files"
$CLI search "payroll specialist"
$CLI ask "Sino sa applicants ang may 5+ years sa payroll?"
$CLI detect --packs hr,personal --file "../demo-data/clipboard-samples/<file>.txt"
$CLI detect --full "<text>"
$CLI redact "../demo-data/HR Files/Scans/<file>.jpg"
$CLI stats
```

Regenerate demo data: `scripts/.venv/bin/python scripts/generate_demo_data.py` (from the repo root).

## Environment variables

| Variable | Effect |
| --- | --- |
| `GEL_HOME` | Overrides `Application Support/Gel` (database, policy, packs, reports) |
| `GEL_FOLDER` | Overrides the indexed folders; several paths separated by `:` |
| `GEL_CLOUD_BASE_URL`, `GEL_CLOUD_API_KEY`, `GEL_CLOUD_MODEL` | Configure and enable the cloud fallback for testing. Set them in your shell only; never commit them |

## Code style

- Match the surrounding code: small types, `public` API in `GelCore`, doc comments only where the *why* isn't obvious (one or two lines).
- Engine logic goes in `GelCore` (testable, no SwiftUI); UI goes in the `Gel` target.
- Text offsets are UTF-16 (`NSString`/`NSRange`) everywhere, to match PDFKit.
- New detection behaviour = pack JSON first; Swift only when a pattern can't express it.
- Every engine change that can be unit-tested gets a test in `GelCoreTests`; everything else gets a `gelcli` check written into the task's verify step.
- User-facing copy: short, plain, Taglish where it helps; categories use the summary nouns in F4.

## Git

- Commit only when the user asks. Never commit secrets, `build/`, `scripts/.venv/`, or `*.xcuserstate`.
- The repo must be public before 10:00 AM Oct 10; nothing committed after the deadline counts.
