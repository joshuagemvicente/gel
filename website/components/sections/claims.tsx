import { FileSearchIcon, LockKeyholeIcon, ShieldAlertIcon } from "lucide-react"

import { Reveal, Section } from "@/components/section"

const CLAIMS = [
  {
    icon: ShieldAlertIcon,
    title: "Caught before you paste.",
    body: "Copy something with ID numbers or bank details in it and switch to an AI chat in your browser: Gel warns you what it holds and offers a copy with placeholders like [SSS_1] to paste instead.",
  },
  {
    icon: FileSearchIcon,
    title: "Finds the personal data for you.",
    body: "Government IDs (SSS, TIN, PhilHealth, Pag-IBIG, PhilSys), passports and driver's licenses, card, bank and GCash numbers, salaries, phone numbers, addresses and names, in text PDFs, scanned pages and photos. Patterns, Apple's name detection and a local AI model each take a pass.",
  },
  {
    icon: LockKeyholeIcon,
    title: "Blacked out for good, before you upload.",
    body: "Need to give an AI or a client the file itself? The redacted copy is rebuilt from page images with the boxes flattened in, so the blacked-out text can't be selected, searched or copied back out. Your original stays exactly as it was.",
  },
]

export function Claims() {
  return (
    <Section id="claims" title="What Gel does." aside>
      <ul className="divide-y divide-border">
        {CLAIMS.map((c, i) => (
          <li key={c.title} className="py-6 first:pt-0 last:pb-0 lg:py-8">
            <Reveal delay={i * 0.035} className="grid grid-cols-[16px_minmax(0,1fr)] gap-x-4">
              <c.icon className="mt-1.5 size-4 text-muted-foreground" aria-hidden />
              <div>
                <h3 className="text-h3">{c.title}</h3>
                <p className="mt-2 text-small text-pretty text-body">{c.body}</p>
              </div>
            </Reveal>
          </li>
        ))}
      </ul>
    </Section>
  )
}
