// Brand tokens from docs/features/app-shell/design.md and polish/design.md.
export const color = {
  canvas: "#F7F5F0",
  canvasDark: "#1E1D1B",
  card: "#FFFFFF",
  cardDark: "#282624",
  hairline: "#E7E3DA",
  hairlineDark: "#3A3733",
  text: "#1F1D1A",
  textDark: "#F2EFE9",
  textSecondary: "#6F6A61",
  textSecondaryDark: "#A8A296",
  accent: "#1F7A4D",
  accentDark: "#3FB27A",
  accentSoft: "rgba(31,122,77,0.12)",
  danger: "#B3402E",
  dangerDark: "#E0705C",
  dangerSoft: "rgba(179,64,46,0.12)",
  dropTop: "#4FC48A",
  dropBottom: "#1F7A4D",
};

export const font = {
  sans: '-apple-system, "SF Pro Display", "SF Pro Text", "Helvetica Neue", Helvetica, Arial, sans-serif',
  serif: '"New York", "Iowan Old Style", "Palatino", Georgia, serif',
  mono: '"SF Mono", Menlo, monospace',
};

// Motion tokens (critically damped unless noted), mirroring Theme.swift.
export const motion = {
  snappy: { mass: 1, stiffness: 420, damping: 41 },
  smooth: { mass: 1, stiffness: 190, damping: 27.6 },
  pop: { mass: 1, stiffness: 300, damping: 25 },
  staggerFrames: 1, // ~35 ms at 30 fps
};

export const FPS = 30;
export const WIDTH = 1920;
export const HEIGHT = 1080;
