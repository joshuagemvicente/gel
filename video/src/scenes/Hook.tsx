import React from "react";
import { AbsoluteFill, interpolate, spring, useCurrentFrame, useVideoConfig } from "remotion";
import { CloudGlyph } from "../components/Glyphs";
import { color, font, motion } from "../theme";

// Synthetic, masked values only (rule: synthetic data on screen).
const LINES = [
  { label: "Employee", value: "Reyes, Maria C.", kind: "name" },
  { label: "SSS No.", value: "34-•••••••-5", kind: "id", at: 36 },
  { label: "TIN", value: "•••-•••-•••-000", kind: "id", at: 44 },
  { label: "Monthly salary", value: "₱ ••,•••.00", kind: "money", at: 66 },
  { label: "Home address", value: "Brgy. ••••••, Makati", kind: "addr", at: 92 },
];
const CLOUD = { x: 1480, y: 470 }; // centre of the cloud glyph
const FLY_AT = 150; // "pasted into cloud AI"

/** Beat 1 (0–8 s): the problem and who has it. Full-frame, the IDs are copied into a cloud. */
export const Hook: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const card = spring({ frame, fps, config: motion.smooth, durationInFrames: 20 });
  const cloud = spring({ frame: frame - 118, fps, config: motion.pop, durationInFrames: 18 });
  const hot = interpolate(frame, [FLY_AT + 30, FLY_AT + 55], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const who = spring({ frame: frame - 70, fps, config: motion.smooth, durationInFrames: 18 });
  const cardX = 180, cardY = 230, rowH = 92, cardW = 820;
  return (
    <AbsoluteFill style={{ background: color.canvasDark }}>
      <div style={{ position: "absolute", left: cardX, top: 120, fontFamily: font.mono, fontSize: 26, color: color.textSecondaryDark, letterSpacing: 1.5, opacity: card }}>201 FILE · HR</div>
      <div
        style={{
          position: "absolute", left: cardX, top: cardY, width: cardW, borderRadius: 22, background: color.cardDark,
          border: `1px solid ${color.hairlineDark}`, boxShadow: "0 40px 100px rgba(0,0,0,0.45)", padding: "10px 40px",
          opacity: card, transform: `translateY(${(1 - card) * 30}px)`,
        }}
      >
        {LINES.map((l, i) => {
          const lit = l.at !== undefined ? spring({ frame: frame - l.at, fps, config: motion.snappy, durationInFrames: 10 }) : 0;
          return (
            <div key={l.label} style={{ height: rowH, display: "flex", alignItems: "center", justifyContent: "space-between", borderTop: i ? `1px solid ${color.hairlineDark}` : "none", fontFamily: font.sans, fontSize: 38 }}>
              <span style={{ color: color.textSecondaryDark }}>{l.label}</span>
              <span style={{ fontFamily: l.kind === "id" ? font.mono : font.sans, fontWeight: 500, color: lit ? `color-mix(in srgb, ${color.textDark} ${100 - lit * 100}%, ${color.dangerDark})` : color.textDark, background: `rgba(224,112,92,${lit * 0.14})`, padding: "4px 12px", borderRadius: 8 }}>{l.value}</span>
            </div>
          );
        })}
      </div>
      {/* Copies of the sensitive values travel into the cloud; the originals stay on the record. */}
      {LINES.filter((l) => l.at !== undefined).map((l, i) => {
        const p = spring({ frame: frame - FLY_AT - i * 5, fps, config: motion.smooth, durationInFrames: 30 });
        if (p <= 0.001) return null;
        const sx = cardX + cardW - 260, sy = cardY + 10 + LINES.indexOf(l) * rowH + rowH / 2 - 20;
        const x = interpolate(p, [0, 1], [sx, CLOUD.x - 120]);
        const y = interpolate(p, [0, 1], [sy, CLOUD.y - 30]) - Math.sin(p * Math.PI) * 120;
        const o = p < 0.75 ? 1 : 1 - (p - 0.75) * 4;
        return (
          <div key={l.label} style={{ position: "absolute", left: x, top: y, opacity: o, transform: `scale(${1 - p * 0.5})`, transformOrigin: "left center", fontFamily: l.kind === "id" ? font.mono : font.sans, fontSize: 36, fontWeight: 500, color: color.dangerDark, whiteSpace: "nowrap" }}>
            {l.value}
          </div>
        );
      })}
      <div style={{ position: "absolute", left: CLOUD.x - 210, top: CLOUD.y - 150, opacity: cloud, transform: `scale(${(0.85 + 0.15 * cloud) * (1 + hot * 0.05)})` }}>
        <CloudGlyph size={420} color={`color-mix(in srgb, ${color.textSecondaryDark} ${100 - hot * 100}%, ${color.dangerDark})`} fill={`rgba(224,112,92,${hot * 0.14})`} />
        <div style={{ textAlign: "center", fontFamily: font.sans, fontSize: 30, color: color.textSecondaryDark, marginTop: 10 }}>cloud AI chat</div>
      </div>
      <div style={{ position: "absolute", left: cardX, top: cardY + LINES.length * rowH + 60, opacity: who, transform: `translateY(${(1 - who) * 10}px)`, fontFamily: font.sans, fontSize: 30, color: color.textSecondaryDark }}>
        HR & payroll teams · protected under the Philippine Data Privacy Act
      </div>
    </AbsoluteFill>
  );
};
