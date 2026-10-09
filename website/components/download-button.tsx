import { ArrowDownToLineIcon } from "lucide-react"

import { buttonVariants } from "@/components/ui/button"
import { release } from "@/lib/release"
import { cn } from "@/lib/utils"

// The page's one chromatic control: acid lime, 6 px radius, 14 px / 510 (design.md → Components).
export function DownloadButton({
  label = "Download for Mac",
  className,
}: {
  label?: string
  className?: string
}) {
  return (
    <a
      href={release.dmgUrl}
      download={release.fileName}
      className={cn(
        buttonVariants(),
        "h-10 gap-2 rounded-md px-4 text-sm tracking-[-0.011em] transition-[background-color,transform] duration-150 ease-standard active:translate-y-0 active:scale-[0.98]",
        className,
      )}
    >
      <ArrowDownToLineIcon aria-hidden />
      {label}
    </a>
  )
}

// The nav's white pill: the second-highest-contrast control, so it never competes with the lime one.
export function NavDownload({ className }: { className?: string }) {
  return (
    <a
      href={release.dmgUrl}
      download={release.fileName}
      className={cn(
        "inline-flex h-8 items-center rounded-full bg-foreground px-4 text-[13px] font-medium text-background transition-[opacity,transform] duration-150 ease-standard outline-none hover:opacity-90 focus-visible:ring-3 focus-visible:ring-ring/50 focus-visible:ring-offset-2 focus-visible:ring-offset-background active:scale-[0.98]",
        className,
      )}
    >
      Download
    </a>
  )
}
