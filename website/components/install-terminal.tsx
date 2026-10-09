"use client"

import { CheckIcon, CopyIcon } from "lucide-react"
import { useInView } from "motion/react"
import { useEffect, useRef, useState } from "react"
import { toast } from "sonner"

import { Button } from "@/components/ui/button"
import { usePrefersReducedMotion } from "@/hooks/use-prefers-reduced-motion"
import { cn } from "@/lib/utils"

// Hand-built after Vercel's CLI panel (D-060): types each command once when scrolled into view, never loops.
// Commands match docs/deliverables/demo-download/start-here-dmg.md character for character.
const TABS = [
  {
    label: "Install Ollama",
    lines: [
      { comment: "Needs Homebrew: https://brew.sh" },
      { cmd: "brew install ollama" },
      { cmd: "brew services start ollama" },
    ],
  },
  {
    label: "Pull models",
    lines: [
      { comment: "Answers: Qwen3 4B Instruct 2507" },
      { cmd: "ollama pull qwen3:4b-instruct-2507-q4_K_M" },
      { comment: "Search: BGE-M3 embeddings" },
      { cmd: "ollama pull bge-m3" },
    ],
  },
] as const

type Line = { cmd: string } | { comment: string }

const text = (l: Line) => ("cmd" in l ? l.cmd : `# ${l.comment}`)

export function InstallTerminal() {
  const ref = useRef<HTMLDivElement>(null)
  const inView = useInView(ref, { once: true, margin: "-80px" })
  const reduce = usePrefersReducedMotion()
  const [tab, setTab] = useState(0)
  const [typed, setTyped] = useState<number[]>(TABS.map(() => 0))
  const [copied, setCopied] = useState(false)

  const lines: readonly Line[] = TABS[tab].lines
  const total = lines.reduce((n, l) => n + text(l).length, 0)

  useEffect(() => {
    if (!inView || reduce || typed[tab] >= total) return
    const t = setTimeout(
      () => setTyped((prev) => prev.map((v, i) => (i === tab ? Math.min(total, v + 2) : v))),
      18,
    )
    return () => clearTimeout(t)
  }, [inView, reduce, tab, typed, total])

  const budget = reduce ? total : typed[tab]
  // Characters typed before each line starts.
  const starts = lines.map((_, i) => lines.slice(0, i).reduce((n, l) => n + text(l).length, 0))

  const commands = lines.filter((l): l is { cmd: string } => "cmd" in l).map((l) => l.cmd)

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(commands.join("\n"))
      setCopied(true)
      toast.success("Copied", { description: TABS[tab].label })
      setTimeout(() => setCopied(false), 2000)
    } catch {
      toast.error("Couldn't copy. Select the text instead.")
    }
  }

  return (
    <div ref={ref} className="overflow-hidden rounded-md border bg-card">
      <div className="flex items-center justify-between gap-2 border-b bg-popover px-2 py-1.5">
        <div role="tablist" aria-label="Setup commands" className="flex gap-1">
          {TABS.map((t, i) => (
            <button
              key={t.label}
              role="tab"
              type="button"
              aria-selected={tab === i}
              onClick={() => setTab(i)}
              className={cn(
                "rounded-full px-3 py-1 text-xs text-muted-foreground transition-colors duration-150 hover:text-foreground focus-visible:ring-3 focus-visible:ring-ring/50 focus-visible:outline-none",
                tab === i && "bg-accent text-foreground",
              )}
            >
              {t.label}
            </button>
          ))}
        </div>
        <Button
          variant="ghost"
          size="icon-sm"
          onClick={copy}
          aria-label={`Copy the ${TABS[tab].label} commands`}
          className="text-muted-foreground hover:text-foreground"
        >
          {copied ? <CheckIcon /> : <CopyIcon />}
        </Button>
      </div>
      <pre
        role="tabpanel"
        aria-label={TABS[tab].label}
        className="min-h-36 overflow-x-auto px-4 py-3.5 font-mono text-[13px] leading-6 tracking-[-0.013em] text-body"
      >
        {/* Screen readers get the full text at once; the typing is visual only. */}
        <span className="sr-only">{lines.map(text).join("\n")}</span>
        <span aria-hidden>
          {lines.map((l, i) => {
            const full = text(l)
            const left = budget - starts[i]
            const shown = full.slice(0, Math.max(0, left))
            const typing = left > 0 && left < full.length
            if (!shown) return null
            return (
              <span key={i} className="block">
                {"cmd" in l ? (
                  <>
                    <span className="text-muted-foreground select-none">$ </span>
                    {shown}
                  </>
                ) : (
                  <span className="text-muted-foreground">{shown}</span>
                )}
                {typing && <span className="animate-caret ml-px inline-block h-4 w-[7px] translate-y-0.5 bg-muted-foreground" />}
              </span>
            )
          })}
          {budget >= total && (
            <span className="block text-body">
              ✓ <span className="text-muted-foreground">{tab === 0 ? "Then pull the models." : "Then open Gel."}</span>
            </span>
          )}
        </span>
      </pre>
    </div>
  )
}
