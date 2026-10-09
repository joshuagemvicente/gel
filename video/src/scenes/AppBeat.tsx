import React from "react";
import { AbsoluteFill, interpolate, spring, useCurrentFrame, useVideoConfig } from "remotion";
import { CaptureFrame } from "../components/CaptureFrame";
import { Pill } from "../components/Pill";
import { clips } from "../captures.generated";
import { SCENES } from "../timeline";
import { color, font, motion } from "../theme";

// Callout boxes are fractions of each clip, measured on frames of the real recordings (spec acceptance criterion).
// Frames below are scene-relative (scene start = 0).

/** Beat 3: the launcher answers the typed Taglish question. Real time, no speed-up. */
export const Ask: React.FC = () => (
  <AbsoluteFill style={{ background: color.canvas }}>
    <CaptureFrame
      clip={clips["R2-ask"]}
      slot="R2-ask"
      slotHint="Launcher answering the demo question"
      width={1440}
      top={40}
      callouts={[
        { x: 0.1, y: 0.622, w: 0.69, h: 0.06, label: "Every source is a chip", side: "below", from: 190 },
        { x: 0.733, y: 0.709, w: 0.167, h: 0.047, label: "Answered on this Mac", side: "below", from: 245 },
      ]}
    />
  </AbsoluteFill>
);

/** Beat 4: clicking Reyes's chip opens her resume on page 2 with the cited passage highlighted. */
export const Verify: React.FC = () => (
  <AbsoluteFill style={{ background: color.canvas }}>
    <CaptureFrame
      clip={clips["R3-verify"]}
      slot="R3-verify"
      slotHint="Viewer on the cited passage"
      width={1100}
      top={40}
      zoom={[[20, 1], [110, 1.08]]}
      zoomOrigin={[0.48, 0.2]}
      callouts={[{ x: 0.105, y: 0.106, w: 0.762, h: 0.259, label: "The passage the answer used", side: "below", from: 40 }]}
    />
  </AbsoluteFill>
);

/** Beat 5: scanning (10× with a tag), then the Before | After review. */
export const Redact: React.FC = () => (
  <AbsoluteFill style={{ background: color.canvas }}>
    <CaptureFrame
      clip={clips["R4-redact"]}
      slot="R4-redact"
      slotHint="Redact review"
      width={1150}
      top={40}
      callouts={[
        { x: 0.059, y: 0.032, w: 0.645, h: 0.064, label: "Checked on this Mac", side: "below", from: 150 },
        { x: 0.503, y: 0.185, w: 0.474, h: 0.432, label: "Blacked out in the saved copy", side: "below", from: 190, tone: "danger" },
      ]}
    />
  </AbsoluteFill>
);

const REDACTED = [
  "Employee: [NAME_1] (BOC-2016-0225)",
  "Position: Operations Manager - Operations",
  "DOB: [DOB_1]",
  "Address: [ADDRESS_1]",
  "SSS: [SSS_1] | TIN: [TIN_1] | PhilHealth: [PHILHEALTH_1] | Pag-IBIG: [PAGIBIG_1]",
  "Basic monthly salary: [SALARY_1]",
  "[NAME_2] acct (Bangko Halimbawa): [BANK_ACCOUNT_1]",
  "Mobile: [PHONE_1]  Email: [EMAIL_1]",
];

/** Beat 6: copy the record with ChatGPT in front → Gel's real overlay → what ⌥⌘V pastes (Gel's real redaction output). */
export const LeakGuard: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const CARD = 205;
  const card = spring({ frame: frame - CARD, fps, config: motion.smooth, durationInFrames: 18 });
  const copyO = interpolate(frame, [4, 10, 40, 48], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return (
    <AbsoluteFill style={{ background: color.canvas }}>
      <CaptureFrame
        clip={clips["R5-leak"]}
        slot="R5-leak"
        slotHint="Leak overlay over chatgpt.com"
        width={1440}
        top={40}
        zoom={[[52, 1], [80, 1.9], [175, 1.9], [200, 1]]}
        zoomOrigin={[0.97, 0]}
      >
        {/* The copy itself happens off-screen in the recording; this tag says what was copied. */}
        <div style={{ position: "absolute", left: 40, bottom: 40, opacity: copyO }}>
          <Pill tone="neutral" size={28}>⌘C · copied an employee record</Pill>
        </div>
        {frame >= CARD && (
          <div
            style={{
              position: "absolute", left: 120, right: 120, top: 150, borderRadius: 18, background: color.card, border: `1px solid ${color.hairline}`,
              boxShadow: "0 30px 80px rgba(0,0,0,0.35)", padding: "26px 34px", opacity: card, transform: `translateY(${(1 - card) * 24}px)`,
            }}
          >
            <div style={{ fontFamily: font.sans, fontSize: 30, fontWeight: 650, color: color.text, letterSpacing: -0.3 }}>⌥⌘V pastes this instead</div>
            <div style={{ fontFamily: font.sans, fontSize: 22, color: color.textSecondary, marginTop: 4, marginBottom: 16 }}>Gel's redaction of the copied record, made on this Mac</div>
            {REDACTED.map((l, i) => (
              <div key={i} style={{ fontFamily: font.mono, fontSize: 21, lineHeight: 1.6, color: color.text, opacity: interpolate(frame, [CARD + 4 + i * 2, CARD + 10 + i * 2], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }) }}>
                {l.split(/(\[[A-Z_0-9]+\])/).map((part, j) =>
                  /^\[.*\]$/.test(part) ? <span key={j} style={{ color: color.accent, background: color.accentSoft, borderRadius: 6, padding: "0 4px" }}>{part}</span> : <span key={j}>{part}</span>
                )}
              </div>
            ))}
          </div>
        )}
      </CaptureFrame>
    </AbsoluteFill>
  );
};

void SCENES;
