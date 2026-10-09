# Test scenarios

Walk-through checklist for Gel, from basic to edge cases. Use it to decide what to fix before the 10:00 AM freeze. Each row links to the feature whose spec owns the behaviour.

**Status:** ✅ verified (observed passing) · 🟡 untested · ⚠️ known gap (the code doesn't handle it yet) · ❌ fails.
**Demo:** ★ = happens in the Demo Day script, so it must be ✅ before going on stage.

## Basic — the everyday path

| ID | Scenario | Steps | Expected | Status | Feature |
| --- | --- | --- | --- | --- | --- |
| B1 ★ | First launch | Fresh install → onboarding → Work: HR → Use demo-data/HR Files → Done | 58 files indexed; Library fills; onboarding never shows again | ✅ | onboarding |
| B2 ★ | Ask the demo question (typed) | ⌥Space → "Sino sa applicants ang may 5+ years sa payroll?" → Enter | Cruz, Santos, Reyes with chips; **Local** badge | ✅ | launcher, query-citations |
| B3 ★ | Open a citation | Click `5 · Resume_REYES p.2` | Main window → Library → page 2, payroll lines highlighted | ✅ | library-viewer |
| B4 | Close and reopen | Esc closes the launcher; close the main window; click the Dock icon | Launcher hides; Gel stays in the menu bar; window reopens | 🟡 | app-shell |
| B5 | Question with no answer | "Ano ang paboritong pagkain ni Reyes?" | Exactly "I couldn't find that in your files.", no chips | ✅ (CLI) | query-citations |
| B6 | Single-fact question | "Magkano ang expected salary ni Reyes?" | ₱45,000.00 with a citation to her resume | 🟡 | query-citations |
| B7 | English question | "Who has payroll experience?" | Answer in English with citations | 🟡 | query-citations |
| B8 ★ | Leak caught | Copy `employee_record.txt` → switch to Chrome | Overlay: "4 government ID numbers, 1 salary, 1 bank account…" | ✅ | leak-guard |
| B9 | Clean text, no alert | Copy `clean_paragraph.txt` → Chrome | No overlay | ✅ (CLI) | leak-guard |
| B10 ★ | Redact from Library | Select 3 resumes → Redact → Redact 3 files | 3 `_REDACTED.pdf` in `Redacted/`; listed in Redactions | 🟡 (you're testing) | redactions-module |
| B11 | Browse by type | Library filters All / PDF / Scans / DOCX; search "Santos" | Lists filter correctly | 🟡 | library-viewer |
| B12 | Home stats | After B2, B8, B10 open Home | Items kept, leaks caught, % local all move | 🟡 | home |

## Intermediate — real use, more variety

| ID | Scenario | Steps | Expected | Status | Feature |
| --- | --- | --- | --- | --- | --- |
| I1 ★ | Voice question | ⌥Space → hold right ⌥ → speak the demo question → release | Transcript fills, answer runs | 🟡 (you're testing) | voice |
| I2 ★ | Safe paste | Copy employee record → chatgpt.com → ⌥⌘V | Placeholders pasted (`[SSS_1]`…), no raw IDs | 🟡 (you're testing) | leak-guard |
| I3 | Safe paste without Accessibility | Same, before granting Accessibility | Clipboard replaced; overlay says "Press ⌘V to paste" | 🟡 | leak-guard |
| I4 ★ | Consumer reveal | Menu bar → Pack → Personal; copy `passport_bank_snippet.txt` → Chrome | Overlay names the passport, bank accounts and card | 🟡 (CLI ✅) | packs, leak-guard |
| I5 | Untick a finding | Redact sheet → untick one name → Redact | That name stays visible in the output; everything else blacked out | 🟡 | redactions-module |
| I6 | Redact a scan | Library → Scans → one JPG → Redact | Image-only PDF with boxes on the IDs | ✅ (CLI) | detection-redaction |
| I7 | Citation on a scan | Ask about a person whose 201 file is only a scan | Chip opens the scan with OCR lines highlighted | 🟡 | library-viewer |
| I8 | DOCX citation | Ask about the offer letter ("Kailan ang start date ni Reyes?") | Text view with the passage highlighted | 🟡 | library-viewer |
| I9 | New file appears | Copy a PDF into `HR Files` while Gel runs | Searchable within 10 s; Library shows it | 🟡 | indexing |
| I10 | History | Open History after a few questions | Grouped by day; selecting shows answer + chips | 🟡 | history |
| I11 ★ | DPO report | Redactions → Export report | CSV + PDF revealed; counts only | 🟡 | policy-dpo-report |
| I12 ★ | Sample policy + block | Settings → Install sample policy → copy employee record → Chrome | HR pack locked; overlay says "Blocked by Bayanihan Outsourcing Corp."; clipboard already redacted | 🟡 | policy-dpo-report, leak-guard |
| I13 | Menu bar status | Stop Ollama (`brew services stop ollama`) → wait 30 s → open menu | "Local model unavailable"; icon changes | 🟡 | app-shell |

## Advanced — fallback, offline, stress

| ID | Scenario | Steps | Expected | Status | Feature |
| --- | --- | --- | --- | --- | --- |
| A1 ★ | Wi-Fi off, whole demo | Turn Wi-Fi off → B2, B3, B10, I1 | Everything works; no network errors anywhere | 🟡 | all |
| A2 | Ollama down, no cloud | Stop Ollama → ask | "Local model unavailable · Retry"; Retry works after restart | ✅ (CLI) | model-fallback |
| A3 ★ | Ollama down, cloud set | Set your endpoint in Settings → stop Ollama → ask | Answer with **Cloud** badge; "What was sent" shows placeholders only | ⚠️ waiting on your endpoint | model-fallback |
| A4 | Cooldown back to local | Right after A3, restart Ollama; ask again within 60 s, then after | Cloud within 60 s, Local after | 🟡 | model-fallback |
| A5 | Test connection | Settings → wrong URL / wrong key / right values | Exact error text / OK · n models | 🟡 | settings |
| A6 | Cold start | Quit Ollama model (`keep_alive 0`) → ask | Waits for the model (≤ 45 s), no false fallback | ✅ (CLI, 13.5 s) | model-fallback |
| A7 | Redaction recall | `gelcli check ../demo-data/ground_truth.json` | All ID types 100%; names ≥ 70% | ✅ (names 73%) | detection-redaction |
| A8 | Ask while indexing | Reindex now → immediately ask | Answers from what's indexed so far; no crash | 🟡 | indexing, query-citations |
| A9 | Many questions in a row | Ask 10 different questions quickly | Each answer belongs to its own question | ⚠️ see E1 | launcher |
| A10 | Long session memory | Leave Gel running 1 h with Ollama loaded | Memory stays within ~7 GB total; no slowdown | 🟡 | app-shell |
| A11 | Sleep / wake | Close the lid 2 min → open → ask | Works; health check recovers | 🟡 | app-shell |
| A12 | Projector / second display | Mirror to an external screen → ⌥Space | Launcher appears on the screen with the mouse, readable | 🟡 | launcher |

## Edge cases — where things break

| ID | Scenario | What happens today | Status | Feature |
| --- | --- | --- | --- | --- |
| E1 · 🟡 fixed in code | Re-ask while an answer is still streaming | The old answer's tokens keep arriving and get appended to the new answer (the outer task is cancelled, the inner stream isn't) | ⚠️ bug | launcher, model-fallback |
| E2 · ✅ fixed | Indexed folder is missing (drive unplugged, folder renamed) | The next 5 s rescan prunes **every** document under that path; the Library empties | ⚠️ bug | indexing |
| E3 · 🟡 fixed in code | Change folder in Settings | Files from the old folder stay in the index and Library alongside the new ones | ⚠️ gap | settings, indexing |
| E4 · ✅ fixed (12 files) | Counting across many files ("Ilan ang empleyado sa Operations?") | Only the top 5 files reach the model, so counts over 15 201 files come out short | ⚠️ limitation | query-citations |
| E5 · 🟡 fixed in code (needs your API key to verify) | Cloud fallback answer about a person | The cloud only sees `[NAME_1]`, `[SSS_1]`, so the answer shows placeholders, not real names | ⚠️ by design (could swap them back locally) | model-fallback |
| E6 · ✅ fixed | Redact a DOCX | Output `.txt` labels every value `[OTHER_n]` instead of `[SSS_1]` etc. | ⚠️ known bug | detection-redaction |
| E7 · ✅ fixed | Redact the same file twice | The second run overwrites the first `_REDACTED.pdf` without asking | ⚠️ gap | detection-redaction |
| E8 · ✅ fixed | Password-protected or corrupt PDF in the folder | Skipped with a log line only; the user isn't told | ⚠️ gap | indexing |
| E9 | 200-page PDF | Indexes (slowly); answers fine; redaction holds all pages in memory | 🟡 | indexing, detection-redaction |
| E10 · ✅ fixed | A document containing "ignore previous instructions…" | The 4B model may follow it (prompt injection from a file) | 🟡 | query-citations |
| E11 | Copy a screenshot or a file (not text) | Leak Guard ignores non-text clipboard content | 🟡 by design | leak-guard |
| E12 · 🟡 fixed in code | Paste into Slack, Messenger desktop, Teams, Notes | Not watched by default (only browsers + ChatGPT/Claude apps) | ⚠️ scope choice | leak-guard |
| E13 | Copy personal data while Chrome is frontmost for a non-AI site | Overlay still appears (Leak Guard can't tell which website) | 🟡 by design | leak-guard |
| E14 | Very short voice press (< 0.3 s) or silence | Ignored, returns to idle | 🟡 | voice |
| E15 | Microphone denied | Mic glyph dims with the reason; typing still works | 🟡 | voice |
| E16 | ChatGPT desktop app installed | ⌥Space opens ChatGPT instead of Gel (shared hotkey) | ⚠️ known (demo uses chatgpt.com) | launcher |
| E17 | Rebuild the app (debug) | macOS may drop Gel's Accessibility trust; safe paste needs re-granting | ⚠️ dev-only | settings |
| E18 | Question typed with typos ("payrol", "aplicants") | Keyword search misses; vector search may still help | 🟡 | query-citations |
| E19 | Policy file with invalid JSON | Treated as "not managed" silently | ⚠️ gap | policy-dpo-report |
| E20 | Same person's ID appears in clipboard twice | One placeholder reused (`[SSS_1]` twice); summary counts both | ✅ (unit test) | detection-redaction |

## QA findings (found by the testing session, Oct 9 ~10:30 PM)

Each row was reproduced with a private build (`-derivedDataPath` outside the repo) and a separate `GEL_HOME`, unless marked "from code". ❌ = observed failing.

| ID | Scenario | Steps to reproduce | What happens today | Status | Feature |
| --- | --- | --- | --- | --- | --- |
| Q1 | Scanned PDF that also has a small text layer (e.g. a "Scanned with CamScanner" stamp, common on phone scans) | Make a PDF with the image `demo-data/HR Files/Scans/IMG_20260912_093415.jpg` as the page plus one 7 pt line "Scanned with CamScanner" (reportlab) → `gelcli redact <that.pdf>` → `gelcli detect --file Redacted/<that>_REDACTED.pdf` | Redact reports `0 finding(s)`; the `_REDACTED.pdf` has no boxes, and OCR of it still shows the SSS, TIN, PhilHealth, Pag-IBIG, salary, bank account, address, phones and email. The page also isn't searchable. Cause: a page with ≥ 20 text-layer chars is treated as text and never OCR'd (`TextExtraction.swift:41`, `Redactor.swift:96`) | ✅ fixed (D-043): stamped scan now 13 findings; redacted output OCR shows 1 name fragment, no IDs | indexing, detection-redaction |
| Q2 | Cloud gate leaks names | Build the exact cloud messages for the demo question (`QueryEngine.systemPrompt()` + `userPrompt(question:sources:)` → `Redactor.cloudSafe` on each) and compare with `ground_truth.json` | 12 ground-truth names survive, mainly from **file names** in the prompt (`[2] Santos_Rodel_Resume.pdf`, `[3] 201_BOC-2023-0392_Flores_Patricia.pdf`, `[5] Resume_REYES.pdf`) and "Surname, First" order (`ZAMORA, Christian B.`, `Javier, Liza M.`). A question about Carlo Velasco's dependents leaks 14 values (spouse/children names + 3 birth dates). Fails the model-fallback acceptance "the cloud request body contains no … names" | ✅ improved (D-044): `gelcli payload` for the demo question → 1 ground-truth value left (a lone first name "LIZA"), no file names | model-fallback, detection-redaction |
| Q3 | Address and an ID on the same line | `gelcli detect "Address: 147 Mabini St., Brgy. Sampaloc I, Dasmarinas City   SSS No: 04-4989449-2"` | One finding, "1 address": the `ADDRESS` pattern (`pack_core.json`) runs to the end of the line and `merge` drops the SSS. With the sample policy (government ID = block, address = warn) that SSS is only **warned**, so it can be pasted raw via Ignore; the overlay summary and DPO counts are also wrong | ✅ fixed: now "1 government ID number, 1 address" | detection-redaction, policy-dpo-report |
| Q4 · known issue (D-043) | Fast layers on a scanned 201 form (what Leak Guard and the cloud gate use) | `gelcli detect --packs hr,personal --file "demo-data/HR Files/Scans/IMG_20260912_093415.jpg"` | Misses the employee's name (VELASCO / CARLO / MARQUEZ), all 3 dependents and all 4 birth dates (labels and values are on separate OCR lines); tags the label "FIRST NAME" as a NAME. Plain sentence "Si Liza Velasco ay ipinanganak noong 02/06/1989." → 0 findings. File redaction with layer 3 is fine (output OCR clean) | ❌ | detection-redaction, leak-guard |
| Q5 | Judge follows the README setup | README says `ollama pull qwen3:4b`; the app's default model is `qwen3:4b-instruct-2507-q4_K_M` (D-009) | The chat model is missing, asks fail, yet the menu says "Local ✓" because `localIsHealthy()` only checks `/api/version`, not that the model is installed (`/api/tags`). README pull line is being fixed; the health check still needs to look for the model | 🟡 fixed in code (`/api/tags`), verify in the app | model-fallback, app-shell |
| Q6 · known issue (D-043) | ⌥⌘V in Finder (from code) | Copy files in Finder → ⌥⌘V ("Move Item Here") | `KeyboardShortcuts` registers ⌥⌘V globally, so Finder's move never fires; `safePaste()` reads the clipboard's string (the file names), replaces the clipboard with that text and sends ⌘V, so the copied files are lost from the clipboard | ⚠️ from code | leak-guard |
| Q7 | ⌥Space while another app is in front (from code) | With the main window open, work in Chrome → ⌥Space → Esc | `LauncherController.show()` calls `NSApp.activate(ignoringOtherApps:)`, which brings Gel's main window in front of Chrome; after Esc, focus stays in Gel instead of returning to Chrome (affects demo beat 4) | 🟡 fixed in code (no activation on show), verify by eye | launcher |
| Q8 · known issue (D-043) | Large copy | Copy ~38,000 characters (e.g. select-all in a long document) | `detectFast` runs on the main thread on every clipboard change: 2.3 s for 38k chars, 0.25–0.45 s for the 300–400-char samples (CLI timing, includes first-call warm-up). Spec target < 100 ms; a large copy can stall the UI | ⚠️ | leak-guard |
| Q9 | Single-fact question about one field (B6) | `gelcli ask "Magkano ang expected salary ni Reyes?"` (also fails in English) | Says the expected salary "is not explicitly stated". `Resume_REYES.pdf` does contain "Expected Salary : ₱45,000.00", but with 2 passages per file, the passages sent are her header and work history, not the chunk with the salary. `gelcli search` shows the resume ranked [2] with the wrong two passages | ❌ | query-citations |
| Q10 | Local model falsely "unavailable" when Ollama is busy | Model loaded (`/api/ps`), another client using Ollama at the same time (here: the build session) → `gelcli ask "Magkano ang expected salary ni Reyes?"` | 3 of 5 runs failed with "Local model unavailable. Start Ollama…" while Ollama was up and the model loaded; successful runs took ~22 s in total. The 15 s first-token limit is hit when requests queue. In the app the same can happen when a layer-3 redaction runs during a question. Without a cloud endpoint the user sees an error that tells them to start Ollama, which is already running | ⚠️ | model-fallback |
| Q11 | Address followed by a birth date on the same line | `gelcli detect "Address: 147 Mabini St., Dasmarinas City, Cavite Birthday: 02/06/1989"` | One finding, "1 address", which swallows the birth date. The Q3 fix stops the address only at a double space or an ID/contact label, not at "Birthday"/"DOB"/"Date of Birth". Low impact (birth date is warn-only in the sample policy), but the summary and DPO counts miss it | ⚠️ | detection-redaction |

**Re-test, 11:10 PM** (testing session, private build of the working tree, fresh `GEL_HOME`, 14 + 10 + 4 unit tests pass):
- **Q1** ✅ confirmed: stamped scan → 27 findings; OCR of the redacted output finds 1 name fragment, no IDs.
- **Q2** 🟡 partly: demo question → 1 value left ("LIZA"), no file names. `gelcli payload "Sino ang mga dependents ni Carlo Velasco at kailan sila ipinanganak?" --gt demo-data/ground_truth.json` still sends **3 birth dates** (02/06/1989, 06/30/2016, 11/06/2014). Same root as Q4 (unlabelled dates on the scanned form).
- **Q3** ✅ confirmed for IDs (double space and single space before "SSS"); see Q11 for birth dates.
- **Q5, Q7**: code read, both look right (`missingLocalModels()` checks `/api/tags` incl. `:latest`; the launcher no longer calls `NSApp.activate`). Still need the eye check in the app.
- **Q9** ❌ unchanged.
- **Q10** ⚠️ recurred once in 4 questions ("Kailan ang start date ni Reyes?" failed, then answered in 1.4 s on retry).
- **D-049 (English answers)**: a system-prompt rule made the demo answer add the non-matching Flores with chip [3] and repeat the list; moved to "Answer in English." after the question. Verified: demo question → Cruz, Santos, Reyes (7 years) only, in English; not-found → exact line; "Kailan ang start date ni Reyes?" → "November 3, 2026 [1]".

## How we decide

For each ⚠️ row, pick one: **fix now** (spec it, build it), **demo-avoid** (keep it out of the script), or **post-hackathon** (log it in `decisions.md`).
