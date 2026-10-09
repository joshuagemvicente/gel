import React from "react";
import { spring, useCurrentFrame, useVideoConfig } from "remotion";
import { color, font, motion } from "../theme";

export type CalloutSpec = {
  /** Box over the element, as fractions of the capture's width/height. */
  x: number;
  y: number;
  w: number;
  h: number;
  label: string;
  /** Where the label sits relative to the box. */
  side?: "above" | "below" | "left" | "right";
  from: number;
  until?: number;
  tone?: "accent" | "danger";
};

/** Accent outline + leader + label, placed inside a CaptureFrame (which provides the sized, relative container). */
export const Callout: React.FC<CalloutSpec & { frameW: number; frameH: number }> = ({ x, y, w, h, label, side = "below", from, until, tone = "accent", frameW, frameH }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const t = frame - from;
  if (t < 0) return null;
  if (until !== undefined && frame >= until) return null;
  const s = spring({ frame: t, fps, config: motion.pop, durationInFrames: 16 });
  const c = tone === "accent" ? color.accent : color.danger;
  const left = x * frameW;
  const top = y * frameH;
  const bw = w * frameW;
  const bh = h * frameH;
  const gap = 18;
  const labelPos: React.CSSProperties =
    side === "below"
      ? { left: 0, top: bh + gap }
      : side === "above"
      ? { left: 0, bottom: bh + gap }
      : side === "right"
      ? { left: bw + gap, top: 0 }
      : { right: bw + gap, top: 0 };
  return (
    <div style={{ position: "absolute", left, top, width: bw, height: bh, opacity: s, transform: `scale(${0.94 + 0.06 * s})`, transformOrigin: "center" }}>
      <div style={{ position: "absolute", inset: -4, border: `3px solid ${c}`, borderRadius: 10, boxShadow: `0 0 0 6px ${tone === "accent" ? "rgba(31,122,77,0.14)" : "rgba(179,64,46,0.14)"}` }} />
      <div
        style={{
          position: "absolute",
          ...labelPos,
          whiteSpace: "nowrap",
          fontFamily: font.sans,
          fontWeight: 600,
          fontSize: 28,
          letterSpacing: -0.2,
          color: "#fff",
          background: c,
          padding: "8px 16px",
          borderRadius: 999,
          boxShadow: "0 6px 20px rgba(0,0,0,0.18)",
        }}
      >
        {label}
      </div>
    </div>
  );
};
