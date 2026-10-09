"use client"

import { CpuIcon } from "lucide-react"
import { motion, useInView } from "motion/react"
import { useEffect, useRef, useState } from "react"

import { GelDrop } from "@/components/gel-drop"
import { TextShimmer } from "@/components/ui/text-shimmer"
import { usePrefersReducedMotion } from "@/hooks/use-prefers-reduced-motion"

// The launcher answering the demo question, recreated from docs/features/launcher/design.md with synthetic data.
// A product frame: it uses the app's own dark colours (--app-*), not the site's greys (design.md → Two palettes).
const QUESTION = "Sino sa applicants ang may 5+ years sa payroll?"
const CITATIONS = ["Resume_REYES.pdf", "Santos_Rodel_Resume.pdf", "CV - Patricia Anne Cruz.pdf"]

type Stage = "asking" | "thinking" | "answer" | "done"

function Ref({ n }: { n: number }) {
  return (
    <span className="mx-0.5 inline-flex size-4 translate-y-[-1px] items-center justify-center rounded-full bg-app-accent-fill align-middle text-[10px] font-semibold text-white">
      {n}
    </span>
  )
}

export function LauncherDemo() {
  const ref = useRef<HTMLDivElement>(null)
  const inView = useInView(ref, { once: true, margin: "-80px" })
  const reduce = usePrefersReducedMotion()
  const [stage, setStage] = useState<Stage>("asking")

  useEffect(() => {
    if (!inView || reduce) return
    const timers = [
      setTimeout(() => setStage("thinking"), 500),
      setTimeout(() => setStage("answer"), 1900),
      setTimeout(() => setStage("done"), 2400),
    ]
    return () => timers.forEach(clearTimeout)
  }, [inView, reduce])

  const shown: Stage = reduce ? "done" : stage
  const answered = shown === "answer" || shown === "done"

  return (
    <div
      ref={ref}
      role="img"
      aria-label={`Gel's launcher answering "${QUESTION}" with Kristine Joy Reyes, Rodel Santos and Patricia Anne Cruz, three citations and a Local badge.`}
      className="w-full overflow-hidden rounded-xl border border-app-hairline bg-app-card text-left text-app-text shadow-frame"
    >
      <div className="flex min-h-13 items-center gap-3 border-b border-app-hairline px-4 py-3">
        <GelDrop className="size-[18px]" breathing={shown === "thinking"} />
        <p className="text-[15px] leading-6 sm:text-base">{QUESTION}</p>
      </div>
      <div className="min-h-[9.5rem] px-4 py-3.5 text-sm leading-6">
        {shown === "thinking" && (
          <TextShimmer
            duration={1.3}
            className="[--base-color:var(--app-text-secondary)] [--base-gradient-color:var(--app-text)]"
          >
            Reading your files…
          </TextShimmer>
        )}
        {answered && (
          <motion.div
            initial={reduce ? false : { opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3, ease: "easeOut" }}
          >
            <p>
              3 applicants have 5+ years in payroll: Kristine Joy Reyes <Ref n={1} />, Rodel Santos{" "}
              <Ref n={2} /> and Patricia Anne Cruz <Ref n={3} />.
            </p>
            <div className="mt-3 flex flex-wrap items-center gap-1.5">
              {CITATIONS.map((file, i) => (
                <motion.span
                  key={file}
                  initial={reduce ? false : { opacity: 0, scale: 0.9 }}
                  animate={shown === "done" ? { opacity: 1, scale: 1 } : { opacity: 0, scale: 0.9 }}
                  transition={{ type: "spring", duration: 0.35, bounce: 0.3, delay: i * 0.035 }}
                  className="inline-flex max-w-full items-center gap-1.5 rounded-md border border-app-hairline bg-app-canvas py-0.5 pr-2 pl-1 text-xs"
                >
                  <Ref n={i + 1} />
                  <span className="truncate">{file}</span>
                </motion.span>
              ))}
              <motion.span
                initial={reduce ? false : { opacity: 0 }}
                animate={{ opacity: shown === "done" ? 1 : 0 }}
                transition={{ delay: 0.15, duration: 0.2 }}
                className="ml-auto inline-flex items-center gap-1 rounded-sm bg-accent px-1.5 py-0.5 font-mono text-xs tracking-[-0.013em] text-app-text-secondary"
              >
                <CpuIcon className="size-3.5 text-app-accent" aria-hidden />
                Local · qwen3 4B
              </motion.span>
            </div>
          </motion.div>
        )}
      </div>
    </div>
  )
}
