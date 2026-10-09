# Demo download — Spec

Approved by the user on October 10, 2026: macOS demo ZIP, local file only.

## Contents

`dist/Gel-Demo-macOS-arm64.zip` extracts to a `Gel Demo/` folder containing:

- `Gel.app`: a Release build for Apple Silicon, minimum macOS 15, with its required embedded frameworks and app icon.
- `demo-data/HR Files`, `demo-data/Personal`, `demo-data/clipboard-samples`, the synthetic dataset README and ground truth. Exclude test-generated redactions, QA-only fixtures and hidden files.
- `START-HERE.md`: requirements, model installation, Gatekeeper/permission guidance and the typed-query → citation → redaction → Leak Guard demo path.
- `BUILD-INFO.json`: configuration, architecture, source revision/tree, build tools and the checks observed passing. Include no credentials, user preferences, local database or real documents.
- `THIRD-PARTY-NOTICES.txt`: license and notice text from the resolved Swift package dependencies.

Write a SHA-256 checksum beside the ZIP. Keep the ZIP and checksum out of Git. Leave GitHub visibility unchanged and do not upload the package.

## Acceptance criteria

- [x] Release `Gel` and `gelcli` builds succeed from the fixed snapshot; `GelCoreTests` pass (24 tests, Debug).
- [x] The snapshot's CLI indexes the synthetic HR folder, answers the demo question locally with citations, and detects/redacts synthetic IDs.
- [x] The extracted app has an arm64 executable, minimum macOS 15, app icon and embedded frameworks; strict code-signature verification succeeds.
- [x] The ZIP has the specified contents, excludes generated/private data, passes archive integrity checks and matches its SHA-256 checksum.
- [x] The setup guide states that models download separately and the demo is ad-hoc signed, not notarized. Record manual checks that have not run.
