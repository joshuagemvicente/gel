# M1 · Model provider and cloud fallback — Spec

**Goal:** local is the core AI. When the local model fails, LLM tasks continue on the user's OpenAI-compatible endpoint, which only ever receives redacted text, and the user can always see which one answered.

## What can fall back

| Component | Local (primary) | Cloud fallback |
| --- | --- | --- |
| Answer generation ([query-citations](../query-citations/spec.md)) | Ollama `qwen3:4b-instruct-2507-q4_K_M` | Yes, redacted input |
| Detection layer 3 ([detection-redaction](../detection-redaction/spec.md)) | same model | Yes, on text already redacted by layers 1–2 |
| Embeddings | Ollama `bge-m3` | No (the index must stay on one embedding model) |
| Speech-to-text ([voice](../voice/spec.md)) | WhisperKit | No (typing is the fallback) |
| OCR, name detection | Vision, NaturalLanguage | No (built into macOS) |

## Rules

- **One client, two base URLs:** `OpenAICompatibleClient` → `POST {base}/chat/completions` (SSE streaming or JSON), `GET {base}/models`. Local base = `{localBaseURL}/v1`; cloud base = the user's URL as entered (e.g. `https://<host>/v1`), `Authorization: Bearer <key>` when a key is set.
- **Triggers** (per request): connection refused/unreachable, HTTP error (incl. model not found), no first token within **15 s**, over **30 s** total with nothing streamed, empty response. Both timeouts are settings. **Cold start:** if the local model isn't loaded yet (`GET /api/ps` doesn't list it), the first-token limit for that request is 45 s, so loading the model isn't mistaken for a failure (D-029). Non-streaming JSON tasks (detection layer 3) have no first token, so they use a single 25 s local timeout and fall back on any local error (D-023).
- **No mid-answer switching:** if local already streamed tokens and then fails, keep the partial answer and report the error.
- **Cooldown:** after a fallback, stay on cloud for **60 s**, then try local again.
- **Health and warm-up:** `GET {local}/api/version` at launch and every 30 s; `POST /api/generate` with an empty prompt and `keep_alive: 60m` at launch, so the first question is fast.
- **Redaction gate (hard rule):** every cloud message goes through `Redactor.cloudSafe`; if that throws, no request is made (`LLMError.redactionFailed`). Citations are computed locally, so they always point at real local files.
- **No cloud configured / disabled by policy:** no fallback; the UI shows "Local model unavailable" with Retry.
- **Cloud timeouts:** 20 s first token, 60 s total.

## Configuration (Settings → Cloud fallback)

| Setting | Default | Storage |
| --- | --- | --- |
| Enable cloud fallback | off (only enable-able once URL + model are set) | UserDefaults |
| Base URL | empty (user supplies) | UserDefaults |
| API key | empty | Keychain (`com.joshuagemvicente.gel` / `cloudAPIKey`) |
| Model name | empty (e.g. a Claude model id on the user's gateway) | UserDefaults |
| First-token / total timeout | 15 s / 30 s | UserDefaults |
| Test connection | button → `GET {base}/models`, shows OK + model count or the error | — |

For terminal testing: `GEL_CLOUD_BASE_URL`, `GEL_CLOUD_API_KEY`, `GEL_CLOUD_MODEL` override settings and enable the fallback.

## Visibility

- Every answer shows a badge: **Local · <model>** or **Cloud · <model>**.
- A Cloud badge opens **What was sent**: the exact redacted payload (`AnswerResult.sentPayload`).
- The menu bar icon shows a cloud variant while the cooldown is active.
- Each cloud call logs a `cloud_call` event (character count only).

## Real names in cloud answers (E5)

The redaction gate returns its placeholder → value mapping (kept in memory on the Mac only). After a cloud answer arrives, Gel swaps placeholders like `[NAME_1]` back to the real values **locally** before showing and saving it. "What was sent" still shows the placeholder version, exactly as it left the Mac.

## Endpoint used for the hackathon

`https://dialagram.me/router/v1` (OpenAI-compatible, `Authorization: Bearer`; unauthenticated `GET /models` → 401). The API key is entered in Settings and stored in the Keychain only.

## Acceptance criteria

- [ ] With Ollama stopped and a cloud endpoint set, a question is answered with a Cloud badge in under 10 s.
- [ ] The cloud request body contains none of the ground-truth ID values or names from the cited sources (unit test with a stub server or by inspecting `sentPayload`).
- [ ] If the redactor throws, no request is sent (unit test with an injected failing redactor).
- [ ] With no cloud configured, stopping Ollama shows "Local model unavailable" and makes no network request.
- [ ] After Ollama returns, the first request after the 60 s cooldown runs locally.
- [ ] The API key never appears in logs, the database or the repo.
