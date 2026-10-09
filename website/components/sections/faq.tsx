import { Reveal, Section } from "@/components/section"
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "@/components/ui/accordion"

const REQUIREMENTS = [
  ["Mac", "Apple silicon (M1 or newer)"],
  ["macOS", "15 Sequoia or later"],
  ["Memory", "16 GB recommended"],
  ["Disk", "About 8 GB free for the models and the index"],
  ["Also needs", "Ollama, installed in step 4"],
]

const FAQ = [
  {
    q: "Why does macOS say it can't verify Gel?",
    a: "This demo is ad-hoc signed and not notarized by Apple, so Gatekeeper asks you to confirm it once. Check the SHA-256 above, then use Open Anyway in System Settings → Privacy & Security.",
  },
  {
    q: "Which models does Gel use?",
    a: "Qwen3 4B Instruct 2507 (Q4_K_M) for answers and BGE-M3 for search, both running in Ollama on your Mac. Scanned pages are read with Apple's Vision framework.",
  },
  {
    q: "Does anything go to the cloud?",
    a: "Not unless you set it up. The cloud fallback is off by default. If you turn it on, it only sends redacted text, for answers, to an endpoint you supply.",
  },
  {
    q: "Can I try it without my own files?",
    a: "Yes. The DMG includes Gel Sample Files: synthetic HR documents (resumes, payslips, contracts, scans) and a sample employee record for testing Leak Guard. No real people's data is included.",
  },
  {
    q: "Does it run on Intel Macs?",
    a: "No. This build is for Apple silicon (arm64) only.",
  },
  {
    q: "How do I uninstall it?",
    a: "Quit Gel and move it from Applications to the Trash. Its index lives in ~/Library/Application Support/Gel; delete that folder too. To remove the models, run ollama rm qwen3:4b-instruct-2507-q4_K_M and ollama rm bge-m3.",
  },
]

export function Faq() {
  return (
    <Section id="faq" eyebrow="Before you start" title="Requirements and questions.">
      <div className="grid grid-cols-1 items-start gap-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.6fr)] lg:gap-14">
        <Reveal>
          <div id="requirements" className="rounded-xl border bg-card p-5">
            <h3 className="text-h3">Requirements</h3>
            <dl className="mt-4 divide-y text-[15px]">
              {REQUIREMENTS.map(([k, v]) => (
                <div key={k} className="flex justify-between gap-4 py-2.5">
                  <dt className="text-muted-foreground">{k}</dt>
                  <dd className="text-right">{v}</dd>
                </div>
              ))}
            </dl>
            <p className="mt-4 text-sm leading-5 text-muted-foreground">Intel Macs aren&apos;t supported.</p>
          </div>
        </Reveal>
        <Reveal delay={0.05}>
          <Accordion className="rounded-xl border bg-card px-5">
            {FAQ.map((item) => (
              <AccordionItem key={item.q} value={item.q}>
                <AccordionTrigger className="py-4 text-[15px] font-medium hover:no-underline">{item.q}</AccordionTrigger>
                <AccordionContent className="pb-4 text-[15px] leading-6 text-pretty text-muted-foreground">
                  {item.a}
                </AccordionContent>
              </AccordionItem>
            ))}
          </Accordion>
        </Reveal>
      </div>
    </Section>
  )
}
