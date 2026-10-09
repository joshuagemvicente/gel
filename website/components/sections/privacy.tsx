import { CheckIcon } from "lucide-react"

import { Reveal, Section } from "@/components/section"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"

// From docs/project/demo-and-submission.md → "Runs locally vs needs internet". Voice is left out until it is verified.
const ROWS: { task: string; local: string; internet: string }[] = [
  { task: "Finding personal data", local: "Patterns, Apple NaturalLanguage, local model", internet: "No" },
  { task: "Redaction and Leak Guard", local: "On your Mac", internet: "No" },
  { task: "Reading scans (OCR)", local: "Apple Vision", internet: "No" },
  {
    task: "Answers",
    local: "Qwen3 4B via Ollama",
    internet: "Only if you turn on a cloud fallback, with redacted text",
  },
  { task: "Search", local: "BGE-M3 via Ollama, SQLite", internet: "No" },
  { task: "First model download", local: "—", internet: "Once, during setup" },
]

export function Privacy() {
  return (
    <Section
      id="privacy"
      eyebrow="Privacy"
      title="Your files never leave your Mac."
      intro={
        <>
          <p>
            Your documents carry ID numbers, bank details and home addresses. Gel finds and blacks them out on your
            Mac, so a file never has to be uploaded to be redacted.
          </p>
          <ul className="mt-6 space-y-3 text-small">
            <li>
              <strong className="font-medium text-foreground">Cloud fallback is off by default.</strong> If you turn it
              on, Gel uses your own OpenAI-compatible endpoint for answers only, and redacts the text first.
            </li>
            <li>
              <strong className="font-medium text-foreground">Counts, never content.</strong> Leak Guard&apos;s log
              keeps counts and categories, never what you copied.
            </li>
          </ul>
        </>
      }
    >
      <Reveal>
        <div className="overflow-hidden rounded-xl border bg-card">
          <Table>
            <caption className="sr-only">What runs on your Mac and what needs the internet</caption>
            <TableHeader>
              <TableRow className="bg-popover hover:bg-popover">
                <TableHead className="h-11 pl-5 text-[13px] text-muted-foreground">Task</TableHead>
                <TableHead className="h-11 text-[13px] text-muted-foreground">On your Mac</TableHead>
                <TableHead className="h-11 pr-5 text-[13px] text-muted-foreground">Internet</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {ROWS.map((r) => (
                <TableRow key={r.task} className="text-small hover:bg-transparent">
                  <TableCell className="py-3.5 pl-5 font-medium whitespace-normal text-foreground">{r.task}</TableCell>
                  <TableCell className="py-3.5 whitespace-normal text-body">
                    {r.local !== "—" && (
                      <CheckIcon className="mr-1.5 inline size-3.5 -translate-y-px text-body" aria-hidden />
                    )}
                    {r.local}
                  </TableCell>
                  <TableCell className="py-3.5 pr-5 whitespace-normal text-muted-foreground">{r.internet}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      </Reveal>
    </Section>
  )
}
