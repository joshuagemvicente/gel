"use client"

import { toast } from "sonner"

import {
  Snippet,
  SnippetCopyButton,
  SnippetHeader,
  SnippetTabsContent,
} from "@/components/kibo-ui/snippet"
import { cn } from "@/lib/utils"

// One copyable command or value, built on Kibo UI's Snippet.
export function CommandSnippet({
  label,
  code,
  prompt = true,
  wrap = false,
  className,
}: {
  label: string
  code: string
  prompt?: boolean
  /** Break long values (a hash) instead of scrolling them. */
  wrap?: boolean
  className?: string
}) {
  return (
    <Snippet defaultValue="only" className={cn("rounded-lg bg-card", className)}>
      <SnippetHeader className="bg-band py-0.5 pl-3">
        <span className="font-mono text-xs text-muted-foreground">{label}</span>
        <SnippetCopyButton
          value={code}
          aria-label={`Copy ${label}`}
          onCopy={() => toast.success("Copied", { description: label })}
          onError={() => toast.error("Couldn't copy. Select the text instead.")}
        />
      </SnippetHeader>
      <SnippetTabsContent
        value="only"
        className={cn(
          "bg-card px-3.5 py-3 font-mono text-[13px] leading-6 focus-visible:ring-3 focus-visible:ring-ring/50 focus-visible:ring-inset",
          wrap && "break-all whitespace-pre-wrap",
        )}
      >
        {prompt && (
          <span className="select-none text-muted-foreground" aria-hidden>
            ${" "}
          </span>
        )}
        {code}
      </SnippetTabsContent>
    </Snippet>
  )
}
