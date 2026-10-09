# S1 · Submission form — Spec

**Goal:** a single file, `docs/deliverables/submission-form/answers.md`, holding the final pasteable answer for every field of the Cerebral Valley form, true as of the moment of submission.

## Content

One section per form field, in the form's order, each with the field name as the heading and the answer in a plain-text block ready to paste:

| Field | Content rule |
| --- | --- |
| Project name | `Gel` |
| Short description | One or two sentences: what it is, who it's for, the local angle. Derived from `product.md` → One line. Within the form's limit. |
| Team name / members | `12M` · Joshua Gem Vicente (solo), exactly as on the official list |
| GitHub repository | `https://github.com/joshuagemvicente/gel` (public for submission) |
| Demo video | The S3 file or URL, per the form's field type |
| X video URL | The URL the user sends back after posting S2 |
| What runs locally | Bullet list of the local AI tasks actually built (STT, OCR, embeddings, search, LLM answers, detection, redaction, Leak Guard) |
| What requires internet | First-time model downloads; the optional, redacted, off-by-default cloud fallback; nothing else |
| Models used | Exact names and sources (Qwen3 4B Instruct 2507 Q4_K_M via Ollama, BGE-M3, Whisper large-v3 turbo via WhisperKit), plus "cloud fallback: user-configured" |
| Technologies and frameworks | From Disclosures in `demo-and-submission.md` |
| APIs and cloud services | User-supplied OpenAI-compatible endpoint, fallback only, redacted text only |
| Existing code and assets | None; demo data generated; OSS libraries as dependencies |
| AI development tools | Claude Code |
| Why local | 80–150 words: the four reasons from `product.md`, the Data Privacy Act, and "the cloud only ever sees redacted text" |
| Any other field the form has | Answered from the same sources; flagged in the file if unclear |

A **pre-submit checklist** at the top of the file (repo public, X URL filled, video link opens logged-out, truth pass done, names match the official list).

## Acceptance criteria

- [ ] Every field on the live form has an answer in `answers.md`, in the form's order, within its limit.
- [ ] No answer contains "TBD", "TODO", placeholders or Markdown the form doesn't render.
- [ ] Every feature mentioned is `[x]` in its `tasks.md` at truth-pass time; no cut feature is mentioned.
- [ ] Every number in any answer appears in `docs/project/decisions.md` as measured; otherwise there is no number.
- [ ] Model names, team name and repo URL match the README exactly.
- [ ] The repo URL and the video/post links open in a logged-out browser window.
