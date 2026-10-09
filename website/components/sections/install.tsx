import Image from "next/image"

import { CommandSnippet } from "@/components/command-snippet"
import { DownloadButton } from "@/components/download-button"
import { InstallTerminal } from "@/components/install-terminal"
import { Reveal, Section } from "@/components/section"
import { metaLine, release } from "@/lib/release"

function Step({ n, title, children }: { n: number; title: string; children: React.ReactNode }) {
  return (
    <li className="relative grid grid-cols-[24px_1fr] gap-x-4 pb-14 last:pb-0 sm:gap-x-6">
      <span
        className="absolute top-8 bottom-0 left-[11.5px] w-px bg-border in-[li:last-child]:hidden"
        aria-hidden
      />
      <span className="mt-0.5 flex size-6 items-center justify-center rounded-full border bg-popover font-mono text-xs text-body">
        {n}
      </span>
      <Reveal className="min-w-0">
        <h3 className="text-h3">{title}</h3>
        <div className="mt-3 space-y-4 text-small text-pretty text-body">{children}</div>
      </Reveal>
    </li>
  )
}

export function Install() {
  return (
    <Section
      id="install"
      aside
      eyebrow="Install"
      title="Four steps to a working install."
      intro="The longest step is downloading the two local models. After setup, typed questions, OCR and redaction run on your Mac."
    >
      <ol>
        <Step n={1} title="Download and check it">
          <div className="flex flex-wrap items-center gap-x-4 gap-y-2">
            <DownloadButton />
            <span className="font-mono text-xs tracking-[-0.013em] text-muted-foreground">{metaLine}</span>
          </div>
          <p>Compare the file&apos;s SHA-256 with this one before you open it:</p>
          <CommandSnippet label="SHA-256" code={release.sha256} prompt={false} wrap />
          <CommandSnippet label="Check in Terminal" code={`shasum -a 256 ~/Downloads/${release.fileName}`} wrap />
        </Step>
        <Step n={2} title="Drag Gel to Applications">
          <p>
            Open the DMG and drag <strong className="font-medium text-foreground">Gel</strong> onto{" "}
            <strong className="font-medium text-foreground">Applications</strong>. Then drag{" "}
            <strong className="font-medium text-foreground">Gel Sample Files</strong> to Documents: the disk image is
            read-only, and Gel writes redacted copies next to the originals. Eject the Gel disk when you&apos;re done.
          </p>
          <Image
            src="/dmg-window.png"
            alt="The Gel installer window: Gel.app with an arrow to Applications, and below it Gel Sample Files, START-HERE.md and About This Build."
            width={1360}
            height={1016}
            sizes="(min-width: 768px) 640px, 100vw"
            className="w-full max-w-[640px] rounded-xl border"
          />
        </Step>
        <Step n={3} title="Open it the first time">
          <p>
            This is an ad-hoc-signed demo build, not a notarized release, so macOS stops it the first time. Open Gel
            once and dismiss the warning. Then go to{" "}
            <strong className="font-medium text-foreground">System Settings → Privacy &amp; Security</strong>, click{" "}
            <strong className="font-medium text-foreground">Open Anyway</strong> under Security, and enter your
            password.
          </p>
          <p>
            The button only appears for about an hour after you try to open the app. On macOS 15, Control-clicking
            and choosing Open no longer skips this step.
          </p>
        </Step>
        <Step n={4} title="Install Ollama and the models">
          <p>
            Gel runs its models through{" "}
            <a href="https://ollama.com" className="text-foreground underline underline-offset-4 hover:text-body">
              Ollama
            </a>
            . The model weights aren&apos;t in the DMG.
          </p>
          <InstallTerminal />
          <p>
            To try the sample files, open Gel, choose <strong className="font-medium text-foreground">Work: HR</strong>, and select{" "}
            <span className="font-mono text-[13px] tracking-[-0.013em] text-foreground">Documents/Gel Sample Files/HR Files</span>. When
            indexing finishes, open the <strong className="font-medium text-foreground">Library</strong>, select three
            résumés and click <strong className="font-medium text-foreground">Redact 3 files</strong>.
          </p>
          <p>
            To try questions, press <span className="font-mono text-[13px]">⌥Space</span> and ask{" "}
            <span className="text-foreground">&ldquo;Sino sa applicants ang may 5+ years sa payroll?&rdquo;</span>
          </p>
        </Step>
      </ol>
    </Section>
  )
}
