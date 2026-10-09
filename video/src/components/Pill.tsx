import React from "react";
import { spring, useCurrentFrame, useVideoConfig } from "remotion";
import { color, font, motion } from "../theme";

type Props = {
  children: React.ReactNode;
  from?: number;
  tone?: "accent" | "neutral" | "danger" | "dark";
  size?: number;
  style?: React.CSSProperties;
  icon?: React.ReactNode;
};

/** Capsule chip that pops in (scale 0.9 → 1 + fade), like the launcher's citation chips. */
export const Pill: React.FC<Props> = ({ children, from = 0, tone = "accent", size = 28, style, icon }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const t = frame - from;
  if (t < 0) return null;
  const s = spring({ frame: t, fps, config: motion.pop, durationInFrames: 16 });
  const palette = {
    accent: { bg: color.accentSoft, fg: color.accent, border: "rgba(31,122,77,0.25)" },
    neutral: { bg: color.card, fg: color.text, border: color.hairline },
    danger: { bg: color.dangerSoft, fg: color.danger, border: "rgba(179,64,46,0.25)" },
    dark: { bg: "rgba(255,255,255,0.08)", fg: color.textDark, border: "rgba(255,255,255,0.14)" },
  }[tone];
  return (
    <div
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: size * 0.4,
        padding: `${size * 0.4}px ${size * 0.8}px`,
        borderRadius: 999,
        background: palette.bg,
        color: palette.fg,
        border: `1.5px solid ${palette.border}`,
        fontFamily: font.sans,
        fontWeight: 600,
        fontSize: size,
        letterSpacing: -0.2,
        opacity: s,
        transform: `scale(${0.9 + 0.1 * s})`,
        transformOrigin: "center",
        whiteSpace: "nowrap",
        ...style,
      }}
    >
      {icon}
      {children}
    </div>
  );
};
