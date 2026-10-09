# S7 · People's Choice — Spec

**Goal:** everything the user needs to earn audience votes fairly: the ask, a closing screen, and a 30-second hallway demo.

## Deliverables

1. **The ask** (in `peoples-choice.md`, and copied into S4's close): ≤ 15 words, names team 12M and Gel, and points at the organizers' QR code. One alternative wording.
2. **Closing screen** (`closing-screen.html`): one full-screen page shown at the end of the pitch and left up during Q&A. Layout in [design.md](design.md). No network requests, no external fonts or scripts.
3. **Hallway demo** (in `peoples-choice.md`): a 30-second script for the 15:20 break: one sentence of setup, the leak catch on chatgpt.com, the ⌥⌘V reveal, one closing line with the ask. Includes the laptop state to keep ready between visitors.
4. **Talking points** (in `peoples-choice.md`): three one-line answers for the most common hallway questions ("does it need internet?", "can I use it?", "is my data sent anywhere?").

## Acceptance criteria

- [ ] The ask is ≤ 15 words and uses the team name exactly as the voting form shows it.
- [ ] `closing-screen.html` opens offline (Wi-Fi off) in Chrome full screen and is readable at 1280×720 and 1920×1080; it makes no network requests.
- [ ] The hallway demo runs in ≤ 30 s on the real app, timed by the user once.
- [ ] Nothing offers anything in exchange for votes; no custom voting QR.
