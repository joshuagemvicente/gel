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

## Addendum: mute other sounds while talking (requested Oct 10)

**Goal:** background music on the Mac goes silent while you hold right ⌥, so it doesn't drown you out or end up in the transcript, and it comes back the moment you let go.

### Behaviour

- **When it mutes:** once recording actually starts (permission granted and the microphone running), Gel mutes the Mac's **current sound output** (the default output device: speakers, headphones, AirPods, …).
- **When it unmutes:** as soon as recording stops (key released), before transcription, so the music is back while the text appears.
- **How it mutes:**
  - It uses the output device's own mute switch.
  - If the device has none (some HDMI, USB and AirPlay outputs), it sets the volume to 0 and later restores the exact previous volume.
  - If the device has neither, nothing is muted and recording works as before.
- **Only undo what Gel did:**
  - If the sound was already muted, or the volume already 0, Gel changes nothing.
  - If you change the mute or volume yourself while talking, Gel leaves your change alone on release.
  - Gel restores the device it muted, identified by device UID, even if the default output changed mid-recording.
- **Every way recording ends restores the sound:**
  - Release.
  - Too-short recording.
  - The launcher closing or losing focus mid-recording; this now **cancels** the recording and discards it.
  - Microphone start failure.
  - Gel quitting.
  - A crash: what Gel muted is saved before muting and restored at the next launch.
- **Setting:** Settings → Hotkeys gets a **"Mute other sounds while I talk"** toggle, on by default. When it's off, Gel never touches the output.
- **Cue:** while recording, the launcher line reads "Listening… release ⌥ to ask · sound muted". The "· sound muted" part only appears when Gel actually muted something.
- **Limits:**
  - Music keeps playing silently; it isn't paused.
  - Notification sounds are muted too.
  - Sound from other devices in the room isn't affected.
  - No new permission is needed (Core Audio device properties).

### Acceptance criteria

- [x] **M1** With audio playing on the Mac, starting a recording mutes the default output, and stopping it unmutes it. Observed as the device's mute property (or volume) reading muted, then restored, around one hold-to-talk.
- [x] **M2** Output already muted before recording → still muted after release.
- [x] **M3** Unmuting by hand during the recording → Gel doesn't re-mute or change it on release.
- [x] **M4** Launcher closed mid-recording → recording discarded (no question runs), sound restored.
- [x] **M5** Gel quits mid-recording → sound restored. A saved mute record from a crash is restored at the next launch.
- [x] **M6** Toggle off → a recording leaves the output untouched.
- [x] **M7** A device without a mute switch: volume goes to 0, then back to the exact previous value. Unit-tested against a fake device. On real hardware only if such a device is at hand.
- [x] **M8** The launcher shows "· sound muted" only while Gel has the output muted.
- [ ] **M9** Transcription still works: a typed-equivalent spoken question is transcribed with the mute on (manual, user).

## Addendum: microphone permission recovery (requested Oct 10)

**Goal:** a denied or first-time microphone permission never leaves voice broken. Once the user allows the microphone, hold-to-talk works on the next press without relaunching Gel, and every press that doesn't record says why.

**Found by QA (Oct 10):**
- A denial set `VoiceRecorder.state` to `.unavailable`. Only `load()` (once, at launch) sets `.ready`, so voice stayed off after the user allowed the microphone, until Gel was relaunched.
- The first press triggered the macOS prompt, ignored the answer and recorded nothing, with no message.

### Behaviour

- **Two separate things:** the voice *model* state (loading, ready, recording, transcribing, failed) and the *microphone access* notice. Microphone access never changes the model state. Only a model load failure or a microphone start failure disables voice for the session.
- **Every press checks access again.** Holding right ⌥ reads the current microphone authorization each time:
  - **Allowed:** record (as today) and clear any notice.
  - **Not asked yet:** show the macOS prompt and record nothing. The notice reads "Allow the microphone in the macOS prompt." while it is open. The prompt takes keyboard focus, so the launcher stays open until it is answered (instead of closing on focus loss) and then takes focus back. When the user answers:
    - **Allow:** "Microphone on. Hold right ⌥ again to talk."
    - **Don't Allow:** the denied notice below.
  - **Denied or restricted:** record nothing. Notice: "Microphone access is off. Allow it in System Settings → Privacy → Microphone."
- **Showing the launcher re-checks too.** If access was allowed in System Settings while the launcher was closed, opening it clears the denied notice before the user presses anything.
- **Where the notice shows:** in the mic glyph's tooltip and VoiceOver label (as today for `.unavailable`). It also replaces the "right ⌥ · hold to talk" key hint in the idle row, so it can be seen without hovering. A voice model failure (`.unavailable`) comes first in both places, so the row and the tooltip always agree. While access is denied, the mic glyph is dimmed.
- **Typing is never affected.**
- **Settings → Permissions updates by itself.** Both rows (Microphone, Accessibility) re-read their status whenever Gel becomes the active app, for example when the user comes back from System Settings. The Refresh link stays.
- **Testable core:** the access-to-action decision is a small pure type in GelCore (`MicGate`) with unit tests. The AVFoundation calls stay in the app target.
- **DEBUG-only override:** the UserDefaults key `gel.debug.micAccess` (`granted`, `denied` or `undetermined`) replaces the real authorization status. With `undetermined`, the prompt is simulated: `gel.debug.micRequest` (`granted` or `denied`, default `granted`) is the answer, after 0.5 s. This lets the criteria be checked without changing the Mac's privacy settings. It is not compiled into Release.

### Acceptance criteria

- [x] **P1** `MicGate` unit tests: granted → record; undetermined → ask; denied and restricted → explain with the denied text; prompt answered → the matching notice.
- [x] **P2** Denied, then allowed, without a relaunch: hold right ⌥ while denied → denied notice and no recording. Then allow access → open the launcher → the notice is gone → hold right ⌥ → "Listening…" (via `gel.debug.micAccess` and `gel.debug.holdToTalk`).
- [x] **P3** First press, not asked yet: no recording, the prompt notice shows, then "Microphone on. Hold right ⌥ again to talk." after Allow. The next press records. Don't Allow → the denied notice (via `gel.debug.micAccess undetermined` and `gel.debug.micRequest`).
- [x] **P4** While denied, the launcher still answers a typed question, and the idle row shows the denied notice in place of the key hint.
- [ ] **P5** Settings → Permissions: change the override, switch to another app and back to Gel → the Microphone row matches without pressing Refresh.
- [x] **P6** Release build compiles without the debug override (`#if DEBUG`), and `GelCoreTests` all pass.
- [ ] **P7** Real permission, manual (user): in System Settings, turn Gel's microphone off then on while Gel is running → voice works again without relaunching.
- [ ] **P8** Real first prompt, manual (user, on a Mac or bundle id never asked before; no `gel.debug.micAccess`): hold right ⌥ → the macOS prompt opens and the launcher stays open behind it with the prompt notice → Allow → the launcher has focus again and reads "Microphone on. Hold right ⌥ again to talk." → the next press records. The DEBUG simulation can't cover this, because it never moves focus.
