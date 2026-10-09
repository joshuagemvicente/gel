# F7 · Packs — Tasks

Legend: `[x]` done and verified · `[~]` built, not verified · `[ ]` not started. CLI: `cd Gel && export GEL_HOME=/tmp/gel-dev && CLI=build/Build/Products/Debug/gelcli`.

- [x] **T1 Pack format + bundled packs.** Files: `GelCore/PII/PIIDetector.swift`, `GelCore/Resources/pack_{core,hr,personal}.json`. **Verify:** unit tests `testPhilippineGovernmentIDs`, `testPersonalIDsAndMoney`, `testCardNeedsLuhn` pass (they load HR and Personal through `PackStore`).
- [x] **T2 Union of active packs.** **Verify:** `$CLI detect --packs hr "Passport P1234567A"` finds no passport; `$CLI detect --packs personal "Passport P1234567A"` finds `PASSPORT`.
- [ ] **T3 Custom pack test.** Unit test: write a pack JSON with a unique type into `$GEL_HOME/Packs/`, `PackStore().types(active: [id])` includes it. Files: `GelCoreTests/PackStoreTests.swift`. **Verify:** test passes.
- [x] **T4 Personal sample check.** **Verify:** `$CLI detect --packs personal --file "../demo-data/clipboard-samples/<passport-bank sample>.txt"` reports a passport number and a bank account.
- [ ] **T5 UI switching** (owned by [settings](../settings/spec.md), [app-shell](../app-shell/spec.md), [onboarding](../onboarding/spec.md)): toggles write `GelSettings.activePacks`; policy `requiredPacks` forced on and disabled. **Verify:** switch HR → Personal from the menu bar; Leak Guard flags the passport sample without restart.

Done when: all [spec.md](spec.md) acceptance criteria observed passing.
