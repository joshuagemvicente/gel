import { BlurFade } from "@/components/ui/blur-fade"
import { cn } from "@/lib/utils"

export function Container({ className, children }: { className?: string; children: React.ReactNode }) {
  return <div className={cn("mx-auto w-full max-w-[1120px] px-4 sm:px-6", className)}>{children}</div>
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

export function Section({
  id,
  eyebrow,
  title,
  intro,
  band = false,
  className,
  children,
}: {
  id: string
  eyebrow: string
  title: React.ReactNode
  intro?: React.ReactNode
  band?: boolean
  className?: string
  children: React.ReactNode
}) {
  return (
    <section
      id={id}
      aria-labelledby={`${id}-title`}
      className={cn("py-16 sm:py-24", band && "bg-band", className)}
    >
      <Container>
        <Reveal className="max-w-2xl">
          <p className="eyebrow">{eyebrow}</p>
          <h2 id={`${id}-title`} className="mt-3 text-h2 text-balance">
            {title}
          </h2>
          {intro && <p className="mt-4 text-body text-pretty text-muted-foreground">{intro}</p>}
        </Reveal>
        <div className="mt-10 sm:mt-12">{children}</div>
      </Container>
    </section>
  )
}
