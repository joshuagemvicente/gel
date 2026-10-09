"use client"

import { MotionConfig } from "motion/react"

import { Toaster } from "@/components/ui/sonner"
import { TooltipProvider } from "@/components/ui/tooltip"

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    // "user": transforms are dropped under prefers-reduced-motion; opacity still fades.
    <MotionConfig reducedMotion="user">
      <TooltipProvider>{children}</TooltipProvider>
      <Toaster position="bottom-center" />
    </MotionConfig>
  )
}
