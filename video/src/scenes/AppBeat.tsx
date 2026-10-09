import React from "react";
import { AbsoluteFill } from "remotion";
import { CaptureFrame } from "../components/CaptureFrame";
import { CalloutSpec } from "../components/Callout";
import { clips } from "../captures.generated";
import { color } from "../theme";

type Props = { clipKey: string; hint: string; callouts?: CalloutSpec[]; muted?: boolean };

/** Beats 3–6: one real recording, framed, with callouts placed from measured positions. */
export const AppBeat: React.FC<Props> = ({ clipKey, hint, callouts = [], muted = true }) => (
  <AbsoluteFill style={{ background: color.canvas }}>
    <CaptureFrame clip={clips[clipKey]} slot={clipKey} slotHint={hint} callouts={callouts} muted={muted} />
  </AbsoluteFill>
);

// Callouts stay empty until the footage exists; positions are then measured on frames (spec acceptance criterion).
export const Ask = () => <AppBeat clipKey="R2-ask" muted={false} hint="⌥Space → hold right ⌥ → spoken Taglish question → answer, chips, Local badge" />;
export const Verify = () => <AppBeat clipKey="R3-verify" hint="Click the Reyes chip → viewer opens on the highlighted passage" />;
export const Redact = () => <AppBeat clipKey="R4-redact" hint="Select resumes → Redact → Before | After review" />;
export const LeakGuard = () => <AppBeat clipKey="R5-leak" hint="Copy the employee record → chatgpt.com → overlay → ⌥⌘V placeholders" />;
