"use client"

import { motion, useInView } from "motion/react"
import { useRef } from "react"

import { usePrefersReducedMotion } from "@/hooks/use-prefers-reduced-motion"
import { cn } from "@/lib/utils"

// Gel's redaction review (RedactionsView + RedactReview), recreated for page 1 of the synthetic Resume_REYES.pdf.
// Values are the file's page-1 entries in demo-data/ground_truth.json; the header and button count all 16 in the file.
// A product frame: the app's own dark colours (--app-*), with the document on white paper.
type Seg = string | { pii: string }
type Line = { segs: Seg[]; kind?: "name" | "role" | "heading" }

const PAGE: Line[] = [
  { kind: "name", segs: [{ pii: "KRISTINE JOY MANALO REYES" }] },
  { kind: "role", segs: ["Payroll Specialist"] },
  { segs: [{ pii: "101 Sampaguita St., Brgy. Dela Paz, Antipolo City, Rizal 1870" }] },
  { segs: [{ pii: "0966 174 4548" }, " · ", { pii: "kristine.reyes@sulat.example" }] },
  { segs: ["Date of birth: ", { pii: "April 18, 1991" }] },
  { kind: "heading", segs: ["Government IDs"] },
  { segs: ["SSS ", { pii: "25-6708763-7" }, "   TIN ", { pii: "320-398-458-000" }] },
  { segs: ["PhilHealth ", { pii: "03-376137895-6" }, "   Pag-IBIG ", { pii: "1861-6116-9066" }] },
  { segs: ["Expected salary: ", { pii: "₱45,000.00" }] },
  { kind: "heading", segs: ["Experience"] },
]

// Each finding's position in reading order, so the black bars arrive top to bottom.
const ORDER = new Map<Seg, number>()
PAGE.flatMap((l) => l.segs).filter((s) => typeof s !== "string").forEach((s, i) => ORDER.set(s, i))

function Page({ after, shown, reduce }: { after: boolean; shown: boolean; reduce: boolean }) {
  return (
    <div className="rounded-sm bg-app-page px-4 py-4 text-[10px] leading-[1.7] text-app-ink sm:text-[11px]">
      {PAGE.map((line, i) => (
        <p
          key={i}
          className={cn(
            line.kind === "name" && "text-[12px] font-semibold tracking-[0.01em] sm:text-[13px]",
            line.kind === "role" && "mb-1.5 text-app-ink-soft",
            line.kind === "heading" && "mt-2 border-b border-app-ink/15 pb-0.5 font-semibold",
          )}
        >
          {line.segs.map((seg, j) =>
            typeof seg === "string" ? (
              <span key={j} className="whitespace-pre-wrap">
                {seg}
              </span>
            ) : after && reduce ? (
              <span key={j} className="bg-app-ink text-transparent select-none">
                {seg.pii}
              </span>
            ) : after ? (
              <motion.span
                key={j}
                initial={false}
                animate={{ opacity: shown ? 1 : 0.15 }}
                transition={{ duration: 0.18, delay: shown ? (ORDER.get(seg) ?? 0) * 0.09 : 0 }}
                className="bg-app-ink text-transparent select-none"
              >
                {seg.pii}
              </motion.span>
            ) : (
              <span key={j} className="bg-app-danger/15 ring-1 ring-app-danger/70">
                {seg.pii}
              </span>
            ),
          )}
        </p>
      ))}
      <div className="mt-2 space-y-1.5" aria-hidden>
        <div className="h-1.5 w-11/12 rounded-full bg-app-ink/10" />
        <div className="h-1.5 w-4/5 rounded-full bg-app-ink/10" />
      </div>
    </div>
  )
}

export function RedactReviewDemo() {
  const ref = useRef<HTMLDivElement>(null)
  const inView = useInView(ref, { once: true, margin: "-80px" })
  const reduce = usePrefersReducedMotion()
  const shown = reduce || inView

  return (
    <div
      ref={ref}
      role="img"
      aria-label="Gel's redaction review for a synthetic résumé: on the left the original page with 10 findings outlined in red, on the right the saved copy with the same 10 blacked out. Header: Gel will black out 16 of 16 items in 1 file. Button: Black out 16 items, Save 1 copy."
      className="w-full overflow-hidden rounded-xl border border-app-hairline bg-app-card text-left text-app-text shadow-frame"
    >
      <div className="border-b border-app-hairline px-4 py-3">
        <p className="text-sm">
          Gel will black out <strong className="font-semibold">16 of 16</strong> items in 1 file.
        </p>
        <p className="mt-0.5 text-xs leading-5 text-app-text-secondary">
          Untick anything you want to keep visible. Your original files are never changed; redacted copies are saved
          to a Redacted folder.
        </p>
      </div>
      <div className="grid grid-cols-1 gap-4 bg-app-canvas p-3 sm:grid-cols-2 sm:p-4">
        <div>
          <p className="mb-2 text-xs">
            <span className="font-semibold">Before</span>
            <span className="text-app-text-secondary"> · your original, unchanged</span>
          </p>
          <Page after={false} shown={shown} reduce={reduce} />
        </div>
        <div>
          <p className="mb-2 text-xs">
            <span className="font-semibold">After</span>
            <span className="text-app-text-secondary"> · exactly what the saved copy will look like</span>
          </p>
          <Page after shown={shown} reduce={reduce} />
        </div>
      </div>
      <div className="flex flex-wrap items-center justify-between gap-3 border-t border-app-hairline px-4 py-3">
        <p className="font-mono text-[11px] text-app-text-secondary">Page 1 of 2 · Resume_REYES.pdf</p>
        <span className="inline-flex h-7 items-center rounded-md bg-app-accent-fill px-3 text-xs font-medium text-white">
          Black out 16 items · Save 1 copy
        </span>
      </div>
    </div>
  )
}
