import { DownloadButton } from "@/components/download-button"
import { LauncherDemo } from "@/components/launcher-demo"
import { Container, Reveal } from "@/components/section"
import { buttonVariants } from "@/components/ui/button"
import { metaLine } from "@/lib/release"
import { cn } from "@/lib/utils"

export function Hero() {
  return (
    <section id="top" aria-labelledby="hero-title" className="relative overflow-hidden pt-12 pb-20 sm:pt-20 sm:pb-28">
      <div className="dot-field pointer-events-none absolute inset-0" aria-hidden />
      <Container className="relative grid grid-cols-1 items-center gap-12 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.05fr)] lg:gap-16">
        <div>
          <Reveal>
            <p className="eyebrow">Private AI for your Mac</p>
            <h1 id="hero-title" className="mt-4 text-hero text-balance">
              Ask your files. Keep&nbsp;them on your Mac.
            </h1>
          </Reveal>
          <Reveal delay={0.05}>
            <p className="mt-5 max-w-xl text-body text-pretty text-muted-foreground">
              Gel answers questions about your own documents with citations, redacts personal data, and catches it
              before you paste it into a cloud AI. The models run on your Mac.
            </p>
          </Reveal>
          <Reveal delay={0.1} className="mt-8 flex flex-wrap items-center gap-3">
            <DownloadButton />
            <a
              href="#install"
              className={cn(
                buttonVariants({ variant: "outline", size: "lg" }),
                "h-10 rounded-md bg-card px-4 transition-[background-color,transform] duration-150 ease-standard active:scale-[0.97] dark:bg-card",
              )}
            >
              Install guide
            </a>
          </Reveal>
          <Reveal delay={0.12}>
            <p className="mt-4 font-mono text-xs text-muted-foreground">{metaLine}</p>
          </Reveal>
        </div>
        <Reveal delay={0.15} className="relative">
          <LauncherDemo />
          <p className="mt-3 text-center text-xs text-muted-foreground">
            The launcher (⌥Space), recreated with Gel&apos;s synthetic sample files.
          </p>
        </Reveal>
      </Container>
    </section>
  )
}
