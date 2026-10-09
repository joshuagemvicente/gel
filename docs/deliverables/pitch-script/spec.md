# S4 · Pitch script — Spec

**Goal:** `docs/deliverables/pitch-script/script.md`: a timed, word-for-word 5-minute pitch with stage directions and recovery lines, built around the live demo.

## Structure (target times)

| Block | Start | Length | Earns | Content |
| --- | --- | --- | --- | --- |
| 1 Hook | 0:00 | 0:20 | Problem | A concrete HR moment: pasting 201 files into ChatGPT; the government IDs in them |
| 2 Problem and user | 0:20 | 0:25 | Problem 25% | Who (HR teams at PH SMEs/BPOs), the Data Privacy Act duty, why Spotlight/ChatGPT don't solve it |
| 3 Live demo: offline answer | 0:45 | 1:10 | Local AI 25%, Execution 20% | Wi-Fi off → voice question → cited answer → open the highlighted scan |
| 4 Live demo: leak catch | 1:55 | 1:00 | Innovation 15% | Copy record → chatgpt.com → overlay → ⌥⌘V placeholders → DPO counts |
| 5 Consumer reveal | 2:55 | 0:20 | Problem (reach) | Switch to Personal pack, catch passport + bank text |
| 6 Why local | 3:15 | 0:35 | Local AI 25% | Privacy, offline, free per-copy checking, speed; the cloud fallback only sees placeholders |
| 7 Business and what's next | 3:50 | 0:25 | Problem | B2B per-seat with policy + DPO reports; free Personal app; more packs |
| 8 Close | 4:15 | 0:15 | Demo quality, People's Choice | One-line memorable close + the People's Choice ask |
| Slack | 4:30 | 0:30 | — | absorbs demo latency |

## Content of `script.md`

- Each block: start time, word count, the exact words, and `[DO: …]` stage directions (keys pressed, windows clicked).
- **Recovery lines** under each demo block: what to say and do if it fails (e.g. model slow → "It's thinking on the laptop, no cloud" + wait ≤ 5 s; answer wrong → open the citation anyway; overlay missing → press ⌥⌘V manually; total failure → play the S3 backup video).
- A **cut version** that removes blocks 5 and 7 if the demo runs long (decision points at 2:55 and 3:50).
- A one-page **cue card** version (block names + first words + stage keys) for the laptop's second screen or a phone.

## Acceptance criteria

- [ ] Spoken at a natural pace, the full script runs 4:15–4:40 in two timed rehearsals (S6 records the times).
- [ ] Every demo beat in the script is ticked as passing in the latest S6 QA run.
- [ ] Every block has recovery lines; the backup video path is in the script.
- [ ] No claim of legal compliance, no unmeasured number, no feature not built.
- [ ] The close includes the People's Choice ask from S7.
- [ ] The user has read it aloud once and marked lines that don't sound like them; those are rewritten.
