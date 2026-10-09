import { ArrowRightIcon } from "lucide-react"

import { DownloadButton } from "@/components/download-button"
import { PasteCatchDemo } from "@/components/paste-catch-demo"
import { Container, Reveal } from "@/components/section"
import { metaLine } from "@/lib/release"

// The on-device components, from the footer disclosures and demo-and-submission.md. Text, not logos.
// WhisperKit stays off until voice is verified.
const RUNS_ON = ["Ollama", "Qwen3 4B", "BGE-M3", "Apple Vision", "NaturalLanguage", "SQLite FTS5"]

export function Hero() {
  return (
    <section id="top" aria-labelledby="hero-title" className="pt-16 pb-16 sm:pt-24 sm:pb-24">
      <Container>
        <Reveal>
          <p className="eyebrow">For everyone who pastes work into AI</p>
          <h1 id="hero-title" className="mt-5 text-hero text-balance">
            <span className="block">Use AI without leaking</span>
            <span className="block">personal&nbsp;data.</span>
          </h1>
        </Reveal>
        <div className="mt-8 grid grid-cols-1 gap-8 lg:grid-cols-[minmax(0,1fr)_auto] lg:items-end lg:gap-16">
          <Reveal delay={0.05}>
            <p className="max-w-xl text-body text-pretty">
              You paste a record into an AI chat to get help, and the ID numbers go with it. Gel warns you before
              personal data reaches the chat and offers a redacted copy to paste. For files, it saves a copy with the
              personal data blacked out. It all runs on your Mac.
            </p>
            <p className="mt-4 font-mono text-xs tracking-[-0.013em] text-muted-foreground">{metaLine}</p>
          </Reveal>
          <Reveal delay={0.1} className="flex flex-wrap items-center gap-x-6 gap-y-3">
            <DownloadButton />
            <a
              href="#install"
              className="group inline-flex items-center gap-1.5 rounded-md text-sm text-body outline-none transition-colors duration-150 hover:text-foreground focus-visible:ring-3 focus-visible:ring-ring/50"
            >
              Install guide
              <ArrowRightIcon
                className="size-4 transition-transform duration-150 ease-standard group-hover:translate-x-0.5"
                aria-hidden
              />
            </a>
          </Reveal>
        </div>
      </Container>

      <Reveal delay={0.15} className="mx-auto mt-12 w-full max-w-[1280px] px-4 sm:mt-16 sm:px-6">
        <div className="hero-floor rounded-xl border px-4 py-10 sm:px-6 sm:py-16">
          <div className="mx-auto max-w-[880px]">
            <PasteCatchDemo />
          </div>
        </div>
        <p className="mt-3 text-center text-[13px] text-muted-foreground">
          Leak Guard, recreated: a synthetic employee record was just copied. The list is Gel&apos;s real output for
          that sample.
        </p>
      </Reveal>

      <Container className="mt-12 sm:mt-16">
        <Reveal className="flex flex-col gap-4 lg:flex-row lg:items-baseline lg:gap-12">
          <p className="shrink-0 text-[13px] text-muted-foreground">Runs on your Mac with</p>
          <ul aria-label="On-device components" className="flex flex-wrap gap-x-8 gap-y-2 sm:gap-x-12">
            {RUNS_ON.map((name) => (
              <li key={name} className="text-[15px] font-medium tracking-[-0.011em] text-muted-foreground">
                {name}
              </li>
            ))}
          </ul>
        </Reveal>
      </Container>
    </section>
  )
}
