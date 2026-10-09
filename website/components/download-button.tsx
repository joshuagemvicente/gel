import { ArrowDownToLineIcon } from "lucide-react"

import { buttonVariants } from "@/components/ui/button"
import { release } from "@/lib/release"
import { cn } from "@/lib/utils"

export function DownloadButton({
  size = "lg",
  label = "Download for Mac",
  className,
}: {
  size?: "default" | "lg"
  label?: string
  className?: string
}) {
  return (
    <a
      href={release.dmgUrl}
      download={release.fileName}
      className={cn(
        buttonVariants({ size }),
        "rounded-md transition-[background-color,transform] duration-150 ease-standard hover:bg-primary/90 active:scale-[0.97] active:translate-y-0",
        size === "lg" && "h-10 px-4 text-sm",
        className,
      )}
    >
      <ArrowDownToLineIcon aria-hidden />
      {label}
    </a>
  )
}
