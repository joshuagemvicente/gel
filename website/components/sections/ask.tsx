import { LauncherDemo } from "@/components/launcher-demo"
import { Reveal, Section } from "@/components/section"

// Search and cited answers: a supporting feature since the redaction-first positioning.
export function Ask() {
  return (
    <Section
      id="ask"
      eyebrow="Also in Gel"
      title="Ask your files, and see the page it came from."
      intro={
        <p>
          Press <span className="font-mono text-[15px]">⌥Space</span> and ask in English or Taglish. Gel answers from
          your documents with numbered sources, using the same local models.
        </p>
      }
      side={
        <Reveal delay={0.05} className="flex w-full flex-col gap-3 lg:w-[520px] lg:pt-2">
          <LauncherDemo />
          <p className="text-center text-[13px] text-muted-foreground">
            The launcher, recreated with Gel&apos;s synthetic sample files.
          </p>
        </Reveal>
      }
    />
  )
}
