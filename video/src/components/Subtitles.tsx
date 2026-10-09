import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { QUESTION_AT, VO_AT } from "../timeline";
import { VO } from "../vo.generated";
import { color, font } from "../theme";

type Cue = { from: number; to: number; text: string; gloss?: string; italic?: boolean };

/** Splits a line into ≤ 7-word phrases at punctuation and spreads its duration by character count. */
function cuesFor(id: string, fps: number): Cue[] {
  const line = VO[id];
  const start = VO_AT[id];
  const words = line.text.split(/\s+/);
  const phrases: string[] = [];
  let cur: string[] = [];
  for (const w of words) {
    cur.push(w);
    const end = /[.,?!]$/.test(w);
    if ((end && cur.length >= 3) || cur.length >= 7) {
      phrases.push(cur.join(" "));
      cur = [];
    }
  }
  if (cur.length) {
    if (cur.length <= 2 && phrases.length) phrases[phrases.length - 1] += " " + cur.join(" ");
    else phrases.push(cur.join(" "));
  }
  const total = phrases.reduce((n, p) => n + p.length, 0);
  const frames = line.seconds * fps;
  let t = start;
  return phrases.map((p) => {
    const len = (p.length / total) * frames;
    const cue = { from: Math.round(t), to: Math.round(t + len), text: p };
    t += len;
    return cue;
  });
}

export function allCues(fps: number): Cue[] {
  const cues = Object.keys(VO_AT).flatMap((id) => cuesFor(id, fps));
  cues.push({ from: QUESTION_AT.from, to: QUESTION_AT.to, text: "“Sino sa applicants ang may 5+ years sa payroll?”", gloss: "Which applicants have 5+ years in payroll?", italic: true });
  return cues.sort((a, b) => a.from - b.from);
}

/** Burned-in subtitles: the narration, word for word, one phrase at a time (spec: works muted). */
export const Subtitles: React.FC<{ dark?: boolean }> = () => {
  const frame = useCurrentFrame();
  const cues = React.useMemo(() => allCues(30), []);
  const cue = cues.find((c) => frame >= c.from && frame < Math.max(c.to, c.from + 36));
  if (!cue) return null;
  const inO = interpolate(frame, [cue.from, cue.from + 4], [0, 1], { extrapolateRight: "clamp" });
  return (
    <div style={{ position: "absolute", left: 0, right: 0, bottom: 44, display: "flex", flexDirection: "column", alignItems: "center", gap: 8, opacity: inO }}>
      <div
        style={{
          fontFamily: font.sans,
          fontWeight: 600,
          fontStyle: cue.italic ? "italic" : "normal",
          fontSize: 44,
          letterSpacing: -0.3,
          color: color.textDark,
          background: "rgba(30,29,27,0.86)",
          padding: "12px 26px",
          borderRadius: 14,
          maxWidth: 1500,
          textAlign: "center",
        }}
      >
        {cue.text}
      </div>
      {cue.gloss && (
        <div style={{ fontFamily: font.sans, fontSize: 28, color: color.text, background: "rgba(255,255,255,0.9)", padding: "6px 16px", borderRadius: 10 }}>{cue.gloss}</div>
      )}
    </div>
  );
};
