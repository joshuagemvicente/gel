# Context

## The hackathon

- **Event:** AppBuildersPH Hackathon 2026. Build Day Fri Oct 9 (remote, building from 2:30 PM, overnight). Demo Day Sat Oct 10, Cyberzone, SM Makati.
- **Submission deadline:** **10:00 AM, Oct 10 (PHT). No extensions. One submission per team, no edits after.** The GitHub repo must be public by then; code freezes at the deadline and judges read the repo as of 10:00 AM.
- **Team:** solo developer (the user), on the official participant list.
- **Demo Day:** finalists announced 1:00 PM. 5 minutes live pitch and demo + 3 minutes judge Q&A. Someone must present in person. Wi-Fi, power, HDMI and USB-C available; demo on our own laptop.
- **Prizes in play:** Grand Champion (₱50,000), WhiteCloak Award (polish and UX), People's Choice. Not targeting the Cognition/Devin award.

## Theme: Local AI

"Useful AI experiences where meaningful AI computation happens on the user's device, rather than depending entirely on cloud inference." The challenge: **build an AI product that remains genuinely useful when the cloud disappears.** Cloud APIs are allowed only as secondary components.

Every submission must answer: **"Why does this product benefit from running AI locally?"**

## Rules that shape the build

- Substantially built during the hackathon; existing code and assets disclosed.
- A meaningful part of AI inference executes locally; core functionality works without a cloud AI API.
- Disclose every model, framework, API, cloud service and AI development tool (we use Claude Code).
- Results can be disputed for a pre-existing project, outside help, or **fake benchmarks**.
- The app need not be deployed if the repo has instructions for judges to recreate it.

## Judging

| Criterion | Weight | What earns it here |
| --- | --- | --- |
| Problem & usefulness | 25% | HR teams with a legal duty (Data Privacy Act, DPO); the same engine reaches consumers |
| Local AI implementation | 25% | Speech, embeddings, LLM and OCR on-device; cloud only as a redacted fallback |
| Technical execution | 20% | The demo chain works live, offline, reliably |
| Innovation | 15% | A private AI layer between people and cloud AI; leak catch at the clipboard |
| Product & demo quality | 15% | Native launcher feel, warm-minimal main window |

## Submission checklist (required fields)

Project name, short description, team members, public GitHub repo, ~1-minute demo video, X/LinkedIn video post tagging Devin/Cognition with #AppBuildersPH, what runs locally, what needs internet, models, frameworks, APIs/cloud services, existing code/assets, AI dev tools, and the why-local answer. Details: `07-demo-and-submission.md`.

## The machine

- MacBook with Apple **M2, 16 GB RAM**, **macOS 15.8** (Sequoia), Xcode 26.3, Swift 6.2, Homebrew, Python 3.14.
- macOS 15.8 means **Apple's Foundation Models framework is unavailable** (it needs macOS 26). Local LLMs run through Ollama.
- Ollama 0.34.4 with `qwen3:4b-instruct-2507-q4_K_M` (~24 tokens/s measured) and `bge-m3` (1024-dim embeddings).
- Memory budget: chat model + embeddings + WhisperKit ≈ 6–7 GB. Close other heavy apps for the demo.

## Legal backdrop

The Philippine **Data Privacy Act of 2012 (RA 10173)** covers government ID numbers, salaries, addresses and health data, and requires organizations processing personal data to appoint a **Data Protection Officer (DPO)**. Gel's B2B value is preventing leaks to AI tools and producing counts-only evidence for the DPO.
