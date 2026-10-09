import { ShieldAlertIcon, XIcon } from "lucide-react"

// Leak Guard's overlay, recreated from docs/features/polish/design.md. The summary is gelcli's real output for
// demo-data/clipboard-samples/employee_record.txt. A product frame: the app's own dark colours (--app-*).
const SUMMARY =
  "4 government ID numbers, 1 salary, 1 bank account, 1 address, 1 birth date, 2 contact details, 2 names"

export function LeakOverlay() {
  return (
    <div
      role="img"
      aria-label={`Gel's Leak Guard overlay in Chrome: "This would leak: ${SUMMARY}", with Paste redacted and Ignore buttons.`}
      className="relative w-full max-w-[380px] overflow-hidden rounded-xl border border-app-hairline bg-app-card text-app-text shadow-frame"
    >
      <span className="absolute inset-y-0 left-0 w-[3px] bg-app-danger" aria-hidden />
      <div className="flex gap-3 p-4 pl-5">
        <span className="flex size-8 shrink-0 items-center justify-center rounded-full bg-app-danger-soft text-app-danger">
          <ShieldAlertIcon className="size-4" aria-hidden />
        </span>
        <div className="min-w-0 flex-1">
          <div className="flex items-start justify-between gap-2">
            <p className="text-sm font-semibold">
              Gel caught a leak <span className="font-normal text-app-text-secondary">· Chrome</span>
            </p>
            <XIcon className="size-3.5 text-app-text-secondary" aria-hidden />
          </div>
          <p className="mt-1 text-[13px] leading-5 text-app-text-secondary">This would leak: {SUMMARY}</p>
          <div className="mt-3 flex items-center gap-3">
            <span className="inline-flex h-7 items-center gap-2 rounded-md bg-app-accent-fill px-3 text-xs font-medium text-white">
              Paste redacted
              <kbd className="font-mono text-[11px] opacity-80">⌥⌘V</kbd>
            </span>
            <span className="text-xs text-app-text-secondary">Ignore</span>
          </div>
        </div>
      </div>
      <div className="h-0.5 bg-app-hairline">
        <div className="h-full w-2/3 bg-app-danger/70" />
      </div>
    </div>
  )
}
