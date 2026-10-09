import React from "react";
import { AbsoluteFill, spring, useCurrentFrame, useVideoConfig } from "remotion";
import { GelDrop } from "../components/GelDrop";
import { color, font, motion } from "../theme";

/** Beat 2 (8–11.5 s): the mark and the promise. */
export const MeetGel: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const drop = spring({ frame, fps, config: motion.pop, durationInFrames: 20 });
  const word = spring({ frame: frame - 6, fps, config: motion.smooth, durationInFrames: 18 });
  const tag = spring({ frame: frame - 30, fps, config: motion.smooth, durationInFrames: 18 });
  return (
    <AbsoluteFill style={{ background: color.canvas }}>
      <div style={{ position: "absolute", left: 0, right: 0, top: 300, display: "flex", justifyContent: "center", alignItems: "center", gap: 40 }}>
        <div style={{ opacity: drop, transform: `translateY(${(1 - drop) * -40}px) scale(${0.7 + 0.3 * drop})` }}><GelDrop size={200} /></div>
        <div style={{ fontFamily: font.sans, fontWeight: 700, fontSize: 180, letterSpacing: -6, color: color.text, opacity: word, transform: `translateX(${(1 - word) * 24}px)` }}>Gel</div>
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, top: 560, textAlign: "center", fontFamily: font.sans, fontSize: 46, color: color.textSecondary, opacity: tag, transform: `translateY(${(1 - tag) * 12}px)` }}>
        Private AI that runs on your Mac.
      </div>
    </AbsoluteFill>
  );
};
