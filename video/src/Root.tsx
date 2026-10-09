import React from "react";
import { AbsoluteFill, Audio, Composition, Easing, Sequence, interpolate, staticFile, useCurrentFrame } from "remotion";
import { Subtitles } from "./components/Subtitles";
import { Ask, LeakGuard, Redact, Verify } from "./scenes/AppBeat";
import { EndCard } from "./scenes/EndCard";
import { Hook } from "./scenes/Hook";
import { LocalStack } from "./scenes/LocalStack";
import { MeetGel } from "./scenes/MeetGel";
import { FPS, HEIGHT, WIDTH } from "./theme";
import { SCENES, T, TOTAL, VO_AT } from "./timeline";
import { VO } from "./vo.generated";

type Out = "cut" | "push" | "fade";
// Hard cut dark → light on "This is Gel"; match cut from the chip into the viewer; pushes between app beats; fade into the end card.
const ORDER: { key: keyof typeof SCENES; C: React.FC; out: Out }[] = [
  { key: "hook", C: Hook, out: "cut" },
  { key: "meet", C: MeetGel, out: "push" },
  { key: "ask", C: Ask, out: "cut" },
  { key: "verify", C: Verify, out: "push" },
  { key: "redact", C: Redact, out: "push" },
  { key: "leak", C: LeakGuard, out: "push" },
  { key: "stack", C: LocalStack, out: "fade" },
  { key: "end", C: EndCard, out: "cut" },
];

const ease = Easing.bezier(0.32, 0.72, 0, 1);

/** Pushes in from the right when the previous scene pushes out; pushes out left over its last T frames. */
const Transit: React.FC<{ len: number; inMode: Out; outMode: Out; children: React.ReactNode }> = ({ len, inMode, outMode, children }) => {
  const f = useCurrentFrame();
  let x = 0, o = 1;
  if (inMode === "push") x += interpolate(f, [0, T], [WIDTH, 0], { extrapolateRight: "clamp", easing: ease });
  if (inMode === "fade") o = interpolate(f, [0, T], [0, 1], { extrapolateRight: "clamp" });
  if (outMode === "push") x += interpolate(f, [len, len + T], [0, -WIDTH * 0.3], { extrapolateLeft: "clamp", easing: ease });
  return <AbsoluteFill style={{ transform: `translateX(${x}px)`, opacity: o }}>{children}</AbsoluteFill>;
};

const GelDemo: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill style={{ background: "#1E1D1B" }}>
      {ORDER.map(({ key, C, out }, i) => {
        const { from, to } = SCENES[key];
        const prevOut = i ? ORDER[i - 1].out : "cut";
        // Both scenes share the window [from, from + T): the old one leaves while the new one enters on top.
        const start = from;
        const len = to - start;
        return (
          <Sequence key={key} name={key} from={start} durationInFrames={len + (out === "cut" ? 0 : T)}>
            <Transit len={len} inMode={prevOut} outMode={out}>
              <C />
            </Transit>
          </Sequence>
        );
      })}
      {Object.entries(VO_AT).map(([id, at]) => (
        <Sequence key={id} name={`vo ${id}`} from={at} durationInFrames={Math.ceil(VO[id].seconds * FPS) + 2}>
          <Audio src={staticFile(VO[id].file)} />
        </Sequence>
      ))}
      {frame < SCENES.end.from && <Subtitles />}
    </AbsoluteFill>
  );
};

export const Root: React.FC = () => <Composition id="GelDemo" component={GelDemo} durationInFrames={TOTAL} fps={FPS} width={WIDTH} height={HEIGHT} />;
