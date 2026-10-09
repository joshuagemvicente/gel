# M1 · Model provider and cloud fallback — Context

## Why it exists

The theme demands local AI as the core ([context](../../project/context.md)); the user also wants answers to survive a local failure, using their own OpenAI-compatible endpoint (a Claude gateway they will supply). The design keeps both promises: local first, redacted cloud second, always visible ([decisions D-003–D-005](../../project/decisions.md)). Optional demo beat 6: stop Ollama, ask again, show the Cloud badge and "What was sent".

## Where it sits

- **Upstream:** Ollama on `localhost:11434`; the user's endpoint (Settings or env vars); the policy's `allowCloudFallback` ([policy-dpo-report](../policy-dpo-report/spec.md)).
- **Downstream:** [query-citations](../query-citations/spec.md) (`chat`), [detection-redaction](../detection-redaction/spec.md) (layer 3 via `completeJSON`), [launcher](../launcher/spec.md) and [history](../history/spec.md) (badge, "What was sent"), [settings](../settings/spec.md) (configuration, Test connection), [app-shell](../app-shell/spec.md) (warm-up, health check, menu bar state).

## Current state

Built:

- `Gel/GelCore/LLM/OpenAICompatibleClient.swift`: `ChatMessage`, `LLMError`, `OpenAICompatibleClient` (`stream`, `complete`, `listModels`).
- `Gel/GelCore/LLM/ModelRouter.swift`: `chat` (local stream with 8 s / 30 s timeouts, no mid-answer switch, 60 s cloud cooldown, redaction gate, 20 s / 60 s cloud timeouts, `cloud_call` event), `completeJSON`, `localIsHealthy`, `warmUp`, `stripThinking`, `cloudAllowedByPolicy`.
- `Gel/GelCore/Support/Settings.swift`: cloud settings (UserDefaults), API key (Keychain service `com.joshuagemvicente.gel`, account `cloudAPIKey`), env overrides, `cloudConfig`.

**Not built:** Settings UI and Test connection, Local/Cloud badge, "What was sent" view, menu bar cooldown state, the 30 s periodic health check, the unit tests for the gate and fallback. The fallback has not been exercised end to end (no endpoint yet).

## Facts and gotchas

- Measured: local model ~24 tokens/s warm; first request after a cold load ~34 s, longer than the 8 s first-token timeout, so `warmUp()` at launch matters ([D-009](../../project/decisions.md)).
- `qwen3:4b` (thinking build) ignored `think:false` and `/no_think`; `stripThinking` stays as a safety net for any model that emits `<think>`.
- **Embeddings have no fallback**: with Ollama stopped, `QueryEngine.search` fails before `chat` is called, so the cloud never gets the chance. See [query-citations tasks](../query-citations/tasks.md) T6.
- `completeJSON` sends `response_format: json_object` to Ollama but not to the cloud (gateways vary); the detector extracts the first `{…}` either way.
- The cloud base URL is used as entered; users must include `/v1` if their gateway needs it.
- Setting any `GEL_CLOUD_BASE_URL` env var also turns `cloudEnabled` on.

## Related

[spec](spec.md) · [tasks](tasks.md) · [interfaces](interfaces.md) · [settings](../settings/spec.md)
