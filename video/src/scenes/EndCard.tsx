import React from "react";
import { AbsoluteFill, spring, useCurrentFrame, useVideoConfig } from "remotion";
import { GelDrop } from "../components/GelDrop";
import { color, font, motion } from "../theme";

/** Beat 8 (57–61 s). */
export const EndCard: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const a = spring({ frame: frame - 4, fps, config: motion.smooth, durationInFrames: 18 });
  const b = spring({ frame: frame - 16, fps, config: motion.smooth, durationInFrames: 18 });
  const c = spring({ frame: frame - 34, fps, config: motion.smooth, durationInFrames: 18 });
  return (
    <AbsoluteFill style={{ background: color.canvasDark, alignItems: "center", justifyContent: "center", fontFamily: font.sans }}>
      <div style={{ display: "flex", alignItems: "center", gap: 34, opacity: a, transform: `translateY(${(1 - a) * 20}px)` }}>
        <GelDrop size={150} />
        <div style={{ fontSize: 140, fontWeight: 700, letterSpacing: -5, color: color.textDark }}>Gel</div>
      </div>
      <div style={{ marginTop: 30, fontSize: 44, color: color.textSecondaryDark, opacity: b, transform: `translateY(${(1 - b) * 12}px)` }}>Private AI for your files. Runs on your Mac.</div>
      <div style={{ marginTop: 90, fontSize: 28, color: color.textSecondaryDark, fontFamily: font.mono, opacity: c, display: "flex", gap: 26 }}>
        <span>Team 12M</span><span>·</span><span>github.com/joshuagemvicente/gel</span><span>·</span><span style={{ color: color.accentDark }}>#AppBuildersPH</span>
      </div>
    </AbsoluteFill>
  );
};
