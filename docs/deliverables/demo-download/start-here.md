# Gel demo

Gel answers questions about your files on your Mac, opens cited passages and redacts personal data. This package includes only synthetic sample documents.

## Requirements

- Apple Silicon Mac (M1 or newer), macOS 15 or later. Recommended: 16 GB RAM and about 8 GB free for models and the index.
- Internet for the first model downloads. After setup, typed questions, OCR and redaction run locally. Voice also needs its speech model downloaded first.
- Ollama and the two exact models below. Model weights are not in this ZIP.

## Install and prepare

1. Extract the ZIP and keep the `Gel Demo` folder and its `demo-data` together. Drag `Gel.app` to Applications, or run it from the extracted folder.
2. Install [Homebrew](https://brew.sh) if needed, then run these commands in Terminal:

   ```sh
   brew install ollama
   brew services start ollama
   ollama pull qwen3:4b-instruct-2507-q4_K_M
   ollama pull bge-m3
   ```

3. Open `Gel.app`. This is an **ad-hoc-signed development demo, not a notarized release**. macOS may block a downloaded copy. If you trust this build, try opening it once, then use System Settings → Privacy & Security → **Open Anyway** if macOS offers it. Check `BUILD-INFO.json` and the ZIP checksum before trusting a copy.
4. In onboarding, choose **Work: HR** and select the extracted `demo-data/HR Files` folder. If onboarding has already finished, add that folder in Settings → Folders. Wait for indexing to finish.
5. Confirm Settings → Models shows Ollama and both models available. Leave Cloud fallback **off** for this demo. The first question can take longer while Ollama loads the model.

## Three-minute typed demo

1. Press **⌥Space**, type **Sino sa applicants ang may 5+ years sa payroll?**, and press Enter. Look for Cruz, Santos and Reyes, citation chips and a **Local** badge.
2. Click a citation chip. Gel opens the document and highlights its source passage; the Reyes payroll passage is on page 2 of `Resume_REYES.pdf`.
3. In Library, select a sample resume and click **Redact**. Review the findings, then confirm. Gel writes a separate file under the source folder's `Redacted/` directory; it keeps the original.
4. Copy the text from `demo-data/clipboard-samples/employee_record.txt` and switch to Chrome. Leak Guard should show a warning. In an empty chat input, press **⌥⌘V** to paste placeholders. **Do not send the sample.**

For safe paste, grant Gel Accessibility access under System Settings → Privacy & Security → Accessibility. Without it, paste the replaced clipboard yourself with ⌘V. Test against synthetic text only; review findings before relying on redaction.

## Optional voice and offline checks

- Hold **right ⌥** in the launcher, speak a question, then release. Grant microphone permission when asked. Allow time and internet for the first WhisperKit speech model download before trying voice offline.
- After the local models have downloaded and a typed question has succeeded, turn Wi-Fi off and repeat the typed question, citation and redaction steps. Turn Wi-Fi back on afterward.
- If another app already owns ⌥Space, change the conflicting shortcut or open the launcher from Gel's menu bar.

## Verification limits

See `BUILD-INFO.json` for build/test results. Automated engine checks do not verify microphone permissions, Accessibility, browser pasting or the entire UI on a fresh Mac; run the steps above before a live presentation.

This build has known detection gaps for names and birth dates on scanned forms. Use synthetic data, keep cloud fallback off and review redactions. The global ⌥⌘V shortcut can also intercept Finder's **Move Item Here** action; use it with copied text in the demo's chat input, not copied files.

Source: https://github.com/joshuagemvicente/gel (private unless the owner changes its visibility).
