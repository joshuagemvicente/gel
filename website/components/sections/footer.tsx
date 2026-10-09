import { GelDrop } from "@/components/gel-drop"
import { Container } from "@/components/section"
import { release } from "@/lib/release"

export function Footer() {
  return (
    <footer className="border-t py-12 text-sm text-muted-foreground">
      <Container className="grid gap-8 md:grid-cols-[1fr_auto]">
        <div className="space-y-3">
          <p className="flex items-center gap-2 text-base font-semibold text-foreground">
            <GelDrop className="size-5" />
            Gel
          </p>
          <p>Built for the AppBuildersPH Hackathon 2026 by Team 12M.</p>
          <p className="max-w-2xl text-xs leading-5">
            Models: Qwen3 4B Instruct 2507 and BGE-M3 through Ollama. Built with Swift, SwiftUI, AppKit, PDFKit, Vision,
            NaturalLanguage and SQLite FTS5. Sample files are synthetic.
          </p>
        </div>
        <div className="space-y-2 font-mono text-xs md:text-right">
          <p>Build {release.build}</p>
          <p className="break-all md:max-w-[34ch] md:break-normal md:[overflow-wrap:anywhere]">
            SHA-256 {release.sha256}
          </p>
          <p>
            <a href={release.repoUrl} className="text-accent-foreground underline-offset-4 hover:underline">
              Source on GitHub
            </a>
          </p>
        </div>
      </Container>
    </footer>
  )
}
