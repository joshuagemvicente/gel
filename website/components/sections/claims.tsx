import { FileSearchIcon, LockKeyholeIcon, ShieldAlertIcon } from "lucide-react"

import { Container, Reveal } from "@/components/section"

const CLAIMS = [
  {
    icon: FileSearchIcon,
    title: "Answers with sources.",
    body: "Ask in English or Taglish. Gel searches your PDFs, scans and Word files, then cites the passage each part of the answer came from.",
  },
  {
    icon: LockKeyholeIcon,
    title: "Personal data stays here.",
    body: "Search, OCR, answers and redaction run on your Mac with local models. Redacting writes a new file and leaves the original alone.",
  },
  {
    icon: ShieldAlertIcon,
    title: "Leaks caught before you paste.",
    body: "Copy an employee record and switch to a chat app in your browser: Gel warns you what it holds and offers a redacted version to paste.",
  },
]

export function Claims() {
  return (
    <section aria-labelledby="claims-title" className="border-y bg-card/60">
      <h2 id="claims-title" className="sr-only">
        What Gel does
      </h2>
      <Container className="grid grid-cols-1 gap-px py-4 sm:grid-cols-3 sm:py-0">
        {CLAIMS.map((c, i) => (
          <Reveal key={c.title} delay={i * 0.035} className="py-6 sm:px-6 sm:py-10 sm:first:pl-0 sm:last:pr-0">
            <span className="flex size-8 items-center justify-center rounded-lg bg-accent text-accent-foreground">
              <c.icon className="size-4" aria-hidden />
            </span>
            <h3 className="mt-4 text-h3">{c.title}</h3>
            <p className="mt-2 text-[15px] leading-6 text-pretty text-muted-foreground">{c.body}</p>
          </Reveal>
        ))}
      </Container>
    </section>
  )
}
