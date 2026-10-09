# S6 · Demo Day run sheet and QA — Spec

**Goal:** two files the user can run from a phone: `runsheet.md` (what to do, when, and how to recover) and `qa-test-plan.md` (manual test cases with a results log).

## `runsheet.md`

1. **Timeline, Oct 10:** submission morning → rehearsals → leave → arrive 12:00 → AV check 12:15 → waiting → on stage → after.
2. **Packing list:** laptop, charger, USB-C→HDMI adapter, headphones or a mic for voice in noise, phone with the cue card.
3. **AV check (12:15):** connect, mirror the display, check launcher size and position on the projector, the overlay is readable from the back, and audio isn't needed.
4. **Pre-flight (T-15 min before the pitch):** Do Not Disturb on, notifications off, heavy apps quit, Ollama running and warmed, Gel on pack HR with the sample policy, index ready, chatgpt.com loaded in Chrome (logged out), clipboard samples open in Finder, Wi-Fi state as the script needs, battery charged and plugged in, the backup video on the Desktop.
5. **Wi-Fi-off checklist:** turn Wi-Fi off from the menu bar, check the icon, confirm `curl -m 3 https://example.com` fails in Terminal (rehearsal only), Ethernet/iPhone hotspot not connected, then the core question still answers with a **Local** badge.
6. **Recovery playbook:** one row per failure: symptom → what to do on stage (≤ 10 s) → what to say. Includes: slow first answer, no answer, wrong citation, viewer doesn't open, overlay missing, ⌥⌘V does nothing (Accessibility), mic not hearing, app crash, projector problem, everything broken → backup video.
7. **Reset between runs:** how to return Gel, Chrome and the clipboard to the start state.

## `qa-test-plan.md`

- **Test cases:** one per demo beat plus setup and failure paths, each with ID, preconditions, steps, expected result, Pass/Fail, notes. At minimum:
  - QA-01 cold start: launch Gel, index present, menu bar icon shows.
  - QA-02 Wi-Fi-off proof.
  - QA-03 voice question → transcript correct.
  - QA-04 cited answer streams with the **Local** badge; names the right applicants.
  - QA-05 citation chip → highlighted page in the viewer.
  - QA-06 redact selected resumes → preview → burned-in PDF (text not selectable).
  - QA-07 leak overlay on chatgpt.com within 1 s with the right summary.
  - QA-08 ⌥⌘V pastes placeholders only.
  - QA-09 clean paragraph → no overlay.
  - QA-10 Personal pack catches the passport + bank sample.
  - QA-11 DPO export shows counts only.
  - QA-12 Ollama stopped → **Cloud** badge, "What was sent" shows placeholders (only if the fallback is configured).
  - QA-13 typed question works when voice fails.
  - QA-14 a full scripted run with a stopwatch.
- **Results log:** a table per run (run #, time, tester, result per case).
- **Rehearsal log:** run #, total time, where it ran long.
- **Bug note format:** `QA-xx · what I did · what I expected · what happened · how often (1/3) · screenshot path`.

## Acceptance criteria

- [ ] Every beat in the S4 script has at least one test case; QA-01–QA-14 exist (skip only those for cut features, marked "cut").
- [ ] Every test case is runnable by hand with no code reading: concrete steps and an observable expected result.
- [ ] The recovery playbook covers every failure seen in any QA run.
- [ ] The user has run the full plan twice with Wi-Fi off before 10:00 and once more before leaving; results logged.
- [ ] The last full run before the pitch has every in-scope case passing, or a recovery step agreed for each failing one.
