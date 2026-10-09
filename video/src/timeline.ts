// v2 timeline (frames at 30 fps), from docs/deliverables/demo-video/design.md → Narration script.
// Each VO line starts at `vo`; scenes run [from, to). Transitions overlap the next scene by `T` frames.
export const T = 10;

export const SCENES = {
  hook: { from: 0, to: 240 },
  meet: { from: 240, to: 390 },
  ask: { from: 390, to: 810 },
  verify: { from: 810, to: 960 },
  redact: { from: 960, to: 1185 },
  leak: { from: 1185, to: 1455 },
  stack: { from: 1455, to: 1710 },
  end: { from: 1710, to: 1830 },
} as const;

export const TOTAL = 1830;

/** Absolute start frame of each narration line. */
export const VO_AT: Record<string, number> = {
  "01": 9,
  "02": 249,
  "03": 396,
  "04": 724,
  "05": 816,
  "06": 966,
  "07": 1191,
  "08": 1461,
  "09": 1722,
};

/** The user's own spoken question inside R2 (absolute frames); refined from the footage. */
export const QUESTION_AT = { from: 480, to: 600 };
