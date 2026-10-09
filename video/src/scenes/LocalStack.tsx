import React from "react";
import { AbsoluteFill, spring, useCurrentFrame, useVideoConfig } from "remotion";
import { CloudGlyph, CpuGlyph } from "../components/Glyphs";
import { Pill } from "../components/Pill";
import { color, font, motion } from "../theme";

// Disclosures from docs/project/demo-and-submission.md; the number is D-030 (measured on the M2).
const STACK: [string, string, number][] = [
  ["WhisperKit", "speech", 6],
  ["Apple Vision", "OCR", 18],
  ["BGE-M3", "search", 30],
  ["Qwen3 4B", "answers", 42],
  ["SQLite", "index", 54],
];

/** Beat 7 (48.5–57 s): what runs locally, one measured number, the cloud rule. Paced to the narration. */
export const LocalStack: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const head = spring({ frame, fps, config: motion.smooth, durationInFrames: 16 });
  const num = spring({ frame: frame - 72, fps, config: motion.smooth, durationInFrames: 18 });
  const cloud = spring({ frame: frame - 110, fps, config: motion.smooth, durationInFrames: 18 });
  return (
    <AbsoluteFill style={{ background: color.canvas }}>
      <div style={{ position: "absolute", top: 110, left: 0, right: 0, display: "flex", justifyContent: "center", alignItems: "center", gap: 18, opacity: head }}>
        <CpuGlyph size={64} color={color.accent} />
        <span style={{ fontFamily: font.sans, fontSize: 48, fontWeight: 650, color: color.text, letterSpacing: -0.8 }}>Runs on this Mac</span>
      </div>
      <div style={{ position: "absolute", top: 230, left: 120, right: 120, display: "flex", justifyContent: "center", gap: 20 }}>
        {STACK.map(([name, role, at]) => (
          <Pill key={name} from={at} tone="accent" size={32}>
            {name}
            <span style={{ color: color.textSecondary, fontWeight: 500, marginLeft: 6 }}>{role}</span>
          </Pill>
        ))}
      </div>
      <div style={{ position: "absolute", top: 400, left: 0, right: 0, textAlign: "center", opacity: num, transform: `translateY(${(1 - num) * 12}px)` }}>
        <div style={{ fontFamily: font.serif, fontSize: 132, color: color.text, letterSpacing: -2, lineHeight: 1 }}>25.5 s</div>
        <div style={{ fontFamily: font.sans, fontSize: 32, color: color.textSecondary, marginTop: 14 }}>to index 58 demo files, 10 of them scans, on an M2</div>
      </div>
      <div style={{ position: "absolute", top: 740, left: 0, right: 0, display: "flex", justifyContent: "center", opacity: cloud, transform: `translateY(${(1 - cloud) * 12}px)` }}>
        <div style={{ display: "flex", alignItems: "center", gap: 18, fontFamily: font.sans, fontSize: 34, color: color.text, background: color.card, border: `1px solid ${color.hairline}`, borderRadius: 999, padding: "14px 30px" }}>
          <CloudGlyph size={52} color={color.textSecondary} />
          Cloud fallback is off by default, and only ever sees redacted text.
        </div>
      </div>
    </AbsoluteFill>
  );
};
