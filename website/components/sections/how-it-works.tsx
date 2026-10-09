import { FolderIcon } from "lucide-react"

import { GelDrop } from "@/components/gel-drop"
import { Reveal, Section } from "@/components/section"

const FOLDERS = ["201 Files", "Contracts", "Payslips", "Resumes", "Scans"]

function FoldersVisual() {
  return (
    <div className="rounded-xl border bg-card p-3 text-sm">
      <p className="px-1 pb-2 text-xs text-muted-foreground">Gel Sample Files / HR Files</p>
      <ul className="space-y-0.5">
        {FOLDERS.map((f) => (
          <li key={f} className="flex items-center gap-2 rounded-md px-1 py-1">
            <FolderIcon className="size-4 text-accent-foreground" aria-hidden />
            {f}
          </li>
        ))}
      </ul>
      <p className="mt-2 flex items-center gap-2 border-t px-1 pt-2.5 text-xs text-muted-foreground">
        <span className="size-1.5 rounded-full bg-primary" aria-hidden />
        58 files ready
      </p>
    </div>
  )
}

function Key({ children, wide = false }: { children: React.ReactNode; wide?: boolean }) {
  return (
    <kbd
      className={`inline-flex h-12 items-center justify-center rounded-lg border border-b-[3px] bg-card font-sans text-lg text-foreground ${wide ? "w-36" : "w-12"}`}
    >
      {children}
    </kbd>
  )
}

function AskVisual() {
  return (
    <div className="flex h-full min-h-[184px] flex-col items-center justify-center gap-4 rounded-xl border bg-card p-4">
      <div className="flex items-center gap-2" aria-hidden>
        <Key>⌥</Key>
        <Key wide>Space</Key>
      </div>
      <div className="flex w-full max-w-60 items-center gap-2 rounded-lg border bg-background px-3 py-2 text-xs text-muted-foreground">
        <GelDrop className="size-3.5" />
        Ask your files…
      </div>
    </div>
  )
}

function PassageVisual() {
  return (
    <div className="flex h-full min-h-[184px] flex-col rounded-xl border bg-card p-4">
      <div className="space-y-2" aria-hidden>
        <div className="h-2 w-3/4 rounded-full bg-border" />
        <div className="h-2 w-full rounded-full bg-border" />
        <div className="-mx-1 space-y-2 rounded-md bg-accent px-1 py-1.5 ring-1 ring-primary/40">
          <div className="h-2 w-full rounded-full bg-primary/35" />
          <div className="h-2 w-5/6 rounded-full bg-primary/35" />
        </div>
        <div className="h-2 w-11/12 rounded-full bg-border" />
        <div className="h-2 w-2/3 rounded-full bg-border" />
      </div>
      <p className="mt-auto inline-flex w-fit items-center gap-1.5 rounded-full bg-accent px-2.5 py-1 text-xs font-medium text-accent-foreground">
        Cited passage · Resume_REYES.pdf, page 2
      </p>
    </div>
  )
}

const STEPS = [
  {
    title: "Choose a folder",
    body: "Point Gel at a folder of documents. It reads PDFs, scanned pages, images and Word files, using on-device OCR for scans, and keeps the index on your Mac.",
    visual: <FoldersVisual />,
  },
  {
    title: "Ask from anywhere",
    body: "Press ⌥Space and a launcher opens at the top of the screen. Type a question; the answer streams in with numbered sources.",
    visual: <AskVisual />,
  },
  {
    title: "Open the cited passage",
    body: "Click a citation and Gel opens the document at that page, with the passage it used highlighted.",
    visual: <PassageVisual />,
  },
]

export function HowItWorks() {
  return (
    <Section
      id="how-it-works"
      band
      eyebrow="How it works"
      title="From a folder to an answer you can check."
      intro="Every answer points back to your own documents, so you can see where it came from."
    >
      <ol className="grid grid-cols-1 gap-8 md:grid-cols-3 md:gap-6">
        {STEPS.map((s, i) => (
          <li key={s.title}>
            <Reveal delay={i * 0.035} className="flex h-full flex-col">
              {s.visual}
              <p className="mt-5 font-mono text-xs text-muted-foreground">0{i + 1}</p>
              <h3 className="mt-1 text-h3">{s.title}</h3>
              <p className="mt-2 text-[15px] leading-6 text-pretty text-muted-foreground">{s.body}</p>
            </Reveal>
          </li>
        ))}
      </ol>
    </Section>
  )
}
