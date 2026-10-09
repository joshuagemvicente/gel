import { BriefcaseIcon, HouseIcon } from "lucide-react"

import { Reveal, Section } from "@/components/section"

// General positioning with HR as the worked example. The two rule sets are the bundled packs (Work: HR, Personal),
// chosen at onboarding (packs T1–T2, T4 and onboarding T2 verified).
const USES = [
  {
    icon: BriefcaseIcon,
    title: "Work: HR and admin teams",
    tag: "The example on this page",
    body: "Résumés, 201 files and payslips carry SSS, TIN and PhilHealth numbers and salaries. Black them out before the files go to a client, a vendor or an AI chat.",
  },
  {
    icon: HouseIcon,
    title: "Personal: your own documents",
    body: "Passports, driver's licenses, bank statements and GCash details. Keep the numbers out of an AI chat, or black them out before you send a loan, rental or job application.",
  },
]

export function Uses() {
  return (
    <Section
      id="uses"
      title="For anyone who asks AI for help with real documents."
      intro="When you set Gel up, pick the rules that fit: Work, Personal, or both."
      aside
    >
      <ul className="divide-y divide-border">
        {USES.map((u, i) => (
          <li key={u.title} className="py-6 first:pt-0 last:pb-0 lg:py-8">
            <Reveal delay={i * 0.035} className="grid grid-cols-[16px_minmax(0,1fr)] gap-x-4">
              <u.icon className="mt-1.5 size-4 text-muted-foreground" aria-hidden />
              <div>
                <h3 className="text-h3">{u.title}</h3>
                {u.tag && (
                  <span className="mt-2 inline-flex rounded-sm bg-accent px-1.5 text-xs text-muted-foreground">
                    {u.tag}
                  </span>
                )}
                <p className="mt-2 text-small text-pretty text-body">{u.body}</p>
              </div>
            </Reveal>
          </li>
        ))}
      </ul>
    </Section>
  )
}
