import React from "react";
import { color } from "../theme";

// Same Bézier path as Gel/Gel/App/GelDropPath.swift, scaled to a 100-unit box.
export const DROP_PATH =
  "M50 2 C57 15 84 38 84 63 C84 83 69 98 50 98 C31 98 16 83 16 63 C16 38 43 15 50 2 Z";

export const GelDrop: React.FC<{ size: number; style?: React.CSSProperties }> = ({ size, style }) => {
  const id = React.useId().replace(/:/g, "");
  return (
    <svg width={size} height={size} viewBox="0 0 100 100" style={style}>
      <defs>
        <linearGradient id={`g${id}`} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor={color.dropTop} />
          <stop offset="1" stopColor={color.dropBottom} />
        </linearGradient>
        <radialGradient id={`r${id}`} cx="0.56" cy="0.7" r="0.3">
          <stop offset="0" stopColor="#fff" stopOpacity="0.35" />
          <stop offset="1" stopColor="#fff" stopOpacity="0" />
        </radialGradient>
        <clipPath id={`c${id}`}>
          <path d={DROP_PATH} />
        </clipPath>
        <filter id={`b${id}`}>
          <feGaussianBlur stdDeviation="1.2" />
        </filter>
      </defs>
      <path d={DROP_PATH} fill={`url(#g${id})`} />
      <g clipPath={`url(#c${id})`}>
        <rect width="100" height="100" fill={`url(#r${id})`} />
        <ellipse cx="37" cy="52" rx="6" ry="11" fill="#fff" fillOpacity="0.7" transform="rotate(24 37 52)" filter={`url(#b${id})`} />
      </g>
      <path d={DROP_PATH} fill="none" stroke="rgba(0,0,0,0.12)" strokeWidth="1.2" />
    </svg>
  );
};
