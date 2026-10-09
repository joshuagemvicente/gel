import { ArrowUpIcon } from "lucide-react"

import { LeakOverlay } from "@/components/leak-overlay"

// Leak Guard at the moment it matters: a generic AI chat in a browser (not any real product's UI), a question being
// typed, and Gel's overlay after a synthetic employee record was copied. The overlay text is gelcli's real output for
// demo-data/clipboard-samples/employee_record.txt. It shows the warning, not the paste (leak-guard T5 is unverified).
export function PasteCatchDemo() {
  return (
    <div className="relative">
      <div
        role="img"
        aria-label="A browser window with an AI chat. The user has typed: Can you summarize this employee record for me? Gel's Leak Guard panel is open on top."
        className="overflow-hidden rounded-xl border bg-card"
      >
        <div className="relative flex h-9 items-center border-b px-3.5">
          <div className="flex gap-1.5" aria-hidden>
            <span className="size-2.5 rounded-full bg-faint" />
            <span className="size-2.5 rounded-full bg-faint" />
            <span className="size-2.5 rounded-full bg-faint" />
          </div>
          <p className="absolute inset-x-16 truncate text-center text-[13px] text-muted-foreground">
            AI chat · Chrome
          </p>
        </div>
        <div className="flex min-h-[300px] flex-col justify-end gap-4 p-4 sm:min-h-[340px] sm:p-6">
          <div className="space-y-2.5 sm:max-w-[55%]" aria-hidden>
            <div className="h-2 w-3/4 rounded-full bg-border" />
            <div className="h-2 w-full rounded-full bg-border" />
            <div className="h-2 w-2/3 rounded-full bg-border" />
          </div>
          <div className="flex items-end gap-3 rounded-xl border bg-popover px-4 py-3">
            <p className="flex-1 text-small text-body">
              Can you summarize this employee record for me?
              <span className="ml-0.5 inline-block h-4 w-px translate-y-0.5 bg-body" aria-hidden />
            </p>
            <span
              className="flex size-7 shrink-0 items-center justify-center rounded-full bg-accent text-muted-foreground"
              aria-hidden
            >
              <ArrowUpIcon className="size-4" />
            </span>
          </div>
        </div>
      </div>
      <div className="mt-4 flex justify-center sm:absolute sm:top-12 sm:right-4 sm:mt-0 sm:block">
        <LeakOverlay />
      </div>
    </div>
  )
}
