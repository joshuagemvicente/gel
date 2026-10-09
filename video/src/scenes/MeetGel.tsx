import React from "react";
import { AbsoluteFill, Sequence, interpolate, spring, useCurrentFrame, useVideoConfig } from "remotion";
import { CaptureFrame } from "../components/CaptureFrame";
import { GelDrop } from "../components/GelDrop";
import { clips } from "../captures.generated";
import { color, font, motion } from "../theme";

const WIFI_AT = 92; // "First, Wi-Fi off." (scene-relative)

/** Beat 2 (8–13 s): the mark, then the real menu bar turning Wi-Fi off. */
export const MeetGel: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const drop = spring({ frame, fps, config: motion.pop, durationInFrames: 20 });
  const word = spring({ frame: frame - 6, fps, config: motion.smooth, durationInFrames: 18 });
  const tag = spring({ frame: frame - 26, fps, config: motion.smooth, durationInFrames: 18 });
  // The brand lockup moves up and shrinks to make room for the recording.
  const lift = spring({ frame: frame - WIFI_AT + 8, fps, config: motion.smooth, durationInFrames: 18 });
  const y = interpolate(lift, [0, 1], [0, -300]);
  const sc = interpolate(lift, [0, 1], [1, 0.45]);
  return (
    <AbsoluteFill style={{ background: color.canvas }}>
      <div style={{ position: "absolute", left: 0, right: 0, top: 330, transform: `translateY(${y}px) scale(${sc})`, transformOrigin: "50% 0%" }}>
        <div style={{ display: "flex", justifyContent: "center", alignItems: "center", gap: 40 }}>
          <div style={{ opacity: drop, transform: `translateY(${(1 - drop) * -40}px) scale(${0.7 + 0.3 * drop})` }}><GelDrop size={200} /></div>
          <div style={{ fontFamily: font.sans, fontWeight: 700, fontSize: 180, letterSpacing: -6, color: color.text, opacity: word, transform: `translateX(${(1 - word) * 24}px)` }}>Gel</div>
        </div>
        <div style={{ textAlign: "center", marginTop: 28, fontFamily: font.sans, fontSize: 46, color: color.textSecondary, opacity: tag * (1 - lift) }}>Private AI for your Mac.</div>
      </div>
      <Sequence from={WIFI_AT} layout="none">
        <CaptureFrame clip={clips["R1-wifi"]} slot="R1-wifi" slotHint="Real menu bar: Control Center → Wi-Fi off" width={1300} aspect={2.6} top={300} />
      </Sequence>
    </AbsoluteFill>
  );
};
