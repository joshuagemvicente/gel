import { GelDrop } from "@/components/gel-drop"
import { Container } from "@/components/section"
import { release } from "@/lib/release"

export function Footer() {
  return (
    <footer className="border-t border-border-strong py-12 text-[13px] text-muted-foreground">
      <Container className="grid gap-8 md:grid-cols-[1fr_auto]">
        <div className="space-y-3">
          <p className="flex items-center gap-2 text-base font-medium text-foreground">
            <GelDrop className="size-5" />
            Gel
          </p>
          <p>Built for the AppBuildersPH Hackathon 2026 by Team 12M.</p>
          <p className="max-w-2xl text-xs leading-5 text-muted-foreground">
            Models: Qwen3 4B Instruct 2507 and BGE-M3 through Ollama. Built with Swift, SwiftUI, AppKit, PDFKit, Vision,
            NaturalLanguage and SQLite FTS5. Sample files are synthetic.
          </p>
        </div>
        <div className="space-y-2 font-mono text-xs tracking-[-0.013em] md:text-right">
          <p>Build {release.build}</p>
          <p className="break-all md:max-w-[34ch] md:break-normal md:[overflow-wrap:anywhere]">
            SHA-256 {release.sha256}
          </p>
          <p>
            <a href={release.repoUrl} className="text-body underline underline-offset-4 hover:text-foreground">
              Source on GitHub
            </a>
          </p>
        </div>
      </Container>
    </footer>
  )
}
