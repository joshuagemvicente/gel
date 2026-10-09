import { CheckIcon } from "lucide-react"

import { LeakOverlay } from "@/components/leak-overlay"
import { Reveal, Section } from "@/components/section"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"

// From docs/project/demo-and-submission.md → "Runs locally vs needs internet". Voice is left out until it is verified.
const ROWS: { task: string; local: string; internet: string }[] = [
  { task: "Reading scans (OCR)", local: "Apple Vision", internet: "No" },
  { task: "Search", local: "BGE-M3 via Ollama, SQLite", internet: "No" },
  {
    task: "Answers",
    local: "Qwen3 4B via Ollama",
    internet: "Only if you turn on a cloud fallback, with redacted text",
  },
  { task: "Finding personal data", local: "Patterns, Apple NaturalLanguage, local model", internet: "No" },
  { task: "Redaction and Leak Guard", local: "On your Mac", internet: "No" },
  { task: "First model download", local: "—", internet: "Once, during setup" },
]

export function Privacy() {
  return (
    <Section
      id="privacy"
      eyebrow="Privacy"
      title="Your files never leave your Mac."
      intro="HR files and personal documents carry government ID numbers, salaries and home addresses. Gel does that work on your Mac instead of sending it to a cloud AI."
    >
      <div className="grid grid-cols-1 items-start gap-10 lg:grid-cols-[minmax(0,1.35fr)_minmax(0,1fr)] lg:gap-14">
        <Reveal>
          <div className="overflow-hidden rounded-xl border bg-card">
            <Table>
              <caption className="sr-only">What runs on your Mac and what needs the internet</caption>
              <TableHeader>
                <TableRow className="bg-band hover:bg-band">
                  <TableHead className="pl-4">Task</TableHead>
                  <TableHead>On your Mac</TableHead>
                  <TableHead className="pr-4">Internet</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {ROWS.map((r) => (
                  <TableRow key={r.task} className="hover:bg-transparent">
                    <TableCell className="py-3 pl-4 font-medium whitespace-normal">{r.task}</TableCell>
                    <TableCell className="py-3 whitespace-normal text-muted-foreground">
                      {r.local !== "—" && (
                        <CheckIcon className="mr-1.5 inline size-3.5 -translate-y-px text-accent-foreground" aria-hidden />
                      )}
                      {r.local}
                    </TableCell>
                    <TableCell className="py-3 pr-4 whitespace-normal text-muted-foreground">{r.internet}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
          <ul className="mt-6 space-y-3 text-[15px] leading-6 text-muted-foreground">
            <li>
              <strong className="font-medium text-foreground">Cloud fallback is off by default.</strong> If you turn it
              on, Gel uses your own OpenAI-compatible endpoint for answers only, and redacts the text first.
            </li>
            <li>
              <strong className="font-medium text-foreground">Counts, never content.</strong> Leak Guard&apos;s log
              keeps counts and categories, never what you copied.
            </li>
          </ul>
        </Reveal>
        <Reveal delay={0.05} className="flex flex-col items-center gap-3 lg:pt-6">
          <LeakOverlay />
          <p className="max-w-[380px] text-center text-xs text-muted-foreground">
            Leak Guard after copying a synthetic employee record in Chrome. The list is Gel&apos;s real output for that
            sample.
          </p>
        </Reveal>
      </div>
    </Section>
  )
}
