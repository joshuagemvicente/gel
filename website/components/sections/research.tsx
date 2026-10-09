import { Reveal, Section } from "@/components/section"

// Cyberhaven Labs research, quoted only as Cyberhaven's own pages state it (checked Oct 10, 2026; decision D-079).
// Cyberhaven's pages don't mention HR records, so the page doesn't attribute that to them.
const SOURCES = [
  {
    n: 1,
    title: "Cyberhaven Labs, 2026 AI Adoption & Risk Report (Feb 5, 2026)",
    href: "https://www.cyberhaven.com/resources/research/ai-adoption-risk-report-2026",
  },
  {
    n: 2,
    title: "Cyberhaven, “Sensitive Enterprise Data Is Flowing Into AI Tools at Scale” (Feb 11, 2026)",
    href: "https://www.cyberhaven.com/blog/sensitive-data-flowing-into-ai-tools",
  },
  {
    n: 3,
    title: "Cyberhaven, “AI Insider Threats” (updated Mar 18, 2026)",
    href: "https://www.cyberhaven.com/blog/insider-threats-in-the-age-of-ai",
  },
]

const STATS = [
  {
    value: "39.7%",
    body: "of all AI interactions involve sensitive data, counting prompts, copy-paste and file uploads.",
    source: 1,
  },
  {
    value: "3 days",
    body: "is how often, on average, an employee puts sensitive data into an AI tool.",
    source: 2,
  },
  {
    value: "32.3%",
    body: "of ChatGPT use happens through personal accounts, outside company accounts. For Claude it's 58.2%, for Perplexity 60.9%.",
    source: 2,
  },
  {
    value: "82%",
    body: "of the 100 most-used AI apps are rated medium, high or critical risk.",
    source: 1,
  },
]

function Cite({ n }: { n: number }) {
  return (
    <a
      href={`#source-${n}`}
      aria-label={`Source ${n}`}
      className="ml-0.5 rounded-sm align-super font-mono text-[11px] text-muted-foreground no-underline outline-none hover:text-foreground focus-visible:ring-3 focus-visible:ring-ring/50"
    >
      [{n}]
    </a>
  )
}

export function Research() {
  return (
    <Section
      id="research"
      eyebrow="The research"
      title="Most leaks into AI aren't malicious. They're copy and paste."
      intro={
        <>
          <p>
            Cyberhaven Labs tracked billions of data movements into AI tools at 222 companies for its 2026 AI Adoption &
            Risk Report. People paste records into a chat to get everyday work done, and the personal data goes with
            them.
          </p>
          <blockquote className="mt-6 border-l-2 border-border-strong pl-4 text-small">
            <p className="text-foreground">&ldquo;AI-related threats are almost always unintentional.&rdquo;</p>
            <footer className="mt-1 text-[13px] text-muted-foreground">
              Cyberhaven
              <Cite n={3} />
            </footer>
          </blockquote>
        </>
      }
      aside
    >
      <ul className="divide-y divide-border">
        {STATS.map((s, i) => (
          <li key={s.value} className="py-6 first:pt-0 last:pb-0 lg:py-8">
            <Reveal delay={i * 0.035} className="grid grid-cols-1 gap-x-8 gap-y-2 sm:grid-cols-[minmax(0,13rem)_minmax(0,1fr)] sm:items-baseline">
              <p className="text-h2 tabular-nums">{s.value}</p>
              <p className="text-small text-pretty text-body">
                {s.body}
                <Cite n={s.source} />
              </p>
            </Reveal>
          </li>
        ))}
      </ul>
      <Reveal>
        <p className="mt-10 text-body text-pretty">
          Gel sits at that moment: <span className="text-foreground">the paste and the upload</span>. It catches personal
          data on your clipboard before it reaches an AI chat, and blacks it out of files before you share them.
        </p>
        <ol className="mt-8 space-y-1.5 border-t pt-6 text-[13px] text-muted-foreground">
          {SOURCES.map((s) => (
            <li key={s.n} id={`source-${s.n}`} className="scroll-mt-24">
              <span className="font-mono">[{s.n}]</span>{" "}
              <a href={s.href} className="text-body underline underline-offset-4 hover:text-foreground">
                {s.title}
              </a>
            </li>
          ))}
        </ol>
      </Reveal>
    </Section>
  )
}
