import React from "react";
import { OffthreadVideo, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { Clip } from "../captures.generated";
import { color, font, motion } from "../theme";
import { Callout, CalloutSpec } from "./Callout";

type Props = {
  clip: Clip;
  slot: string;
  slotHint: string;
  width?: number;
  aspect?: number;
  top?: number;
  callouts?: CalloutSpec[];
  /** Frame (scene-relative) at which the clip starts playing. */
  startAt?: number;
  /** Only R2 keeps its audio: the user's own spoken question. */
  muted?: boolean;
  /** Push-in keyframes [frame, scale] (scene-relative) around `zoomOrigin` (fractions of the clip). */
  zoom?: [number, number][];
  zoomOrigin?: [number, number];
  children?: React.ReactNode;
};

/**
 * A recording of the real app in a rounded window frame. Clips are cut and sped by ffmpeg beforehand
 * (media/captures/clips.json lists any sped spans), so they play 1:1 here.
 */
export const CaptureFrame: React.FC<Props> = ({ clip, slot, slotHint, width = 1440, aspect, top = 48, callouts = [], startAt = 0, muted = true, zoom, zoomOrigin = [0.5, 0.5], children }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const a = aspect ?? clip?.aspect ?? 16 / 9;
  const height = width / a;
  const enter = spring({ frame, fps, config: motion.smooth, durationInFrames: 16 });
  const z = zoom && zoom.length > 1
    ? interpolate(frame, zoom.map((k) => k[0]), zoom.map((k) => k[1]), { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: (t) => 1 - Math.pow(1 - t, 3) })
    : 1;
  return (
    <>
      <div
        style={{
          position: "absolute",
          left: (1920 - width) / 2,
          top,
          width,
          height,
          borderRadius: 16,
          overflow: "hidden",
          background: color.card,
          border: `1px solid ${color.hairline}`,
          boxShadow: "0 30px 80px rgba(31,29,26,0.22)",
          opacity: enter,
          transform: `scale(${0.985 + 0.015 * enter})`,
        }}
      >
        <div style={{ position: "absolute", inset: 0, transform: `scale(${z})`, transformOrigin: `${zoomOrigin[0] * 100}% ${zoomOrigin[1] * 100}%` }}>
          {clip ? (
            frame >= startAt ? (
              <OffthreadVideo src={staticFile(clip.file)} startFrom={0} muted={muted} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
            ) : null
          ) : (
            <Slot slot={slot} hint={slotHint} />
          )}
          {callouts.map((c) => (
            <Callout key={c.label + c.from} {...c} frameW={width} frameH={height} />
          ))}
        </div>
        {children}
      </div>
      {clip?.speedSpans?.map((s) => (
        <SpeedTag key={s.from} factor={s.speed} from={startAt + Math.round(s.from * fps)} until={startAt + Math.round(s.to * fps)} right={(1920 - width) / 2 + 24} top={top + 24} />
      ))}
    </>
  );
};

const Slot: React.FC<{ slot: string; hint: string }> = ({ slot, hint }) => (
  <div style={{ position: "absolute", inset: 0, background: `repeating-linear-gradient(135deg, ${color.canvas} 0 28px, #F0EDE6 28px 56px)`, display: "flex", alignItems: "center", justifyContent: "center", fontFamily: font.sans }}>
    <div style={{ border: `3px dashed ${color.hairline}`, borderRadius: 18, padding: "30px 48px", background: "rgba(255,255,255,0.8)", textAlign: "center", maxWidth: 1000 }}>
      <div style={{ fontFamily: font.mono, fontSize: 24, color: color.accent, letterSpacing: 1, marginBottom: 8 }}>RECORDING SLOT · {slot}</div>
      <div style={{ fontSize: 32, fontWeight: 600, color: color.text, lineHeight: 1.25 }}>{hint}</div>
    </div>
  </div>
);

export const SpeedTag: React.FC<{ factor: number; from: number; until: number; right?: number; top?: number }> = ({ factor, from, until, right = 270, top = 70 }) => {
  const frame = useCurrentFrame();
  if (factor === 1 || frame < from || frame >= until) return null;
  const o = interpolate(frame, [from, from + 4, until - 4, until], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return (
    <div style={{ position: "absolute", top, right, opacity: o, fontFamily: font.sans, fontWeight: 700, fontSize: 30, color: "#fff", background: "rgba(30,29,27,0.85)", borderRadius: 999, padding: "6px 18px" }}>
      {factor}× speed
    </div>
  );
};
