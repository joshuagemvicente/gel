# F2 · Voice input — Spec

**Goal:** ask a question by speaking Taglish, fully offline.

## Behaviour

- In the launcher, **hold right ⌥** (or press and hold the mic button) to record; release to transcribe. A local key monitor is enough because the launcher is key while open (no Input Monitoring permission needed).
- Record 16 kHz mono with `AVAudioEngine`; show a live level meter in the input field while recording.
- Transcribe with **WhisperKit**, model `large-v3-v20240930_turbo` (fall back to `small` if the large model fails to load), language auto-detect. Load the model once in the background at app launch.
- The transcript fills the input field and stays editable; it runs automatically on release (user can press Esc to cancel, edit, then Enter).
- If WhisperKit or the microphone is unavailable, the mic control is disabled with a one-line reason and typing still works.
- Microphone permission text: "Gel transcribes your voice questions on this Mac. Audio never leaves your device."

## Acceptance criteria

- [ ] A 10-word Taglish question is transcribed within 2 s of releasing the key (model already loaded).
- [ ] Works with Wi-Fi off.
- [ ] With the microphone denied, the launcher still accepts typed questions and explains why voice is off.
