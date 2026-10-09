import { useId } from "react"

import { cn } from "@/lib/utils"

// GelDropPath.swift in a 100 × 100 box.
const DROP = "M50 2C57 15 84 38 84 63C84 83 69 98 50 98C31 98 16 83 16 63C16 38 43 15 50 2Z"

export function GelDrop({
  className,
  breathing = false,
}: {
  className?: string
  breathing?: boolean
}) {
  const id = useId()
  return (
    <svg
      viewBox="0 0 100 100"
      aria-hidden
      className={cn("shrink-0", breathing && "animate-gel-breathe", className)}
    >
      <defs>
        <linearGradient id={`${id}-fill`} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="var(--drop-top)" />
          <stop offset="1" stopColor="var(--drop-bottom)" />
        </linearGradient>
        <radialGradient id={`${id}-glow`} cx="0.56" cy="0.7" r="0.25">
          <stop offset="0" stopColor="white" stopOpacity="0.35" />
          <stop offset="1" stopColor="white" stopOpacity="0" />
        </radialGradient>
        <filter id={`${id}-soft`} x="-50%" y="-50%" width="200%" height="200%">
          <feGaussianBlur stdDeviation="2.5" />
        </filter>
        <clipPath id={`${id}-clip`}>
          <path d={DROP} />
        </clipPath>
      </defs>
      <g clipPath={`url(#${id}-clip)`}>
        <path d={DROP} fill={`url(#${id}-fill)`} />
        <rect width="100" height="100" fill={`url(#${id}-glow)`} />
        <ellipse
          cx="37"
          cy="52"
          rx="6"
          ry="11"
          fill="white"
          fillOpacity="0.7"
          transform="rotate(24 37 52)"
          filter={`url(#${id}-soft)`}
        />
      </g>
      <path d={DROP} fill="none" stroke="black" strokeOpacity="0.12" strokeWidth="1.2" />
    </svg>
  )
}
