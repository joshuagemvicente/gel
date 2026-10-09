# M1 · Model provider and cloud fallback — Tasks

Legend: `[x]` done and verified · `[~]` built, not verified · `[ ]` not started. CLI: `cd Gel && export GEL_HOME=/tmp/gel-dev && CLI=build/Build/Products/Debug/gelcli`.

- [x] **T1 OpenAI-compatible client.** Files: `GelCore/LLM/OpenAICompatibleClient.swift`. **Verify:** `$CLI ask "<demo question>"` streams tokens from Ollama (`provider: local`).
- [x] **T2 Local timeouts + warm-up.** Files: `GelCore/LLM/ModelRouter.swift`. **Verify:** after `ollama stop qwen3:4b-instruct-2507-q4_K_M` (unload), a cold `ask` without warm-up hits the 8 s first-token timeout; with `warmUp()` first it answers locally.
- [ ] **T3 Gate unit tests.** Add `GelCoreTests/ModelRouterTests.swift`: (a) a stub `URLProtocol` cloud endpoint receives a body with none of the ground-truth IDs from the prompt; (b) a throwing `redactForCloud` → `LLMError.redactionFailed` and zero requests. May need a small injection seam (spec-first: note it in [interfaces](interfaces.md) and [decisions](../../project/decisions.md)). **Verify:** tests pass.
- [x] **T4 No-cloud degraded path.** **Verify:** Ollama stopped, `GEL_CLOUD_*` unset → `$CLI ask` prints "Local model unavailable…" quickly and makes no external request.
- [ ] **T5 Cloud fallback end to end** (needs the user's endpoint). **Verify:** Ollama stopped, `GEL_CLOUD_*` exported, keyword-only search in place ([query-citations](../query-citations/tasks.md) T6) → `$CLI ask` prints `provider: cloud` and a `SENT TO CLOUD` block containing placeholders, not raw IDs; answer in < 10 s.
- [ ] **T6 Cooldown.** **Verify:** restart Ollama right after T5; asks within 60 s stay `cloud`, the first after 60 s is `local`.
- [ ] **T7 App surfaces** (owned by [settings](../settings/spec.md), [launcher](../launcher/spec.md), [history](../history/spec.md), [app-shell](../app-shell/spec.md)): settings + Test connection, badge, "What was sent", menu bar state, 30 s health check. **Verify:** each feature's own acceptance criteria.
- [ ] **T8 Secret hygiene.** **Verify:** `grep -r "<the key>" ~/Library/Preferences "$GEL_HOME" Gel/ docs/` finds nothing; `security find-generic-password -s com.joshuagemvicente.gel -a cloudAPIKey` finds it.

Done when: all [spec.md](spec.md) acceptance criteria observed passing.
