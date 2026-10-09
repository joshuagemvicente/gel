// v2 timeline (frames at 30 fps), fitted to the real clips in media/captures and the narration lengths.
export const T = 10;

export const SCENES = {
  hook: { from: 0, to: 240 },
  meet: { from: 240, to: 345 },
  ask: { from: 345, to: 700 },
  verify: { from: 700, to: 880 },
  redact: { from: 880, to: 1190 },
  leak: { from: 1190, to: 1540 },
  stack: { from: 1540, to: 1795 },
  end: { from: 1795, to: 1915 },
} as const;

export const TOTAL = 1915;

/** Absolute start frame of each narration line. */
export const VO_AT: Record<string, number> = {
  "01": 9,
  "02": 249,
  "03": 352,
  "04": 540,
  "05": 712,
  "06": 890,
  "07": 1196,
  "08": 1546,
  "09": 1807,
};

/** English gloss of the typed Taglish question, between narration lines 03 and 04. */
export const QUESTION_AT = { from: 432, to: 532 };
