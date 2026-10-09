import { BlurFade } from "@/components/ui/blur-fade"
import { cn } from "@/lib/utils"

export function Container({ className, children }: { className?: string; children: React.ReactNode }) {
  return <div className={cn("mx-auto w-full max-w-[1200px] px-4 sm:px-6", className)}>{children}</div>
}

// Rise 8 px and fade once on view (design.md → Motion). Blur is kept light so text stays crisp mid-fade.
export function Reveal({
  delay = 0,
  className,
  children,
}: {
  delay?: number
  className?: string
  children: React.ReactNode
}) {
  return (
    <BlurFade inView direction="up" offset={8} blur="4px" duration={0.4} delay={delay} className={className}>
      {children}
    </BlurFade>
  )
}

// Every section opens with a Smoke rule and sits on the canvas (design.md → Layout).
// `aside` puts the heading in a sticky left column with the content on the right (≥1024 px).
// `side` sits beside the heading (≥1024 px), with the content full width below.
export function Section({
  id,
  eyebrow,
  title,
  intro,
  aside = false,
  side,
  className,
  children,
}: {
  id: string
  eyebrow?: string
  title: React.ReactNode
  intro?: React.ReactNode
  aside?: boolean
  side?: React.ReactNode
  className?: string
  children?: React.ReactNode
}) {
  const heading = (
    <Reveal className="max-w-2xl">
      {eyebrow && <p className="eyebrow">{eyebrow}</p>}
      <h2 id={`${id}-title`} className={cn("text-h2 text-balance", eyebrow && "mt-4")}>
        {title}
      </h2>
      {intro && <div className="mt-5 text-body text-pretty">{intro}</div>}
    </Reveal>
  )

  return (
    <section
      id={id}
      aria-labelledby={`${id}-title`}
      className={cn("border-t border-border-strong py-16 sm:py-24", className)}
    >
      <Container>
        {aside ? (
          <div className="grid grid-cols-1 gap-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.5fr)] lg:gap-16">
            <div className="lg:sticky lg:top-24 lg:self-start">{heading}</div>
            <div className="min-w-0">{children}</div>
          </div>
        ) : (
          <>
            {side ? (
              <div className="grid grid-cols-1 items-start gap-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,auto)] lg:gap-16">
                {heading}
                {side}
              </div>
            ) : (
              heading
            )}
            {children && <div className="mt-12 sm:mt-16">{children}</div>}
          </>
        )}
      </Container>
    </section>
  )
}
