import Image from "next/image"

import { CommandSnippet } from "@/components/command-snippet"
import { DownloadButton } from "@/components/download-button"
import { InstallTerminal } from "@/components/install-terminal"
import { Reveal, Section } from "@/components/section"
import { metaLine, release } from "@/lib/release"

function Step({ n, title, children }: { n: number; title: string; children: React.ReactNode }) {
  return (
    <li className="relative grid grid-cols-[28px_1fr] gap-x-4 pb-12 last:pb-0 sm:gap-x-6">
      <span
        className="absolute top-8 bottom-0 left-[13.5px] w-px bg-border in-[li:last-child]:hidden"
        aria-hidden
      />
      <span className="flex size-7 items-center justify-center rounded-full border bg-card font-mono text-xs font-medium">
        {n}
      </span>
      <Reveal className="min-w-0">
        <h3 className="text-h3 leading-7">{title}</h3>
        <div className="mt-3 space-y-4 text-[15px] leading-6 text-pretty text-muted-foreground">{children}</div>
      </Reveal>
    </li>
  )
}

export function Install() {
  return (
    <Section
      id="install"
      band
      eyebrow="Install"
      title="Four steps to a working install."
      intro="The longest step is downloading the two local models. After setup, typed questions, OCR and redaction run on your Mac."
    >
      <ol className="max-w-3xl">
        <Step n={1} title="Download and check it">
          <div className="flex flex-wrap items-center gap-x-4 gap-y-2">
            <DownloadButton />
            <span className="font-mono text-xs">{metaLine}</span>
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
            className="w-full max-w-[640px] rounded-xl border shadow-float"
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
            <a href="https://ollama.com" className="text-accent-foreground underline-offset-4 hover:underline">
              Ollama
            </a>
            . The model weights aren&apos;t in the DMG.
          </p>
          <InstallTerminal />
          <p>
            Open Gel, choose <strong className="font-medium text-foreground">Work: HR</strong>, and select{" "}
            <span className="font-mono text-[13px] text-foreground">Documents/Gel Sample Files/HR Files</span>. When
            indexing finishes, press ⌥Space and ask{" "}
            <span className="text-foreground">&ldquo;Sino sa applicants ang may 5+ years sa payroll?&rdquo;</span>
          </p>
        </Step>
      </ol>
    </Section>
  )
}
