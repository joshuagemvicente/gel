import { CheckIcon, FileTextIcon, FolderIcon } from "lucide-react"

import { RedactReviewDemo } from "@/components/redact-review-demo"
import { Reveal, Section } from "@/components/section"
import { cn } from "@/lib/utils"

// The redact flow (docs/features/redactions-module/spec.md), with the app's own labels and synthetic sample files.
const RESUMES = [
  { name: "Resume_REYES.pdf", picked: true },
  { name: "Santos_Rodel_Resume.pdf", picked: true },
  { name: "CV - Patricia Anne Cruz.pdf", picked: true },
  { name: "CV - Rommel Valdez.pdf", picked: false },
]

const FINDINGS = [
  { value: "25-6708763-7", label: "SSS", keep: false },
  { value: "0966 174 4548", label: "Phone", keep: true },
  { value: "₱45,000.00", label: "Salary", keep: false },
  { value: "April 18, 1991", label: "Birth date", keep: false },
]

const COPIES = ["Resume_REYES_REDACTED.pdf", "Santos_Rodel_Resume_REDACTED.pdf", "CV - Patricia Anne Cruz_REDACTED.pdf"]

function Card({ className, children }: { className?: string; children: React.ReactNode }) {
  return <div className={cn("rounded-xl border bg-card p-4 text-small", className)}>{children}</div>
}

function Box({ on }: { on: boolean }) {
  return (
    <span
      className={cn(
        "flex size-4 shrink-0 items-center justify-center rounded-sm border",
        on ? "border-body bg-body text-background" : "border-faint",
      )}
      aria-hidden
    >
      {on && <CheckIcon className="size-3" strokeWidth={3} />}
    </span>
  )
}

function SelectVisual() {
  return (
    <Card>
      <p className="px-1 pb-2 text-[13px] text-muted-foreground">Library · HR Files / Resumes</p>
      <ul className="space-y-0.5 text-body">
        {RESUMES.map((r) => (
          <li key={r.name} className="flex items-center gap-2.5 rounded-md px-1 py-1.5">
            <Box on={r.picked} />
            <FileTextIcon className="size-4 text-muted-foreground" aria-hidden />
            <span className="truncate">{r.name}</span>
          </li>
        ))}
      </ul>
      <div className="mt-2 flex justify-end border-t pt-3">
        <span className="inline-flex h-8 items-center rounded-md border px-3 text-[13px] text-foreground">
          Redact 3 files
        </span>
      </div>
    </Card>
  )
}

function ReviewVisual() {
  return (
    <Card>
      <p className="px-1 pb-2 text-[13px] text-body">
        Gel will black out <span className="font-medium text-foreground">15 of 16</span> items in 1 file.
      </p>
      <ul className="divide-y text-body">
        {FINDINGS.map((f) => (
          <li key={f.value} className="flex items-center gap-2.5 px-1 py-2">
            <Box on={!f.keep} />
            <span className={cn("font-mono text-[13px] tracking-[-0.013em]", f.keep && "text-muted-foreground line-through")}>
              {f.value}
            </span>
            <span className="text-[13px] text-muted-foreground">{f.label}</span>
            {f.keep && (
              <span className="ml-auto rounded-sm bg-accent px-1.5 text-xs text-muted-foreground">kept</span>
            )}
          </li>
        ))}
      </ul>
    </Card>
  )
}

function SaveVisual() {
  return (
    <Card>
      <p className="px-1 pb-2 text-[13px] text-muted-foreground">HR Files / Resumes / Redacted</p>
      <ul className="space-y-0.5 text-body">
        {COPIES.map((c) => (
          <li key={c} className="flex items-center gap-2.5 rounded-md px-1 py-1.5">
            <FileTextIcon className="size-4 text-muted-foreground" aria-hidden />
            <span className="truncate">{c}</span>
          </li>
        ))}
      </ul>
      <p className="mt-2 flex items-center gap-2 border-t px-1 pt-3 text-[13px] text-muted-foreground">
        <FolderIcon className="size-4" aria-hidden />
        Saved 3 redacted files. Originals are unchanged.
      </p>
    </Card>
  )
}

const STEPS = [
  {
    title: "Select the files",
    body: "In Gel's Library, select one file or several and click Redact. Gel checks every page on your Mac, scans included.",
    visual: <SelectVisual />,
  },
  {
    title: "Review Before and After",
    body: "Each page shows side by side: your original with every finding outlined, and exactly what the saved copy will look like. Untick anything you want to keep visible.",
    visual: <ReviewVisual />,
  },
  {
    title: "Save the redacted copies",
    body: "Gel saves a new file for each one in a Redacted folder next to the originals. Originals are never changed, and an earlier copy is never overwritten.",
    visual: <SaveVisual />,
  },
]

export function HowItWorks() {
  return (
    <Section
      id="how-it-works"
      eyebrow="How it works"
      title="Uploading the file itself? Send a redacted copy."
      intro="You check every item before anything is saved. The example below redacts résumés from Gel's HR sample files."
    >
      <Reveal className="mb-14 sm:mb-20">
        <RedactReviewDemo />
        <p className="mt-3 text-center text-[13px] text-muted-foreground">
          Gel&apos;s review screen, recreated with a synthetic résumé from the sample files.
        </p>
      </Reveal>
      <ol className="space-y-14 sm:space-y-20">
        {STEPS.map((s, i) => (
          <li key={s.title}>
            <Reveal className="grid grid-cols-1 items-center gap-6 lg:grid-cols-2 lg:gap-16">
              <div className="max-w-md">
                <p className="font-mono text-xs tracking-[-0.013em] text-muted-foreground">0{i + 1}</p>
                <h3 className="mt-2 text-h3">{s.title}</h3>
                <p className="mt-2 text-small text-pretty text-body">{s.body}</p>
              </div>
              {s.visual}
            </Reveal>
          </li>
        ))}
      </ol>
    </Section>
  )
}
