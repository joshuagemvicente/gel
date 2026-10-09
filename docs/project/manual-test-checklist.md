# Manual test checklist

For you to run by hand, so we share one understanding of how Gel behaves. Tick each box only when you saw the **Pass if** happen. When something differs, write it in the log at the bottom; that's a finding, even if it's small or just "felt slow" or "confusing".

`scenarios.md` IDs (B·I·A·E·Q) are in brackets so we can match your results to the automated ones in [test-scenarios.md](test-scenarios.md).

## 0 · Before you start

- [ ] Ollama is running: menu bar shows a llama icon, or `curl -s localhost:11434/api/version` prints a version.
- [ ] Models are installed: `ollama list` shows `qwen3:4b-instruct-2507-q4_K_M` and `bge-m3`.
- [ ] Gel is the latest build (I'll tell you when to relaunch: `pkill -x Gel; open Gel/build/Build/Products/Debug/Gel.app`).
- [ ] Demo files are at `demo-data/` (all synthetic; nothing real).
- [ ] Have Chrome open with chatgpt.com (logged in or not, the input box is enough).

**Tips for finding bugs:** do things in an unusual order, do them twice, do them fast, cancel halfway, switch apps in the middle, and watch for anything that looks wrong for even a second (flicker, wrong numbers, stale text).

## 1 · First run and the folder

- [ ] **Onboarding** [B1] — reset with `defaults write com.joshuagemvicente.gel onboardingDone -bool NO`, relaunch. Pick **Work: HR**, use `demo-data/HR Files`, wait. **Pass if:** progress counts up to 58, then Done; relaunching doesn't show onboarding again.
- [ ] **Library contents** [B11] — Library → All / PDF / Scans / DOCX, search "Santos". **Pass if:** 58 files total; Scans shows only `IMG_…jpg` and `Scan …pdf`; search narrows to Santos files.
- [ ] **New file appears** [I9] — copy any PDF into `demo-data/HR Files` while Gel runs. **Pass if:** it appears in Library within ~10 s. (Delete it afterwards.)
- [ ] **Folder disappears** [E2] — rename `demo-data/HR Files` to `HR Files x` for 15 s, then rename back. **Pass if:** Library keeps its files (after the next build: shows "Folder not found" while renamed) and nothing is lost after renaming back.

## 2 · Asking questions (launcher)

- [ ] **Demo question** [B2] — ⌥Space, type `Sino sa applicants ang may 5+ years sa payroll?`, Enter. **Pass if:** names Cruz, Santos and Reyes (no one else), Reyes = 7 years, chips `1 · CV - Patricia Anne Cruz p.1`, `… Santos …`, `… Resume_REYES p.2`, green **Local · Qwen3 4B** badge. Note how many seconds it takes.
- [ ] **Same question again** — **Pass if:** same answer, noticeably faster (prompt cache).
- [ ] **Single fact** [B6] — `Magkano ang expected salary ni Reyes?` **Pass if:** ₱45,000.00 with a citation.
- [ ] **English** [B7] — `Who has payroll experience?` **Pass if:** answer in English with citations.
- [ ] **No answer** [B5] — `Ano ang paboritong pagkain ni Reyes?` **Pass if:** exactly "I couldn't find that in your files.", no chips.
- [ ] **Counting** [E4] — `Ilan ang empleyado sa Operations?` **Note** whether the number seems right (there are 15 201 files). Report what it says.
- [ ] **Re-ask fast** [E1] — ask a long question, and while it's still streaming, replace it with a different question and press Enter. **Pass if:** the final answer has no sentences from the first question.
- [ ] **Typos** [E18] — `sino may payrol experiance`. Report whether it still finds the right people.
- [ ] **Esc and focus** [Q7] — in Chrome, ⌥Space, then Esc. **Pass if:** you can keep typing in Chrome immediately, and Gel's main window didn't jump in front. (Fixed in the next build; today it may fail.)
- [ ] **Open in Gel** — after an answer, click **Open in Gel**. **Pass if:** History opens on that question.

## 3 · Citations and the viewer

- [ ] **Text PDF citation** [B3] — click the Reyes chip. **Pass if:** main window → Library → `Resume_REYES.pdf`, footer says page 2 of 2, payroll section highlighted yellow.
- [ ] **Scan citation** [I7] — ask `Ano ang SSS number ni Carlo Velasco?` and click its chip. **Pass if:** a scan opens and the highlighted lines are the ones holding the answer (not shifted).
- [ ] **DOCX citation** [I8] — ask `Kailan ang start date ni Kristine Joy Reyes?` **Pass if:** the offer letter opens as text with the passage highlighted.
- [ ] **Check the answer yourself** — for any answer, read the highlighted passage. **Pass if:** the fact in the answer really is in the passage (this is how users trust a 4B model).

## 4 · Voice

- [ ] **First use** [I1] — ⌥Space, hold **right** ⌥, say the demo question, release. Allow the microphone prompt if it appears (then try once more). **Pass if:** the level meter moves while you talk, "Transcribing…" appears, then the transcript fills and the answer runs.
- [ ] **Taglish accuracy** — say 3 different Taglish questions. Note any words it gets wrong.
- [ ] **Tap without talking** [E14] — tap right ⌥ quickly. **Pass if:** nothing breaks; it returns to idle.
- [ ] **Left ⌥** — hold the **left** ⌥. **Pass if:** nothing records (only the right ⌥ is push-to-talk).

## 5 · Redaction

- [ ] **Three resumes** [B10] — Library → ⌘-click `Resume_REYES`, `Santos_Rodel_Resume`, `CV - Patricia Anne Cruz` → **Redact 3 files**. **Pass if:** the sheet scans each file, shows findings grouped by category with counts, and "AI check: on this Mac".
- [ ] **Untick one** [I5] — untick one name, then Redact. Open the output. **Pass if:** that name is still readable, everything else in the list is blacked out.
- [ ] **Really gone** — open a `_REDACTED.pdf` in Preview, press ⌘F and search for an SSS number from the original. **Pass if:** nothing found; you can't select text under the boxes.
- [ ] **Scan** [I6] — redact one `IMG_…jpg` from Scans. **Pass if:** boxes cover the ID numbers on the photo.
- [ ] **Twice** [E7] — redact the same file again. **Pass if:** a new `_REDACTED-2.pdf` appears; the first isn't overwritten.
- [ ] **DOCX** [E6] — redact `Offer_Letter_Reyes_Kristine.docx`. Open the `_REDACTED.txt`. **Pass if:** placeholders read like `[NAME_1]`, `[SALARY_1]`, not `[OTHER_1]`.
- [ ] **Redactions module** — open Redactions & Leak Guard. **Pass if:** every redaction is listed with counts; Open and Reveal work.

## 6 · Leak Guard and safe paste

- [ ] **Leak caught** [B8] — copy all text of `demo-data/clipboard-samples/employee_record.txt`, switch to Chrome. **Pass if:** top-right overlay "Gel caught a leak in Chrome — This would leak: 4 government ID numbers, 1 salary, …" within ~1 s.
- [ ] **Safe paste** [I2] — click into the chatgpt.com box, press ⌥⌘V. First time, grant Accessibility (System Settings → Privacy & Security → Accessibility → Gel), then press ⌥⌘V again. **Pass if:** the pasted text shows `[SSS_1]`, `[TIN_1]`, `[NAME_1]`… and no real ID numbers. **Don't send it.**
- [ ] **Clean text** [B9] — copy `clean_paragraph.txt`, switch to Chrome. **Pass if:** no overlay.
- [ ] **Ignore** — trigger the overlay, click Ignore, paste with ⌘V. **Pass if:** the raw text pastes (warn mode lets you choose).
- [ ] **Pause** — menu bar → Pause Leak Guard, copy the employee record, switch to Chrome. **Pass if:** no overlay. Un-pause after.
- [ ] **Home moved** [B12] — open Home. **Pass if:** "leaks caught" and "items kept on device" went up.
- [ ] **⌥⌘V in Finder** [Q6, known issue] — copy a file in Finder, open another folder, press ⌥⌘V. **Expected today:** Finder's "move" doesn't happen (Gel takes the shortcut). Confirm you see this.

## 7 · Packs (the consumer reveal)

- [ ] **Switch to Personal** [I4] — menu bar → Pack → Personal (on). Copy `passport_bank_snippet.txt`, switch to Chrome. **Pass if:** overlay mentions a government ID (the passport), bank accounts and a card.
- [ ] **HR only** — turn Personal off. Copy the same snippet → Chrome. **Pass if:** fewer findings (no passport, no card).

## 8 · Company policy and the DPO report

- [ ] **Install sample policy** [I12] — Settings → Policy → Install sample policy. **Pass if:** Settings shows "Managed by Bayanihan Outsourcing Corp." and the HR pack toggle is locked.
- [ ] **Block mode** — copy the employee record → Chrome. **Pass if:** overlay says "Blocked by Bayanihan Outsourcing Corp." (no Ignore), and a plain ⌘V pastes the redacted version.
- [ ] **Address + SSS on one line** [Q3] — copy this line, switch to Chrome: `Address: 147 Mabini St., Brgy. Sampaloc I, Dasmarinas City   SSS No: 04-4989449-2`. **Expected today:** summary says only "1 address" (bug). After the next build: "1 government ID number, 1 address" and blocked.
- [ ] **Export report** [I11] — Redactions → Export report. **Pass if:** a CSV and a PDF open in Finder; open both: counts only, **no names, ID numbers or file names**.
- [ ] **Remove policy** — Settings → Remove policy. **Pass if:** locks disappear.

## 9 · Offline and the cloud fallback

- [ ] **Wi-Fi off, full demo** [A1] — turn Wi-Fi off, then repeat sections 2 (demo question), 3 (Reyes citation), 5 (one redaction) and 4 (voice). **Pass if:** all work exactly as with Wi-Fi on.
- [ ] **Ollama stopped, no cloud** [A2] — `brew services stop ollama`, wait ~30 s, ask a question. **Pass if:** "Local model unavailable · Retry"; menu bar status says the same. Then `brew services start ollama`, click Retry. **Pass if:** it answers.
- [ ] **Set up the cloud fallback** [A5] — Settings → Cloud fallback: Base URL `https://dialagram.me/router/v1`, model `qwen-3.7-plus`, paste your API key → Save, then **Test connection**. **Pass if:** "✓ OK · n models". Try a wrong key once: **Pass if:** a clear error.
- [ ] **Fallback answers** [A3] — enable the fallback, stop Ollama, ask the demo question. **Pass if:** answer with a **Cloud · qwen-3.7-plus** badge. Open History → that answer → **What was sent**: **Pass if:** no real names or ID numbers, only `[NAME_1]`-style placeholders and "Source n" labels (after the next build; today file names still appear, Q2).
- [ ] **Back to local** [A4] — start Ollama, ask within 60 s (still Cloud), then after 60 s. **Pass if:** it switches back to Local.

## 10 · Try to break it

- [ ] **Scan with a text stamp** [Q1] — I'll put a test file at `demo-data/qa/Stamped_Scan.pdf` after the next build. Redact it. **Pass if:** the IDs on the photo get boxes (today: none, the output keeps every ID).
- [ ] **Ask while indexing** [A8] — Settings → Reindex now, immediately ask a question. **Pass if:** no crash; a sensible answer.
- [ ] **Huge copy** [Q8, known issue] — open a long document, select all, copy. **Note** whether the app or overlay lags.
- [ ] **Sleep and wake** [A11] — close the lid for a minute, open, ask. **Pass if:** it answers.
- [ ] **Second screen** [A12] — with a projector or external monitor, move the mouse to it and press ⌥Space. **Pass if:** the launcher opens on that screen.
- [ ] **Light and dark mode** — switch macOS appearance. **Pass if:** everything stays readable.
- [ ] **Anything else** — anything that surprised you.

## Findings log

Copy a row per finding (or just tell me in chat, and I'll add it).

| # | Section/ID | What I did | What I expected | What happened | Severity (blocker / annoying / cosmetic) |
| --- | --- | --- | --- | --- | --- |
| 1 | | | | | |
