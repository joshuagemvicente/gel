import React from "react";

/** Minimal line icons (no SF Symbols in Chromium). */
export const CloudGlyph: React.FC<{ size: number; color: string; fill?: string }> = ({ size, color, fill = "none" }) => (
  <svg width={size} height={size * 0.7} viewBox="0 0 100 70" fill={fill} stroke={color} strokeWidth={5} strokeLinecap="round" strokeLinejoin="round">
    <path d="M28 62 H74 a18 18 0 0 0 2 -36 a24 24 0 0 0 -46 -6 a16 16 0 0 0 -2 42 Z" />
  </svg>
);

export const WifiGlyph: React.FC<{ size: number; color: string; slash?: number }> = ({ size, color, slash = 0 }) => (
  <svg width={size} height={size} viewBox="0 0 100 100" fill="none" stroke={color} strokeWidth={7} strokeLinecap="round">
    <path d="M10 38 a60 60 0 0 1 80 0" />
    <path d="M24 54 a38 38 0 0 1 52 0" />
    <path d="M38 70 a16 16 0 0 1 24 0" />
    <circle cx="50" cy="84" r="4" fill={color} stroke="none" />
    {slash > 0 && <path d="M18 18 L82 82" strokeWidth={9} strokeDasharray={100} strokeDashoffset={100 - 100 * slash} />}
  </svg>
);

export const ShieldGlyph: React.FC<{ size: number; color: string }> = ({ size, color }) => (
  <svg width={size} height={size} viewBox="0 0 100 100" fill="none" stroke={color} strokeWidth={6} strokeLinejoin="round" strokeLinecap="round">
    <path d="M50 8 L84 22 V48 C84 70 68 86 50 94 C32 86 16 70 16 48 V22 Z" />
    <path d="M36 50 L46 60 L66 40" />
  </svg>
);

export const CpuGlyph: React.FC<{ size: number; color: string }> = ({ size, color }) => (
  <svg width={size} height={size} viewBox="0 0 100 100" fill="none" stroke={color} strokeWidth={6} strokeLinejoin="round">
    <rect x="24" y="24" width="52" height="52" rx="8" />
    <rect x="40" y="40" width="20" height="20" rx="3" />
    {[34, 50, 66].map((p) => (
      <React.Fragment key={p}>
        <path d={`M${p} 24 V10`} /><path d={`M${p} 76 V90`} /><path d={`M24 ${p} H10`} /><path d={`M76 ${p} H90`} />
      </React.Fragment>
    ))}
  </svg>
);
